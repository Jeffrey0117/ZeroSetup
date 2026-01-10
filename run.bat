@echo off
chcp 65001 >nul
title %APP_NAME% - ZeroSetup
cd /d "%~dp0"

:: ╔══════════════════════════════════════════════════════════════════╗
:: ║  ZeroSetup - Windows 零配置啟動框架                              ║
:: ║  https://github.com/Jeffrey0117/ZeroSetup                        ║
:: ╚══════════════════════════════════════════════════════════════════╝

:: ========== 載入設定 ==========
if not exist "zerosetup.config.bat" (
    echo [錯誤] 找不到 zerosetup.config.bat
    echo 請複製 zerosetup.config.example.bat 並重新命名
    pause
    exit /b 1
)
call zerosetup.config.bat

:: ========== 檢查 winget ==========
winget --version >nul 2>&1
if errorlevel 1 (
    echo [錯誤] 需要 winget 來自動安裝依賴
    echo.
    echo 請先更新 Windows 或手動安裝 App Installer:
    echo https://aka.ms/getwinget
    echo.
    pause
    exit /b 1
)

echo ══════════════════════════════════════════════════
echo   %APP_NAME%
echo ══════════════════════════════════════════════════
echo.

:: ========== 檢查 Python ==========
if "%NEED_PYTHON%"=="1" (
    echo [1/4] 檢查 Python...
    python --version >nul 2>&1
    if errorlevel 1 (
        echo [!] Python 未安裝，正在安裝...
        winget install Python.Python.3.11 --accept-package-agreements --accept-source-agreements
        if errorlevel 1 (
            echo [錯誤] Python 安裝失敗！
            pause
            exit /b 1
        )
        echo [!] 請重新開啟命令提示字元後再執行
        pause
        exit /b 0
    )
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do echo [OK] Python %%i
)

:: ========== 檢查 Node.js ==========
if "%NEED_NODE%"=="1" (
    echo [2/4] 檢查 Node.js...
    node --version >nul 2>&1
    if errorlevel 1 (
        echo [!] Node.js 未安裝，正在安裝...
        winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
        if errorlevel 1 (
            echo [錯誤] Node.js 安裝失敗！
            pause
            exit /b 1
        )
        echo [!] 請重新開啟命令提示字元後再執行
        pause
        exit /b 0
    )
    for /f "tokens=1" %%i in ('node --version 2^>^&1') do echo [OK] Node.js %%i
)

:: ========== 檢查 Git ==========
if "%NEED_GIT%"=="1" (
    echo [3/4] 檢查 Git...
    git --version >nul 2>&1
    if errorlevel 1 (
        echo [!] Git 未安裝，正在安裝...
        winget install Git.Git --accept-package-agreements --accept-source-agreements
        if errorlevel 1 (
            echo [錯誤] Git 安裝失敗！
            pause
            exit /b 1
        )
        echo [!] 請重新開啟命令提示字元後再執行
        pause
        exit /b 0
    )
    for /f "tokens=3" %%i in ('git --version 2^>^&1') do echo [OK] Git %%i
)

:: ========== 檢查 FFmpeg ==========
if "%NEED_FFMPEG%"=="1" (
    echo [4/4] 檢查 FFmpeg...
    ffmpeg -version >nul 2>&1
    if errorlevel 1 (
        echo [!] FFmpeg 未安裝，正在安裝...
        winget install FFmpeg --accept-package-agreements --accept-source-agreements >nul 2>&1
        echo [OK] FFmpeg 已安裝 (需重啟終端生效^)
    ) else (
        echo [OK] FFmpeg 已安裝
    )
)

:: ========== 安裝依賴 ==========
echo.
echo [*] 檢查依賴...

if "%NEED_PYTHON%"=="1" (
    if exist "requirements.txt" (
        pip show %PIP_CHECK_PACKAGE% >nul 2>&1
        if errorlevel 1 (
            echo [*] 安裝 Python 依賴...
            pip install -r requirements.txt -q
        )
        echo [OK] Python 依賴已就緒
    )
)

if "%NEED_NODE%"=="1" (
    if exist "package.json" (
        if not exist "node_modules" (
            echo [*] 安裝 Node.js 依賴...
            npm install
        )
        echo [OK] Node.js 依賴已就緒
    )
)

:: ========== 啟動應用程式 ==========
echo.
echo [*] 啟動 %APP_NAME%...

if "%RUN_MODE%"=="python" (
    start "%APP_NAME%" /min cmd /c "cd /d %~dp0 && python %MAIN_FILE%"
)

if "%RUN_MODE%"=="node" (
    start "%APP_NAME%" /min cmd /c "cd /d %~dp0 && node %MAIN_FILE%"
)

if "%RUN_MODE%"=="npm" (
    start "%APP_NAME%" /min cmd /c "cd /d %~dp0 && npm start"
)

:: ========== 等待並檢查 ==========
if not "%HEALTH_URL%"=="" (
    echo [*] 等待服務啟動...
    set RETRY=0
    :CHECK_HEALTH
    timeout /t 2 /nobreak >nul
    powershell -Command "try { Invoke-WebRequest -Uri '%HEALTH_URL%' -UseBasicParsing -TimeoutSec 5 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if errorlevel 1 (
        set /a RETRY+=1
        if %RETRY% lss 5 (
            echo     Retry %RETRY%/5...
            goto :CHECK_HEALTH
        )
        echo [警告] 服務可能還在啟動中
    ) else (
        echo [OK] 服務已就緒
    )
)

:: ========== 完成 ==========
echo.
echo ══════════════════════════════════════════════════
echo   %APP_NAME% 已啟動！
echo ══════════════════════════════════════════════════
echo.
if not "%APP_URL%"=="" echo   網址: %APP_URL%
echo   停止: 關閉最小化的視窗
echo.
pause
