# Phase 5 — optional large view (`TrustFlowWindow`)

A `panel`-kind window that opens all four Flow layers at once, summoned from the Flow header. **Optional, and
the only phase that changes how the outside world addresses this plugin.** The popup is complete on its own: if the
in-panel Flow answers the four user questions of [`04 §1`](../design/04-trust-graph-spec.md) after **Phase 4**
dogfooding, this phase is not built. The anchor is Phase 4, not Phase 3: the post-Phase-3 live review found the graph
rendered no nodes and did not explain itself, so the popup only becomes correct and self-explanatory — the actual
input to this decision — once T4.0 (live correctness) and T4.1 (comprehension) land.

Effort L · 5–8 days. Risk: high — a new surface plus an IPC route change.
Spec: [`05 §8`](../design/05-implementation-roadmap.md), `04 §wide surface`, `05 §9` (component inventory row for
`TrustFlowWindow.qml`).

## Contents

1. [Go/no-go](#1-gono-go)
2. [Task list](#2-task-list)
3. [Tasks](#3-tasks)
4. [Acceptance](#4-acceptance)
5. [Risks](#5-risks)
6. [Sources](#6-sources)

## 1 Go/no-go

Decide before any code (open decision 6). The criterion is not "would a bigger view be nice" but: **after Phase 4
dogfooding, does any of the four questions in `04 §1` remain unanswerable inside the popup?** If none does, stop
here and record that. Judge it against the Phase 4 popup, not the Phase 3 one — T4.1's progressive disclosure exists
precisely to make the popup answer all four questions in 420 units, so a "no" is more likely, not less, after Phase 4.
The second half of the gate is the owner's explicit sign-off on the IPC change in T5.2 —
`omarchy-shell shell hide io.github.tuthan.omasafe` stops closing the popup the moment `kinds` grows, and that is a
user-visible change to a documented command.

## 2 Task list

| Order | Task | Creates / modifies | Effort |
|---|---|---|---|
| 1 | [T5.1](#t51-record-the-decision) record the decision | `docs/design/07` §8 | 30 min |
| 2 | [T5.2](#t52-manifest-and-the-ipc-route) manifest + IPC route | `manifest.json` | 2 h |
| 3 | [T5.3](#t53-trustflowwindowqml) `TrustFlowWindow.qml` | 1 file | 2–3 d |
| 4 | [T5.4](#t54-summon-payload-and-the-degradation-ladder) summon, payload, degradation | `Panel.qml`, `views/FlowView.qml` | 1 d |
| 5 | [T5.5](#t55-the-windows-own-collectors) the window's own collectors | `TrustFlowWindow.qml` | 1 d |
| 6 | [T5.6](#t56-ipc-documentation-and-version-bump) IPC docs + version bump | `README.md`, `manifest.json` | 4 h |

## 3 Tasks

### T5.1 Record the decision

**Change.** Write the go/no-go and its evidence into [`07 §8`](../design/07-verification-findings.md) as a new row.
A "no" is a real outcome and should be as visible as a "yes"; the plan explicitly permits stopping after Phase 4.

### T5.2 Manifest and the IPC route

**Change.** Per `05 §8`, and only in this phase:

| Key | Today | Phase 5 | Note |
|---|---|---|---|
| `kinds` | `["bar-widget"]` | `["bar-widget", "panel"]` | `shell.qml:426–438 isBarWidgetPanelPlugin` now returns false for this id |
| `entryPoints.panel` | absent | `"TrustFlowWindow.qml"` | loaded by the panel loader on `summon`, unloaded on `hide` |
| `keepLoaded` | absent (false) | stays absent | the window costs nothing while closed (`shell.qml:625`) |
| `version` | `0.3.0` | `0.4.0` | the `kinds` change alters the IPC route |
| `barWidget.*` | unchanged | unchanged | the bar icon still opens the popup via `summonBarWidget` |

The dual-kind shape to copy is `plugins/menu/manifest.json`.

**Consequence to internalise before writing it.** Once `panel` is present, `isBarWidgetPanelPlugin` returns false for
this id, so `summon` (`shell.qml:456–461`), `hide` (480–494) and `isPluginOpen` (497–) — and therefore `toggle`
(510) — all take the panel-loader path. `omarchy-shell shell summon|toggle|hide io.github.tuthan.omasafe` then
address the **window only**: `shell hide` can no longer close the popup and `toggle` never reaches it. The popup is
still opened by the bar icon and still dismissed by Esc and outside-click, exactly as today.

**Verify.** `omarchy plugin validate .` passes with both kinds. `shell hide` with the popup open leaves the popup
open and returns without a warning.

### T5.3 `TrustFlowWindow.qml`

**Change.** A `PanelWindow` (Overlay layer) holding a `BorderSurface` card at `Style.space(1080)`, with
`PanelKeyCatcher`, `PanelHero`, the lens `ButtonGroup`, `TrustFlow` with all four layers open, `InspectorStrip`,
`PluginDetailView` and `ConfirmSheet`. It implements `open(payloadJson)` and `close()` and dismisses through
`shell.hide(manifest.id)` (`plugins/panels/wifiqr/Panel.qml:51–92`).

The window reuses the graph components as T4.0 left them: `TrustFlow`, `FlowNode`, `MatrixGrid` and `TraceChain`
already pass their model roles explicitly, so the corrected delegate contract is inherited, not re-derived. It also
carries T4.1's comprehension copy — the `ANALYSIS PATHS` heading, the `Plugin → observed capability → detecting rule
→ Baseline V3 mapping` line, the never-blank inspector, the `solid = parser-backed` / `dashed = text match only`
vocabulary and the typed rail labels. T4.1's *progressive-disclosure defaults do not carry over*: Matrix-first and
hidden rest edges exist to fit the 420-unit popup, whereas this window's purpose is to show all four layers at once.
The non-anonymous-edge rule still holds — every edge terminates at a visible, labelled node.

`PluginDetailView` is not optional here: mutations exist only inside the detail sheet (`TRUST BASELINE` per
`04 §6.1`; `MARKETPLACE CLAIM` and `ENFORCEMENT` per `03 §5.4`), so a `ConfirmSheet` without it has nothing to open
it.

**Verify.** The window is unloaded after close — no `TrustFlowWindow` item in a QML debugger dump.
`shell.openPanelIds` is consistent after `hide`. With all four layers open, a fresh live-shell journal interval is
free of delegate-creation, required-property, assignment, JavaScript and binding-loop warnings — the T4.0 gate, run
against the surface that stresses it hardest — and every rendered edge terminates at a visible node.

### T5.4 Summon, payload and the degradation ladder

**Change.** The popup calls `bar.shell.summon(root.moduleName, JSON.stringify(payload))`, as
`plugins/panels/network/Panel.qml:468` does for `omarchy.wifiqr`. Note `root.moduleName`, not `manifest.id`:
`manifest` is injected only into panel/overlay/menu loader items, so the popup does not have it (`06 §14`).

The payload carries `view`, `lens`, `pluginId`, scan meta and alerts **only** — no warm analysis caches. The launcher
is a `PanelActionButton 󱁉 "Open large view (g)"` in the Flow header, hidden when unavailable.

Degradation ladder, in order: `bar.shell` null (`plugins/bar/Bar.qml:25` declares `property var shell: null`) →
`summon()` returns false → the loader errors. At any rung the launcher is hidden and every Enter stays in the popup.

**Verify.** A build with `bar.shell` forced null shows no launcher and loses no function. `shell summon` and
`shell toggle io.github.tuthan.omasafe` open the window; `shell hide io.github.tuthan.omasafe` closes it.

### T5.5 The window's own collectors

**Change.** The window runs its own bounded collectors — a verbatim copy of the process pattern, not a shared
instance — and **re-fetches `plugins status` before any `ConfirmSheet`**, whatever the payload said. Two collector
instances mean two status sweeps when both surfaces are open; the window skips its sweep when the payload's trust
states are under 60 s old, but never skips the pre-confirmation identity fetch.

Alerts are the one thing the window cannot fetch: the CLI has no read-only alerts query. Until `scan --status` exists
(`05 §12`, a non-blocking CLI ask), the window shows `Alerts unavailable in this view · press r to scan` rather than
rendering the payload's alerts as current.

**Verify.** Every confirmation in the window shows action-specific authorization facts fetched **by the window
itself**. With both surfaces open, at most one status sweep runs per surface per 60 s.

### T5.6 IPC documentation and version bump

**Change.** Add the README "IPC" note: `omarchy-shell shell summon|toggle|hide io.github.tuthan.omasafe` address the
large view only, `hide` no longer closes the popup, and the popup is opened by the bar icon and closed by Esc or
outside-click. Document the keybind form
`omarchy-shell shell toggle io.github.tuthan.omasafe '{"view":"flow"}'`. Bump `version` to `0.4.0` and add the
`CHANGELOG.md` entry.

## 4 Acceptance

- [ ] `shell summon` and `shell toggle io.github.tuthan.omasafe` open the window; `shell hide
      io.github.tuthan.omasafe` closes it.
- [ ] With the popup open, `shell hide` leaves the popup open and returns without a warning.
- [ ] The bar icon still opens the popup; Esc and outside-click still close it.
- [ ] `shell.openPanelIds` is consistent after `hide`; the window is unloaded after close.
- [ ] A build with `bar.shell` forced null shows no launcher and loses no function.
- [ ] Every confirmation in the window shows facts the window fetched itself.
- [ ] The README IPC note is present; `manifest.json` is `0.4.0`.

## 5 Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| The IPC route change surprises a user's keybind | high if undocumented | the T5.2 consequence paragraph, the T5.6 README note, and the owner's explicit sign-off in the go/no-go |
| Two collector instances double the CLI load | medium | the 60 s payload-freshness skip, and the pre-confirmation fetch that is never skipped |
| Alerts look current in the window when they are not | medium | the explicit `Alerts unavailable in this view` line until `scan --status` exists |
| The window becomes the de facto main surface and the popup rots | medium | the popup stays the primary and complete home for Trust Flow (`04`); this phase adds a surface, it does not move one |

## 6 Sources

- [`05 §8`](../design/05-implementation-roadmap.md) manifest table, contract, degradation ladder, risks and
  acceptance; `05 §9` component inventory; `05 §12` README and version policy; `05 §13` open decision 6.
- [`04 §1`](../design/04-trust-graph-spec.md) the four questions the go/no-go is judged against; `04 §wide surface`
  the window contract.
- Host: `shell.qml:426–438, 456–461, 480–494, 497–, 510, 625`; `plugins/menu/manifest.json`;
  `plugins/panels/network/Panel.qml:468`; `plugins/panels/wifiqr/Panel.qml:51–92`; `plugins/bar/Bar.qml:25`.
