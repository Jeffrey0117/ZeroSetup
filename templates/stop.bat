@echo off
chcp 65001 >nul
cd /d "%~dp0"

:: ======================================================================
::  ZeroSetup - Universal Stop Script
::  https://github.com/Jeffrey0117/ZeroSetup
:: ======================================================================

REM --- Read config ---
set "ZS_NAME="
set "ZS_STOP="

if exist "zerosetup.json" (
  node --version >nul 2>&1
  if not errorlevel 1 (
    for /f "delims=" %%n in ('node -e "console.log(require('./zerosetup.json').name||'')" 2^>nul') do set "ZS_NAME=%%n"
    for /f "delims=" %%s in ('node -e "const s=require('./zerosetup.json').scripts;console.log(s&&s.stop||'')" 2^>nul') do set "ZS_STOP=%%s"
  )
)

if "%ZS_NAME%"=="" (
  for %%I in ("%~dp0.") do set "ZS_NAME=%%~nI"
)

echo.
echo   Stopping %ZS_NAME%...

REM --- Custom stop command ---
if not "%ZS_STOP%"=="" (
  echo   Running: %ZS_STOP%
  call %ZS_STOP%
  echo.
  echo   %ZS_NAME% stopped.
  pause
  exit /b 0
)

REM --- Default: kill by window title ---
taskkill /f /fi "WINDOWTITLE eq %ZS_NAME%*" >nul 2>&1
taskkill /f /fi "WINDOWTITLE eq %ZS_NAME% - ZeroSetup*" >nul 2>&1

echo.
echo   %ZS_NAME% stopped.
pause
