import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/overlays/cards"
import "root:/reusables"
import "root:/services"

Item {
    id: body

    property string kind: ""
    property color tint: Colors.accent
    property bool wide: false
    property bool big: false
    property string notifSummary: ""
    property string notifBody: ""
    property string notifApp: ""
    property string notifImage: ""
    property string notifIcon: ""
    property int notifCount: 1
    property var notifMsgs: []
    property bool notifCritical: false
    readonly property real want: card.item && card.item.wantH !== undefined ? card.item.wantH : 0
    property var notifLive: null
    property bool notifTools: false
    property bool notifReplying: false
    property bool notifNear: true
    property int notifPage: 0
    property int notifTotal: 1
    property var call: null
    property string clipImage: ""
    property string clipText: ""
    property var demo: ({})
    property var cmd: ({})
    property string cmdTook: ""
    property string shotPath: ""
    property var skyInfo: ({})

    signal focusWin(string win)
    signal dismissed()
    signal notifReply(bool on)
    signal notifDone()
    signal callAccept()
    signal callDecline()

    readonly property string glyph: body.glyphFor(body.kind)

    function glyphFor(k) {
        switch (k) {
        case "alarm":  return "󰀠";
        case "remind": return "󰂞";
        case "record": return "󰑊";
        case "osd":    return Feedback.icon !== "" ? Feedback.icon : "󰕾";
        case "notif":  return "󰂚";
        case "timer":  return "󰔛";
        case "media":  return "󰎈";
        case "clock":  return "󰥔";
        case "bt":     return Bt.connectedCount > 0 ? Bt.icon(Bt.primary) : "󰂲";
        case "peri":   return Peripherals.glyph !== "" ? Peripherals.glyph : "󰍽";
        case "power":  return Power.glyph;
        case "net":    return Network.glyph;
        case "vpn":    return Vpn.up ? "󰦝" : "󰦞";
        case "print":  return "󰐪";
        }
        return "";
    }

    readonly property string headline: body.headlineFor(body.kind)

    function headlineFor(k) {
        switch (k) {
        case "alarm":  return I18n.t("isle.alarm");
        case "remind": return Reminders.ringing ? Reminders.ringing.title : "";
        case "record": return Recorder.clock;
        case "osd":    return Feedback.label !== "" ? Feedback.label
                                                    : Feedback.percent(Feedback.value);
        case "notif":  return body.notifSummary;
        case "timer":  return Timers.soonest ? Timers.clock(Timers.left(Timers.soonest))
                                             : "";
        case "media":  return Media.title !== "" ? Media.title : Media.label;
        case "clock":  return Qt.formatDateTime(clockTick.date, "HH:mm");
        case "bt":     return Bt.connectedCount > 0 ? Bt.label(Bt.primary)
                                                    : I18n.t("isle.bt.gone");
        case "peri":   return Peripherals.model !== "" ? Peripherals.model
                                                       : I18n.t("isle.src.peri");
        case "power":  return Power.percent + "%";
        case "net":    return Network.wired ? (Network.wiredName !== "" ? Network.wiredName
                                                                        : I18n.t("isle.net.cable"))
                              : Network.connected ? Network.ssid
                                                  : I18n.t("isle.net.gone");
        case "vpn":    return Vpn.up ? Vpn.iface : I18n.t("isle.vpn.off");
        case "print":  return I18n.t("isle.src.print");
        }
        return "";
    }

    readonly property real fraction: body.fractionFor(body.kind)

    function fractionFor(k) {
        switch (k) {
        case "osd":    return Feedback.showBar ? Feedback.value : -1;
        case "timer":  return Timers.soonest ? Timers.progress(Timers.soonest) : -1;
        case "media":  return Media.hasPosition ? Media.progress : -1;
        case "power":  return Power.fraction;
        case "peri":   return Peripherals.percent / 100;
        }
        return -1;
    }

    SystemClock { id: clockTick; precision: SystemClock.Minutes }

    readonly property Loader card: body.front === 0 ? slotA : slotB
    readonly property Loader spare: body.front === 0 ? slotB : slotA
    readonly property string shownKind: body.alive ? body.card.kind : ""

    readonly property Item heroItem:
        card.item && card.status === Loader.Ready && card.item.hero ? card.item.hero : null
    readonly property bool cardReady: card.status === Loader.Ready && card.item !== null
    readonly property real heroRadius:
        card.item && card.item.heroRadius !== undefined ? card.item.heroRadius : -1

    property bool alive: false
    property int front: 0

    onWideChanged: {
        if (body.wide) {
            unmount.stop();
            body.alive = true;
            body.swap();
        } else {
            unmount.restart();
        }
    }

    onKindChanged: Qt.callLater(body.swap)

    function swap() {
        const cur = body.card.kind;
        if (body.kind === cur)
            return;
        if (!body.wide) {
            if (!body.alive)
                body.card.kind = body.kind;
            return;
        }
        if (cur === "" || body.kind === "") {
            body.card.kind = body.kind;
            return;
        }
        body.spare.kind = body.kind;
        body.front = 1 - body.front;
        spareDrop.restart();
    }

    Timer {
        id: spareDrop
        interval: 460
        onTriggered: body.spare.kind = ""
    }

    Timer {
        id: unmount
        interval: 360
        onTriggered: {
            body.alive = false;
            spareDrop.stop();
            slotA.kind = "";
            slotB.kind = "";
            body.front = 0;
            body.swap();
        }
    }

    function pick(k) {
        switch (k) {
        case "media":  return mediaCard;
        case "osd":    return osdCard;
        case "timer":  return timerCard;
        case "alarm":  return alarmCard;
        case "remind": return remindCard;
        case "record": return recordCard;
        case "notif":  return notifCard;
        case "call":   return callCard;
        case "jarvis": return jarvisCard;
        case "bt":     return btCard;
        case "peri":   return periCard;
        case "power":  return powerCard;
        case "net":    return netCard;
        case "vpn":    return vpnCard;
        case "print":  return printCard;
        case "clip":   return clipCard;
        case "cmd":    return cmdCard;
        case "shot":   return shotCard;
        case "weather": return weatherCard;
        }
        return null;
    }

    Item {
        id: deck

        anchors.fill: parent

        opacity: body.wide ? 1 : 0
        scale: body.wide ? 1 : 0.94
        visible: opacity > 0.01

        readonly property real haze: (1 - deck.opacity) * 0.5

        layer.enabled: deck.haze > 0.004
        layer.smooth: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 24
            blur: deck.haze
        }

        transform: Translate {
            y: body.wide ? 0 : 7
            Behavior on y {
                SequentialAnimation {
                    PauseAnimation {
                        duration: body.wide ? Motion.isleRevealDelay : 0
                    }
                    NumberAnimation {
                        duration: body.wide ? Motion.isleRevealMs : Motion.isleHideMs
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.isleContent
                    }
                }
            }
        }

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation {
                    duration: body.wide ? Motion.isleRevealDelay : 0
                }
                NumberAnimation {
                    duration: body.wide ? Motion.isleRevealMs : Motion.isleHideMs
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.isleContent
                }
            }
        }
        Behavior on scale {
            SequentialAnimation {
                PauseAnimation {
                    duration: body.wide ? Motion.isleRevealDelay : 0
                }
                NumberAnimation {
                    duration: body.wide ? Motion.isleRevealMs : Motion.isleHideMs
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.isleContent
                }
            }
        }

        IslandDeckSlot {
            id: slotA
            other: slotB
            isFront: body.front === 0
            active: body.alive && slotA.kind !== ""
            sourceComponent: body.pick(slotA.kind)
        }
        IslandDeckSlot {
            id: slotB
            other: slotA
            isFront: body.front === 1
            active: body.alive && slotB.kind !== ""
            sourceComponent: body.pick(slotB.kind)
        }
    }

    Component { id: mediaCard;  MediaCard  { tint: body.tint; demo: body.demo; big: body.big } }
    Component { id: osdCard;    OsdCard    { tint: body.tint; glyph: body.glyphFor("osd") } }
    Component { id: timerCard;  TimerCard  { tint: body.tint; demo: body.demo } }
    Component { id: alarmCard;  AlarmCard  {} }
    Component { id: remindCard; RemindCard { tint: body.tint } }
    Component { id: recordCard; RecordCard { demo: body.demo } }
    Component {
        id: notifCard
        NotifCard {
            tint: body.tint
            notifApp: body.notifApp
            notifBody: body.notifBody
            notifSummary: body.notifSummary
            notifImage: body.notifImage
            notifIcon: body.notifIcon
            count: body.notifCount
            msgs: body.notifMsgs
            critical: body.notifCritical
            live: body.notifLive
            tools: body.notifTools
            replying: body.notifReplying
            near: body.notifNear
            page: body.notifPage
            total: body.notifTotal
            onReply: (on) => body.notifReply(on)
            onDone: body.notifDone()
        }
    }
    Component {
        id: callCard
        CallCard {
            tint: body.tint
            call: body.call
            onAccept: body.callAccept()
            onDecline: body.callDecline()
        }
    }
    Component {
        id: clipCard
        ClipCard { tint: body.tint; clipImage: body.clipImage; clipText: body.clipText }
    }
    Component {
        id: btCard
        BtCard { tint: body.tint; demo: body.demo; glyph: body.glyphFor("bt"); headline: body.headlineFor("bt") }
    }
    Component {
        id: periCard
        PeriCard { demo: body.demo; glyph: body.glyphFor("peri"); headline: body.headlineFor("peri") }
    }
    Component { id: powerCard;  PowerCard  { tint: body.tint; demo: body.demo } }
    Component { id: netCard;    NetCard    { tint: body.tint; headline: body.headlineFor("net") } }
    Component { id: vpnCard;    VpnCard    { tint: body.tint } }
    Component { id: printCard;  PrintCard  { tint: body.tint; demo: body.demo } }
    Component {
        id: cmdCard
        CmdCard {
            tint: body.tint
            info: body.cmd
            took: body.cmdTook
            onFocusWin: (w) => body.focusWin(w)
        }
    }
    Component { id: jarvisCard; JarvisCard { tint: body.tint } }
    Component { id: weatherCard; WeatherCard { tint: body.tint; info: body.skyInfo } }
    Component {
        id: shotCard
        ShotCard {
            tint: body.tint
            path: body.shotPath
            onDismissed: body.dismissed()
        }
    }
}
