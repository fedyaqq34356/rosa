import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/services"

Scope {
    id: root

    property bool shown: false
    property int selected: 0
    property string filter: ""
    property var screenOverride: null
    property int picked: -1

    readonly property real p: flip.value
    readonly property bool alive: root.shown || flip.value > 0.002

    function ease(a, b, x) {
        const t = Math.max(0, Math.min(1, (x - a) / (b - a)));
        return t * t * (3 - 2 * t);
    }

    function geomOf(toplevel) {
        const list = Hyprland.toplevels ? Hyprland.toplevels.values : [];
        for (const t of list) {
            if (!t || t.wayland !== toplevel)
                continue;
            const o = t.lastIpcObject;
            if (!o || !o.at || !o.size)
                return null;
            return { x: o.at[0], y: o.at[1], w: o.size[0], h: o.size[1],
                     ws: o.workspace ? o.workspace.id : -1,
                     hidden: !!o.hidden };
        }
        return null;
    }

    readonly property int curWs: {
        const s = win.screen;
        const m = s ? Hyprland.monitorFor(s) : null;
        return m && m.activeWorkspace ? m.activeWorkspace.id : -1;
    }

    MorphSpring {
        id: flip
        target: 0
        response: 0.50
        damping: 1.0
        springBack: true
    }

    Timer {
        id: launch
        interval: 45
        onTriggered: flip.target = root.shown ? 1 : 0
    }

    readonly property string mono: Fonts.mono

    readonly property var windows: {
        const all = ToplevelManager.toplevels.values.filter(t => t && t.title !== undefined);
        const q = root.filter.toLowerCase().trim();
        if (q === "") return all;
        return all.filter(t => (t.title || "").toLowerCase().includes(q)
                            || (t.appId || "").toLowerCase().includes(q));
    }

    function plural(n) { return I18n.plural("plural.window", n); }

    function workspaceOf(toplevel) {
        if (!toplevel || !Hyprland.toplevels)
            return -1;

        const list = Hyprland.toplevels.values;
        for (const t of list) {
            if (!t)
                continue;
            if (t.wayland === toplevel) {
                const w = t.workspace;
                return w ? w.id : -1;
            }
        }

        for (const t of list) {
            const o = t ? t.lastIpcObject : null;
            if (!o || !o.workspace)
                continue;
            if (o.title === toplevel.title)
                return o.workspace.id;
        }

        return -1;
    }

    function toggle() { if (root.shown) root.close(); else root.shown = true; }
    function close()  { root.shown = false; }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (shown) {
            filter = "";
            selected = 0;
            picked = -1;
            Hyprland.refreshToplevels();
            launch.restart();
            Qt.callLater(root.takeFocus);
        } else {
            launch.stop();
            flip.target = 0;
        }
    }

    property var focusTarget: null

    function takeFocus() {
        if (root.focusTarget)
            root.focusTarget.forceActiveFocus();
    }

    function activate(index) {
        const t = root.windows[index];
        if (!t) return;
        root.picked = index;
        root.close();
        t.activate();
    }

    function move(delta) {
        const n = root.windows.length;
        if (n === 0) return;
        root.selected = (root.selected + delta + n) % n;
    }

    HyprlandFocusGrab {
        active: root.shown && !root.screenOverride
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-overview"
        id: win
        screen: root.screenOverride || Focus.screen
        visible: root.alive
        focusable: !root.screenOverride

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: -1
        color: "transparent"

        Loader {
            anchors.fill: parent
            active: root.alive

            sourceComponent: Item {
                id: stage
                anchors.fill: parent

                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: 0.66 * root.ease(0, 0.85, root.p)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.close()
                    }
                }

                FocusScope {
                    id: grab

                    Component.onCompleted: root.focusTarget = grab
                    Component.onDestruction: root.focusTarget = null
                    anchors.fill: parent
                    focus: true

                    Keys.onEscapePressed: root.close()
                    Keys.onLeftPressed: root.move(-1)
                    Keys.onRightPressed: root.move(1)
                    Keys.onTabPressed: root.move(1)
                    Keys.onBacktabPressed: root.move(-1)
                    Keys.onReturnPressed: root.activate(root.selected)
                    Keys.onEnterPressed: root.activate(root.selected)
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Backspace) {
                            root.filter = root.filter.slice(0, -1);
                            root.selected = 0;
                            event.accepted = true;
                        } else if (event.text && event.text.length === 1
                                   && event.text.charCodeAt(0) >= 32) {
                            root.filter += event.text;
                            root.selected = 0;
                            event.accepted = true;
                        }
                    }

                    Column {
                        id: col
                        anchors.centerIn: parent
                        spacing: 26

                        Rectangle {
                            id: field

                            opacity: root.ease(0.35, 1, root.p)
                            transform: Translate { y: -14 * (1 - root.ease(0.2, 1, root.p)) }

                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 460
                            height: 50
                            radius: Shape.field
                            antialiasing: true
                            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.82)
                            border.width: 1
                            border.color: root.filter !== ""
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                          Colors.accent.b, 0.55)
                                : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                          Colors.outline.b, 0.18)
                            Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                            RectangularShadow {
                                z: -1
                                anchors.centerIn: parent
                                width: parent.width + 12
                                height: parent.height + 12
                                radius: parent.radius + 6
                                color: Colors.accent
                                opacity: root.filter !== "" ? 0.22 : 0.12
                                Behavior on opacity { NumberAnimation { duration: Motion.slow } }

                                blur: 40
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 14
                                spacing: 12

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰍉"
                                    color: Colors.accent
                                    opacity: root.filter !== "" ? 1 : 0.6
                                    font.family: root.mono
                                    font.pixelSize: Fonts.large
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 130
                                    elide: Text.ElideRight
                                    text: root.filter !== "" ? root.filter : I18n.t("act.search")
                                    color: root.filter !== "" ? Colors.fg : Colors.fgDim
                                    opacity: root.filter !== "" ? 1 : 0.45
                                    font.family: root.mono
                                    font.pixelSize: Fonts.medium
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: countLabel.implicitWidth + 18
                                    height: 22
                                    radius: Shape.detail
                                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                   Colors.fgDim.b, 0.10)

                                    Text {
                                        id: countLabel
                                        anchors.centerIn: parent
                                        text: root.windows.length + " "
                                              + root.plural(root.windows.length)
                                        color: Colors.fgDim
                                        opacity: 0.75
                                        font.family: root.mono
                                        font.pixelSize: Fonts.tiny
                                    }
                                }
                            }
                        }

                        Grid {
                            id: grid

                            anchors.horizontalCenter: parent.horizontalCenter
                            columns: Math.min(3, Math.max(1, root.windows.length))
                            spacing: 20

                            Repeater {
                                model: root.windows

                                Item {
                                    id: slot

                                    required property var modelData
                                    required property int index

                                    readonly property bool current: root.selected === index
                                    readonly property int workspace:
                                        root.workspaceOf(modelData)

                                    width: 400
                                    height: 268

                                    readonly property var geo: root.alive ? root.geomOf(modelData) : null
                                    readonly property real scrX: win.screen ? win.screen.x : 0
                                    readonly property real scrY: win.screen ? win.screen.y : 0
                                    readonly property bool here: !!slot.geo && !slot.geo.hidden
                                        && slot.geo.ws === root.curWs
                                        && slot.geo.x - slot.scrX > -slot.geo.w
                                        && slot.geo.x - slot.scrX < stage.width
                                    readonly property bool chosen: root.picked === slot.index

                                    readonly property point home: {
                                        void col.x; void col.y; void grid.x; void grid.y;
                                        void grid.width; void stage.width;
                                        return grid.mapToItem(stage, slot.x, slot.y);
                                    }

                                    readonly property real k: Math.max(0, Math.min(1, root.p))
                                    readonly property real side: {
                                        if (!slot.geo || slot.geo.ws < 0 || root.curWs < 0)
                                            return 0;
                                        return slot.geo.ws > root.curWs ? 1 : slot.geo.ws < root.curWs ? -1 : 0;
                                    }

                                    readonly property real fx: slot.here ? slot.geo.x - slot.scrX : slot.home.x + slot.side * 160
                                    readonly property real fy: slot.here ? slot.geo.y - slot.scrY : slot.home.y + 18
                                    readonly property real fsx: slot.here ? slot.geo.w / slot.width : 0.92
                                    readonly property real fsy: slot.here ? slot.geo.h / slot.height : 0.92

                                    opacity: slot.here || (slot.chosen && !root.shown) ? 1 : root.ease(0, 0.9, slot.k)
                                    z: slot.chosen || slot.current ? 2 : 1

                                    transform: [
                                        Scale {
                                            origin.x: 0; origin.y: 0
                                            xScale: slot.fsx + (1 - slot.fsx) * slot.k
                                            yScale: slot.fsy + (1 - slot.fsy) * slot.k
                                        },
                                        Translate {
                                            x: (slot.fx - slot.home.x) * (1 - slot.k)
                                            y: (slot.fy - slot.home.y) * (1 - slot.k)
                                        }
                                    ]

                                    Rectangle {
                                        z: -1
                                        anchors.centerIn: parent
                                        width: parent.width - 16
                                        height: parent.height - 16
                                        radius: Shape.card
                                        color: Colors.accent
                                        opacity: (slot.current ? 0.32
                                               : (cardArea.containsMouse ? 0.16 : 0)) * root.ease(0.6, 1, slot.k)
                                        Behavior on opacity { NumberAnimation { duration: Motion.base } }

                                        layer.enabled: opacity > 0.01
                                        layer.effect: MultiEffect {
                                            blurEnabled: true
                                            blur: 1.0
                                            blurMax: 44
                                        }
                                    }

                                    ClippingRectangle {
                                        id: card

                                        anchors.fill: parent
                                        radius: Shape.card + (Shape.window / Math.max(0.2, Math.min(slot.fsx, slot.fsy)) - Shape.card) * (1 - slot.k)
                                        color: Qt.rgba(Colors.bg.r, Colors.bg.g,
                                                       Colors.bg.b, 0.92 * root.ease(0.3, 1, slot.k))
                                        border.width: slot.k > 0.5 ? (slot.current ? 2 : 1) : 0
                                        border.color: slot.current
                                            ? Colors.accent
                                            : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                                      Colors.outline.b, 0.22)
                                        Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                                        scale: slot.current ? 1.03
                                             : (cardArea.containsMouse ? 1.015 : 1.0)
                                        Behavior on scale {
                                            SpringAnimation {
                                                spring: Motion.tapSpring
                                                damping: Motion.tapDamping
                                                mass: Motion.tapMass
                                                epsilon: 0.001
                                            }
                                        }

                                        ScreencopyView {
                                            id: preview

                                            anchors.fill: parent
                                            captureSource: slot.modelData

                                            live: false
                                            constraintSize: Qt.size(card.width, card.height)
                                        }

                                        IconImage {
                                            anchors.centerIn: parent
                                            visible: !preview.hasContent
                                            implicitSize: 64
                                            source: Quickshell.iconPath(slot.modelData.appId,
                                                                        "application-x-executable")
                                        }

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            height: 62
                                            opacity: root.ease(0.55, 1, slot.k)

                                            gradient: Gradient {
                                                GradientStop {
                                                    position: 0.0
                                                    color: Qt.rgba(Colors.bg.r, Colors.bg.g,
                                                                   Colors.bg.b, 0.0)
                                                }
                                                GradientStop {
                                                    position: 1.0
                                                    color: Qt.rgba(Colors.bg.r, Colors.bg.g,
                                                                   Colors.bg.b, 0.95)
                                                }
                                            }
                                        }

                                        Row {
                                            opacity: root.ease(0.6, 1, slot.k)
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            anchors.leftMargin: 14
                                            anchors.rightMargin: 14
                                            anchors.bottomMargin: 12
                                            spacing: 11

                                            IconImage {
                                                anchors.verticalCenter: parent.verticalCenter
                                                implicitSize: 24
                                                source: Quickshell.iconPath(slot.modelData.appId,
                                                                            "application-x-executable")
                                            }

                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.width - 24 - 11
                                                       - (slot.workspace > 0 ? 46 : 0)
                                                spacing: 1

                                                Text {
                                                    width: parent.width
                                                    elide: Text.ElideRight
                                                    text: slot.modelData.title
                                                          || slot.modelData.appId
                                                    color: slot.current ? Colors.fg : Colors.fgDim
                                                    opacity: slot.current ? 1 : 0.85
                                                    font.family: Fonts.display
                                                    font.features: { "tnum": 1 }
                                                    font.pixelSize: Fonts.medium
                                                    font.weight: slot.current
                                                        ? Font.DemiBold : Font.Normal
                                                }

                                                Text {
                                                    width: parent.width
                                                    visible: text !== ""
                                                    elide: Text.ElideRight
                                                    text: slot.modelData.appId || ""
                                                    color: Colors.fgDim
                                                    opacity: 0.55
                                                    font.family: root.mono
                                                    font.pixelSize: Fonts.tiny
                                                }
                                            }

                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: slot.workspace > 0
                                                width: 34
                                                height: 24
                                                radius: Shape.detail
                                                antialiasing: true
                                                color: slot.current
                                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                              Colors.accent.b, 0.25)
                                                    : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                              Colors.fgDim.b, 0.10)
                                                Behavior on color { ColorAnimation { duration: Motion.fast } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: slot.workspace
                                                    color: slot.current ? Colors.accent : Colors.fgDim
                                                    opacity: slot.current ? 1 : 0.7
                                                    font.family: root.mono
                                                    font.pixelSize: Fonts.small
                                                    font.weight: Font.DemiBold
                                                }
                                            }
                                        }

                                        Sheen {
                                            anchors.fill: parent
                                            opacity: root.ease(0.5, 1, slot.k)
                                            radius: Shape.card
                                            border: false
                                            grainOpacity: 0.02
                                        }
                                    }

                                    MouseArea {
                                        id: cardArea

                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                        hoverEnabled: true
                                        enabled: root.shown
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: root.selected = slot.index
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.MiddleButton)
                                                slot.modelData.close();
                                            else
                                                root.activate(slot.index);
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: 0.5 * root.ease(0.4, 1, root.p)
                            visible: root.windows.length === 0
                            text: root.filter === "" ? I18n.t("ov.noWindows") : I18n.t("ov.noMatch")
                            color: Colors.fgDim
                            font.family: root.mono
                            font.pixelSize: Fonts.medium
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: I18n.t("ov.keys")
                            color: Colors.fgDim
                            opacity: 0.4 * root.ease(0.5, 1, root.p)
                            font.family: root.mono
                            font.pixelSize: Fonts.tiny
                        }
                    }
                }
            }
        }
    }
}
