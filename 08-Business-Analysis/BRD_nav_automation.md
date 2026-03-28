# Business Requirements Document: NAV Reconciliation Automation Project

---

## 1. Document Control

| Field | Detail |
|---|---|
| Document Title | BRD - NAV Reconciliation Automation Project |
| Version | 1.0 |
| Author | Business Analysis Team, Capital Management Co. |
| Date | 2025-09-15 |
| Status | Draft for Approval |
| Classification | Internal - Confidential |

### Approvers

| Name | Role | Date | Signature |
|---|---|---|---|
| Head of Fund Operations | Head of Fund Operations | Pending | |
| Chief Technology Officer | Chief Technology Officer | Pending | |
| Head of Compliance | Head of Compliance | Pending | |
| Chief Risk Officer | Chief Risk Officer | Pending | |

### Version History

| Version | Date | Author | Changes |
|---|---|---|---|
| 0.1 | 2025-08-01 | BA Team | Initial draft |
| 0.2 | 2025-08-20 | BA Team | Incorporated stakeholder feedback |
| 0.3 | 2025-09-05 | BA Team | Added data flow diagrams and acceptance criteria |
| 1.0 | 2025-09-15 | BA Team | Final draft for approval |

---

## 2. Executive Summary

Capital Management Co. currently performs daily NAV reconciliation manually across six funds, consuming approximately three hours of skilled staff time per day and introducing the risk of undetected errors or delayed identification of NAV breaks. This project proposes automating the end-to-end NAV reconciliation process, from data ingestion through to break detection, alerting, and reporting. The solution will reduce manual effort by at least 80%, enable real-time break detection, and provide a complete audit trail for regulatory and board reporting purposes.

---

## 3. Business Context and Problem Statement

### 3.1 Background

Capital Management Co. manages six funds across UCITS and AIFMD structures:

- Global Equity Fund (IE00B4X9L533) - UCITS
- European Bond Fund (IE00BK5BQ103) - UCITS
- Multi-Asset Growth Fund (LU0292097234) - UCITS
- Emerging Markets Fund (IE00BFYN9Y00) - UCITS
- Real Estate Opportunities Fund (LU0488316133) - AIFMD
- Private Credit Fund (LU0629460675) - AIFMD

NAV reconciliation is a critical daily control ensuring that the NAV calculated by the fund administrator matches the NAV derived from internal records. This process is fundamental to investor protection and regulatory compliance.

### 3.2 Problem Statement

The current manual NAV reconciliation process presents the following challenges:

1. **Time-intensive**: Reconciling all six funds takes approximately three hours each business day, performed by senior fund accounting staff.
2. **Error-prone**: Manual comparison of spreadsheets across multiple data sources leads to approximately 5-8 undetected discrepancies per quarter, some of which are only caught during month-end reviews.
3. **Delayed detection**: NAV breaks are typically identified 4-6 hours after the administrator publishes the NAV, reducing the window for corrective action.
4. **Inconsistent documentation**: Manual reconciliation records vary in format and completeness, making audit evidence preparation time-consuming.
5. **Key-person dependency**: Only two staff members are fully trained on the end-to-end process, creating operational risk.
6. **Scaling limitations**: The current process cannot absorb additional funds without proportional headcount increases.

---

## 4. Objectives

| Objective ID | Objective | Success Metric |
|---|---|---|
| OBJ-001 | Reduce manual reconciliation effort by at least 80% | Staff time reduced from 3 hours to under 36 minutes daily |
| OBJ-002 | Enable real-time NAV break detection | Breaks detected within 15 minutes of data availability |
| OBJ-003 | Provide a complete audit trail for all reconciliation activities | 100% of reconciliation events logged with timestamp, user, and outcome |
| OBJ-004 | Standardise reconciliation outputs across all funds | Single reporting format used for all six funds |
| OBJ-005 | Reduce undetected discrepancies to zero per quarter | Zero NAV breaks undetected beyond same business day |
| OBJ-006 | Support onboarding of new funds without process changes | New fund reconciliation configurable within 2 business days |

---

## 5. Scope

### 5.1 In Scope

- Automated ingestion of NAV data from fund administrator systems (file-based and API)
- Automated ingestion of NAV data from internal accounting system (Fund Accounting System)
- Configurable tolerance thresholds per fund and data element
- Automated break detection and classification (material vs. immaterial)
- Real-time alerting via email and dashboard notifications
- Reconciliation dashboard with drill-down capability
- Daily, weekly, and monthly reconciliation summary reports
- Full audit trail with user attribution and timestamps
- Configuration interface for tolerance levels and fund parameters
- Historical reconciliation data storage and trend analysis

### 5.2 Out of Scope

- Changes to the fund administrator's systems or NAV calculation processes
- Modifications to the internal Fund Accounting System accounting platform
- NAV calculation or shadow NAV computation
- Investor-facing reporting or communications
- Integration with board reporting tools (Phase 2)
- Reconciliation of non-NAV data (e.g., shareholder registers, trade confirmations)

---

## 6. Stakeholders

| Stakeholder | Role | Interest | Involvement |
|---|---|---|---|
| Head of Fund Operations | Head of Fund Operations | Process owner; accountable for NAV accuracy | Approve requirements, UAT sign-off |
| Chief Technology Officer | CTO | Technology delivery and architecture | Technical design approval |
| Head of Compliance | Head of Compliance | Regulatory obligations and audit readiness | Review compliance requirements |
| Chief Risk Officer | CRO | Operational risk reduction | Risk assessment review |
| Fund Accounting Team | Daily reconciliation operators | Primary users of the new system | Requirements input, UAT, daily operation |
| IT Development Team | System builders | Deliver the technical solution | Design, build, test |
| Fund Administrators | External data providers | Supply daily NAV and position data | Data format agreement |
| Internal Audit | Assurance function | Audit trail and control effectiveness | Review controls framework |
| Board of Directors | Governance oversight | Confidence in NAV accuracy | Informed via board reporting |

---

## 7. Functional Requirements

### FR-001: Automated Data Ingestion from Fund Administrator

- **Description**: The system shall automatically ingest daily NAV data files from each fund administrator in agreed formats (CSV, XML, SWIFT MT940) at scheduled times.
- **Priority**: Must Have
- **Acceptance Criteria**:
  - Data files are retrieved automatically by 09:00 each business day.
  - System supports CSV, XML, and SWIFT MT940 formats.
  - Failed ingestion triggers an alert within 5 minutes.
  - Ingestion log records file name, timestamp, row count, and checksum.

### FR-002: Automated Data Ingestion from Internal Systems

- **Description**: The system shall extract NAV and position data from the internal Fund Accounting System accounting platform via API or database connection.
- **Priority**: Must Have
- **Acceptance Criteria**:
  - Internal data extraction completes within 10 minutes of scheduled trigger.
  - Data includes fund-level NAV, share class NAV, and position-level detail.
  - Extraction failures are logged and alerted.

### FR-003: Data Validation and Quality Checks

- **Description**: The system shall validate all ingested data against predefined quality rules before reconciliation, including completeness, format, and reasonableness checks.
- **Priority**: Must Have
- **Acceptance Criteria**:
  - Missing mandatory fields are flagged and reported.
  - NAV values outside a configurable reasonable range (e.g., +/- 10% from previous day) are flagged.
  - Duplicate records are detected and rejected.
  - Validation results are logged in the audit trail.

### FR-004: Configurable Tolerance Thresholds

- **Description**: The system shall allow authorised users to configure reconciliation tolerance thresholds per fund, per share class, and per data element.
- **Priority**: Must Have
- **Acceptance Criteria**:
  - Tolerances can be set as absolute values or percentage thresholds.
  - Tolerance changes require dual authorisation.
  - Historical tolerance settings are retained for audit purposes.
  - Default tolerances are pre-configured: 0.01% for NAV per share, 0.05% for total NAV.

### FR-005: Automated Reconciliation Engine

- **Description**: The system shall automatically compare administrator NAV data against internal records and identify matches, tolerance breaks, and material breaks.
- **Priority**: Must Have
- **Acceptance Criteria**:
  - Reconciliation runs automatically upon successful ingestion of both data sources.
  - Items within tolerance are marked as matched.
  - Items outside tolerance are classified as breaks and assigned severity (Warning, Material, Critical).
  - Reconciliation completes for all six funds within 15 minutes.

### FR-006: Real-Time Break Alerting

- **Description**: The system shall send immediate alerts when NAV breaks are detected, routed to appropriate personnel based on severity and fund assignment.
- **Priority**: Must Have
- **Acceptance Criteria**:
  - Warning-level breaks generate dashboard notifications.
  - Material breaks trigger email alerts to fund accounting team leads.
  - Critical breaks trigger email and SMS alerts to Head of Fund Operations and Compliance.
  - Alerts include fund name, ISIN, break amount, severity, and suggested action.

### FR-007: Reconciliation Dashboard

- **Description**: The system shall provide a web-based dashboard showing real-time reconciliation status for all funds, with drill-down to individual breaks.
- **Priority**: Must Have
- **Acceptance Criteria**:
  - Dashboard displays traffic-light status for each fund (Green/Amber/Red).
  - Users can drill down from fund level to share class to individual line items.
  - Dashboard updates in real time as reconciliation results are produced.
  - Dashboard is accessible to authorised users via single sign-on.

### FR-008: Break Investigation and Resolution Workflow

- **Description**: The system shall provide a workflow for investigating and resolving breaks, including assignment, commentary, escalation, and closure.
- **Priority**: Should Have
- **Acceptance Criteria**:
  - Breaks can be assigned to specific users for investigation.
  - Users can add comments and attach supporting documents.
  - Unresolved breaks older than configurable thresholds trigger escalation alerts.
  - Break resolution requires a root cause category selection from a predefined list.

### FR-009: Reconciliation Reporting

- **Description**: The system shall generate daily, weekly, and monthly reconciliation summary reports suitable for management, compliance, and board reporting.
- **Priority**: Must Have
- **Acceptance Criteria**:
  - Daily report lists all funds with match status, break counts, and resolution status.
  - Weekly report includes trend analysis and aging of open breaks.
  - Monthly report provides executive summary suitable for board pack inclusion.
  - Reports are exportable in PDF and Excel formats.

### FR-010: Full Audit Trail

- **Description**: The system shall maintain a complete, immutable audit trail of all reconciliation activities, including data ingestion, matching, break identification, user actions, and configuration changes.
- **Priority**: Must Have
- **Acceptance Criteria**:
  - Every system action is logged with timestamp, user ID, action type, and outcome.
  - Audit logs are immutable and cannot be modified or deleted by any user.
  - Audit logs are retained for a minimum of 7 years in line with regulatory requirements.
  - Audit trail is searchable and exportable for internal audit and regulatory review.

---

## 8. Non-Functional Requirements

### 8.1 Performance

- Reconciliation for all six funds shall complete within 15 minutes of data availability.
- Dashboard shall load within 3 seconds under normal conditions.
- System shall support concurrent access by up to 25 users without degradation.

### 8.2 Security

- Access shall be controlled via Active Directory integration with role-based permissions.
- All data in transit shall be encrypted using TLS 1.2 or higher.
- All data at rest shall be encrypted using AES-256.
- System shall comply with Capital Management Co.' Information Security Policy.

### 8.3 Availability

- System shall be available from 06:00 to 22:00 CET on all business days with 99.5% uptime.
- Planned maintenance windows shall be scheduled outside business hours with 48 hours' notice.
- Recovery Point Objective (RPO): 1 hour. Recovery Time Objective (RTO): 4 hours.

### 8.4 Scalability

- System shall support the addition of new funds without architectural changes.
- System shall handle a 100% increase in data volume without performance degradation.

### 8.5 Compliance

- System shall meet Central Bank of Ireland and CSSF requirements for fund accounting controls.
- Audit trail shall satisfy ISAE 3402 / SOC 1 requirements for the fund administrator oversight framework.

---

## 9. Data Requirements

### 9.1 Source Systems

| Source System | Data Provided | Format | Frequency | Owner |
|---|---|---|---|---|
| Fund Administrator (Fund Admin A) | Official NAV, share class NAVs, position valuations | CSV / SWIFT MT940 | Daily by 08:30 CET | Fund Admin Team |
| Fund Administrator (Fund Admin B) | Official NAV, share class NAVs, position valuations | XML | Daily by 08:30 CET | Fund Admin Team |
| Fund Accounting System (Internal) | Shadow NAV, internal positions, trade data | API (REST) | Daily by 08:00 CET | IT / Fund Accounting |
| Bloomberg | Market prices, FX rates | API | Real-time | Market Data Team |

### 9.2 Data Flows

**Current State**: Administrator sends NAV file via SFTP. Fund accounting staff manually download, open in Excel, compare against Fund Accounting System export, and document results in a shared spreadsheet.

**Future State**: System automatically retrieves administrator files from SFTP and extracts Fund Accounting System data via API. Reconciliation engine compares data sets, applies tolerance rules, and publishes results to the dashboard. Breaks trigger automated alerts. All actions are logged.

---

## 10. Process Flows

### 10.1 Current State Process

1. Fund administrator publishes NAV data to SFTP (by 08:30 CET).
2. Fund accounting analyst manually downloads file (08:30 - 09:00).
3. Analyst exports Fund Accounting System data to Excel (09:00 - 09:30).
4. Analyst manually compares NAV per share, total NAV, and key positions (09:30 - 11:00).
5. Discrepancies are investigated via email with the administrator (11:00 - 12:00).
6. Results are documented in a shared Excel workbook (12:00 - 12:30).
7. Summary email is sent to Head of Fund Operations (12:30).

**Total elapsed time**: approximately 4 hours. **Manual effort**: approximately 3 hours.

### 10.2 Future State Process

1. System retrieves administrator NAV files from SFTP automatically (08:30 CET).
2. System extracts Fund Accounting System data via API (08:30 CET, parallel).
3. Data validation rules are applied (08:35 CET).
4. Reconciliation engine compares data sets and applies tolerances (08:40 CET).
5. Dashboard is updated with results; breaks trigger automated alerts (08:45 CET).
6. Fund accounting analyst reviews dashboard, investigates breaks via workflow (09:00 - 09:30).
7. Break resolutions are logged; daily summary report is auto-generated (09:30).

**Total elapsed time**: approximately 1 hour. **Manual effort**: approximately 30 minutes.

---

## 11. Dependencies and Risks

### 11.1 Dependencies

| Dependency ID | Description | Owner | Impact if Not Met |
|---|---|---|---|
| DEP-001 | Fund administrators agree to standardised file formats and delivery schedule | Fund Admin Team | Data ingestion cannot be automated |
| DEP-002 | Fund Accounting System API is available and documented | IT Team | Internal data extraction delayed |
| DEP-003 | Active Directory integration is available | IT Infrastructure | User authentication delayed |
| DEP-004 | SFTP connectivity between administrator and CMC network | IT Infrastructure | File retrieval not possible |
| DEP-005 | Budget approval for infrastructure and licensing costs | CFO | Project cannot proceed |

### 11.2 Risks

| Risk ID | Description | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| RSK-001 | Fund administrator delays in agreeing file formats | Medium | High | Early engagement; escalate via relationship manager |
| RSK-002 | Fund Accounting System API performance insufficient for daily extraction | Low | High | Fallback to database view extraction |
| RSK-003 | Staff resistance to new process | Medium | Medium | Early involvement in UAT; training programme |
| RSK-004 | Reconciliation logic does not cover all edge cases | Medium | High | Extensive parallel running period (minimum 4 weeks) |
| RSK-005 | Regulatory change requires process modification during build | Low | Medium | Modular design to accommodate rule changes |

---

## 12. Implementation Timeline

| Phase | Activities | Duration | Target Dates |
|---|---|---|---|
| Phase 1: Discovery and Design | Requirements finalisation, architecture design, administrator engagement | 6 weeks | Oct 2025 - Nov 2025 |
| Phase 2: Build | Core reconciliation engine, data ingestion, break detection | 10 weeks | Nov 2025 - Jan 2026 |
| Phase 3: Dashboard and Reporting | Dashboard build, report templates, alerting configuration | 6 weeks | Feb 2026 - Mar 2026 |
| Phase 4: Testing | SIT, UAT, parallel running with manual process | 6 weeks | Mar 2026 - Apr 2026 |
| Phase 5: Go-Live and Hypercare | Production deployment, monitoring, issue resolution | 4 weeks | May 2026 |

---

## 13. Sign-Off

By signing below, the approver confirms that the requirements documented in this BRD accurately reflect the business needs and authorises the project to proceed to the design phase.

| Name | Role | Signature | Date |
|---|---|---|---|
| Head of Fund Operations | Head of Fund Operations | _________________ | _________ |
| Chief Technology Officer | CTO | _________________ | _________ |
| Head of Compliance | Head of Compliance | _________________ | _________ |
| Chief Risk Officer | CRO | _________________ | _________ |
