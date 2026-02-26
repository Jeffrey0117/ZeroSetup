/**
 * ZeroSetup - Config Generator
 *
 * Takes detection results and produces a clean zerosetup.json config.
 */

/**
 * Generate zerosetup.json from detection results
 * @param {object} detected - Output from detect.js
 * @returns {object} Clean config object
 */
function generate(detected) {
  const config = {
    name: detected.name,
    runtime: detected.runtime || 'node',
    entry: detected.entry || 'index.js',
  };

  // Port & health (only if detected)
  if (detected.port) {
    config.port = detected.port;
    config.health = detected.health || `http://localhost:${detected.port}/health`;
  }

  // Dependencies
  const deps = {};
  if (detected.deps.winget.length > 0) {
    deps.winget = detected.deps.winget;
  }
  if (detected.deps.npmGlobal.length > 0) {
    deps['npm-global'] = detected.deps.npmGlobal;
  }
  if (detected.deps.npm) {
    deps.npm = true;
  }
  if (detected.deps.pip) {
    deps.pip = true;
  }
  if (Object.keys(deps).length > 0) {
    config.dependencies = deps;
  }

  // Scripts
  const scripts = {};
  if (detected.preStart) {
    scripts['pre-start'] = detected.preStart;
  }
  if (detected.startCmd) {
    scripts.start = detected.startCmd;
  }
  if (detected.stopCmd) {
    scripts.stop = detected.stopCmd;
  }
  if (Object.keys(scripts).length > 0) {
    config.scripts = scripts;
  }

  return config;
}

module.exports = { generate };
