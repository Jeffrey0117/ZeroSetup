# ZeroSetup

Scan any project, auto-detect runtime/dependencies, generate `setup.bat`. Users just `git clone` and double-click.

## Stack
- Node.js (CommonJS), zero runtime dependencies — pure `fs`/`path`
- Distributed as a CLI via `npm i -g zerosetup` / `npx zerosetup` (bin: `init.js`)
- Generated artifacts are Windows batch scripts driven by `winget`
- Target end-user platform: Windows 10 1709+ / 11

## Directory structure

```
init.js                 ← CLI entry: scan → generate zerosetup.json → copy bat templates
lib/
  detect.js             ← Auto-detection engine (runtime, entry, port, framework, deps, pkg mgr)
  generate.js           ← Turns detection result into a clean zerosetup.json config object
templates/
  setup.bat             ← Universal run script copied into user projects (the file users double-click)
  stop.bat              ← Universal stop script
  windows-winget/       ← Extra reference templates (run/stop/auto-update, README, config example)
docs/index.html         ← GitHub Pages landing page
SPEC.md                 ← Spec
README.md / README.en.md / README.zh-CN.md
```

## Key concepts

- **Two-stage flow**: (1) Developer runs `zerosetup init` → `init.js` scans the project, writes `zerosetup.json`, and copies `setup.bat`/`stop.bat`. (2) End user double-clicks `setup.bat`, which reads `zerosetup.json` and installs + starts everything on a fresh machine.
- **Detection engine (`lib/detect.js`)**: Returns a result object with `runtime` (node/python/both), `entry`, `port`, `health`, `framework`, `packageManager`, `startCmd`/`stopCmd`, and `deps` (winget, npmGlobal, npm, pip).
  - Runtime: presence of `package.json` (node) and/or `requirements.txt`/`pyproject.toml` (python).
  - Entry: `pkg.main` → common filenames (index.js/server.js/...) for node; main.py/app.py/... for python.
  - Framework: pm2 (ecosystem.config.js), next, nuxt, express, fastapi, flask, django — each sets a default start command.
  - Port: scanned from `.env` (PORT=), `config.json`, `.listen(PORT)` in entry file, then `--port`/`-p` in start/dev scripts.
  - Package manager: detected by lockfile — bun / pnpm / yarn / npm (node); uv / pipenv / poetry / pip (python).
  - System deps: source-file keyword scan (ffmpeg/ffprobe → FFmpeg.FFmpeg, cloudflared → cloudflare.cloudflared; yt-dlp in requirements → FFmpeg). Walks max depth 3, ignores node_modules/venv/dist/.git etc.
- **Config generation (`lib/generate.js`)**: Omits defaults (e.g. only emits `packageManager` if not npm; only emits port/health/deps/scripts when present).
- **setup.bat phases**: (1) Bootstrap — ensure winget + Node.js (+ Git if `.git`). (2) Read config — parse `zerosetup.json` into batch vars via inline `node -e`. (3) Install deps — Python, winget packages, npm globals, then `<pkgMgr> install` / `pip install`. (4) Start — run pre-start + start command, then poll `health` URL up to 5 times. `:REFRESH_PATH` reloads PATH from registry after each install so freshly installed tools resolve.

## Commands

- `zerosetup` / `zerosetup init` — scan current directory
- `zerosetup init <path>` / `zerosetup <path>` — scan a specific project
- `npx zerosetup` — run without installing
- `npm start` — runs `node init.js` (scan cwd)
- No build step, no test suite present.

## Coding rules

- CommonJS modules (`require`/`module.exports`), no external dependencies — keep it dependency-free.
- Detection must be non-throwing: wrap all file reads/JSON parses in try/catch and fall back to sensible defaults rather than crashing the scan.
- Generated config omits empty/default fields; preserve this minimal-output convention in `generate.js`.
- `setup.bat` must assume a fresh Windows machine: only winget is guaranteed present; install everything else and refresh PATH after.
- Never overwrite a user's existing `setup.bat`/`stop.bat` when copying templates (init.js skips existing files).
