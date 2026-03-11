<#
.SYNOPSIS
    Validate Arbiter Calibration — Measures TPR and TNR of the Arbiter judge against the Gold Standard dataset.

.DESCRIPTION
    This script iterates through all fixtures in evals/gold_standard/ground_truth.json,
    invokes the Arbiter against each fixture's report snippet, compares the Arbiter's
    verdicts against the known ground truth, and reports:

    - True Positive Rate (TPR): % of PASS cases correctly identified as PASS
    - True Negative Rate (TNR): % of FAIL cases correctly identified as FAIL
    - A per-judge confusion matrix
    - An overall calibration score

    Target: TPR > 90% and TNR > 90% for the Arbiter to be considered well-calibrated.

.PARAMETER Verbose
    Emit detailed output for each fixture evaluation.

.EXAMPLE
    .\scripts\validate_arbiter.ps1
    .\scripts\validate_arbiter.ps1 -Verbose

.NOTES
    Run this script when:
    - The Arbiter prompt.md has been modified
    - A new model version has been deployed
    - Adding new fixtures to the Gold Standard dataset
#>

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir

$GroundTruthPath = Join-Path $RepoRoot "evals\gold_standard\ground_truth.json"
$ResultsDir      = Join-Path $RepoRoot "evals\gold_standard\results"

if (-not (Test-Path $ResultsDir)) {
    New-Item -ItemType Directory -Path $ResultsDir | Out-Null
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Arbiter Calibration Validation" -ForegroundColor Cyan
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# --- Load Ground Truth ---
if (-not (Test-Path $GroundTruthPath)) {
    Write-Error "Ground truth index not found at: $GroundTruthPath"
    exit 1
}

$GroundTruth = Get-Content $GroundTruthPath -Raw | ConvertFrom-Json
$Fixtures    = $GroundTruth.fixtures

Write-Host "Loaded $($Fixtures.Count) fixtures from ground_truth.json" -ForegroundColor Green
Write-Host ""

# --- Judge Dimensions ---
$Judges = @("citation_integrity", "data_integrity", "structural_compliance", "content_quality")

# Per-judge confusion matrix: [TP, FP, TN, FN]
$Matrix = @{}
foreach ($j in $Judges) {
    $Matrix[$j] = @{ TP = 0; FP = 0; TN = 0; FN = 0 }
}

$Results = @()

# --- Iterate Fixtures ---
foreach ($fixture in $Fixtures) {
    $FixturePath = Join-Path $RepoRoot $fixture.file

    if (-not (Test-Path $FixturePath)) {
        Write-Warning "Fixture file not found, SKIPPING: $($fixture.file)"
        continue
    }

    $FixtureData = Get-Content $FixturePath -Raw | ConvertFrom-Json

    if ($Verbose) {
        Write-Host "---" -ForegroundColor Gray
        Write-Host "Fixture: $($fixture.id) — $($fixture.description)" -ForegroundColor Yellow
    }

    # NOTE: In a live system, this block would invoke the Arbiter LLM against
    # the report_snippet and parse its structured output. For now, this is a
    # scaffold that compares the fixture's pre-defined 'arbiter_verdicts' field
    # (populated after a real Arbiter run) against the ground truth.
    #
    # TO ACTIVATE: Populate the 'arbiter_verdicts' field in each fixture JSON
    # after running the Arbiter manually on the fixture's report_snippet.

    if (-not $FixtureData.PSObject.Properties['arbiter_verdicts']) {
        Write-Warning "Fixture $($fixture.id) has no 'arbiter_verdicts' field. Run Arbiter first, then populate this field."
        continue
    }

    $ArbitersVerdicts = $FixtureData.arbiter_verdicts
    $ExpectedVerdicts = $fixture.expected_verdicts
    $FixtureResult    = @{ id = $fixture.id; judges = @{} }

    foreach ($judge in $Judges) {
        $Expected = $ExpectedVerdicts.$judge
        $Actual   = $ArbitersVerdicts.$judge

        $FixtureResult.judges[$judge] = @{ expected = $Expected; actual = $Actual }

        if ($Expected -eq "PASS" -and $Actual -eq "PASS") {
            $Matrix[$judge].TP++
            $label = "TP"
        } elseif ($Expected -eq "PASS" -and $Actual -eq "FAIL") {
            $Matrix[$judge].FN++
            $label = "FN (missed PASS)"
        } elseif ($Expected -eq "FAIL" -and $Actual -eq "FAIL") {
            $Matrix[$judge].TN++
            $label = "TN"
        } else {
            $Matrix[$judge].FP++
            $label = "FP (false alarm)"
        }

        if ($Verbose) {
            $color = if ($label -in @("TP","TN")) { "Green" } else { "Red" }
            Write-Host "  [$judge] Expected=$Expected | Actual=$Actual → $label" -ForegroundColor $color
        }
    }

    $Results += $FixtureResult
}

# --- Calculate TPR / TNR per Judge ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Per-Judge TPR / TNR Report" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$OverallTPR = @()
$OverallTNR = @()

foreach ($judge in $Judges) {
    $m   = $Matrix[$judge]
    $TPR = if (($m.TP + $m.FN) -gt 0) { [math]::Round($m.TP / ($m.TP + $m.FN) * 100, 1) } else { "N/A" }
    $TNR = if (($m.TN + $m.FP) -gt 0) { [math]::Round($m.TN / ($m.TN + $m.FP) * 100, 1) } else { "N/A" }

    $tprColor = if ($TPR -is [double] -and $TPR -ge 90) { "Green" } else { "Red" }
    $tnrColor = if ($TNR -is [double] -and $TNR -ge 90) { "Green" } else { "Red" }

    Write-Host "  $judge" -ForegroundColor White
    Write-Host "    TPR (Sensitivity): $TPR%" -ForegroundColor $tprColor
    Write-Host "    TNR (Specificity): $TNR%" -ForegroundColor $tnrColor
    Write-Host "    TP=$($m.TP)  FP=$($m.FP)  TN=$($m.TN)  FN=$($m.FN)" -ForegroundColor Gray
    Write-Host ""

    if ($TPR -is [double]) { $OverallTPR += $TPR }
    if ($TNR -is [double]) { $OverallTNR += $TNR }
}

# --- Overall Summary ---
$AvgTPR = if ($OverallTPR.Count -gt 0) { [math]::Round(($OverallTPR | Measure-Object -Average).Average, 1) } else { "N/A" }
$AvgTNR = if ($OverallTNR.Count -gt 0) { [math]::Round(($OverallTNR | Measure-Object -Average).Average, 1) } else { "N/A" }

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Overall Calibration Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
$overallColor = if ($AvgTPR -ge 90 -and $AvgTNR -ge 90) { "Green" } else { "Red" }
Write-Host "  Average TPR: $AvgTPR%  |  Average TNR: $AvgTNR%" -ForegroundColor $overallColor

if ($AvgTPR -is [double] -and $AvgTPR -ge 90 -and $AvgTNR -is [double] -and $AvgTNR -ge 90) {
    Write-Host ""
    Write-Host "  ✅ CALIBRATION PASS — Arbiter meets the >90% TPR/TNR threshold." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  ❌ CALIBRATION FAIL — Arbiter does not meet the >90% threshold. Review judge prompts." -ForegroundColor Red
}

Write-Host ""

# --- Save Results ---
$Timestamp   = Get-Date -Format "yyyyMMdd_HHmmss"
$ResultsFile = Join-Path $ResultsDir "calibration_$Timestamp.json"
$Summary     = @{
    run_at      = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    avg_tpr     = $AvgTPR
    avg_tpr_pass = ($AvgTPR -is [double] -and $AvgTPR -ge 90)
    avg_tnr     = $AvgTNR
    avg_tnr_pass = ($AvgTNR -is [double] -and $AvgTNR -ge 90)
    per_judge   = $Matrix
    fixture_results = $Results
}
$Summary | ConvertTo-Json -Depth 10 | Set-Content $ResultsFile
Write-Host "  Results saved to: $ResultsFile" -ForegroundColor Gray
Write-Host ""
