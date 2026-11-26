import Quickshell
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/services"

Scope {
    id: root

    readonly property real depth: 0.55
    readonly property int dawnHold: 700
    readonly property int dawnMs: 1600

    property bool night: false
    property bool dawning: false

    function dawn() {
        root.dawning = true;
        root.night = false;
        dawnEnd.restart();
    }

    Connections {
        target: Idle
        function onScreenOffChanged() {
            if (Idle.screenOff) {
                dawnEnd.stop();
                root.dawning = false;
                root.night = true;
            } else if (root.night) {
                dawnHoldT.restart();
            }
        }
    }

    Timer { id: dawnHoldT; interval: root.dawnHold; onTriggered: root.dawn() }
    Timer { id: dawnEnd; interval: root.dawnMs + 80; onTriggered: root.dawning = false }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            WlrLayershell.namespace: "qs-dim"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            screen: modelData
            color: "transparent"

            visible: shade.opacity > 0.001

            anchors { top: true; bottom: true; left: true; right: true }

            mask: Region {}

            Rectangle {
                id: shade
                anchors.fill: parent
                color: "black"
                opacity: root.night ? 1 : Idle.dimming ? root.depth : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.night ? 260
                                : root.dawning ? root.dawnMs
                                : Idle.dimming ? Motion.lazy * 2 : Motion.base
                        easing.type: root.dawning ? Easing.InOutSine : Easing.InOutQuad
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                opacity: root.dawning ? 1 : 0
                visible: opacity > 0.001
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.0) }
                    GradientStop { position: 0.55; color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.035) }
                    GradientStop { position: 1.0; color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.09) }
                }
                Behavior on opacity {
                    NumberAnimation { duration: root.dawning ? 300 : root.dawnMs * 0.9; easing.type: Easing.InOutSine }
                }
            }
        }
    }
}
