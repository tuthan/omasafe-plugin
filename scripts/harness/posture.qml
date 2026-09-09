import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "views"
import "model/Posture.js" as Posture

// Posture-tab acceptance harness (v0.3.1 T4). It instantiates the REAL
// `views/PostureView.qml` against the captured `omasafe.posture.v1` report, with a
// stub standing in for the Panel.qml root.
//
// This exists because `qmllint` does not catch a missing `QtQuick.Controls` import
// or a bad kit-property assign, and because the panel body only instantiates when a
// human opens the panel — so a clean shell restart proves nothing about this view.
// Instantiating it here exercises the same QML the shell would.
//
// The stub below is also the written-down contract between PostureView and the
// panel: everything the view reads off `panel` appears in it.
ShellRoot {
  id: harness

  readonly property int base: Number(Quickshell.env("HARNESS_BASE") || "12")
  readonly property string out: Quickshell.env("HARNESS_OUT") || "/tmp/posture.png"
  readonly property string fixture: Quickshell.env("HARNESS_FIXTURE") || ""
  // The compact panel body: 420 units wide. A rule is drawn at 420 units down so the
  // "above the fold" acceptance can be read off the image.
  readonly property int foldHeight: 420

  property var report: null

  FileView {
    id: reportFile
    path: harness.fixture
    onLoaded: {
      try { harness.report = JSON.parse(text()) }
      catch (e) { console.log("harness: fixture parse failed: " + e) }
    }
  }

  FloatingWindow {
    id: win
    visible: true
    color: Color.background

    readonly property color fg: Color.foreground
    function dimStep(k) {
      var b = Color.background
      return Qt.rgba(fg.r * (1 - k) + b.r * k, fg.g * (1 - k) + b.g * k, fg.b * (1 - k) + b.b * k, 1)
    }

    // ---- the Panel.qml stand-in: every property and function PostureView reads ----
    QtObject {
      id: panelStub

      property color fg: win.fg
      property color urgent: Color.urgent
      property color dimHeader: win.dimStep(0.25)
      property color dim: win.dimStep(0.33)
      property color faint: win.dimStep(0.55)
      property string fontFamily: Style.font.family

      property bool cliVerified: true
      property bool navigationLocked: false
      property var postureReport: harness.report
      property bool postureLoading: false
      property string postureError: ""
      readonly property var postureModel: Posture.build(postureReport)

      property bool cursorActive: false
      property string focusSection: "hero"
      property int selectedIndex: 0

      property var postureExpandedChecks: ({})
      property var postureCollapsedGroups: ({})
      property bool postureHostExpanded: false

      function postureCheckExpanded(id) { return postureExpandedChecks[String(id)] === true }
      function postureToggleCheck(id) {
        var next = {}, key
        for (key in postureExpandedChecks) next[key] = postureExpandedChecks[key]
        next[String(id)] = !(next[String(id)] === true)
        postureExpandedChecks = next
      }
      function postureGroupCollapsed(domain) { return postureCollapsedGroups[String(domain)] === true }
      function postureToggleGroup(domain) {
        var next = {}, key
        for (key in postureCollapsedGroups) next[key] = postureCollapsedGroups[key]
        next[String(domain)] = !(next[String(domain)] === true)
        postureCollapsedGroups = next
      }
      function postureObservedRows() {
        var model = postureModel
        if (!model || !model.available) return []
        var out = []
        for (var g = 0; g < model.groups.length; g++) {
          if (postureGroupCollapsed(model.groups[g].domain)) continue
          for (var c = 0; c < model.groups[g].checks.length; c++) out.push(model.groups[g].checks[c])
        }
        return out
      }
      function postureCommandInStep(text) {
        var match = /`([^`]{1,256})`/.exec(String(text || ""))
        return match ? match[1] : ""
      }
      function postureCopyActions() {
        var model = postureModel
        if (!model || !model.available) return []
        var out = []
        for (var i = 0; i < model.attention.length; i++) {
          var command = postureCommandInStep(model.attention[i].nextStep)
          if (command === "") continue
          out.push({
            checkId: model.attention[i].id, value: command,
            label: command.indexOf(" ") >= 0 ? "Copy command" : "Copy tool name",
            tooltip: model.attention[i].title + " — copies `" + command + "`. OmaSafe never runs it."
          })
        }
        return out
      }
      function posturePerformCopy(index) { }
      function postureRevealCheck(index) { }
      function hoverCursor(section, index) {
        cursorActive = true; focusSection = section; selectedIndex = index
      }
      function ensureCursorVisible(item) { }
      function runPostureScan() { }
    }

    Rectangle {
      id: sheet
      color: Color.background
      width: Style.space(420) + Style.space(16)
      height: view.implicitHeight + Style.space(16)

      PostureView {
        id: view
        x: Style.space(8)
        y: Style.space(8)
        width: Style.space(420)
        panel: panelStub
      }

      // The fold: everything above this line is on screen without scrolling in the
      // compact panel.
      Rectangle {
        y: Style.space(8) + Style.space(harness.foldHeight)
        width: parent.width
        height: Math.max(1, Style.space(1))
        color: Color.urgent
        visible: y < sheet.height
      }
      Text {
        y: Style.space(8) + Style.space(harness.foldHeight) + Style.space(2)
        x: Style.space(8)
        text: "^ fold: " + harness.foldHeight + " units"
        color: Color.urgent
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        visible: y < sheet.height
      }
    }

    // shell.toml resets Style.fontBaseSize when the theme loads, so assert the base
    // after that has settled, then wait a frame before grabbing.
    Timer {
      interval: 1100
      running: true
      onTriggered: { Style.fontBaseSize = harness.base; settle.start() }
    }
    Timer {
      id: settle
      interval: 500
      onTriggered: {
        console.log("harness: available=" + panelStub.postureModel.available +
          " checks=" + panelStub.postureModel.checkTotal +
          " attention=" + panelStub.postureModel.attention.length +
          " groups=" + panelStub.postureModel.groups.length +
          " viewHeight=" + Math.round(view.implicitHeight) +
          " units=" + Math.round(view.implicitHeight / Style.space(1)))
        sheet.grabToImage(function(result) {
          result.saveToFile(harness.out)
          Qt.callLater(Qt.quit)
        })
      }
    }
  }
}
