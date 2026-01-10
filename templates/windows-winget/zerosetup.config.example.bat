@echo off
:: ╔══════════════════════════════════════════════════════════════════╗
:: ║  ZeroSetup 設定檔                                                ║
:: ║  複製此檔案為 zerosetup.config.bat 並修改設定                    ║
:: ╚══════════════════════════════════════════════════════════════════╝

:: ========== 應用程式資訊 ==========
set APP_NAME=My App
set APP_URL=http://localhost:8000

:: ========== 執行模式 ==========
:: python | node | npm
set RUN_MODE=python
set MAIN_FILE=main.py

:: ========== 依賴需求 (1=需要, 0=不需要) ==========
set NEED_PYTHON=1
set NEED_NODE=0
set NEED_GIT=1
set NEED_FFMPEG=0

:: ========== Python 設定 ==========
:: 用來檢查依賴是否已安裝的套件名稱
set PIP_CHECK_PACKAGE=fastapi

:: ========== 健康檢查 ==========
:: 留空則跳過檢查
set HEALTH_URL=http://localhost:8000/health
