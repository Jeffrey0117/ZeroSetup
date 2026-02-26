@echo off
chcp 65001 >nul
cd /d "%~dp0"

:: ======================================================================
::  ZeroSetup - Universal Run Script
::  https://github.com/Jeffrey0117/ZeroSetup
::
::  Reads zerosetup.json, auto-installs everything, starts your app.
::  Works on a fresh Windows machine with only winget available.
:: ======================================================================

echo.
echo   ZeroSetup
echo   =========
echo.

REM ============================================================
REM  Phase 1: Bootstrap (no Node.js required yet)
REM ============================================================

echo [Phase 1] Bootstrap...

REM --- Check winget ---
winget --version >nul 2>&1
if errorlevel 1 (
  echo.
  echo   [ERROR] winget not found!
  echo   Install from: https://aka.ms/getwinget
  pause
  exit /b 1
)

REM --- Install Node.js (needed to parse zerosetup.json) ---
node --version >nul 2>&1
if errorlevel 1 (
  echo   Installing Node.js...
  winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements >nul 2>&1
  call :REFRESH_PATH
  node --version >nul 2>&1
  if errorlevel 1 (
    echo   [ERROR] Node.js install failed. Restart terminal and try again.
    pause
    exit /b 1
  )
)
echo   Node.js OK

REM --- Install Git (if this is a git repo) ---
if exist ".git" (
  git --version >nul 2>&1
  if errorlevel 1 (
    echo   Installing Git...
    winget install Git.Git --accept-source-agreements --accept-package-agreements >nul 2>&1
    call :REFRESH_PATH
  )
  echo   Git OK
)

REM ============================================================
REM  Phase 2: Read config (Node.js available now)
REM ============================================================

echo.
echo [Phase 2] Reading config...

REM --- Parse zerosetup.json into batch variables via node ---
if exist "zerosetup.json" (
  echo   Found zerosetup.json
  node -e "const c=require('./zerosetup.json');const d=c.dependencies||{};const s=c.scripts||{};const e=v=>String(v||'').replace(/\x22/g,'');const lines=[];lines.push('set \"ZS_NAME='+e(c.name)+'\"');lines.push('set \"ZS_RUNTIME='+e(c.runtime||'node')+'\"');lines.push('set \"ZS_ENTRY='+e(c.entry||'index.js')+'\"');lines.push('set \"ZS_PORT='+e(c.port)+'\"');lines.push('set \"ZS_HEALTH='+e(c.health)+'\"');lines.push('set \"ZS_PKG_MGR='+e(c.packageManager||'npm')+'\"');lines.push('set \"ZS_NPM='+(d.npm?'1':'0')+'\"');lines.push('set \"ZS_PIP='+(d.pip?'1':'0')+'\"');lines.push('set \"ZS_WINGET='+(d.winget?d.winget.map(e).join(','):'')+'\"');lines.push('set \"ZS_NPM_GLOBAL='+(d['npm-global']?d['npm-global'].map(e).join(','):'')+'\"');lines.push('set \"ZS_PRESTART='+e(s['pre-start'])+'\"');lines.push('set \"ZS_START='+e(s.start)+'\"');lines.push('set \"ZS_STOP='+e(s.stop)+'\"');console.log(lines.join('\n'));" > "%TEMP%\zs_vars.bat" 2>nul
  call "%TEMP%\zs_vars.bat"
  del "%TEMP%\zs_vars.bat" >nul 2>&1
) else (
  echo   No zerosetup.json found, using defaults...
  set "ZS_NAME=%~n0"
  set "ZS_RUNTIME=node"
  set "ZS_ENTRY=index.js"
  set "ZS_PORT="
  set "ZS_HEALTH="
  set "ZS_PKG_MGR=npm"
  set "ZS_NPM=1"
  set "ZS_PIP=0"
  set "ZS_WINGET="
  set "ZS_NPM_GLOBAL="
  set "ZS_PRESTART="
  set "ZS_START="
  set "ZS_STOP="
  if exist "package.json" (
    for /f "delims=" %%n in ('node -e "console.log(require('./package.json').name||'')" 2^>nul') do (
      if not "%%n"=="" set "ZS_NAME=%%n"
    )
  )
)

title %ZS_NAME% - ZeroSetup

echo   Name:    %ZS_NAME%
echo   Runtime: %ZS_RUNTIME%
echo   Entry:   %ZS_ENTRY%
if not "%ZS_PORT%"=="" echo   Port:    %ZS_PORT%

REM ============================================================
REM  Phase 3: Install dependencies
REM ============================================================

echo.
echo [Phase 3] Installing dependencies...

REM --- Python (if runtime is python or both) ---
if "%ZS_RUNTIME%"=="python" call :INSTALL_PYTHON
if "%ZS_RUNTIME%"=="both" call :INSTALL_PYTHON

REM --- Winget packages (comma-separated list) ---
if not "%ZS_WINGET%"=="" (
  for %%p in (%ZS_WINGET%) do (
    call :INSTALL_WINGET %%p
  )
)

REM --- NPM globals (comma-separated list) ---
if not "%ZS_NPM_GLOBAL%"=="" (
  for %%g in (%ZS_NPM_GLOBAL%) do (
    call :INSTALL_NPM_GLOBAL %%g
  )
)

REM --- Install JS dependencies (smart package manager) ---
if "%ZS_NPM%"=="1" (
  if exist "package.json" (
    if not exist "node_modules" (
      echo   Running %ZS_PKG_MGR% install...
      call %ZS_PKG_MGR% install >nul 2>&1
    )
    echo   %ZS_PKG_MGR% dependencies OK
  )
)

REM --- pip install ---
if "%ZS_PIP%"=="1" (
  if exist "requirements.txt" (
    echo   Running pip install...
    pip install -r requirements.txt -q >nul 2>&1
    echo   pip dependencies OK
  )
)

REM ============================================================
REM  Phase 4: Start application
REM ============================================================

echo.
echo [Phase 4] Starting %ZS_NAME%...

REM --- Pre-start script ---
if not "%ZS_PRESTART%"=="" (
  echo   Running pre-start: %ZS_PRESTART%
  call %ZS_PRESTART%
)

REM --- Start ---
if not "%ZS_START%"=="" (
  echo   Running: %ZS_START%
  call %ZS_START%
) else (
  REM Auto-detect start method — run in background window
  if "%ZS_RUNTIME%"=="python" (
    echo   Running: python %ZS_ENTRY%
    start "%ZS_NAME%" /min cmd /c "python %ZS_ENTRY%"
  ) else (
    if exist "package.json" (
      echo   Running: npm start
      start "%ZS_NAME%" /min cmd /c "npm start"
    ) else (
      echo   Running: node %ZS_ENTRY%
      start "%ZS_NAME%" /min cmd /c "node %ZS_ENTRY%"
    )
  )
)

REM --- Health check ---
if "%ZS_HEALTH%"=="" goto :SKIP_HEALTH

echo.
echo   Waiting for service...
set "ZS_RETRY=0"

:HEALTH_CHECK
timeout /t 2 /nobreak >nul
powershell -Command "try{Invoke-WebRequest -Uri '%ZS_HEALTH%' -UseBasicParsing -TimeoutSec 5|Out-Null;exit 0}catch{exit 1}" >nul 2>&1
if not errorlevel 1 (
  echo   Service is healthy!
  goto :SKIP_HEALTH
)
set /a ZS_RETRY+=1
if %ZS_RETRY% GEQ 5 (
  echo   [WARN] Service may still be starting...
  goto :SKIP_HEALTH
)
echo   Retry %ZS_RETRY%/5...
goto :HEALTH_CHECK

:SKIP_HEALTH

REM ============================================================
REM  Done
REM ============================================================

echo.
echo   ========================================
echo   %ZS_NAME% started!
echo   ========================================
echo.
if not "%ZS_PORT%"=="" echo   URL: http://localhost:%ZS_PORT%
echo   Stop: run stop.bat
echo.
pause
exit /b 0

REM ============================================================
REM  Subroutines
REM ============================================================

:INSTALL_PYTHON
python --version >nul 2>&1
if errorlevel 1 (
  echo   Installing Python...
  winget install Python.Python.3.11 --accept-source-agreements --accept-package-agreements >nul 2>&1
  call :REFRESH_PATH
  python --version >nul 2>&1
  if errorlevel 1 (
    echo   [ERROR] Python install failed. Restart terminal and try again.
    pause
    exit /b 1
  )
)
echo   Python OK
exit /b 0

:INSTALL_WINGET
echo   Checking %1...
winget list --id %1 >nul 2>&1
if errorlevel 1 (
  echo   Installing %1...
  winget install %1 --accept-source-agreements --accept-package-agreements >nul 2>&1
  call :REFRESH_PATH
)
echo   %1 OK
exit /b 0

:INSTALL_NPM_GLOBAL
call %1 --version >nul 2>&1
if errorlevel 1 (
  echo   Installing %1 globally...
  call npm install -g %1 >nul 2>&1
  call :REFRESH_PATH
)
echo   %1 OK
exit /b 0

:REFRESH_PATH
for /f "tokens=2*" %%a in ('reg query "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SysPath=%%b"
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "UserPath=%%b"
set "PATH=%SysPath%;%UserPath%"
exit /b 0
