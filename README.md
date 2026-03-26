# The BA Guide — Fund Governance Edition

A comprehensive, bilingual (EN/PT) study guide and professional reference for Business Analysts working in Fund Governance.

## Overview

Single-file HTML application covering the full spectrum of fund governance operations — from regulatory frameworks to ManCo operations, risk management, financial analysis and career development. Designed as an interactive knowledge platform with no external dependencies.

## Topics Covered

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

## Features

- **Bilingual** — full content in English and Portuguese with instant toggle
- **Dark mode** — Radix zinc palette, persistent via localStorage
- **Full-text search** — searches across all parts with in-page highlighting and navigation
- **Hash routing** — bookmarkable deep links (e.g. `#part3/ch3-2`), browser back/forward support
- **Reading position** — auto-saves progress, offers to resume on return
- **Share button** — copies deep-link URL to clipboard
- **Keyboard navigation** — arrow keys, H (home), P/N (prev/next), Ctrl+F (search)
- **70+ acronym tooltips** — hover or keyboard focus to see definitions
- **Reading time estimates** — per-part word count calculation
- **Print/PDF** — print current part or all, with cover page, table of contents and B&W-optimised layout
- **Responsive** — sidebar collapses on mobile, fluid typography with `clamp()`
- **Accessible** — skip-link, ARIA landmarks, `aria-live` regions, keyboard-focusable elements
- **Performant** — DOM pooling (inactive parts detached), lazy acronym processing, `requestAnimationFrame` throttled scroll
- **Secure** — Content Security Policy, zero `innerHTML`, input validation

## Architecture

Single HTML file with embedded CSS and JS. No build tools, no bundler, no server required.

```
index.html
├── CSS — Design system with 50+ variables, Apple-style light/dark themes
├── HTML — 10 parts, 38 chapters, bilingual content blocks
└── JS (IIFE) — 10 modules
    ├── State — Reactive store with onChange subscribers
    ├── DomPool — Detaches inactive parts from DOM
    ├── Nav — Navigation, sidebar, breadcrumb
    ├── Search — Full-text search engine
    ├── Theme — Dark/light mode
    ├── Lang — Bilingual system
    ├── Render — DOM builders (TOCs, nav, cards, tooltips)
    ├── Print — PDF/print system
    ├── Scroll — Progress bar, scroll-to-top, scroll spy
    ├── Router — Hash-based URL routing
    └── Position — Reading position persistence
```

## Usage

Open `index.html` in any modern browser. No dependencies, no build step, no server required.

## Live Version

Available at: [https://dms1996.github.io/fund-governance-guide/](https://dms1996.github.io/fund-governance-guide/)

## Version

**v2.0** — March 2026

## Disclaimer

This guide was researched, written and built with the assistance of AI (Claude by Anthropic). All content was reviewed, validated and curated by the author.

---

2026 © dms1996
