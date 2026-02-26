<p align="center">
  <b>ZeroSetup 2.0</b>
</p>

<p align="center">
  <b>掃一下就生成啟動腳本 — 全新電腦雙擊就能跑</b>
  <br>
  自動偵測專案類型、自動裝依賴、自動啟動，零人工介入
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"></a>
</p>

## 這是什麼？

一個指令掃描你的專案，自動生成 `zerosetup.json` + `run.bat` + `stop.bat`。

拿到任何一台全新 Windows 電腦：

```
git clone → run.bat → 自動裝 Node.js/Python/PM2/FFmpeg/所有依賴 → 服務啟動
```

**不需要手動設定任何東西。**

## 運作方式

```
                    你的專案目錄
                         │
          node path/to/zerosetup/init.js
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
   偵測 runtime      偵測 framework    偵測 dependencies
   (Node/Python)    (PM2/Express/     (cloudflared/FFmpeg/
                     FastAPI/Next)     npm globals)
         │               │               │
         └───────────────┼───────────────┘
                         ▼
               生成 zerosetup.json
               複製 run.bat + stop.bat
                         │
                         ▼
              全新電腦雙擊 run.bat
                         │
         ┌───────┬───────┼───────┬──────────┐
         ▼       ▼       ▼       ▼          ▼
      裝 Node  裝 Git  裝 PM2  winget     npm/pip
      (winget) (winget) (npm)  自訂套件   install
                         │
                         ▼
                    啟動 + Health Check
```

## 快速開始

```bash
# 對任何專案跑一次 init
node C:\path\to\zerosetup\init.js C:\path\to\your-project

# 輸出：
#   Runtime:    node
#   Framework:  pm2
#   Entry:      index.js
#   Port:       8787
#   Start:      pm2 start ecosystem.config.js
#   Winget:     cloudflare.cloudflared, FFmpeg.FFmpeg
#   NPM Global: pm2
#
#   Created: zerosetup.json
#   Created: run.bat
#   Created: stop.bat
```

完成。以後任何人拿到這個專案，雙擊 `run.bat` 就能跑。

## 自動偵測能力

| 偵測項目 | 方法 |
|---------|------|
| Runtime | `package.json` → Node.js、`requirements.txt` → Python、都有 → both |
| Entry Point | `pkg.main` → 常見檔名 (server.js, app.js, main.py...) |
| Port | `.env` PORT → `config.json` → 原始碼 `.listen(PORT)` → scripts `--port` |
| Framework | PM2 (ecosystem.config.js)、Next.js、Express、FastAPI、Flask、Django |
| Start/Stop | PM2 → `pm2 start/delete`、npm scripts → `npm start`、否則 `node/python <entry>` |
| Winget 依賴 | 掃原始碼關鍵字：cloudflared、ffmpeg、ffprobe |
| NPM Global | PM2、pnpm (偵測 lock file) |

## 生成的 zerosetup.json

```json
{
  "name": "cloudpipe",
  "runtime": "node",
  "entry": "index.js",
  "port": 8787,
  "health": "http://localhost:8787/health",
  "dependencies": {
    "winget": ["cloudflare.cloudflared", "FFmpeg.FFmpeg"],
    "npm-global": ["pm2"],
    "npm": true
  },
  "scripts": {
    "start": "pm2 start ecosystem.config.js",
    "stop": "pm2 delete all"
  }
}
```

可以手動編輯加入更多依賴或自訂指令。

## run.bat 四階段

| 階段 | 動作 |
|------|------|
| Phase 1: Bootstrap | 確認 winget → 自動裝 Node.js → 自動裝 Git（如果有 .git） |
| Phase 2: 讀設定 | `node -e` 解析 `zerosetup.json` → 轉成 batch 變數 |
| Phase 3: 裝依賴 | Python → winget 套件 → npm globals → npm install → pip install |
| Phase 4: 啟動 | pre-start → start → health check（自動重試 5 次） |

PATH 刷新技巧：裝完軟體後從 Windows Registry 重新載入 PATH，不用重開終端。

## 檔案結構

```
zerosetup/
├── init.js              # CLI 入口：掃描 + 生成
├── lib/
│   ├── detect.js        # 自動偵測邏輯
│   └── generate.js      # 生成 zerosetup.json
├── templates/
│   ├── run.bat          # 通用啟動腳本（所有專案共用）
│   └── stop.bat         # 通用停止腳本
│   └── windows-winget/  # v1 舊模板（legacy）
└── package.json
```

## 系統需求

- Windows 10 1709+ 或 Windows 11
- winget（大多數 Windows 10/11 已內建）

## License

MIT

---

<p align="center">
  <b>讓用戶專注在使用，而不是設環境</b>
</p>
