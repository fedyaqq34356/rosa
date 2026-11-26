import QtQuick
import QtQuick.Shapes as Vec
import "root:/design"

Item {
    id: g

    property string mode: "speaker"
    property bool muted: false
    property bool fromMuted: false
    property color ink: "white"
    property color cut: Qt.rgba(0, 0, 0, 0.35)

    implicitWidth: 24
    implicitHeight: 24

    readonly property real u: Math.min(g.width, g.height) / 24
    readonly property real ox: (g.width - 24 * g.u) / 2
    readonly property real oy: (g.height - 24 * g.u) / 2
    function px(v) { return g.ox + v * g.u; }
    function py(v) { return g.oy + v * g.u; }
    function clamp01(v) { return Math.max(0, Math.min(1, v)); }
    function ease(v) { const t = g.clamp01(v); return t * t * (3 - 2 * t); }

    MorphSpring {
        id: m
        target: g.muted ? 1 : 0
        response: 0.62
        damping: 1
        springBack: true
    }

    Component.onCompleted: {
        m.settle(g.muted ? 0 : (g.fromMuted ? 1 : 0));
        m.target = Qt.binding(() => g.muted ? 1 : 0);
    }

    readonly property real k: m.value
    readonly property real wave2: 1 - g.ease(g.k / 0.4)
    readonly property real wave1: 1 - g.ease((g.k - 0.15) / 0.4)
    readonly property real slash: g.ease((g.k - 0.3) / 0.7)
    readonly property real w: 2.1 * g.u

    Vec.Shape {
        anchors.fill: parent
        preferredRendererType: Vec.Shape.CurveRenderer
        visible: g.mode === "speaker"

        Vec.ShapePath {
            fillColor: g.ink
            strokeColor: g.ink
            strokeWidth: g.u * 1.2
            joinStyle: Vec.ShapePath.RoundJoin
            startX: g.px(3.5); startY: g.py(9.2)
            PathLine { x: g.px(7.2);  y: g.py(9.2) }
            PathLine { x: g.px(11.6); y: g.py(5.0) }
            PathLine { x: g.px(11.6); y: g.py(19.0) }
            PathLine { x: g.px(7.2);  y: g.py(14.8) }
            PathLine { x: g.px(3.5);  y: g.py(14.8) }
            PathLine { x: g.px(3.5);  y: g.py(9.2) }
        }

        Vec.ShapePath {
            fillColor: "transparent"
            strokeColor: Colors.alpha(g.ink, g.wave1)
            strokeWidth: g.w
            capStyle: Vec.ShapePath.RoundCap
            PathAngleArc {
                centerX: g.px(11.6); centerY: g.py(12)
                radiusX: g.u * (2.2 + 2.4 * g.wave1); radiusY: radiusX
                startAngle: -48 * g.wave1; sweepAngle: 96 * g.wave1
            }
        }

        Vec.ShapePath {
            fillColor: "transparent"
            strokeColor: Colors.alpha(g.ink, g.wave2)
            strokeWidth: g.w
            capStyle: Vec.ShapePath.RoundCap
            PathAngleArc {
                centerX: g.px(11.6); centerY: g.py(12)
                radiusX: g.u * (4.2 + 4.0 * g.wave2); radiusY: radiusX
                startAngle: -52 * g.wave2; sweepAngle: 104 * g.wave2
            }
        }
    }

    Vec.Shape {
        anchors.fill: parent
        preferredRendererType: Vec.Shape.CurveRenderer
        id: micShape
        visible: g.mode === "mic"

        readonly property real dim: 1 - 0.35 * g.slash

        Vec.ShapePath {
            fillColor: Colors.alpha(g.ink, micShape.dim)
            strokeColor: "transparent"
            PathRectangle {
                x: g.px(8.8); y: g.py(2.8)
                width: 6.4 * g.u; height: 11.4 * g.u
                radius: 3.2 * g.u
            }
        }

        Vec.ShapePath {
            fillColor: "transparent"
            strokeColor: Colors.alpha(g.ink, micShape.dim)
            strokeWidth: g.w
            capStyle: Vec.ShapePath.RoundCap
            PathAngleArc {
                centerX: g.px(12); centerY: g.py(10.6)
                radiusX: 6.2 * g.u; radiusY: radiusX
                startAngle: 0; sweepAngle: 180
            }
        }

        Vec.ShapePath {
            fillColor: "transparent"
            strokeColor: Colors.alpha(g.ink, micShape.dim)
            strokeWidth: g.w
            capStyle: Vec.ShapePath.RoundCap
            startX: g.px(12); startY: g.py(16.8)
            PathLine { x: g.px(12); y: g.py(20.6) }
            PathMove { x: g.px(8.6); y: g.py(20.6) }
            PathLine { x: g.px(15.4); y: g.py(20.6) }
        }
    }

    Vec.Shape {
        anchors.fill: parent
        preferredRendererType: Vec.Shape.CurveRenderer
        id: cutShape
        visible: g.slash > 0.001

        readonly property real x0: g.px(3.6)
        readonly property real y0: g.py(3.6)
        readonly property real x1: g.px(3.6 + 16.8 * g.slash)
        readonly property real y1: g.py(3.6 + 16.8 * g.slash)

        Vec.ShapePath {
            fillColor: "transparent"
            strokeColor: g.cut
            strokeWidth: g.w * 2.4
            capStyle: Vec.ShapePath.RoundCap
            startX: cutShape.x0; startY: cutShape.y0
            PathLine { x: cutShape.x1; y: cutShape.y1 }
        }
        Vec.ShapePath {
            fillColor: "transparent"
            strokeColor: g.ink
            strokeWidth: g.w
            capStyle: Vec.ShapePath.RoundCap
            startX: cutShape.x0; startY: cutShape.y0
            PathLine { x: cutShape.x1; y: cutShape.y1 }
        }
    }
}
