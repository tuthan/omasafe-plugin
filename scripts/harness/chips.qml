import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "components"

// View-chip row acceptance harness. The compact panel body is 420 units wide and the
// kit `ButtonGroup` is a plain `Row` — it does not wrap, elide or shrink — so a chip
// label that grows by two characters can push the row off the panel with nothing on
// screen saying so. This measures the row at each base size and draws the 420-unit
// edge, so overflow is a number and a picture rather than an estimate.
ShellRoot {
  id: harness

  readonly property int base: Number(Quickshell.env("HARNESS_BASE") || "12")
  readonly property string out: Quickshell.env("HARNESS_OUT") || "/tmp/chips.png"
  readonly property int panelWidth: 420
  // The chips do NOT get `Style.space(420)`. The kit panel puts `popupPadding` inside
  // its contentWidth and a border outside that, so the fixed column is narrower than
  // the number the panel is configured with. Measuring against 420 is what let a
  // two-character label change ship as an overflow.
  readonly property real usableWidth:
    Style.space(panelWidth) - 2 * Style.spacing.popupPadding - 2 * Style.normalBorderWidth

  // Each variant is a candidate labelling scheme. They are measured together so the
  // cost of a change is visible against the alternatives rather than on its own.
  // The five tabs, with the counts the captured report produces.
  readonly property var tabOptions: [
    { value: "overview", label: "Plugins", count: "2" },
    { value: "flow", label: "Analysis", count: "" },
    { value: "rules", label: "Rules", count: "" },
    { value: "posture", label: "Posture", count: "3" },
    { value: "source-scan", label: "Source Scan", count: "" }
  ]
  function withScanLabel(text) {
    var out = []
    for (var i = 0; i < tabOptions.length; i++) {
      out.push({ value: tabOptions[i].value, label: i === 4 ? text : tabOptions[i].label,
                 count: tabOptions[i].count })
    }
    return out
  }

  // SHIPPED is the configuration Panel.qml uses. It must read "one line" on every
  // theme and every base size; the rest are the alternatives it was chosen over, kept
  // so the next person changing a label can see what the row costs.
  readonly property var variants: [
    { name: "SHIPPED md-padding, Source", opts: withScanLabel("Source"), pad: Style.spacing.md },
    { name: "alt kit-padding, Source", opts: withScanLabel("Source"), pad: Style.spacing.controlPaddingX },
    { name: "alt md-padding, Source Scan", opts: tabOptions, pad: Style.spacing.md },
    { name: "was kit-padding, Source Scan", opts: tabOptions, pad: Style.spacing.controlPaddingX },
    { name: "realmax two-digit counts", opts: [
        { value: "a", label: "Plugins", count: "12" }, { value: "b", label: "Analysis", count: "" },
        { value: "c", label: "Rules", count: "" }, { value: "d", label: "Posture", count: "18" },
        { value: "e", label: "Source", count: "" }], pad: Style.spacing.md },
    { name: "worst all-counted", opts: [
        { value: "a", label: "Plugins", count: "12" }, { value: "b", label: "Analysis", count: "·" },
        { value: "c", label: "Rules", count: "·" }, { value: "d", label: "Posture", count: "18" },
        { value: "e", label: "Source", count: "·" }], pad: Style.spacing.md }
  ]

  FloatingWindow {
    id: win
    visible: true
    color: Color.background

    Rectangle {
      id: sheet
      color: Color.background
      width: Style.space(harness.panelWidth) + Style.space(60)
      height: body.implicitHeight + Style.space(16)

      Column {
        id: body
        x: Style.space(8)
        y: Style.space(8)
        width: Style.space(harness.panelWidth)
        spacing: Style.space(10)

        Text {
          text: "base " + Style.font.baseSize + " · panel " + Style.space(harness.panelWidth) +
            "px · usable " + Math.round(harness.usableWidth) + "px (popupPadding " +
            Style.spacing.popupPadding + " x2)"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }

        Repeater {
          id: measured
          model: harness.variants

          delegate: Column {
            required property var modelData
            width: parent.width
            spacing: Style.space(2)

            readonly property real rowWidth: group.unwrappedWidth
            readonly property real overflow: rowWidth - harness.usableWidth
            readonly property bool wrapped: group.wrapped

            Text {
              text: modelData.name + " — " + Math.round(parent.rowWidth) + "px" +
                (parent.wrapped ? "  WRAPPED +" + Math.round(parent.overflow)
                                : "  one line, " + Math.round(-parent.overflow) + " spare")
              color: parent.wrapped ? Color.urgent : Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            // The REAL component, at the real usable width, so a wrap shows up here
            // as a second line rather than as a clip in the shipped panel.
            ViewChips {
              id: group
              width: harness.usableWidth
              options: modelData.opts
              chipPadding: modelData.pad
              value: "posture"
              cursorIndex: -1
              fontSize: Style.font.bodySmall
              foreground: Color.foreground
              fontFamily: Style.font.family
            }
          }
        }
      }

      // The real content edge. Anything to its right is clipped in compact mode.
      Rectangle {
        x: Style.space(8) + harness.usableWidth
        width: Math.max(1, Style.space(1))
        height: sheet.height
        color: Color.urgent
      }
    }

    Timer {
      interval: 1100
      running: true
      onTriggered: { Style.fontBaseSize = harness.base; settle.start() }
    }
    Timer {
      id: settle
      interval: 500
      onTriggered: {
        var line = "chips: base=" + Style.font.baseSize +
          " panel=" + Style.space(harness.panelWidth) +
          " popupPadding=" + Style.spacing.popupPadding +
          " usable=" + Math.round(harness.usableWidth) + " |"
        for (var i = 0; i < measured.count; i++) {
          var it = measured.itemAt(i)
          if (it) line += " " + harness.variants[i].name.split(" ")[0] + "=" +
            Math.round(it.rowWidth) + (it.wrapped ? "!" : "")
        }
        console.log(line)
        sheet.grabToImage(function(result) {
          result.saveToFile(harness.out)
          Qt.callLater(Qt.quit)
        })
      }
    }
  }
}
