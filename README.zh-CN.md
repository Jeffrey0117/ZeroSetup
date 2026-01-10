<p align="center">
  <b>ZeroSetup</b>
</p>

<p align="center">
  <b>Windows 零配置启动框架 — 让任何项目一键即用</b>
  <br>
  全新电脑也能跑，不需要预先安装任何东西
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"></a>
</p>

<p align="center">
  <a href="README.md">繁體中文</a> | 简体中文 | <a href="README.en.md">English</a>
</p>

## 🔍 这是什么？

ZeroSetup 是一套 Windows 批处理脚本框架，让你的项目可以：

```
git clone → run.bat → 直接能用
```

**不需要用户预先安装：**
- Python
- Node.js
- Git
- FFmpeg
- 任何依赖包

## ✨ 特色

| 功能 | 说明 |
|------|------|
| 🎯 零配置 | 全新电脑双击就能跑 |
| 🔄 自动更新 | Git pull + 依赖更新 + 优雅重启 |
| 🛡️ 优雅重启 | 等待任务完成才重启 |
| 📦 多语言支持 | Python / Node.js |
| ⚙️ 可配置 | 一个配置文件搞定 |

## 🚀 如何使用

### 1. 复制到你的项目

```bash
# 复制这些文件到你的项目根目录
run.bat
auto-update.bat
auto-update-loop.bat
stop.bat
zerosetup.config.example.bat
```

### 2. 创建配置文件

```bash
# 复制示例配置
copy zerosetup.config.example.bat zerosetup.config.bat
```

### 3. 修改配置

```batch
:: zerosetup.config.bat

:: 应用程序信息
set APP_NAME=My Awesome App
set APP_URL=http://localhost:8000

:: 运行模式: python | node | npm
set RUN_MODE=python
set MAIN_FILE=main.py

:: 依赖需求 (1=需要, 0=不需要)
set NEED_PYTHON=1
set NEED_NODE=0
set NEED_GIT=1
set NEED_FFMPEG=0

:: 健康检查端点
set HEALTH_URL=http://localhost:8000/health
```

### 4. 完成！

用户只需要：

```bash
git clone https://github.com/你的账号/你的项目.git
cd 你的项目
run.bat
```

## 📁 文件说明

| 文件 | 用途 |
|------|------|
| `run.bat` | 主启动脚本，自动安装依赖并启动 |
| `auto-update.bat` | 单次更新检查 |
| `auto-update-loop.bat` | 持续更新循环（每 5 分钟） |
| `stop.bat` | 停止所有服务 |
| `zerosetup.config.bat` | 你的项目配置 |

## 🎯 支持的依赖

| 依赖 | winget 包 ID |
|------|-------------|
| Python 3.11 | `Python.Python.3.11` |
| Node.js LTS | `OpenJS.NodeJS.LTS` |
| Git | `Git.Git` |
| FFmpeg | `FFmpeg` |

需要其他依赖？在 `run.bat` 中添加：

```batch
winget install 包ID --accept-package-agreements --accept-source-agreements
```

## 🔄 自动更新机制

1. 每 5 分钟检查 GitHub 是否有新 commit
2. 如果有更新，等待进行中的任务完成
3. 更新依赖（pip install / npm install）
4. 重启服务

### 优雅重启 API（可选）

在你的应用程序中实现：

```
GET /api/can-restart
```

返回：
```json
{"can_restart": true}   // 没有任务，可以重启
{"can_restart": false}  // 有任务进行中，等一下
```

## 📋 系统要求

- Windows 10 1709+ 或 Windows 11
- 需要 winget（App Installer）

> 大多数 Windows 10/11 已内置 winget

## 🤝 贡献

欢迎 Issue 和 PR！

## 📜 License

MIT - 自由使用、修改、分发

---

<p align="center">
  <b>让用户专注在使用，而不是配环境</b>
</p>
