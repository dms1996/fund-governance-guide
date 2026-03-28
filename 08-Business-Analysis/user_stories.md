# User Stories: NAV Reconciliation Automation Project

**Project**: NAV Reconciliation Automation
**Version**: 1.0
**Date**: 2025-09-15
**Author**: Business Analysis Team, Capital Management Co.

---

## US-001: Automated Administrator Data Ingestion

**As a** Fund Accounting Analyst,
**I want** the system to automatically retrieve daily NAV files from each fund administrator's SFTP server at scheduled times,
**So that** I no longer need to manually download files each morning, reducing the risk of delays and human error.

**Acceptance Criteria:**
- System connects to Fund Admin A and Fund Admin B SFTP servers using pre-configured credentials.
- Files are retrieved automatically by 09:00 CET each business day.
- System supports CSV, XML, and SWIFT MT940 file formats.
- A notification is displayed on the dashboard confirming successful ingestion with file name, timestamp, and record count.
- If a file is missing or retrieval fails, an alert is sent to the Fund Accounting team within 5 minutes.

**Priority:** Must Have | **Story Points:** 8

---

## US-002: Automated Internal Data Extraction

**As a** Fund Accounting Analyst,
**I want** the system to automatically extract NAV and position data from our Fund Accounting System accounting platform via API,
**So that** internal data is available for reconciliation without manual export steps.

**Acceptance Criteria:**
- System calls the Fund Accounting System REST API on a configurable schedule (default 08:00 CET).
- Extracted data includes fund-level NAV, share class NAV per unit, total shares outstanding, and top-level position data for all six funds.
- Extraction completes within 10 minutes.
- Extraction failures are logged and trigger an alert to IT Support and Fund Accounting.
- Data is stored in a staging area pending reconciliation.

**Priority:** Must Have | **Story Points:** 8

---

## US-003: Data Quality Validation

**As a** Fund Accounting Team Lead,
**I want** all ingested data to be validated against predefined quality rules before reconciliation begins,
**So that** I can be confident that reconciliation results are based on complete and reasonable data.

**Acceptance Criteria:**
- Mandatory fields (Fund Name, ISIN, NAV Date, NAV per Share, Total NAV) are checked for completeness.
- NAV values are checked against the previous business day; deviations beyond +/- 10% are flagged as warnings.
- Duplicate records (same fund, same date) are detected and rejected.
- Validation results are visible on the dashboard with pass/fail status per fund.
- Failed validation items are logged in the audit trail with reason codes.

**Priority:** Must Have | **Story Points:** 5

---

## US-004: Configurable Tolerance Thresholds

**As a** Head of Fund Operations,
**I want** to configure reconciliation tolerance thresholds per fund and per data element, with changes requiring dual authorisation,
**So that** the reconciliation sensitivity is appropriate for each fund and all changes are controlled.

**Acceptance Criteria:**
- Tolerances can be set as absolute EUR values or as percentage thresholds.
- Default tolerances are pre-set: 0.01% for NAV per share, 0.05% for total NAV, EUR 500 for cash balances.
- Changing a tolerance requires a request from one authorised user and approval from a second.
- All tolerance changes are logged in the audit trail with old value, new value, requestor, and approver.
- Historical tolerance settings are retained and viewable for any past date.

**Priority:** Must Have | **Story Points:** 5

---

## US-005: Automated Break Detection

**As a** Fund Accounting Analyst,
**I want** the system to automatically compare administrator data against internal data and identify breaks by severity,
**So that** I can immediately see which funds have issues requiring my attention.

**Acceptance Criteria:**
- Reconciliation runs automatically once both data sources are successfully ingested and validated.
- Items within tolerance are classified as "Matched."
- Items outside tolerance but below a material threshold are classified as "Warning."
- Items above the material threshold are classified as "Material Break" or "Critical Break."
- Reconciliation for all six funds (Global Equity Fund, European Bond Fund, Multi-Asset Growth Fund, Emerging Markets Fund, Real Estate Opportunities Fund, Private Credit Fund) completes within 15 minutes.
- Results are published to the dashboard immediately upon completion.

**Priority:** Must Have | **Story Points:** 13

---

## US-006: Real-Time Alert Notifications

**As a** Fund Accounting Team Lead,
**I want** to receive immediate alerts when material or critical NAV breaks are detected, routed based on severity and fund assignment,
**So that** I can take corrective action before the NAV is published to investors.

**Acceptance Criteria:**
- Warning-level breaks generate dashboard notifications only.
- Material breaks trigger email alerts to the assigned fund accounting team lead.
- Critical breaks trigger email alerts to the Head of Fund Operations and Head of Compliance, plus SMS to the Head of Fund Operations.
- Each alert includes: fund name, ISIN, NAV date, break amount, percentage deviation, severity classification, and a link to the dashboard detail view.
- Alerts are sent within 2 minutes of break detection.
- Users can configure their alert preferences (email, SMS, dashboard) for each severity level.

**Priority:** Must Have | **Story Points:** 5

---

## US-007: Reconciliation Dashboard

**As a** Fund Accounting Analyst,
**I want** a web-based dashboard showing real-time reconciliation status for all funds with traffic-light indicators,
**So that** I can see the overall picture at a glance and drill down into specific issues.

**Acceptance Criteria:**
- Dashboard home page displays all six funds with Green (matched), Amber (warnings only), or Red (material/critical breaks) status.
- Clicking a fund shows share class level detail with individual match/break status.
- Clicking a share class shows line-item detail including administrator value, internal value, difference, and tolerance applied.
- Dashboard updates automatically as new reconciliation results are produced (no manual refresh required).
- Dashboard is accessible via web browser with single sign-on authentication.
- Dashboard loads within 3 seconds under normal conditions.

**Priority:** Must Have | **Story Points:** 13

---

## US-008: Break Investigation Workflow

**As a** Fund Accounting Analyst,
**I want** to investigate and resolve breaks through a structured workflow with assignment, commentary, and resolution tracking,
**So that** break resolution is documented consistently and nothing falls through the cracks.

**Acceptance Criteria:**
- Breaks can be assigned to a specific analyst for investigation.
- Analysts can add investigation comments and attach supporting documents (e.g., administrator correspondence, pricing evidence).
- Each break resolution requires selection of a root cause category from a predefined list (e.g., pricing difference, FX rate difference, timing difference, administrator error, internal error).
- Breaks unresolved for more than 4 hours trigger an escalation alert to the team lead.
- Breaks unresolved for more than 1 business day trigger escalation to the Head of Fund Operations.
- Resolved breaks are locked from further editing but remain viewable.

**Priority:** Should Have | **Story Points:** 8

---

## US-009: Daily Reconciliation Summary Report

**As a** Head of Fund Operations,
**I want** an automated daily summary report of reconciliation results across all funds,
**So that** I have a single document confirming the status of all NAV reconciliations for that day.

**Acceptance Criteria:**
- Report is auto-generated at a configurable time (default 10:00 CET) each business day.
- Report lists all six funds with: match status, number of breaks by severity, number of open vs. resolved breaks, and overall reconciliation outcome (Pass/Fail).
- Report is available on the dashboard and distributed via email to a configurable recipient list.
- Report is exportable in PDF and Excel formats.
- Report includes a comparison to the previous business day to highlight new or recurring breaks.

**Priority:** Must Have | **Story Points:** 5

---

## US-010: Monthly Management Report

**As a** Head of Fund Operations,
**I want** a monthly reconciliation management report with trend analysis and KPIs,
**So that** I can report to the board on reconciliation control effectiveness and identify systemic issues.

**Acceptance Criteria:**
- Report covers the full calendar month and is generated by the 3rd business day of the following month.
- KPIs include: percentage of days with clean reconciliation per fund, average break resolution time, number of breaks by root cause category, and trend vs. prior months.
- Report includes charts showing break trends over the last 12 months.
- Report is suitable for inclusion in board packs without modification.
- Report is exportable in PDF and PowerPoint formats.

**Priority:** Should Have | **Story Points:** 8

---

## US-011: Comprehensive Audit Trail

**As an** Internal Auditor,
**I want** a complete, immutable audit trail of all reconciliation activities,
**So that** I can verify control effectiveness and provide evidence for regulatory examinations.

**Acceptance Criteria:**
- Every system event is logged: data ingestion, validation, reconciliation execution, break creation, user actions (comments, assignments, resolutions), configuration changes, and report generation.
- Each log entry includes: timestamp (UTC), user ID, action type, affected entity (fund, break ID), and outcome.
- Audit logs cannot be modified or deleted by any user, including system administrators.
- Logs are retained for a minimum of 7 years.
- Audit trail is searchable by date range, user, fund, action type, and entity.
- Audit trail data is exportable in CSV format for offline analysis.

**Priority:** Must Have | **Story Points:** 8

---

## US-012: New Fund Configuration

**As a** System Administrator,
**I want** to onboard a new fund into the reconciliation system through a configuration interface without code changes,
**So that** new funds can be added quickly as the business grows.

**Acceptance Criteria:**
- A configuration screen allows entry of: fund name, ISIN, fund type (UCITS/AIFMD), administrator, data source details, tolerance thresholds, and alert recipients.
- New fund configuration requires approval from the Head of Fund Operations before activation.
- A new fund can be fully configured and operational within 2 business days.
- Test reconciliation can be run for a new fund in a sandbox mode before going live.
- Fund deactivation is supported (soft delete) with all historical data retained.

**Priority:** Should Have | **Story Points:** 5

---

## Summary

| Story ID | Title | Priority | Story Points |
|---|---|---|---|
| US-001 | Automated Administrator Data Ingestion | Must Have | 8 |
| US-002 | Automated Internal Data Extraction | Must Have | 8 |
| US-003 | Data Quality Validation | Must Have | 5 |
| US-004 | Configurable Tolerance Thresholds | Must Have | 5 |
| US-005 | Automated Break Detection | Must Have | 13 |
| US-006 | Real-Time Alert Notifications | Must Have | 5 |
| US-007 | Reconciliation Dashboard | Must Have | 13 |
| US-008 | Break Investigation Workflow | Should Have | 8 |
| US-009 | Daily Reconciliation Summary Report | Must Have | 5 |
| US-010 | Monthly Management Report | Should Have | 8 |
| US-011 | Comprehensive Audit Trail | Must Have | 8 |
| US-012 | New Fund Configuration | Should Have | 5 |
| | **Total** | | **91** |
