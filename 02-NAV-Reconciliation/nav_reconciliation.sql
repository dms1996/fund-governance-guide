-- =============================================================================
-- NAV Reconciliation SQL Scripts
-- Capital Management Co. - Fund Governance Simulation
-- Purpose: Detect and analyse NAV breaks between internal calculations
--          and administrator-reported NAVs
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. DAILY NAV COMPARISON
-- Compare internally calculated NAV against administrator-reported NAV
-- for all funds on a given date.
-- -----------------------------------------------------------------------------

SELECT
    a.nav_date,
    a.fund_name,
    a.isin,
    a.admin_nav_per_share      AS admin_nav,
    i.internal_nav_per_share   AS internal_nav,
    ROUND(a.admin_nav_per_share - i.internal_nav_per_share, 4) AS variance_eur,
    ROUND(
        ABS(a.admin_nav_per_share - i.internal_nav_per_share)
        / a.admin_nav_per_share * 100, 6
    ) AS variance_pct,
    a.shares_outstanding,
    ROUND(
        (a.admin_nav_per_share - i.internal_nav_per_share) * a.shares_outstanding, 2
    ) AS total_nav_impact_eur
FROM admin_nav_report a
INNER JOIN internal_nav_calc i
    ON a.isin = i.isin
    AND a.nav_date = i.nav_date
WHERE a.nav_date = :report_date
ORDER BY ABS(a.admin_nav_per_share - i.internal_nav_per_share) DESC;


-- -----------------------------------------------------------------------------
-- 2. TOLERANCE THRESHOLD CHECK (0.01%)
-- Flag any fund where the NAV variance exceeds the agreed tolerance of
-- 0.01% (1 basis point). Breaches require investigation and escalation.
-- -----------------------------------------------------------------------------

SELECT
    a.nav_date,
    a.fund_name,
    a.isin,
    a.admin_nav_per_share      AS admin_nav,
    i.internal_nav_per_share   AS internal_nav,
    ROUND(
        ABS(a.admin_nav_per_share - i.internal_nav_per_share)
        / a.admin_nav_per_share * 100, 6
    ) AS variance_pct,
    CASE
        WHEN ABS(a.admin_nav_per_share - i.internal_nav_per_share)
             / a.admin_nav_per_share * 100 > 0.05
            THEN 'CRITICAL - Exceeds 5bps'
        WHEN ABS(a.admin_nav_per_share - i.internal_nav_per_share)
             / a.admin_nav_per_share * 100 > 0.01
            THEN 'BREACH - Exceeds 1bp tolerance'
        ELSE 'WITHIN TOLERANCE'
    END AS breach_status
FROM admin_nav_report a
INNER JOIN internal_nav_calc i
    ON a.isin = i.isin
    AND a.nav_date = i.nav_date
WHERE a.nav_date = :report_date
  AND ABS(a.admin_nav_per_share - i.internal_nav_per_share)
      / a.admin_nav_per_share * 100 > 0.01
ORDER BY variance_pct DESC;


-- -----------------------------------------------------------------------------
-- 3. BREAK SUMMARY BY FUND
-- Aggregate break statistics per fund over a specified date range.
-- Useful for board reporting and service provider performance monitoring.
-- -----------------------------------------------------------------------------

SELECT
    a.fund_name,
    a.isin,
    COUNT(*)                                               AS total_nav_days,
    SUM(
        CASE
            WHEN ABS(a.admin_nav_per_share - i.internal_nav_per_share)
                 / a.admin_nav_per_share * 100 > 0.01
            THEN 1 ELSE 0
        END
    )                                                      AS break_count,
    ROUND(
        SUM(
            CASE
                WHEN ABS(a.admin_nav_per_share - i.internal_nav_per_share)
                     / a.admin_nav_per_share * 100 > 0.01
                THEN 1 ELSE 0
            END
        ) * 100.0 / COUNT(*), 2
    )                                                      AS break_rate_pct,
    ROUND(MAX(
        ABS(a.admin_nav_per_share - i.internal_nav_per_share)
        / a.admin_nav_per_share * 100
    ), 6)                                                  AS max_variance_pct,
    ROUND(AVG(
        ABS(a.admin_nav_per_share - i.internal_nav_per_share)
        / a.admin_nav_per_share * 100
    ), 6)                                                  AS avg_variance_pct
FROM admin_nav_report a
INNER JOIN internal_nav_calc i
    ON a.isin = i.isin
    AND a.nav_date = i.nav_date
WHERE a.nav_date BETWEEN :start_date AND :end_date
GROUP BY a.fund_name, a.isin
ORDER BY break_count DESC;


-- -----------------------------------------------------------------------------
-- 4. UNRESOLVED BREAKS REPORT
-- List all NAV breaks that have been logged but not yet resolved.
-- This report is reviewed daily by the Operations team and escalated
-- to the ManCo Designated Person if breaks remain open > 2 business days.
-- -----------------------------------------------------------------------------

SELECT
    b.break_id,
    b.break_date,
    b.fund_name,
    b.isin,
    b.break_type,
    b.expected_nav,
    b.calculated_nav,
    b.variance_eur,
    b.variance_pct,
    b.root_cause,
    b.assigned_to,
    DATEDIFF(DAY, b.break_date, GETDATE())                AS days_open,
    CASE
        WHEN DATEDIFF(DAY, b.break_date, GETDATE()) > 5
            THEN 'ESCALATE TO BOARD'
        WHEN DATEDIFF(DAY, b.break_date, GETDATE()) > 2
            THEN 'ESCALATE TO DESIGNATED PERSON'
        ELSE 'WITHIN SLA'
    END AS escalation_status
FROM nav_breaks_log b
WHERE b.status = 'Open'
ORDER BY b.break_date ASC, b.variance_pct DESC;


-- -----------------------------------------------------------------------------
-- 5. TREND ANALYSIS
-- Analyse NAV break frequency and magnitude over time to identify
-- systemic issues (e.g., recurring pricing source problems, FX feed
-- failures). Results feed into quarterly ManCo risk reports.
-- -----------------------------------------------------------------------------

-- 5a. Monthly break trend
SELECT
    FORMAT(b.break_date, 'yyyy-MM')                        AS break_month,
    COUNT(*)                                               AS total_breaks,
    SUM(CASE WHEN b.break_type = 'Pricing Error'          THEN 1 ELSE 0 END) AS pricing_errors,
    SUM(CASE WHEN b.break_type = 'FX Rate Mismatch'       THEN 1 ELSE 0 END) AS fx_mismatches,
    SUM(CASE WHEN b.break_type = 'Corporate Action Miss'  THEN 1 ELSE 0 END) AS corp_action_misses,
    SUM(CASE WHEN b.break_type = 'Trade Settlement Failure' THEN 1 ELSE 0 END) AS settlement_failures,
    SUM(CASE WHEN b.break_type = 'Valuation Dispute'      THEN 1 ELSE 0 END) AS valuation_disputes,
    SUM(CASE WHEN b.break_type = 'Accrual Error'          THEN 1 ELSE 0 END) AS accrual_errors,
    SUM(CASE WHEN b.break_type = 'Cash Reconciliation Break' THEN 1 ELSE 0 END) AS cash_breaks,
    ROUND(AVG(b.variance_pct), 4)                          AS avg_variance_pct,
    ROUND(MAX(b.variance_pct), 4)                          AS max_variance_pct
FROM nav_breaks_log b
WHERE b.break_date BETWEEN :start_date AND :end_date
GROUP BY FORMAT(b.break_date, 'yyyy-MM')
ORDER BY break_month;

-- 5b. Break resolution time analysis
SELECT
    b.fund_name,
    b.break_type,
    COUNT(*)                                               AS total_breaks,
    ROUND(AVG(
        DATEDIFF(DAY, b.break_date, b.resolution_date)
    ), 1)                                                  AS avg_resolution_days,
    MAX(DATEDIFF(DAY, b.break_date, b.resolution_date))   AS max_resolution_days,
    SUM(
        CASE
            WHEN DATEDIFF(DAY, b.break_date, b.resolution_date) > 2
            THEN 1 ELSE 0
        END
    )                                                      AS breached_sla_count
FROM nav_breaks_log b
WHERE b.status = 'Resolved'
  AND b.break_date BETWEEN :start_date AND :end_date
GROUP BY b.fund_name, b.break_type
ORDER BY avg_resolution_days DESC;

-- 5c. Repeat offender analysis - identify funds with recurring break types
SELECT
    b.fund_name,
    b.isin,
    b.break_type,
    COUNT(*)                                               AS occurrence_count,
    MIN(b.break_date)                                      AS first_occurrence,
    MAX(b.break_date)                                      AS last_occurrence,
    ROUND(AVG(b.variance_pct), 4)                          AS avg_variance_pct
FROM nav_breaks_log b
WHERE b.break_date BETWEEN :start_date AND :end_date
GROUP BY b.fund_name, b.isin, b.break_type
HAVING COUNT(*) >= 2
ORDER BY occurrence_count DESC;
