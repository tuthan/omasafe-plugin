// Candidate.js — pure normalisation for the persistent-in-session v0.2.2 source scan view.
//
// The CLI owns parsing, acquisition, analysis, and policy. This module only
// accepts the versioned scan-only report, bounds target-derived display text,
// and turns it into view data. It never executes a command or infers safety.
.pragma library

var MAX_TEXT = 2048
var MAX_ITEMS = 200

function _arr(value) { return Array.isArray(value) ? value : [] }
function _obj(value) { return value && typeof value === "object" && !Array.isArray(value) ? value : null }
function _str(value) { return String(value === null || value === undefined ? "" : value) }
function _display(value, limit) {
  var text = _str(value)
  // Text.PlainText protects the view from markup; replace terminal/bidi controls
  // as well so evidence cannot create invisible or stateful display text.
  text = text.replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, "�")
    .replace(/[\u202a-\u202e\u2066-\u2069]/g, "�")
  return text.slice(0, limit || MAX_TEXT)
}
function _commit(value) {
  var text = _str(value)
  return /^(?:[0-9a-fA-F]{40}|[0-9a-fA-F]{64})$/.test(text) ? text : ""
}
function _version(value) {
  var match = /^(\d+)\.(\d+)(?:\.(\d+))?$/.exec(_str(value).trim())
  return match ? [Number(match[1]), Number(match[2]), Number(match[3] || 0)] : null
}
function _atLeast(value, minimum) {
  var parsed = _version(value)
  if (!parsed) return false
  for (var i = 0; i < 3; i++) {
    if (parsed[i] !== minimum[i]) return parsed[i] > minimum[i]
  }
  return true
}
function _count(value) {
  return typeof value === "number" && isFinite(value) && value >= 0 && Math.floor(value) === value
    ? value : null
}
function _safeUrl(value) {
  var text = _str(value)
  return /^https:\/\/[^\s/?#@]+(?:\/[^\s?#]*)?$/.test(text) &&
    !/[\u0000-\u001f\u007f]/.test(text) ? text : ""
}
function _suggestedInstallCommand(acquisition, url) {
  var verb = acquisition.install_verb === "install" ? "install" : "add"
  var command = "omarchy plugin " + verb + " " + url
  var flags = _arr(acquisition.discarded_install_flags)
  if (flags.indexOf("enable") >= 0) command += " --enable"
  return command
}
function _failure(error) { return { ok: false, error: _display(error, MAX_TEXT) } }

function _omission(omissions, name) {
  var value = omissions ? _obj(omissions[name]) : null
  if (!value) return null
  var total = _count(value.total), emitted = _count(value.emitted), omitted = _count(value.omitted)
  if (total === null || emitted === null || omitted === null || emitted + omitted !== total) return null
  return { total: total, emitted: emitted, omitted: omitted }
}

function _finding(value) {
  var finding = _obj(value) || {}
  return {
    ruleId: _display(finding.rule_id, 512),
    title: _display(finding.title, 1024),
    severity: _display(finding.severity, 32),
    relativePath: _display(finding.relative_path, 1024),
    line: _count(finding.line) === null ? "" : String(finding.line),
    evidence: _display(finding.evidence, MAX_TEXT),
    confidence: _display(finding.confidence, 64),
    explanation: _display(finding.explanation, MAX_TEXT),
    reviewGuidance: _display(finding.review_guidance, MAX_TEXT)
  }
}

function _capability(value) {
  var capability = _obj(value) || {}
  return {
    capability: _display(capability.capability, 128),
    relativePath: _display(capability.relative_path, 1024),
    detail: _display(capability.detail, MAX_TEXT),
    confidence: _display(capability.confidence, 64)
  }
}

function _edge(value) {
  var edge = _obj(value) || {}
  return {
    fromPath: _display(edge.from_path, 1024),
    targetPath: _display(edge.target_path, 1024),
    kind: _display(edge.kind, 128)
  }
}

function build(report) {
  var top = _obj(report)
  if (!top || top.schema !== "omasafe.report.v1" || !_atLeast(top.tool_version, [0, 2, 2]))
    return _failure("unsupported candidate report or CLI version")

  var result = _obj(top.result), target = result && _obj(result.target)
  var acquisition = result && _obj(result.acquisition)
  var analysis = result && _obj(result.analysis)
  var suppressions = result && _obj(result.suppressions)
  var profile = result && _obj(result.report_profile)
  var payload = result && _obj(result.payload_inventory)
  if (!result || !target || !acquisition || !analysis || !suppressions || !profile || !payload)
    return _failure("candidate report is missing a required section")
  if (acquisition.schema !== "omasafe.acquisition.v1" || acquisition.operation !== "scan-only" ||
      acquisition.installation_performed !== false)
    return _failure("candidate report is not scan-only")
  if (["raw-github-url", "omarchy-install-command", "exact-git", "marketplace-id"].indexOf(acquisition.input_kind) < 0 ||
      ["none", "add", "install"].indexOf(acquisition.install_verb) < 0)
    return _failure("candidate report has an unsupported input kind")
  if (suppressions.policy !== "candidate-unsuppressed" || suppressions.consulted !== false ||
      !Array.isArray(suppressions.applied) || suppressions.applied.length !== 0 ||
      suppressions.active_records !== null)
    return _failure("candidate suppression policy is not explicit")

  var revision = _commit(acquisition.resolved_identity && acquisition.resolved_identity.value)
  var observed = acquisition.integrity && acquisition.integrity.observed
  var algorithm = revision.length === 64 ? "git-sha256" : "git-sha1"
  if (!revision || !_obj(acquisition.resolved_identity) || acquisition.resolved_identity.kind !== "git-commit" ||
      !_obj(acquisition.integrity) || acquisition.integrity.state !== "resolved-exact" ||
      acquisition.integrity.algorithm !== algorithm || observed !== revision)
    return _failure("candidate integrity does not match a full resolved commit")
  if (typeof acquisition.network_used !== "boolean" || !_obj(acquisition.cache) ||
      typeof acquisition.cache.used !== "boolean" ||
      ["not-used", "hit", "miss"].indexOf(acquisition.cache.result) < 0)
    return _failure("candidate acquisition facts are unsupported")
  if (!Array.isArray(acquisition.discarded_install_flags) ||
      acquisition.discarded_install_flags.some(function(flag) { return ["enable", "yes"].indexOf(flag) < 0 }))
    return _failure("candidate install flags are unsupported")
  if (_commit(target.revision) !== revision ||
      ["resolved-git-request", "pinned-revision", "marketplace-listing"].indexOf(target.source) < 0 ||
      target.scope !== "plugin-root")
    return _failure("candidate target is not bound to the resolved commit")
  if (analysis.schema !== "omasafe.analysis.v1" || !Array.isArray(analysis.findings) ||
      !Array.isArray(analysis.capabilities) || !Array.isArray(analysis.invocation_edges) ||
      !Array.isArray(analysis.coverage_limitations))
    return _failure("candidate analysis schema is unsupported")
  if (profile.name !== "review" || _count(profile.serialized_byte_limit) === null ||
      profile.serialized_byte_limit > 1572864)
    return _failure("candidate review profile is unsupported")

  var omissions = _obj(profile.omissions)
  var payloadOmission = _omission(omissions, "payload_entries")
  var findingOmission = _omission(omissions, "findings")
  var capabilityOmission = _omission(omissions, "capabilities")
  var edgeOmission = _omission(omissions, "invocation_edges")
  if (!payloadOmission || !findingOmission || !capabilityOmission || !edgeOmission ||
      !Array.isArray(payload.entries) || payload.entries.length !== 0 ||
      !_obj(payload.totals) || _count(payload.totals.entries) !== payloadOmission.total ||
      findingOmission.emitted > MAX_ITEMS || capabilityOmission.emitted > MAX_ITEMS ||
      edgeOmission.emitted > MAX_ITEMS ||
      analysis.findings.length !== findingOmission.emitted ||
      analysis.capabilities.length !== capabilityOmission.emitted ||
      analysis.invocation_edges.length !== edgeOmission.emitted)
    return _failure("candidate review profile omission data is invalid")

  var effectiveUrl = _safeUrl(acquisition.effective_repository_url)
  if (!effectiveUrl) return _failure("candidate repository URL is unavailable")
  if (acquisition.input_kind === "marketplace-id" && !_obj(acquisition.marketplace_claim))
    return _failure("marketplace candidate attribution is unavailable")

  var findings = analysis.findings.slice(0, MAX_ITEMS).map(_finding)
  var capabilities = analysis.capabilities.slice(0, MAX_ITEMS).map(_capability)
  var edges = analysis.invocation_edges.slice(0, MAX_ITEMS).map(_edge)
  var highCritical = false
  var classified = true
  for (var f = 0; f < analysis.findings.length; f++) {
    var severity = _str(analysis.findings[f] && analysis.findings[f].severity).toLowerCase()
    if (["info", "low", "medium", "high", "critical"].indexOf(severity) < 0) classified = false
    if (severity === "high" || severity === "critical") highCritical = true
  }
  var completeFindings = findingOmission.omitted === 0 && classified
  var installCommand = completeFindings && !highCritical
    ? _suggestedInstallCommand(acquisition, effectiveUrl) : ""
  var installCommandReason = findingOmission.omitted > 0
    ? "Suggested install command withheld because the compact report omits findings."
    : highCritical
      ? "Suggested install command withheld because high or critical findings were reported."
      : !classified
        ? "Suggested install command withheld because finding severity is incomplete."
        : "Suggested install command unavailable."
  var limitationTexts = analysis.coverage_limitations.slice(0, MAX_ITEMS).map(function(value) {
    return _display(value, MAX_TEXT)
  })
  var acquisitionLimitations = _arr(acquisition.limitations).slice(0, MAX_ITEMS).map(function(value) {
    return _display(value, MAX_TEXT)
  })
  for (var l = 0; l < acquisitionLimitations.length; l++) limitationTexts.push(acquisitionLimitations[l])

  var stateCounts = {}
  var states = _obj(payload.coverage_states) || {}
  for (var state in states) {
    var stateCount = _count(states[state])
    if (stateCount !== null) stateCounts[_display(state, 128)] = stateCount
  }

  var listed = acquisition.listed_repository === null || acquisition.listed_repository === undefined
    ? "" : _display(acquisition.listed_repository, 2048)
  var claim = _obj(acquisition.marketplace_claim)
  var marketplace = claim ? {
    verificationStatus: _display(claim.verification_status, 64),
    listingCommit: _commit(claim.listing_validated_commit),
    catalogCommit: _commit(claim.registry_commit),
    ageSeconds: _count(claim.age_seconds)
  } : null
  var policyKey = ""
  try { policyKey = JSON.stringify(analysis.policy_identity || {}) } catch (ignore) { policyKey = "" }
  policyKey = _display(policyKey, MAX_TEXT)

  return {
    ok: true,
    toolVersion: _display(top.tool_version, 32),
    target: {
      source: _display(target.source, 64),
      id: _display(target.id, 512),
      url: _display(target.url, 2048),
      revision: revision,
      root: _display(target.root, 1024)
    },
    acquisition: {
      inputKind: _display(acquisition.input_kind, 64),
      installVerb: _display(acquisition.install_verb, 32),
      requestedReference: _display(acquisition.requested_reference, 128),
      discardedFlags: _arr(acquisition.discarded_install_flags).slice(0, 8).map(function(value) {
        return _display(value, 32)
      }),
      resolvedRevision: revision,
      integrityAlgorithm: algorithm,
      networkUsed: acquisition.network_used === true,
      cacheResult: _display(acquisition.cache && acquisition.cache.result, 32),
      listedRepository: listed,
      effectiveRepositoryUrl: effectiveUrl,
      marketplace: marketplace,
      installationPerformed: false
    },
    suppressions: { policy: "candidate-unsuppressed", consulted: false },
    analysis: {
      fingerprint: _display(analysis.analysis_fingerprint, 128),
      policyKey: policyKey,
      findings: findings,
      findingsTotal: findingOmission.total,
      findingsOmitted: findingOmission.omitted,
      capabilities: capabilities,
      capabilitiesTotal: capabilityOmission.total,
      capabilitiesOmitted: capabilityOmission.omitted,
      edges: edges,
      edgesTotal: edgeOmission.total,
      edgesOmitted: edgeOmission.omitted,
      coverageStates: stateCounts,
      limitations: limitationTexts
    },
    profile: {
      serializedByteLimit: profile.serialized_byte_limit,
      omissions: {
        payloadEntries: payloadOmission,
        findings: findingOmission,
        capabilities: capabilityOmission,
        edges: edgeOmission
      }
    },
    marketplace: marketplace,
    listedRepository: listed,
    installCommand: installCommand,
    installCommandReason: installCommandReason,
    highCriticalFindings: highCritical,
    rescanCommand: "omasafe-cli scan-plugin --git " + effectiveUrl + " --revision " + revision +
      " --report-profile review --format json",
    noActiveFindings: findingOmission.total === 0 && findingOmission.omitted === 0
  }
}
