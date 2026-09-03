import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

// The confirmation sheet (doc 03 §10, 02 §3.7). It keeps the kit ConfirmDialog
// contract — opened, handleKey(event), canceled(), confirmed(), the scrim, the card
// BorderSurface and the button chrome of Ui/ConfirmDialog.qml:96–130 — and departs
// from it in the ways GR6 requires:
//   • selectedIndex starts at 0 (Cancel; the kit defaults to 1);
//   • a title + action-specific identity InfoGrid + body replace the single message;
//   • an optional policy ButtonGroup with a one-line definition;
//   • `destructive` is per kind, applied to the confirm button, not index-based;
//   • the card has a height cap with a scrolling middle so Cancel/confirm are never
//     pushed off a short screen;
//   • the button MouseAreas do NOT pre-select on hover (a parked pointer must not
//     flip the selection to confirm on open);
//   • a held Return/Enter cannot confirm: auto-repeat activations are dropped and a
//     non-repeat Return/Enter is ignored for the first 300 ms after open.
Item {
  id: sheet

  property bool opened: false
  property string title: ""
  property string body: ""
  property var infoRows: []
  property real labelWidth: Style.space(72)

  property bool showPolicy: false
  property string policyValue: "advisory"
  property string policyDefinition: ""

  property string confirmLabel: "Confirm"
  property string cancelLabel: "Cancel"
  property bool destructive: false
  property bool busy: false

  property color foreground: Color.foreground
  property color dim: Color.foreground
  property color urgent: Color.urgent
  property string fontFamily: Style.font.family
  // Where focus returns when the sheet closes (the panel key catcher).
  property Item returnFocusItem: null

  // 0 = Cancel, 1 = confirm. Cancel is pre-selected on every open.
  property int selectedIndex: 0
  // "policy" | "buttons" — which section j/k has landed on.
  property string section: "buttons"
  property int policyIndex: 0
  property double openedAt: 0

  readonly property var policyOptions: [
    { value: "advisory", label: "Advisory" },
    { value: "hardened", label: "Hardened" }
  ]

  signal canceled()
  signal confirmed()
  signal policyChanged(string value)

  anchors.fill: parent
  visible: opened
  focus: opened
  z: 20

  onOpenedChanged: {
    if (opened) {
      selectedIndex = 0
      section = "buttons"
      policyIndex = policyValue === "hardened" ? 1 : 0
      openedAt = Date.now()
      forceActiveFocus()
    } else if (returnFocusItem) {
      returnFocusItem.forceActiveFocus()
    }
  }

  function _commitPolicy(idx) {
    policyIndex = idx < 0 ? 0 : (idx > 1 ? 1 : idx)
    policyChanged(policyOptions[policyIndex].value)
  }

  // Extended handleKey (doc 03 §10): Up/Down/j/k switch section; Left/Right/h/l/Tab
  // move within the focused section; Enter on policy selects the chip and moves to
  // the buttons (never confirms); Enter on buttons fires the selected button; Esc
  // cancels; every other key is accepted and ignored so nothing leaks to the catcher.
  function handleKey(event) {
    if (!sheet.opened) return true
    // While the operation runs, the sheet is inert to the keyboard too — Enter must not
    // cancel or re-confirm a mutation in flight (Phase 1 invariant 9). Everything is
    // accepted and ignored so nothing leaks to the catcher.
    if (sheet.busy) return true
    var k = event.key
    if (k === Qt.Key_Escape) { sheet.canceled(); return true }

    if (k === Qt.Key_Down || event.text === "j") {
      if (sheet.showPolicy && sheet.section === "policy") sheet.section = "buttons"
      return true
    }
    if (k === Qt.Key_Up || event.text === "k") {
      if (sheet.showPolicy && sheet.section === "buttons") sheet.section = "policy"
      return true
    }

    var left = k === Qt.Key_Left || event.text === "h" || k === Qt.Key_Backtab
    var right = k === Qt.Key_Right || event.text === "l" || k === Qt.Key_Tab
    if (left || right) {
      if (sheet.section === "policy") sheet._commitPolicy(left ? 0 : 1)
      else sheet.selectedIndex = sheet.selectedIndex === 0 ? 1 : 0
      return true
    }

    if (k === Qt.Key_Return || k === Qt.Key_Enter) {
      if (sheet.section === "policy") {
        sheet._commitPolicy(sheet.policyIndex)
        sheet.section = "buttons"
      } else if (sheet.selectedIndex === 0) {
        sheet.canceled()
      } else {
        sheet.confirmed()
      }
      return true
    }

    // Space and everything else: accepted and ignored (nothing reaches the catcher).
    return true
  }

  Keys.onPressed: function(event) {
    // Held-key stop (doc 03 §10 invariant 2): drop any auto-repeat activation, and
    // ignore a non-repeat Return/Enter for the first 300 ms after open, so a held
    // Enter that opened the sheet cannot immediately fire a button.
    if (event.isAutoRepeat && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
        || event.key === Qt.Key_Space)) {
      event.accepted = true
      return
    }
    if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
        && (Date.now() - sheet.openedAt) < 300) {
      event.accepted = true
      return
    }
    event.accepted = sheet.handleKey(event)
  }

  // Scrim: swallows clicks and the wheel so nothing behind reacts (doc 03 §10 inv 6).
  Rectangle {
    anchors.fill: parent
    color: Util.alpha(Color.background, 0.7)

    // The scrim swallows clicks and the wheel and does nothing (Phase 1 invariant 6):
    // no bypass path, and a stray click cannot cancel a pending or in-flight action.
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.AllButtons
      onClicked: {}
      onWheel: function(wheel) { wheel.accepted = true }
    }

    BorderSurface {
      id: card
      width: Math.min(parent.width - Style.space(32), Style.space(370))
      height: Math.min(implicitHeight, parent.height - Style.space(32))
      implicitHeight: card.contentTopInset + card.contentBottomInset +
        contentColumn.implicitHeight + Style.space(10) + Style.space(34)
      anchors.centerIn: parent
      color: Color.background
      borderSpec: Border.flat(Color.accent, Style.normalBorderWidth)
      padding: Style.space(18)
      radius: Style.cornerRadius

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset

        // Title + identity + policy + body scroll; the button row stays anchored.
        Flickable {
          id: cardFlick
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: buttonRow.top
          anchors.bottomMargin: Style.space(10)
          contentWidth: width
          contentHeight: contentColumn.implicitHeight
          clip: true
          interactive: contentHeight > height
          boundsBehavior: Flickable.StopAtBounds
          ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

          Column {
            id: contentColumn
            width: cardFlick.width
            spacing: Style.space(10)

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: sheet.title
              color: sheet.foreground
              font.family: sheet.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              wrapMode: Text.WordWrap
            }

            InfoGrid {
              width: parent.width
              rows: sheet.infoRows
              labelWidth: sheet.labelWidth
              foreground: sheet.foreground
              labelColor: sheet.dim
              fontFamily: sheet.fontFamily
            }

            Column {
              width: parent.width
              visible: sheet.showPolicy
              spacing: Style.space(4)

              ButtonGroup {
                id: policyGroup
                width: parent.width
                options: sheet.policyOptions
                value: sheet.policyValue
                focusable: false
                cursorIndex: sheet.section === "policy" ? sheet.policyIndex : -1
                fontSize: Style.font.bodySmall
                foreground: sheet.foreground
                fontFamily: sheet.fontFamily
                onChanged: function(v) {
                  sheet.policyIndex = v === "hardened" ? 1 : 0
                  sheet.policyChanged(v)
                }
                onHovered: function(index, isHovered) {
                  if (isHovered) sheet.section = "policy"
                }
              }

              Text {
                width: parent.width
                textFormat: Text.PlainText
                text: sheet.policyDefinition
                color: sheet.dim
                font.family: sheet.fontFamily
                font.pixelSize: Style.font.bodySmall
                wrapMode: Text.WordWrap
              }
            }

            Text {
              width: parent.width
              visible: sheet.body !== ""
              textFormat: Text.PlainText
              text: sheet.body
              color: sheet.foreground
              font.family: sheet.fontFamily
              font.pixelSize: Style.font.body
              wrapMode: Text.WordWrap
            }
          }
        }

        Row {
          id: buttonRow
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          spacing: Style.space(10)

          Repeater {
            model: [sheet.cancelLabel, sheet.busy ? "Working…" : sheet.confirmLabel]

            delegate: BorderSurface {
              id: btn
              required property int index
              required property string modelData

              // Selection only paints while the cursor is on the button row; on the
              // policy section neither button is highlighted (doc 03 §10).
              readonly property bool isSelected: sheet.section === "buttons" && sheet.selectedIndex === index
              // Destructive chrome is per kind, on the confirm button only.
              readonly property bool isDestructive: index === 1 && sheet.destructive

              width: Math.max(Style.space(88), btnLabel.implicitWidth + Style.space(28))
              height: Style.space(34)
              radius: 0
              color: btn.isSelected
                ? (btn.isDestructive ? Util.alpha(sheet.urgent, 0.22) : Util.alpha(sheet.foreground, 0.08))
                : "transparent"
              borderSpec: Border.flat(btn.isDestructive
                ? (btn.isSelected ? sheet.urgent : Util.alpha(sheet.urgent, 0.56))
                : (btn.isSelected ? Color.accent : Util.alpha(sheet.foreground, 0.38)), Style.normalBorderWidth)
              opacity: sheet.busy ? 0.6 : 1.0

              Text {
                id: btnLabel
                anchors.centerIn: parent
                textFormat: Text.PlainText
                text: btn.modelData
                color: btn.isDestructive
                  ? (btn.isSelected ? sheet.urgent : sheet.foreground)
                  : (btn.isSelected ? Color.accent : sheet.foreground)
                font.family: sheet.fontFamily
                font.pixelSize: Style.font.body
              }

              MouseArea {
                anchors.fill: parent
                enabled: !sheet.busy
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                // No onEntered pre-select: a click fires the action directly and
                // leaves selectedIndex alone (doc 03 §10 invariant 3).
                onClicked: {
                  if (btn.index === 0) sheet.canceled()
                  else sheet.confirmed()
                }
              }
            }
          }
        }
      }
    }
  }
}
