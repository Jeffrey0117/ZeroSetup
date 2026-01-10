# Windows 原生方案 (winget)

使用 Windows 內建的 winget 套件管理器，自動安裝所有依賴。

## 特色

- 🎯 **零配置** — 全新電腦雙擊 `run.bat` 就能跑
- 🔄 **自動更新** — Git pull + 依賴更新 + 優雅重啟
- 🛡️ **優雅重啟** — 等待進行中的任務完成才重啟
- 📦 **多語言支援** — Python / Node.js
- ⚙️ **可配置** — 一個設定檔搞定

## 系統需求

- Windows 10 1709+ 或 Windows 11
- winget（大多數系統已內建）

## 快速開始

### 1. 複製檔案

將以下檔案複製到你的專案根目錄：

```
run.bat
auto-update.bat
auto-update-loop.bat
stop.bat
zerosetup.config.example.bat
```

### 2. 建立設定檔

```bash
copy zerosetup.config.example.bat zerosetup.config.bat
```

### 3. 修改設定

編輯 `zerosetup.config.bat`：

```batch
:: 應用程式資訊
set APP_NAME=My App
set APP_URL=http://localhost:8000

:: 執行模式: python | node | npm
set RUN_MODE=python
set MAIN_FILE=main.py

:: 依賴需求 (1=需要, 0=不需要)
set NEED_PYTHON=1
set NEED_NODE=0
set NEED_GIT=1
set NEED_FFMPEG=0

:: 健康檢查
set HEALTH_URL=http://localhost:8000/health
```

### 4. 完成！

使用者只需要：

```bash
git clone https://github.com/你的帳號/你的專案.git
cd 你的專案
run.bat
```

## 檔案說明

| 檔案 | 用途 |
|------|------|
| `run.bat` | 主啟動腳本，自動安裝依賴並啟動 |
| `auto-update.bat` | 單次更新檢查 |
| `auto-update-loop.bat` | 持續更新循環（每 5 分鐘） |
| `stop.bat` | 停止所有服務 |
| `zerosetup.config.bat` | 你的專案設定 |

## 支援的依賴

| 依賴 | winget 套件 ID |
|------|---------------|
| Python 3.11 | `Python.Python.3.11` |
| Node.js LTS | `OpenJS.NodeJS.LTS` |
| Git | `Git.Git` |
| FFmpeg | `Gyan.FFmpeg` |

需要其他依賴？在 `run.bat` 中加入：

```batch
winget install 套件ID --accept-package-agreements --accept-source-agreements
```

## 優雅重啟 API（可選）

在你的應用程式中實作：

```
GET /api/can-restart
```

回傳：
```json
{"can_restart": true}   // 沒有任務，可以重啟
{"can_restart": false}  // 有任務進行中，等一下
```

## 適用場景

✅ **適合**
- Windows 使用者
- 內部工具 / 企業應用
- 持續開發中的專案
- 不想用 Docker

❌ **不適合**
- 需要離線使用
- 需要跨平台（macOS/Linux）
- 需要保護程式碼
