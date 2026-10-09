@echo off
setlocal

if not exist "%~dp0FxRecord.exe" (
  echo FxRecord.exe was not found in %~dp0
  exit /b 1
)

if not exist "%~dp0FxRecord.ini" (
  echo FxRecord.ini was not found in %~dp0
  exit /b 1
)

"%~dp0FxRecord.exe" --install --config "%~dp0FxRecord.ini"
if errorlevel 1 exit /b %errorlevel%

sc.exe start FxRecord
if errorlevel 1 exit /b %errorlevel%
sc.exe query FxRecord
if errorlevel 1 exit /b %errorlevel%

echo.
echo FxRecord is installed with automatic startup and failure recovery.
echo Check FxRecord.log for the delayed-start setting and any warnings.
endlocal
