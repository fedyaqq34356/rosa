import QtQuick
import QtQuick.Shapes as Vec
import "root:/design"
import "root:/services"

Item {
    id: fan

    property real strength: 1
    property bool on: true
    property bool wired: false
    property bool morphIn: false
    property color tint: Colors.accent

    implicitWidth: 44
    implicitHeight: 36

    MorphSpring {
        id: wire
        target: fan.wired ? 1 : 0
        response: 0.5
        damping: 1
        springBack: true
    }
    readonly property real w: wire.value

    MorphSpring {
        id: link
        target: fan.on || fan.wired ? 1 : 0
        response: 0.75
        damping: 1
        springBack: true
    }
    readonly property real lk: link.value

    function shown(n) {
        const t = Math.max(0, Math.min(1, (fan.lk - (n - 1) / 4) / 0.5));
        return t * t * (3 - 2 * t);
    }

    property real breath: 0
    SequentialAnimation on breath {
        running: !fan.on && !fan.wired && fan.visible
        loops: Animation.Infinite
        paused: running && Stage.gaming
        onStopped: fan.breath = 0
        NumberAnimation { from: 0; to: 1; duration: 1500; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1; to: 0; duration: 1500; easing.type: Easing.InOutSine }
    }

    Component.onCompleted: {
        if (fan.morphIn)
            wire.value = fan.wired ? 0 : 1;
        else
            wire.land();
        link.settle(fan.on || fan.wired ? 0 : 1);
        link.target = Qt.binding(() => fan.on || fan.wired ? 1 : 0);
    }

    property real sweep: -1
    readonly property int level: fan.wired ? 3
        : fan.on ? Math.max(1, Math.ceil(fan.strength * 3)) : 0

    SequentialAnimation {
        running: !fan.wired && fan.on
        loops: 2
        paused: running && Stage.gaming
        NumberAnimation {
            target: fan; property: "sweep"
            from: -0.5; to: 3.5; duration: 720
            easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: 120 }
        onFinished: fan.sweep = -1
    }

    readonly property real cx: fan.width / 2
    readonly property real by: fan.height - 3
    readonly property real stroke: Math.max(3, fan.height * 0.11)

    readonly property real plugW: Math.min(fan.width, fan.height * 1.05)
    readonly property real plugH: fan.height * 0.58
    readonly property real plugY: fan.height * 0.04
    readonly property real plugBottom: fan.plugY + fan.plugH

    function glow(i) {
        if (fan.sweep < 0)
            return 0;
        return Math.max(0, 1 - Math.abs(fan.sweep - i) * 1.3) * (1 - fan.w);
    }

    function lit(i) { return i <= fan.level; }

    Rectangle {
        id: body
        x: fan.cx - fan.plugW / 2
        y: fan.plugY
        width: fan.plugW
        height: fan.plugH
        radius: fan.plugH * 0.24
        antialiasing: true
        color: Colors.alpha(fan.tint, 0.16)
        border.width: fan.stroke * 0.75
        border.color: fan.tint
        opacity: Math.max(0, fan.w * 2 - 1)
        scale: Motion.mix(0.7, 1, fan.w)
    }

    Rectangle {
        width: fan.plugW * 0.4
        height: fan.height * 0.13
        x: fan.cx - width / 2
        y: fan.plugBottom - fan.stroke * 0.4
        radius: fan.stroke * 0.5
        antialiasing: true
        color: fan.tint
        opacity: Math.max(0, fan.w * 2 - 1)
        scale: Motion.mix(0.7, 1, fan.w)
    }

    Rectangle {
        readonly property real dot: fan.stroke * 1.5
        width: Motion.mix(dot, fan.stroke, fan.w)
        height: Motion.mix(dot, fan.height - fan.plugBottom + 1, fan.w)
        radius: width / 2
        x: fan.cx - width / 2
        y: Motion.mix(fan.by - dot / 2 - 1, fan.plugBottom - 1, fan.w)
        antialiasing: true
        color: fan.on || fan.wired ? fan.tint : Colors.alpha(Colors.fg, 0.28 + 0.32 * fan.breath)
        scale: 1 + fan.glow(0) * 0.35 + (1 - fan.lk) * 0.12 * fan.breath
    }

    Repeater {
        model: 3

        Vec.Shape {
            id: arc
            required property int index
            readonly property int n: arc.index + 1
            readonly property real q: fan.w > 0.001 ? 1 : fan.shown(arc.n)
            readonly property real r: (fan.stroke * 1.2 + arc.n * (fan.height - fan.stroke * 2) / 3.3)
                                      * (0.55 + 0.45 * arc.q)
            readonly property real g: fan.glow(arc.n)

            readonly property real s: 0.70711 * arc.r
            readonly property real k: 0.55228 * arc.s

            readonly property real px: fan.cx + (arc.n - 2) * fan.plugW * 0.2
            readonly property real p0: fan.plugY + fan.plugH * 0.4
            readonly property real p1: fan.plugY + fan.plugH * 0.7

            function at(a, b) { return Motion.mix(a, b, fan.w); }

            anchors.fill: parent
            preferredRendererType: Vec.Shape.CurveRenderer
            opacity: arc.q * (fan.lit(arc.n) || !fan.on ? 1 : (0.2 + 0.8 * arc.g))
            visible: arc.q > 0.002

            Vec.ShapePath {
                strokeColor: fan.lit(arc.n) || arc.g > 0
                    ? Qt.lighter(fan.tint, 1 + arc.g * 0.5)
                    : Colors.alpha(Colors.fg, 1)
                strokeWidth: Motion.mix(fan.stroke * (0.5 + 0.5 * arc.q), fan.stroke * 0.6, fan.w)
                fillColor: "transparent"
                capStyle: Vec.ShapePath.RoundCap
                startX: arc.at(fan.cx - arc.s, arc.px)
                startY: arc.at(fan.by - arc.s, arc.p0)
                PathCubic {
                    control1X: arc.at(fan.cx - arc.s + arc.k, arc.px)
                    control1Y: arc.at(fan.by - arc.s - arc.k, Motion.mix(arc.p0, arc.p1, 1 / 3))
                    control2X: arc.at(fan.cx + arc.s - arc.k, arc.px)
                    control2Y: arc.at(fan.by - arc.s - arc.k, Motion.mix(arc.p0, arc.p1, 2 / 3))
                    x: arc.at(fan.cx + arc.s, arc.px)
                    y: arc.at(fan.by - arc.s, arc.p1)
                }
            }
        }
    }
}
