# Changelog

All notable changes to the OmaSafe plugin are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project follows
semantic versioning (`0.5.0` for the current v0.3.1 glanceability release).

## [Unreleased] — v0.3.1 glanceability

Paired with `omasafe-cli 0.3.1`. `cliVersionMin` stays `0.3.0`: every surface below
degrades cleanly on 0.3.0, and the two fields that need the newer CLI ship dark.

Nothing here adds a score, grade, percentage or aggregate judgement, and no action
was added to any boundary — no install, enable, trust, suppress, override, schedule
or approve, and the Source Scan install-command visibility rule is untouched.

### Added

- **Posture summary band** — a unit strip of one cell per check in CLI catalog
  order, the state counts in attention order with their zeros, a coverage
  *sentence*, the host/age line, and a tools line that names a missing tool
  together with its consequence. Six lines, above the fold at base 12.
- **Posture attention-first body** — `NEEDS ATTENTION` (error · regression ·
  incomplete · attention) expanded with evidence, the coverage limitation labelled
  `Not observed`, and the next step; then `OBSERVED`, grouped by the domain prefix
  of the check id and collapsed to one line each carrying a fact from the check's
  first evidence string. The tab went from ~90 rendered lines to a summary plus 26
  collapsed rows.
- **Copy command** on a posture next step, copying the backticked span the report
  printed, verbatim. The panel never runs it and never synthesises one.
- **Source Scan result band** — severity meter, `BY RULE` ranked bars, a 17-cell
  capability strip in the same catalog order an installed plugin uses, and a
  coverage meter over the payload states. Above the install command and above the
  findings, so the first sweep lands on the distribution rather than on an action.
- **One reconciliation line per collection**, printed always
  (`n shown · n omitted by the scanner · n hidden by the display cap`), replacing
  five omission notices with one that names every non-zero term.
- **Keyboard reach on both tabs.** Posture and Source Scan gain real cursor
  sections: the check strip, the attention set, the copy actions, the observed
  list, the scan findings and the scan copy actions. `/` finds posture checks and
  scan findings. No new keys.
- **Tab chips carry counts** — Overview and Posture. A digit when the collector
  ran and found items, `·` when it ran and found none, `–` when it has not run.
- **Bar shield tooltip** gains one host-posture line, in the same words as the tab.
  `alertCount` is unchanged.
- `components/UnitStrip.qml`, `components/MeterBar.qml`,
  `components/RankedBars.qml`, `components/PostureCheckBlock.qml`,
  `model/Tiers.js`, `model/Posture.js`, `scripts/posture-test.js`,
  `scripts/harness/` and `docs/design/fixtures/`.
- Three glyphs, verified by codepoint **and** glyph name: `incomplete`
  (`md-progress_question`), `not-applicable` (`md-minus_circle_outline`) and
  `changed` (`md-delta`).

### Changed

- **`incomplete` no longer shares severity `high`'s mark.** In a unit strip, where
  the state word is not on the cell, "we could not look" and "high severity" were
  the same glyph.
- **The semantic tier palette moved to `model/Tiers.js`** so the charts and the row
  marker paint from one ladder. `SemanticMark`'s public API is unchanged.
- The posture header no longer prints `14 COMPLETE · 2 INCOMPLETE · 2 N/A`.
  `complete` there means "observation succeeded" and includes the regression, so
  the line read as "14 fine". It is a sentence now, on its own axis.
- Plugin detail renders the six payload coverage states as the candidate's meter
  and counts line, and gains a `BY RULE` block from `review_summary.rule_counts`.
  The Rules Baseline V3 summary gains a bar; its counts line is unchanged.
- Source Scan findings are collapsed rows that `Enter` expands, instead of every
  line of every finding always rendered.

### Fixed

- **The installed path could draw omission as absence.** `ViewModel` grouped
  `analysis.capabilities[]` and `analysis.findings[]` without consulting
  `report_profile.omissions`, so the Overview capability strip, the Matrix cells
  and the Rules green check treated "we cannot claim completeness" as "we looked
  and there was nothing". A new `analysisExact` verdict is required before any
  cell renders `·` and before the green check is drawn; it is true only when each
  consumed collection reports finite counters that reconcile with `omitted === 0`
  and sizing recovery was not applied. **A missing counter is not evidence of
  zero.** No visual change against a real report — `plugins analyze` resolves
  exact today — and correct degradation against eight synthetic ones.
- The candidate capability strip renders `–`, not `·`, at unobserved positions
  whenever anything was omitted or capped, with the header marked `PARTIAL` and
  the derived counts prefixed `at least`.
- **The two new tabs were keyboard-unreachable.** `sectionCount()` returned 1 for
  each, which pinned the cursor on the first cell of a horizontal section; 18
  posture checks and 32 findings existed and none was reachable.
- Plugin detail truncated `changed_files` at five with no disclosure; it now
  prints `+N more changed files`.
- `Posture.build()` never infers: a missing field yields null and the view renders
  nothing, so an absent coverage block produces no reconstructed sentence.

### Deferred

- **`checks[].previous_state` and `checks[].gap_open_since` (CLI 0.3.1).** The
  change mark and the `open N days` slot are implemented and absent-safe, and ship
  **dark**: `omasafe-cli 0.3.0` emits neither field, so no delta mark can be
  produced from a real report. Do not export `posture-state.json →
  previous_states` — despite its name it holds the states of the report that
  produced it, so `previous_state == state` for every check and every delta mark
  would silently disappear. The CLI must capture the displaced prior before the
  insert. The panel-side guard is in place; the real two-run verification is open.
- Posture history and a state timeline; posture in `BarWidget.alertCount`; the
  structural merge of `UnitStrip` and `CapabilityStrip`; top-files hot-spot bars.

## [Unreleased] — v0.2.4 review evidence compatibility

### Added

- **Host Posture tab** — renders the CLI's `omasafe.posture.v1` report with
  explicit pass, regression, attention, informational, incomplete, and error
  states, coverage limitations, host facts, and a bounded Run posture scan action.

- Source Scan and installed Analysis retain review freshness, presentation completeness,
  occurrence IDs, analysis methods, structured evidence steps, behavior context, and
  typed coverage gaps while keeping legacy reports readable.
- Review collection counts distinguish CLI omissions from the UI display cap; contradictory
  summary arithmetic is rejected before it can become a quiet-state presentation.

## [Unreleased] — v0.2.3 Cached installed-scan hydration

### Added

- **CLI-owned scan cache** — the widget hydrates the installed-analysis profile
  through `scan-cache show`, labels cached/validated/stale provenance, and keeps
  prior rows visible when a later scan fails. Cache files are private and safe to
  delete without affecting trust or enforcement history.
- **Lazy panel cache validation** — startup performs a bounded show-only request;
  the first panel open may request read-only context validation.
- **Enforcement summary badge** — ordinary scan reports now surface typed block
  decisions when the CLI provides them.
- **Persistent analysis details** — installed-plugin analysis survives shell restarts
  through the CLI-owned bounded cache; opening the panel restores cached analysis
  counts across the overview and detail views, while an explicit Analyze action
  refreshes the result.
- **Schedule controls and execution status** — the Sources row shows the next trigger,
  last outcome, and offers confirmed Disable plus reinstall/policy controls.

### Changed

- The widget now requires CLI `0.2.3` for the cache and schedule lifecycle; Source
  Scan remains a separate tab rather than an Overview shortcut.
- The legacy `last-scan.json` QML cache is no longer read or written.
- Schedule exit 3 is rendered as findings, while exit 1 is rendered as a failed run;
  the timer's next trigger is shown when systemd provides it.

## [Unreleased] — v0.2.2 Plugin Source Scan

### Added

- **Plugin Source Scan** — the dedicated Source Scan tab accepts a GitHub URL or copied plain
  Omarchy install command, retains the last result in session memory, and renders
  the CLI's exact-commit, scan-only report without installing or enabling anything.
- **Conditional install guidance** — when complete findings contain no high or critical
  item, the tab shows a suggested install command for copying; it stays hidden when
  findings are omitted or severity is incomplete.
- **Bounded candidate state** — resolving/fetching/analyzing progress, cancellation,
  120-second timeout cleanup, strict acquisition/identity/report normalization,
  omission-aware findings/capabilities/coverage, and an exact rescan command.

## [Unreleased] — Phase 5: expanded panel

### Added

- **Analysis status markers** — the former Flow tab is now user-facing **Analysis**.
  Shared health/severity markers span alerts, plugins, rules, capabilities and
  graph nodes: green checks are reserved for current no-alert/no-hit states,
  while medium, high and critical findings use yellow, amber and red tiers.
- **Persistent scan snapshot** — the last successful parsed scan is retained under
  the XDG cache directory and shown as stale after restart until a fresh scan runs.
- **Focused graph pulse** — selected or pinned medium/high/critical graph nodes use
  a bounded halo pulse without moving graph geometry.

- **Expand/Compact panel** — the existing popup can grow to a fitted wide view with
  all four Graph layers (`PLUGINS → CAPABILITIES → RULES → BASELINE V3`) visible at
  once. The button sits beside Scan in the hero action row on every tab; Compact keeps
  the normal popup size, and the expanded size persists while switching tabs. The `g`
  shortcut and button call the same panel-wide toggle. Expanded Matrix now uses
  responsive cell widths, a larger label column and a two-line class header.
- **Wide-layout regression coverage** — `scripts/flow-test.js` now verifies four-column
  placement and the expanded row budget.

### Fixed

- **Bar alert-count overlap** — the shield and sibling alert count now use an explicit
  content-sized layout (including the inter-item gap and a trailing optical guard) so
  negative-bearing neighboring glyphs cannot paint over the count.
- **Matrix table alignment** — compact and expanded Matrix columns now start at the
  panel edge and share the available width; horizontal scrolling is used only when
  the full catalog is wider than the viewport.
- **Matrix header consistency** — the plugin column now keeps a visible `PLUGINS`
  heading in every all-plugin state (or `PLUGIN` for a scoped row), including before
  any plugin has been analyzed; the title is stable in compact and expanded layouts.

## [Unreleased] — Phase 4: comprehension, correctness and polish

The Flow surface is made correct in the running shell and rewritten to explain itself
before any cosmetic polish. See `../omasafe-docs/implementation/phase-4-polish.md`.

### Fixed

- **Graph rendered no nodes** — every `FlowNode` delegate failed to instantiate at runtime
  (required `modelData` / `index` re-declared on an imported root: fine under `qmllint`,
  dead in the shell). `graph/TrustFlow.qml` now uses a wrapper delegate that owns the model
  roles and passes them into `FlowNode` by explicit binding.
- **Graph collapsed to one row** — `flowMaxRows` was derived from the panel's current
  (content-sized) height, and the graph body is `rows · rowH`, so the window self-collapsed
  to a single row regardless of plugin count. Row budget now comes from the panel's maximum
  reachable height (`flowViewportHeightMax`); `FlowLayout` still caps `geometry.rows` at the
  tallest column so small graphs stay tight.
- **`+N more` painted over a node** — in a one-row window (`realRows == 0`) the overflow rail
  drew at `y = 0` on top of the single node; it is now hidden when no row is reserved for it.
- **Trace claimed plugin-wide data was path-specific** — `FILE EDGES` and `COVERAGE LIMITS`
  are the plugin's call graph and coverage gaps, not one class path's; they are now labelled
  `· PLUGIN-WIDE` instead of `ON THIS PATH`.
- **Stale analysis preempt** — a superseded selected-plugin request could be chained by a
  later, current analysis completion; the stale `onExited` branch now clears the deferred
  request slots before returning.
- **Overlapping capability glyphs** — the Overview capability strip packed 17 glyphs into
  one `Text`, so Nerd-Font icons (whose ink is wider than their advance) drew over their
  neighbours. `components/CapabilityStrip.qml` now lays out one fixed-width, glyph-centred
  cell per catalog position, so positions align across rows and never collide.

### Changed

- **Progressive disclosure** — Z0 (all plugins) opens on the readable **Matrix** lens, Graph
  one keystroke away; Z1 (one plugin) opens on Graph. The graph draws no resting-state edges
  — only a cursor's one hop or a pinned path — so labels and counts lead, not spaghetti.
- **Says what it is** — the heading reads `ANALYSIS PATHS`, with a legend line
  `Plugin → observed capability → detecting rule → Baseline V3 mapping`. The inspector is
  never blank, and carries the `solid = parser-backed · dashed = text match only` vocabulary.
- **Honest incompleteness** — when fewer than all live plugins are analyzed, a persistent
  callout says `N of M plugins analyzed — paths are incomplete. Press A to analyze the rest.`;
  absent paths are never implied to be absent capabilities.
- **Typed overflow** — `+N more` rails now name what they hide (`+3 plugins`, `+N Baseline ids`).

## [Unreleased] — Phase 3: the trust flow

The third view lands: an interactive trust graph inside the 420-unit popup. See
`../omasafe-docs/implementation/phase-3-trust-flow.md`.

### Added

- **Analysis view (`views/FlowView.qml`, internal Trust Flow lens)** — reachable on chip
  `[Analysis]` / key `2`. Four fixed
  layers `PLUGINS → CAPABILITIES → RULES → BASELINE V3` drawn as the same `CursorSurface`
  rows the other views use, joined by cubic-Bézier edges in one `Shape` through
  `Shape.CurveRenderer`. A focus pair of two open columns with two rails; `h`/`l` cross
  columns landing on the nearest connected node and slide a rail open, `j`/`k` walk a
  column, Enter pins then opens (Z1 / Matrix / rule sheet / coverage row). Nothing encodes
  a verdict: counts are printed digits, edge weight is thickness, confidence is a dash.
- **Pure layout engine (`graph/FlowLayout.js`)** — node sets, order keys, a barycentre
  tie-break over the middle layers, the shared window with `+N more`, focus-pair geometry,
  eight bucketed path strings, and `hot()` (cursor 1-hop, pin full reach). `relayout()`
  recomputes geometry and paths on navigation without touching the node models. Covered by
  `scripts/flow-test.js` (78 assertions reproducing the four recorded analyses: 5 class /
  6 rule / 12 baseline nodes, 16 / 6 / 1 / 0 edges, order keys, same-epoch preservation).
- **`model/ViewModel.flowInput()`** — walks raw analyses into per-plugin `byClass`
  evidence, class/rule/baseline aggregates and the derived edges; Z1 scoping and the
  zero-analyses sentinel.
- **Graph primitives** — `graph/{TrustFlow,FlowNode,EdgeLayer,MatrixGrid,TraceChain}.qml`
  and `components/InspectorStrip.qml`. Matrix lens (`m`, `c` for all 17 classes) and the
  Z2 Trace (`t`) over the same store.
- **Root analysis queue** — `analysisQueue` / `analysisSweepGeneration` /
  `analysisStateById`; `a` queues the cursor plugin (never changing the selection), `A`
  every uncached live plugin, `x` drops the rest of a sweep. One `Process`, sequential;
  the 30 s timeout and 2 MiB cap apply per run. Analysis runs on `a`/`A` only, never on
  view open.
- **`?` legend** — a `PanelToolTip` of glyphs, edge styles and keys.

## [0.3.0] — Phase 2: information architecture

The four-tab UI becomes two views plus a plugin detail sheet, and every fact is placed by
authority (see `../omasafe-docs/implementation/phase-2-information-architecture.md`). Every list is
now written once, on the kit row grammar, bound to one normalised view model.

### Changed

- **Two views, one detail sheet** — `overviewTabComponent` / `findingsTabComponent` /
  `pluginsTabComponent` / `catalogTabComponent` are deleted and rebuilt as `views/`:
  Overview (`ALERTS · PLUGINS · SOURCES`, the product-disclaimer footer, the backups
  toggle) with a plugin detail sheet at depth 1 (`TRUST BASELINE · WHAT CHANGED · REVIEW
  ITEMS · CAPABILITIES OBSERVED · COVERAGE · MARKETPLACE CLAIM · ENFORCEMENT ·
  PROVENANCE`), and the Rules view (`RULE CATALOG` + `BASELINE V3 COVERAGE`). The chips
  collapse to `[Overview] [Rules]` on keys `1` and `3`; `2` (Flow) is inert until Phase 3.
- **One view model** — `model/ViewModel.js` normalises inventory, status, analysis,
  marketplace, schedule, override, rules and coverage into the object every view binds to
  (`readonly property var vm`), so no delegate walks a raw report; it strips `file_digests`
  and tolerates null inputs.
- **Row grammar written once** — `components/{ActionRow,AlertRow,PluginRow,ClassRow,
  EvidenceRow,EdgeRow,SourceRow,RuleRow,RelationRow,CapabilityStrip,FactPill,Breadcrumb,
  FinderField}` compose the kit `CursorSurface`/`Button` parts; hover routes through
  `PointerMoveGate`, never `containsMouse`.
- **Authority separation (GR2)** — a catalog claim and a trust word never share a row;
  every `registry_claim.verification_status` starts `Catalog says:` and "verified" is
  suppressed for a stale snapshot; ineligible verbs stay visible, dim, and name the unmet
  condition.
- **Coverage always visible (GR4)** — plugin rows print ` · <n> limits` and ` · text match
  only`; the detail sheet renders `COVERAGE | <n> LIMITS` / `NO LIMITS REPORTED` grouped
  by file then kind.
- **Rules and finder** — a 16th bounded collector fetches `rules list --format json`
  (cached per CLI version); the Rules view expands each rule into its sheet with LOCAL
  HITS and `rules explain` Baseline V3 relations, and the Baseline V3 table carries no
  plugin count. `/` opens a finder over an ~85-string index (plugins, capability classes,
  rule ids + titles, Baseline ids); LOCAL HITS and rule counts read `–`, never `0`, before
  any analysis.
- **Depth and return frame** — per-view depth with `h` / `-` / the breadcrumb popping one
  level, and one cross-view return frame so Open rule (and a finder result opened from
  another view) returns to where it was invoked. Data arrival never changes view, depth or
  cursor.

## [Unreleased]

### Fixed

Phase 0 correctness and authorization fixes, made inside the existing four-tab UI with no
visual change (see `../omasafe-docs/implementation/phase-0-correctness.md`):

- **Forced tab jump** — opening with alerts, and a successful trust, no longer yank the
  view to Findings / away from Plugins (T0.7, A1).
- **Non-modal confirmation** — the confirmation is now modal: while an authorization is
  pending, controls behind the scrim cannot be clicked, hovered or scrolled, and every
  action control is gated on `navigationLocked` (T0.3, A2).
- **Stacking confirmation flags** — the five independent `*Confirming` booleans are
  replaced by a single `pendingAction`; confirmations never stack and the confirm button
  runs exactly one action through one switch (T0.4, A2/GR6).
- **Drifting authorization facts** — the trust/replace/remove confirmation pins plugin id,
  head, tree and digest at open and builds argv from those pinned values, refusing on
  drift, so the CLI receives exactly the identity the user was shown (T0.18, PF-10).
- **Esc during confirmation** — Esc, `close()`, and any panel close now drop the pending
  action instead of leaving a confirmation armed behind a closed panel (T0.5, A3).
- **Ungated `r`** — the scan hotkey and Scan button share one `scanAvailable` condition, so
  `r` no longer starts a scan during a confirmation or an in-flight scan (T0.6, A4).
- **Unrendered trust result** — a completed trust/untrust now renders a result line keyed on
  the CLI's own words and the authorized identity (T0.8, A1/GR3).
- **Expanding every item sharing a rule** — review-item expansion is keyed on the finding
  (`rule:path:line`), not the rule id (T0.9, A17).
- **Undeduplicated capabilities** — observed capabilities are grouped as `<class> ×<n>`
  instead of a flat token list (T0.10, A7).
- **`Coverage: complete` for missing data** — absent coverage renders `Coverage unavailable`,
  `[]` renders `No limitations reported`, never a fabricated `complete` (T0.11, A8/GR3).
- **`rules explain` plaintext/JSON blob** — the command now requests `--format json`,
  requires the report schema, renders named rule fields, and shows a clear unavailable line
  on any parse or schema failure (T0.12, A13).
- **60-second enforcement flash** — the periodic enforcement refresh no longer blanks a known
  decision to its loading string (T0.13, A21).
- **Catalog claim called "verified"** — the review-update sheet names the catalog claim and
  its verifier rather than asserting a "verified commit" (T0.14, A10/GR2).
- **Unrendered inventory coverage limits** — inventory-level `coverage.limitations` are now
  surfaced instead of being silently dropped (T0.15, A9/GR4).
- **Cold analysis on every open** — a cached analysis survives close/reopen; the cache is
  dropped selectively per plugin on the alert kinds that invalidate it, not wholesale
  (T0.16).
- **Enable/Remove showing unchecked facts** — Enable and Remove are gated unavailable with a
  clear reason until a CLI release implements the expected-identity mutation contracts
  (T0.17, A2/GR6).

Also removed ~950 lines of never-instantiated legacy content (T0.1, A39) and set
`textFormat: Text.PlainText` on every `Text`, so attacker-influenced strings render as plain
text (T0.2, A6/GR4).

### Changed

Phase 1 rebuilds the chrome around the content out of `qs.Ui` primitives and theme tokens,
puts one keyboard cursor over the shell targets, and replaces the overlay with a sheet that
cannot be bypassed (see `../omasafe-docs/implementation/phase-1-shell-and-confirmation.md`). The four
tab bodies are untouched and keep working by mouse; Phase 2 rebuilds them on kit rows.

- **Kit shell** — the hand-rolled tab strip and status-identity block become a `PanelHero`
  (all eleven states in the CLI's own vocabulary; a failed scan never prints a positive
  headline from stale data), a status line, reasoned `NoticeRow`s, and one `ButtonGroup` of
  view chips, over a `Flickable` body that always scrolls (T1.5/T1.6).
- **Bar icon** — `OmaSafeShield` replaces `OmaSafeStatusIcon`: the shield SHAPE (filled vs
  outline), not its colour, says whether a current scan result exists, with a sibling
  `bodySmall` count and an urgent badge only for a critical/error alert or a block; a failed
  scan never shows the filled quiet glyph (T1.7).
- **Tokens and semantic markers** — colour and type are declared once on the root (`fg`,
  `urgent`, the `dimStep` ladder, `hoverFill`/`selectedFill`, `fontFamily`); the shared
  `SemanticMark` adds theme-aware green/yellow/amber/red status tiers while keeping the
  state word and glyph visible (T1.2/T1.3).
- **One cursor** — the dev-gallery cursor model drives a single highlight over the hero scan
  button and the view chips by keyboard and mouse; no `Button` is `focusable`, so Tab keeps
  switching bar panels (T1.8).
- **Confirmation sheet** — the modal overlay becomes `ConfirmSheet`, which keeps the kit
  `ConfirmDialog` contract, pre-selects Cancel, drops held/auto-repeat Enter for 300 ms, does
  not pre-select on hover, caps the card height with a scrolling middle, and shows the pinned
  action-specific authorization facts with bare-verb buttons (T1.9).
- New pure-JS modules `model/{Labels,Glyphs,Time}.js` own the closed-enum labels, the
  verified Nerd/ASCII glyph table, and relative-time/age formatting (T1.1).

- Planned for Phases 2–4: two-view information architecture, the Trust Flow graph, and the
  polish pass. See `../omasafe-docs/implementation/`.
