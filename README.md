<p align="center">
  <b>ZeroSetup 2.0</b>
</p>

<p align="center">
  <b>讓你的 GitHub 專案，任何人雙擊就能跑</b>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"></a>
</p>

## 問題

你寫了一個很棒的工具放上 GitHub。然後使用者看到你的 README：

```
安裝步驟：
1. 安裝 Python 3.11
2. 安裝 FFmpeg 並加入 PATH
3. git clone 本專案
4. pip install -r requirements.txt
5. python main.py
```

**90% 的人在第 1 步就關掉了。**

他們不是工程師。他們不知道 PATH 是什麼、pip 是什麼。他們只是想用你的工具。

## 解法

用 ZeroSetup 掃一下你的專案，它會生成 `setup.bat`。使用者只需要：

```
git clone https://github.com/你/你的專案.git
雙擊 setup.bat
```

沒了。Python、FFmpeg、pip install，全部自動處理。

## 使用者看到的

```
  ZeroSetup
  =========

  [Phase 1] Bootstrap...
    Installing Node.js...    ← 自動裝
    Node.js OK

  [Phase 2] Reading config...
    Found zerosetup.json

  [Phase 3] Installing dependencies...
    Installing Python...     ← 自動裝
    Python OK
    Installing FFmpeg...     ← 自動裝
    FFmpeg OK
    Running pip install...   ← 自動裝
    pip dependencies OK

  [Phase 4] Starting...
    Running: python main.py
    Service is healthy!

  ========================================
  YourApp started!
  ========================================

  URL: http://localhost:8000
```

使用者什麼都不用懂。雙擊，等它跑完，打開瀏覽器。

## 你（開發者）要做什麼

只要一次，一行指令：

```bash
# 裝過一次就好
npm i -g zerosetup

# 在你的專案目錄跑
cd your-project
zerosetup init
```

或者不想裝，直接 npx：

```bash
cd your-project
npx zerosetup
```

它會自動掃描你的專案，偵測出所有需要的東西，生成三個檔案：

| 生成的檔案 | 用途 |
|-----------|------|
| `zerosetup.json` | 你的專案需要什麼（runtime、dependencies、start command） |
| `setup.bat` | 通用啟動腳本（使用者雙擊這個） |
| `stop.bat` | 通用停止腳本 |

把這三個檔案 commit 進你的專案就好。

## 自動偵測什麼

你不用手動填任何設定。它掃描你的專案自動判斷：

| 偵測項目 | 怎麼偵測 |
|---------|---------|
| Node.js / Python | 有 `package.json` 或 `requirements.txt` |
| Express / FastAPI / PM2 / Next.js... | 看 dependencies 和設定檔 |
| Port | 掃 `.env`、`config.json`、原始碼 `.listen()` |
| FFmpeg / cloudflared 等系統工具 | 掃原始碼關鍵字 |
| npm globals (pm2, pnpm) | 看 lock file 和 ecosystem.config.js |
| 怎麼啟動 / 怎麼停止 | 根據 framework 自動決定 |

## 生成的 zerosetup.json 範例

```json
{
  "name": "my-video-tool",
  "runtime": "python",
  "entry": "main.py",
  "port": 8000,
  "health": "http://localhost:8000/health",
  "dependencies": {
    "winget": ["FFmpeg.FFmpeg"],
    "pip": true
  },
  "scripts": {
    "start": "python main.py"
  }
}
```

想加東西？直接改這個 JSON 就好。

## Before / After

**Before（沒有 ZeroSetup）：**

```
你的 README：
  1. 安裝 Python 3.11
  2. 安裝 FFmpeg
  3. 設定 PATH
  4. pip install -r requirements.txt
  5. python main.py

使用者：看不懂，關掉。
```

**After（有 ZeroSetup）：**

```
你的 README：
  git clone → 雙擊 setup.bat

使用者：好，開了。能用了。
```

## 系統需求

使用者端：
- Windows 10 1709+ 或 Windows 11
- winget（大多數 Windows 已內建）
- 需要網路（首次安裝依賴）

開發者端：
- Node.js（跑 init.js 用）

## License

MIT
