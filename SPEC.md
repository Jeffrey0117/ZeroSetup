# ZeroSetup 規格文檔

> 零配置啟動方案指南 — 讓任何專案一鍵即用

## 專案定位

ZeroSetup 不只是一個框架，而是一個**方案指南 + 模板集合**，幫助開發者選擇最適合的零配置啟動方案。

```
使用者需求 → 選擇方案 → 複製模板 → 一鍵啟動
```

---

## 目錄結構

```
ZeroSetup/
├── README.md                    # 專案說明
├── SPEC.md                      # 本規格文檔
├── LICENSE                      # MIT License
│
├── docs/                        # 官網 (GitHub Pages)
│   └── index.html               # 方案選擇器官網
│
├── templates/                   # 各方案模板
│   ├── windows-winget/          # Windows 原生方案
│   ├── docker/                  # Docker 容器方案
│   ├── devcontainer/            # VS Code Dev Container
│   ├── codespaces/              # GitHub Codespaces
│   ├── gitpod/                  # GitPod
│   └── package/                 # 打包工具設定範例
│
└── examples/                    # 完整範例專案
    ├── python-fastapi/          # Python FastAPI 範例
    └── node-express/            # Node.js Express 範例
```

---

## 方案規格

### 1. Windows 原生方案 (`templates/windows-winget/`)

**目標用戶**：Windows 10/11 使用者，不想裝 Docker

**原理**：使用 winget 自動安裝依賴，批次腳本啟動

#### 檔案清單

| 檔案 | 用途 | 狀態 |
|------|------|------|
| `run.bat` | 主啟動腳本 | ✅ 已完成 |
| `auto-update.bat` | 單次更新檢查 | ✅ 已完成 |
| `auto-update-loop.bat` | 持續更新循環 | ✅ 已完成 |
| `stop.bat` | 停止服務 | ✅ 已完成 |
| `zerosetup.config.example.bat` | 設定檔範例 | ✅ 已完成 |

#### 設定檔規格 (`zerosetup.config.bat`)

```batch
:: === 應用程式資訊 ===
set APP_NAME=My App              # 應用名稱，顯示在視窗標題
set APP_URL=http://localhost:8000 # 啟動後開啟的 URL

:: === 執行模式 ===
set RUN_MODE=python              # python | node | npm
set MAIN_FILE=main.py            # 主程式檔案 (python/node 模式)
set NPM_SCRIPT=start             # npm 腳本名稱 (npm 模式)

:: === 依賴需求 (1=需要, 0=不需要) ===
set NEED_PYTHON=1                # Python 3.11
set NEED_NODE=0                  # Node.js LTS
set NEED_GIT=1                   # Git
set NEED_FFMPEG=0                # FFmpeg

:: === 自動更新 ===
set HEALTH_URL=http://localhost:8000/health  # 健康檢查
set RESTART_CHECK_URL=http://localhost:8000/api/can-restart  # 優雅重啟
set UPDATE_INTERVAL=300          # 更新檢查間隔（秒）
```

#### 功能需求

- [x] 自動檢測並安裝 Python/Node.js/Git/FFmpeg
- [x] 自動安裝 pip/npm 依賴
- [x] 健康檢查，確認服務啟動
- [x] 自動開啟瀏覽器
- [x] Git pull 自動更新
- [x] 優雅重啟（等待任務完成）
- [ ] 多服務支援（同時啟動多個服務）
- [ ] 日誌輪替

---

### 2. Docker 容器方案 (`templates/docker/`)

**目標用戶**：已安裝 Docker，需要環境隔離

**原理**：Dockerfile + docker-compose 一鍵啟動

#### 檔案清單

| 檔案 | 用途 | 狀態 |
|------|------|------|
| `Dockerfile.python` | Python 基礎映像 | ⏳ 待開發 |
| `Dockerfile.node` | Node.js 基礎映像 | ⏳ 待開發 |
| `docker-compose.yml` | 服務編排範例 | ⏳ 待開發 |
| `docker-compose.dev.yml` | 開發環境（熱重載） | ⏳ 待開發 |
| `.dockerignore` | 忽略檔案 | ⏳ 待開發 |
| `run-docker.bat` | Windows 一鍵啟動 | ⏳ 待開發 |
| `run-docker.sh` | Linux/Mac 一鍵啟動 | ⏳ 待開發 |

#### Dockerfile 規格 (Python)

```dockerfile
FROM python:3.11-slim

# 設定工作目錄
WORKDIR /app

# 安裝系統依賴（可選）
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 複製依賴檔案
COPY requirements.txt .

# 安裝 Python 依賴
RUN pip install --no-cache-dir -r requirements.txt

# 複製應用程式碼
COPY . .

# 暴露埠號
EXPOSE 8000

# 健康檢查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# 啟動命令
CMD ["python", "main.py"]
```

#### docker-compose 規格

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - ./data:/app/data        # 持久化資料
    environment:
      - ENV=production
    restart: unless-stopped

  # 可選：資料庫
  # db:
  #   image: postgres:15
  #   volumes:
  #     - db_data:/var/lib/postgresql/data

# volumes:
#   db_data:
```

#### 功能需求

- [ ] Python 基礎映像（含常用工具）
- [ ] Node.js 基礎映像
- [ ] 多階段構建（減少映像大小）
- [ ] 開發模式熱重載
- [ ] 健康檢查
- [ ] 日誌輸出
- [ ] 一鍵啟動腳本（跨平台）

---

### 3. VS Code Dev Container (`templates/devcontainer/`)

**目標用戶**：VS Code 用戶，想要一致的開發環境

**原理**：.devcontainer 設定，開啟專案自動進入容器

#### 檔案清單

| 檔案 | 用途 | 狀態 |
|------|------|------|
| `.devcontainer/devcontainer.json` | 容器設定 | ⏳ 待開發 |
| `.devcontainer/Dockerfile` | 開發環境映像 | ⏳ 待開發 |
| `.devcontainer/post-create.sh` | 安裝後腳本 | ⏳ 待開發 |

#### devcontainer.json 規格

```json
{
    "name": "Python Dev Container",
    "build": {
        "dockerfile": "Dockerfile"
    },
    "features": {
        "ghcr.io/devcontainers/features/git:1": {},
        "ghcr.io/devcontainers/features/github-cli:1": {}
    },
    "customizations": {
        "vscode": {
            "extensions": [
                "ms-python.python",
                "ms-python.vscode-pylance"
            ],
            "settings": {
                "python.defaultInterpreterPath": "/usr/local/bin/python"
            }
        }
    },
    "postCreateCommand": "pip install -r requirements.txt",
    "forwardPorts": [8000],
    "remoteUser": "vscode"
}
```

#### 功能需求

- [ ] Python 開發環境模板
- [ ] Node.js 開發環境模板
- [ ] 常用 VS Code 擴充套件預裝
- [ ] Git 設定
- [ ] 埠號轉發

---

### 4. GitHub Codespaces (`templates/codespaces/`)

**目標用戶**：想在瀏覽器開發，或無本機環境

**原理**：基於 devcontainer，GitHub 雲端運行

#### 檔案清單

| 檔案 | 用途 | 狀態 |
|------|------|------|
| `.devcontainer/devcontainer.json` | Codespaces 設定 | ⏳ 待開發 |
| `.github/codespaces/prebuild.yml` | 預建構設定 | ⏳ 待開發 |
| `README-badge.md` | 一鍵開啟按鈕範例 | ⏳ 待開發 |

#### README Badge 規格

```markdown
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/你的帳號/你的專案?quickstart=1)
```

#### 功能需求

- [ ] 與 devcontainer 共用設定
- [ ] 預建構加速啟動
- [ ] 一鍵開啟按鈕
- [ ] 免費額度說明

---

### 5. GitPod (`templates/gitpod/`)

**目標用戶**：開源替代 Codespaces，或需要更多免費額度

**原理**：.gitpod.yml 設定

#### 檔案清單

| 檔案 | 用途 | 狀態 |
|------|------|------|
| `.gitpod.yml` | GitPod 設定 | ⏳ 待開發 |
| `.gitpod.Dockerfile` | 自訂映像（可選） | ⏳ 待開發 |
| `README-badge.md` | 一鍵開啟按鈕範例 | ⏳ 待開發 |

#### .gitpod.yml 規格

```yaml
image: gitpod/workspace-python-3.11

tasks:
  - name: Setup
    init: pip install -r requirements.txt
    command: python main.py

ports:
  - port: 8000
    onOpen: open-preview
    visibility: public

vscode:
  extensions:
    - ms-python.python
```

#### README Badge 規格

```markdown
[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/你的帳號/你的專案)
```

#### 功能需求

- [ ] Python 環境模板
- [ ] Node.js 環境模板
- [ ] 預建構設定
- [ ] 一鍵開啟按鈕

---

### 6. 打包指南 (`templates/package/`)

**目標用戶**：需要分發單一執行檔

**原理**：提供打包工具設定範例和說明

#### 檔案清單

| 檔案 | 用途 | 狀態 |
|------|------|------|
| `pyinstaller/` | PyInstaller 設定範例 | ⏳ 待開發 |
| `nuitka/` | Nuitka 設定範例 | ⏳ 待開發 |
| `electron-builder/` | Electron 打包範例 | ⏳ 待開發 |
| `COMPARISON.md` | 工具比較指南 | ⏳ 待開發 |

---

## 範例專案規格

### Python FastAPI (`examples/python-fastapi/`)

完整範例，展示所有方案如何應用。

```
examples/python-fastapi/
├── main.py                      # FastAPI 主程式
├── requirements.txt             # Python 依賴
├── README.md                    # 說明文檔
│
├── run.bat                      # Windows 原生
├── zerosetup.config.bat
│
├── Dockerfile                   # Docker
├── docker-compose.yml
│
├── .devcontainer/               # Dev Container / Codespaces
│   └── devcontainer.json
│
└── .gitpod.yml                  # GitPod
```

#### main.py 規格

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Hello ZeroSetup!"}

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/api/can-restart")
def can_restart():
    # 檢查是否有進行中的任務
    return {"can_restart": True}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Node.js Express (`examples/node-express/`)

同樣提供完整的多方案範例。

---

## 官網規格 (`docs/index.html`)

### 功能需求

- [x] 方案選擇器（4 選項）
- [x] 各方案詳細說明
- [x] 比較表格
- [x] 響應式設計
- [ ] 語言切換（繁中/簡中/英文）
- [ ] 互動式決策樹
- [ ] 搜尋功能

### 決策樹邏輯

```
Q1: 你的使用者主要使用什麼系統？
├─ Windows → Q2
├─ macOS/Linux → Docker 或 雲端
└─ 混合/不確定 → Docker 或 雲端

Q2: 使用者願意安裝 Docker 嗎？
├─ 願意 → Docker
├─ 不願意 → Windows 原生 (winget)
└─ 不知道 → Windows 原生 (最簡單)

Q3: 需要離線使用嗎？
├─ 是 → 打包
└─ 否 → 繼續

Q4: 需要保護程式碼嗎？
├─ 是 → 編譯 (Nuitka)
└─ 否 → 選擇上述方案
```

---

## 開發優先順序

### Phase 1：整理現有 ✅
1. [x] 將現有 Windows 腳本移到 `templates/windows-winget/`
2. [x] 建立規格文檔
3. [x] 官網方案選擇器

### Phase 2：Docker 方案 ⏳
1. [ ] Python Dockerfile
2. [ ] Node.js Dockerfile
3. [ ] docker-compose 範例
4. [ ] 一鍵啟動腳本

### Phase 3：雲端方案 ⏳
1. [ ] devcontainer 模板
2. [ ] Codespaces 設定
3. [ ] GitPod 設定
4. [ ] README badges

### Phase 4：範例專案 ⏳
1. [ ] Python FastAPI 完整範例
2. [ ] Node.js Express 完整範例

### Phase 5：官網增強 ⏳
1. [ ] 互動式決策樹
2. [ ] 多語言支援
3. [ ] 搜尋功能

---

## 貢獻指南

### 新增方案

1. 在 `templates/` 建立方案資料夾
2. 提供必要的設定檔
3. 在本規格文檔新增方案規格
4. 更新官網選擇器
5. 提供範例專案整合

### 程式碼風格

- Batch：使用 `::` 註解，`setlocal enabledelayedexpansion`
- Docker：多階段構建，最小化映像
- YAML：2 空格縮排
- JSON：4 空格縮排

---

## 版本歷史

| 版本 | 日期 | 說明 |
|------|------|------|
| 0.1.0 | 2025-01 | 初版，Windows winget 方案 |
| 0.2.0 | 規劃中 | 新增 Docker 方案 |
| 0.3.0 | 規劃中 | 新增雲端方案 |
| 1.0.0 | 規劃中 | 所有方案完成 |

---

<p align="center">
  <b>讓使用者專注在使用，而不是設環境</b>
</p>
