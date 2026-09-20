@echo off
set "ADB=C:\Users\KadiR-PC\AppData\Local\Android\Sdk\platform-tools\adb.exe"
title MediRemind Phone Screen Mirror
echo ==================================================
echo   Starting MediRemind Live Phone Screen Mirror...
echo ==================================================
"C:\Users\KadiR-PC\AppData\Local\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v4.1\scrcpy.exe" --stay-awake --window-title="MediRemind Phone Screen"
if %errorlevel% neq 0 (
    echo.
    echo Something went wrong. Please check if USB debugging is active.
    pause
)
