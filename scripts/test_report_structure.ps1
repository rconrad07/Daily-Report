# test_report_structure.ps1 - Unit Tests for Daily Report HTML
# Validates: section order, footnote markers, stock data integrity, and placeholder tokens.

param (
    [Parameter(Mandatory = $false)]
    [string]$ReportPath
)

# Find latest report if not specified
if (-not $ReportPath) {
    $reportsDir = Join-Path $PSScriptRoot "..\reports"
    $latest = Get-ChildItem -Path $reportsDir -Filter "Daily_Report_*.html" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -eq $latest) {
        Write-Host "[SKIP] No reports found." -ForegroundColor Yellow
        exit 0
    }
    $ReportPath = $latest.FullName
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Structure Tests" -ForegroundColor Cyan
Write-Host "  File: $(Split-Path $ReportPath -Leaf)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$content = Get-Content $ReportPath -Raw
$passed = 0
$failed = 0

# --- TEST 1: Section Order ---
$sectionNames = @("Executive Summary", "Stock Performance", "AI Tooling", "Hospitality Tech")
$positions = @()
$allFound = $true

foreach ($s in $sectionNames) {
    $idx = $content.IndexOf($s)
    if ($idx -lt 0) {
        Write-Host "  [FAIL] Section not found: $s" -ForegroundColor Red
        $failed++
        $allFound = $false
    }
    else {
        $positions += $idx
    }
}

if ($allFound) {
    $sorted = $positions | Sort-Object
    $inOrder = $true
    for ($i = 0; $i -lt $positions.Count; $i++) {
        if ($positions[$i] -ne $sorted[$i]) {
            $inOrder = $false
            break
        }
    }
    if ($inOrder) {
        Write-Host "  [PASS] Sections are in the correct order." -ForegroundColor Green
        $passed++
    }
    else {
        Write-Host "  [FAIL] Sections are OUT OF ORDER." -ForegroundColor Red
        $failed++
    }
}

# --- TEST 2: No Footnote Markers ---
$footnotePattern = '\[\d+\]'
$hasFootnotes = [regex]::IsMatch($content, $footnotePattern)
if ($hasFootnotes) {
    Write-Host "  [FAIL] Found footnote markers like [1] in the report." -ForegroundColor Red
    $failed++
}
else {
    Write-Host "  [PASS] No footnote markers found." -ForegroundColor Green
    $passed++
}

# --- TEST 3: Stock Change (%) is Numeric ---
$stockPattern = 'id="stockBody"'
if ($content.Contains($stockPattern)) {
    $tdPattern = '<td[^>]*>(.*?)</td>'
    $tbodyStart = $content.IndexOf($stockPattern)
    $tbodyEnd = $content.IndexOf('</tbody>', $tbodyStart)
    if ($tbodyEnd -gt $tbodyStart) {
        $stockSection = $content.Substring($tbodyStart, $tbodyEnd - $tbodyStart)
        $trMatches = [regex]::Matches($stockSection, '<tr>(.*?)</tr>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $stockPass = $true
        foreach ($tr in $trMatches) {
            $tdMatches = [regex]::Matches($tr.Groups[1].Value, $tdPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($tdMatches.Count -ge 2) {
                $changeVal = $tdMatches[1].Groups[1].Value.Trim()
                $numericPattern = '^[+-]?\d+\.?\d*%$'
                if (-not [regex]::IsMatch($changeVal, $numericPattern)) {
                    Write-Host "  [FAIL] Stock Change column has invalid value: $changeVal" -ForegroundColor Red
                    $stockPass = $false
                    $failed++
                    break
                }
            }
        }
        if ($stockPass) {
            Write-Host "  [PASS] All stock Change values are numeric." -ForegroundColor Green
            $passed++
        }
    }
}
else {
    Write-Host "  [WARN] No stockBody element found. Skipping stock test." -ForegroundColor Yellow
}

# --- TEST 4: No Unresolved Placeholders ---
$placeholderPattern = '\{\{[A-Z_]+\}\}'
$hasPlaceholders = [regex]::IsMatch($content, $placeholderPattern)
if ($hasPlaceholders) {
    Write-Host "  [FAIL] Found unresolved template placeholders." -ForegroundColor Red
    $failed++
}
else {
    Write-Host "  [PASS] No unresolved template placeholders." -ForegroundColor Green
    $passed++
}

# --- TEST 5: Manifest Consistency ---
$manifestPath = Join-Path (Split-Path $ReportPath) "reports_manifest.json"
if (Test-Path $manifestPath) {
    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
    $htmlFiles = Get-ChildItem -Path (Split-Path $ReportPath) -Filter "Daily_Report_*.html" | Select-Object -ExpandProperty Name
    $manifestFiles = $manifest | ForEach-Object { $_.filename }
    $missingCount = 0
    foreach ($hf in $htmlFiles) {
        if ($hf -notin $manifestFiles) {
            Write-Host "  [FAIL] Missing from manifest: $hf" -ForegroundColor Red
            $missingCount++
        }
    }
    if ($missingCount -gt 0) {
        $failed++
    }
    else {
        Write-Host "  [PASS] All HTML files have manifest entries." -ForegroundColor Green
        $passed++
    }
}
else {
    Write-Host "  [WARN] Manifest not found. Skipping consistency test." -ForegroundColor Yellow
}

# --- Summary ---
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Results: $passed passed, $failed failed" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

if ($failed -gt 0) { exit 1 } else { exit 0 }
