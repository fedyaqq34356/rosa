import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/services"

Rectangle {
    id: control

    property real value: 0
    property real step: 0.05
    property color tint: Colors.accent
    property bool silent: false

    signal moved(real value)
    signal released()

    readonly property bool dragging: area.pressed
    readonly property bool awake: hover.hovered || control.dragging

    height: 6
    radius: height / 2
    color: "transparent"

    readonly property real v: Math.max(0, Math.min(1, control.value))

    MorphSpring {
        id: front
        target: control.v * control.width
        response: control.dragging ? 0.32 : 0.48
        damping: 0.92
        springBack: true
        epsilon: 0.05
        Component.onCompleted: front.land()
    }

    property real swell: control.awake ? 1 : 0
    Behavior on swell { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    property real slosh: 0
    FrameAnimation {
        running: front.running || control.slosh > 0.02
        onTriggered: {
            const want = Math.min(1, Math.abs(front.velocity) / 900);
            const k = want > control.slosh ? 1 - Math.exp(-frameTime * 10) : 1 - Math.exp(-frameTime * 2.2);
            control.slosh += (want - control.slosh) * k;
            if (!front.running && control.slosh < 0.02)
                control.slosh = 0;
        }
    }

    property real phase: 0
    NumberAnimation on phase {
        running: control.awake && control.visible
        loops: Animation.Infinite
        paused: running && Stage.gaming
        from: 0; to: Math.PI * 2
        duration: 2400
    }

    ClippingRectangle {
        id: tube
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: control.height + Math.round(control.height * 1.1) * control.swell
        radius: height / 2
        color: Prefs.apple ? Colors.alpha(Colors.fg, 0.16)
                           : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.2)

        Water {
            anchors.fill: parent
            axis: 1
            level: Math.max(0, front.value)
            phase1: control.phase
            amp1: (0.25 + 1.1 * control.swell) * (tube.height / 14) + 2.2 * control.slosh
            waves1: 0.9
            phase2: control.phase * 2.3
            amp2: 1.6 * control.slosh
            waves2: 2.2
            nearColor: control.tint
            nearAlpha: 1.0
            farColor: control.tint
            farAlpha: 0.78 + 0.1 * control.swell
            crestColor: Qt.lighter(control.tint, 1.4)
            crestAlpha: 0.55 * control.swell
            crestWidth: 1.4
        }
    }

    Rectangle {
        id: knob

        readonly property real speed: Math.max(-1, Math.min(1, front.velocity / 1600))
        readonly property real stretch: Math.abs(knob.speed)

        width: Prefs.apple ? 20 : 14
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: front.value - width / 2
        color: Prefs.apple ? "white" : control.tint
        opacity: Prefs.apple || control.awake ? 1 : 0

        RectangularShadow {
            z: -1
            anchors.fill: parent
            visible: Prefs.apple
            radius: parent.radius
            blur: 6
            offset.y: 2
            color: Qt.rgba(0, 0, 0, 0.4)
        }
        RectangularShadow {
            z: -2
            anchors.fill: parent
            radius: parent.radius
            blur: 14
            spread: 1
            color: Colors.alpha(control.tint, 0.5 * control.swell)
        }

        scale: control.dragging ? 1.12 : 1
        transform: Scale {
            origin.x: knob.speed >= 0 ? knob.width : 0
            origin.y: knob.height / 2
            xScale: 1 + 0.42 * knob.stretch
            yScale: 1 - 0.16 * knob.stretch
        }

        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        Behavior on scale { Spring {} }
    }

    HoverHandler { id: hover }

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -10

        function apply(mouse) {
            const raw = Math.max(0, Math.min(1, mouse.x / control.width));
            const snapped = Math.round(raw / control.step) * control.step;
            if (Math.abs(snapped - control.value) < control.step / 2)
                return;
            control.value = snapped;
            if (!control.silent)
                Sfx.tick();
            control.moved(snapped);
        }

        onPressed: (mouse) => area.apply(mouse)
        onPositionChanged: (mouse) => {
            if (area.pressed)
                area.apply(mouse);
        }
        onReleased: {
            if (!control.silent)
                Sfx.tap();
            control.released();
        }
    }
}
