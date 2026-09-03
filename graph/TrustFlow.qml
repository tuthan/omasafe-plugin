import QtQuick
import qs.Commons
import qs.Ui

// TrustFlow — the four-layer graph body (doc 04 T3.5, §10.2). Column headers, four
// Repeaters of FlowNode over the four `nodes` arrays, "+N more" rail rows, EdgeLayer,
// one column-level wheel MouseArea per column, one PanelToolTip at the hovered node,
// and a PointerMoveGate so reflow under a stationary pointer cannot steal the cursor.
//
// Three properties, three reassignment cadences (§3.2): `nodes` is reassigned only
// when membershipKey OR contentKey changes; `geometry` on every slide / offset move;
// `paths` on every build() and hot(). Navigation (h/l/j/k/wheel) touches geometry and
// paths only — the Repeater models are the stable `nodes` arrays, so no FlowNode
// delegate is created or destroyed while navigating.
Item {
  id: flow

  property var nodes: [[], [], [], []]
  property var geometry: ({ headerH: 20, rowH: 28, rows: 0, cols: [] })
  property var paths: ({})
  property var hotKeys: ({})
  property string focusSection: ""
  property int selectedIndex: -1
  property string pinnedKey: ""
  property int hoverColumn: -1
  property int hoverIndex: -1

  property string fontFamily: Style.font.family
  property string resolvedFamily: Style.font.resolvedFamily
  property color fg: Color.foreground
  property color urgentColor: Color.urgent
  property color dimColor: fg
  property color faintColor: fg
  property color dimHeaderColor: fg

  signal cursorRequested(int column, int index)
  signal activated(int column, int index)
  signal wheelRequested(int column, int steps)

  readonly property var _headerLabels: [
    { full: "PLUGINS", abbr: "PL" }, { full: "CAPABILITIES", abbr: "CA" },
    { full: "RULES", abbr: "RU" }, { full: "BASELINE V3", abbr: "BA" }
  ]
  function _geoCol(i) {
    return (flow.geometry.cols && flow.geometry.cols[i])
      ? flow.geometry.cols[i] : ({ x: 0, width: 0, open: false, offset: 0, realRows: 0, hidden: 0, moreLabel: "" })
  }

  PointerMoveGate { id: gate; referenceItem: flow }

  // Paths and nodes share this root coordinate space; rowCenter() already includes headerH.
  EdgeLayer { anchors.fill: parent; paths: flow.paths; foreground: flow.fg }

  // column headers
  Repeater {
    model: 4
    delegate: Text {
      required property int index
      readonly property var geo: flow._geoCol(index)
      x: geo.x + Style.space(10)
      y: 0
      width: Math.max(0, geo.width - Style.space(12))
      height: flow.geometry.headerH
      verticalAlignment: Text.AlignVCenter
      textFormat: Text.PlainText
      text: geo.open ? flow._headerLabels[index].full : flow._headerLabels[index].abbr
      elide: Text.ElideRight
      color: flow.dimHeaderColor
      font.family: flow.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }

  // four columns
  Repeater {
    model: 4
    delegate: Item {
      id: col
      required property int index
      readonly property var geo: flow._geoCol(index)
      x: geo.x
      y: flow.geometry.headerH
      width: geo.width
      height: flow.geometry.rows * Style.spacing.popupRowHeight
      clip: true

      // the column owns the wheel; the outer Flickable never sees it
      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel) {
          wheel.accepted = true
          flow.wheelRequested(col.index, wheel.angleDelta.y > 0 ? -1 : 1)
        }
      }

      Repeater {
        model: flow.nodes[col.index]
        // A wrapper Item is the Repeater delegate so `modelData`/`index` are injected into
        // a root that declares them at this use site (T4.0). FlowNode's own required inputs
        // are then set by explicit binding — never left to implicit fill of an imported
        // component's inherited required properties, which does not instantiate at runtime.
        delegate: Item {
          id: nodeSlot
          required property var modelData
          required property int index
          width: col.width
          height: Style.spacing.popupRowHeight
          y: (nodeSlot.index - col.geo.offset) * Style.spacing.popupRowHeight
          visible: nodeSlot.index >= col.geo.offset &&
                   nodeSlot.index < col.geo.offset + Math.max(1, col.geo.realRows || flow.geometry.rows)

          FlowNode {
            width: nodeSlot.width
            modelData: nodeSlot.modelData
            index: nodeSlot.index
            column: col.index
            open: col.geo.open
            gate: gate
            fontFamily: flow.fontFamily
            resolvedFamily: flow.resolvedFamily
            fg: flow.fg
            urgentColor: flow.urgentColor
            dimColor: flow.dimColor
            faintColor: flow.faintColor
            dimHeaderColor: flow.dimHeaderColor
            hasCursor: flow.focusSection === "col-" + col.index && flow.selectedIndex === nodeSlot.index
            current: flow.pinnedKey !== "" && flow.pinnedKey === nodeSlot.modelData.key
            faint: nodeSlot.modelData.faint === true && !flow.hotKeys[nodeSlot.modelData.key]
            onCursorRequested: function(c, i) { flow.cursorRequested(c, i) }
            onActivated: function(c, i) { flow.activated(c, i) }
            onHoverEntered: function(c, i) { flow.hoverColumn = c; flow.hoverIndex = i }
            onHoverExited: function(c, i) { if (flow.hoverColumn === c && flow.hoverIndex === i) { flow.hoverColumn = -1; flow.hoverIndex = -1 } }
          }
        }
      }

      // "+N more" rail row: the last window slot when the column has hidden nodes.
      // Requires a reserved row (realRows >= 1); when the body is so short that
      // realRows collapses to 0 (one forced node fills a one-row window), showing it
      // would paint "+N more" at y=0 over that node — so it is hidden instead.
      Text {
        visible: col.geo.hidden > 0 && col.geo.realRows >= 1
        x: Style.space(10)
        y: (col.geo.realRows || 0) * Style.spacing.popupRowHeight
        width: Math.max(0, col.width - Style.space(18))
        height: Style.spacing.popupRowHeight
        verticalAlignment: Text.AlignVCenter
        textFormat: Text.PlainText
        text: col.geo.moreLabel
        elide: Text.ElideRight
        color: flow.dimColor
        font.family: flow.fontFamily
        font.pixelSize: Style.font.bodySmall
      }
    }
  }

  // one hover tooltip for the whole graph; pointer hover only (a keyboard cursor move
  // never sets hoverColumn, so it never pops one — the InspectorStrip is the keyboard path)
  readonly property var _hoverNode: (flow.hoverColumn >= 0 && flow.nodes[flow.hoverColumn]
    && flow.nodes[flow.hoverColumn][flow.hoverIndex]) ? flow.nodes[flow.hoverColumn][flow.hoverIndex] : null
  PanelToolTip {
    id: tip
    parent: flow
    visible: !!flow._hoverNode && !!flow._hoverNode.tooltip
    text: flow._hoverNode ? String(flow._hoverNode.tooltip) : ""
    fontFamily: flow.fontFamily
    delay: 300
    x: flow.hoverColumn >= 0 ? flow._geoCol(flow.hoverColumn).x + Style.space(10) : 0
    y: flow.geometry.headerH + Math.max(0, (flow.hoverIndex - flow._geoCol(flow.hoverColumn >= 0 ? flow.hoverColumn : 0).offset)) * Style.spacing.popupRowHeight - Style.space(28)
  }
}
