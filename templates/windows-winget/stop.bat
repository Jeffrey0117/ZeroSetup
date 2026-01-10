@echo off
chcp 65001 >nul
cd /d "%~dp0"

:: 載入設定
if exist "zerosetup.config.bat" call zerosetup.config.bat

echo 正在停止 %APP_NAME%...

:: 停止主服務
taskkill /f /fi "WINDOWTITLE eq %APP_NAME%*" >nul 2>&1

:: 停止更新服務
taskkill /f /fi "WINDOWTITLE eq *auto-update*" >nul 2>&1
taskkill /f /fi "WINDOWTITLE eq *updater*" >nul 2>&1

echo [OK] 已停止所有服務
pause
