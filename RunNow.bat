@echo off
echo ==========================================
echo   Daily Report Automated Generator
echo ==========================================
echo.
echo Initializing Local Report Generation...
echo.

powershell -ExecutionPolicy Bypass -File "scripts\GenerateReport.ps1"

echo.
echo ==========================================
echo   REPORT GENERATED IN /reports
echo ==========================================
echo.
pause
