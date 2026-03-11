# Gold Standard — Evaluator Calibration Dataset

This directory contains **Ground Truth** evaluation fixtures used to measure and calibrate the accuracy of the Arbiter agent.

## Purpose

The Arbiter is itself an LLM agent, which means it can be wrong. This dataset exists to answer:

- **TPR (True Positive Rate / Sensitivity)**: When a report is genuinely GOOD, does the Arbiter correctly identify it as PASS?
- **TNR (True Negative Rate / Specificity)**: When a report has known failures, does the Arbiter correctly identify them as FAIL?

A well-calibrated Arbiter should achieve **>90% TPR and >90% TNR** against this dataset.

## Directory Structure

```
gold_standard/
├── README.md              ← This file
├── good/                  ← Known-PASS reports (ground truth: all judges pass)
│   └── example_good.json
├── bad/                   ← Known-FAIL reports (ground truth: specific judges fail)
│   └── example_bad_citations.json
└── ground_truth.json      ← Master index of all fixtures with expected verdicts
```

## Fixture Schema

Each fixture file is a JSON object with the following schema:

```json
{
  "id": "fixture_001",
  "description": "Report with valid citations, correct stock data, correct order, no footnotes",
  "category": "good",
  "report_snippet": "<html>...</html>",
  "expected_verdicts": {
    "citation_integrity": "PASS",
    "data_integrity": "PASS",
    "structural_compliance": "PASS",
    "content_quality": "PASS"
  },
  "expected_score": 100,
  "injected_failures": []
}
```

For `bad` fixtures, `injected_failures` lists the exact failure modes present, e.g.:
```json
"injected_failures": ["homepage_link", "non_numeric_stock_change"]
```

## Running Calibration

Use the validation script to measure Arbiter accuracy against this dataset:

```powershell
.\scripts\validate_arbiter.ps1
```

This script will output TPR, TNR, and a confusion matrix for each judge dimension.
