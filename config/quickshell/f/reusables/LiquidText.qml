import QtQuick
import QtQuick.Effects
import "root:/design"

Row {
    id: root

    property string text: ""
    property color color: "white"
    property string family: Fonts.mono
    property int pixelSize: Fonts.text
    property int weight: Font.DemiBold
    property int rollDuration: 320
    property real overshoot: 0
    property real melt: 0.17

    TextMetrics {
        id: metrics
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        font.features: { "tnum": 1 }
        text: "0"
    }

    Repeater {
        model: root.text.length

        Item {
            id: cell
            required property int index
            readonly property string ch: root.text.charAt(index)
            readonly property bool digit: /[0-9]/.test(cell.ch)
            property real t: 0

            TextMetrics {
                id: own
                font.family: root.family
                font.features: { "tnum": 1 }
                font.pixelSize: root.pixelSize
                font.weight: root.weight
                text: cell.ch
            }
            width: cell.digit ? metrics.width : Math.max(1, own.advanceWidth)
            height: metrics.height * 1.25

            readonly property real pad: Math.ceil(root.pixelSize * root.melt) + 2

            Item {
                id: box
                x: -cell.pad
                y: -cell.pad
                width: cell.width + cell.pad * 2
                height: cell.height + cell.pad * 2
                visible: false
                layer.enabled: true

                Text {
                    id: oldT
                    x: cell.pad
                    width: cell.width
                    horizontalAlignment: Text.AlignHCenter
                    y: cell.pad + (cell.height - metrics.height) / 2
                    text: ""
                    color: "white"
                    font.family: root.family
                    font.pixelSize: root.pixelSize
                    font.weight: root.weight
                    font.features: { "tnum": 1 }
                }
            }

            Item {
                id: boxB
                x: box.x
                y: box.y
                width: box.width
                height: box.height
                visible: false
                layer.enabled: true

                Text {
                    id: newT
                    x: cell.pad
                    width: cell.width
                    horizontalAlignment: Text.AlignHCenter
                    y: cell.pad + (cell.height - metrics.height) / 2
                    text: ""
                    color: "white"
                    font.family: root.family
                    font.pixelSize: root.pixelSize
                    font.weight: root.weight
                    font.features: { "tnum": 1 }
                }
            }

            readonly property bool moving: cell.t > 0.001 && cell.t < 0.999
            readonly property real wave: Math.sin(Math.PI * Math.max(0, Math.min(1, cell.t)))

            MultiEffect {
                id: blurA
                x: box.x; y: box.y; width: box.width; height: box.height
                source: box
                visible: cell.moving
                autoPaddingEnabled: false
                blurEnabled: cell.moving
                blurMax: Math.max(2, Math.round(root.pixelSize * root.melt))
                blur: cell.wave
            }
            MultiEffect {
                id: blurB
                x: box.x; y: box.y; width: box.width; height: box.height
                source: boxB
                visible: cell.moving
                autoPaddingEnabled: false
                blurEnabled: cell.moving
                blurMax: Math.max(2, Math.round(root.pixelSize * root.melt))
                blur: cell.wave
            }

            ShaderEffect {
                x: box.x
                y: box.y
                width: box.width
                height: box.height
                visible: cell.moving
                property variant srcA: ShaderEffectSource { sourceItem: blurA; hideSource: true; live: true }
                property variant srcB: ShaderEffectSource { sourceItem: blurB; hideSource: true; live: true }
                property real t: cell.t
                property color color: root.color
                fragmentShader: Qt.resolvedUrl("../design/shaders/liquidtext2.frag.qsb")
            }

            Text {
                x: 0
                width: cell.width
                horizontalAlignment: Text.AlignHCenter
                y: (cell.height - metrics.height) / 2
                visible: !cell.moving
                text: newT.text
                color: root.color
                font.family: root.family
                font.pixelSize: root.pixelSize
                font.weight: root.weight
                font.features: { "tnum": 1 }
            }

            Component.onCompleted: {
                oldT.text = cell.ch;
                newT.text = cell.ch;
            }

            onChChanged: {
                if (morph.running)
                    morph.complete();
                if (newT.text === cell.ch)
                    return;
                if (!cell.digit || !/[0-9]/.test(newT.text)) {
                    oldT.text = cell.ch;
                    newT.text = cell.ch;
                    return;
                }
                oldT.text = newT.text;
                newT.text = cell.ch;
                cell.t = 0;
                morph.restart();
            }

            NumberAnimation {
                id: morph
                target: cell
                property: "t"
                from: 0
                to: 1
                duration: Math.round(root.rollDuration * 1.7)
                easing.type: Easing.InOutSine
                onFinished: {
                    oldT.text = newT.text;
                    cell.t = 0;
                }
            }
        }
    }
}
