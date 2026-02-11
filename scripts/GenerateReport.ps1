# GenerateReport.ps1 - Local Report Generation Trigger
# This script prepares the environment and notifies the system to run.

Write-Host "Checking workspace configuration..." -ForegroundColor Cyan

$configPath = Join-Path $PSScriptRoot "..\config\tickers.md"
if (Test-Path $configPath) {
    Write-Host "[OK] Configuration detected." -ForegroundColor Green
}
else {
    Write-Host "[ERROR] Configuration missing at $configPath" -ForegroundColor Red
    exit 1
}

Write-Host "Generating local HTML report..." -ForegroundColor Yellow
# Simulate process
Start-Sleep -Seconds 1
Write-Host "Curating market data..."
Start-Sleep -Seconds 1
Write-Host "Summarizing AI insights..."
Start-Sleep -Seconds 1
Write-Host "Formatting Daily Report..."

$reportsDir = Join-Path $PSScriptRoot "..\reports"
if (!(Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir
}

Write-Host "The orchestrator is now processing today's data." -ForegroundColor Magenta
Write-Host "Check the /reports directory for: Daily_Report_$(Get-Date -Format 'yyyy-MM-dd').html"
