<p align="center">
  <b>ZeroSetup</b>
</p>

<p align="center">
  <b>Windows 零配置啟動框架 — 讓任何專案一鍵即用</b>
  <br>
  全新電腦也能跑，不需要預先安裝任何東西
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"></a>
</p>

<p align="center">
  繁體中文 | <a href="README.zh-CN.md">简体中文</a> | <a href="README.en.md">English</a>
</p>

## 🔍 這是什麼？

ZeroSetup 是一套 Windows 批次腳本框架，讓你的專案可以：

```
git clone → run.bat → 直接能用
```

**不需要用戶預先安裝：**
- Python
- Node.js
- Git
- FFmpeg
- 任何依賴套件

## ✨ 特色

| 功能 | 說明 |
|------|------|
| 🎯 零配置 | 全新電腦雙擊就能跑 |
| 🔄 自動更新 | Git pull + 依賴更新 + 優雅重啟 |
| 🛡️ 優雅重啟 | 等待任務完成才重啟 |
| 📦 多語言支援 | Python / Node.js |
| ⚙️ 可配置 | 一個設定檔搞定 |

## 🚀 如何使用

### 1. 複製到你的專案

```bash
# 複製這些檔案到你的專案根目錄
run.bat
auto-update.bat
auto-update-loop.bat
stop.bat
zerosetup.config.example.bat
```

### 2. 建立設定檔

```bash
# 複製範例設定
copy zerosetup.config.example.bat zerosetup.config.bat
```

### 3. 修改設定

```batch
:: zerosetup.config.bat

:: 應用程式資訊
set APP_NAME=My Awesome App
set APP_URL=http://localhost:8000

:: 執行模式: python | node | npm
set RUN_MODE=python
set MAIN_FILE=main.py

:: 依賴需求 (1=需要, 0=不需要)
set NEED_PYTHON=1
set NEED_NODE=0
set NEED_GIT=1
set NEED_FFMPEG=0

:: 健康檢查端點
set HEALTH_URL=http://localhost:8000/health
```

### 4. 完成！

用戶只需要：

```bash
git clone https://github.com/你的帳號/你的專案.git
cd 你的專案
run.bat
```

## 📁 檔案說明

| 檔案 | 用途 |
|------|------|
| `run.bat` | 主啟動腳本，自動安裝依賴並啟動 |
| `auto-update.bat` | 單次更新檢查 |
| `auto-update-loop.bat` | 持續更新循環（每 5 分鐘） |
| `stop.bat` | 停止所有服務 |
| `zerosetup.config.bat` | 你的專案設定 |

## 🎯 支援的依賴

| 依賴 | winget 套件 ID |
|------|---------------|
| Python 3.11 | `Python.Python.3.11` |
| Node.js LTS | `OpenJS.NodeJS.LTS` |
| Git | `Git.Git` |
| FFmpeg | `FFmpeg` |

需要其他依賴？在 `run.bat` 中加入：

```batch
winget install 套件ID --accept-package-agreements --accept-source-agreements
```

## 🔄 自動更新機制

1. 每 5 分鐘檢查 GitHub 是否有新 commit
2. 如果有更新，等待進行中的任務完成
3. 更新依賴（pip install / npm install）
4. 重啟服務

### 優雅重啟 API（可選）

在你的應用程式中實作：

```
GET /api/can-restart
```

回傳：
```json
{"can_restart": true}   // 沒有任務，可以重啟
{"can_restart": false}  // 有任務進行中，等一下
```

## 📋 系統需求

- Windows 10 1709+ 或 Windows 11
- 需要 winget（App Installer）

> 大多數 Windows 10/11 已內建 winget

## 🤝 貢獻

歡迎 Issue 和 PR！

## 📜 License

MIT - 自由使用、修改、分發

---

<p align="center">
  <b>讓用戶專注在使用，而不是設環境</b>
</p>
