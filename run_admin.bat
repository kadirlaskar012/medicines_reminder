@echo off
title MediRemind - Local Offline Admin Dashboard
echo ========================================================
echo   MediRemind - Local Database Admin Dashboard
echo ========================================================
echo.
echo Starting local offline dashboard server in browser...
echo (Press Ctrl+C in this terminal window to stop the server)
echo.
python tool\admin_dashboard.py
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Could not start Python server.
    echo Please make sure Python 3 is installed and added to PATH.
    echo.
    pause
)
