@echo off
echo ==========================================
echo   Daily Report — Pipeline Runner
echo ==========================================
echo.

echo [1/3] Rebuilding manifest from /reports...
powershell -ExecutionPolicy Bypass -File "scripts\build_manifest.ps1"
echo.

echo [2/3] Running structure tests on latest report...
powershell -ExecutionPolicy Bypass -File "scripts\test_report_structure.ps1"
echo.

echo [3/3] Validating external URLs in latest report...
powershell -ExecutionPolicy Bypass -File "scripts\validate_urls.ps1"
echo.

echo ==========================================
echo   Pipeline complete. Check /logs for details.
echo ==========================================
echo.
pause
