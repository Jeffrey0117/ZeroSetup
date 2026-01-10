@echo off
chcp 65001 >nul
:: ZeroSetup 自動更新腳本 (含優雅重啟)

cd /d "%~dp0"

:: 載入設定
if exist "zerosetup.config.bat" call zerosetup.config.bat

:: 建立 logs 資料夾
if not exist logs mkdir logs

:: 儲存更新前的 commit hash
for /f "tokens=*" %%i in ('git rev-parse HEAD 2^>nul') do set OLD_HASH=%%i

:: 拉取最新更新
git pull origin main >nul 2>&1

:: 取得更新後的 commit hash
for /f "tokens=*" %%i in ('git rev-parse HEAD 2^>nul') do set NEW_HASH=%%i

:: 比較 hash - 有變化才重啟
if not "%OLD_HASH%"=="%NEW_HASH%" (
    echo [%date% %time%] 發現更新: %OLD_HASH:~0,7% to %NEW_HASH:~0,7% >> logs\auto-update.log
    call :graceful_restart
)

goto :eof

:graceful_restart
:: 最多等待 10 分鐘
set max_wait=60
set wait_count=0

:check_loop
:: 檢查是否可以重啟 (如果有設定 HEALTH_URL)
if "%HEALTH_URL%"=="" goto :do_restart

powershell -Command "try { $r = Invoke-WebRequest -Uri '%HEALTH_URL%' -UseBasicParsing -TimeoutSec 5; exit 0 } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
    echo [%date% %time%] 服務未響應，直接重啟 >> logs\auto-update.log
    goto :do_restart
)

:: 如果有 /api/can-restart 端點，檢查是否有進行中的任務
curl -s -o "%TEMP%\zerosetup_restart.json" http://localhost:8000/api/can-restart 2>nul
if exist "%TEMP%\zerosetup_restart.json" (
    findstr /c:"\"can_restart\": true" "%TEMP%\zerosetup_restart.json" >nul 2>&1
    if %errorlevel%==0 goto :do_restart

    set /a wait_count+=1
    if %wait_count% geq %max_wait% (
        echo [%date% %time%] 等待超時，強制重啟 >> logs\auto-update.log
        goto :do_restart
    )

    echo [%date% %time%] 有任務進行中，等待... (%wait_count%/%max_wait%) >> logs\auto-update.log
    timeout /t 10 /nobreak >nul
    goto :check_loop
)

:do_restart
:: 停止舊服務
taskkill /f /fi "WINDOWTITLE eq %APP_NAME%*" >nul 2>&1
timeout /t 2 /nobreak >nul

:: 更新 Python 依賴 (如果有)
if "%NEED_PYTHON%"=="1" (
    if exist "requirements.txt" (
        pip install -r requirements.txt -q >nul 2>&1
        echo [%date% %time%] Python 依賴已更新 >> logs\auto-update.log
    )
)

:: 更新 Node.js 依賴 (如果有)
if "%NEED_NODE%"=="1" (
    if exist "package.json" (
        npm install >nul 2>&1
        echo [%date% %time%] Node.js 依賴已更新 >> logs\auto-update.log
    )
)

:: 啟動新服務
if "%RUN_MODE%"=="python" (
    start "%APP_NAME%" /min cmd /c "chcp 65001 >nul && cd /d %~dp0 && python %MAIN_FILE%"
)
if "%RUN_MODE%"=="node" (
    start "%APP_NAME%" /min cmd /c "cd /d %~dp0 && node %MAIN_FILE%"
)
if "%RUN_MODE%"=="npm" (
    start "%APP_NAME%" /min cmd /c "cd /d %~dp0 && npm start"
)

echo [%date% %time%] 服務已重啟 >> logs\auto-update.log

:: 清理暫存
del "%TEMP%\zerosetup_restart.json" >nul 2>&1
goto :eof
