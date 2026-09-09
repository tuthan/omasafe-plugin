import QtQuick
import qs.Commons
import qs.Ui
import "../model/Glyphs.js" as Glyphs
import "../model/Posture.js" as Posture

// One posture check, in the two shapes the tab uses (doc 08 §5.2). Collapsed it is a
// single line — mark, state word, title, and a right-aligned one-fact summary drawn
// from the first evidence string, so a collapsed check is still evidence and not a
// bare state word. Expanded it adds the evidence, the coverage limitation labelled
// `Not observed`, and the next step.
//
// The same component renders both, so an attention item and an expanded observed
// item cannot drift into two different layouts.
//
// Purely presentational: `check` is a normalised row from `model/Posture.js` and every
// word on screen comes from it. Nothing here derives a state, a count or a verdict.
Column {
  id: root

  property var check: null
  property bool expanded: false
  property var panel: null
  property string resolvedFamily: Style.font.resolvedFamily

  function col(name) { return panel ? panel[name] : Color.foreground }
  readonly property string _family: panel ? panel.fontFamily : Style.font.family

  // CLI 0.3.1 fields, both absent-safe (08 C1, C2). An absent field renders NOTHING
  // — never "no change", never "new", never an empty slot.
  readonly property string _changed: root.check ? Posture.changedFrom(root.check) : ""
  readonly property string _gapAge: root.check ? Posture.gapAgeText(root.check) : ""
  readonly property string _rightSlot: {
    if (root._gapAge !== "") return root._gapAge
    if (!root.expanded && root.check) return String(root.check.evidenceSummary || "")
    return ""
  }

  spacing: Style.space(2)

  // The identity line. Anchors, not computed widths: the right slot is capped at a
  // share of the row and elides, so a long evidence summary can never squeeze the
  // title — the leftmost column is identity and never yields to a number (08 §3.8).
  Item {
    id: line
    width: parent.width
    height: Math.max(mark.implicitHeight, titleText.implicitHeight, rightText.implicitHeight)

    SemanticMark {
      id: mark
      anchors.left: parent.left
      anchors.leftMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      compact: true
      level: root.check ? root.check.level : "unknown"
      labelOverride: root.check ? root.check.stateWord : ""
      foreground: root.col("fg"); dim: root.col("dim")
      fontFamily: root._family; resolvedFamily: root.resolvedFamily
    }

    // The word is always printed; colour and glyph only reinforce it (02 §2.4). On a
    // collapsed row the word lives in the mark's tooltip so the line stays one fact
    // wide, and the mark itself already differs per state.
    Text {
      id: stateText
      anchors.left: mark.right
      anchors.leftMargin: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
      visible: root.expanded
      // No explicit width: a Text's implicitWidth derives from its width, so binding
      // one to the other is a loop. `titleText` anchors past it when it is hidden.
      textFormat: Text.PlainText
      text: root.check ? root.check.stateWord : ""
      color: root.col("dim")
      font.family: root._family
      font.pixelSize: Style.font.caption
      font.bold: true
    }

    Text {
      id: rightText
      anchors.right: parent.right
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      visible: root._rightSlot !== ""
      width: visible ? Math.min(implicitWidth, Math.round(line.width * 0.46)) : 0
      textFormat: Text.PlainText
      text: root._rightSlot
      horizontalAlignment: Text.AlignRight
      elide: Text.ElideRight
      color: root.col("dim")
      font.family: root._family
      font.pixelSize: Style.font.caption
    }

    Text {
      id: titleText
      anchors.left: stateText.visible ? stateText.right : mark.right
      anchors.leftMargin: Style.space(6)
      anchors.right: rightText.visible ? rightText.left : parent.right
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: root.check ? root.check.title : ""
      color: root.col("fg")
      font.family: root._family
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
    }
  }

  // The delta. One mark and one sentence naming the previous state — no arrow, no
  // trend, no colour direction, because there is no ordering in which
  // `informational → pass` is "up".
  Row {
    x: Style.space(22)
    visible: root._changed !== ""
    spacing: Style.space(6)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: Glyphs.ui_("changed", root.resolvedFamily)
      color: root.col("dim")
      font.family: root._family
      font.pixelSize: Style.font.caption
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: root._changed
      color: root.col("dim")
      font.family: root._family
      font.pixelSize: Style.font.caption
    }
  }

  Text {
    width: parent.width - Style.space(30); x: Style.space(22)
    visible: root.expanded && root.check && root.check.evidence.length > 0
    textFormat: Text.PlainText
    text: root.check && root.check.evidence.length > 0 ? root.check.evidence.join("; ") : ""
    color: root.col("dim")
    font.family: root._family; font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

  // A check with no evidence at all says so, rather than showing an empty block that
  // could be read as "nothing found" — unless it carries a coverage limitation, which
  // already says the same thing and says it better.
  Text {
    width: parent.width - Style.space(30); x: Style.space(22)
    visible: root.expanded && root.check && root.check.evidence.length === 0 &&
      root.check.limitations.length === 0
    textFormat: Text.PlainText
    text: "No evidence was recorded for this check."
    color: root.col("dim")
    font.family: root._family; font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

  // Labelled detail lines. The label takes its natural width and the value takes the
  // rest, so a label can never overrun a fixed column at a larger base size and a
  // value never wraps earlier than it must. `Not observed`, not `Coverage limitation`:
  // the reader needs to know what was NOT looked at, in those words.
  Item {
    width: parent.width - Style.space(30); x: Style.space(22)
    visible: root.expanded && root.check && root.check.limitations.length > 0
    height: visible ? notObservedValue.implicitHeight : 0

    Text {
      id: notObservedLabel
      anchors { left: parent.left; top: parent.top }
      textFormat: Text.PlainText
      text: "Not observed"
      color: root.col("fg")
      font.family: root._family; font.pixelSize: Style.font.caption
    }
    Text {
      id: notObservedValue
      anchors { left: notObservedLabel.right; leftMargin: Style.space(8); right: parent.right; top: parent.top }
      textFormat: Text.PlainText
      text: root.check && root.check.limitations.length > 0 ? root.check.limitations.join("; ") : ""
      color: root.col("dim")
      font.family: root._family; font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
  }

  Item {
    width: parent.width - Style.space(30); x: Style.space(22)
    visible: root.expanded && root.check && root.check.nextStep !== ""
    height: visible ? nextStepValue.implicitHeight : 0

    Text {
      id: nextStepLabel
      anchors { left: parent.left; top: parent.top }
      textFormat: Text.PlainText
      text: "Next step"
      color: root.col("fg")
      font.family: root._family; font.pixelSize: Style.font.caption
    }
    Text {
      id: nextStepValue
      anchors { left: nextStepLabel.right; leftMargin: Style.space(8); right: parent.right; top: parent.top }
      textFormat: Text.PlainText
      text: root.check ? root.check.nextStep : ""
      color: root.col("dim")
      font.family: root._family; font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
  }
}
