-- =============================================================================
-- Investor Data Extract and Reporting Queries
-- Capital Management Co. - Fund Governance Simulation
-- =============================================================================
-- Purpose: Extract investor-level data for regulatory reporting, board packs,
--          and AML/KYC oversight. These queries support the investor services
--          function and the fund governance reporting cycle.
--
-- Fund Universe:
--   Global Equity Fund              | IE00B4X9L533
--   European Bond Fund              | IE00BK5BQ103
--   Multi-Asset Growth Fund         | LU0292097234
--   Emerging Markets Fund           | IE00BFYN9Y00
--   Real Estate Opportunities       | LU0488316133
--   Private Credit Fund             | LU0629460675
--
-- Tables Referenced: funds, investors, investor_holdings, nav_daily
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. FULL INVESTOR REGISTER WITH CURRENT HOLDINGS
-- -----------------------------------------------------------------------------
-- Produces the complete investor register showing each investor's current
-- position across all funds. This is used for the register of shareholders
-- and for AML/KYC review purposes.

SELECT
    i.investor_id,
    i.investor_name,
    i.investor_type,
    i.country,
    i.onboarding_date,
    i.kyc_status,
    f.fund_name,
    f.isin,
    ih.units_held,
    nd.nav_per_share,
    ROUND(ih.units_held * nd.nav_per_share, 2) AS holding_value,
    ih.as_of_date
FROM investors i
INNER JOIN investor_holdings ih ON i.investor_id = ih.investor_id
INNER JOIN funds f ON ih.fund_id = f.fund_id
INNER JOIN nav_daily nd
    ON ih.fund_id = nd.fund_id
    AND ih.as_of_date = nd.nav_date
WHERE ih.as_of_date = (
    -- Use the most recent holding date available per fund
    SELECT MAX(ih2.as_of_date)
    FROM investor_holdings ih2
    WHERE ih2.fund_id = ih.fund_id
)
ORDER BY f.fund_name, i.investor_name;


-- -----------------------------------------------------------------------------
-- 2. SUBSCRIPTION AND REDEMPTION ACTIVITY FOR A GIVEN PERIOD
-- -----------------------------------------------------------------------------
-- Shows all investor transactions (subscriptions and redemptions) within
-- a specified date range. Adjust the @start_date and @end_date parameters
-- to match the reporting period.

DECLARE @start_date DATE = '2025-01-01';
DECLARE @end_date   DATE = '2025-12-31';

SELECT
    i.investor_id,
    i.investor_name,
    i.investor_type,
    f.fund_name,
    f.isin,
    ih.transaction_type,
    ih.transaction_date,
    ih.units_transacted,
    ih.transaction_amount,
    ih.nav_at_transaction,
    ih.settlement_date
FROM investors i
INNER JOIN investor_holdings ih ON i.investor_id = ih.investor_id
INNER JOIN funds f ON ih.fund_id = f.fund_id
WHERE ih.transaction_date BETWEEN @start_date AND @end_date
  AND ih.transaction_type IN ('Subscription', 'Redemption')
ORDER BY ih.transaction_date DESC, f.fund_name, i.investor_name;


-- -----------------------------------------------------------------------------
-- 3. TOP INVESTORS BY AUM PER FUND
-- -----------------------------------------------------------------------------
-- Identifies the largest investors in each fund by the market value of
-- their holdings. This supports the concentration risk analysis reported
-- to the board.

SELECT
    f.fund_name,
    f.isin,
    i.investor_id,
    i.investor_name,
    i.investor_type,
    i.country,
    ih.units_held,
    ROUND(ih.units_held * nd.nav_per_share, 2) AS holding_value,
    RANK() OVER (
        PARTITION BY f.fund_id
        ORDER BY ih.units_held * nd.nav_per_share DESC
    ) AS rank_in_fund
FROM investor_holdings ih
INNER JOIN investors i ON ih.investor_id = i.investor_id
INNER JOIN funds f ON ih.fund_id = f.fund_id
INNER JOIN nav_daily nd
    ON ih.fund_id = nd.fund_id
    AND ih.as_of_date = nd.nav_date
WHERE ih.as_of_date = (
    SELECT MAX(ih2.as_of_date)
    FROM investor_holdings ih2
    WHERE ih2.fund_id = ih.fund_id
)
ORDER BY f.fund_name, rank_in_fund;


-- -----------------------------------------------------------------------------
-- 4. INVESTOR CONCENTRATION ANALYSIS (TOP 5 AS % OF FUND)
-- -----------------------------------------------------------------------------
-- Calculates the percentage of each fund held by the top 5 investors.
-- High concentration is a governance risk that must be disclosed to the
-- board and monitored for liquidity management purposes.

WITH current_holdings AS (
    SELECT
        ih.fund_id,
        ih.investor_id,
        ROUND(ih.units_held * nd.nav_per_share, 2) AS holding_value
    FROM investor_holdings ih
    INNER JOIN nav_daily nd
        ON ih.fund_id = nd.fund_id
        AND ih.as_of_date = nd.nav_date
    WHERE ih.as_of_date = (
        SELECT MAX(ih2.as_of_date)
        FROM investor_holdings ih2
        WHERE ih2.fund_id = ih.fund_id
    )
),

fund_totals AS (
    SELECT fund_id, SUM(holding_value) AS total_fund_aum
    FROM current_holdings
    GROUP BY fund_id
),

ranked_investors AS (
    SELECT
        ch.fund_id,
        ch.investor_id,
        ch.holding_value,
        ft.total_fund_aum,
        ROUND(ch.holding_value / ft.total_fund_aum * 100.0, 2) AS pct_of_fund,
        ROW_NUMBER() OVER (
            PARTITION BY ch.fund_id ORDER BY ch.holding_value DESC
        ) AS investor_rank
    FROM current_holdings ch
    INNER JOIN fund_totals ft ON ch.fund_id = ft.fund_id
)

SELECT
    f.fund_name,
    f.isin,
    i.investor_name,
    i.investor_type,
    ri.holding_value,
    ri.pct_of_fund,
    ri.investor_rank,
    ri.total_fund_aum,
    -- Running total of top N investors as % of fund
    SUM(ri.pct_of_fund) OVER (
        PARTITION BY ri.fund_id ORDER BY ri.investor_rank
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_pct
FROM ranked_investors ri
INNER JOIN funds f ON ri.fund_id = f.fund_id
INNER JOIN investors i ON ri.investor_id = i.investor_id
WHERE ri.investor_rank <= 5
ORDER BY f.fund_name, ri.investor_rank;


-- -----------------------------------------------------------------------------
-- 5. GEOGRAPHIC DISTRIBUTION OF INVESTORS
-- -----------------------------------------------------------------------------
-- Breaks down the investor base by country for each fund. This data feeds
-- into the regulatory reporting requirements (e.g., FATCA/CRS) and is
-- included in the quarterly board pack.

WITH current_holdings AS (
    SELECT
        ih.fund_id,
        ih.investor_id,
        ROUND(ih.units_held * nd.nav_per_share, 2) AS holding_value
    FROM investor_holdings ih
    INNER JOIN nav_daily nd
        ON ih.fund_id = nd.fund_id
        AND ih.as_of_date = nd.nav_date
    WHERE ih.as_of_date = (
        SELECT MAX(ih2.as_of_date)
        FROM investor_holdings ih2
        WHERE ih2.fund_id = ih.fund_id
    )
)

SELECT
    f.fund_name,
    f.isin,
    i.country,
    COUNT(DISTINCT i.investor_id) AS investor_count,
    SUM(ch.holding_value) AS total_aum_by_country,
    ROUND(
        SUM(ch.holding_value) /
        SUM(SUM(ch.holding_value)) OVER (PARTITION BY f.fund_id) * 100.0,
        2
    ) AS pct_of_fund_aum
FROM current_holdings ch
INNER JOIN investors i ON ch.investor_id = i.investor_id
INNER JOIN funds f ON ch.fund_id = f.fund_id
GROUP BY f.fund_id, f.fund_name, f.isin, i.country
ORDER BY f.fund_name, total_aum_by_country DESC;


-- -----------------------------------------------------------------------------
-- 6. INVESTOR TYPE BREAKDOWN
-- -----------------------------------------------------------------------------
-- Categorises investors by type (e.g., Institutional, Retail, Pension Fund,
-- Insurance Company, Family Office). This analysis helps the board
-- understand the investor base composition and associated risks.

WITH current_holdings AS (
    SELECT
        ih.fund_id,
        ih.investor_id,
        ROUND(ih.units_held * nd.nav_per_share, 2) AS holding_value
    FROM investor_holdings ih
    INNER JOIN nav_daily nd
        ON ih.fund_id = nd.fund_id
        AND ih.as_of_date = nd.nav_date
    WHERE ih.as_of_date = (
        SELECT MAX(ih2.as_of_date)
        FROM investor_holdings ih2
        WHERE ih2.fund_id = ih.fund_id
    )
)

SELECT
    f.fund_name,
    f.isin,
    i.investor_type,
    COUNT(DISTINCT i.investor_id) AS investor_count,
    SUM(ch.holding_value) AS total_aum_by_type,
    ROUND(
        SUM(ch.holding_value) /
        SUM(SUM(ch.holding_value)) OVER (PARTITION BY f.fund_id) * 100.0,
        2
    ) AS pct_of_fund_aum,
    MIN(ch.holding_value) AS min_holding,
    MAX(ch.holding_value) AS max_holding,
    ROUND(AVG(ch.holding_value), 2) AS avg_holding
FROM current_holdings ch
INNER JOIN investors i ON ch.investor_id = i.investor_id
INNER JOIN funds f ON ch.fund_id = f.fund_id
GROUP BY f.fund_id, f.fund_name, f.isin, i.investor_type
ORDER BY f.fund_name, total_aum_by_type DESC;


-- -----------------------------------------------------------------------------
-- 7. NEW INVESTORS ONBOARDED IN PERIOD
-- -----------------------------------------------------------------------------
-- Lists all investors onboarded during the reporting period, along with
-- their initial subscription details. This supports the AML oversight
-- function and is reviewed at each board meeting.

DECLARE @onboard_start DATE = '2025-01-01';
DECLARE @onboard_end   DATE = '2025-12-31';

SELECT
    i.investor_id,
    i.investor_name,
    i.investor_type,
    i.country,
    i.onboarding_date,
    i.kyc_status,
    f.fund_name,
    f.isin,
    ih.transaction_date AS first_subscription_date,
    ih.units_transacted AS initial_units,
    ih.transaction_amount AS initial_investment,
    ih.nav_at_transaction AS entry_nav
FROM investors i
INNER JOIN investor_holdings ih ON i.investor_id = ih.investor_id
INNER JOIN funds f ON ih.fund_id = f.fund_id
WHERE i.onboarding_date BETWEEN @onboard_start AND @onboard_end
  AND ih.transaction_type = 'Subscription'
  AND ih.transaction_date = (
      -- First subscription per fund for each new investor
      SELECT MIN(ih2.transaction_date)
      FROM investor_holdings ih2
      WHERE ih2.investor_id = i.investor_id
        AND ih2.fund_id = ih.fund_id
        AND ih2.transaction_type = 'Subscription'
  )
ORDER BY i.onboarding_date DESC, f.fund_name;

-- =============================================================================
-- END OF INVESTOR DATA EXTRACT
-- =============================================================================
