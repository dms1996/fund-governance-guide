# Fund Governance Guide

A comprehensive, bilingual (EN/PT) learning platform for Business Analysts working in Fund Governance. Combines an interactive simulation of a real working day with an in-depth reference guide covering regulatory frameworks, ManCo operations, risk management and career development.

**Live version:** [https://dms1996.github.io/fund-governance-guide/](https://dms1996.github.io/fund-governance-guide/)

---

## What's Included

### Interactive Tutorial (`index.html`)

Step-by-step simulation of a Fund Governance Analyst's working day, covering:

- NAV reconciliation (editable tables, break classification with drag-drop)
- Compliance alert investigation (email composer, breach notification)
- Investor onboarding (KYC decision engine)
- Fee validation (live calculator, high-water mark examples)
- Board pack preparation (performance and risk dashboards)
- Service provider oversight and regulatory calendar

Includes 5 quizzes (14 questions), interactive activities, and a scoring system with progress persistence.

### BA Reference Guide (`guide.html`)

Single-file knowledge platform with 10 parts and 38 chapters:

| Part | Topic |
|------|-------|
| I | The Fund Governance Industry |
| II | Investment Funds: UCITS and AIFs |
| III | Regulatory Framework (EU, Luxembourg, Ireland, UK) |
| IV | Management Company Operations |
| V | Risk Management and Compliance |
| VI | The Business Analyst Role |
| VII | Applied Financial Analysis |
| VIII | Technology and Data in Fund Services |
| IX | Professional Development and Certifications |
| X | Integrated Case Study and Glossary |

### Simulation Data (17 CSVs + 1 Excel)

Realistic datasets for 6 fictitious funds managed by Capital Management Co.:

| Fund | ISIN | Type | Domicile |
|------|------|------|----------|
| Global Equity Fund | IE00B4X9L533 | UCITS | Ireland |
| European Bond Fund | IE00BK5BQ103 | UCITS | Ireland |
| Multi-Asset Growth Fund | LU0292097234 | UCITS | Luxembourg |
| Emerging Markets Fund | IE00BFYN9Y00 | UCITS | Ireland |
| Real Estate Opportunities Fund | LU0488316133 | AIF (AIFMD) | Luxembourg |
| Private Credit Fund | LU0629460675 | AIF (AIFMD) | Luxembourg |

### SQL Scripts & Python Automation

- **4 SQL scripts** for NAV validation, fee reconciliation, investor data extraction, and AUM tracking
- **3 Python scripts** for automated NAV break analysis, fee calculation, and board report generation

---

## Project Structure

```
fund-governance-guide/
|
|-- index.html                     Interactive tutorial (bilingual)
|-- guide.html                     BA reference guide (bilingual)
|-- info.md                        Detailed workflow guide (PT)
|-- Fund_Governance_Data_Template.xlsx
|
|-- 01-Fund-Setup/                 Fund register, structure overview, setup checklist
|-- 02-NAV-Reconciliation/         Daily NAV reports, breaks log, reconciliation SQL
|-- 03-Compliance-Monitoring/      Compliance checklist, AML/KYC tracker, breaches log
|-- 04-Fee-Calculations/           Management & performance fees, fee validation SQL
|-- 05-Board-Reporting/            Board pack, fund performance summary, risk dashboard
|-- 06-Investor-Reporting/         Investor register, monthly factsheet, report template
|-- 07-Regulatory-Reporting/       Regulatory calendar, UCITS & AIFMD reporting data
|-- 08-Business-Analysis/          BRD, user stories, data dictionary, gap analysis
|-- 09-SQL-Scripts/                NAV validation, fee reconciliation, AUM tracking
|-- 10-Python-Automation/          NAV break analysis, fee calculator, report generator
```

---

## Features

- **Bilingual** -- full content in English and Portuguese with instant toggle
- **Dark mode** -- persistent via localStorage
- **Interactive activities** -- editable tables, drag-drop, quizzes, decision engine, fee calculator, email composer
- **Scoring system** -- tracks progress across all activities with category breakdown
- **Full-text search** -- in the BA guide with result navigation
- **Responsive** -- works on desktop and mobile
- **Zero dependencies** -- no build tools, no server, just open in a browser

---

## Technologies

- **HTML/CSS/JS** -- Single-file applications, no external dependencies
- **SQL** (T-SQL syntax) -- Data validation and reporting queries
- **Python 3.8+** -- Automation scripts using pandas and numpy
- **CSV/Excel** -- Simulated datasets

---

## Disclaimer

This is a simulation project created for educational and portfolio demonstration purposes. All data, fund names, investor names, and entities are fictitious. Any resemblance to real companies is coincidental.

This project was researched, written and built with the assistance of AI (Claude by Anthropic). All content was reviewed, validated and curated by the author.

---

**v3.0** -- March 2026

2026 © dms1996
