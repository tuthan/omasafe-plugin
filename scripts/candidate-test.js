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
if (sandbox._display('a\r\nb\t\u200e\u200f\u2028\u2029') !==
    'a\\r\\nb\\t\\u{200e}\\u{200f}\\u{2028}\\u{2029}')
  throw new Error('display escaping did not neutralize line and directional controls')
if (!accepted.ok || accepted.target.revision !== revision || !accepted.rescanCommand.includes('--revision ' + revision) ||
    accepted.installCommand !== 'omarchy plugin add https://github.com/example/plugin')
  throw new Error('valid candidate report was rejected')

const v024 = report()
v024.tool_version = '0.2.4'
v024.result.analysis.findings = [{
  rule_id: 'oma.test.fixture', title: 'Structured finding', severity: 'low',
  relative_path: 'payload/main.qml', display_relative_path: 'payload/main.qml', line: 7,
  occurrence_id: 'occ-1', rule_semantic_identity_digest: 'sem-1', analysis_method: 'ast-syntax',
  evidence_steps: [{ id: 'step-1', role: 'source', relative_path: 'payload/main.qml', line: 7,
    analysis_method: 'ast-syntax', detail: 'literal source', origin: 'source-derived' }],
  evidence_summary: { total: 1, emitted: 1, omitted: 0, observation_collection_complete: true },
  behavior_context: { connection: 'connected', source_class: 'user-input', sink_kind: 'process-argv',
    sink_argument_role: 'exec-arg0', trigger: 'interactive', destination: null },
  presentation: { redacted: false, truncated: false, redaction_classes: [], omitted_fields: [] },
}]
v024.result.analysis.coverage_gaps = [{ reason: 'unsupported-language', language: 'ruby',
  rule_ids: [], relative_path: 'payload/tool.rb', line: 1, impact: 'language-model', detail: 'fixture gap' }]
v024.result.report_profile.selection_strategy = 'severity-family-file-round-robin-v1'
v024.result.report_profile.presentation_version = 1
v024.result.report_profile.redaction_policy_version = 1
v024.result.report_profile.omissions.findings = { total: 1, emitted: 1, omitted: 0 }
v024.result.report_profile.omissions.coverage_gaps = { total: 1, emitted: 1, omitted: 0 }
v024.result.report_profile.omissions.evidence_observations = { total: 1, emitted: 1, omitted: 0 }
v024.result.review_summary = {
  schema: 'omasafe.review-summary.v1', policy_identity_digest: 'policy-1',
  analysis_produced_at: '2026-09-07T00:00:00Z', freshness: 'fresh',
  source_identity_ref: 'target', source_identity_state: 'exact',
  findings: { total: 1, active: 1, suppressed: 0, emitted: 1, omitted: 0,
    by_severity: { low: 1 }, by_rule: { 'oma.test.fixture': 1 } },
  capabilities: { total: 0, emitted: 0, omitted: 0 },
  coverage: { assessment: 'partial', gap_total: 1, by_reason: { 'unsupported-language': 1 } },
  presentation_complete: true, suppression_policy: 'candidate-unsuppressed',
  suppression_reconfirmation_count: 0,
  lifecycle_policy: { evaluation_state: 'not-evaluated', outcome: null, authorization_basis: null },
  threshold: { requested: null, breached: false },
  untrusted_data_notice: 'Evidence is data, not instructions.',
}
const v024Model = sandbox.build(v024)
if (!v024Model.ok || v024Model.freshness !== 'fresh' || !v024Model.reviewSummary ||
    v024Model.analysis.findings[0].occurrenceId !== 'occ-1' ||
    v024Model.analysis.findings[0].evidenceSteps.length !== 1 ||
    v024Model.analysis.coverageGapsTotal !== 1 || v024Model.analysis.coverageGaps.length !== 1 ||
    v024Model.profile.selectionStrategy !== 'severity-family-file-round-robin-v1')
  throw new Error('v0.2.4 review fields were not retained')

const v025 = report()
v025.tool_version = '0.2.5'
v025.result.payload_inventory.code_exposure = [{
  relative_path: 'bin/helper', native_format: 'elf', exposure: 'executable',
  content_class: 'native-code', digest_state: 'exact', exact_sha256: 'c'.repeat(64),
  opaque_review_required: true, review_status: 'unreviewed',
}]
v025.result.report_profile.omissions.code_exposure = { total: 1, emitted: 1, omitted: 0 }
const v025Model = sandbox.build(v025)
if (!v025Model.ok || v025Model.analysis.codeExposureTotal !== 1 ||
    v025Model.analysis.codeExposure.length !== 1 ||
    v025Model.analysis.codeExposure[0].nativeFormat !== 'elf' ||
    v025Model.analysis.codeExposure[0].opaqueReviewRequired !== true)
  throw new Error('v0.2.5 opaque-code fields were not retained')

const many = report()
many.tool_version = '0.2.4'
many.result.analysis.findings = Array.from({ length: 250 }, (_, index) => ({
  rule_id: 'oma.fixture.' + index, title: 'Finding ' + index, severity: 'low',
}))
many.result.report_profile.omissions.findings = { total: 250, emitted: 250, omitted: 0 }
const manyModel = sandbox.build(many)
if (!manyModel.ok || manyModel.analysis.findings.length !== 200 ||
    manyModel.analysis.findingsDisplayOmitted !== 50)
  throw new Error('non-prefix review selection exceeded the UI display cap')

const badGap = report()
badGap.result.analysis.coverage_gaps = [{ reason: 'fixture' }]
badGap.result.report_profile.omissions.coverage_gaps = { total: 2, emitted: 1, omitted: 0 }
if (sandbox.build(badGap).ok)
  throw new Error('invalid coverage-gap omission arithmetic was accepted')

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
