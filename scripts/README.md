# Daily Report — Setup & Automation Guide

## Quick Start

Double-click `RunNow.bat` at any time to generate a report on-demand.

## Automated Daily Execution (No Admin Required)

1. Locate `RunNow.bat` in the root project directory.
2. Press `Win + R`, type `shell:startup`, and hit Enter.
3. Right-click `RunNow.bat` → **Copy** → **Paste Shortcut** into the Startup folder.
4. **Result**: The report pipeline runs every time you log in.

## Pipeline Steps (What RunNow.bat Does)

1. Rebuilds `reports_manifest.json` from the `/reports/` directory.
2. Validates all external URLs in the latest report.
3. Logs results to `/logs/`.

## Configuration

| File | Purpose |
|:---|:---|
| `config/tickers.md` | Stock watchlist |
| `config/ai_tooling.md` | AI experts, sources, and keywords |
| `config/hospitality_tech.md` | Hospitality competitors and topics |

## Agent Pipeline

```
Curator → Summarizer → Filter → Formatter → Arbiter
```

Each agent's behavior is defined in `agents/<name>/prompt.md`. Data contracts between agents are defined in `schemas/agent_contracts.json`.

## Validation & Testing

- **URL Validation**: `powershell -File scripts\validate_urls.ps1` — HEAD-requests all links in the latest report.
- **Structure Test**: `powershell -File scripts\test_report_structure.ps1` — Validates section order, stock data, and footnote markers.
- **Manifest Rebuild**: `powershell -File scripts\build_manifest.ps1` — Regenerates sidebar history from file system.

## Report Archives

Reports are stored in `reports/` with the naming convention `Daily_Report_YYYY-MM-DD[_vN].html`. The sidebar in each report shows historical entries as `"MMM-DD"` for easy scanning.
