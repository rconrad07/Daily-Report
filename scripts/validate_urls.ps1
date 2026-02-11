# validate_urls.ps1 - URL Validation for Daily Report
# Extracts all href URLs from an HTML report and HEAD-requests each.

param (
    [Parameter(Mandatory = $false)]
    [string]$ReportPath,
    [switch]$PatchBroken
)

$ErrorActionPreference = "Continue"

# If no path provided, find the latest report
if (-not $ReportPath) {
    $reportsDir = Join-Path $PSScriptRoot "..\reports"
    $latest = Get-ChildItem -Path $reportsDir -Filter "Daily_Report_*.html" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -eq $latest) {
        Write-Host "[ERROR] No reports found." -ForegroundColor Red
        exit 1
    }
    $ReportPath = $latest.FullName
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  URL Validator" -ForegroundColor Cyan
Write-Host "  File: $(Split-Path $ReportPath -Leaf)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$content = Get-Content $ReportPath -Raw

# Extract all href URLs (skip anchors, javascript:, and file://)
$hrefPattern = 'href="(https?://[^"]+)"'
$hrefMatches = [regex]::Matches($content, $hrefPattern)
# URLs to skip (fonts, CDNs, display resources — not citations)
$skipDomains = @("fonts.googleapis.com", "fonts.gstatic.com")
$urls = @()
foreach ($m in $hrefMatches) {
    $url = $m.Groups[1].Value
    $uriCheck = [System.Uri]::new($url)
    $skip = $false
    foreach ($sd in $skipDomains) {
        if ($uriCheck.Host -eq $sd) { $skip = $true; break }
    }
    if (-not $skip -and $url -notin $urls) {
        $urls += $url
    }
}

if ($urls.Count -eq 0) {
    Write-Host "[WARN] No external URLs found in the report." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($urls.Count) unique external URLs to validate." -ForegroundColor White
Write-Host ""

$passedCount = 0
$failedCount = 0
$results = @()

foreach ($url in $urls) {
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -UseBasicParsing -MaximumRedirection 3 -ErrorAction Stop
        $statusCode = $response.StatusCode

        # Check if URL path is just "/" (homepage detection)
        $uriObj = [System.Uri]::new($url)
        $pathIsRoot = ($uriObj.AbsolutePath -eq "/") -or ($uriObj.AbsolutePath -eq "")

        if ($statusCode -ge 200 -and $statusCode -lt 400 -and -not $pathIsRoot) {
            Write-Host "  [PASS] $statusCode - $url" -ForegroundColor Green
            $passedCount++
            $results += [PSCustomObject]@{ URL = $url; Status = $statusCode; Result = "PASS"; Note = "" }
        }
        elseif ($pathIsRoot) {
            Write-Host "  [WARN] $statusCode - HOMEPAGE - $url" -ForegroundColor Yellow
            $failedCount++
            $results += [PSCustomObject]@{ URL = $url; Status = $statusCode; Result = "HOMEPAGE"; Note = "Link points to site root" }
        }
        else {
            Write-Host "  [FAIL] $statusCode - $url" -ForegroundColor Red
            $failedCount++
            $results += [PSCustomObject]@{ URL = $url; Status = $statusCode; Result = "FAIL"; Note = "HTTP $statusCode" }
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Host "  [FAIL] ERROR - $url" -ForegroundColor Red
        Write-Host "         $errMsg" -ForegroundColor DarkGray
        $failedCount++
        $results += [PSCustomObject]@{ URL = $url; Status = "ERR"; Result = "FAIL"; Note = $errMsg }
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Results: $passedCount passed, $failedCount failed of $($urls.Count)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Log results
$logDir = Join-Path $PSScriptRoot "..\logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$logFile = Join-Path $logDir "url_validation_$timestamp.log"
$results | Format-Table -AutoSize | Out-String | Set-Content $logFile -Encoding UTF8
Write-Host "Log saved to: $logFile" -ForegroundColor DarkGray

if ($failedCount -gt 0) { exit 1 } else { exit 0 }
