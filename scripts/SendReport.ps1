# SendReport.ps1 - Automate Daily Intelligence Report Email
# Usage: powershell.exe -File SendReport.ps1 -AppPassword "your-16-char-app-password"

param (
    [Parameter(Mandatory=$true)]
    [string]$AppPassword
)

$configPath = Join-Path $PSScriptRoot "..\config\email_config.json"
$config = Get-Content $configPath | ConvertFrom-Json

$reportsDir = Join-Path $PSScriptRoot "..\reports"
$latestReport = Get-ChildItem -Path $reportsDir -Filter "Daily_Report_*.html" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($null -eq $latestReport) {
    Write-Error "No daily report found in $reportsDir"
    exit
}

$reportContent = Get-Content $latestReport.FullName -Raw

# Send Email
$smtpserver = $config.smtp_server
$from = $config.sender_email
$to = $config.recipient_email
$subject = "Daily Intelligence Report - $(Get-Date -Format 'yyyy-MM-dd')"

$message = New-Object System.Net.Mail.MailMessage $from, $to, $subject, $reportContent
$message.IsBodyHtml = $true

$client = New-Object System.Net.Mail.SmtpClient $smtpserver, $config.smtp_port
$client.EnableSsl = $true
$client.Credentials = New-Object System.Net.NetworkCredential($from, $AppPassword)

try {
    $client.Send($message)
    Write-Host "Successfully sent report: $($latestReport.Name)"
}
catch {
    Write-Error "Failed to send email: $($_.Exception.Message)"
}
finally {
    $message.Dispose()
    $client.Dispose()
}
