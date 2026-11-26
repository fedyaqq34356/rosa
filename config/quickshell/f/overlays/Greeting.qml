import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes as Sh
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool showing: false
    property string screenName: ""
    property real ms: 0
    readonly property int total: 6300

    WeatherHold { active: root.showing }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string part: {
        const h = clock.date.getHours();
        if (h < 5)  return "night";
        if (h < 12) return "morning";
        if (h < 18) return "day";
        if (h < 23) return "evening";
        return "night";
    }

    readonly property string line: {
        const out = [Qt.formatDateTime(clock.date, "dddd, d MMMM").toLowerCase()];
        if (Weather.ready)
            out.push(Weather.glyph + "  " + Math.round(Weather.temp) + "°");
        const battery = UPower.displayDevice;
        if (battery && battery.isLaptopBattery)
            out.push(Math.round(battery.percentage * 100) + "%");
        if (NotifHistory.unseen > 0)
            out.push(I18n.count("plural.notification", NotifHistory.unseen));
        if (Updates.count > 0)
            out.push(Updates.count + I18n.t("notif.packages"));
        return out.join("   ·   ");
    }

    function ease(a, b) {
        const x = Math.max(0, Math.min(1, (root.ms - a) / (b - a)));
        return x * x * x * (x * (x * 6 - 15) + 10);
    }
    function mix(a, b, t) { return a + (b - a) * t; }

    readonly property real dropIn:   root.ease(120, 950)
    readonly property real grow:     root.ease(600, 1750)
    readonly property real drift:    root.ease(1500, 3700)
    readonly property real textIn:   root.ease(1150, 2400)
    readonly property real lineIn:   root.ease(1750, 2900)
    readonly property real lineOut:  root.ease(3150, 3850)
    readonly property real textOut:  root.ease(3300, 4000)
    readonly property real land:     root.ease(3500, 4850)
    readonly property real reveal:   root.ease(3450, 6100)
    readonly property real handoff:  root.ease(4600, 5150)
    readonly property real glowOut:  root.ease(4100, 5000)

    function show() {
        if (root.showing)
            return;
        IslandBus.veil = 1;
        IslandBus.watch += 1;
        root.ms = 0;
        root.showing = true;
        Sfx.sessionStart();
        run.restart();
    }

    function finish() {
        if (!root.showing)
            return;
        root.showing = false;
        IslandBus.veil = 0;
        IslandBus.watch = Math.max(0, IslandBus.watch - 1);
    }

    NumberAnimation {
        id: run
        target: root; property: "ms"
        from: 0; to: root.total; duration: root.total
        easing.type: Easing.Linear
        onFinished: root.finish()
    }

    Binding {
        target: IslandBus; property: "veil"
        value: 1 - root.handoff
        when: root.showing
    }

    FileView {
        id: marker
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-greeted"
        blockLoading: true
        printErrors: false

        onLoadFailed: (error) => {
            if (error !== FileViewError.FileNotFound)
                return;
            marker.setText(String(Date.now()));
            if (Prefs.greetingEnabled) {
                root.show();
                blackReady.start();
            } else {
                blackMark.running = true;
            }
        }
    }

    Timer {
        id: blackReady
        interval: 160
        onTriggered: blackMark.running = true
    }

    Process {
        id: blackMark
        command: ["touch", (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/qs-greet-black"]
    }

    IpcHandler {
        target: "greeting"
        function demo(): void { root.finish(); root.show(); }
        function stop(): void { run.stop(); root.finish(); }
        function hold(): void {
            run.stop();
            root.finish();
            IslandBus.veil = 1;
            IslandBus.watch += 1;
            root.ms = 0;
            root.showing = true;
        }
        function go(): void { Sfx.sessionStart(); run.restart(); }
    }

    PanelWindow {
        id: win

        WlrLayershell.namespace: "qs-greeting"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        screen: {
            if (root.screenName !== "") {
                for (const s of Quickshell.screens)
                    if (s.name === root.screenName) return s;
            }
            return Focus.screen;
        }
        visible: root.showing

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: -1
        color: "transparent"
        mask: Region {}

        readonly property bool isleHere: IslandBus.isleW > 4
            && (IslandBus.isleScreen === "" || (win.screen && IslandBus.isleScreen === win.screen.name))
        readonly property real dstW: win.isleHere ? IslandBus.isleW : 150
        readonly property real dstH: win.isleHere ? IslandBus.isleH : 34
        readonly property real dstX: win.isleHere ? IslandBus.isleX + IslandBus.isleW / 2 : win.width / 2
        readonly property real dstY: win.isleHere ? IslandBus.isleY + IslandBus.isleH / 2 : 8 + 17

        readonly property real bigW: Math.max(420, title.implicitWidth + 120) + 14 * root.drift
        readonly property real bigH: 74 + 2 * root.drift
        readonly property real dot: 16 * root.dropIn

        readonly property real capW: root.mix(root.mix(win.dot, win.bigW, root.grow), win.dstW, root.land)
        readonly property real capH: root.mix(root.mix(win.dot, win.bigH, root.grow), win.dstH, root.land)
        readonly property real capX: root.mix(win.width / 2, win.dstX, root.land)
        readonly property real capY: root.mix(win.height / 2 - 24, win.dstY, root.land)

        readonly property real diag: Math.sqrt(win.width * win.width + win.height * win.height)
        readonly property real holeR: root.reveal * win.diag * 1.05
        readonly property real soft: 560 * Math.min(1, win.holeR / 560)

        Rectangle {
            anchors.fill: parent
            color: "black"
            visible: win.holeR < 2
        }

        Sh.Shape {
            anchors.fill: parent
            visible: win.holeR >= 2
            preferredRendererType: Sh.Shape.GeometryRenderer

            Sh.ShapePath {
                strokeWidth: -1
                fillGradient: Sh.RadialGradient {
                    centerX: win.capX; centerY: win.capY
                    focalX: win.capX; focalY: win.capY
                    centerRadius: win.holeR + win.soft
                    focalRadius: 0
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop {
                        position: win.holeR + win.soft > 0.5
                            ? win.holeR / (win.holeR + win.soft) : 0
                        color: "transparent"
                    }
                    GradientStop { position: 1.0; color: "black" }
                }
                startX: 0; startY: 0
                PathLine { x: win.width; y: 0 }
                PathLine { x: win.width; y: win.height }
                PathLine { x: 0; y: win.height }
                PathLine { x: 0; y: 0 }
            }
        }

        RectangularShadow {
            x: win.width / 2 - width / 2
            y: win.height / 2 - 24 - height / 2
            width: 900
            height: 520
            radius: 260
            blur: 260
            color: Colors.alpha(Colors.accent, 0.10 * root.dropIn * (1 - root.glowOut))
        }

        Item {
            id: cap
            x: win.capX - width / 2
            y: win.capY - height / 2
            width: win.capW
            height: win.capH
            opacity: (1 - root.handoff) * Math.min(1, root.dropIn * 1.4)

            RectangularShadow {
                anchors.fill: parent
                radius: height / 2
                blur: 34 + 30 * root.grow * (1 - root.land)
                spread: 2
                color: Colors.alpha(Colors.accent, (0.55 - 0.25 * root.grow) * (1 - root.glowOut))
            }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "black"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.10 * (1 - root.glowOut))

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: height / 2
                    opacity: 0.9 * (1 - root.glowOut)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.07) }
                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                }
            }

            Text {
                id: title
                anchors.centerIn: parent
                text: I18n.t("hello." + root.part)
                color: "white"
                font.family: Fonts.display
                font.pixelSize: 30
                font.weight: Font.Light
                font.letterSpacing: 7 * (1 - root.textIn) + 0.4
                opacity: root.textIn * (1 - root.textOut)
                scale: 0.94 + 0.06 * root.textIn - 0.05 * root.textOut
                visible: opacity > 0.002

                layer.enabled: visible && (root.textIn < 0.999 || root.textOut > 0.001)
                layer.effect: MultiEffect {
                    autoPaddingEnabled: true
                    blurEnabled: true
                    blurMax: 24
                    blur: Math.max(1 - root.textIn, root.textOut)
                }
            }
        }

        Text {
            id: sub
            anchors.horizontalCenter: parent.horizontalCenter
            y: win.height / 2 - 24 + win.bigH / 2 + 22 + 10 * (1 - root.lineIn) - 6 * root.lineOut
            text: root.line
            color: Qt.rgba(1, 1, 1, 0.62)
            font.family: Fonts.display
            font.pixelSize: 14
            font.letterSpacing: 0.6
            opacity: root.lineIn * (1 - root.lineOut)
            visible: opacity > 0.002

            layer.enabled: visible && (root.lineIn < 0.999 || root.lineOut > 0.001)
            layer.effect: MultiEffect {
                autoPaddingEnabled: true
                blurEnabled: true
                blurMax: 16
                blur: Math.max(1 - root.lineIn, root.lineOut)
            }
        }
    }
}
