# CLI v0.2 integration for the OmaSafe panel

Status: implemented in the 0.2.1 plugin release. The v0.2 analyzer surfaces
below are additive and remain compatible with the `omasafe.report.v1` envelope.

OmaSafe CLI 0.2.1 is backward-compatible with the v0.2 commands this plugin
already invoked (verified against the 0.2.1 source: version gate, `scan`
report shape, `plugins trust/review/status/diff/inventory` argv and JSON,
exit codes 0/3). The sections below record the v0.2 contracts and how the
panel adopts them.

## What v0.2 adds that the UI can consume

### 1. Analysis alerts in scan output (`scan --include-analysis`)

Default scans stay quiet by design. With the flag, the report's `alerts[]`
can carry four new kinds:

| kind | severity | meaning |
|---|---|---|
| `new-capability` | warning | analysis observed a capability class it had not seen before for this plugin |
| `finding-regression` | warning | a rule id appeared that was absent from the last recorded evaluation |
| `analyzer-policy-update` | warning | rule catalog / parser / limits changed; findings re-evaluated |
| `fingerprint-instability` | error | same source + policy but different fingerprint; nondeterminism suspected |

The bar badge counts every `alerts[]` entry generically, so adopting this is
a one-word change and needs no new UI logic. Badge stays count/state.

- Bar: `BarWidget.qml` scan invocation → add `"--include-analysis"`.
- Scheduled timer: the unit runs `scan --notify --only-new` (hardcoded by
  the CLI's `schedule install`). Surfacing these alerts in desktop
  notifications requires a CLI-side change first (flag on the unit template);
  tracked as a CLI issue, not plugin work.

### 2. Per-plugin findings report (`plugins analyze ID --format json`)

Full analysis of an installed plugin under `result.analysis`, schema-pinned
(`omasafe.analysis.v1`) by a CLI integration test:

- `findings[]`: `rule_id`, `severity`, `confidence` (evidence quality, not a
  verdict), `relative_path`, `line`, `evidence`, `explanation`,
  `review_guidance`, `capability`, `language`
- `capabilities[]`: observed ability occurrences with confidence
- `invocation_edges[]`: resolved references between files
- `coverage_limitations[]`: always render when non-empty (budget/skip notes)
- `parser`: object with grammar versions, or explicit **null** = lexical-only
  build. That null IS the degradation signal — show a "lexical mode" hint.
- `policy_identity`, `analysis_fingerprint`, `equivalence`: provenance block;
  display verbatim in a details drawer rather than interpreting.
- Exit code 4 = `--fail-on SEV` threshold breached (useful for scripted checks).

### 3. Rule catalog (`rules list --format json`, `rules explain RULE_ID`)

Static, versioned catalog compiled into the CLI (no external DB). The panel
can deep-link any finding's `rule_id` to `rules explain` output instead of
duplicating guidance text.

### 4. Reviewed update flow (`plugins review-update ID …`)

The v0.2 headline feature. Safe to drive from the panel because the CLI owns
every safety property (dirty-tree refusal, trusted-baseline requirement,
candidate validation, native delegation, postcondition verification, fail-
closed interruption):

```
omasafe-cli plugins review-update <ID> \
  --expected-commit <sha> --yes
```

Prefill `--expected-commit` from inventory:
`result.marketplace[].registry_claim.upstream_observed_commit` (present when
`status` is `listed`/`installed-differs`; it is a registry *claim* — the CLI
still verifies the exact candidate before anything goes live).

Exit codes to handle: `0` updated+trusted · `1` refused/failed (stderr carries
the specific reason: dirty worktree, no baseline, manifest invalid, raced
commit, native failure — surface it verbatim) · `130` interrupted (plugin left
disabled; show the stderr recovery steps).

Never call without `--expected-commit`: unattended mode requires the exact
pin by design.

### 5. Inventory additions already available today

- `result.marketplace[]`: per-plugin correlation `status`
  (`listed|installed-differs|unlisted|conflict|incomplete`), human `reason`,
  disclaimer, and the full `registry_claim` block
  (`upstream_observed_commit`, `upstream_moved`, `verification_status`,
  `listing_validated_commit`, registry commit/repository).
- Top-level `marketplace_snapshot_verified`, `marketplace_age_seconds`,
  `marketplace_stale` for snapshot health display.

### 6. v0.2.1 enforcement and schedule handoff

The panel treats enforcement as a CLI-owned, additive contract. The inventory
result may include `enforcement_summary` with the last decision's compact
`evaluation_state`, `outcome`, `authorization_basis`, and `evaluated_at` for
each installed plugin. Selecting a plugin lazily invokes:

```text
omasafe-cli plugins enforcement-status PLUGIN_ID --format json
```

The full decision is rendered only as data: unknown schemas or enum values show
as unsupported, while reason codes and blocking rule IDs remain visible. The
panel never evaluates policy, validates overrides, or decides expiry. It does
not create overrides; H8a's interactive terminal-only command remains the sole
creation path.

The Overview tab also consumes:

```text
omasafe-cli schedule status --format json
```

This is the only source for installed/not-installed state, advisory/hardened
policy, report-only behavior, unit identity, and the last known execution
result. The panel never scrapes `systemctl` output or infers policy from unit
text. Missing or stale status is rendered as unavailable, never as clean.

## Panel information architecture: replace the single long page with tabs

Before adding the larger v0.2 views, split the current vertically stacked
panel into four tabs. Use the interaction pattern from
`/home/hvo/Projects/omarchy-unraid/Panel.qml`: a compact tab strip, one
`activeIndex`, keyboard navigation, and a `Loader` that instantiates only the
active tab. Do not copy its Unraid-specific components or data flow.

The panel remains one `KeyboardPanel`; “tabs” are internal views, not separate
popups or separate bar widgets.

| tab | contents | primary actions |
|---|---|---|
| **Overview** | scan state/message, installed/trusted/review/untrusted counts, CLI/panel errors, non-built-in-bar warning, short safety disclaimer | Run scan |
| **Findings** | scan `alerts[]`; selected plugin's `plugins analyze` findings, coverage limitations, lexical-mode warning, and rule explanation drawer | Select alert/finding, explain rule |
| **Plugins** | installed plugin list, selected plugin identity/status/diff, trust controls, reviewed-update eligibility and result | Select, trust, untrust, review update |
| **Catalog** | marketplace snapshot integrity/age/staleness, selected listing claims and disclaimer | Update catalog |

Four tabs fit the existing 420-unit panel without horizontal scrolling and
keep distinct concepts separate: current posture, evidence to review, local
plugin actions, and marketplace claims. Marketplace claims must not be mixed
into the Overview status in a way that looks like an OmaSafe verdict.

### Shared state and navigation contract

- Add `tabs`, `activeIndex`, `setActive(index)`, and `switchTabBy(delta)` at the
  panel root. Use stable tab keys internally (`overview`, `findings`, `plugins`,
  `catalog`) even if labels change later.
- Keep the compact status identity, tab strip, and global Run scan control
  outside the tab `Loader` so the current state and refresh action remain
  available while navigating. Show the outstanding count on the Findings tab
  label; do not add a score or grade.
- Preserve `selectedPluginId` across tabs. Selecting a scan alert sets that id
  and stays on Findings so analysis can be reviewed; an explicit “Open plugin
  controls” action switches to Plugins. Selecting an installed plugin from the
  Plugins tab must not implicitly switch tabs.
- Support mouse selection, Left/Right tab cycling, number keys 1–4, `R` for a
  scan, and the existing panel close/switch shortcuts via `PanelKeyCatcher`, as
  demonstrated by the reference panel.
- Each tab starts at scroll position 0 when activated. Use one bounded active-
  tab `Flickable` (or one per tab) rather than retaining the old long-page
  scroll offset across unrelated views.
- An unavailable or old CLI disables only the commands it cannot serve. The
  Overview error and tab navigation remain usable.

### Component and process boundaries

Refactor visual sections into root-level `Component`s named
`overviewTabComponent`, `findingsTabComponent`, `pluginsTabComponent`, and
`catalogTabComponent`, selected by the active tab key. Keep these outside the
component instances:

- all `Process`, timeout, queue, and bounded-output state;
- inventory, status, diff, analysis, rule-explanation, and marketplace reports;
- selected plugin/tab ids and operation errors; and
- trust, untrust, and reviewed-update confirmation state.

This is important because changing tabs destroys the active `Loader` item. A
tab switch must never cancel a CLI process, clear its result, or lose the
target identity for a destructive confirmation. Confirmation UI should be a
modal layer outside the `Loader`; disable tab switching while a confirmed
trust/untrust/update operation is executing.

Continue loading inventory once when the panel opens and running the existing
per-plugin status queue independently of the active tab. Load expensive v0.2
data lazily:

- run `plugins analyze ID --format json` when Findings needs analysis for a
  selected installed plugin;
- cache the result only for that plugin's current content digest, invalidating
  it after scan, inventory identity change, trust/update completion, or panel
  close; and
- run `rules explain RULE_ID` only when a finding is expanded, with one cached
  explanation per CLI version + rule id.

All new collectors need the scan path's output cap, timeout,
first-terminal-event latch, and argv-only invocation, plus stale-selection
protection. The existing panel collectors use `waitForEnd` without all of
those bounds; phase 2 should extract one reusable bounded process pattern and
apply it to inventory, status, diff, trust, and catalog refresh before adding
analysis/update collectors. A late response for plugin A must not overwrite
the visible result for plugin B.

### Migration phases

1. **Shell first, no behavior change**
   - Introduce the tab model, tab strip, keyboard handling, active-view loader,
     and per-tab scrolling.
   - Move existing content only: summary/actions to Overview, alerts to
     Findings, selection/trust/compliant list to Plugins, and snapshot/listing
     claims to Catalog.
   - Keep current root properties, helpers, commands, and processes unchanged.
2. **Selection and dialog hardening**
   - Make selection shared across Findings and Plugins.
   - Move trust/untrust confirmations outside the active component and verify
     tab switches/rapid reselection cannot apply a result to the wrong plugin.
3. **Add v0.2 analysis to Findings**
   - Add the lazy analysis process and render findings without collapsing them
     into a score. Always show coverage limitations; show lexical mode when
     `parser === null`; keep provenance verbatim in an expandable details area.
4. **Add reviewed update to Plugins**
   - Gate the action on eligible marketplace status, trusted-baseline state,
     and an observed upstream commit. Confirmation displays the exact commit
     passed as `--expected-commit`; surface CLI refusal/recovery text verbatim.
5. **Add rule explanations and polish**
   - Add the lazy rule drawer, tab count, empty/loading/error states, focus
     restoration, and accessible tooltips/keyboard hints.

### Acceptance checks for the tab refactor

- At 420-unit target width all four labels and the global scan/refresh control
  fit without clipping or horizontal scrolling.
- Opening the panel performs one inventory load, not one load per tab switch;
  tab switching does not duplicate the per-plugin status sweep.
- Overview, Findings, Plugins, and Catalog each have explicit loading, empty,
  error, and unavailable-CLI states.
- Switching tabs during inventory/status/analysis/catalog refresh preserves the
  operation and renders its result in the correct tab when it completes.
- Rapidly selecting two plugins cannot show the first plugin's status, diff, or
  analysis under the second plugin's name.
- Trust, untrust, and reviewed update always confirm the plugin id and exact
  pinned identity/commit; keyboard tab switching cannot bypass confirmation.
- Findings tab count equals the CLI's outstanding count and remains count/state,
  never a safety grade. Catalog verification remains explicitly attributed as
  a marketplace claim.
- Mouse, Left/Right, 1–4, `R`, close, and panel-switch keyboard paths work; each
  newly activated tab begins at its top and receives focus predictably.

## Suggested adoption order

1. **P1 — multi-tab shell**: complete migration phases 1–2 before adding v0.2
   detail views. This shortens the current page without changing CLI behavior.
2. **P1 — badge coverage**: add `--include-analysis` to the bar scan. Zero UI
   risk; new alert kinds start counting automatically.
3. **P1 — version floor**: keep the configured CLI floor aligned with the
   shipped enforcement contract before release; an old CLI must not serve new
   views. During the v0.2.1 development window the panel renders unavailable
   status rather than treating an older CLI as an allow.
4. **P2 — findings tab**: complete migration phase 3, fed by
   `plugins analyze --format json`; render `coverage_limitations` and the
   lexical-mode indicator prominently; never summarize findings into a score.
5. **P2 — reviewed-update button**: enabled only when
   `marketplace[].status ∈ {listed, installed-differs}` and a trusted baseline
   exists (`plugins status` clean or acknowledged); confirm dialog shows the
   pinned commit; stderr passthrough for refusals.
6. **P3 — rule deep-links**: tap a finding → `rules explain <rule_id>` text.

## Ground rules (unchanged)

All invocations stay argv-style with bounded JSON parsing; the badge remains
count/state, never a grade; marketplace fields are claims, not guarantees
(already worded that way in the inventory disclaimer).
