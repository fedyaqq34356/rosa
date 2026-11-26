import QtQuick
import QtQuick.Shapes as Vec
import "root:/design"

Item {
    id: g

    property string device: ""
    property color ink: "white"
    property int hold: 380

    implicitWidth: 24
    implicitHeight: 24

    readonly property int n: 64

    readonly property var rune: [[7, 7.5], [17, 16.5], [12, 21], [12, 3], [17, 7.5], [7, 16.5]]

    function arc(cx, cy, rx, ry, a0, a1, steps) {
        const out = [];
        for (let i = 0; i <= steps; i++) {
            const a = (a0 + (a1 - a0) * i / steps) * Math.PI / 180;
            out.push([cx + rx * Math.cos(a), cy + ry * Math.sin(a)]);
        }
        return out;
    }

    function shapeFor(kind) {
        if (kind === "headphones")
            return [[5, 14], [8, 14], [8, 20], [5, 20]]
                .concat(g.arc(12, 13, 7, 8, 180, 360, 20))
                .concat([[19, 20], [16, 20], [16, 14], [19, 14]]);
        if (kind === "mouse")
            return [[12, 9.5]].concat(g.arc(12, 12, 6.2, 8.6, 270, 630, 30));
        if (kind === "phone")
            return [[12, 20.5], [16, 20.5], [17, 19.5], [17, 4.5], [16, 3.5], [8, 3.5],
                    [7, 4.5], [7, 19.5], [8, 20.5], [12, 20.5]];
        if (kind === "keyboard")
            return [[3, 8], [21, 8], [21, 17], [3, 17], [3, 8]];
        return g.rune;
    }

    function resample(pts, count) {
        const seg = [];
        let total = 0;
        for (let i = 1; i < pts.length; i++) {
            const d = Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]);
            seg.push(d);
            total += d;
        }
        const out = [];
        let si = 0, acc = 0;
        for (let k = 0; k < count; k++) {
            const want = total * k / (count - 1);
            while (si < seg.length - 1 && acc + seg[si] < want) {
                acc += seg[si];
                si++;
            }
            const f = seg[si] > 0 ? Math.min(1, (want - acc) / seg[si]) : 0;
            const a = pts[si], b = pts[si + 1];
            out.push([a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f]);
        }
        return out;
    }

    readonly property var from: g.resample(g.rune, g.n)
    readonly property var to: g.resample(g.shapeFor(g.device), g.n)

    MorphSpring {
        id: m
        target: 0
        response: 0.7
        damping: 1
        springBack: true
    }

    Timer {
        interval: g.hold
        running: g.device !== ""
        onTriggered: m.target = 1
    }
    onDeviceChanged: if (g.device === "") m.target = 0

    readonly property real k: m.value
    readonly property real u: Math.min(g.width, g.height) / 24
    readonly property real ox: (g.width - 24 * g.u) / 2
    readonly property real oy: (g.height - 24 * g.u) / 2

    readonly property var pts: {
        const out = [];
        const t = g.k;
        for (let i = 0; i < g.n; i++) {
            const a = g.from[i], b = g.to[i];
            out.push(Qt.point(g.ox + (a[0] + (b[0] - a[0]) * t) * g.u,
                              g.oy + (a[1] + (b[1] - a[1]) * t) * g.u));
        }
        return out;
    }

    Vec.Shape {
        anchors.fill: parent
        preferredRendererType: Vec.Shape.CurveRenderer

        Vec.ShapePath {
            fillColor: "transparent"
            strokeColor: g.ink
            strokeWidth: g.u * (2.1 + 0.3 * g.k)
            capStyle: Vec.ShapePath.RoundCap
            joinStyle: Vec.ShapePath.RoundJoin
            PathPolyline { path: g.pts }
        }
    }
}
