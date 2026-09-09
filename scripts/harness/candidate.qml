import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "views"
import "model/Candidate.js" as Candidate

// Source Scan acceptance harness (v0.3.1 T5, T6). It instantiates the REAL
// `views/CandidateView.qml` against a captured `omasafe.report.v1` review report,
// with a stub standing in for the Panel.qml root.
//
// The Source Scan tab needs a network scan and a human paste to reach its result
// state in the running shell, so this is the only way to exercise the result band
// end to end on every theme and base size. The stub is also the written-down
// contract between CandidateView and the panel.
ShellRoot {
  id: harness

  readonly property int base: Number(Quickshell.env("HARNESS_BASE") || "12")
  readonly property string out: Quickshell.env("HARNESS_OUT") || "/tmp/candidate.png"
  readonly property string fixture: Quickshell.env("HARNESS_FIXTURE") || ""
  // A full result view with 32 finding blocks is ~9,000 units tall, which at 2x DPI
  // exceeds the 16,384 px maximum texture size and produces a silently clipped grab.
  // The band is what this harness is for, so the sheet is clipped to it by default.
  readonly property int clipUnits: Number(Quickshell.env("HARNESS_CLIP") || "900")

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

    QtObject {
      id: panelStub

      property color fg: win.fg
      property color urgent: Color.urgent
      property color dimHeader: win.dimStep(0.25)
      property color dim: win.dimStep(0.33)
      property color faint: win.dimStep(0.55)
      property color selectedFill: Style.selectedFillFor(win.fg, Color.accent)
      property string fontFamily: Style.font.family

      readonly property var candidateModel: harness.report ? Candidate.build(harness.report) : null
      property string candidateState: "ready"
      property string candidateInput: ""
      property string candidateError: ""
      property bool candidateCanRun: true
      property bool candidateProcessRunning: false

      property bool navigationLocked: false
      property bool cursorActive: false
      property string focusSection: "hero"
      property int selectedIndex: 0
      property var candidateExpandedFindings: ({})

      function candidateCopyActions() { return Candidate.copyActions(candidateModel) }
      function candidatePerformCopy(index) { }
      function candidateFindingExpanded(index) { return candidateExpandedFindings[String(index)] === true }
      function candidateToggleFinding(index) {
        var next = {}, key
        for (key in candidateExpandedFindings) next[key] = candidateExpandedFindings[key]
        next[String(index)] = !(next[String(index)] === true)
        candidateExpandedFindings = next
      }
      function hoverCursor(section, index) {
        cursorActive = true; focusSection = section; selectedIndex = index
      }
      function ensureCursorVisible(item) { }

      function candidateProgressText() { return "Scanning plugin source…" }
      function leaveSourceScan() { }
      function runCandidate() { }
      function cancelCandidate() { }
      function copyValue(v) { }
      function copyCandidateCommand() { }
    }

    Rectangle {
      id: sheet
      color: Color.background
      clip: true
      width: Style.space(420) + Style.space(16)
      height: Math.min(view.implicitHeight + Style.space(16), Style.space(harness.clipUnits))

      CandidateView {
        id: view
        x: Style.space(8)
        y: Style.space(8)
        width: Style.space(420)
        panel: panelStub
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
        var model = panelStub.candidateModel
        console.log("harness: ok=" + (model && model.ok) +
          (model && model.ok
            ? (" findings=" + model.summary.severityTotal +
               " rules=" + model.summary.ruleRows.length +
               " capsComplete=" + model.summary.capabilitiesComplete +
               " coverage=" + model.summary.coverageTotal +
               " reconcile=" + JSON.stringify(model.summary.reconciliationNotice || ""))
            : (" error=" + (model ? model.error : "no model"))) +
          " viewHeight=" + Math.round(view.implicitHeight))
        sheet.grabToImage(function(result) {
          result.saveToFile(harness.out)
          Qt.callLater(Qt.quit)
        })
      }
    }
  }
}
