# build_manifest.ps1 — Auto-generate reports_manifest.json
# Scans /reports/ for Daily_Report_*.html files and builds the manifest.

$reportsDir = (Resolve-Path (Join-Path $PSScriptRoot "..\reports")).Path
$manifestPath = Join-Path $reportsDir "reports_manifest.json"

$files = Get-ChildItem -Path $reportsDir -Filter "Daily_Report_*.html" -Recurse |
Sort-Object Name -Descending

$manifest = @()

foreach ($file in $files) {
    # Extract date from filename: Daily_Report_YYYY-MM-DD[_vN].html
    if ($file.Name -match "Daily_Report_(\d{4}-\d{2}-\d{2})(_v(\d+))?\.html") {
        $rawDate = $Matches[1]
        $version = if ($Matches[3]) { "v$($Matches[3])" } else { "v1" }

        # Parse date to get short month format: "Feb-10"
        $parsedDate = [DateTime]::ParseExact($rawDate, "yyyy-MM-dd", $null)
        $shortTitle = $parsedDate.ToString("MMM-dd")

        # If versioned, append version
        if ($version -ne "v1") {
            $shortTitle = "$shortTitle ($version)"
        }

        # Compute relative path from reports dir (for archived files in subdirs)
        $relativePath = $file.FullName.Substring($reportsDir.Length + 1).Replace('\', '/')

        $manifest += [PSCustomObject]@{
            date     = $rawDate
            filename = $relativePath
            title    = $shortTitle
        }
    }
}

# Write as JSON
$json = $manifest | ConvertTo-Json -Depth 3
Set-Content -Path $manifestPath -Value $json -Encoding UTF8

Write-Host "[OK] Manifest rebuilt with $($manifest.Count) entries." -ForegroundColor Green
Write-Host "     Saved to: $manifestPath" -ForegroundColor DarkGray
