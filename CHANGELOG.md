# Changelog

All notable changes to the OmaSafe plugin are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project aims to follow
semantic versioning once the two-view UI ships (`0.3.0`).

## [Unreleased] — Phase 4: comprehension, correctness and polish

The Flow surface is made correct in the running shell and rewritten to explain itself
before any cosmetic polish. See `docs/implementation/phase-4-polish.md`.

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
`docs/implementation/phase-3-trust-flow.md`.

### Added

- **Flow view (`views/FlowView.qml`)** — reachable on chip `[Flow]` / key `2`. Four fixed
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
authority (see `docs/implementation/phase-2-information-architecture.md`). Every list is
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
visual change (see `docs/implementation/phase-0-correctness.md`):

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
cannot be bypassed (see `docs/implementation/phase-1-shell-and-confirmation.md`). The four
tab bodies are untouched and keep working by mouse; Phase 2 rebuilds them on kit rows.

- **Kit shell** — the hand-rolled tab strip and status-identity block become a `PanelHero`
  (all eleven states in the CLI's own vocabulary; a failed scan never prints a positive
  headline from stale data), a status line, reasoned `NoticeRow`s, and one `ButtonGroup` of
  view chips, over a `Flickable` body that always scrolls (T1.5/T1.6).
- **Bar icon** — `OmaSafeShield` replaces `OmaSafeStatusIcon`: the shield SHAPE (filled vs
  outline), not its colour, says whether a current scan result exists, with a sibling
  `bodySmall` count and an urgent badge only for a critical/error alert or a block; a failed
  scan never shows the filled quiet glyph (T1.7).
- **Tokens** — colour and type are declared once on the root (`fg`, `urgent`, the `dimStep`
  ladder, `hoverFill`/`selectedFill`, `fontFamily`); the three `#e5a50a` literals and
  `Color.muted` are gone, and there is no warning hue (T1.2/T1.3).
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
  polish pass. See `docs/implementation/`.
