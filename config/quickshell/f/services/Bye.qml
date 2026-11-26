pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/services"

Singleton {
    id: root

    property bool shown: false
    property var pending: null
    property bool demo: false
    property string lead: ""
    property var screenOverride: null

    property real ms: 0
    readonly property int total: 2700
    readonly property int hold: root.total + 60

    function run(command) {
        if (root.shown)
            return;
        root.pending = command;
        root.demo = false;
        root.start();
    }

    function start() {
        root.lead = root.screenOverride ? root.screenOverride.name
                  : Focus.screen ? Focus.screen.name : "";
        IslandBus.watch += 1;
        root.ms = 0;
        root.ready = false;
        root.shown = true;
        wait.restart();
    }

    property bool ready: false
    function go() {
        if (!root.shown || root.ready)
            return;
        wait.stop();
        root.ready = true;
        clockRun.restart();
        fire.restart();
    }

    Timer {
        id: wait
        interval: 300
        onTriggered: root.go()
    }

    function finish() {
        clockRun.stop();
        fire.stop();
        wait.stop();
        root.ready = false;
        if (root.shown)
            IslandBus.watch = Math.max(0, IslandBus.watch - 1);
        root.shown = false;
        root.ms = 0;
    }

    function ease(a, b) {
        const x = Math.max(0, Math.min(1, (root.ms - a) / (b - a)));
        return x * x * x * (x * (x * 6 - 15) + 10);
    }
    function mix(a, b, t) { return a + (b - a) * t; }

    readonly property real fold:    root.ease(0, 1000)
    readonly property real dark:    root.ease(0, 820)
    readonly property real shotOut: root.ease(520, 1000)
    readonly property real ember:   root.ease(560, 1150)
    readonly property real rise:    root.ease(1000, 1720)
    readonly property real textIn:  root.ease(1250, 1800)
    readonly property real textOut: root.ease(1900, 2250)
    readonly property real drop:    root.ease(1950, 2480)
    readonly property real fade:    root.ease(2320, 2680)

    readonly property string title: {
        const h = new Date().getHours();
        const night = h >= 21 || h < 5;
        if (Prefs.language === "ru")
            return night ? "Спокойной ночи" : "До встречи";
        return night ? "Good night" : "See you soon";
    }

    NumberAnimation {
        id: clockRun
        target: root
        property: "ms"
        from: 0
        to: root.total
        duration: root.total
    }

    Process { id: runner }

    Timer {
        id: fire
        interval: root.hold
        repeat: false
        onTriggered: {
            if (root.demo) {
                root.finish();
                return;
            }
            if (root.pending) {
                runner.command = root.pending;
                runner.running = true;
                root.pending = null;
            }
        }
    }

    IpcHandler {
        target: "bye"
        function demo(): void {
            if (root.shown)
                return;
            root.demo = true;
            root.pending = null;
            root.start();
        }
        function stop(): void { root.finish(); }
    }

    Variants {
        model: root.shown ? (root.screenOverride ? [root.screenOverride] : Quickshell.screens) : []

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "qs-bye"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.demo || root.screenOverride
                ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

            anchors { top: true; bottom: true; left: true; right: true }
            exclusiveZone: -1
            color: "transparent"
            mask: root.demo ? empty : null
            Region { id: empty }

            readonly property bool isLead: modelData.name === root.lead

            readonly property bool isleHere: IslandBus.isleW > 4
                && (IslandBus.isleScreen === "" || IslandBus.isleScreen === modelData.name)
            readonly property real iW: win.isleHere ? IslandBus.isleW : 150
            readonly property real iH: win.isleHere ? IslandBus.isleH : 34
            readonly property real iX: win.isleHere ? IslandBus.isleX + IslandBus.isleW / 2 : win.width / 2
            readonly property real iY: win.isleHere ? IslandBus.isleY + IslandBus.isleH / 2 : 8 + 17

            readonly property real bigW: Math.max(360, title.implicitWidth + 110)
            readonly property real bigH: 70

            readonly property real foldW: root.mix(win.width, win.iW, root.fold)
            readonly property real foldH: root.mix(win.height, win.iH, root.fold)
            readonly property real foldX: root.mix(win.width / 2, win.iX, root.fold)
            readonly property real foldY: root.mix(win.height / 2, win.iY, root.fold)

            readonly property real dot: 16 * (1 - root.fade)
            readonly property real capW: root.mix(root.mix(win.foldW, win.bigW, root.rise), win.dot, root.drop)
            readonly property real capH: root.mix(root.mix(win.foldH, win.bigH, root.rise), win.dot, root.drop)
            readonly property real capX: root.mix(win.foldX, win.width / 2, root.rise)
            readonly property real capY: root.mix(win.foldY, win.height / 2 - 24, root.rise)

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: win.isLead ? root.dark : root.ease(0, 900)
            }

            RectangularShadow {
                visible: win.isLead && root.ready
                x: win.capX - width / 2
                y: win.capY - height / 2
                width: win.capW
                height: win.capH
                radius: Math.min(width, height) / 2
                blur: 26 + 20 * root.drop
                spread: 2
                color: Colors.alpha(Colors.accent, 0.34 * root.ember * (1 - root.fade))
            }

            Rectangle {
                id: cap
                visible: win.isLead && win.capW > 0.5 && root.ready
                x: win.capX - width / 2
                y: win.capY - height / 2
                width: win.capW
                height: win.capH
                radius: root.mix(0, Math.min(width, height) / 2, Math.min(1, root.fold * 1.4))
                color: Qt.rgba(0.035, 0.035, 0.04, 1)
                antialiasing: true
                clip: true
                layer.enabled: root.ms < 1050
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: capMask
                    autoPaddingEnabled: false
                }

                ScreencopyView {
                    id: shot
                    anchors.centerIn: parent
                    width: cap.width
                    height: cap.width * win.height / Math.max(1, win.width)
                    captureSource: win.modelData
                    live: false
                    onHasContentChanged: if (hasContent && win.isLead) root.go()
                    opacity: 1 - root.shotOut
                    visible: opacity > 0.002
                }

                Rectangle {
                    anchors.fill: parent
                    radius: cap.radius
                    color: "transparent"
                    border.width: 1
                    border.color: Colors.alpha(Colors.accent, 0.22 * root.ember * (1 - root.drop))
                }

                Text {
                    id: title
                    anchors.centerIn: parent
                    text: root.title
                    color: Colors.fg
                    opacity: root.textIn * (1 - root.textOut)
                    scale: 0.94 + 0.06 * root.textIn - 0.04 * root.textOut
                    font.family: Fonts.display
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.3
                    layer.enabled: opacity > 0.01 && opacity < 0.99
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blurMax: 14
                        blur: 1 - title.opacity
                    }
                }
            }

            Item {
                id: capMask
                visible: false
                layer.enabled: true
                width: cap.width
                height: cap.height
                Rectangle {
                    anchors.fill: parent
                    radius: cap.radius
                    color: "black"
                    antialiasing: true
                }
            }
        }
    }
}
