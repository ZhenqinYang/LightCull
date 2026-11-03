@echo off
setlocal
rem Drag a folder onto this BAT, or double-click it to browse from the app.
rem PowerShell -STA is required by the built-in WPF desktop UI.
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0LightCull.ps1" "%~1"
if errorlevel 1 (
  echo.
  echo LightCull could not start. Please see README.md / README.en.md.
  pause
)
endlocal
