#!/usr/bin/env node
// Compatibility regression for the v0.3.2 CLI floor. This deliberately stays
// independent of a running shell: it checks the manifest contract, the QML
// fallback literals, and the same numeric comparison used by BarWidget.qml.
'use strict'

const fs = require('fs')
const path = require('path')

const root = path.resolve(__dirname, '..')
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'manifest.json'), 'utf8'))
const schema = manifest.barWidget && manifest.barWidget.schema
const setting = Array.isArray(schema) && schema.find(item => item.key === 'cliVersionMin')
if (!setting || setting.defaultValue !== '0.3.2')
  throw new Error('manifest cliVersionMin must default to 0.3.2')
if (!String(setting.description || '').includes('0.3.2 or newer'))
  throw new Error('manifest must describe the 0.3.2 minimum')

function parse(value) {
  const match = String(value).trim().match(/^(?:omasafe-cli\s+)?(\d+)\.(\d+)(?:\.(\d+))?$/i)
  return match ? [Number(match[1]), Number(match[2]), Number(match[3] || 0)] : null
}
function compare(a, b) {
  for (let i = 0; i < 3; i++) {
    if (a[i] !== b[i]) return a[i] - b[i]
  }
  return 0
}
function compatible(output, minimum) {
  const version = parse(output)
  return !!version && compare(version, minimum) >= 0
}

const minimum = [0, 3, 2]
if (compatible('omasafe-cli 0.3.1', minimum))
  throw new Error('an older CLI must be rejected')
if (!compatible('omasafe-cli 0.3.2', minimum) || !compatible('omasafe-cli 0.4.0', minimum))
  throw new Error('the minimum and newer CLIs must be accepted')
if (compatible('omasafe-cli 0.3', minimum) || compatible('other-cli 0.3.2', minimum))
  throw new Error('malformed or unidentified versions must not pass this contract')

for (const file of ['BarWidget.qml', 'Panel.qml', 'views/PostureView.qml']) {
  const source = fs.readFileSync(path.join(root, file), 'utf8')
  if (!source.includes('0.3.2')) throw new Error(`${file} is missing the v0.3.2 floor`)
}

console.log('cli floor tests: ok')
