-- =============================================================================
-- NAV Data Quality Validation Script
-- Capital Management Co. - Fund Governance Simulation
-- =============================================================================
-- Purpose: Comprehensive validation of daily NAV data across all funds.
--          Designed to be run as part of the daily NAV oversight process.
--
-- Fund Universe:
--   Global Equity Fund              | IE00B4X9L533
--   European Bond Fund              | IE00BK5BQ103
--   Multi-Asset Growth Fund         | LU0292097234
--   Emerging Markets Fund           | IE00BFYN9Y00
--   Real Estate Opportunities       | LU0488316133
--   Private Credit Fund             | LU0629460675
--
-- Tables Referenced: funds, nav_daily, nav_breaks, investor_holdings
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. CHECK FOR MISSING NAV DATES (GAPS IN BUSINESS DAY CALENDAR)
-- -----------------------------------------------------------------------------
-- Business days should have a NAV entry for every active fund. This query
-- identifies any dates where a fund is missing its NAV record by comparing
-- against a generated business day calendar. Weekends and known public
-- holidays are excluded.

WITH business_days AS (
    -- Generate a sequence of business days for the reporting window.
    -- Adjust the date range as needed for your validation period.
    SELECT cal.business_date
    FROM (
        SELECT DATEADD(DAY, seq.n, '2025-01-01') AS business_date
        FROM (
            SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
            FROM sys.objects a CROSS JOIN sys.objects b
        ) seq
        WHERE DATEADD(DAY, seq.n, '2025-01-01') <= GETDATE()
    ) cal
    WHERE DATENAME(WEEKDAY, cal.business_date) NOT IN ('Saturday', 'Sunday')
    -- Optionally join to a public_holidays table to exclude those dates
    -- AND cal.business_date NOT IN (SELECT holiday_date FROM public_holidays)
),

active_funds AS (
    SELECT fund_id, fund_name, isin
    FROM funds
    WHERE status = 'Active'
),

expected_entries AS (
    -- Every active fund should have a NAV on every business day.
    SELECT af.fund_id, af.fund_name, af.isin, bd.business_date
    FROM active_funds af
    CROSS JOIN business_days bd
)

SELECT
    ee.fund_id,
    ee.fund_name,
    ee.isin,
    ee.business_date AS missing_nav_date,
    'MISSING_NAV' AS issue_type,
    'No NAV record found for this business day' AS issue_description
FROM expected_entries ee
LEFT JOIN nav_daily nd
    ON ee.fund_id = nd.fund_id
    AND ee.business_date = nd.nav_date
WHERE nd.nav_date IS NULL
ORDER BY ee.fund_name, ee.business_date;


-- -----------------------------------------------------------------------------
-- 2. DETECT DUPLICATE NAV ENTRIES
-- -----------------------------------------------------------------------------
-- Each fund should have exactly one NAV per date. Duplicate entries may
-- indicate a data load error or a failure in the deduplication process.

SELECT
    nd.fund_id,
    f.fund_name,
    f.isin,
    nd.nav_date,
    COUNT(*) AS entry_count,
    'DUPLICATE_NAV' AS issue_type,
    'Multiple NAV entries found for the same date' AS issue_description
FROM nav_daily nd
INNER JOIN funds f ON nd.fund_id = f.fund_id
GROUP BY nd.fund_id, f.fund_name, f.isin, nd.nav_date
HAVING COUNT(*) > 1
ORDER BY f.fund_name, nd.nav_date;


-- -----------------------------------------------------------------------------
-- 3. FLAG ABNORMAL DAILY RETURNS (GREATER THAN 5% MOVE)
-- -----------------------------------------------------------------------------
-- Large single-day NAV movements may indicate a pricing error, a corporate
-- action that was not processed correctly, or a genuine market event that
-- requires investigation. The 5% threshold is configurable.

WITH nav_with_returns AS (
    SELECT
        nd.fund_id,
        f.fund_name,
        f.isin,
        nd.nav_date,
        nd.nav_per_share,
        LAG(nd.nav_per_share) OVER (
            PARTITION BY nd.fund_id ORDER BY nd.nav_date
        ) AS prev_nav,
        CASE
            WHEN LAG(nd.nav_per_share) OVER (
                PARTITION BY nd.fund_id ORDER BY nd.nav_date
            ) IS NOT NULL
            AND LAG(nd.nav_per_share) OVER (
                PARTITION BY nd.fund_id ORDER BY nd.nav_date
            ) <> 0
            THEN (nd.nav_per_share - LAG(nd.nav_per_share) OVER (
                PARTITION BY nd.fund_id ORDER BY nd.nav_date
            )) / LAG(nd.nav_per_share) OVER (
                PARTITION BY nd.fund_id ORDER BY nd.nav_date
            ) * 100.0
            ELSE NULL
        END AS daily_return_pct
    FROM nav_daily nd
    INNER JOIN funds f ON nd.fund_id = f.fund_id
)

SELECT
    fund_id,
    fund_name,
    isin,
    nav_date,
    prev_nav,
    nav_per_share AS current_nav,
    ROUND(daily_return_pct, 4) AS daily_return_pct,
    'ABNORMAL_RETURN' AS issue_type,
    CONCAT('Daily return of ', CAST(ROUND(daily_return_pct, 2) AS VARCHAR),
           '% exceeds +/-5% threshold') AS issue_description
FROM nav_with_returns
WHERE ABS(daily_return_pct) > 5.0
ORDER BY ABS(daily_return_pct) DESC, fund_name;


-- -----------------------------------------------------------------------------
-- 4. VALIDATE NAV VS SUM OF HOLDINGS
-- -----------------------------------------------------------------------------
-- The total NAV of a fund should reconcile to the sum of all investor
-- holdings multiplied by the NAV per share. A material variance may
-- indicate an issue with the unit reconciliation or a subscription/
-- redemption that has not been reflected.

SELECT
    f.fund_id,
    f.fund_name,
    f.isin,
    nd.nav_date,
    nd.total_net_assets AS reported_total_nav,
    SUM(ih.units_held * nd.nav_per_share) AS calculated_from_holdings,
    nd.total_net_assets - SUM(ih.units_held * nd.nav_per_share) AS variance,
    CASE
        WHEN nd.total_net_assets <> 0
        THEN ROUND(
            (nd.total_net_assets - SUM(ih.units_held * nd.nav_per_share))
            / nd.total_net_assets * 100.0, 4
        )
        ELSE NULL
    END AS variance_pct,
    'NAV_HOLDINGS_MISMATCH' AS issue_type,
    'Total NAV does not reconcile to sum of investor holdings' AS issue_description
FROM nav_daily nd
INNER JOIN funds f ON nd.fund_id = f.fund_id
INNER JOIN investor_holdings ih
    ON nd.fund_id = ih.fund_id
    AND nd.nav_date = ih.as_of_date
GROUP BY f.fund_id, f.fund_name, f.isin, nd.nav_date,
         nd.total_net_assets, nd.nav_per_share
HAVING ABS(nd.total_net_assets - SUM(ih.units_held * nd.nav_per_share)) > 0.01
ORDER BY ABS(nd.total_net_assets - SUM(ih.units_held * nd.nav_per_share)) DESC;


-- -----------------------------------------------------------------------------
-- 5. CHECK STALE PRICES (SAME NAV FOR 3+ CONSECUTIVE BUSINESS DAYS)
-- -----------------------------------------------------------------------------
-- If the NAV per share remains identical for three or more consecutive
-- business days, the underlying assets may not be receiving updated
-- market prices. This is especially relevant for Real Estate
-- Opportunities Fund (LU0488316133) and Private Credit Fund
-- (LU0629460675) where illiquid holdings can mask stale pricing.

WITH nav_sequence AS (
    SELECT
        nd.fund_id,
        f.fund_name,
        f.isin,
        nd.nav_date,
        nd.nav_per_share,
        LAG(nd.nav_per_share, 1) OVER (
            PARTITION BY nd.fund_id ORDER BY nd.nav_date
        ) AS nav_prev_1,
        LAG(nd.nav_per_share, 2) OVER (
            PARTITION BY nd.fund_id ORDER BY nd.nav_date
        ) AS nav_prev_2
    FROM nav_daily nd
    INNER JOIN funds f ON nd.fund_id = f.fund_id
)

SELECT
    fund_id,
    fund_name,
    isin,
    nav_date,
    nav_per_share,
    'STALE_PRICE' AS issue_type,
    'NAV per share unchanged for 3+ consecutive business days' AS issue_description
FROM nav_sequence
WHERE nav_per_share = nav_prev_1
  AND nav_per_share = nav_prev_2
ORDER BY fund_name, nav_date;


-- -----------------------------------------------------------------------------
-- 6. CROSS-VALIDATE AGAINST ADMINISTRATOR DATA
-- -----------------------------------------------------------------------------
-- The nav_breaks table holds discrepancies between the internally
-- calculated NAV and the NAV reported by the fund administrator.
-- Any break exceeding the agreed tolerance (typically 0.01% or 0.05%)
-- must be investigated and resolved before the NAV is published.

SELECT
    nb.break_id,
    f.fund_id,
    f.fund_name,
    f.isin,
    nb.nav_date,
    nb.internal_nav     AS internal_nav_per_share,
    nb.administrator_nav AS admin_nav_per_share,
    nb.internal_nav - nb.administrator_nav AS absolute_difference,
    CASE
        WHEN nb.administrator_nav <> 0
        THEN ROUND(
            (nb.internal_nav - nb.administrator_nav)
            / nb.administrator_nav * 100.0, 6
        )
        ELSE NULL
    END AS difference_pct,
    nb.tolerance_pct,
    nb.break_status,
    nb.resolution_notes,
    'ADMIN_NAV_BREAK' AS issue_type,
    CASE
        WHEN nb.break_status = 'Open'
        THEN 'Unresolved NAV break against administrator - requires investigation'
        ELSE 'Resolved NAV break - included for audit trail'
    END AS issue_description
FROM nav_breaks nb
INNER JOIN funds f ON nb.fund_id = f.fund_id
WHERE ABS(
    CASE
        WHEN nb.administrator_nav <> 0
        THEN (nb.internal_nav - nb.administrator_nav) / nb.administrator_nav * 100.0
        ELSE 0
    END
) > nb.tolerance_pct
ORDER BY nb.nav_date DESC, f.fund_name;


-- -----------------------------------------------------------------------------
-- 7. SUMMARY REPORT OF ALL VALIDATION ISSUES
-- -----------------------------------------------------------------------------
-- Consolidated view of all issue types found across the validation checks.
-- This summary is intended for the daily NAV oversight meeting and for
-- inclusion in the fund governance board pack.

-- 7a. Count of issues by type and fund
SELECT
    issue_type,
    fund_name,
    isin,
    COUNT(*) AS issue_count
FROM (
    -- Missing NAV dates
    SELECT 'MISSING_NAV' AS issue_type, f.fund_name, f.isin
    FROM funds f
    INNER JOIN (
        SELECT fund_id, business_date
        FROM (
            SELECT af.fund_id, bd.business_date
            FROM funds af
            CROSS JOIN (
                SELECT DISTINCT nav_date AS business_date FROM nav_daily
            ) bd
            WHERE af.status = 'Active'
        ) expected
        LEFT JOIN nav_daily nd
            ON expected.fund_id = nd.fund_id
            AND expected.business_date = nd.nav_date
        WHERE nd.nav_date IS NULL
    ) missing ON f.fund_id = missing.fund_id

    UNION ALL

    -- Duplicate NAV entries
    SELECT 'DUPLICATE_NAV', f.fund_name, f.isin
    FROM nav_daily nd
    INNER JOIN funds f ON nd.fund_id = f.fund_id
    GROUP BY f.fund_name, f.isin, nd.fund_id, nd.nav_date
    HAVING COUNT(*) > 1

    UNION ALL

    -- Stale prices (simplified detection)
    SELECT 'STALE_PRICE', f.fund_name, f.isin
    FROM nav_daily nd
    INNER JOIN funds f ON nd.fund_id = f.fund_id
    INNER JOIN nav_daily nd2
        ON nd.fund_id = nd2.fund_id
        AND nd2.nav_date = DATEADD(DAY, -1, nd.nav_date)
        AND nd.nav_per_share = nd2.nav_per_share
    INNER JOIN nav_daily nd3
        ON nd.fund_id = nd3.fund_id
        AND nd3.nav_date = DATEADD(DAY, -2, nd.nav_date)
        AND nd.nav_per_share = nd3.nav_per_share

    UNION ALL

    -- Open NAV breaks
    SELECT 'ADMIN_NAV_BREAK', f.fund_name, f.isin
    FROM nav_breaks nb
    INNER JOIN funds f ON nb.fund_id = f.fund_id
    WHERE nb.break_status = 'Open'
) all_issues
GROUP BY issue_type, fund_name, isin
ORDER BY issue_type, fund_name;

-- 7b. High-level summary for governance reporting
SELECT
    issue_type,
    COUNT(*) AS total_issues,
    COUNT(DISTINCT fund_name) AS funds_affected
FROM (
    SELECT 'MISSING_NAV' AS issue_type, f.fund_name
    FROM funds f
    WHERE f.status = 'Active'
      AND EXISTS (
          SELECT 1 FROM nav_daily nd2
          WHERE nd2.fund_id <> f.fund_id
            AND nd2.nav_date NOT IN (
                SELECT nav_date FROM nav_daily WHERE fund_id = f.fund_id
            )
      )

    UNION ALL

    SELECT 'DUPLICATE_NAV', f.fund_name
    FROM nav_daily nd
    INNER JOIN funds f ON nd.fund_id = f.fund_id
    GROUP BY f.fund_name, nd.fund_id, nd.nav_date
    HAVING COUNT(*) > 1

    UNION ALL

    SELECT 'OPEN_NAV_BREAK', f.fund_name
    FROM nav_breaks nb
    INNER JOIN funds f ON nb.fund_id = f.fund_id
    WHERE nb.break_status = 'Open'
) summary
GROUP BY issue_type
ORDER BY total_issues DESC;

-- =============================================================================
-- END OF NAV VALIDATION SCRIPT
-- =============================================================================
