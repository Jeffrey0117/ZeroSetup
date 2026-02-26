/**
 * ZeroSetup - Project Auto-Detection
 *
 * Scans a project directory and detects:
 * - Runtime (node, python, both)
 * - Entry point (server.js, main.py, etc.)
 * - Port
 * - Framework (express, nextjs, fastapi, pm2, etc.)
 * - Dependencies (winget packages, npm globals)
 * - Start/stop commands
 */

const fs = require('fs');
const path = require('path');

/**
 * Detect everything about a project
 * @param {string} projectPath - Absolute path to project directory
 * @returns {object} Detection results
 */
function detect(projectPath) {
  const result = {
    name: path.basename(projectPath),
    runtime: null,       // 'node' | 'python' | 'both'
    entry: null,         // 'server.js' | 'main.py'
    port: null,          // 8787
    health: null,        // 'http://localhost:8787/health'
    framework: null,     // 'express' | 'nextjs' | 'pm2' | 'fastapi' | 'flask'
    packageManager: null, // { name, install, global, lockfile }
    startCmd: null,      // 'pm2 start ecosystem.config.js'
    stopCmd: null,       // 'pm2 delete all'
    preStart: null,      // 'node scripts/deploy-all.js'
    deps: {
      winget: [],        // ['cloudflare.cloudflared']
      npmGlobal: [],     // ['pm2']
      npm: false,
      pip: false,
    },
  };

  const hasNode = detectNode(projectPath, result);
  const hasPython = detectPython(projectPath, result);

  if (hasNode && hasPython) {
    result.runtime = 'both';
  } else if (hasNode) {
    result.runtime = 'node';
  } else if (hasPython) {
    result.runtime = 'python';
  }

  detectPort(projectPath, result);
  detectPackageManager(projectPath, result);
  detectWingetDeps(projectPath, result);
  deduplicateDeps(result);

  return result;
}

// ==================== Node.js Detection ====================

function detectNode(projectPath, result) {
  const pkgPath = path.join(projectPath, 'package.json');
  if (!fs.existsSync(pkgPath)) return false;

  result.deps.npm = true;

  let pkg;
  try {
    pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
  } catch {
    return true;
  }

  // Name from package.json
  if (pkg.name) {
    result.name = pkg.name;
  }

  // Entry point detection
  result.entry = detectNodeEntry(projectPath, pkg);

  // Framework detection
  const allDeps = { ...(pkg.dependencies || {}), ...(pkg.devDependencies || {}) };

  // PM2 ecosystem
  if (fs.existsSync(path.join(projectPath, 'ecosystem.config.js'))) {
    result.framework = 'pm2';
    result.startCmd = 'pm2 start ecosystem.config.js';
    result.stopCmd = 'pm2 delete all';
    result.deps.npmGlobal.push('pm2');
  }
  // Next.js
  else if (allDeps['next']) {
    result.framework = 'nextjs';
    result.startCmd = 'npm start';
  }
  // Nuxt
  else if (allDeps['nuxt']) {
    result.framework = 'nuxt';
    result.startCmd = 'npm start';
  }
  // Express / general Node
  else if (allDeps['express']) {
    result.framework = 'express';
    if (pkg.scripts?.start) {
      result.startCmd = 'npm start';
    } else {
      result.startCmd = `node ${result.entry}`;
    }
  }
  // Has start script
  else if (pkg.scripts?.start) {
    result.framework = 'npm';
    result.startCmd = 'npm start';
  }
  // Raw Node
  else {
    result.framework = 'node';
    result.startCmd = `node ${result.entry}`;
  }

  return true;
}

function detectNodeEntry(projectPath, pkg) {
  // Priority: pkg.main → common filenames
  if (pkg.main && fs.existsSync(path.join(projectPath, pkg.main))) {
    return pkg.main;
  }

  const candidates = ['index.js', 'server.js', 'app.js', 'main.js', 'src/index.js', 'src/server.js'];
  for (const c of candidates) {
    if (fs.existsSync(path.join(projectPath, c))) {
      return c;
    }
  }

  return pkg.main || 'index.js';
}

// ==================== Python Detection ====================

function detectPython(projectPath, result) {
  const hasRequirements = fs.existsSync(path.join(projectPath, 'requirements.txt'));
  const hasPyproject = fs.existsSync(path.join(projectPath, 'pyproject.toml'));

  if (!hasRequirements && !hasPyproject) return false;

  result.deps.pip = hasRequirements;

  // Entry point detection
  if (!result.entry) {
    result.entry = detectPythonEntry(projectPath);
  }

  // Framework detection from requirements.txt
  if (hasRequirements) {
    const reqLines = fs.readFileSync(path.join(projectPath, 'requirements.txt'), 'utf8')
      .split('\n')
      .map(l => l.trim().toLowerCase());
    const hasPackage = (name) => reqLines.some(l => l.match(new RegExp(`^${name}([>=<\\[!]|$)`)));

    if (hasPackage('fastapi')) {
      result.framework = result.framework || 'fastapi';
      if (!result.startCmd) {
        const module = result.entry.replace(/\.py$/, '').replace(/[\\/]/g, '.');
        result.startCmd = `uvicorn ${module}:app --host 0.0.0.0`;
      }
    } else if (hasPackage('flask')) {
      result.framework = result.framework || 'flask';
      if (!result.startCmd) {
        result.startCmd = `python ${result.entry}`;
      }
    } else if (hasPackage('django')) {
      result.framework = result.framework || 'django';
      if (!result.startCmd) {
        result.startCmd = 'python manage.py runserver';
      }
    } else if (!result.startCmd) {
      result.startCmd = `python ${result.entry}`;
    }
  }

  return true;
}

function detectPythonEntry(projectPath) {
  const candidates = ['main.py', 'app.py', 'server.py', 'index.py', 'app/main.py', 'src/main.py'];
  for (const c of candidates) {
    if (fs.existsSync(path.join(projectPath, c))) {
      return c;
    }
  }
  return 'main.py';
}

// ==================== Package Manager Detection ====================

function detectPackageManager(projectPath, result) {
  // Node.js package managers — priority by lock file
  if (result.runtime === 'node' || result.runtime === 'both') {
    if (fs.existsSync(path.join(projectPath, 'bun.lockb')) || fs.existsSync(path.join(projectPath, 'bun.lock'))) {
      result.packageManager = {
        name: 'bun',
        install: 'bun install',
        run: (script) => `bun run ${script}`,
        global: { cmd: 'bun', winget: 'Oven-sh.Bun' },
        lockfile: 'bun.lockb',
      };
    } else if (fs.existsSync(path.join(projectPath, 'pnpm-lock.yaml'))) {
      result.packageManager = {
        name: 'pnpm',
        install: 'pnpm install',
        run: (script) => `pnpm run ${script}`,
        global: { cmd: 'pnpm', npmGlobal: 'pnpm' },
        lockfile: 'pnpm-lock.yaml',
      };
    } else if (fs.existsSync(path.join(projectPath, 'yarn.lock'))) {
      result.packageManager = {
        name: 'yarn',
        install: 'yarn install',
        run: (script) => `yarn ${script}`,
        global: { cmd: 'yarn', npmGlobal: 'yarn' },
        lockfile: 'yarn.lock',
      };
    } else if (fs.existsSync(path.join(projectPath, 'package-lock.json')) || fs.existsSync(path.join(projectPath, 'package.json'))) {
      result.packageManager = {
        name: 'npm',
        install: 'npm install',
        run: (script) => `npm run ${script}`,
        global: null,
        lockfile: 'package-lock.json',
      };
    }

    // Add the global tool to deps if needed
    if (result.packageManager?.global) {
      const g = result.packageManager.global;
      if (g.winget) {
        result.deps.winget.push(g.winget);
      }
      if (g.npmGlobal) {
        result.deps.npmGlobal.push(g.npmGlobal);
      }
    }
  }

  // Python package managers — priority by config file
  if (result.runtime === 'python' || result.runtime === 'both') {
    if (!result.packageManager || result.runtime === 'python') {
      if (fs.existsSync(path.join(projectPath, 'uv.lock'))) {
        result.packageManager = {
          name: 'uv',
          install: 'uv sync',
          global: { cmd: 'uv', pip: 'uv' },
          lockfile: 'uv.lock',
        };
      } else if (fs.existsSync(path.join(projectPath, 'Pipfile'))) {
        result.packageManager = {
          name: 'pipenv',
          install: 'pipenv install',
          global: { cmd: 'pipenv', pip: 'pipenv' },
          lockfile: 'Pipfile.lock',
        };
      } else if (fs.existsSync(path.join(projectPath, 'poetry.lock'))) {
        result.packageManager = {
          name: 'poetry',
          install: 'poetry install',
          global: { cmd: 'poetry', pip: 'poetry' },
          lockfile: 'poetry.lock',
        };
      }
      // else: plain pip, handled by deps.pip = true
    }
  }
}

// ==================== Port Detection ====================

function detectPort(projectPath, result) {
  // 1. Check .env file
  const envPath = path.join(projectPath, '.env');
  if (fs.existsSync(envPath)) {
    const envContent = fs.readFileSync(envPath, 'utf8');
    const portMatch = envContent.match(/^PORT\s*=\s*(\d+)/m);
    if (portMatch) {
      result.port = parseInt(portMatch[1], 10);
      result.health = `http://localhost:${result.port}/health`;
      return;
    }
  }

  // 2. Check config.json
  const configPath = path.join(projectPath, 'config.json');
  if (fs.existsSync(configPath)) {
    try {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      if (config.port) {
        result.port = config.port;
        result.health = `http://localhost:${result.port}/health`;
        return;
      }
    } catch {}
  }

  // 3. Scan entry file for .listen(PORT)
  if (result.entry) {
    const entryPath = path.join(projectPath, result.entry);
    if (fs.existsSync(entryPath)) {
      const content = fs.readFileSync(entryPath, 'utf8');
      const listenMatch = content.match(/\.listen\(\s*(\d{4,5})/);
      if (listenMatch) {
        result.port = parseInt(listenMatch[1], 10);
        result.health = `http://localhost:${result.port}/health`;
        return;
      }
    }
  }

  // 4. Check package.json scripts for --port flags
  const pkgPath = path.join(projectPath, 'package.json');
  if (fs.existsSync(pkgPath)) {
    try {
      const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
      const startScript = pkg.scripts?.start || pkg.scripts?.dev || '';
      const portMatch = startScript.match(/(?:--port|-p)\s+(\d{4,5})/);
      if (portMatch) {
        result.port = parseInt(portMatch[1], 10);
        result.health = `http://localhost:${result.port}/health`;
        return;
      }
    } catch {}
  }
}

// ==================== Winget / System Dependency Detection ====================

function detectWingetDeps(projectPath, result) {
  // Scan source files for known tool keywords
  const filesToScan = collectSourceFiles(projectPath, result.runtime);

  const keywords = {
    'cloudflared': 'cloudflare.cloudflared',
    'cloudflare tunnel': 'cloudflare.cloudflared',
    'ffmpeg': 'FFmpeg.FFmpeg',
    'ffprobe': 'FFmpeg.FFmpeg',
  };

  for (const filePath of filesToScan) {
    let content;
    try {
      content = fs.readFileSync(filePath, 'utf8').toLowerCase();
    } catch {
      continue;
    }

    for (const [keyword, wingetId] of Object.entries(keywords)) {
      if (content.includes(keyword)) {
        result.deps.winget.push(wingetId);
      }
    }
  }



  // Check requirements.txt for Python tools
  const reqPath = path.join(projectPath, 'requirements.txt');
  if (fs.existsSync(reqPath)) {
    const reqs = fs.readFileSync(reqPath, 'utf8').toLowerCase();
    if (reqs.includes('yt-dlp') || reqs.includes('youtube')) {
      result.deps.winget.push('FFmpeg.FFmpeg');
    }
  }
}

function collectSourceFiles(projectPath, runtime) {
  const files = [];
  const extensions = new Set();

  if (!runtime || runtime === 'node' || runtime === 'both') {
    extensions.add('.js');
    extensions.add('.ts');
    extensions.add('.mjs');
  }
  if (runtime === 'python' || runtime === 'both') {
    extensions.add('.py');
  }

  const ignoreDirs = new Set(['node_modules', 'venv', '.venv', '__pycache__', 'dist', 'build', '.git', '.next']);

  function walk(dir, depth) {
    if (depth > 3) return; // Don't go too deep
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      return;
    }

    for (const entry of entries) {
      if (entry.name.startsWith('.') && entry.isDirectory()) continue;
      if (ignoreDirs.has(entry.name)) continue;

      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        walk(fullPath, depth + 1);
      } else if (extensions.has(path.extname(entry.name))) {
        files.push(fullPath);
      }
    }
  }

  walk(projectPath, 0);
  return files;
}

// ==================== Helpers ====================

function deduplicateDeps(result) {
  result.deps.winget = [...new Set(result.deps.winget)];
  result.deps.npmGlobal = [...new Set(result.deps.npmGlobal)];
}

module.exports = { detect };
