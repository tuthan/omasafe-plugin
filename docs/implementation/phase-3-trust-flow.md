# Phase 3 — Trust Flow

The Flow view, complete inside the 420-unit popup: four fixed layers `PLUGINS → CAPABILITIES → RULES → BASELINE V3`
drawn as the same `CursorSurface` rows the other views use, joined by Bézier edges in one `Shape`; a Matrix lens over
plugins × capability classes; a Z2 Trace for one path; an inspector strip; and analysis that runs only when asked.

Two milestones, ordered so the rendering gate is passed before the text lenses are built. **3a** is the graph
(smoke test, layout, nodes, edges, view, inspector, chip). **3b** is Matrix, Trace, the analysis queue and the letter
keys. If the day-1 smoke test fails, 3a shrinks to `FlowView` + `InspectorStrip` and 3b carries the whole Flow body
as text rows — the fallback is pre-decided so the phase cannot stall.

Effort L · 8–12 days (3a 4–6 d, 3b 4–6 d). Risk: medium-high, all of it in rendering.
Spec: [`04`](../design/04-trust-graph-spec.md) in full — §2 model, §3 view-model shapes, §4 layout, §5 encodings,
§6 interactions, §7 disclosure ladder, §8 states, §9 wireframes, §10 architecture, §11 budget, §12 acceptance —
plus [`03 §6`](../design/03-ui-overhaul-proposal.md) (frame, entry, exit) and
[`05 §6`](../design/05-implementation-roadmap.md).

## Contents

1. [Entry criteria](#1-entry-criteria)
2. [Task list](#2-task-list)
3. [Milestone 3a — the graph](#3-milestone-3a--the-graph)
4. [Milestone 3b — Matrix, Trace, queue](#4-milestone-3b--matrix-trace-queue)
5. [Commit plan](#5-commit-plan)
6. [Acceptance](#6-acceptance)
7. [Risks](#7-risks)
8. [Sources](#8-sources)

## 1 Entry criteria

- Phase 2 merged: `vm`, the row components, the cursor model with per-view sections, depth stacks and the finder all
  work.
- `rules list` and `rules coverage` are both cached (T2.9): the rule column labels and the whole Baseline layer come
  from them.
- Read [`04 §4`](../design/04-trust-graph-spec.md) before writing any layout code. Steps 2, 3 and 4 (order keys,
  the barycentre sweep gated on `orderEpoch`, and the shared window) are where a plausible-looking implementation
  silently turns occurrence order into topology order or lets nodes jump under the cursor.
- Nothing in this phase adds a CLI call. `plugins analyze` runs on `a` or `A` only — **never** on view open.

## 2 Task list

| Order | Task | Creates / modifies | Blocked by | Effort |
|---|---|---|---|---|
| 1 | [T3.1](#t31-day-1-the-curverenderer-smoke-test-gate) CurveRenderer smoke test | throwaway probe | — | 4 h |
| 2 | [T3.2](#t32-graphflowlayoutjs) `graph/FlowLayout.js` | 1 file | T3.1 pass | 1.5 d |
| 3 | [T3.3](#t33-graphflownodeqml) `graph/FlowNode.qml` | 1 file | T3.2 | 4 h |
| 4 | [T3.4](#t34-graphedgelayerqml) `graph/EdgeLayer.qml` | 1 file | T3.1 pass | 4 h |
| 5 | [T3.5](#t35-graphtrustflowqml) `graph/TrustFlow.qml` | 1 file | T3.3, T3.4 | 1.5 d |
| 6 | [T3.6](#t36-viewsflowviewqml-and-the-inspector-strip) `views/FlowView.qml`, `InspectorStrip.qml` | 2 files | T3.5 | 1 d |
| 7 | [T3.7](#t37-show-the-flow-chip) Flow chip, key `2`, graph cursor sections | `Panel.qml` | T3.6 | 4 h |
| 8 | [T3.8](#t38-the-root-analysis-queue) root analysis queue | `Panel.qml` | T3.7 | 1 d |
| 9 | [T3.9](#t39-a-a-and-x) `a` / `A` / `x` | `Panel.qml`, `FlowView.qml` | T3.8 | 4 h |
| 10 | [T3.10](#t310-graphmatrixgridqml) `graph/MatrixGrid.qml`, `m` / `c` | 1 file | T3.6 | 1 d |
| 11 | [T3.11](#t311-graphtracechainqml-z2) `graph/TraceChain.qml` (Z2), `t` | 1 file | T3.10 | 1 d |
| 12 | [T3.12](#t312-the--legend) `?` legend | `FlowView.qml` | T3.10 | 2 h |
| 13 | [T3.13](#t313-render-timing-and-legibility-pass) render timing + legibility | — | all | 4 h |

## 3 Milestone 3a — the graph

### T3.1 Day 1: the CurveRenderer smoke test (gate)

**Goal.** Decide, on evidence, whether edges can be drawn at all on this host — before any graph code exists.

**Change.** Side-load a ≈ 40-line throwaway view containing `Shape { preferredRendererType: Shape.CurveRenderer }`
with one solid and one `ShapePath { strokeStyle: ShapePath.DashLine; dashPattern: [4, 4] }` `PathSvg` bucket.
Screenshot it in `catppuccin-latte` and `flexoki-light`, at base 9 and 20, at Hyprland scale 1.0 and 1.25
(`hyprctl keyword monitor`). All three APIs are present in the installed Qt: `CurveRenderer` at
`/usr/lib/qt6/qml/QtQuick/Shapes/plugins.qmltypes:51`, `DashLine` at 389, `dashPattern` at 488.

**Gate.** If edges are missing, misaligned or aliased beyond legibility at any of those four combinations, the graph
lens is dropped for this release: 3a shrinks to `FlowView` + `InspectorStrip`, Matrix + Trace become the Flow body as
text rows (`CursorSurface` + `Text`), and T3.2–T3.5 are cancelled. `Canvas` is **not** a fallback — no first-party
file instantiates one, and `05 §11.1` greps for it.

**Verify.** Eight screenshots, a written verdict, and the probe deleted. Record the verdict in the phase's first
commit message.

### T3.2 `graph/FlowLayout.js`

**Goal.** Pure functions that turn the view-model into node sets, order, geometry and path strings.

**Change.** Implement `04 §4.1` steps 1–7 and the pseudocode of `04 §4.2` exactly:

1. **Node sets** from scope and filters. Plugins: live rows (`b` adds backups as `faint`, edgeless, `not scanned`).
   Classes: those present in any cached analysis in scope. Rules: those referenced by a drawn class → rule edge.
   Baseline: at Z0 with ≥ 1 analyzed plugin, every distinct `externalId` in `rules coverage` in map order, including
   `not_covered`; with **zero** analyses, one `not analyzed` sentinel represents the column, because no local path
   exists yet. At Z1, only the ids reachable from the scope plugin.
2. **Order keys.** Plugins `outstanding desc, analyzed first, id asc`; classes `occurrences desc, id asc` (the one
   exception to catalog order — `CapabilityStrip` and `MatrixGrid` keep catalog order); rules `reviewItems desc,
   occurrences desc, id asc`; Baseline in map order. Keys are computed on Flow entry or scope change and frozen while
   open (`orderEpoch`).
3. **Barycentre tie-break** over the middle layers only, left → right then right → left. The step-2 keys stay
   primary: barycentre orders only nodes **tied** on those keys, so drawn occurrence order never silently becomes
   topology order. It runs only when `orderEpoch` changes. On same-epoch data arrival the previous order is retained
   and genuinely new keys append at the column end — neither key-sort nor barycentre may move an existing node.
4. **Window.** `rowH = Style.spacing.popupRowHeight`; `bodyH` is what the popup has left (`04 §4.3` table), not a
   fixed cap; `maxRows = floor(bodyH / rowH)`; all four columns share `rows = min(maxRows, max(node count))`. A
   fuller column shows `rows − 1` plus a `+N more` rail row; the cursor moves that column's `offset` — **geometry
   only, never the node arrays** — and edges into hidden nodes terminate at the `+N more` row.
5. **Geometry (focus pair).** Two adjacent columns open, two as rails. `railW = Style.space(28)`,
   `pairGutter = Style.space(72)`, `railGutter = Style.space(12)`,
   `openW = (width − 2·railW − pairGutter − 2·railGutter) / 2` = 118 at base 12, where `width` is the graph item's
   width. Columns snap: no `Behavior` on widths, or edges misalign mid-slide.
6. **Edges.** `y = headerH + (row − offset) · rowH + rowH / 2`; cubic Bézier
   `M x1 y1 C x1+lane/3 y1 x2−lane/3 y2 x2 y2`. Control points at **thirds**, not the midpoint, so parallel edges fan
   across the 72-unit lane instead of packing into a near-vertical S. There are no skip edges: class-level Baseline
   relations are node adornments (`04 §2.2`).
7. **Buckets.** Thickness by weight (`thin` ≤ 3, `med` 4–9, `thick` ≥ 10 → `Style.space(1/2/3)`), dashed per
   `04 §2.2`. Eight path strings: `dim × {thin, med, thick} × {solid, dashed}` + `hot × {solid, dashed}`.

**Verify.** Unit-test against [`fixtures/contract-cases.json`](../design/fixtures/contract-cases.json) and
[`verified-summary.json`](../design/fixtures/verified-summary.json): the four sampled analyses produce 5 capability
nodes, 6 rule nodes and 12 Baseline ids; class → baseline edges are 0; `PathSvg` strings total under 6 KB. Same-epoch
rebuilds preserve prior order; a new epoch re-sorts.

### T3.3 `graph/FlowNode.qml`

**Change.** `CursorSurface` + `OpticalGlyph` + label `Text` + count `Text` (`bodySmall`) + a `MouseArea` for hover and
click only — no tooltip, no wheel (those belong to the column and to `TrustFlow`). Labels `ElideMiddle`, counts never
elided: at base 9 the focus-pair column is 87 units (`04 §4.3`) and the count is the fact worth keeping. A node with
no analysis is hollow and reads `not analyzed` — never `0`.

**Verify.** No `containsMouse` read; nothing encodes a verdict — every state is a word, a glyph shape or a weight.

### T3.4 `graph/EdgeLayer.qml`

**Change.** One `Shape { preferredRendererType: Shape.CurveRenderer }` holding **eight static**
`ShapePath { PathSvg }` buckets — the `Ui/BorderOverlay.qml:51` technique. Paths are written as strings by
`FlowLayout.build()` and `hot()`; empty strings cost nothing. Nodes and paths share the `TrustFlow` root coordinate
space, and `rowCenter()` includes `headerH` **exactly once** — `EdgeLayer` has no top margin. Rest alpha binds to
`Style.hoverBorderAlpha`.

**Verify.** Edge endpoints align with node centres at base 9 / 12 / 16 / 20. No `Timer` in the file; no
`layer.enabled`, `MultiEffect` or `Particles` anywhere.

### T3.5 `graph/TrustFlow.qml`

**Change.** Column headers, four `Repeater`s of `FlowNode` over the four `nodes` arrays, `+N more` rail rows,
`EdgeLayer`, one column-level wheel `MouseArea` per column, one `PanelToolTip` at the hovered node, and
`PointerMoveGate` so reflow under a stationary pointer cannot steal the cursor. Rows outside the shared window are
`visible: false` (10 visible rows at base 12).

The two revision keys are the correctness core (`04 §10.1`, `06 §14`): `membershipKey` tracks node identity and
`contentKey` tracks counts, state and adornments, so a same-membership analysis change still notifies QML. Data
revisions may reassign the models; **navigation may not**.

**Verify.** 50 `h`/`l`/`j`/`k`/wheel operations do not reassign any node model. The cursor path plugin → class → rule
→ baseline keeps exactly one hot edge set at every `h`/`l`. Columns snap with no geometry `Behavior`.
`ensureCursorVisible` runs on every graph cursor move.

### T3.6 `views/FlowView.qml` and the inspector strip

**Change.** `FlowView` owns the Flow depth stack, the lens `ButtonGroup`, the scope, the `HIDING …` fragment of the
section-header value, the `?` legend button in the lens row's right slot, and a `Loader` selecting Graph
(`TrustFlow`), Matrix (`MatrixGrid`, T3.10) or Z2 (`TraceChain`, T3.11). `InspectorStrip` is `PanelSeparator` +
four `Text` + one `Button` carrying the cursor's facts for whichever lens is active. The Flow `Loader` unloads when
the panel closes; `layout` is reused on reopen.

**Verify.** Z0 opens on `PLUGINS | CAPABILITIES` with the header `TRUST FLOW · ALL PLUGINS | 4 OF 8 ANALYZED`. A
`parser: null` fixture in scope shows the persistent lexical-only `NoticeRow`, and only evidence edges with no
parser-backed support are dashed — mixed edges stay solid and disclose both counts.

### T3.7 Show the Flow chip

**Change.** The `ButtonGroup` options become `[Overview] [Flow] [Rules]` and key `2` is bound; `2` from a plugin
detail sheet opens Flow at Z1 for that plugin. Add the graph cursor sections of `03 §13`:
`hero → views → lens → col-0 … col-3 → inspector-actions`, with `h`/`l` crossing columns.

**Verify.** No digit changed meaning for an existing view: `1` is still Overview and `3` still Rules. Enter on a
pinned rule node pushes a `returnFrame` and lands in the rule sheet; `-` comes back.

## 4 Milestone 3b — Matrix, Trace, queue

### T3.8 The root analysis queue

**Goal.** `a` on a node that is not the selected plugin, and `A` over eight plugins, both need a queue. `Panel.qml`
has none: `analysisProcess.startFor()` (4692–4707) keeps one `nextPluginId` slot and **preempts** the running
analysis, and `ensureAnalysis()` reads `selectedPlugin()` into a single display slot.

**Change.** Add the four members of `04 §10.1`, mirroring `statusQueue` / `statusSweepGeneration` (77–78, 602–622):
`analysisQueue` (ids waiting), `analysisSweepGeneration` (bumped by `x`, by `close()` / `onOpenedChanged(false)` and
by CLI gate loss; a result whose generation is stale is discarded), `analysisStateById`
(`not analyzed` / `analyzing` / `analyzed` / `unavailable`, replacing `analysisLoading` for the graph and read by the
detail sheet too), and `startNextAnalysis()` (no-op while the process runs, else shift and `startFor(id,
++requestId)`). `analysisProcess.onExited` chains `applyAnalysis` → `analysisStateById[id]` → `startNextAnalysis()`.
`startFor()`'s preemption survives **only** for the selected-plugin path.

The queue is sequential by construction — one `Process` — so the 30 s timeout and 2 MiB cap apply per run.

**Verify.** `a` on `ilyazar.btop` runs exactly one bounded process; its node fills in without relayout of the other
columns. A failed analysis renders a hollow node and `unavailable`, never a zero. A sweep of eight uncached plugins
takes ≈ 8 × 0.2 s.

### T3.9 `a`, `A` and `x`

**Change.** `a` queues the cursor plugin, `A` queues every live plugin whose cache key misses. `x` drops the rest of
the queue and lets the running process finish; it never mutates anything. Progress shows as the `󰦖` node glyph plus
`Queued (n ahead)` in the inspector. Analysis never starts on view open.

**Verify.** With an `A` sweep running, `x` leaves exactly one process running and clears the rest. Open decision 5 is
answered here: whether the node glyph plus the inspector line is enough, or the hero meta needs a progress fragment.

### T3.10 `graph/MatrixGrid.qml`

**Change.** Two `Repeater`s of `CursorSurface` + `Text` cells with header glyph `Text`s inside a horizontal
`Flickable`. Default columns are the observed classes (5 with the sampled analyses); `c` shows all 17 in **catalog
order**. Unanalyzed rows show `–`. Enter on a cell opens Z2 for that class. `m` toggles the lens.

**Verify.** 5 columns by default, 17 after `c`, horizontal scrolling only inside the grid's own `Flickable` — the
panel body never scrolls sideways. `x` unpins and mutates nothing.

### T3.11 `graph/TraceChain.qml` (Z2)

**Change.** The chain `Text`s plus a `ListView` of `EvidenceRow`, the `EdgeRow`s and the limitation rows
(`04 §9.4`). `t` traces the pinned path.

**Verify.** The trace for `lgse.sandman → process-execution → oma.qml.process-execution → curl-pipe-shell` renders
the three-line chain, `EVIDENCE | 16 ROWS`, `FILE EDGES | 5` and `COVERAGE LIMITS ON THIS PATH | 13`. The map `note`
is **not** on this screen — it is rendered verbatim only in the Baseline V3 coverage table (T2.11), reached by Enter
on the chain's baseline id.

### T3.12 The `?` legend

**Change.** One `PanelToolTip` listing the glyphs, edge styles and keys in use, opened by `?` from the lens row's
right slot. Every string comes from `02 §2.7` and `02 §3.6`; none contains "safe", "clean", bare "verified" or
"risk".

### T3.13 Render timing and legibility pass

**Change.** Relaunch the shell from a terminal as
`QSG_RENDER_TIMING=1 quickshell -n -p /usr/share/omarchy/shell 2> /tmp/qsg.log`, open Flow, move the cursor across
all four columns, and read the render-pass lines; budget 4 ms at base 12 on the reference machine. Restore the normal
launch with `omarchy-restart-shell`. Take edge-legibility screenshots in `flexoki-light` and `catppuccin-latte`. If
edge alpha is too faint on a translucent light theme, switch the rest alpha binding from `Style.hoverBorderAlpha` to
`Style.normalBorderAlpha` — one binding.

Open decision 7 applies: if the owner prefers not to relaunch the shell, check the budget by eye on the 1.25-scale
monitor and record it as an eye check, not a measurement.

## 5 Commit plan

| Commit | Tasks | Note |
|---|---|---|
| 1 | T3.1 | the verdict, in the message; the probe is not committed |
| 2 | T3.2 | pure JS plus its fixture tests, no QML |
| 3 | T3.3 + T3.4 | node and edge primitives, not yet composed |
| 4 | T3.5 | the graph assembles |
| 5 | T3.6 + T3.7 | the view and its chip: the first commit where Flow is reachable |
| 6 | T3.8 | queue, behind the existing keys |
| 7 | T3.9 | `a` / `A` / `x` |
| 8 | T3.10 | Matrix |
| 9 | T3.11 | Trace |
| 10 | T3.12 + T3.13 | legend and the measurement record |

If T3.1 fails, commits 2–4 do not exist and commit 5 ships `FlowView` + `InspectorStrip` with the Matrix as the
default body.

## 6 Acceptance

Restated from `04 §12` and `05 §6`:

- [ ] With the four sampled analyses: 5 capability nodes, 6 rule nodes, 12 Baseline ids — 3 markless (`not-covered`:
      `cargo-git-unpinned`, `remote-build`, `remote-git-execution-unpinned`), 5 with a via-class glyph (`installer`,
      `package-manager`, `privilege`, `sudoers-modification` under `󰆍`; `service-management` under `󰔛`), 1 with an
      incoming edge (`oma.qml.process-execution → curl-pipe-shell`, dashed), 3 marked `≈` with neither edge nor
      glyph; class → baseline edges 0.
- [ ] Z0 opens on `PLUGINS | CAPABILITIES`; header `TRUST FLOW · ALL PLUGINS | 4 OF 8 ANALYZED`.
- [ ] Cursor path keeps exactly one hot edge set at every `h`/`l`; columns snap; `PathSvg` total under 6 KB.
- [ ] `a` on `ilyazar.btop` runs one bounded process and does not relayout other columns; a failed analysis renders
      hollow + `unavailable`.
- [ ] `parser: null` scope: persistent lexical-only notice; only unsupported evidence edges dashed; two independent
      `decision.outcome: "block"` fixtures keep two `󰂭` urgent glyphs, both inside the `02 P9` allowlist.
- [ ] Edge endpoints align at base 9 / 12 / 16 / 20; same-membership revisions update through `contentKey`; 50
      navigation operations reassign no model.
- [ ] Matrix: 5 columns default, 17 after `c`, `–` for unanalyzed, Enter opens Z2, `x` unpins without mutating.
- [ ] Z2 renders the three-line chain with `EVIDENCE | 16 ROWS`, `FILE EDGES | 5`, `COVERAGE LIMITS ON THIS PATH |
      13`, and no map note.
- [ ] `grep -rn 'Timer {' graph/ views/FlowView.qml` is empty;
      `grep -rnE 'layer.enabled|MultiEffect|Particles|Canvas' --include='*.qml' .` is empty; the Flow `Loader` is
      unloaded when the panel closes.
- [ ] Render pass under 4 ms at base 12; legibility screenshots taken.

## 7 Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| `CurveRenderer` under fractional scaling | medium-high | T3.1 on day 1, with the text fallback pre-decided |
| Edge alpha too faint on translucent light themes | medium | one binding switch, decided in T3.13 |
| Focus-pair columns too narrow at base 9 (`openW` = 87) | medium | labels `ElideMiddle`, counts kept |
| `A` = eight bounded processes | low | sequential by construction, cancellable by `x`, progress shown |
| Layout cost on the hot path | low | rebuild only on inventory / analysis / alert-or-trust content / scope / filter change; cursor moves touch geometry and `hot()` only |
| Nodes jumping under the cursor after `a` | medium | `orderEpoch`: same-epoch arrivals append at the column end and never re-sort |

## 8 Sources

- [`04`](../design/04-trust-graph-spec.md) §2 four-layer model and edge derivation, §3 view-model shapes and worked
  examples, §4 layout steps, pseudocode and sizing math, §5 verdict-free encodings, §6 interactions and cursor
  integration, §7 disclosure ladder, §8 states, §9 wireframes, §10 architecture and the analysis-queue table, §11
  performance budget, §12 acceptance checklist.
- [`03 §6`](../design/03-ui-overhaul-proposal.md) Flow frame, entry and exit; `03 §13` graph cursor sections and the
  return frame.
- [`05 §6`](../design/05-implementation-roadmap.md) milestones, file list, data dependencies, risks and acceptance;
  `05 §9` component inventory; `05 §11.4` measurement recipes.
- Qt and kit: `/usr/lib/qt6/qml/QtQuick/Shapes/plugins.qmltypes:51, 389, 488`; `Ui/BorderOverlay.qml:51`;
  `Ui/PanelToolTip.qml`; `Ui/PointerMoveGate.qml:30`.
