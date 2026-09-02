# CLI v0.2.1 hardening integration

Status: implemented in plugin version 0.2.1.

The panel requires `omasafe-cli` 0.2.1 or newer by default. It verifies the
CLI with `--version` before invoking any operational command, and rejects an
older or malformed binary. The optional identity check remains available as
the `cliVersionRequireIdentity` setting.

## Consumed contracts

All commands use argv-style invocation, bounded output buffers, timeouts, and
request/selection guards. Unknown schemas and enum values are rendered as
unsupported or unavailable; they are never treated as an allow or clean state.

| CLI surface | Panel behavior |
|---|---|
| `scan --include-analysis --format json` | Includes v0.2 analysis alerts in the count/state badge and marks prior alerts stale when a scan fails. |
| `plugins analyze ID --format json` | Loads lazily in Findings; shows findings, parser fallback, coverage states/limitations, capabilities, and provenance. Cache is keyed by plugin identity, CLI version, and analyzer policy identity. |
| `rules explain RULE_ID` | Loads on demand and caches per CLI version and rule id. |
| `rules coverage --format json` | Loads a bounded, read-only Baseline V3 coverage drawer with explicit relation labels. |
| `plugins enforcement-status ID --format json` | Loads on selection and refreshes while open; displays the CLI decision, reason codes, identities, binding, and recovery command. |
| `schedule status --format json` | Shows CLI-owned schedule policy, unit identity, and last execution without scraping systemd output. |
| `schedule install --policy advisory\|hardened` | Requires explicit confirmation and states that scheduled scans are report-only. |
| `plugins enable ID --policy advisory\|hardened --format json` | Offers a confirmed control only for an installed, provably inactive plugin. The CLI owns preflight, mutation, postconditions, and rollback. |
| `plugins review-update ID --expected-commit SHA --policy advisory\|hardened --yes` | Requires a trusted baseline and marketplace commit claim; confirmation shows the exact commit/digest and selected policy. |
| `plugins override list --format json` | Read-only listing of active/expired exact bindings. The panel never creates overrides. |

The plugin retains the count/state badge and does not synthesize a safety
score. Marketplace verification remains attributed to the marketplace
snapshot, while enforcement outcomes remain attributed to the CLI.

## Version skew

An older CLI is rejected before panel commands run because the panel consumes
the v0.2.1 enforcement and schedule contracts. A newer CLI may add fields to
the versioned reports; the panel ignores additive fields and remains
fail-closed for unknown decision enums. Start a new Omarchy Shell session (or
rescan plugins) after installing a new CLI so the panel re-runs its version
probe.

## Validation

From the plugin repository root:

```sh
omarchy plugin validate .
qmllint BarWidget.qml Panel.qml
```
