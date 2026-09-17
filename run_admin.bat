@echo off
title MediRemind - Cloud & Local Admin Dashboard
echo ========================================================
echo   MediRemind - User & Medicine Database Dashboard
echo ========================================================
echo.
echo Connecting to Supabase Cloud / Local Cache...
echo Starting dashboard web server at http://localhost:8080...
echo.
echo (Press Ctrl+C in this terminal window to stop the server)
echo.
python tool\admin_dashboard.py
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Could not start Python server.
    echo Please ensure Python 3 is installed and added to your system PATH.
    echo.
    pause
)
