<p align="center">
  <b>ZeroSetup</b>
</p>

<p align="center">
  <b>Windows Zero-Config Startup Framework — One-Click for Any Project</b>
  <br>
  Works on a fresh PC, no pre-installation required
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"></a>
</p>

<p align="center">
  <a href="README.md">繁體中文</a> | <a href="README.zh-CN.md">简体中文</a> | English
</p>

## 🔍 What is this?

ZeroSetup is a Windows batch script framework that lets your project:

```
git clone → run.bat → Just works
```

**Users don't need to pre-install:**
- Python
- Node.js
- Git
- FFmpeg
- Any dependencies

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎯 Zero Config | Double-click on fresh PC |
| 🔄 Auto Update | Git pull + deps update + graceful restart |
| 🛡️ Graceful Restart | Waits for tasks to complete |
| 📦 Multi-Language | Python / Node.js |
| ⚙️ Configurable | One config file |

## 🚀 How to Use

### 1. Copy to Your Project

```bash
# Copy these files to your project root
run.bat
auto-update.bat
auto-update-loop.bat
stop.bat
zerosetup.config.example.bat
```

### 2. Create Config File

```bash
# Copy example config
copy zerosetup.config.example.bat zerosetup.config.bat
```

### 3. Modify Config

```batch
:: zerosetup.config.bat

:: App info
set APP_NAME=My Awesome App
set APP_URL=http://localhost:8000

:: Run mode: python | node | npm
set RUN_MODE=python
set MAIN_FILE=main.py

:: Dependencies (1=need, 0=don't need)
set NEED_PYTHON=1
set NEED_NODE=0
set NEED_GIT=1
set NEED_FFMPEG=0

:: Health check endpoint
set HEALTH_URL=http://localhost:8000/health
```

### 4. Done!

Users just need to:

```bash
git clone https://github.com/your-account/your-project.git
cd your-project
run.bat
```

## 📁 File Descriptions

| File | Purpose |
|------|---------|
| `run.bat` | Main startup script, auto-installs deps and starts |
| `auto-update.bat` | Single update check |
| `auto-update-loop.bat` | Continuous update loop (every 5 min) |
| `stop.bat` | Stops all services |
| `zerosetup.config.bat` | Your project config |

## 🎯 Supported Dependencies

| Dependency | winget Package ID |
|------------|------------------|
| Python 3.11 | `Python.Python.3.11` |
| Node.js LTS | `OpenJS.NodeJS.LTS` |
| Git | `Git.Git` |
| FFmpeg | `FFmpeg` |

Need other dependencies? Add to `run.bat`:

```batch
winget install PackageID --accept-package-agreements --accept-source-agreements
```

## 🔄 Auto Update Mechanism

1. Checks GitHub for new commits every 5 minutes
2. If update found, waits for running tasks to complete
3. Updates dependencies (pip install / npm install)
4. Restarts service

### Graceful Restart API (Optional)

Implement in your app:

```
GET /api/can-restart
```

Returns:
```json
{"can_restart": true}   // No tasks, safe to restart
{"can_restart": false}  // Tasks running, wait
```

## 📋 System Requirements

- Windows 10 1709+ or Windows 11
- Requires winget (App Installer)

> Most Windows 10/11 have winget built-in

## 🤝 Contributing

Issues and PRs welcome!

## 📜 License

MIT - Free to use, modify, and distribute

---

<p align="center">
  <b>Let users focus on using, not setting up</b>
</p>
