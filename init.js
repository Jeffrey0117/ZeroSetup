#!/usr/bin/env node
/**
 * ZeroSetup Init
 *
 * Scans a project directory, auto-detects everything,
 * generates zerosetup.json and copies universal bat files.
 *
 * Usage:
 *   zerosetup                       # scan current directory
 *   zerosetup init                  # same as above
 *   zerosetup init C:\path\to\project
 *   npx zerosetup
 */

const fs = require('fs');
const path = require('path');
const { detect } = require('./lib/detect');
const { generate } = require('./lib/generate');

const ZEROSETUP_ROOT = __dirname;

function main() {
  // Support: zerosetup, zerosetup init, zerosetup init ./path, zerosetup ./path
  const args = process.argv.slice(2).filter(a => a !== 'init');
  const targetPath = path.resolve(args[0] || process.cwd());

  if (!fs.existsSync(targetPath)) {
    console.error(`Error: Directory not found: ${targetPath}`);
    process.exit(1);
  }

  console.log('');
  console.log('  ZeroSetup Init');
  console.log('  ==============');
  console.log(`  Target: ${targetPath}`);
  console.log('');

  // 1. Detect
  console.log('  Scanning...');
  const detected = detect(targetPath);

  if (!detected.runtime) {
    console.error('  Error: No supported runtime detected.');
    console.error('  Supported: Node.js (package.json), Python (requirements.txt)');
    process.exit(1);
  }

  // Print detection results
  console.log(`  Runtime:    ${detected.runtime}`);
  console.log(`  Framework:  ${detected.framework || 'none'}`);
  console.log(`  Entry:      ${detected.entry}`);
  if (detected.port) console.log(`  Port:       ${detected.port}`);
  if (detected.startCmd) console.log(`  Start:      ${detected.startCmd}`);
  if (detected.stopCmd) console.log(`  Stop:       ${detected.stopCmd}`);
  if (detected.deps.winget.length > 0) console.log(`  Winget:     ${detected.deps.winget.join(', ')}`);
  if (detected.deps.npmGlobal.length > 0) console.log(`  NPM Global: ${detected.deps.npmGlobal.join(', ')}`);
  console.log('');

  // 2. Generate config
  const config = generate(detected);

  // 3. Write zerosetup.json
  const configPath = path.join(targetPath, 'zerosetup.json');
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n');
  console.log(`  Created: zerosetup.json`);

  // 4. Copy bat templates
  const templates = ['setup.bat', 'stop.bat'];
  for (const tpl of templates) {
    const src = path.join(ZEROSETUP_ROOT, 'templates', tpl);
    const dest = path.join(targetPath, tpl);

    if (!fs.existsSync(src)) {
      console.error(`  Warning: Template not found: ${src}`);
      continue;
    }

    // Don't overwrite if already exists (user may have customized)
    if (fs.existsSync(dest)) {
      console.log(`  Skipped: ${tpl} (already exists)`);
    } else {
      fs.copyFileSync(src, dest);
      console.log(`  Created: ${tpl}`);
    }
  }

  console.log('');
  console.log('  Done! To start your project:');
  console.log('');
  console.log('    setup.bat');
  console.log('');
}

main();
