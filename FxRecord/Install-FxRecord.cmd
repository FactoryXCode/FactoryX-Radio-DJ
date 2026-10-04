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
sc.exe query FxRecord

echo.
echo FxRecord is installed with delayed automatic startup and failure recovery.
endlocal
