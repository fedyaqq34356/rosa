import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: find

    property bool active: false
    property real grow: 0

    readonly property var f: IslandBus.finder
    readonly property var d: find.f ? find.f.face : null

    readonly property string kind: find.d ? find.d.kind : ""
    readonly property var best: find.d ? find.d.best : null
    readonly property var conv: find.d ? find.d.conv : null
    readonly property color glow: find.d ? find.d.glow : Colors.accent
    readonly property string query: IslandBus.query.trim()
    readonly property int sel: find.f ? find.f.sel : 0
    readonly property int count: find.f && find.kind === "app" ? Math.min(find.f.results.length, 6) : 0

    readonly property real reveal: Math.max(0, Math.min(1, (find.grow - 2) / 38))
    readonly property real ease: 1 - Math.pow(1 - find.reveal, 3)

    readonly property real iconX: 20
    readonly property real iconS: 52
    readonly property real textX: find.iconX + find.iconS + 16
    readonly property real searchTextX: 42

    visible: find.grow > 0.5

    property real t: 0
    NumberAnimation on t {
        running: find.visible
        loops: Animation.Infinite
        from: 0; to: Math.PI * 2
        duration: 9000
    }

    property real kick: 0
    property real iconIn: 1
    SequentialAnimation {
        id: kickRun
        NumberAnimation { target: find; property: "kick"; to: 1; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation { target: find; property: "kick"; to: 0; duration: 1200; easing.type: Easing.InOutSine }
    }

    property bool typing: false
    Timer { id: rest; interval: 700; onTriggered: find.typing = false }
    Connections {
        target: IslandBus
        function onKeyed(dir) {
            find.typing = true;
            rest.restart();
            if (find.visible)
                kickRun.restart();
        }
    }

    property real blink: 1
    SequentialAnimation on blink {
        running: find.visible && !find.typing
        loops: Animation.Infinite
        onStopped: find.blink = 1
        NumberAnimation { to: 0.15; duration: 560; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1; duration: 560; easing.type: Easing.InOutSine }
    }

    Item {
        id: aura
        anchors.fill: parent
        opacity: find.ease

        RectangularShadow {
            x: find.iconX + find.iconS / 2 - 110 + Math.sin(find.t) * 18
            y: find.height / 2 - 70 + Math.cos(find.t * 2) * 8
            width: 220
            height: 140
            radius: 70
            blur: 80
            color: Colors.alpha(find.glow, 0.46 + 0.22 * find.kick)
        }
        RectangularShadow {
            x: find.width * (0.60 + 0.12 * Math.cos(find.t)) - 90
            y: find.height * (0.55 + 0.2 * Math.sin(find.t * 2 + 1)) - 75
            width: 260
            height: 150
            radius: 75
            blur: 90
            color: Colors.alpha(Qt.lighter(find.glow, 1.3), 0.14)
        }

        IconImage {
            visible: pane.faceKind === "app" && pane.face !== null
            width: 280
            height: 280
            implicitSize: 280
            x: find.iconX + find.iconS / 2 + Math.sin(find.t) * 22 - width / 2
            y: find.height / 2 + Math.cos(find.t * 2) * 10 - height / 2
            rotation: find.t * 180 / Math.PI
            opacity: 0.38 + 0.2 * find.kick
            source: pane.face ? find.iconOf(pane.face) : ""
            asynchronous: true
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                saturation: 0.25
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.0) }
                GradientStop { position: 0.4; color: Qt.rgba(0, 0, 0, 0.30) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.50) }
            }
        }
    }

    Item {
        id: pane
        anchors.fill: parent

        Rectangle {
            id: gloss
            width: 160
            height: pane.height * 2.6
            y: -pane.height * 0.8
            rotation: 18
            opacity: 0
            visible: opacity > 0.01
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.07) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            SequentialAnimation {
                id: glossRun
                ParallelAnimation {
                    NumberAnimation { target: gloss; property: "x"; from: -220; to: pane.width + 60; duration: 1200; easing.type: Easing.InOutCubic }
                    SequentialAnimation {
                        NumberAnimation { target: gloss; property: "opacity"; to: 1; duration: 300 }
                        PauseAnimation { duration: 450 }
                        NumberAnimation { target: gloss; property: "opacity"; to: 0; duration: 420 }
                    }
                }
            }
        }

        property var face: null
        property string faceKind: ""
        property int lastSel: 0
        property real dir: 1
        readonly property string wantKey: find.kind === "app" && find.best
            ? "app:" + (find.best.id || find.best.name)
            : find.kind === "conv" && find.conv ? "conv:" + find.conv.from + ">" + find.conv.to
            : find.kind === "unnote" ? "unnote:" + (find.f && find.f.noteHit ? find.f.noteHit.id : 0)
            : find.kind

        onWantKeyChanged: {
            if (find.kind === "")
                return;
            pane.dir = find.sel < pane.lastSel ? -1 : 1;
            pane.lastSel = find.sel;
            if (pane.faceKind === "" || find.reveal < 0.05) {
                swap.stop();
                pane.face = find.best;
                pane.faceKind = find.kind;
                faceIn.restart();
                glossRun.restart();
                return;
            }
            swap.restart();
        }

        SequentialAnimation {
            id: swap
            ParallelAnimation {
                NumberAnimation { target: face; property: "opacity"; to: 0; duration: 230; easing.type: Easing.InOutCubic }
                NumberAnimation { target: face; property: "lift"; to: -9 * pane.dir; duration: 230; easing.type: Easing.InOutCubic }
                NumberAnimation { target: face; property: "haze"; to: 0.7; duration: 230; easing.type: Easing.InOutCubic }
            }
            ScriptAction {
                script: {
                    pane.face = find.best;
                    pane.faceKind = find.kind;
                    if (find.kind === "app" || find.kind === "conv")
                        glossRun.restart();
                }
            }
            ScriptAction { script: faceIn.restart() }
        }

        ParallelAnimation {
            id: faceIn
            NumberAnimation { target: face; property: "opacity"; from: 0; to: 1; duration: 560; easing.type: Easing.OutCubic }
            NumberAnimation { target: face; property: "lift"; from: 11 * pane.dir; to: 0; duration: 720; easing.type: Easing.OutCubic }
            NumberAnimation { target: face; property: "haze"; to: 0; duration: 640; easing.type: Easing.OutCubic }
            NumberAnimation { target: find; property: "iconIn"; from: 0.82; to: 1; duration: 820; easing.type: Easing.OutCubic }
        }

        Item {
            id: face
            anchors.fill: parent
            property real lift: 0
            property real haze: 0

            readonly property real blurNow: Math.max(face.haze, 0.6 * (1 - find.ease))
            transform: Translate { y: face.lift }

            layer.enabled: face.blurNow > 0.02
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: face.blurNow
                blurMax: 28
            }

            Item {
                id: lead
                x: Motion.mix(4, find.iconX, find.ease)
                anchors.verticalCenter: parent.verticalCenter
                width: find.iconS
                height: find.iconS
                scale: (0.34 + 0.66 * find.ease) * find.iconIn
                opacity: find.ease

                RectangularShadow {
                    anchors.centerIn: parent
                    width: 44
                    height: 44
                    radius: 22
                    blur: 26
                    color: Colors.alpha(find.glow, 0.55 + 0.15 * Math.sin(find.t * 3) + 0.3 * find.kick)
                }

                IconImage {
                    visible: pane.faceKind === "app" && pane.face !== null
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: Math.sin(find.t * 2) * 2
                    implicitSize: find.iconS
                    scale: 1 + 0.018 * Math.sin(find.t * 3) + 0.05 * find.kick
                    source: pane.face ? find.iconOf(pane.face) : ""
                    asynchronous: true
                }

                Rectangle {
                    visible: pane.faceKind !== "app"
                    anchors.centerIn: parent
                    width: 48
                    height: 48
                    radius: 24
                    color: Colors.alpha(find.glow, 0.16)
                    border.width: 1
                    border.color: Colors.alpha(Qt.lighter(find.glow, 1.4), 0.35)

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: Math.sin(find.t * 2) * 1.5
                        text: pane.faceKind === "calc" ? "󰃬"
                            : pane.faceKind === "conv" ? (find.conv ? find.conv.glyph || "󰓡" : "󰓡")
                            : pane.faceKind === "note" ? "󰎚"
                            : pane.faceKind === "unnote" ? "󰄬"
                            : pane.faceKind === "run" ? "󰞷" : ""
                        color: "white"
                        font.family: Fonts.glyph
                        font.pixelSize: 22
                    }
                }
            }

            Item {
                id: words
                x: find.textX
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(40, (pill.visible ? pill.x : pane.width - 20) - find.textX - 16)
                height: col.implicitHeight
                opacity: Math.min(1, find.ease * 1.4)
                transform: [
                    Scale {
                        origin.x: 0
                        origin.y: words.height / 2
                        xScale: 0.8 + 0.2 * find.ease
                        yScale: 0.8 + 0.2 * find.ease
                    },
                    Translate { x: (find.searchTextX - find.textX) * (1 - find.ease) }
                ]

                Column {
                    id: col
                    width: parent.width
                    spacing: 3

                    Item {
                        width: parent.width
                        height: title.implicitHeight

                        Text {
                            id: title
                            width: parent.width
                            visible: pane.faceKind !== "app"
                            textFormat: Text.StyledText
                            text: find.titleText
                            color: "white"
                            font.family: Fonts.display
                            font.pixelSize: 21
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        TextMetrics {
                            id: upTo
                            font: title.font
                            text: find.caretPrefix
                        }

                        Item {
                            id: letters
                            visible: pane.faceKind === "app"
                            width: parent.width
                            height: title.implicitHeight
                            clip: true

                            readonly property int litFrom: find.matchAt
                            readonly property int litTo: find.matchAt >= 0 ? find.matchAt + find.query.length : -1

                            readonly property real caretX: {
                                letterRow.width;
                                if (letters.litTo <= 0)
                                    return 0;
                                const it = letterRep.itemAt(letters.litTo - 1);
                                return it ? it.x + it.width : 0;
                            }

                            Row {
                                id: letterRow
                                anchors.verticalCenter: parent.verticalCenter

                                Repeater {
                                    id: letterRep
                                    model: find.appName.split("")

                                    Item {
                                        id: glyph
                                        required property string modelData
                                        required property int index

                                        readonly property bool lit: glyph.index >= letters.litFrom
                                                                    && glyph.index < letters.litTo
                                        property real l: glyph.lit ? 1 : 0
                                        Behavior on l { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

                                        property real pop: 0
                                        onLitChanged: if (glyph.lit && find.typing) popRun.restart()
                                        SequentialAnimation {
                                            id: popRun
                                            NumberAnimation { target: glyph; property: "pop"; to: 1; duration: 140; easing.type: Easing.OutCubic }
                                            NumberAnimation { target: glyph; property: "pop"; to: 0; duration: 520; easing.type: Easing.InOutSine }
                                        }

                                        width: glyph.modelData === " " ? Math.round(21 * 0.27) : ch.implicitWidth
                                        height: ch.implicitHeight

                                        Text {
                                            anchors.centerIn: ch
                                            text: glyph.modelData
                                            color: Qt.lighter(find.glow, 1.6)
                                            font: ch.font
                                            opacity: 0.85 * glyph.pop
                                            visible: opacity > 0.01
                                            scale: 1 + 0.25 * glyph.pop
                                            layer.enabled: visible
                                            layer.effect: MultiEffect {
                                                blurEnabled: true
                                                blur: 0.8
                                                blurMax: 12
                                            }
                                        }

                                        Text {
                                            id: ch
                                            text: glyph.modelData
                                            color: Qt.rgba(1, 1, 1, 0.42 + 0.58 * glyph.l)
                                            font.family: Fonts.display
                                            font.pixelSize: 21
                                            font.weight: Font.DemiBold
                                            transform: Translate { y: -2.5 * glyph.pop }
                                            scale: 1 + 0.08 * glyph.pop
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                width: 28
                                height: parent.height
                                visible: letterRow.width > letters.width
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.5) }
                                }
                            }
                        }

                        Rectangle {
                            visible: find.caretInTitle
                            x: (pane.faceKind === "app" ? Math.min(letters.caretX, letters.width)
                                                       : Math.min(upTo.advanceWidth, title.width)) + 1
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2
                            height: 22
                            radius: 1
                            color: Qt.lighter(find.glow, 1.5)
                            opacity: find.active ? (find.typing ? 1 : find.blink) : 0
                            Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        }

                        Rectangle {
                            visible: pane.faceKind === "unnote" && find.strike > 0
                            x: -2
                            y: title.font.pixelSize * 0.62
                            width: (Math.min(title.contentWidth, title.width) + 4) * find.strike
                            height: 2
                            radius: 1
                            color: Qt.lighter(find.glow, 1.5)
                        }
                    }

                    Row {
                        spacing: 0
                        width: parent.width

                        Text {
                            id: sub
                            width: Math.min(implicitWidth, parent.width - 4)
                            text: find.subText
                            color: Qt.rgba(1, 1, 1, find.caretInSub ? 0.72 : 0.5)
                            font.family: find.caretInSub && pane.faceKind !== "app" ? Fonts.mono : Fonts.display
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            visible: find.caretInSub
                            anchors.verticalCenter: sub.verticalCenter
                            width: 1.5
                            height: 14
                            radius: 1
                            color: Qt.lighter(find.glow, 1.5)
                            opacity: find.active ? (find.typing ? 1 : find.blink) : 0
                        }
                    }
                }
            }

            Rectangle {
                id: pill
                anchors.right: parent.right
                anchors.rightMargin: dots.visible ? 34 : 22
                anchors.verticalCenter: parent.verticalCenter
                visible: find.pillLabel !== ""
                height: 26
                width: pillRow.implicitWidth + 24
                radius: 13
                color: Colors.alpha(find.glow, 0.18)
                border.width: 1
                border.color: Colors.alpha(find.glow, 0.34)
                opacity: find.ease
                scale: 0.86 + 0.14 * find.ease

                Row {
                    id: pillRow
                    anchors.centerIn: parent
                    spacing: 7

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: find.pillGlyph
                        color: Qt.lighter(find.glow, 1.35)
                        font.family: Fonts.glyph
                        font.pixelSize: 12
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: find.pillLabel
                        color: Qt.lighter(find.glow, 1.35)
                        font.family: Fonts.display
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        Column {
            id: dots
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            visible: find.count > 1
            opacity: find.ease

            Repeater {
                model: find.count

                Rectangle {
                    required property int index
                    readonly property bool on: index === Math.min(find.sel, find.count - 1)
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 4
                    height: on ? 14 : 4
                    radius: 2
                    color: on ? Qt.lighter(find.glow, 1.5) : Qt.rgba(1, 1, 1, 0.22)
                    Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 280 } }
                }
            }
        }

        TapHandler {
            enabled: find.active && find.reveal > 0.5
            onTapped: if (find.f) find.f.accept()
        }
        HoverHandler {
            enabled: find.active
            cursorShape: Qt.PointingHandCursor
        }
    }

    property real strike: 0
    SequentialAnimation {
        id: strikeRun
        PauseAnimation { duration: 260 }
        NumberAnimation { target: find; property: "strike"; to: 1; duration: 620; easing.type: Easing.InOutCubic }
    }
    Connections {
        target: faceIn
        function onStarted() {
            find.strike = 0;
            if (pane.faceKind === "unnote" && find.f && find.f.noteHit)
                strikeRun.restart();
        }
    }

    readonly property var e: pane.faceKind === "app" ? pane.face : null
    readonly property string appName: find.e ? (find.e.name || "") : ""
    readonly property int matchAt: find.query === "" ? -1 : find.appName.toLowerCase().indexOf(find.query.toLowerCase())

    readonly property bool caretInTitle: pane.faceKind === "app" ? find.matchAt >= 0
                                         : pane.faceKind === "note" || pane.faceKind === "run"
    readonly property bool caretInSub: !find.caretInTitle

    readonly property string caretPrefix: {
        if (pane.faceKind === "app")
            return find.matchAt >= 0 ? find.appName.slice(0, find.matchAt + find.query.length) : "";
        return find.plainTitle;
    }

    readonly property string plainTitle: {
        const k = pane.faceKind;
        const l = find.f;
        if (!l)
            return "";
        if (k === "note")
            return l.noteText;
        if (k === "unnote")
            return l.noteHit ? l.noteHit.text : I18n.t("notes.none");
        if (k === "run")
            return "$ " + l.runCmd;
        if (k === "calc")
            return l.calcResult !== "" ? "= " + l.calcResult : "…";
        if (k === "conv")
            return find.conv ? find.conv.result + " " + find.conv.to : "";
        return "";
    }

    readonly property string titleText: {
        if (pane.faceKind === "app")
            return find.marked(find.appName);
        if (pane.faceKind === "note" && find.f && find.f.noteText === "")
            return "<font color=\"#66ffffff\">" + find.esc(I18n.t("notes.hint")) + "</font>";
        return find.esc(find.plainTitle);
    }

    readonly property string subText: {
        const k = pane.faceKind;
        const l = find.f;
        if (!l)
            return "";
        if (k === "app") {
            if (find.matchAt < 0)
                return find.query;
            return find.e ? (find.e.genericName || find.e.comment || "") : "";
        }
        if (k === "calc")
            return l.calcExpr;
        if (k === "conv")
            return find.query;
        if (k === "note")
            return I18n.t("notes.new") + (Notes.count > 0 ? "  ·  " + Notes.count : "");
        if (k === "unnote")
            return find.query;
        if (k === "run")
            return "Run in shell";
        return "";
    }

    readonly property string pillLabel: {
        const k = pane.faceKind;
        if (k === "app")
            return Running.any
                ? (Running.workspaces.length === 1 ? "Desk " + Running.workspaces[0]
                                                   : Running.workspaces.length + " desks")
                : "Open";
        if (k === "calc" || k === "conv")
            return "Copy";
        if (k === "note")
            return find.f && find.f.noteText !== "" ? I18n.t("notes.save") : "";
        if (k === "unnote")
            return find.f && find.f.noteHit ? I18n.t("notes.done") : "";
        if (k === "run")
            return "Run";
        return "";
    }
    readonly property string pillGlyph: pane.faceKind === "app" && Running.any ? "󰖯"
                                      : pane.faceKind === "calc" || pane.faceKind === "conv" ? "󰆏" : "󰌑"

    function esc(s) {
        return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    function iconOf(e) {
        const i = e && e.icon ? e.icon : "";
        if (i.startsWith("/"))
            return "file://" + i;
        return Quickshell.iconPath(i, "application-x-executable");
    }

    function marked(name) {
        const q = find.query.toLowerCase();
        const i = q === "" ? -1 : name.toLowerCase().indexOf(q);
        if (i < 0)
            return find.esc(name);
        const dim = "<font color=\"#73ffffff\">";
        return dim + find.esc(name.slice(0, i)) + "</font>"
            + find.esc(name.slice(i, i + q.length))
            + dim + find.esc(name.slice(i + q.length)) + "</font>";
    }
}
