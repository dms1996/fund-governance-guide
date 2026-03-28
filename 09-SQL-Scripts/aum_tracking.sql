-- =============================================================================
-- AUM Tracking and Analysis Queries
-- Capital Management Co. - Fund Governance Simulation
-- =============================================================================
-- Purpose: Track assets under management across the fund range for board
--          reporting, regulatory filings, and commercial oversight.
--
-- Fund Universe:
--   Global Equity Fund              | IE00B4X9L533
--   European Bond Fund              | IE00BK5BQ103
--   Multi-Asset Growth Fund         | LU0292097234
--   Emerging Markets Fund           | IE00BFYN9Y00
--   Real Estate Opportunities       | LU0488316133
--   Private Credit Fund             | LU0629460675
--
-- Tables Referenced: funds, nav_daily, investor_holdings
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. DAILY AUM PER FUND
-- -----------------------------------------------------------------------------
-- Returns the total net assets for each fund on each business day.
-- This is the primary AUM data source and is derived from the daily
-- NAV production process.

SELECT
    f.fund_id,
    f.fund_name,
    f.isin,
    f.domicile,
    f.fund_type,
    nd.nav_date,
    nd.total_net_assets AS daily_aum,
    nd.nav_per_share,
    nd.shares_outstanding
FROM nav_daily nd
INNER JOIN funds f ON nd.fund_id = f.fund_id
WHERE nd.nav_date >= DATEADD(MONTH, -3, GETDATE())  -- Last 3 months
ORDER BY nd.nav_date DESC, f.fund_name;


-- -----------------------------------------------------------------------------
-- 2. AUM ATTRIBUTION (MARKET MOVEMENT VS NET FLOWS)
-- -----------------------------------------------------------------------------
-- Decomposes the daily change in AUM into two components:
--   (a) Market movement: change in value of existing assets
--   (b) Net flows: new subscriptions minus redemptions
-- This attribution is essential for understanding whether AUM growth
-- is organic (flows) or driven by market performance.

WITH daily_changes AS (
    SELECT
        nd.fund_id,
        nd.nav_date,
        nd.total_net_assets AS current_aum,
        LAG(nd.total_net_assets) OVER (
            PARTITION BY nd.fund_id ORDER BY nd.nav_date
        ) AS previous_aum,
        -- Net flows = sum of subscriptions minus redemptions on this date
        ISNULL((
            SELECT SUM(
                CASE
                    WHEN ih.transaction_type = 'Subscription' THEN ih.transaction_amount
                    WHEN ih.transaction_type = 'Redemption' THEN -ih.transaction_amount
                    ELSE 0
                END
            )
            FROM investor_holdings ih
            WHERE ih.fund_id = nd.fund_id
              AND ih.transaction_date = nd.nav_date
        ), 0) AS net_flows
    FROM nav_daily nd
)

SELECT
    f.fund_name,
    f.isin,
    dc.nav_date,
    dc.previous_aum,
    dc.current_aum,
    dc.current_aum - dc.previous_aum AS total_aum_change,
    dc.net_flows,
    (dc.current_aum - dc.previous_aum - dc.net_flows) AS market_movement,
    -- Percentages
    CASE
        WHEN dc.previous_aum <> 0
        THEN ROUND(
            (dc.current_aum - dc.previous_aum) / dc.previous_aum * 100.0, 4
        )
        ELSE NULL
    END AS total_change_pct,
    CASE
        WHEN dc.previous_aum <> 0
        THEN ROUND(dc.net_flows / dc.previous_aum * 100.0, 4)
        ELSE NULL
    END AS net_flow_pct,
    CASE
        WHEN dc.previous_aum <> 0
        THEN ROUND(
            (dc.current_aum - dc.previous_aum - dc.net_flows)
            / dc.previous_aum * 100.0, 4
        )
        ELSE NULL
    END AS market_movement_pct
FROM daily_changes dc
INNER JOIN funds f ON dc.fund_id = f.fund_id
WHERE dc.previous_aum IS NOT NULL
ORDER BY dc.nav_date DESC, f.fund_name;


-- -----------------------------------------------------------------------------
-- 3. MONTHLY AUM SUMMARY WITH GROWTH RATES
-- -----------------------------------------------------------------------------
-- Aggregates AUM to a monthly level using end-of-month snapshots. Includes
-- month-over-month and year-over-year growth rates for board reporting.

WITH monthly_aum AS (
    SELECT
        nd.fund_id,
        YEAR(nd.nav_date) AS aum_year,
        MONTH(nd.nav_date) AS aum_month,
        FORMAT(nd.nav_date, 'yyyy-MM') AS period,
        -- End-of-month AUM (use the last available NAV date in the month)
        MAX(nd.nav_date) AS month_end_date,
        (SELECT nd2.total_net_assets
         FROM nav_daily nd2
         WHERE nd2.fund_id = nd.fund_id
           AND nd2.nav_date = MAX(nd.nav_date)
        ) AS eom_aum,
        AVG(nd.total_net_assets) AS avg_daily_aum,
        MIN(nd.total_net_assets) AS min_daily_aum,
        MAX(nd.total_net_assets) AS max_daily_aum
    FROM nav_daily nd
    GROUP BY nd.fund_id, YEAR(nd.nav_date), MONTH(nd.nav_date),
             FORMAT(nd.nav_date, 'yyyy-MM')
)

SELECT
    f.fund_name,
    f.isin,
    ma.period,
    ma.month_end_date,
    ROUND(ma.eom_aum, 2) AS end_of_month_aum,
    ROUND(ma.avg_daily_aum, 2) AS avg_daily_aum,
    -- Month-over-month growth
    ROUND(
        (ma.eom_aum - LAG(ma.eom_aum) OVER (
            PARTITION BY ma.fund_id ORDER BY ma.aum_year, ma.aum_month
        )) / NULLIF(LAG(ma.eom_aum) OVER (
            PARTITION BY ma.fund_id ORDER BY ma.aum_year, ma.aum_month
        ), 0) * 100.0,
        2
    ) AS mom_growth_pct,
    -- Year-over-year growth (compare to same month last year)
    ROUND(
        (ma.eom_aum - LAG(ma.eom_aum, 12) OVER (
            PARTITION BY ma.fund_id ORDER BY ma.aum_year, ma.aum_month
        )) / NULLIF(LAG(ma.eom_aum, 12) OVER (
            PARTITION BY ma.fund_id ORDER BY ma.aum_year, ma.aum_month
        ), 0) * 100.0,
        2
    ) AS yoy_growth_pct
FROM monthly_aum ma
INNER JOIN funds f ON ma.fund_id = f.fund_id
ORDER BY f.fund_name, ma.aum_year, ma.aum_month;


-- -----------------------------------------------------------------------------
-- 4. AUM BY UMBRELLA / VEHICLE
-- -----------------------------------------------------------------------------
-- Groups AUM by domicile and legal vehicle structure. The CMC fund range
-- includes both Irish-domiciled (IE) and Luxembourg-domiciled (LU) funds
-- under different umbrella structures.

SELECT
    f.domicile,
    f.umbrella_name,
    f.vehicle_type,
    COUNT(DISTINCT f.fund_id) AS fund_count,
    SUM(nd.total_net_assets) AS total_aum,
    ROUND(
        SUM(nd.total_net_assets) /
        SUM(SUM(nd.total_net_assets)) OVER () * 100.0,
        2
    ) AS pct_of_total_aum,
    MIN(nd.total_net_assets) AS smallest_fund_aum,
    MAX(nd.total_net_assets) AS largest_fund_aum,
    ROUND(AVG(nd.total_net_assets), 2) AS avg_fund_aum
FROM nav_daily nd
INNER JOIN funds f ON nd.fund_id = f.fund_id
WHERE nd.nav_date = (
    SELECT MAX(nav_date) FROM nav_daily
)
GROUP BY f.domicile, f.umbrella_name, f.vehicle_type
ORDER BY total_aum DESC;

-- Detail by fund within each umbrella
SELECT
    f.domicile,
    f.umbrella_name,
    f.fund_name,
    f.isin,
    f.fund_type,
    nd.total_net_assets AS current_aum,
    ROUND(
        nd.total_net_assets /
        SUM(nd.total_net_assets) OVER (PARTITION BY f.umbrella_name) * 100.0,
        2
    ) AS pct_of_umbrella
FROM nav_daily nd
INNER JOIN funds f ON nd.fund_id = f.fund_id
WHERE nd.nav_date = (
    SELECT MAX(nav_date) FROM nav_daily
)
ORDER BY f.domicile, f.umbrella_name, nd.total_net_assets DESC;


-- -----------------------------------------------------------------------------
-- 5. QUARTERLY AUM FOR BOARD REPORTING
-- -----------------------------------------------------------------------------
-- Produces the quarterly AUM snapshot used in the board pack. Includes
-- quarter-end AUM, average AUM for fee calculation purposes, net flows
-- during the quarter, and the number of business days.

WITH quarterly_data AS (
    SELECT
        nd.fund_id,
        YEAR(nd.nav_date) AS q_year,
        DATEPART(QUARTER, nd.nav_date) AS q_quarter,
        CONCAT('Q', DATEPART(QUARTER, nd.nav_date), ' ',
               YEAR(nd.nav_date)) AS quarter_label,
        COUNT(nd.nav_date) AS business_days,
        -- Quarter-end AUM
        (SELECT nd2.total_net_assets
         FROM nav_daily nd2
         WHERE nd2.fund_id = nd.fund_id
           AND nd2.nav_date = MAX(nd.nav_date)
        ) AS quarter_end_aum,
        -- Quarter-start AUM
        (SELECT nd3.total_net_assets
         FROM nav_daily nd3
         WHERE nd3.fund_id = nd.fund_id
           AND nd3.nav_date = MIN(nd.nav_date)
        ) AS quarter_start_aum,
        AVG(nd.total_net_assets) AS avg_aum,
        MIN(nd.total_net_assets) AS min_aum,
        MAX(nd.total_net_assets) AS max_aum
    FROM nav_daily nd
    GROUP BY nd.fund_id, YEAR(nd.nav_date), DATEPART(QUARTER, nd.nav_date)
),

quarterly_flows AS (
    SELECT
        ih.fund_id,
        YEAR(ih.transaction_date) AS q_year,
        DATEPART(QUARTER, ih.transaction_date) AS q_quarter,
        SUM(CASE WHEN ih.transaction_type = 'Subscription'
            THEN ih.transaction_amount ELSE 0 END) AS gross_subscriptions,
        SUM(CASE WHEN ih.transaction_type = 'Redemption'
            THEN ih.transaction_amount ELSE 0 END) AS gross_redemptions
    FROM investor_holdings ih
    WHERE ih.transaction_type IN ('Subscription', 'Redemption')
    GROUP BY ih.fund_id, YEAR(ih.transaction_date),
             DATEPART(QUARTER, ih.transaction_date)
)

SELECT
    f.fund_name,
    f.isin,
    qd.quarter_label,
    qd.business_days,
    ROUND(qd.quarter_start_aum, 2) AS quarter_start_aum,
    ROUND(qd.quarter_end_aum, 2) AS quarter_end_aum,
    ROUND(qd.quarter_end_aum - qd.quarter_start_aum, 2) AS total_aum_change,
    ROUND(ISNULL(qf.gross_subscriptions, 0), 2) AS gross_subscriptions,
    ROUND(ISNULL(qf.gross_redemptions, 0), 2) AS gross_redemptions,
    ROUND(
        ISNULL(qf.gross_subscriptions, 0) - ISNULL(qf.gross_redemptions, 0),
        2
    ) AS net_flows,
    -- Market movement = total change minus net flows
    ROUND(
        (qd.quarter_end_aum - qd.quarter_start_aum)
        - (ISNULL(qf.gross_subscriptions, 0) - ISNULL(qf.gross_redemptions, 0)),
        2
    ) AS market_movement,
    ROUND(qd.avg_aum, 2) AS avg_aum_for_fees,
    CASE
        WHEN qd.quarter_start_aum <> 0
        THEN ROUND(
            (qd.quarter_end_aum - qd.quarter_start_aum)
            / qd.quarter_start_aum * 100.0, 2
        )
        ELSE NULL
    END AS quarterly_growth_pct
FROM quarterly_data qd
INNER JOIN funds f ON qd.fund_id = f.fund_id
LEFT JOIN quarterly_flows qf
    ON qd.fund_id = qf.fund_id
    AND qd.q_year = qf.q_year
    AND qd.q_quarter = qf.q_quarter
ORDER BY f.fund_name, qd.q_year, qd.q_quarter;


-- -----------------------------------------------------------------------------
-- 6. YEAR-OVER-YEAR AUM COMPARISON
-- -----------------------------------------------------------------------------
-- Compares end-of-year AUM across years for each fund, showing absolute
-- and percentage growth. This long-term view is used in the annual report
-- and for strategic planning.

WITH year_end_aum AS (
    SELECT
        nd.fund_id,
        YEAR(nd.nav_date) AS aum_year,
        (SELECT nd2.total_net_assets
         FROM nav_daily nd2
         WHERE nd2.fund_id = nd.fund_id
           AND nd2.nav_date = MAX(nd.nav_date)
        ) AS year_end_aum,
        MAX(nd.nav_date) AS year_end_date,
        AVG(nd.total_net_assets) AS avg_annual_aum,
        MIN(nd.total_net_assets) AS annual_low,
        MAX(nd.total_net_assets) AS annual_high
    FROM nav_daily nd
    GROUP BY nd.fund_id, YEAR(nd.nav_date)
)

SELECT
    f.fund_name,
    f.isin,
    f.domicile,
    yea.aum_year,
    yea.year_end_date,
    ROUND(yea.year_end_aum, 2) AS year_end_aum,
    ROUND(yea.avg_annual_aum, 2) AS avg_annual_aum,
    ROUND(yea.annual_low, 2) AS annual_low,
    ROUND(yea.annual_high, 2) AS annual_high,
    -- Year-over-year change
    ROUND(
        yea.year_end_aum - LAG(yea.year_end_aum) OVER (
            PARTITION BY yea.fund_id ORDER BY yea.aum_year
        ),
        2
    ) AS yoy_change,
    CASE
        WHEN LAG(yea.year_end_aum) OVER (
            PARTITION BY yea.fund_id ORDER BY yea.aum_year
        ) <> 0
        THEN ROUND(
            (yea.year_end_aum - LAG(yea.year_end_aum) OVER (
                PARTITION BY yea.fund_id ORDER BY yea.aum_year
            )) / LAG(yea.year_end_aum) OVER (
                PARTITION BY yea.fund_id ORDER BY yea.aum_year
            ) * 100.0, 2
        )
        ELSE NULL
    END AS yoy_growth_pct,
    -- Compound annual growth rate (CAGR) from first year
    CASE
        WHEN FIRST_VALUE(yea.year_end_aum) OVER (
            PARTITION BY yea.fund_id ORDER BY yea.aum_year
        ) > 0
        AND yea.aum_year > FIRST_VALUE(yea.aum_year) OVER (
            PARTITION BY yea.fund_id ORDER BY yea.aum_year
        )
        THEN ROUND(
            (POWER(
                yea.year_end_aum / FIRST_VALUE(yea.year_end_aum) OVER (
                    PARTITION BY yea.fund_id ORDER BY yea.aum_year
                ),
                1.0 / (yea.aum_year - FIRST_VALUE(yea.aum_year) OVER (
                    PARTITION BY yea.fund_id ORDER BY yea.aum_year
                ))
            ) - 1) * 100.0, 2
        )
        ELSE NULL
    END AS cagr_pct
FROM year_end_aum yea
INNER JOIN funds f ON yea.fund_id = f.fund_id
ORDER BY f.fund_name, yea.aum_year;

-- =============================================================================
-- END OF AUM TRACKING SCRIPT
-- =============================================================================
