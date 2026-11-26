import QtQuick

Loader {
    id: slot
    property string kind: ""
    property Loader other: null
    property bool isFront: false
    readonly property bool ready: slot.status === Loader.Ready && slot.item !== null

    anchors.fill: parent
    asynchronous: true

    opacity: slot.isFront ? (slot.ready ? 1 : 0)
                          : (slot.other && !slot.other.ready ? 1 : 0)
    scale: slot.isFront || (slot.other && !slot.other.ready) ? 1 : 0.97
    visible: opacity > 0.01
    z: slot.isFront ? 1 : 0

    Behavior on opacity {
        enabled: slot.other !== null && slot.other.kind !== ""
        NumberAnimation { duration: 260; easing.type: Easing.InOutSine }
    }
    Behavior on scale {
        enabled: slot.other !== null && slot.other.kind !== ""
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
}
