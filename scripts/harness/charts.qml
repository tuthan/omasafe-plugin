import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "components"

// T2 acceptance harness: instantiates UnitStrip, MeterBar and RankedBars off-screen,
// grabs the result to a PNG and quits. Run once per (theme, base size) pair with HOME
// pointed at a scratch state dir, so the user's live desktop theme is never touched.
ShellRoot {
  id: harness

  readonly property int base: Number(Quickshell.env("HARNESS_BASE") || "12")
  readonly property string out: Quickshell.env("HARNESS_OUT") || "/tmp/harness.png"

  FloatingWindow {
    id: win
    visible: true
    implicitWidth: 460
    implicitHeight: 760
    color: Color.background

    readonly property color fg: Color.foreground
    function dimStep(k) {
      var b = Color.background
      return Qt.rgba(fg.r * (1 - k) + b.r * k, fg.g * (1 - k) + b.g * k, fg.b * (1 - k) + b.b * k, 1)
    }
    readonly property color dim: dimStep(0.33)

    
    Rectangle {
      id: sheet
      color: Color.background
      width: Style.space(420) + Style.space(24)
      height: body.implicitHeight + Style.space(24)

    Column {
      id: body
      x: Style.space(12)
      y: Style.space(12)
      width: Style.space(420)
      spacing: Style.space(12)

      Text {
        text: "base " + Style.font.baseSize + " · " + Style.font.resolvedFamily
        color: win.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }

      // --- UnitStrip: 18 posture-shaped cells, then a 40-cell overflow case ---
      Text {
        text: "UNIT STRIP · 18 cells"
        color: win.dim; font.family: Style.font.family; font.pixelSize: Style.font.caption; font.bold: true
      }
      UnitStrip {
        width: parent.width
        cells: harness.postureCells
        foreground: win.fg; dim: win.dim
        fontFamily: Style.font.family; resolvedFamily: Style.font.resolvedFamily
      }
      Text {
        text: "UNIT STRIP · 40 cells (wrap, never scroll)"
        color: win.dim; font.family: Style.font.family; font.pixelSize: Style.font.caption; font.bold: true
      }
      UnitStrip {
        width: parent.width
        cells: harness.wideCells
        foreground: win.fg; dim: win.dim
        fontFamily: Style.font.family; resolvedFamily: Style.font.resolvedFamily
      }

      // --- MeterBar: 1-of-33 visibility, zero-vs-absent, empty track ---
      Text {
        text: "METER BAR · 1 of 33 must be visible"
        color: win.dim; font.family: Style.font.family; font.pixelSize: Style.font.caption; font.bold: true
      }
      MeterBar {
        width: parent.width
        total: 33
        segments: [
          { key: "critical", count: 0, level: "critical", label: "critical" },
          { key: "high", count: 1, level: "high", label: "high" },
          { key: "medium", count: 31, level: "medium", label: "medium" },
          { key: "low", count: 1, level: "low", label: "low" },
          { key: "info", count: 0, level: "info", label: "info" }
        ]
        foreground: win.fg; dim: win.dim; fontFamily: Style.font.family
      }
      Text {
        text: "0 critical · 1 high · 31 medium · 1 low · 0 info"
        color: win.fg; font.family: Style.font.family; font.pixelSize: Style.font.bodySmall
      }

      Text {
        text: "METER BAR · measured zero (empty track, zeros printed)"
        color: win.dim; font.family: Style.font.family; font.pixelSize: Style.font.caption; font.bold: true
      }
      MeterBar {
        width: parent.width
        total: 0
        segments: [
          { key: "critical", count: 0, level: "critical", label: "critical" },
          { key: "medium", count: 0, level: "medium", label: "medium" }
        ]
        foreground: win.fg; dim: win.dim; fontFamily: Style.font.family
      }
      Text {
        text: "0 critical · 0 high · 0 medium · 0 low · 0 info"
        color: win.fg; font.family: Style.font.family; font.pixelSize: Style.font.bodySmall
      }

      Text {
        text: "METER BAR · unavailable (no track at all, below this line)"
        color: win.dim; font.family: Style.font.family; font.pixelSize: Style.font.caption; font.bold: true
      }
      MeterBar {
        width: parent.width
        available: false
        total: 10
        segments: [{ key: "medium", count: 10, level: "medium", label: "medium" }]
        foreground: win.fg; dim: win.dim; fontFamily: Style.font.family
      }
      Text {
        text: "unavailable"
        color: win.dim; font.family: Style.font.family; font.pixelSize: Style.font.bodySmall
      }

      // --- RankedBars ---
      Text {
        text: "RANKED BARS · 7 rows, maxRows 5"
        color: win.dim; font.family: Style.font.family; font.pixelSize: Style.font.caption; font.bold: true
      }
      RankedBars {
        width: parent.width
        total: 44
        rows: [
          { label: "oma.qml.out-of-tree-reference", count: 31, level: "medium" },
          { label: "oma.qml.dynamic-reference", count: 1, level: "low" },
          { label: "oma.sh.eval", count: 6, level: "high" },
          { label: "oma.sh.curl-pipe", count: 3, level: "critical" },
          { label: "oma.json.manifest-drift", count: 1, level: "info" },
          { label: "oma.qml.loader-source", count: 1, level: "medium" },
          { label: "oma.qml.aaa-tiebreak", count: 1, level: "medium" }
        ]
        foreground: win.fg; dim: win.dim; fontFamily: Style.font.family
      }
    }

    }

    // shell.toml resets Style.fontBaseSize when the theme loads, so the harness
    // asserts the base AFTER that has settled, then waits a frame before grabbing.
    Timer {
      interval: 900
      running: true
      onTriggered: { Style.fontBaseSize = harness.base; settle.start() }
    }
    Timer {
      id: settle
      interval: 400
      onTriggered: {
        sheet.grabToImage(function(result) {
          result.saveToFile(harness.out)
          Qt.callLater(Qt.quit)
        })
      }
    }
  }

  readonly property var postureCells: [
    { key: "boot.secure_boot", glyph: "i", level: "info", tooltip: "Secure Boot · INFORMATIONAL" },
    { key: "encryption.root_luks", glyph: "✓", level: "healthy", tooltip: "Root LUKS · PASS" },
    { key: "execution.path", glyph: "✓", level: "healthy", tooltip: "Execution path · PASS" },
    { key: "firewall.configuration", glyph: "i", level: "info", tooltip: "Firewall configuration · INFORMATIONAL" },
    { key: "firewall.effective", glyph: "%", level: "incomplete", tooltip: "Effective firewall · INCOMPLETE" },
    { key: "firewall.service", glyph: "i", level: "info", tooltip: "Firewall service · INFORMATIONAL" },
    { key: "host.context", glyph: "✓", level: "healthy", tooltip: "Host context · PASS" },
    { key: "kernel.restart", glyph: "✓", level: "healthy", tooltip: "Kernel restart · PASS" },
    { key: "network.listeners", glyph: "i", level: "info", tooltip: "Listeners · INFORMATIONAL" },
    { key: "packages.foreign", glyph: "i", level: "info", tooltip: "Foreign packages · INFORMATIONAL" },
    { key: "packages.integrity", glyph: "_", level: "not_applicable", tooltip: "Package integrity · NOT APPLICABLE" },
    { key: "packages.keyring", glyph: "✓", level: "healthy", tooltip: "Keyring · PASS" },
    { key: "persistence.selected", glyph: "i", level: "info", tooltip: "Persistence · INFORMATIONAL" },
    { key: "ssh.configuration", glyph: "_", level: "not_applicable", tooltip: "SSH · NOT APPLICABLE" },
    { key: "updates.omarchy", glyph: "✓", level: "healthy", tooltip: "Omarchy updates · PASS" },
    { key: "updates.post_update_hook", glyph: "i", level: "info", tooltip: "Post-update hook · INFORMATIONAL" },
    { key: "updates.repository", glyph: "!", level: "high", tooltip: "Repository updates · REGRESSION" },
    { key: "vulnerabilities.arch_audit", glyph: "%", level: "incomplete", tooltip: "arch-audit · INCOMPLETE" }
  ]

  readonly property var wideCells: {
    var out = []
    var levels = ["healthy", "info", "incomplete", "not_applicable", "high", "critical", "none", "absent"]
    var glyphs = ["✓", "i", "%", "_", "!", "O", "·", "–"]
    for (var i = 0; i < 40; i++) {
      var k = i % levels.length
      out.push({ key: "check." + i, glyph: glyphs[k], level: levels[k], tooltip: "check " + i })
    }
    return out
  }
}
