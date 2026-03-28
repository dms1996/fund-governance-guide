-- =============================================================================
-- Capital Management Co. - Fee Calculation Validation Queries
-- Purpose: Validate management fees, performance fees, and reconcile payments
-- Author: CMC Fund Accounting & Compliance
-- Last Updated: 2026-03-28
-- =============================================================================


-- =============================================================================
-- 1. MANAGEMENT FEE ACCRUAL VERIFICATION
-- Recalculate expected accruals and compare to recorded amounts
-- =============================================================================

SELECT
    mf.Fund_Name,
    mf.ISIN,
    mf.Share_Class,
    mf.Fee_Type,
    mf.Annual_Rate_Pct,
    mf.Avg_NAV_EUR,
    mf.Period_Start,
    mf.Period_End,
    -- Calculate expected accrual: (Avg NAV * Annual Rate / 100) * (days in period / 365)
    ROUND(
        (mf.Avg_NAV_EUR * mf.Annual_Rate_Pct / 100.0)
        * (DATEDIFF(day, mf.Period_Start, mf.Period_End) / 365.0),
        2
    ) AS Expected_Accrual_EUR,
    mf.Accrued_Fee_EUR AS Recorded_Accrual_EUR,
    ROUND(
        mf.Accrued_Fee_EUR - (
            (mf.Avg_NAV_EUR * mf.Annual_Rate_Pct / 100.0)
            * (DATEDIFF(day, mf.Period_Start, mf.Period_End) / 365.0)
        ),
        2
    ) AS Variance_EUR,
    CASE
        WHEN ABS(
            mf.Accrued_Fee_EUR - (
                (mf.Avg_NAV_EUR * mf.Annual_Rate_Pct / 100.0)
                * (DATEDIFF(day, mf.Period_Start, mf.Period_End) / 365.0)
            )
        ) > 100 THEN 'INVESTIGATE'
        ELSE 'OK'
    END AS Validation_Status
FROM management_fees mf
ORDER BY mf.Fund_Name, mf.Share_Class, mf.Fee_Type;


-- =============================================================================
-- 2. PERFORMANCE FEE HIGH-WATER MARK VALIDATION
-- Ensure performance fees are only accrued when NAV exceeds HWM
-- =============================================================================

SELECT
    pf.Fund_Name,
    pf.ISIN,
    pf.Share_Class,
    pf.Performance_Fee_Rate_Pct,
    pf.HWM_Per_Share,
    pf.Current_NAV_Per_Share,
    pf.Outperformance_Pct,
    pf.Accrued_Fee_EUR,
    -- Validate: no fee should accrue if current NAV is below HWM
    CASE
        WHEN pf.Current_NAV_Per_Share < pf.HWM_Per_Share
            AND pf.Accrued_Fee_EUR > 0
            THEN 'FAIL - Fee accrued below HWM'
        WHEN pf.Current_NAV_Per_Share >= pf.HWM_Per_Share
            AND pf.Outperformance_Pct <= 0
            AND pf.Accrued_Fee_EUR > 0
            THEN 'FAIL - Fee accrued without outperformance'
        WHEN pf.Current_NAV_Per_Share < pf.HWM_Per_Share
            AND pf.Accrued_Fee_EUR = 0
            THEN 'PASS - Correctly not accruing (below HWM)'
        WHEN pf.Outperformance_Pct > 0
            AND pf.Accrued_Fee_EUR > 0
            THEN 'PASS - Correctly accruing (above HWM with outperformance)'
        ELSE 'REVIEW'
    END AS HWM_Validation,
    pf.Status
FROM performance_fees pf
ORDER BY pf.Fund_Name, pf.Share_Class;


-- =============================================================================
-- 3. FEE RATE VS PROSPECTUS RATE COMPARISON
-- Cross-reference applied fee rates against prospectus-permitted maximums
-- =============================================================================

WITH prospectus_rates AS (
    SELECT 'Global Equity Fund' AS Fund_Name, 'Institutional' AS Share_Class, 'Management Fee' AS Fee_Type, 0.75 AS Max_Rate_Pct
    UNION ALL SELECT 'Global Equity Fund', 'Retail', 'Management Fee', 1.50
    UNION ALL SELECT 'European Bond Fund', 'Institutional', 'Management Fee', 0.60
    UNION ALL SELECT 'European Bond Fund', 'Retail', 'Management Fee', 1.20
    UNION ALL SELECT 'Multi-Asset Growth Fund', 'Institutional', 'Management Fee', 1.00
    UNION ALL SELECT 'Multi-Asset Growth Fund', 'Retail', 'Management Fee', 1.75
    UNION ALL SELECT 'Emerging Markets Fund', 'Institutional', 'Management Fee', 1.25
    UNION ALL SELECT 'Emerging Markets Fund', 'Retail', 'Management Fee', 2.00
    UNION ALL SELECT 'Real Estate Opportunities Fund', 'Institutional', 'Management Fee', 1.50
    UNION ALL SELECT 'Private Credit Fund', 'Institutional', 'Management Fee', 1.75
)
SELECT
    mf.Fund_Name,
    mf.Share_Class,
    mf.Fee_Type,
    mf.Annual_Rate_Pct AS Applied_Rate_Pct,
    pr.Max_Rate_Pct AS Prospectus_Max_Rate_Pct,
    CASE
        WHEN mf.Annual_Rate_Pct > pr.Max_Rate_Pct
            THEN 'BREACH - Rate exceeds prospectus maximum'
        WHEN mf.Annual_Rate_Pct = pr.Max_Rate_Pct
            THEN 'AT MAXIMUM - Review recommended'
        ELSE 'OK - Within prospectus limit'
    END AS Rate_Validation
FROM management_fees mf
INNER JOIN prospectus_rates pr
    ON mf.Fund_Name = pr.Fund_Name
    AND mf.Share_Class = pr.Share_Class
    AND mf.Fee_Type = pr.Fee_Type
ORDER BY mf.Fund_Name, mf.Share_Class;


-- =============================================================================
-- 4. FEE PAYMENT RECONCILIATION
-- Verify paid amounts against accruals and identify outstanding balances
-- =============================================================================

SELECT
    mf.Fund_Name,
    mf.ISIN,
    mf.Share_Class,
    mf.Fee_Type,
    mf.Period_Start,
    mf.Period_End,
    mf.Accrued_Fee_EUR,
    mf.Paid_Fee_EUR,
    (mf.Accrued_Fee_EUR - mf.Paid_Fee_EUR) AS Outstanding_EUR,
    ROUND(
        (mf.Paid_Fee_EUR / NULLIF(mf.Accrued_Fee_EUR, 0)) * 100, 2
    ) AS Pct_Paid,
    mf.Payment_Date,
    mf.Status,
    CASE
        WHEN mf.Accrued_Fee_EUR = mf.Paid_Fee_EUR THEN 'Fully Reconciled'
        WHEN mf.Paid_Fee_EUR = 0 THEN 'No Payment - Investigate'
        WHEN mf.Status = 'Partially Paid'
            AND mf.Period_End > GETDATE()
            THEN 'In Period - Expected'
        WHEN mf.Status = 'Partially Paid'
            AND mf.Period_End <= GETDATE()
            THEN 'Period Ended - Outstanding Balance'
        ELSE 'Review Required'
    END AS Reconciliation_Status
FROM management_fees mf
ORDER BY mf.Fund_Name, mf.Fee_Type, mf.Share_Class;


-- =============================================================================
-- 5. YEAR-END FEE SUMMARY BY FUND
-- Aggregate fees across all share classes and fee types per fund
-- =============================================================================

SELECT
    mf.Fund_Name,
    mf.ISIN,
    mf.Fee_Type,
    COUNT(DISTINCT mf.Share_Class) AS Num_Share_Classes,
    SUM(mf.Avg_NAV_EUR) AS Total_Avg_NAV_EUR,
    SUM(mf.Accrued_Fee_EUR) AS Total_Accrued_EUR,
    SUM(mf.Paid_Fee_EUR) AS Total_Paid_EUR,
    SUM(mf.Accrued_Fee_EUR) - SUM(mf.Paid_Fee_EUR) AS Total_Outstanding_EUR,
    -- Effective fee rate (weighted across share classes)
    ROUND(
        SUM(mf.Accrued_Fee_EUR) / NULLIF(SUM(mf.Avg_NAV_EUR), 0) * 100
        * (365.0 / DATEDIFF(day, MIN(mf.Period_Start), MAX(mf.Period_End))),
        4
    ) AS Effective_Annual_Rate_Pct
FROM management_fees mf
GROUP BY mf.Fund_Name, mf.ISIN, mf.Fee_Type
ORDER BY mf.Fund_Name, mf.Fee_Type;


-- =============================================================================
-- 6. COMBINED FEE BURDEN ANALYSIS (TER APPROXIMATION)
-- Estimate total expense ratio per fund for board reporting
-- =============================================================================

SELECT
    mf.Fund_Name,
    mf.ISIN,
    mf.Share_Class,
    SUM(mf.Avg_NAV_EUR) AS Avg_NAV_EUR,
    SUM(mf.Accrued_Fee_EUR) AS Total_Fees_Accrued_EUR,
    COALESCE(pf.Accrued_Fee_EUR, 0) AS Performance_Fee_Accrued_EUR,
    SUM(mf.Accrued_Fee_EUR) + COALESCE(pf.Accrued_Fee_EUR, 0) AS Total_Cost_EUR,
    ROUND(
        (SUM(mf.Accrued_Fee_EUR) + COALESCE(pf.Accrued_Fee_EUR, 0))
        / NULLIF(MAX(mf.Avg_NAV_EUR), 0) * 100
        * (365.0 / DATEDIFF(day, MIN(mf.Period_Start), MAX(mf.Period_End))),
        4
    ) AS Estimated_TER_Pct
FROM management_fees mf
LEFT JOIN performance_fees pf
    ON mf.Fund_Name = pf.Fund_Name
    AND mf.ISIN = pf.ISIN
    AND mf.Share_Class = pf.Share_Class
GROUP BY
    mf.Fund_Name,
    mf.ISIN,
    mf.Share_Class,
    pf.Accrued_Fee_EUR
ORDER BY mf.Fund_Name, mf.Share_Class;


-- =============================================================================
-- 7. PERFORMANCE FEE CRYSTALLISATION CHECK
-- Identify funds approaching crystallisation date with accrued performance fees
-- =============================================================================

SELECT
    pf.Fund_Name,
    pf.ISIN,
    pf.Share_Class,
    pf.Crystallisation_Date,
    DATEDIFF(day, GETDATE(), pf.Crystallisation_Date) AS Days_To_Crystallisation,
    pf.Performance_Fee_Rate_Pct,
    pf.HWM_Per_Share,
    pf.Current_NAV_Per_Share,
    pf.Outperformance_Pct,
    pf.Accrued_Fee_EUR,
    pf.Crystallised_Fee_EUR,
    pf.Status,
    CASE
        WHEN DATEDIFF(day, GETDATE(), pf.Crystallisation_Date) <= 30
            AND pf.Accrued_Fee_EUR > 0
            THEN 'APPROACHING - Prepare for crystallisation'
        WHEN DATEDIFF(day, GETDATE(), pf.Crystallisation_Date) <= 90
            AND pf.Accrued_Fee_EUR > 0
            THEN 'MONITOR - Crystallisation within 90 days'
        WHEN pf.Accrued_Fee_EUR = 0
            THEN 'NO ACCRUAL - No action required'
        ELSE 'STANDARD MONITORING'
    END AS Action_Required
FROM performance_fees pf
ORDER BY pf.Crystallisation_Date, pf.Fund_Name;
