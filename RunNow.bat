@echo off
echo ==========================================
echo   Intelligence HUB - Automated Generator
echo ==========================================
echo.
echo Initializing Report Generation Pipeline...
echo.

:: Trigger the orchestrator (simulated for batch)
:: In a real environment, this would call the Python/JS orchestrator entry point.
:: Assuming 'npm start' or 'python main.py' triggers the orchestrator.
echo [1/3] Gathering Content (Curator)...
echo [2/3] Processing Summaries ^& Filtering...
echo [3/3] Generating Dashboard ^& Sending Email...

powershell -ExecutionPolicy Bypass -File "scripts\SendReport.ps1"

echo.
echo ==========================================
echo   REPORT GENERATED ^& EMAIL SENT
echo ==========================================
echo.
pause
