# Fund Structure Overview

**Capital Management Co. -- Fund Governance Simulation**

This document describes the umbrella and sub-fund structures managed under Capital Management Co., including regulatory frameworks, share class design, and governance arrangements.

---

## 1. Umbrella Structures

Capital Management Co. operates three umbrella vehicles, each serving a distinct investor base and regulatory purpose.

### 1.1 UCITS Platform ICAV (Ireland)

| Attribute | Detail |
|-----------|--------|
| Legal Form | Irish Collective Asset-management Vehicle (ICAV) |
| Domicile | Ireland |
| Regulator | Central Bank of Ireland (CBI) |
| Framework | UCITS V Directive (2014/91/EU) |
| Management Company | Capital Management Co. |
| Depositary | Fund Admin A Fiduciary Services (Ireland) Ltd / Fund Admin B Trust Company (Ireland) Ltd |
| Administrator | Fund Admin A IFAS (Ireland) Ltd / Fund Admin B Fund Services (Ireland) DAC |

**Sub-Funds:**

| Fund Name | ISIN | Base Currency | Fund Type | Launch Date |
|-----------|------|---------------|-----------|-------------|
| Global Equity Fund | IE00B4X9L533 | EUR | Equity | 2019-03-15 |
| European Bond Fund | IE00BK5BQ103 | EUR | Fixed Income | 2020-06-01 |
| Emerging Markets Fund | IE00BFYN9Y00 | USD | Equity | 2021-09-10 |

**Key Features:**
- Segregated liability between sub-funds under the ICAV Act 2015
- EU marketing passport available under UCITS for distribution across the EEA
- Daily dealing with T+3 settlement for subscriptions and redemptions
- Subject to UCITS investment restrictions (5/10/40 rule, maximum 10% in unlisted securities, etc.)

---

### 1.2 Luxembourg SICAV

| Attribute | Detail |
|-----------|--------|
| Legal Form | Societe d'Investissement a Capital Variable (SICAV) |
| Domicile | Luxembourg |
| Regulator | Commission de Surveillance du Secteur Financier (CSSF) |
| Framework | UCITS V Directive (2014/91/EU), Luxembourg Law of 17 December 2010 |
| Management Company | ManCo Provider Management Company S.A. |
| Depositary | Custodian A Bank Luxembourg S.A. |
| Administrator | European Fund Administration S.A. |

**Sub-Funds:**

| Fund Name | ISIN | Base Currency | Fund Type | Launch Date |
|-----------|------|---------------|-----------|-------------|
| Multi-Asset Growth Fund | LU0292097234 | EUR | Multi-Asset | 2018-11-20 |

**Key Features:**
- Variable capital structure; shares issued and redeemed at NAV
- Umbrella with segregated compartments under Luxembourg Part I UCI law
- UCITS-compliant with full EU distribution passport
- Daily dealing with T+2 settlement

---

### 1.3 Alternative ICAV (AIFMD)

| Attribute | Detail |
|-----------|--------|
| Legal Form | Irish Collective Asset-management Vehicle (ICAV) |
| Domicile | Luxembourg (registered as a Luxembourg vehicle despite ICAV name convention for internal branding) |
| Regulator | CSSF |
| Framework | AIFMD (Directive 2011/61/EU), Luxembourg Law of 12 July 2013 |
| Management Company (AIFM) | ManCo Provider Management Company S.A. |
| Depositary | Custodian A Bank Luxembourg S.A. / Custodian B S.A. |
| Administrator | Fund Admin E (Luxembourg) |

**Sub-Funds:**

| Fund Name | ISIN | Base Currency | Fund Type | Launch Date |
|-----------|------|---------------|-----------|-------------|
| Real Estate Opportunities Fund | LU0488316133 | EUR | Real Estate (AIF) | 2022-01-17 |
| Private Credit Fund | LU0629460675 | EUR | Private Credit (AIF) | 2023-04-03 |

**Key Features:**
- Restricted to professional and qualifying investors (minimum subscription EUR 100,000)
- Monthly or quarterly dealing with longer notice periods (30-90 calendar days)
- Subject to AIFMD leverage limits, liquidity management, and Annex IV reporting
- Not passportable under UCITS; relies on AIFMD National Private Placement Regimes (NPPR) or AIFMD passport where available

---

## 2. Share Class Design

Each sub-fund may issue multiple share classes to accommodate different investor types and distribution preferences.

### 2.1 Standard Share Classes

| Share Class | Suffix | Description | Minimum Investment | Distribution Policy |
|-------------|--------|-------------|--------------------|---------------------|
| Institutional Accumulating | I Acc | For institutional investors; returns reinvested | EUR 1,000,000 | Accumulating |
| Institutional Distributing | I Dist | For institutional investors; dividends paid quarterly | EUR 1,000,000 | Distributing |
| Retail Accumulating | R Acc | For retail investors; returns reinvested | EUR 1,000 | Accumulating |
| Retail Distributing | R Dist | For retail investors; dividends paid quarterly | EUR 1,000 | Distributing |
| Founder | F Acc | Reduced-fee class for seed/anchor investors | EUR 5,000,000 | Accumulating |

### 2.2 Fee Structure by Share Class (Illustrative)

| Share Class | Management Fee (bps) | Performance Fee | TER Cap |
|-------------|---------------------|-----------------|---------|
| I Acc / I Dist | 50 - 75 | None (UCITS) / 15% over hurdle (AIF) | 0.95% |
| R Acc / R Dist | 100 - 150 | None | 1.75% |
| F Acc | 25 - 40 | None | 0.55% |

### 2.3 Currency-Hedged Classes

Where investor demand warrants, hedged share classes are offered in USD, GBP, and CHF. Currency hedging is implemented via rolling 1-month FX forward contracts, targeting a hedge ratio of 95-105% of the hedged class NAV.

---

## 3. Regulatory Frameworks

### 3.1 UCITS (UCITS Platform ICAV and Luxembourg SICAV)

The Undertakings for Collective Investment in Transferable Securities (UCITS) framework provides:

- **Investment Restrictions**: Diversification rules (5/10/40), eligible asset requirements, derivative exposure limits (commitment or VaR approach), concentration limits
- **Liquidity**: Minimum daily dealing obligation; ability to apply swing pricing or anti-dilution levies
- **Disclosure**: KIID (transitioning to PRIIPs KID), semi-annual and annual reports, prospectus
- **Depositary Oversight**: Independent depositary with safekeeping, cash monitoring, and oversight duties
- **Passporting**: Funds can be marketed across all EEA member states via a management company passport notification

### 3.2 AIFMD (Alternative ICAV)

The Alternative Investment Fund Managers Directive (AIFMD) framework provides:

- **Investor Eligibility**: Restricted to professional investors (MiFID II classification) or well-informed investors (Luxembourg)
- **Leverage Reporting**: Gross and commitment method leverage calculation; reporting to CSSF via Annex IV
- **Liquidity Management**: Liquidity management policy required; stress testing at least annually
- **Valuation**: Independent valuation of illiquid assets at least annually; quarterly NAV for semi-liquid funds
- **Depositary Duties**: Enhanced liability regime for loss of financial instruments held in custody
- **Remuneration**: AIFM remuneration policy aligned with ESMA guidelines
- **Transparency**: Annual report, Annex IV filing, investor disclosure (Article 23)

---

## 4. Governance Structure

### 4.1 Board of Directors

Each umbrella vehicle has an independent board responsible for oversight of the fund and its service providers.

| Role | UCITS Platform ICAV | Luxembourg SICAV | Alternative ICAV |
|------|------------------------|----------------------|---------------------|
| Independent Chair | Mary Independent NED 1 | Jean-Claude Weber | Jean-Claude Weber |
| Independent Director | Patrick Independent NED 2 | Sophie Muller | Sophie Muller |
| Independent Director | Aisling Head of Fund Governance | Marc Faber | Marc Faber |
| ManCo Representative | Designated Person 1 (ManCo) | Designated Person 2 (ManCo) | Designated Person 2 (ManCo) |
| Company Representative | Chief Investment Officer (CIO) | Chief Investment Officer (CIO) | Head of Alternatives |

**Board Responsibilities:**
- Approve prospectus, supplements, and material changes
- Oversee investment manager compliance with mandates
- Review and approve annual financial statements
- Monitor service provider performance against SLAs
- Oversee risk management, valuation, and conflicts of interest
- Ensure regulatory compliance and timely filings

### 4.2 Management Company (ManCo)

The ManCo is responsible for portfolio management, risk management, and administration (which may be delegated).

- **Capital Management Co.** (Irish UCITS ManCo, authorised by CBI): Provides designated persons for investment management, risk management, compliance, operations, and distribution for the Irish UCITS funds.
- **ManCo Provider Management Company S.A.** (Luxembourg ManCo / AIFM, authorised by CSSF): Acts as UCITS ManCo for the Luxembourg SICAV and as AIFM for the Alternative ICAV.

### 4.3 Depositary

The depositary provides independent oversight including:

- Safekeeping of fund assets (financial instruments and other assets)
- Cash flow monitoring across all fund bank accounts
- Oversight of NAV calculations, share issuance/redemption, and income allocation
- Verification that transactions comply with fund rules and applicable law

### 4.4 Compliance and Risk

| Function | Responsibility |
|----------|---------------|
| Compliance Officer (ManCo) | Pre- and post-trade compliance monitoring, regulatory filings, breach reporting |
| Risk Manager (ManCo) | Investment risk (VaR, stress testing), liquidity risk, counterparty risk, operational risk |
| MLRO | AML/CFT compliance, suspicious transaction reporting, investor due diligence oversight |
| Data Protection Officer | GDPR compliance for investor data processing |

---

## 5. Organisational Chart (Simplified)

```
                         Board of Directors
                               |
                    Management Company (ManCo)
                    /          |           \
          Investment      Risk           Compliance
          Manager(s)      Management     & MLRO
              |               |               |
         Sub-Funds       Risk Reports     Regulatory
         (Portfolios)    & Monitoring     Filings
              |
    -----------------------
    |           |         |
Administrator  Depositary  Auditor
(NAV, TA)     (Custody)   (Annual Audit)
```

---

*Document Owner: Capital Management Co. -- Fund Governance Team*
*Version: 1.0 | Last Updated: 2026-03-28*
