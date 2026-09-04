#!/usr/bin/env node
// Node regression test for the pure candidate report normalizer. This keeps the
// QML view from becoming the only executable check for the v0.2.2 boundary.
'use strict'

const fs = require('fs')
const vm = require('vm')
const path = require('path')

const source = fs.readFileSync(path.join(__dirname, '..', 'model/Candidate.js'), 'utf8')
  .replace(/^\s*\.pragma\s+library\s*$/gm, '')
const sandbox = { Array, JSON, Number, Object, String, isFinite, console }
vm.createContext(sandbox)
vm.runInContext(source, sandbox, { filename: 'model/Candidate.js' })

const revision = 'a'.repeat(40)
function report() {
  return {
    schema: 'omasafe.report.v1',
    tool_version: '0.2.2',
    result: {
      target: {
        source: 'resolved-git-request',
        url: 'https://github.com/example/plugin',
        revision,
        scope: 'plugin-root',
        root: '',
      },
      acquisition: {
        schema: 'omasafe.acquisition.v1',
        operation: 'scan-only',
        installation_performed: false,
        input_kind: 'raw-github-url',
        install_verb: 'none',
        requested_reference: 'default-branch-head',
        resolved_identity: { kind: 'git-commit', value: revision },
        integrity: { state: 'resolved-exact', algorithm: 'git-sha1', observed: revision },
        network_used: true,
        cache: { used: true, result: 'miss' },
        discarded_install_flags: [],
        listed_repository: null,
        effective_repository_url: 'https://github.com/example/plugin',
        marketplace_claim: null,
        limitations: [],
      },
      analysis: {
        schema: 'omasafe.analysis.v1',
        findings: [],
        capabilities: [],
        invocation_edges: [],
        coverage_limitations: [],
      },
      suppressions: {
        policy: 'candidate-unsuppressed',
        consulted: false,
        applied: [],
        active_records: null,
      },
      payload_inventory: {
        totals: { entries: 0 },
        coverage_states: {},
        entries: [],
      },
      report_profile: {
        name: 'review',
        serialized_byte_limit: 1572864,
        omissions: {
          payload_entries: { total: 0, emitted: 0, omitted: 0 },
          findings: { total: 0, emitted: 0, omitted: 0 },
          capabilities: { total: 0, emitted: 0, omitted: 0 },
          invocation_edges: { total: 0, emitted: 0, omitted: 0 },
        },
      },
    },
  }
}

const accepted = sandbox.build(report())
if (!accepted.ok || accepted.target.revision !== revision || !accepted.rescanCommand.includes('--revision ' + revision) ||
    accepted.installCommand !== 'omarchy plugin add https://github.com/example/plugin')
  throw new Error('valid candidate report was rejected')

const malformed = report()
malformed.result.suppressions.applied = ['oma.qml.process-execution']
if (sandbox.build(malformed).ok)
  throw new Error('configured suppression state was accepted')

const high = report()
high.result.analysis.findings = [{ severity: 'high', title: 'reported finding' }]
high.result.report_profile.omissions.findings = { total: 1, emitted: 1, omitted: 0 }
if (sandbox.build(high).installCommand !== '')
  throw new Error('install guidance was shown for a high finding')

const copied = report()
copied.result.acquisition.input_kind = 'omarchy-install-command'
copied.result.acquisition.install_verb = 'install'
copied.result.acquisition.discarded_install_flags = ['enable', 'yes']
const copiedModel = sandbox.build(copied)
if (copiedModel.installCommand !== 'omarchy plugin install https://github.com/example/plugin --enable')
  throw new Error('copied install command was not reconstructed safely')

console.log('candidate model: ok')
