-- =============================================================================
-- Fee Reconciliation Queries
-- Capital Management Co. - Fund Governance Simulation
-- =============================================================================
-- Purpose: Reconcile management fees, performance fees, and other charges
--          against prospectus rates and administrator calculations. These
--          queries form part of the quarterly fee oversight process
--          conducted by the fund board.
--
-- Fund Universe:
--   Global Equity Fund              | IE00B4X9L533
--   European Bond Fund              | IE00BK5BQ103
--   Multi-Asset Growth Fund         | LU0292097234
--   Emerging Markets Fund           | IE00BFYN9Y00
--   Real Estate Opportunities       | LU0488316133
--   Private Credit Fund             | LU0629460675
--
-- Tables Referenced: funds, nav_daily, fees, fee_payments
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. MANAGEMENT FEE ACCRUAL VS EXPECTED (NAV * RATE / 365)
-- -----------------------------------------------------------------------------
-- Management fees accrue daily based on the fund's total net assets and
-- the contractual fee rate. This query compares the recorded daily accrual
-- against the expected amount calculated as: TNA * annual_rate / 365.
-- Variances may indicate a rate change that was not reflected, or a
-- calculation error in the administrator's system.

SELECT
    f.fund_id,
    f.fund_name,
    f.isin,
    fe.fee_type,
    fe.fee_rate_annual,
    nd.nav_date,
    nd.total_net_assets,
    fe.daily_accrual AS recorded_accrual,
    ROUND(nd.total_net_assets * fe.fee_rate_annual / 365.0, 2) AS expected_accrual,
    fe.daily_accrual - ROUND(nd.total_net_assets * fe.fee_rate_annual / 365.0, 2)
        AS accrual_variance,
    CASE
        WHEN ROUND(nd.total_net_assets * fe.fee_rate_annual / 365.0, 2) <> 0
        THEN ROUND(
            (fe.daily_accrual - ROUND(nd.total_net_assets * fe.fee_rate_annual / 365.0, 2))
            / ROUND(nd.total_net_assets * fe.fee_rate_annual / 365.0, 2) * 100.0,
            4
        )
        ELSE NULL
    END AS variance_pct
FROM fees fe
INNER JOIN funds f ON fe.fund_id = f.fund_id
INNER JOIN nav_daily nd
    ON fe.fund_id = nd.fund_id
    AND fe.accrual_date = nd.nav_date
WHERE fe.fee_type = 'Management Fee'
  AND ABS(
      fe.daily_accrual - ROUND(nd.total_net_assets * fe.fee_rate_annual / 365.0, 2)
  ) > 1.00  -- Flag variances greater than 1.00 in base currency
ORDER BY ABS(
    fe.daily_accrual - ROUND(nd.total_net_assets * fe.fee_rate_annual / 365.0, 2)
) DESC;


-- -----------------------------------------------------------------------------
-- 2. PERFORMANCE FEE CRYSTALLISATION CHECK
-- -----------------------------------------------------------------------------
-- Performance fees crystallise at defined intervals (typically annually or
-- at the fund's financial year end). This query validates that the
-- crystallisation amount aligns with the performance above the high-water
-- mark and the contractual performance fee rate.

SELECT
    f.fund_id,
    f.fund_name,
    f.isin,
    fe.fee_type,
    fe.accrual_date AS crystallisation_date,
    fe.high_water_mark,
    fe.nav_at_crystallisation,
    fe.performance_above_hwm,
    fe.fee_rate_annual AS performance_fee_rate,
    fe.crystallised_amount AS recorded_perf_fee,
    ROUND(
        fe.performance_above_hwm * fe.fee_rate_annual * fe.eligible_assets,
        2
    ) AS expected_perf_fee,
    fe.crystallised_amount - ROUND(
        fe.performance_above_hwm * fe.fee_rate_annual * fe.eligible_assets,
        2
    ) AS crystallisation_variance,
    fe.eligible_assets,
    fe.share_class
FROM fees fe
INNER JOIN funds f ON fe.fund_id = f.fund_id
WHERE fe.fee_type = 'Performance Fee'
  AND fe.crystallised_amount IS NOT NULL
ORDER BY fe.accrual_date DESC, f.fund_name;


-- -----------------------------------------------------------------------------
-- 3. FEE PAYMENTS VS ACCRUALS RECONCILIATION
-- -----------------------------------------------------------------------------
-- Fee payments should match the cumulative accruals for the payment period.
-- This query reconciles actual payments made to the investment manager
-- against the sum of daily accruals, highlighting any discrepancies.

WITH accrual_totals AS (
    SELECT
        fe.fund_id,
        fe.fee_type,
        fe.share_class,
        fp.payment_period_start,
        fp.payment_period_end,
        SUM(fe.daily_accrual) AS total_accrued
    FROM fees fe
    INNER JOIN fee_payments fp
        ON fe.fund_id = fp.fund_id
        AND fe.fee_type = fp.fee_type
        AND fe.share_class = fp.share_class
        AND fe.accrual_date BETWEEN fp.payment_period_start AND fp.payment_period_end
    GROUP BY fe.fund_id, fe.fee_type, fe.share_class,
             fp.payment_period_start, fp.payment_period_end
)

SELECT
    f.fund_name,
    f.isin,
    fp.fee_type,
    fp.share_class,
    fp.payment_period_start,
    fp.payment_period_end,
    fp.payment_date,
    fp.payment_amount,
    at.total_accrued,
    fp.payment_amount - at.total_accrued AS payment_vs_accrual_diff,
    CASE
        WHEN at.total_accrued <> 0
        THEN ROUND(
            (fp.payment_amount - at.total_accrued) / at.total_accrued * 100.0,
            4
        )
        ELSE NULL
    END AS diff_pct,
    CASE
        WHEN ABS(fp.payment_amount - at.total_accrued) > 100
        THEN 'INVESTIGATE'
        WHEN ABS(fp.payment_amount - at.total_accrued) > 10
        THEN 'REVIEW'
        ELSE 'OK'
    END AS reconciliation_status
FROM fee_payments fp
INNER JOIN funds f ON fp.fund_id = f.fund_id
INNER JOIN accrual_totals at
    ON fp.fund_id = at.fund_id
    AND fp.fee_type = at.fee_type
    AND fp.share_class = at.share_class
    AND fp.payment_period_start = at.payment_period_start
    AND fp.payment_period_end = at.payment_period_end
ORDER BY ABS(fp.payment_amount - at.total_accrued) DESC;


-- -----------------------------------------------------------------------------
-- 4. FEE RATE VS PROSPECTUS RATE VALIDATION
-- -----------------------------------------------------------------------------
-- The fee rate applied in daily accrual calculations must match the rate
-- disclosed in the fund prospectus. This query compares the rate used in
-- the fees table against the prospectus-defined rate stored in the funds
-- table. Any mismatch is a compliance issue requiring immediate attention.

SELECT
    f.fund_id,
    f.fund_name,
    f.isin,
    fe.fee_type,
    fe.share_class,
    fe.fee_rate_annual AS applied_rate,
    f.prospectus_mgmt_fee_rate AS prospectus_rate,
    fe.fee_rate_annual - f.prospectus_mgmt_fee_rate AS rate_difference,
    CASE
        WHEN fe.fee_rate_annual <> f.prospectus_mgmt_fee_rate
        THEN 'MISMATCH - COMPLIANCE ISSUE'
        ELSE 'OK'
    END AS validation_status,
    fe.effective_from,
    fe.effective_to
FROM fees fe
INNER JOIN funds f ON fe.fund_id = f.fund_id
WHERE fe.fee_type = 'Management Fee'
  AND fe.accrual_date = (
      SELECT MAX(fe2.accrual_date)
      FROM fees fe2
      WHERE fe2.fund_id = fe.fund_id
        AND fe2.fee_type = fe.fee_type
        AND fe2.share_class = fe.share_class
  )
ORDER BY
    CASE WHEN fe.fee_rate_annual <> f.prospectus_mgmt_fee_rate THEN 0 ELSE 1 END,
    f.fund_name;


-- -----------------------------------------------------------------------------
-- 5. YEAR-END FEE SUMMARY PER FUND AND SHARE CLASS
-- -----------------------------------------------------------------------------
-- Provides a complete summary of fees accrued and paid for each fund and
-- share class during the financial year. This is a key input to the annual
-- financial statements and is reviewed by the auditors.

DECLARE @fiscal_year_start DATE = '2025-01-01';
DECLARE @fiscal_year_end   DATE = '2025-12-31';

SELECT
    f.fund_name,
    f.isin,
    fe.share_class,
    fe.fee_type,
    fe.fee_rate_annual,
    COUNT(fe.accrual_date) AS accrual_days,
    ROUND(SUM(fe.daily_accrual), 2) AS total_accrued,
    ISNULL(
        (SELECT SUM(fp.payment_amount)
         FROM fee_payments fp
         WHERE fp.fund_id = fe.fund_id
           AND fp.fee_type = fe.fee_type
           AND fp.share_class = fe.share_class
           AND fp.payment_date BETWEEN @fiscal_year_start AND @fiscal_year_end),
        0
    ) AS total_paid,
    ROUND(SUM(fe.daily_accrual), 2) -
    ISNULL(
        (SELECT SUM(fp.payment_amount)
         FROM fee_payments fp
         WHERE fp.fund_id = fe.fund_id
           AND fp.fee_type = fe.fee_type
           AND fp.share_class = fe.share_class
           AND fp.payment_date BETWEEN @fiscal_year_start AND @fiscal_year_end),
        0
    ) AS outstanding_accrual,
    MIN(fe.accrual_date) AS first_accrual_date,
    MAX(fe.accrual_date) AS last_accrual_date
FROM fees fe
INNER JOIN funds f ON fe.fund_id = f.fund_id
WHERE fe.accrual_date BETWEEN @fiscal_year_start AND @fiscal_year_end
GROUP BY f.fund_name, f.isin, fe.fund_id, fe.share_class,
         fe.fee_type, fe.fee_rate_annual
ORDER BY f.fund_name, fe.share_class, fe.fee_type;


-- -----------------------------------------------------------------------------
-- 6. FEE TREND ANALYSIS (MONTHLY ACCRUALS OVER 12 MONTHS)
-- -----------------------------------------------------------------------------
-- Shows the monthly progression of fee accruals for each fund over the
-- trailing 12 months. This trend analysis helps the board identify
-- unexpected changes in fee levels that may correlate with AUM movements,
-- rate changes, or calculation errors.

SELECT
    f.fund_name,
    f.isin,
    fe.fee_type,
    fe.share_class,
    YEAR(fe.accrual_date) AS accrual_year,
    MONTH(fe.accrual_date) AS accrual_month,
    FORMAT(fe.accrual_date, 'yyyy-MM') AS period,
    COUNT(fe.accrual_date) AS accrual_days,
    ROUND(SUM(fe.daily_accrual), 2) AS monthly_accrual,
    ROUND(AVG(fe.daily_accrual), 2) AS avg_daily_accrual,
    -- Month-over-month change
    ROUND(
        SUM(fe.daily_accrual) - LAG(SUM(fe.daily_accrual)) OVER (
            PARTITION BY fe.fund_id, fe.fee_type, fe.share_class
            ORDER BY YEAR(fe.accrual_date), MONTH(fe.accrual_date)
        ),
        2
    ) AS mom_change,
    CASE
        WHEN LAG(SUM(fe.daily_accrual)) OVER (
            PARTITION BY fe.fund_id, fe.fee_type, fe.share_class
            ORDER BY YEAR(fe.accrual_date), MONTH(fe.accrual_date)
        ) <> 0
        THEN ROUND(
            (SUM(fe.daily_accrual) - LAG(SUM(fe.daily_accrual)) OVER (
                PARTITION BY fe.fund_id, fe.fee_type, fe.share_class
                ORDER BY YEAR(fe.accrual_date), MONTH(fe.accrual_date)
            )) / LAG(SUM(fe.daily_accrual)) OVER (
                PARTITION BY fe.fund_id, fe.fee_type, fe.share_class
                ORDER BY YEAR(fe.accrual_date), MONTH(fe.accrual_date)
            ) * 100.0,
            2
        )
        ELSE NULL
    END AS mom_change_pct
FROM fees fe
INNER JOIN funds f ON fe.fund_id = f.fund_id
WHERE fe.accrual_date >= DATEADD(MONTH, -12, GETDATE())
GROUP BY f.fund_name, f.isin, fe.fund_id, fe.fee_type, fe.share_class,
         YEAR(fe.accrual_date), MONTH(fe.accrual_date),
         FORMAT(fe.accrual_date, 'yyyy-MM')
ORDER BY f.fund_name, fe.fee_type, fe.share_class, accrual_year, accrual_month;

-- =============================================================================
-- END OF FEE RECONCILIATION SCRIPT
-- =============================================================================
