@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-android-emulator.ps1" %*
exit /b %ERRORLEVEL%
