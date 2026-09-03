# OmaSafe UI/UX overhaul — decision record

Date 2026-09-02. Role: lead designer / architect, final call. Inputs: `brief.md`; drafts A (evidence-first), B (graph-first),
C (keyboard-dense); the three judge verdicts (end-user, security-designer, qml-engineer); the six research reports;
`cli-samples/`; `Panel.qml` (5174 lines); the Quattro kit at `/usr/share/omarchy/shell`. Every kit name, token, signal,
codepoint and line number below was re-verified against the installed files today; where a draft or a judge was wrong,
the correction is stated and is binding for all six documents.

Versions: omasafe-cli 0.2.1 · plugin 0.2.1 · Omarchy 4.0.2 Quattro · Quickshell 0.3.1 · Qt 6.11.2 · JetBrainsMonoNerdFont.

## 0 Verdict

Direction A ("Evidence first, calm surface") is the base. All three judges ranked A > B > C (80 / 79 / 67.5; 85 / 78 / 65;
82 / 76 / 66). We ship A's shell, information architecture, copy system and honesty machinery, and graft into it B's graph
(Baseline V3 as a drawn layer, dashed evidence edges, Matrix lens, verified glyph table, no-bypass invariants, the optional
wide surface under B's contract) and C's keyboard mechanics (global finder, breadcrumb depth stack, blocked-mode confirm
wiring, a/A-only analysis, ineligible-verb copy, the Panel.qml fate table). The graph — named **Trust Flow** — lives inside
the 420-unit popup as its primary and complete home. A `panel`-kind window is an optional final phase, never a dependency.

## 1 Why A wins — in the judges' evidence

| Criterion (weights: comprehension, graph, honesty ×2) | Evidence the judges cited for A | Scores (EU / Sec / QML) |
|---|---|---|
| End-user comprehension | The `PanelHero` title is the CLI's own status sentence, so the first screen answers "am I okay" without a caption; sections run alerts → plugins → sources, plumbing last; exactly one non-destructive action per row; every mutating verb carries an effect + caveat sentence. | 9 / 9 / 9 |
| Honesty (GR1–GR4) | One `NoticeRow` reason enum for loading / none / unavailable / unsupported / stale / lexical-only; `Labels.js` is the single closed-enum map; three authority headers with the authority in the right slot; every catalog string prefixed "Catalog says:"; `COVERAGE` always rendered; `decision: null` never "allowed"; `Color.urgent` at most once per screen. | 8.5 / 9 / 9 |
| Quattro-native fit | Only kit primitives (`PanelHero`, `ButtonGroup`, `PanelSectionHeader`, `PanelSeparator`, `CursorSurface`, `Button`, `PanelActionButton`); `Qt.darker` dim ladder; `Style.*FillFor`; motion inside the kit set; no cards, no filled accent button, no stat strip. Would pass as the tailscale panel's sibling. | 8 / 9 / 8 |
| QML feasibility | Phase 0 fixes every audited defect with zero visual change (855 tab jump, 947/2267 flags, 1161/1169 findingKey, 2277 `r` gate, 2421/2425 scrim, 2923 dedupe, 3376 "complete", 4681 flicker, 4830 `--format json` — all line numbers re-verified today); collectors 3815–5173 untouched; ~3-week roadmap. | 8 / 9 / 8 |
| Completeness / copy | Every status string, enum label, alert kind, empty state, tooltip and confirm template is written out and passes the "It is a fact that…" test; plumbing words (gate, preflight, fingerprint, mutation) leave the UI. | 9 / 9 / 9 |

Why B is not the base: a second QML tree with a second collector instance and a 256 KB payload that renders data the window
did not fetch; adding a `panel` kind flips `shell.qml:426–438 isBarWidgetPanelPlugin`, so `shell summon io.github.tuthan.omasafe`
changes meaning; `bar.shell` (Bar.qml:25 `property var shell: null`) may be null on third-party bars; a severity ladder of
`Util.alpha(urgent, 0.35/0.56)` pills and an `attentionFill` on "differs" is a hue ramp on non-block states (GR1); §5.3 plugin
rows print "Matches baseline · 2 review items · listed" (GR2 slip); hero title "OmaSafe" demotes the answer to caps meta; a
nine-week path with the high-risk phase in the middle; `PanelActionButton.iconSpinning` does not exist (only `Button` has it).
Why C is not the base: TUI mannerisms with no first-party precedent (two-letter class codes, box-drawing trees, always-on
two-line footer, hairlines between rows, `bodySmall` as row primary); five top-level views reinstate the tab sprawl; the
opening screen is a matrix that needs a legend; there is no visual graph; U+25D0 (its medium glyph) is absent from
JetBrainsMonoNerdFont-Regular (re-checked); the all-17 matrix overflows 420 units at base 12; ▁▃▅▇ magnitude bars and alpha
"heat" invite big-equals-bad.

A's defects, each closed by a graft in §2: focus-pair rails too cramped and Baseline V3 not drawn (G1, G4, G13); no matrix
answer to "which plugins can do Y" (G3); confidence carried by a ring on the same glyph as availability (G2, §6); `󰄬` for
"matches baseline" reads as a safe-mark (G10); coverage map attributed to snapshot commit 65b6385 instead of
`verified_at_commit` 964dc08 (G11); auto-analyze queue on entering Flow (G18); "routes every PanelKeyCatcher signal to
`sheet.handleKey`" cannot compile — signals are not `KeyEvent`s (G14); glyph codepoints unverified (G9); 160 ms column-width
`Behavior` would misalign `PathSvg` edges mid-slide (§5); "item to review" vs "review item" near-collision (§7).

## 2 Grafted ideas and where each lands

| # | Graft | From | Lands in | Replaces in A |
|---|---|---|---|---|
| G1 | Baseline V3 drawn as the fourth layer: 12 externalIds in map order, relation glyph `=`/`≈`/`—`, not-covered ids present with no incoming edge; rule→baseline edges solid for structural-equivalent, dashed for partial-overlap; class-level (`omaCapability`) mappings dashed past the rule column | B | 04 §layers; `graph/TrustFlow.qml`, `graph/FlowLayout.js` | Baseline V3 confined to the rule sheet |
| G2 | Dashed edge buckets (`ShapePath.DashLine`, `dashPattern: [4,4]`, both confirmed in `/usr/lib/qt6/qml/QtQuick/Shapes/plugins.qmltypes`) for edges backed only by `lexical-fallback`/null; every edge dashed when `parser == null` | B | 04 §encodings; `graph/EdgeLayer.qml` | filled/hollow ring on node glyphs |
| G3 | Matrix lens: plugins × capability classes, `Text` digits, `·` none observed, `–` not analyzed; observed classes by default, `c` toggles all 17 (horizontal `Flickable` when wider than the card) | B form, C default | 04 §Matrix; `graph/MatrixGrid.qml`, `views/FlowView.qml` | "filter Overview by a capability node" |
| G4 | Trace zoom (Z2): pinned path as a chain line, `EVIDENCE` rows (path:line · detail · confidence word), `FILE EDGES` with target coverage state, `COVERAGE LIMITS ON THIS PATH`; Baseline coverage table with `exercised here · of N analyzed` and a not-covered footer | B | 04 §Z2; `graph/TraceChain.qml`; 03 §Rules | Zoom 2 sites + rules only |
| G5 | `CapabilityStrip`: one `Text` of 17 glyphs in fixed catalog order, presence only (class glyph when observed, `·` none, `┄` not analyzed); one `PanelToolTip` listing observed classes with counts | B fixed order, C single-Text, Sec judge encoding | 03 §PLUGINS; `components/CapabilityStrip.qml` | count-sorted chip `Row` |
| G6 | Every filter or toggle prints what it hides in the header meta: `HIDING 7 BACKUPS · 4 NOT ANALYZED` | B | 03 / 04 header meta | dim-only filter |
| G7 | No-bypass invariants as code and acceptance checks: one `pendingAction` enum; `swallowNextActivate` set by `openSheet()`; `navigationLocked` disables every action `Button` and the view/lens/finder controls; `close()` and `onOpenedChanged(false)` reset `pendingAction` | B | 05 Phase 0/1; `Panel.qml` root | prose |
| G8 | Inventory-level `coverage.limitations[]` (never rendered today) as a `NoticeRow` under the hero when non-empty; CLI asks carried forward: read-only `scan --status`, `recorded_at` in `plugins status` (verified absent: `trusted` has no such key) | B | 03 §hero; 05 open questions | per-plugin coverage only |
| G9 | Verified Nerd Font codepoint table (all 41 UI + class glyphs present in JetBrainsMonoNerdFont-Regular.ttf, re-checked with fontTools) with an ASCII fallback selected when `Style.font.resolvedFamily` lacks "Nerd" | B | 02 §iconography; `model/Glyphs.js` | open question 1 |
| G10 | `󰄬` is never a state glyph; "matches baseline" is a word only | B | 02 §encodings | trust unchanged glyph |
| G11 | Coverage map attributed to `rules coverage` `verified_at_commit` 964dc08… and `map_version` 2, never to `marketplace_repository_commit` 65b6385 | B | 03 §Baseline V3; 04 coverage | "verified at catalog commit 65b6385" |
| G12 | Backups behind a kit `Toggle { label: "Show 7 backup copies (not scanned)" }` row at the end of PLUGINS | B | 03 §PLUGINS | SOURCES row |
| G13 | Optional Phase 5 wide surface under B's contract: manifest `kinds: ["bar-widget","panel"]`, `entryPoints.panel`, `bar.shell.summon(manifest.id, JSON.stringify(payload))` (network/Panel.qml:468 precedent), `open(payloadJson)`/`close()` with `shell.hide` (wifiqr 51–92), degradation ladder, no warm analysis caches in the payload, identity re-fetched before any sheet, README documents the IPC route change | B | 05 Phase 5; `TrustFlowWindow.qml`, `manifest.json` | one-line "S2 option" |
| G14 | Confirm-sheet key wiring: `keyCatcher.blocked = sheet.opened \|\| finder.activeFocus`; the sheet takes `activeFocus` on open and its `Keys.onPressed` calls the kit `handleKey(event)` contract; focus returns to the catcher on close | C | 03 §confirmations; 05 Phase 1; `components/ConfirmSheet.qml` | "route signals to handleKey" |
| G15 | Global `/` finder over one prebuilt lowercase index (8 plugins + 17 classes + 45 rules + 15 Baseline ids ≈ 85 strings); results replace the view body under `PLUGINS · CAPABILITIES · RULES · BASELINE V3` (≤ 6 each); Up/Down/Enter inside the `TextField`; Esc clears and refocuses the catcher | C | 03 §finder; `components/FinderField.qml`, `views/FinderResultsView.qml` | per-view filters in Rules and Flow |
| G16 | Per-view depth stack with a breadcrumb line (`All plugins › lgse.sandman`; `lgse.sandman › process-execution › oma.qml.process-execution › curl-pipe-shell`), popped by `h` (vertical section) or `-`; Backspace opportunistic (verify `event.text === "\b"` in Phase 1) | C | 03 §navigation; `components/Breadcrumb.qml` | `h`-back without a path |
| G17 | `FILES AND EDGES` section: `invocation_edges` as `from ─▶ target` chains with the target's coverage state appended when not `analyzed` (`Service.qml ─▶ sandman.py · partially analyzed · text match only`) | C | 03 §detail sheet; `components/EdgeRow.qml` | absent |
| G18 | Analysis runs only on `a` (cursor plugin) / `A` (all live plugins, sequentially through the existing queue); never on view open | C (B agrees) | 04 §states; 05 | auto-analyze queue |
| G19 | Ineligible verbs stay visible, dim, with the unmet condition named | C | 03 §detail actions; 02 copy | review update only |
| G20 | `InspectorStrip` states identical facts for whatever the cursor is on in Graph, Matrix and Trace (node, cell, rule, baseline row) | C | 04 §inspector; `components/InspectorStrip.qml` | graph-only `FlowInspector` |
| G21 | Text-only Matrix + Trace as the graph fallback if `Shape.CurveRenderer` misbehaves; Canvas is not a fallback | C | 04 §fallback; 05 Phase 3 | Canvas fallback |
| G22 | Rule rows and LOCAL HITS show `–` (never 0) until at least one plugin is analyzed; unanalyzed plugins listed as "not analyzed", never omitted | C | 02 copy; 03 §Rules | "Fires here … · 4 not analyzed" |
| G23 | Enforcement null copy: "No decision has been recorded. A decision exists only after a gated enable or reviewed update." | C | 02 copy | one sentence |
| G24 | Untrust / Replace effect sentences; baseline definition line as the PLUGINS footer | C | 02 copy | confirm-only caveat |
| G25 | Panel.qml range → fate table as the shared refactor checklist | C | 05 Phase 0 | five-step split |
| G26 | Colon-grammar limitation parser `kind[:sub]:file[:line[:target]]` grouped by file then kind (`LidService.qml · 8 sink references rejected (absolute) · 5 missing local target`), raw codes one Enter away, unknown → verbatim + "unsupported limitation" | C | 03 §COVERAGE; `model/Labels.js` | one row per code, `+12 more` |
| G27 | Data floor: anything read as data (ids, paths, line numbers, hashes, counts, rule ids, strip glyphs) is `bodySmall` or larger at every base size; `caption` only for headers, hero meta, hints, relative times | C intent, restated | 02 type roles | caption secondary lines |

Rejected: C's four-row IDENTITY block (duplicates the three authority sections and weakens GR2 separation); C's ▁▃▅▇ bars
and alpha heat; B's 17-`Rectangle` strip; B's urgent-alpha pills and `attentionFill`; B's skeleton rows (no precedent);
B's second collector instance as a default; C's five views; C's `t/u/e/U` mutation accelerators; A's 160 ms column slide.

## 3 Final information architecture

```
Bar: BarIconButton { iconComponent: OmaSafeShield }  glyph 󰒃 · caption count · one urgent badge (critical/error/block)
Panel > KeyboardPanel  contentWidth fittedContentWidth(Style.space(420)) · fittedContentHeight(h, Style.space(560))
└─ PanelKeyCatcher  blocked: sheet.opened || finder.activeFocus
   └─ Flickable > Column spacing Style.space(12)
      ├─ PanelHero            title = status sentence · meta = counts/age · detail "cli 0.2.1" · trailing scan Button
      ├─ Status line          bodySmall: verbatim cliError (urgent) or stale sentence (dim); hidden otherwise
      ├─ NoticeRow ×0..n      unavailable · stale · lexical-only · inventory coverage limitations
      ├─ ButtonGroup          [Overview] [Flow] [Rules]   keys 1 2 3
      ├─ FinderField          TextField, shown by "/"; results replace the view body (PLUGINS · CAPABILITIES · RULES · BASELINE V3)
      ├─ Breadcrumb           shown at depth >= 1
      ├─ Loader (view, 140 ms opacity crossfade)
      │   ├─ Overview (depth 0)   ALERTS · PLUGINS (+ Toggle backups; definition footer) · SOURCES · disclaimer footer
      │   │   └─ depth 1: PluginDetailView (hero swaps to plugin id; back PanelActionButton 󰅁)
      │   │        TRUST BASELINE | LOCAL · WHAT CHANGED | N FILES (state changed only) · CAPABILITIES OBSERVED | n · k CLASSES
      │   │        REVIEW ITEMS | n · <severity summary> · FILES AND EDGES | n EDGES · COVERAGE | n LIMITS
      │   │        MARKETPLACE CLAIM | CATALOG <commit7> · <age> · ENFORCEMENT | POLICY · PROVENANCE (collapsed)
      │   │        review item / class / limitation / provenance rows expand inline (no depth change)
      │   ├─ Flow (depth 0 = Z0 Atlas)   TRUST FLOW · ALL PLUGINS | 4 OF 8 ANALYZED · lens ButtonGroup [Graph] [Matrix]
      │   │   ├─ Graph lens: 4 layers PLUGINS → CAPABILITIES → RULES → BASELINE V3, focus pair + rails, EdgeLayer
      │   │   ├─ Matrix lens: plugins × classes grid
      │   │   ├─ depth 1 = Z1 Plugin scope (one plugin; Enter on a plugin node, or "2" from a detail sheet)
      │   │   ├─ depth 2 = Z2 Trace (chain · EVIDENCE · FILE EDGES · COVERAGE LIMITS ON THIS PATH)
      │   │   └─ InspectorStrip (3–4 lines, fixed, under the body)
      │   └─ Rules (depth 0)   RULE CATALOG | V7 · 45 RULES (ListView) · BASELINE V3 COVERAGE | 12 PARTIAL · 3 NOT COVERED
      │        rule row expands inline to the rule sheet (facts · LOCAL HITS · BASELINE V3 relations)
      │        baseline row expands inline (covering rules · note · exercised here)
      └─ footer (Overview only): "OmaSafe reports changes and coverage limits. It does not declare plugins safe."
   ConfirmSheet  z: 20, outside the Loader   (Phase 5 only: TrustFlowWindow.qml, panel kind, summoned from the Flow header)
```

Primary (no interaction): hero sentence + meta, alert rows, plugin rows with strip and review-item count, disclaimer.
Secondary (one Enter): detail sheet sections, Flow inspector, rule sheet. Tertiary (second Enter): raw `evidence`,
`explanation`, `review_guidance`, parsed limitations, provenance fields, full digests, override bindings, stderr.

## 4 Final navigation model

1. Data arrival never changes view, depth or cursor (`setActive(1)` at 855 and the post-trust re-selection go). Trust
   success renders a success line in place and reconciles with `plugins status`.
2. `1/2/3` switch views; each view keeps its own depth stack and cursor; pressing the current view's digit pops to depth 0.
3. Enter drills one level (plugin row → detail sheet; plugin node → Z1; pinned capability/rule node or `t` → Z2; rule row →
   inline sheet); `h` in a vertical section, `-`, the back `PanelActionButton` or the breadcrumb pop one level and restore
   the previous cursor. Views without depth ignore `-`.
4. Esc closes the panel (kit grammar) except: sheet open → `canceled()`; finder focused → clear, hide, refocus catcher.
5. Mutations exist only as `Button`s inside the section they change (TRUST BASELINE, MARKETPLACE CLAIM, ENFORCEMENT,
   SOURCES schedule row) and always pass through `ConfirmSheet`. No letter opens or performs a mutation. Scan (`r`) and
   Update catalog remain unconfirmed with inline progress (`Updating catalog… 12 s`).
6. `close()` resets `pendingAction`, finder text and depth stacks; keeps `view` and `selectedPluginId`.

## 5 Final graph concept — Trust Flow

Form: deterministic, layered, left-to-right DAG over four fixed layers `PLUGINS → CAPABILITIES → RULES → BASELINE V3`,
nodes drawn as `CursorSurface` rows, edges as cubic Béziers in one `Shape`. Evidence (sites and findings) is not a column:
it is the Trace zoom, because at Z0 finding groups collapse to the same keys as rules and a fifth column does not fit.
Marketplace is never a layer (GR2); trust state, catalog status and enforcement are inspector facts and node adornments
(bold label = outstanding alert; `󰂭` urgent glyph = enforcement block, the one urgent element).

| Aspect | Decision |
|---|---|
| Surface | In-panel view "Flow" (primary, complete). Optional Phase 5 `TrustFlowWindow` (`panel` kind, `Style.space(1080)` card) opens all four layers at once; summoned from the Flow header slot `PanelActionButton 󱁉 "Open large view (g)"`, hidden when unavailable. |
| Popup layout | Focus pair: two adjacent layers open (`openW = (width − 2·railW − 3·gutter) / 2`, ≈ 146 units at base 12, 110 at base 9), the other two are rails (`railW = Style.space(28)`: glyph + count). `h`/`l` slide the pair; widths snap (no `Behavior` — edges would misalign). Default pair Z0: PLUGINS \| CAPABILITIES; Z1: CAPABILITIES \| RULES. Rows `Style.spacing.popupRowHeight`; ≤ `floor(Style.space(360) / rowH)` rows per column (12 at base 12) with a `+N more` rail row; edges into hidden nodes end at that row. |
| Node sets | Plugins: live, non-backup (8). Capabilities: classes present in any cached analysis (Matrix: all 17). Rules: referenced by drawn evidence (6 here; all 45 only in Rules view). Baseline: 12 externalIds in map order, not-covered edgeless. |
| Order | Plugins: outstanding alert desc, analyzed first, id. Classes: occurrences desc, name. Rules: findings desc, occurrences desc, id. Baseline: map order. One barycentre sweep left→right then right→left over the middle layers (< 100 nodes, sub-ms), stable ties. |
| Edges | plugin→class weight = occurrences; class→rule via `source_rule_id` and `findings[].rule_id`; rule→baseline via `omaRuleId`; class→baseline dashed via `omaCapability`. Thickness buckets `Style.space(1)` ≤ 3, `space(2)` 4–9, `space(3)` ≥ 10. Dash = confidence (G2) or partial-overlap (G1). Rest alpha `Util.alpha(fg, Style.hoverBorderAlpha)`, hot `Util.alpha(fg, 0.9)`. |
| Zoom / lenses | Z0 Atlas (all plugins, aggregated) · Z1 Plugin (one plugin's classes, rules, baseline ids; non-neighbours `Qt.darker(fg, 2.0)`) · Z2 Trace (chain + evidence rows) · Matrix lens (`m`) · Baseline coverage table (Rules view). Four views for doc 04's wireframes: Z0, Z1, Z2, Matrix, plus coverage table. |
| Interactions | hover / `j` `k` move within a column (hot 1-hop set follows); `h` `l` cross columns clamping to a connected node; Enter pins (`current`) and opens the inspector; Enter again on a pinned plugin → detail sheet, rule → rule sheet, baseline id → Rules coverage row, capability → Z1 filtered; `x` unpins (never mutates); `t` trace; `a`/`A` analyze; `/` finder; `m` lens; `c` all classes (Matrix); `b` backups; `?` legend `PanelToolTip`; wheel scrolls the column under the pointer via `PointerMoveGate`. |
| Rendering | `FlowNode` = `CursorSurface` rows in four `Repeater` columns (window ≤ 13 each ⇒ ≤ 52 items); `EdgeLayer` = one `Shape { preferredRendererType: Shape.CurveRenderer }` with 8 static `ShapePath { PathSvg }` buckets: dim × {thin, medium, thick} × {solid, dashed} + hot × {solid, dashed} at `space(2)`. Same technique as `Ui/BorderOverlay.qml:51`. `Repeater` cannot host `ShapePath`, so buckets are static; empty path strings cost nothing. |
| Fallback | If `CurveRenderer` fails under fractional scaling on the Phase 3 smoke test: Matrix lens + Trace tree (text rows only) become the Flow body; no `Canvas`. Verified fact for all docs: no first-party file instantiates a `Canvas` element (`qrCanvas` wifiqr:279 is a `Rectangle`, `opticalCanvas` BarIconButton:24 is an `Item`); the ethos report's "Canvas graph" suggestion is superseded. |
| Budget | ≤ 52 node items, ≤ 150 edges (136 worst case plugin→class, ≈ 25 real), path strings ≤ 6 KB, layout rebuilt only on inventory / analysis / scope / filter change, hot path on cursor change only; zero `Timer`s beyond collector timeouts; Flow `Loader` unloaded when the panel is closed; forbidden: `layer.enabled`, `MultiEffect`, `Particles`, force simulation, `Canvas`. |
| States | CLI unavailable → `NoticeRow` in place of the body; no analyses → plugin column hollow, rails read `not analyzed`, inspector offers `Analyze (a) · Analyze all (A)`; analysis failed → hollow node + `unavailable`, never zero; `parser == null` → persistent lexical-only `NoticeRow` + all edges dashed; limitations → `· N limits` suffix; filter active → `HIDING …` meta; enforcement block → `󰂭`. |

## 6 Final visual system

Type roles (family: `bar ? bar.fontFamily : Style.font.family`; no literal `font.pixelSize` anywhere):

| Role | Token | Notes |
|---|---|---|
| Hero title / meta / detail / glyph | `Style.font.title` bold / `caption` bold upper (kit) / `body` bold dim (kit) / `display` | all inside `PanelHero` |
| Status line, key:value, digests, rule ids, paths, evidence, strip glyphs, matrix digits, node labels | `Style.font.bodySmall` | data floor (G27); hashes `WrapAnywhere` only on hash-only `Text` |
| Row primary, notice text, button label, confirm body | `Style.font.body` | bold only for an outstanding alert |
| Section header, header right value, chip labels, hints, relative times, footer, node counts | `Style.font.caption` | `PanelSectionHeader` default; ≈ 25 uses, down from 110 |
| Row leading glyph / hero action glyph | `Style.font.icon` (= title) in a `Style.space(22)` column / `Style.font.display` in hero | `OpticalGlyph` |
| Confirm title | `Style.font.title` bold | `ConfirmSheet` |

Spacing: panel `fittedContentWidth(Style.space(420))`, `fittedContentHeight(h, Style.space(560))` (the inner `space(480)` cap
at 2394 goes); outer `Column.spacing: Style.space(12)`; section `space(10)`; rows `space(6)`; lines `space(1)`; row height
`content + Style.spacing.rowPaddingX`; insets left `space(10)`, right `space(8)`; glyph column `space(22)`, gap `space(8)`;
key:value `GridLayout { columnSpacing: Style.space(20); rowSpacing: Style.spacing.labelGap }`; confirm card
`min(width − space(32), space(370))`, padding `space(18)`, buttons `space(88) × space(34)`, gap `space(10)`; graph `railW
space(28)`, `gutter space(24)`, height cap `space(360)`; long lists `ListView { height: min(contentHeight, space(400)) }`.

Colour (declared once on each root; nothing else is a colour expression):

```qml
readonly property color fg:           bar ? bar.foreground : Color.foreground
readonly property color urgent:       bar ? bar.urgent : Color.urgent
readonly property color dimHeader:    Qt.darker(fg, 1.4)   // matches PanelHero.dim / PanelSectionHeader
readonly property color dim:          Qt.darker(fg, 1.5)   // secondary, unavailable, unsupported, notices
readonly property color faint:        Qt.darker(fg, 2.0)   // disabled glyphs, non-neighbour graph nodes
readonly property color hoverFill:    Style.hoverFillFor(fg, Color.accent)
readonly property color selectedFill: Style.selectedFillFor(fg, Color.accent)
```

`Color.accent` reaches the screen only through the kit; `Color.muted` is never used (falls back to foreground, Color.qml:23/
164); `#e5a50a` is deleted from Panel.qml:153, BarWidget.qml:116, OmaSafeStatusIcon.qml:9; there is no warning token and no
warning colour. `Util.alpha(fg, …)` only inside `EdgeLayer` (bound to `Style.hoverBorderAlpha` / 0.9) and the kit.
`Color.urgent` appears at most once per screen, for exactly one of: critical/error severity glyph, enforcement block glyph or
row border, CLI failure status line, destructive confirm button (kit), bar badge.

Semantic encodings (word first, then shape, then weight; hue never alone; no opacity ramps):

| Meaning | Word (always printed) | Glyph | Weight |
|---|---|---|---|
| Trust unchanged / partial / untrusted / revoked | matches baseline · matches · coverage limited · no baseline · baseline revoked | none | regular |
| Trust changed | differs · N files | `󰀦` | bold |
| Trust loading / unavailable / unsupported | checking… / unavailable / unsupported | none | dim |
| Severity info / low / medium / high | the word | `󰋽` / `󰝦` / `󰝥` / `󰀦` | regular / regular / regular / bold |
| Severity critical / unknown | critical / unsupported | `󰀦` in urgent / none | bold / dim |
| Confidence ast-backed / lexical-fallback / null | parser-backed / text match only / no parser | none (edges: solid / dashed / dashed) | — |
| Alert row | kind label | `󰀦` fg; urgent only for critical / error | bold primary |
| Catalog claim | Catalog says: … | none, never a pill, never beside a trust word | regular |
| Enforcement block / allow / null | Blocked: … / Allowed by policy·override / two-sentence null | `󰂭` urgent / none / none | row `Border.flat(urgent, Style.normalBorderWidth)` / regular / dim |
| Unavailable / unsupported / not analyzed | literal word | hollow `󰝦` on graph nodes only | dim; hero glyph `iconOpacity 0.5` |
| Lexical-only build | Lexical-only analysis (no QML parser). Review items are text matches. | `󰀦` fg | persistent `NoticeRow` |
| Cursor / current | — | — | `CursorSurface.hasCursor` → `hoverFill` + `Border.controlSpec("hover-cursor")`; `current` → `selectedFill` |

Radius `Style.cornerRadius` on rows, confirm card, graph nodes; pills (only the two disabled bordered `Button`s on an expanded
review item) `Style.cornerRadius > 0 ? height / 2 : 0`. Borders only via `Border.controlSpec` (kit), `Border.flat(Color.accent,
Style.normalBorderWidth)` (confirm card), `Border.flat(urgent, Style.normalBorderWidth)` (block row). No cards. Scrim
`Util.alpha(Color.background, 0.7)` with a swallowing `MouseArea`.

Motion: 60 ms row fill (`CursorSurface`), 120 ms `Button` fill, 140 ms `Easing.OutCubic` opacity for view swap / sheet push-pop
/ lens swap, 120 ms `ColorAnimation` on the hot `ShapePath` stroke, 900 ms `Button.iconSpinning` and bar `RotationAnimation`
only while `opened && checking`. Nothing else animates; no geometry `Behavior`s; nothing runs while closed.

Iconography (Nerd Font, verified codepoints): shield `󰒃` U+F0483 (same glyph as tailscale/Panel.qml:767), in-flight `󰦖` F0996,
rescan `󰑐` F0450, back/open `󰅁`/`󰅂` F0141/F0142, expand/collapse `󰅀`/`󰅃` F0140/F0143, copy `󰆏` F018F, alert `󰀦` F0026,
info `󰋽` F02FD, block `󰂭` F00AD, rule `󰧮` F09EE, catalog/baseline `󰆼` F01BC, large view `󱁉` F1049, filled/outline circle
`󰝥`/`󰝦` F0765/F0766, Git-managed `󰊢` F02A2, installed without git `󰏗` F03D7, backup `󰁓` F0053, unsupported `󰘥` F0625.
Classes: process-execution `󰆍` F018D · detached-process-execution `󰏌` F03CC · network-access `󰖟` F059F · filesystem-access
`󰉖` F0256 · sensitive-path `󰌆` F0306 · input-injection `󰌌` F030C · screen-capture `󰹑` F0E51 · persistence-scheduling `󰔛`
F051B · clipboard-access `󰅌` F014C · compositor-control `󰍹` F0379 · polkit-agent-ui `󰯄` F0BC4 · session-lock-surface `󰍁`
F0341 · pam-authentication `󰀋` F000B · dynamic-code-execution `󰅩` F0169 · shell-ipc-inventory `󰌘` F0318 · replaces-bar-context
`󱂢` F10A2 · bundled-binary `󰍛` F035B · unknown → `󰘥` + "unsupported". Text glyphs (verified): relation `=` `≈` `—`, edge `─▶`,
crumb `›`, strip `·` `┄`, rail more `+N`. Never `󰄬`, never `✓ … ⟳ ? !` text glyphs, never emoji, never U+25D0.

Density: rows are two lines; plugin row line 1 = glyph · id (`ElideMiddle`) · right-aligned trust word; line 2 = strip ·
`N review items` / `not analyzed` / `analysis unavailable`. At base 9 the trust word abbreviates and the strip stays (17 ×
bodySmall glyphs ≈ 130 px); at base 20 nothing wraps to a third line. Light themes accept the kit's `Qt.darker` contrast trade;
acceptance screenshots in `white` (urgent `#2a2a2a`), `catppuccin-latte`, `retro-82`, `oxocarbon`, `ame-quattro` at 9/12/16/20.

## 7 Final copy vocabulary and status strings

Voice: factual, present tense, sentence case with a period for messages, uppercase for hero meta and headers, no exclamation
marks, no "Are you sure?", no clean / safe / protected / verified (bare) / risk / dangerous / permission. Test: prefix "It is a
fact that…" and the sentence stays true given only the CLI JSON.

| Use | Never | Note |
|---|---|---|
| capability (observed in source) · occurrence · site | permission, grant, request | Omarchy has no permission boundary |
| review item (rule match) | finding (in UI), vulnerability, issue | "finding" stays in code |
| alert (scan alert) | finding, item to review, warning (noun) | ends both collisions |
| baseline · Record / Replace / Remove baseline · matches / differs from baseline · no baseline · baseline revoked | Trust source / identity, trusted, untrusted, clean, changed (alone) | trust is the user's act |
| Catalog says: … · catalog snapshot · listed | verified plugin, marketplace verified | attribution every time |
| snapshot integrity verified | verified (bare) | it is the file, not the plugin |
| catalog severity | risk, danger level | the rule's default |
| parser-backed · text match only · no parser | confidence high/low | evidence source |
| unavailable · unsupported · not analyzed · nothing observed · not analyzable | unknown, error (alone), 0, blank, n/a | fail-closed states |
| decision · Blocked: … · Allowed by policy | gate, preflight, mutation, interposed | plain outcome words |

Hero titles: `No outstanding alerts` · `<n> alerts to review` / `1 alert to review` · `1 critical alert to review` / `<n>
critical alerts to review` · `Scanning…` · `Ready to scan` · `Scan unavailable` · `omasafe-cli not found` · `omasafe-cli
incompatible` · detail sheet: `<plugin id>`. Meta fragments (` · `-joined, uppercased by the kit): `<n> PLUGINS`, `<n> NEW`,
`SCANNED <relative>`, `LAST SCAN FAILED`, `SHOWING RESULTS FROM <relative>`, `NO EARLIER RESULTS`, `READING INSTALLED STATE`,
`INSTALL OMASAFE-CLI, THEN RESTART THE SHELL`, `<found> FOUND · <min> OR NEWER REQUIRED`, detail: `GIT CHECKOUT · 35 FILES ·
SERVICE, BAR WIDGET`. Detail pill: `cli 0.2.1` / `unavailable`.

Relative time: `just now` (< 60 s), `<n> min ago`, `<n> h ago`, `yesterday`, `<n> days ago`; ISO in a tooltip. Ages: `<n> min
old`, `<n> days old (stale)` at ≥ 30 days.

Loading (one verb): `Loading plugins…` · `Loading analysis…` · `Loading rules…` · `Loading coverage map…` · `Loading catalog…`
· `Loading decision…` · `Checking baseline…` (per row) · `Updating catalog… <n> s` · `Scanning…`. Unavailable: `<Noun>
unavailable: <verbatim CLI reason>.` · `omasafe-cli timed out after 30 seconds.` · `Output was larger than 2 MiB and was
discarded. Run \`omasafe-cli <command>\` in a terminal.` · gate: `Plugins, review items, rules and the trust flow are
unavailable until omasafe-cli 0.2.1 or newer is found on PATH.` Empty: `No alerts outstanding.` · `No plugins installed.` · `No
review items in analyzed files. <n> files were not analyzed.` · `No capabilities observed in analyzed files.` · `No decision
has been recorded. A decision exists only after a gated enable or reviewed update.` · `No override records. This panel cannot
create overrides.` · `No plugin, class, rule or baseline id matches "<text>".` · `Not analyzed. Press a to analyze (about
0.2 s).`

Trust rows (long / short): `No trust baseline recorded` / `no baseline` · `Baseline revoked; record a new one to resume drift
reports` / `baseline revoked` · `Installed source matches the baseline you recorded` / `matches baseline` · `Matches the
baseline; coverage is limited (see COVERAGE)` / `matches · coverage limited` · `Installed source differs from the baseline ·
<n> files changed` / `differs · <n> files` · `Baseline status unavailable: <reason>` / `unavailable`. PLUGINS footer: `A
baseline is the exact source identity you recorded. "Matches" and "differs" compare the installed files against it; neither
is a safety judgment.`

Alert kinds: `source-drift` → `Source differs from baseline` · `missing-plugin` → `Recorded plugin is missing` ·
`lost-coverage` → `Coverage lost` · `bar-replacement` → `Third-party bar replaces the OmaSafe widget` · `provenance-conflict`
→ `Repository conflicts with catalog` · `new-capability` → `New capability class observed` · `finding-regression` → `New
review item: <rule>` · `analyzer-policy-update` → `Analyzer policy changed; re-evaluated` · `analyzer-improvement` → `Results
changed under unchanged source` · `fingerprint-instability` → `Analysis was not deterministic; review required` · other →
`Unsupported alert kind: "<kind>"`. Line 2: `<plugin id> · reported <relative>` + ` · plugin changed` when `post_change`.

Enum labels (`model/Labels.js`; unknown → "unsupported", counted, never dropped): classification `Git-managed` → `Git checkout`,
`built-in` → `Installed without git` (verified: `repository: null`), `backup` → `Backup copy (not scanned)`, other →
`Unsupported classification: "<value>"`; marketplace status `listed` → `Listed in catalog snapshot`, `installed-differs` →
`Listed; installed commit differs from the listing`, `unlisted` → `Not in catalog snapshot`, `conflict` → `Catalog entry
conflicts with the installed repository`, `incomplete` → `Catalog entry incomplete`; `verification_status` → `Catalog says:
verified` / `unverified` / `not stated` (null) / `"<value>"` (verbatim, quoted); `upstream_moved` → `Upstream has moved past
the validated commit`; `marketplace_source` `pinned-fetch` → `pinned fetch, snapshot integrity verified`, `unverified-cache`
→ `cached snapshot, not re-verified`, `local-file` → `local catalog file`, absent → `snapshot unavailable`; stale → `Snapshot
<n> days old (stale)` and the word "verified" is suppressed everywhere in the section; coverage state `analyzed` /
`partially analyzed` / `skipped` / `truncated` / `not analyzable` (`unsupported`) / `nothing observed` (`unreferenced`);
relation `Equivalent check` / `Partially covered` / `Not covered by OmaSafe` / no pointers → `Inventory behaviour only (see
note)`; enforcement `Evaluated` / `Not evaluated`, `Allowed by policy`, `Allowed by override · expires <date>`, `Blocked:
<reason codes with hyphens replaced>`; schedule `not installed`, `Advisory: reports only`, `Hardened: enable and update may
be refused`, `Last run <relative> · exit <n>` / `Last run unavailable`, `Unit metadata inconsistent`; limitation codes per G26,
unknown → verbatim + `unsupported limitation`.

Ineligible verbs (dim, always visible): `Review update needs: catalog status listed or installed-differs · a baseline that
matches · an upstream commit claimed by the catalog.` · `Enable applies only to plugins that are disabled and inactive.` ·
`Remove baseline needs a recorded baseline.` · `Replace baseline appears only when the source differs from the baseline.`

Success lines (rendered; `trustOutput` is rendered, unlike today): `Baseline recorded for <id> at digest <12>.` · `Baseline
replaced for <id> at digest <12>.` · `Baseline removed for <id>.` · `<id> enabled.` · `<id> updated to <commit7> and baseline
recorded.` · `Schedule installed (<policy>).` · `Catalog updated to <commit7>.`

Coverage strings: per-file summary `3 analyzed · 4 partially analyzed · 3 nothing observed · 8 not analyzable` (never a
percentage); header `COVERAGE | 13 LIMITS` or `| NO LIMITS REPORTED`; when `coverage_limitations` is not an array → `Coverage
unavailable` (never "complete"). Baseline V3 header lines: `automated-security-baseline v3 · map 2 · verified at 964dc08` ·
`Relations are coverage claims about rules; no plugin is checked against Baseline V3 here.` Footer: `Not covered by OmaSafe:
cargo-git-unpinned · remote-build · remote-git-execution-unpinned`.

Tooltips (`PanelToolTip`, bodySmall; every one states a fact or a key): `Run scan (r)` · `All plugins (h)` · `Open plugin` /
`Open rule` / `Open review item` · `Copy full digest` · `Analyze (a)` · `Open large view (g)` · severity pill: `Catalog
severity: the rule's default severity class. Not a measure of this plugin.` · confidence pill: `Confidence: evidence quality.
Parser-backed = syntax tree; text match only = lexical; no parser = context or lexical build.` · trust word: `A baseline is the
exact source identity you recorded.` · catalog: `Snapshot fetched <ISO>. The catalog validates listings, not plugin
security.` · strip: `Observed: <class> <n> · <class> <n> …` · CAPABILITIES header: `APIs and tools referenced in source.
Presence, not permission or intent.`

Confirmation template and variants (all via `ConfirmSheet`; Cancel pre-selected; confirm label = verb):

```
<Verb phrase>?                                  title (Style.font.title bold)
Plugin   <id>                                   identity grid (bodySmall, WrapAnywhere): Head / Tree / Digest, 40/40/64 hex or "unavailable"
[Expected commit <40 hex> — claimed by catalog snapshot <commit7>]      review update only (replaces Head)
[Policy  [Advisory] [Hardened] + one-line definition]                  enable · review update · schedule
<Effect sentence>. <Caveat sentence>.           body
[ Cancel ]  [ <Verb> ]
```

| Kind | Title | Effect · caveat | Confirm | Destructive chrome |
|---|---|---|---|---|
| record | Record trust baseline? | OmaSafe will store this identity and report drift from it in future scans. It does not establish that the plugin is safe. Nothing is executed. | Record baseline | no |
| replace | Replace trust baseline? | The previous baseline is superseded by this identity; drift is measured from it. It does not establish that the plugin is safe. Nothing is executed. | Replace baseline | no |
| remove | Remove trust baseline? | Future scans report this plugin as having no baseline. The plugin keeps running. Nothing is executed. | Remove baseline | yes |
| enable | Enable plugin? | The CLI checks this exact source before enabling it and may refuse under hardened policy. A decision is recorded either way. | Enable | yes |
| review update | Update at the catalog-claimed commit? | The CLI updates <id> only if upstream still matches the commit the catalog snapshot claims, re-analyzes it, and records the result as the baseline. The commit is a catalog claim; the CLI verifies it before anything changes. | Update | yes |
| schedule | Install scheduled scan? | Installs or replaces omasafe-scan.timer / omasafe-scan.service with <policy> policy. Scheduled scans report only; hardened adds analysis and does not disable a running plugin. No plugin identity is involved. | Install | hardened only |

## 8 Final keyboard map (PanelKeyCatcher grammar is fixed: Esc, Tab/Shift-Tab, arrows + hjkl, Return/Enter, Space, x, textKey)

| Key | Signal | No sheet, finder unfocused | Sheet open (`blocked`) | Finder focused (`blocked`) |
|---|---|---|---|---|
| Esc | `closeRequested` | close panel | `canceled()`; panel stays open | clear text, hide finder, refocus catcher |
| Tab / Shift-Tab | `tabRequested` | `bar.switchPanelFrom` (host popout switching) | toggle Cancel/confirm (kit `handleKey`) | field-internal |
| ↓ j / ↑ k | `moveRequested(0,±1)` | `moveCursor(±1)` across sections, scroll into view | nothing | move result cursor |
| → l / ← h | `moveRequested(±1,0)` | horizontal sections (`ButtonGroup`s, action rows, graph columns, matrix cells); in a vertical section of a sheet `h` = back, `l` on a plugin row = open | toggle Cancel/confirm; move inside the policy `ButtonGroup` when it has the cursor | caret |
| Enter / Space | `activateRequested` (Enter also `returnRequested`) | `activateCursor()`: open, expand, press, pin | fires the selected button only (Cancel by default); Space does nothing | Enter opens the result |
| x | `deleteRequested` | unpin (Flow) / collapse expanded row; never mutates | nothing | field-internal |
| 1 2 3 | `textKey` | views (`2` from a detail sheet opens Flow at Z1 for that plugin) | nothing | typed |
| r | `textKey` | `hostWidget.runScan()` only when `cliVerified && !checking && !navigationLocked` | nothing | typed |
| a / A | `textKey` | analyze cursor plugin / all live plugins sequentially | nothing | typed |
| / | `textKey` | show and focus the finder | nothing | typed |
| - | `textKey` | pop one depth level | nothing | typed |
| m · c · b · t · g · ? | `textKey` | Flow lens toggle · all 17 classes (Matrix) · backups toggle · trace pinned path · open large view (Phase 5, when available) · key legend | nothing | typed |

Cursor model: dev-gallery template (`GalleryPanel.qml:101–262`): root owns `cursorActive` (false on open), `focusSection`,
`selectedIndex`, per-view `visibleSections`, `sectionCount`, `sectionIsHorizontal`, `moveCursor`, `moveCursorH`,
`activateCursor`, `clampCursor` (after every model change), `ensureCursorVisible` (`Flickable.contentY` /
`ListView.positionViewAtIndex(i, ListView.Contain)`). Hover sets the same cursor through `PointerMoveGate.moved(item, mouse)`;
rows never read `containsMouse`. Only the catcher holds focus; no `Button` is `focusable`. Sections: Overview `hero → views →
alerts → plugins → backups-toggle → sources`; detail `hero → views → trust-actions(H) → changed → classes → review → edges →
coverage → claim-actions(H) → enforcement → provenance`; Flow `hero → views → lens(H) → col-0..3 (h/l cross) → inspector-actions(H)`;
Rules `hero → views → rules → baseline`; finder `results`; sheet `policy(H, optional) → buttons(H)`.

No-bypass invariants (Phase 0/1 acceptance): (1) `keyCatcher.blocked = sheet.opened || finder.activeFocus`; (2) the sheet
has `activeFocus` while open and `Keys.onPressed: event.accepted = handleKey(event)`; (3) `openSheet(kind)` sets
`pendingAction` (single enum, a second request while open is ignored) and `swallowNextActivate`, so the held Enter that
opened it cannot confirm; (4) `selectedIndex = 0` on every open; (5) `navigationLocked` disables every action `Button`, the
view/lens `ButtonGroup`s and the finder, and the `Flickable` is `interactive: false`; (6) scrim `MouseArea` swallows clicks and
wheel; (7) `close()` and `onOpenedChanged(false)` reset `pendingAction`; (8) selection change cancels a pending sheet
(existing 808–816) and `targetStillExact` re-validation (1219, 1241) stays; (9) `busy` while `operationRunning` disables both
buttons and relabels confirm `Working…`. Copy actions use `Util.execArgv(["wl-copy", "--", value])` (first-party precedent:
tailscale/Service.qml:109, network/Panel.qml:450); this adds one documented detached-process-execution occurrence to OmaSafe's
own analysis.

## 9 Final component inventory

| File | Composes | Responsibility |
|---|---|---|
| `BarWidget.qml` (modified) | `BarIconButton`, `OmaSafeShield` | resolver, version gate, bounded scan, timer kept; `warningColor` and `visible: !vertical` (112) removed |
| `OmaSafeShield.qml` (new; `OmaSafeStatusIcon.qml` deleted) | `OpticalGlyph` `󰒃`, caption count `Text`, `BorderSurface` urgent badge, `RotationAnimation` | bar icon and hero icon (TailscaleIcon pattern) |
| `Panel.qml` (≈ 2 000 lines) | `Panel` › `KeyboardPanel` › `PanelKeyCatcher`; root state, cursor model, `pendingAction`, `vm`, view `Loader`, `ConfirmSheet`, all 15 `Process` collectors verbatim | the popup |
| `components/SectionHeaderRow.qml` | `PanelSeparator` + `Row { PanelSectionHeader; Text value }` | every section header with right value |
| `components/NoticeRow.qml` | `CursorSurface` (no cursor) + `Text` (tailscale 511–529 idiom) | reasons loading · none · unavailable · unsupported · stale · lexical-only |
| `components/{AlertRow,PluginRow,ClassRow,EvidenceRow,RuleRow,RelationRow,EdgeRow,SourceRow}.qml` | `CursorSurface`, glyph column, two `Text` lines, ≤ 2 `PanelActionButton`s; expanding rows open a `Column` | list rows for every section |
| `components/CapabilityStrip.qml` | one `Text` + `PanelToolTip` | 17-glyph fixed-order presence strip |
| `components/InfoGrid.qml` | `GridLayout { columns: 2 }`, optional copy `PanelActionButton` | key:value blocks (identity, provenance, decision) |
| `components/ActionRow.qml` | `Row` of `Button { bordered: true; hasCursor }` + dim condition `Text` | mutating actions with ineligible-verb copy |
| `components/Breadcrumb.qml` | `Text` (`ElideMiddle` segments) + back `PanelActionButton` | depth path |
| `components/FinderField.qml` | kit `TextField`, `Keys.onPressed` for Up/Down/Enter/Esc | `/` finder input; owns `blocked` |
| `components/InspectorStrip.qml` | `PanelSeparator`, 3–4 `Text`, one `Button` | cursor facts for Graph / Matrix / Trace |
| `components/ConfirmSheet.qml` | scrim `Rectangle` + `MouseArea`, `BorderSurface` card, `Text`, `InfoGrid`, optional `ButtonGroup`, two kit-styled buttons (ConfirmDialog.qml:96–130 chrome) | §7 template; kit `handleKey` contract, Cancel first |
| `views/{OverviewView,PluginDetailView,FlowView,RulesView,FinderResultsView}.qml` | the sections above; Rules uses `ListView` + `positionViewAtIndex` | the three views, the detail sheet, finder results |
| `graph/TrustFlow.qml` | four `Repeater` columns of `FlowNode` + `EdgeLayer` + rail rows | Graph lens (Z0/Z1) |
| `graph/FlowNode.qml` | `CursorSurface`, `OpticalGlyph`, label/count `Text`, `MouseArea` + `PointerMoveGate` | node row |
| `graph/EdgeLayer.qml` | `Shape { CurveRenderer }` + 8 static `ShapePath { PathSvg }` | edges |
| `graph/MatrixGrid.qml` | two `Repeater`s of `CursorSurface` + `Text` cells, header glyph `Text`s, horizontal `Flickable` | Matrix lens |
| `graph/TraceChain.qml` | chain `Text` + `ListView` evidence rows + `EdgeRow`s + limitation rows | Z2 |
| `graph/FlowLayout.js` | pure functions | node sets, ordering, barycentre sweep, geometry, bucketed path strings |
| `model/{ViewModel,Labels,Glyphs,Time}.js` | pure functions | normaliser (strips `file_digests`), finder index, closed-enum labels + limitation parser, glyph table + ASCII fallback, relative time |
| Phase 5 only: `TrustFlowWindow.qml`; `manifest.json` `kinds: ["bar-widget","panel"]`, `entryPoints.panel` | `PanelWindow` (Overlay), `BorderSurface` card, `PanelKeyCatcher`, `PanelHero`, `ButtonGroup`, `TrustFlow`, `PluginDetailView`, `ConfirmSheet` | large view with all four layers open |

## 10 Final roadmap

| Phase | Scope | Effort | Risk |
|---|---|---|---|
| 0 Correctness, no visual change | delete 1310–2258; `Text.PlainText` on every `Text`; scrim `MouseArea`; `pendingAction` + `swallowNextActivate`; `close()`/`onOpenedChanged` reset; Esc cancels while confirming; `r` gated; remove `setActive(1)` (855) and post-trust re-selection; `findingKey` expansion; dedupe capabilities by class (2923); "complete" → "unavailable" (3376, 1737); `rules explain … --format json` (4830); render `trustOutput`; enforcement refresh in place (4681). Checklist = C's fate table. | S (1–2 d) | low |
| 1 Kit, tokens, cursor, sheet | `OmaSafeShield`, `PanelHero`, `ButtonGroup`, `SectionHeaderRow`, `NoticeRow`, `CursorSurface` rows, `InfoGrid`, `ConfirmSheet` with blocked-mode wiring, root colour/font bindings, `#e5a50a` gone, type roles, spacing, cursor model, key map, `Labels.js`, `Glyphs.js` (+ font check), `Time.js`; content still the four tabs' | M (3–4 d) | medium (keyboard regressions) |
| 2 Information architecture | `ViewModel.js`; Overview (ALERTS · PLUGINS + strip + Toggle · SOURCES); `PluginDetailView` (nine sections incl. FILES AND EDGES, grouped COVERAGE); `RulesView` with rule sheet and Baseline V3 table; finder + breadcrumb depth stack; full copy system; ineligible verbs; success lines | M (4–5 d) | medium (parity with four tabs) |
| 3 Trust Flow v1 (in-panel) | `graph/*`, `FlowView`, focus pair, Z0/Z1/Z2, Matrix lens, `InspectorStrip`, a/A queue, dashed buckets, legend, states; smoke test of `CurveRenderer` first, text fallback if it fails | L (5–6 d) | medium-high (rendering unknowns) |
| 4 Polish and hardening | tooltips, `?` legend, light-theme contrast pass (`Style.normalBorderAlpha` if edges are faint), `PointerMoveGate` on reflow, performance audit (binding counts, RSS over 1 h with periodic scans), README screenshots, docs | S (2–3 d) | low |
| 5 Optional large view | `TrustFlowWindow.qml`, manifest `panel` kind, summon + degradation ladder, payload without warm caches, identity re-fetched, README IPC note; go/no-go after Phase 3 acceptance and the owner's sign-off on the route change | L (5–8 d) | high (new surface, IPC alias) |

Never changes in any phase: CLI argv shapes, 2 MiB caps, 15/30/60 s timeouts, SIGTERM→SIGKILL, `requestId`/generation guards,
schema checks in every `apply*`, `enforcementEnum`/`coverageRelation`/`overrideStatus` fail-closed gates, `cliCommand`
`/usr/bin/false` gate (164–167), confirmation identity and `targetStillExact`, marketplace attribution, disclaimer pass-through.

## 11 Conflict resolutions

| # | Conflict | Resolution |
|---|---|---|
| R1 | Hero title: status sentence (A) vs "OmaSafe" (B, C) | Status sentence. The bar icon and gallery already say OmaSafe; the persona's first question wins. |
| R2 | Top-level structure: 3 views + depth (A) vs tabless popup + window (B) vs 5 views (C) | 3 views + per-view depth stack + breadcrumb. Catalog and Policy are SOURCES rows and detail-sheet sections. |
| R3 | Graph home: popup (A, C) vs window (B) | Popup is primary and complete; window optional Phase 5 under B's contract. |
| R4 | Layers: PLUGINS·CAPABILITIES·EVIDENCE·RULES (A) vs PLUGINS·CLASSES·RULES·BASELINE V3 (B) | B's four layers; evidence becomes the Trace zoom. |
| R5 | Severity: glyph-opacity steps (A) vs urgent-alpha pills (B) vs text shapes (C) | Word + five distinct verified Nerd glyphs; no opacity ramp, no urgent alphas; urgent only for critical. |
| R6 | Confidence: filled/hollow ring (A) vs pill (B) vs word (C) | Word only, plus dashed edges in the graph. Hollow glyph means "not analyzed / unavailable" on nodes and nothing else. |
| R7 | `󰄬` for matches baseline | Never. Trust state is a word; only `changed` gets `󰀦`. |
| R8 | Strip: count chips sorted by count (A) vs 17 Rectangles (B) vs ▁▃▅▇ bars (C) | One `Text`, 17 fixed-order class glyphs, presence only; counts live in the Matrix, the detail sheet and the tooltip. |
| R9 | Matrix: absent (A) vs lens (B) vs primary view (C) | Lens inside Flow (`m`), observed classes by default, `c` for all 17. |
| R10 | Auto-analyze on Flow open (A) vs a/A only (B, C) | a/A only. |
| R11 | Sheet key wiring: "route signals" (A, B) vs `blocked` + `activeFocus` + `handleKey(event)` (C) | C's wiring; it is the only one that matches `PanelKeyCatcher.blocked` semantics. |
| R12 | Identity presentation: three authority sections (A) vs one IDENTITY grid (C) | Three sections; no combined block. |
| R13 | Coverage map attribution: 65b6385 (A, C) vs 964dc08 (B) | `verified_at_commit` 964dc08 (verified in `rules-coverage.json`). |
| R14 | Graph fallback: Canvas (A, B) vs text (C) | Text (Matrix + Trace). No first-party `Canvas` element exists; the qml judge's wifiqr:279 counter-example is a `Rectangle`. |
| R15 | Focus-pair column width animation 160 ms (A) | Removed; columns snap so `PathSvg` edges stay aligned. Motion set is {60, 120, 140, 900} ms. |
| R16 | Alerts noun: "items to review" (A) vs "alerts" (B, C) | "alerts" for scan alerts, "review items" for findings; hero `3 alerts to review`, header `ALERTS`. |
| R17 | Backups: SOURCES row (A) vs Toggle (B) vs `b` key (C) | Kit `Toggle` row under PLUGINS plus `b`; hidden count printed in meta when active. |
| R18 | Density floor: conditional caption→bodySmall promotion (C) | Replaced by the fixed data-floor role assignment (G27); no conditional token switching. |
| R19 | Letter accelerators for mutations (C `t u e U`) | None; mutations are reached by cursor + Enter on their `Button`. |
| R20 | Catalog refresh confirmation | Unconfirmed (all drafts agree): network only, 60 s, inline progress. |
| R21 | Esc at depth (C open question) | Esc closes the panel (kit grammar); depth pops with `h` / `-` / back button. |
| R22 | `built-in` classification label | `Installed without git` (verified `repository: null`); never "built-in" in UI copy. |
| R23 | Hero trailing controls: one Button (A) vs two PanelActionButtons (B) | One scan `Button { iconSpinning }`; the large-view launcher lives in the Flow header slot. |
| R24 | Copy action mechanism | `Util.execArgv(["wl-copy", "--", value])` (first-party idiom), documented as a self-reported occurrence. |

## 12 Consistency contract (binding for every document)

- Views: **Overview**, **Flow**, **Rules** (keys 1/2/3). Lenses (Flow only): **Graph**, **Matrix**. Zoom levels: **Z0 Atlas**,
  **Z1 Plugin**, **Z2 Trace**. Sheets: **plugin detail sheet**, **rule sheet**, **baseline sheet** (inline expansions),
  **ConfirmSheet**. The graph's product name is **Trust Flow**; the view chip reads `Flow`.
- Section header strings (exact, with right value after `|`): `ALERTS | <n>`, `PLUGINS | <n> · <k> ANALYZED`, `SOURCES`,
  `TRUST BASELINE | LOCAL`, `WHAT CHANGED | <n> FILES`, `CAPABILITIES OBSERVED | <n> · <k> CLASSES`, `REVIEW ITEMS | <n> ·
  <summary>`, `FILES AND EDGES | <n> EDGES`, `COVERAGE | <n> LIMITS`, `MARKETPLACE CLAIM | CATALOG <commit7> · <age>[ · STALE]`,
  `ENFORCEMENT | POLICY`, `PROVENANCE`, `TRUST FLOW · ALL PLUGINS | <k> OF <n> ANALYZED`, `TRUST FLOW · <id>`, `TRACE`,
  `EVIDENCE | <n> ROWS`, `FILE EDGES | <n>`, `COVERAGE LIMITS ON THIS PATH | <n>`, `RULE CATALOG | V7 · 45 RULES`,
  `BASELINE V3 COVERAGE | 12 PARTIAL · 3 NOT COVERED`, `LOCAL HITS | <k> PLUGINS · <n>`, `BASELINE V3 | <n> ROWS · MAP 2`,
  finder groups `PLUGINS · CAPABILITIES · RULES · BASELINE V3`.
- Availability states (NoticeRow `reason`): `loading`, `none`, `unavailable`, `unsupported`, `stale`, `lexical-only`; per-plugin
  analysis states: `not analyzed`, `analyzing`, `analyzed`, `unavailable`. Trust states (CLI): `untrusted` (reason never /
  revoked), `unchanged`, `partial`, `changed`, plus panel `unavailable`. Never "baselined-unchanged".
- Root colour names: `fg`, `urgent`, `dimHeader`, `dim`, `faint`, `hoverFill`, `selectedFill`. No other colour expressions; no
  hex literals; no `Color.muted`; no warning colour of any kind.
- Type tokens by role exactly as §6; spacing only `Style.space(n)` with n ∈ {1, 2, 6, 8, 10, 12, 18, 20, 22, 24, 28, 32, 34,
  88, 360, 370, 400, 420, 560} or `Style.spacing.*`; motion only {60, 120, 140, 900} ms.
- Glyph names and codepoints exactly as §6; class glyphs from `model/Glyphs.js`; wireframes may use ASCII stand-ins
  (`(S)`, `!`, `o`, `PX TM WM FS`) but must say so once.
- Keys exactly as §8; `x` never mutates; no letter opens a mutation sheet.
- Files exactly as §9 (`components/`, `views/`, `graph/`, `model/`; `OmaSafeShield.qml`; `TrustFlowWindow.qml` Phase 5 only).
- Real-data numbers used in every example: 15 inventory rows = 8 live (6 Git-managed, 2 installed without git) + 7 backups; 4
  analyzed (btop 27 occurrences / 5 review items, dropdown-terminal 10 / 2, omasafe 54 / 1, sandman 29 / 2; all 10 review items
  `low`, all `oma.qml.dynamic-reference`); 3 outstanding alerts, all `provenance-conflict`, `highest_severity: warning`;
  marketplace 7 unlisted · 3 listed · 3 conflict · 2 installed-differs; snapshot 65b6385 · `pinned-fetch` · 935 s old;
  catalog v7 · 45 rules · 17 classes; coverage map 15 rows = 12 partial-overlap + 3 not-covered over 12 externalIds,
  `verified_at_commit` 964dc08, map 2; limitations sandman 13 · omasafe 2 · btop 3 · dropdown-terminal 0; inventory-level
  `coverage.limitations` = []; schedule not installed; overrides none; every `decision: null`; parser tree-sitter-qmljs 0.3.1.
- Line references: `Panel.qml:<n>` unqualified, `BW:<n>`, `Icon:<n>`, kit as `Ui/<File>.qml:<n>`, `Style.qml:<n>`,
  `shell.qml:<n>`; verified anchors: 153, 164–167, 808–816, 855, 947, 1099, 1161, 1169, 1183, 1219, 1241, 1310–2258, 2260–2281,
  2277, 2283–2581, 2341, 2394, 2421, 2425, 2437, 2453, 2570, 2584–3790, 2923, 3376, 3570, 3815–5173, 4681, 4830; BW:112, BW:116;
  Icon:9; shell.qml:426–438, 456–494; network/Panel.qml:468; Bar.qml:25; wifiqr/Panel.qml:51–92; GalleryPanel.qml:101–262;
  tailscale/Panel.qml:500–529, 767; BorderOverlay.qml:51; ConfirmDialog.qml:11, 23–38, 96–130.
- Facts that override the drafts and judges: no first-party `Canvas` element exists; `PanelActionButton` has no `iconSpinning`;
  `Style.font.heading` exists (16 at base 12) but is not used; `PanelKeyCatcher` emits `returnRequested` then
  `activateRequested` on Enter and only `activateRequested` on Space; `ConfirmDialog.handleKey` returns false for Space;
  `Toggle { label; description; checked; hasCursor }` exists; `plugins status` has no `recorded_at`; the shield glyph is
  U+F0483 (tailscale), not U+F0498.
- Vocabulary: §7 table is closed. "Trusted" appears only in the definition footer and confirm titles ("trust baseline").

## 13 Document plan with adjustments

| File | Must contain (beyond the plan) | Lines |
|---|---|---|
| `docs/design/README.md` | Ask quoted from `brief.md`; one-paragraph thesis (§0 wording); one-paragraph decision naming A + the graft families; document table; reading order README → 02 → 03 → 04 → 05 → 01; status "proposal, unimplemented, runtime-unverified"; versions line from this record. | 80–160 |
| `docs/design/01-research-and-audit.md` | Current IA map; audit findings table with the verified line anchors; kit-gap table; token-misuse list (`#e5a50a` ×3, 83 `Util.alpha`, 110 `caption`, 68 `AutoText`); condensed 14 ethos principles; the 12 external patterns actually adopted (Android Privacy Dashboard, Apple privacy labels, VS Code Workspace Trust, GitHub SARIF two axes, Semgrep confidence/impact, Sigstore provenance wording, Firefox explicit empty state, Little Snitch linked selection, Shneiderman mantra, Tufte small multiples, Bertin size-only, Ghoniem matrix-vs-node-link) with URLs; Mermaid erDiagram + condensed field dictionary + real cardinalities (§12 numbers); feasibility verdict: Shape+PathSvg chosen, Canvas/force/Sankey/sunburst rejected, text fallback; surface options S1/S2/S3 with the `isBarWidgetPanelPlugin` route flip and the two CLI asks. Must state the corrected Canvas fact and the `recorded_at` absence. | 500–900 |
| `docs/design/02-design-principles.md` | 12 principles (statement · why · do/don't · review test) merging ethos P1–P14 with GR1–GR6; visual system tables from §6 verbatim (type, spacing, colour block, encodings, radius/border, motion, glyph table with codepoints and ASCII fallback, density, text-scaling stops 9/12/16/20); copy system from §7 (vocabulary, every status string, tooltips, confirmation template and the six variants); the review checklist with a blocker block (no hex, no pixel literals, kit only, five-theme screenshots, urgent ≤ 1, no `󰄬`, no percentage coverage, `–` never 0). | 400–700 |
| `docs/design/03-ui-overhaul-proposal.md` | Bar states table; panel shell; 52-column wireframes with component/token callouts for: Overview attention / quiet / unavailable / loading / error, plugin detail sheet (top, review item expanded, FILES AND EDGES + COVERAGE grouped, MARKETPLACE CLAIM + ENFORCEMENT + PROVENANCE), Rules (catalog with rule sheet, Baseline V3 table with 964dc08), SOURCES expanded, finder results, breadcrumb at depth, Toggle backups row, NoticeRow catalogue, all six ConfirmSheet variants (two drawn in full), states matrix (view × loading/none/unavailable/unsupported/stale/lexical-only/not-analyzed); Mermaid flows: open → understand → act; alert → trace → decide; record/replace/remove baseline; reviewed update; keyboard table from §8; cursor sections; accessibility (colour-blind, contrast, scaling, screen-reader limitation). Flow view appears only as its frame, entry (`2`, plugin row `l`, alert row) and exit (`h`, `1`); the graph body is specified in 04. | 700–1200 |
| `docs/design/04-trust-graph-spec.md` | Purpose and the four user questions; four-layer model with evidence as Z2 and adornments (alert bold, block glyph, trust word, catalog status in the inspector only); Matrix lens; Baseline coverage table; JS view-model shapes with the worked example for `lgse.sandman` and `io.github.tuthan.omasafe` from `cli-samples/` (29 / 54 occurrences, classes, 2 / 1 review items, 13 / 2 limitations, 5 / 1 edges, `parser` object, catalog listed-verified / conflict); `FlowLayout.js` pseudocode (node sets, order, barycentre sweep, focus-pair geometry, path strings, buckets) with sizing math for 420 × 480 at base 9/12/20 and for the optional 1080-unit window; encodings table with the explicit "nothing encodes a verdict" rule; interactions and keyboard from §5/§8 incl. connected-node clamping and `swallowNextActivate`; disclosure ladder Z0 → Z1 → Z2 → review item → rule sheet → baseline row; states table; wireframes for Z0, Z1, Z2, Matrix, coverage table (five); QML architecture with 100–200 lines of sketch (`EdgeLayer` with 8 static `ShapePath { strokeStyle: ShapePath.DashLine; dashPattern: [4,4] }` buckets, `FlowNode`, `TrustFlow` column `Repeater`, `InspectorStrip`) using only APIs verified here; text fallback; performance budget and caps; acceptance checklist (layout counts on the four samples: 5 class nodes, 6 rule nodes, 12 baseline ids; hot edge survives every h/l; `a` fills one node without relayout; no `Timer`; dashed fixture; `flexoki-light` and `catppuccin-latte` edge legibility). | 600–1000 |
| `docs/design/05-implementation-roadmap.md` | Phases 0–5 from §10 with goals, exact files, components, CLI calls per phase, risks, mitigations, acceptance checks (reuse `docs/cli-v0.2-plan.md:229–246` and extend with §8's nine invariants, `grep -nE '#[0-9a-fA-F]{6}'` empty, no `font.pixelSize` literal, `–` never 0, COVERAGE for sandman/omasafe without expansion, catalog and trust never in one row), S/M/L; C's Panel.qml range → fate table verbatim; component inventory from §9; manifest change list conditional on Phase 5 (`kinds`, `entryPoints.panel`, README IPC note, `keepLoaded` stays false); validation: `omarchy plugin validate .`, `qmllint -I /usr/share/omarchy/shell -I /usr/lib/qt6/qml`, manual matrix (`white`, `catppuccin-latte`, `retro-82`, `oxocarbon`, `ame-quattro` × base 9/12/16/20), `QSG_RENDER_TIMING=1` for the graph, RSS after 1 h; rollout note (screenshots to `media/`, README sections, CHANGELOG line, CLI asks filed as issues). Must list what never changes (§10 footer). | 400–700 |

Cross-document rules: every document uses §12's names, numbers and line anchors; ASCII wireframes are 52 columns for the
popup and ~104 for the optional window; Mermaid only for flows and the ER diagram; no HTML; no "consult a lawyer"-style
disclaimers; the one product disclaimer sentence appears once per document at most, quoted exactly.

## 14 Errata — points superseded by the deliverables

The body above (§0–§13) is the record as written on 2026-09-02, unchanged so that every `G<n>` / `R<n>` citation and every
line reference made by 01–05 still resolves. Where a deliverable was verified against source after this record was closed
and found the record wrong or incomplete, the deliverable is binding and the correction is listed here. Nothing below
reopens a decision; each row narrows or corrects one.

| Record (line) | Superseded text | Binding text | Where |
|---|---|---|---|
| G9 (61), §6 (222–231), §12 (476) | glyph table "present … re-checked with fontTools" (presence only); backup `󰁓` F0053; replaces-bar-context `󱂢` F10A2; severity `low` `󰝦` | verification is by codepoint **and** glyph name (`cmap[0xF0483] == 'md-security'` …); outline shield `󰒙` U+F0499 `md-shield_outline` added (drawn whenever no scan result exists); backup `󱈎` U+F120E `md-archive_outline`; replaces-bar-context `󱔓` U+F1513 `md-dock_top`; critical `󰀩` U+F0029 `md-alert_octagon`; `low` is the word alone and `󰝦` means only a hollow Flow node; in-flight ASCII fallback `/`, `~` for `≈` only | 02 §2.4, §2.7; 03 §2; 05 §4, §9 |
| §6 (183–185) | dim ladder `Qt.darker(fg, 1.4 / 1.5 / 2.0)` | `dimStep(k)`: an opaque mix of `fg` toward `Color.background` (0.25 / 0.33 / 0.55); the seven root colour names are unchanged | 02 §2.3 |
| §3 (92, 103), §6 (164), §12 (463–465) | hero detail pill `cli 0.2.1`; `TRUST BASELINE \| LOCAL`; `ENFORCEMENT \| POLICY`; `FILES AND EDGES \| <n> EDGES` | detail pill only when it reads `unavailable` (the CLI version is a SOURCES row); `TRUST BASELINE` with no right value; `ENFORCEMENT \| EVALUATED / NOT EVALUATED / NO DECISION` (a recorded decision carries no advisory/hardened mode); file references are a collapsed sub-row of `COVERAGE`, the `FILES AND EDGES` header is retired | 02 §2.1, P2; 03 §3, §5.1, §5.3, §5.4 |
| G12 (64), §9 | backups behind a kit `Toggle { label }` row | a `CursorSurface` row holding the label and a kit `ToggleSwitch { interactive: false }` (`Toggle`'s 54 px floor, `space(240)` width, `activeFocusOnTab` and 100 ms animation are rejected) | 03 §4.1; 05 §5 |
| G13 (65), §5 Surface (146) | `bar.shell.summon(manifest.id, …)` from the popup | `bar.shell.summon(root.moduleName, …)` — `manifest` is injected only into panel/overlay/menu loader items; `manifest.id` is used solely inside `TrustFlowWindow.qml` | 04 §6.1; 05 §8 |
| §5 Popup layout (147), §6 spacing (175–176), §12 (474–475) | `openW ≈ 146` with a 24-unit gutter; graph height cap `space(360)`; a closed spacing set | `openW` = 118 at base 12 in the content holder; edge lane `pairGutter = space(72)`, `railGutter = space(12)`; body height derived from what the popup has left (10 rows at base 12); the spacing set is preferred, not closed | 02 §2.2; 04 §4.1 step 4, §4.3 |
| §5 Interactions (152) | Enter on a pinned capability → "Z1 filtered" | Enter on a pinned capability at Z0 → Matrix lens, cursor on that column (there is no single-plugin scope to land in) | 04 §6.1, §13 |
| §7 Ages (264–265) | `<n> days old (stale)` at ≥ 30 days | `(stale)` when and only when `result.marketplace_stale` is true; `Time.js` formats ages and decides nothing | 02 §3.3 |
| §7 Empty (274–275) | `Not analyzed. Press a to analyze (about 0.2 s).` | `Not analyzed. Press a or Analyze.` (no timing promise) | 02 §3.3 |
| §7 Enum labels (293–294, 302–304) | `installed-differs` → `Listed; installed commit differs from the listing`; schedule `Advisory: reports only` / `Hardened: enable and update may be refused` | `Listed; installed commit is not the listed commit`; `installed_matches_listing` → `Installed commit is / is not the listed commit` — `matches` / `differs` never appear in a marketplace label; schedule `Advisory: daily drift scan, reports only` / `Hardened: daily drift scan with analysis, reports only` (a scheduled scan refuses nothing); `cloned/local`, `unscannable` and a `First-party: yes / no / not stated` fact line added | 02 §3.4 |
| §7 Ineligible verbs (307–309) | `Review update needs: catalog status listed or installed-differs …`; `Replace baseline appears only when the source differs from the baseline.` | `… catalog status listed (at or off the listed commit) …` (no raw enum, no `differs` beside `listed`); the Replace string has no surface — Record and Replace are one verb and only the state-matching one is drawn | 02 §3.5; 03 §5.1, §5.4 |
| §7 Success lines (311–313) | `<id> enabled.`; `<id> updated to <commit7> and baseline recorded.` on exit 0 | `<id> enabled (<EnableResult.policy>).` only when `result.enabled === true`; the update line only when stdout contains `Reviewed update complete`; `Already at pinned commit` renders `Already at the claimed commit; nothing was updated.`; exit 0 alone never renders a positive line; after a trust the row reads `checking…` until `plugins status` supplies the state | 02 §3.3; 03 §5.5, §12.4 |
| §7 Coverage strings (317) | Baseline V3 header `… verified at 964dc08` | `… checked against marketplace commit 964dc08` (never the bare word "verified") | 02 §3.5; 03 §7.2 |
| §8 invariant (3) (376–378), G7 (59) | `swallowNextActivate` stops the held Enter | the held key is stopped in `ConfirmSheet.Keys.onPressed` (auto-repeat Return/Enter/Space dropped; non-repeat Return/Enter ignored for 300 ms after open); `swallowNextActivate` is only the same-event-loop-turn double-delivery guard | 03 §10 invariant 2; 05 §4 |
| §8 (382–384), R24 | `Util.execArgv` copy action described as an argv-only detached process | `Util.execArgv` runs `bash -lc 'exec "$@"' bash wl-copy -- <value>`: a login shell is spawned and the value is a positional parameter, never re-tokenised; same `detached-process-execution` class as the first-party idiom | 05 §9 |
| §9 (391) | `OmaSafeShield` carries a "caption count `Text`" | the count is a sibling `bodySmall` `Text` in the `BarWidget.qml` `Row` (a count is data); `filled: hasScanResult`, outline for every `unavailable` | 03 §2; 05 §9 |
| §12 anchors (488–489) | `hostWidget` `Connections` range implied by 3815 | `3784–3813` (`onCliVerifiedChanged` 3788, `onCliVersionChanged` 3796, `onAlertsChanged` 3808) | 01 §2.6; 05 §2 |
| §12 Section header strings (462–468), G17 (69) | `FILES AND EDGES \| <n> EDGES` in the detail sheet | retired (see the third row above); `FILE EDGES \| <n>` remains the Z2 Trace section | 03 §5.3; 04 §9.4 |
| GR6 / G7 / §8 confirmation assumptions | a visible plugin identity plus QML `targetStillExact` is sufficient for every mutation; current mutation argv stays fixed | authorization is action-specific and enforced atomically by the CLI: Record/Replace and Enable bind required current digest plus head/tree when present; Remove binds the recorded baseline digest; Review update binds the claimed target commit; Schedule binds unit names and exact effective argv/policy. QML checks are feedback only. CLI 0.2.1 lacks safe Enable/Remove contracts, so those controls remain unavailable and `cliVersionMin` must rise to the first release implementing them | README GR6; 01 §2.4; 02 P5, §3.7; 03 §5.5, §10; 05 §1, §3, §10 |
| §5/§6 graph confidence | `parser == null` anywhere in scope makes every edge dashed | lexical confidence is per evidence edge: dashed only when no parser-backed fact supports that edge; mixed and unrelated edges stay solid, with mixed support counts in the inspector. Rule→Baseline dashes continue to mean `partial-overlap` | 04 §2.2, §3.2, §5, §8, §9.8 |
| §5 graph coordinates | no single coordinate-space rule for node rows and edge paths | nodes and paths share the TrustFlow-root coordinate space; `rowCenter()` includes `headerH` once and `EdgeLayer` has no top margin | 04 §4.1, §10.2, §12 |
| §5 graph stability | node arrays change only with membership and barycentre may run after any analysis | `membershipKey` tracks node identity, `contentKey` tracks counts/state/adornments so same-membership data changes notify QML; only a new `orderEpoch` runs key sort and barycentre, while same-epoch arrivals preserve previous order and append new keys | 04 §3.2, §4, §10–§12; 05 §6 |
| §6 / §12 colour contract; §13 blocker | `Color.urgent` appears at most once per screen | urgent is a semantic allowlist, not a global quota: critical/error alerts, enforcement blocks, CLI failures, the active destructive confirm, and the bar badge. Multiple independent critical/block rows retain emphasis; decorative or ordinal severity uses remain forbidden | README thesis; 02 P9, §4; 03 §14; 04 §5, §12; 05 §4, §11 |
| §7 confirmation variants | hardened scheduled scan uses destructive chrome | schedule installation/replacement is neutral chrome for both policies; hardened adds analysis but remains report-only. The sheet shows the exact effective scan argv | 02 §3.7; 03 §10 |
| §9 model split | pure `Labels.js` calls enum gates left in `Panel.qml`; `Time.js` owns the stale threshold | `Labels.js` owns all closed-enum gates and QML wrappers temporarily delegate to it; pure JS never calls QML. `Time.js` formats relative time/ages and owns no policy threshold | 05 §2, §9 |
| §13 accessibility deliverable | plain `Text.PlainText` is enough for a future screen-reader path | no screen-reader accessibility is claimed until a Quickshell bridge is verified and roles, names, focus exposure and live announcements pass an assistive-technology test | 03 §14; 05 §13 |
| §8 keyboard map (360) | the `r` gate is `cliVerified && !checking && !navigationLocked` in every phase | `checking` is a Phase 1 declaration (`BarWidget` and panel root); Phase 0 gates on `root.statusLevel !== "checking"`, because Phase 0 does not touch `BarWidget.qml` and `hostWidget` is `property var`, so a premature `!hostWidget.checking` reads `undefined` and the guard silently passes | 01 A4; 03 §10 invariant 7; 05 §3 item 0.6 |
| §8 confirmation reachability (489) | buttons under the scrim are "gated only on `!operationRunning`"; if-order anchor 2570 | the gating differs per button: schedule installs (2727, 2737) gate on `!operationRunning`, Update catalog (`Button` 3663, `enabled` 3666) only on its own process, and Explain rule (2994) with the provenance and coverage expanders (3019, 3106) have no `enabled` binding at all. The action if-chain is 2571 (2570 is its `onClicked`), the confirm-label chain 2559–2563 | 01 A2; 03 §10 invariant 5; 05 §2, §3 items 0.3–0.4 |
