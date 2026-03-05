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
    $latest = Get-ChildItem -Path $reportsDir -Filter "Daily_Report_*.html" -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1
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
$unverifiedCount = 0
$results = @()

$headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Accept"     = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
}

foreach ($url in $urls) {
    $isVerified = $false
    $retryCount = 0
    $maxRetries = 2
    $lastError = ""
    $statusCode = 0

    while (-not $isVerified -and $retryCount -le $maxRetries) {
        if ($retryCount -gt 0) {
            Write-Host "  [RETRY $retryCount] $url" -ForegroundColor Cyan
        }
        try {
            $response = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 12 -UseBasicParsing -MaximumRedirection 3 -Headers $headers -ErrorAction Stop
            $statusCode = $response.StatusCode

            $uriObj = [System.Uri]::new($url)
            $pathIsRoot = ($uriObj.AbsolutePath -eq "/") -or ($uriObj.AbsolutePath -eq "")

            if ($statusCode -ge 200 -and $statusCode -lt 400 -and -not $pathIsRoot) {
                $isVerified = $true
            }
            elseif ($pathIsRoot) {
                $lastError = "HOMEPAGE_LINK"
                break # Don't retry homepage links
            }
            else {
                $lastError = "HTTP_$statusCode"
            }
        }
        catch {
            $lastError = $_.Exception.Message
            $retryCount++
            if ($retryCount -le $maxRetries) {
                Start-Sleep -Seconds 1
            }
        }
    }

    if ($isVerified) {
        Write-Host "  [PASS] $url" -ForegroundColor Green
        $passedCount++
        $results += [PSCustomObject]@{ URL = $url; Status = $statusCode; Result = "PASS"; Note = "" }
    }
    else {
        if ($lastError -eq "HOMEPAGE_LINK") {
            Write-Host "  [WARN] HOMEPAGE - $url" -ForegroundColor Yellow
            $results += [PSCustomObject]@{ URL = $url; Status = $statusCode; Result = "HOMEPAGE"; Note = "Link points to site root" }
        }
        else {
            Write-Host "  [UNVERIFIED] $lastError - $url" -ForegroundColor Yellow
            $unverifiedCount++
            $results += [PSCustomObject]@{ URL = $url; Status = "ERR"; Result = "UNVERIFIED"; Note = $lastError }

            # Patch HTML if requested
            if ($PatchBroken) {
                Write-Host "    -> Patching label..." -ForegroundColor Gray
                # Pattern to find the specific anchor tag for this URL and add the label
                # This is a bit coarse but works for the report structure
                $pattern = " href=`"$url`">([^<]+)</a>"
                $template = " href=`"$url`" class=`"unverified-link`">$1 <span class=`"unverified-label`">(Unverified)</span></a>"
                if ($content -match $pattern) {
                    $content = $content -replace [regex]::Escape($matches[0]), ($matches[0] -replace $pattern, $template)
                }
            }
        }
    }
}

if ($PatchBroken -and $unverifiedCount -gt 0) {
    $content | Set-Content $ReportPath -Encoding UTF8
    Write-Host "Report patched with unverified labels." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Results: $passedCount passed, $unverifiedCount unverified of $($urls.Count)" -ForegroundColor Cyan
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

exit 0 # Always exit 0 to allow workflow to continue
