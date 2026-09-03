import QtQuick
import QtQuick.Shapes
import qs.Commons

// EdgeLayer — the Bézier edges of the Trust Flow graph (doc 04 T3.4, §10.2).
// One Shape holding EIGHT static ShapePath buckets (ShapePath is not an Item, so a
// Repeater cannot generate them — the Ui/BorderOverlay.qml:51 technique). The path
// strings are written by FlowLayout.bucket() / hot(); an empty string costs nothing.
// Nodes and paths share the TrustFlow root coordinate space and rowCenter() already
// includes headerH, so this layer has no top margin. No timer and none of the banned
// GPU effects — just eight static stroked paths.
Shape {
  id: root

  property var paths: ({})                       // FlowLayout.bucket() output
  // Resting-state (dim) edges are hidden by default (T4.1): an all-edges graph is
  // anonymous spaghetti before the reader has asked a question. Only the hot buckets —
  // a cursor's one-hop edges and a pin's connected path — draw. Flip showRest to reveal
  // the full weave as faint context.
  property bool showRest: false
  property color foreground: Color.foreground
  readonly property color dimStroke: Util.alpha(foreground, Style.hoverBorderAlpha)
  readonly property color hotStroke: Util.alpha(foreground, 0.9)

  preferredRendererType: Shape.CurveRenderer

  component Bucket: ShapePath { fillColor: "transparent"; capStyle: ShapePath.RoundCap }
  component Dashed: Bucket { strokeStyle: ShapePath.DashLine; dashPattern: [4, 4] }

  Bucket {
    strokeWidth: Math.max(1, Style.space(1)); strokeColor: root.dimStroke
    PathSvg { path: root.showRest ? (root.paths.dimThinSolid || "") : "" }
  }
  Dashed {
    strokeWidth: Math.max(1, Style.space(1)); strokeColor: root.dimStroke
    PathSvg { path: root.showRest ? (root.paths.dimThinDashed || "") : "" }
  }
  Bucket {
    strokeWidth: Math.max(1, Style.space(2)); strokeColor: root.dimStroke
    PathSvg { path: root.showRest ? (root.paths.dimMedSolid || "") : "" }
  }
  Dashed {
    strokeWidth: Math.max(1, Style.space(2)); strokeColor: root.dimStroke
    PathSvg { path: root.showRest ? (root.paths.dimMedDashed || "") : "" }
  }
  Bucket {
    strokeWidth: Math.max(1, Style.space(3)); strokeColor: root.dimStroke
    PathSvg { path: root.showRest ? (root.paths.dimThickSolid || "") : "" }
  }
  Dashed {
    strokeWidth: Math.max(1, Style.space(3)); strokeColor: root.dimStroke
    PathSvg { path: root.showRest ? (root.paths.dimThickDashed || "") : "" }
  }
  Bucket {
    strokeWidth: Math.max(1, Style.space(2)); strokeColor: root.hotStroke
    Behavior on strokeColor { ColorAnimation { duration: 120 } }
    PathSvg { path: root.paths.hotSolid || "" }
  }
  Dashed {
    strokeWidth: Math.max(1, Style.space(2)); strokeColor: root.hotStroke
    Behavior on strokeColor { ColorAnimation { duration: 120 } }
    PathSvg { path: root.paths.hotDashed || "" }
  }
}
