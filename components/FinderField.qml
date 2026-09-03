import QtQuick
import qs.Commons
import qs.Ui

// The finder input (doc 03 §8): a kit TextField shown and focused by `/`. The panel
// binds keyCatcher.blocked to this field's activeFocus. Up/Down move the result
// cursor, Enter opens the current result, Esc clears and refocuses the catcher; Tab
// and Backtab are accepted as a NO-OP so an unaccepted Tab cannot bubble to the
// blocked catcher and let Qt's focus chain move activeFocus off the field.
TextField {
  id: root

  placeholderText: "plugin, capability, rule or baseline id"
  font.pixelSize: Style.font.bodySmall

  signal submitted()
  signal dismissed()
  signal moveResult(int delta)

  Keys.priority: Keys.BeforeItem
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Up) { root.moveResult(-1); event.accepted = true }
    else if (event.key === Qt.Key_Down) { root.moveResult(1); event.accepted = true }
    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.submitted(); event.accepted = true }
    else if (event.key === Qt.Key_Escape) { root.dismissed(); event.accepted = true }
    else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) { event.accepted = true }
  }
}
