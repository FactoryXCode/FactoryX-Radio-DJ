@echo off
setlocal
"%~dp0FxRecord.exe" --uninstall
if errorlevel 1 exit /b %errorlevel%
echo FxRecord service registration was removed. Files were not deleted.
endlocal
