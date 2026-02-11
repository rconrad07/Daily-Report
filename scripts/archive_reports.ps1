# archive_reports.ps1 — Organize reports into YYYY/MM subdirectories
# Moves Daily_Report_*.html files from flat /reports/ into /reports/YYYY/MM/

param (
    [switch]$DryRun
)

$reportsDir = Join-Path $PSScriptRoot "..\reports"

$files = Get-ChildItem -Path $reportsDir -Filter "Daily_Report_*.html" -File

if ($files.Count -eq 0) {
    Write-Host "No reports to archive." -ForegroundColor Yellow
    exit 0
}

$moved = 0

foreach ($file in $files) {
    if ($file.Name -match "Daily_Report_(\d{4})-(\d{2})-\d{2}") {
        $year = $Matches[1]
        $month = $Matches[2]
        $targetDir = Join-Path $reportsDir "$year\$month"

        if (-not (Test-Path $targetDir)) {
            if (-not $DryRun) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
        }

        $targetPath = Join-Path $targetDir $file.Name
        if ($DryRun) {
            Write-Host "  [DRY RUN] Would move $($file.Name) -> $year/$month/" -ForegroundColor Yellow
        }
        else {
            Move-Item -Path $file.FullName -Destination $targetPath -Force
            Write-Host "  [MOVED] $($file.Name) -> $year/$month/" -ForegroundColor Green
        }
        $moved++
    }
}

Write-Host ""
Write-Host "$moved file(s) processed." -ForegroundColor Cyan

if (-not $DryRun -and $moved -gt 0) {
    Write-Host "Rebuilding manifest after archival..." -ForegroundColor Yellow
    # Update build_manifest to scan subdirectories
    & (Join-Path $PSScriptRoot "build_manifest.ps1")
}
