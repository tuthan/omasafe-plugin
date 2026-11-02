// PostureIndicator.qml — a single posture bar indicator, one segment per state.
//
// One cell per posture state; the active state is drawn filled, all others
// dim. The state word is on the tooltip and never painted as text — it is a
// colour-coded shape, the same as the strip cells in PostureView.
//
// Usage:
//   PostureIndicator {
//     state: panel.postureIndicatorState   // "pass" | "attention" | "regression" | "error" | "incomplete" | "unsupported" | "unavailable" | "not_yet_run" | "stale"
//     panel: root.panel
//   }
//
// State → colour (CH8 / doc 08):
//   pass                          green    (healthy)
//   attention                     amber    (needs review)
//   incomplete                    amber    (partial observation)
//   unsupported                   gray     (unreadable)
//   regression                    red      (worse than before)
//   error                         red      (system fault)
//   unavailable / not_yet_run     dim grey (no data)
//   stale                         dim grey (stale data)
//
// A state with no observed checks is NOT rendered as a label; the indicator is
// one filled segment only.

import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs

Item {
  id: root

  // One of: pass, attention, incomplete, unsupported, regression, error,
  // unavailable, not_yet_run, stale. "" renders nothing.
  property string state: ""

  // The panel this indicator belongs to (for cursor support).
  property var panel: null

  property color passColor:   Color.healthy
  property color attentionColor: Color.accent
  property color incompleteColor: Color.accent
  property color unsupportedColor: Color.dim
  property color regressionColor: Color.urgent
  property color errorColor: Color.urgent
  property color unavailableColor: Color.faint
  property color notYetRunColor: Color.faint
  property color staleColor: Color.faint

  readonly property color _stateColor: {
    if (root.state === "pass") return root.passColor
    if (root.state === "attention" || root.state === "incomplete") return root.attentionColor
    if (root.state === "unsupported") return root.unsupportedColor
    if (root.state === "regression" || root.state === "error") return root.errorColor
    return root.unavailableColor
  }

  // Bar space: 1 segment, height = icon size.
  readonly property real indicatorHeight: Style.space(6)
  readonly property real indicatorWidth: 36

  width: parent ? parent.width : implicitWidth
  height: Math.max(implicitHeight, indicatorHeight)

  // The filled segment. Visible only when a real state is set (CH7: a measure
  // of zero is data, not "unavailable"). The dim track is always painted so the
  // bar keeps its anchor.
  Rectangle {
    id: segment
    x: 0
    y: (height - indicatorHeight) / 2
    width: root.state !== "" ? root.indicatorWidth : 0
    height: root.indicatorHeight
    color: root._stateColor
    radius: Style.cornerRadius
    visible: root.state !== ""

    // Tooltip: the state word, plus the age when stale.
    ToolTip {
      text: {
        if (root.state === "stale") return "Posture stale (" + (root.panel ? root.panel.postureModel : "").ageText + ")"
        if (root.state === "unavailable") return "Posture unavailable (CLI not verified)"
        if (root.state === "not_yet_run") return "Posture: no scan has completed"
        return "Posture: " + String(root.state).toUpperCase()
      }
      visible: root.state !== ""
      enabled: root.panel !== null
    }
  }

  // The dim track: always visible, so the bar keeps its visual anchor even when
  // there is no posture data yet.
  Rectangle {
    x: segment.x + segment.width
    y: segment.y
    width: Math.max(0, root.width - segment.x - segment.width)
    height: segment.height
    color: Color.dim
    radius: Style.cornerRadius
    visible: root.state !== ""
  }
}
