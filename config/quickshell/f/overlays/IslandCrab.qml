import QtQuick
import "root:/design"
import "root:/services"

Item {
    id: crab

    property bool running: false
    property bool greeting: false
    property color body: Colors.accent
    property color eye: Colors.bg
    property int p: 2

    width: 14 * crab.p
    height: 9 * crab.p

    property int lookX: 0
    property bool shut: false
    property bool joy: false
    property int liftL: 0
    property int liftR: 0
    property int sway: 0
    property int hop: 0
    property int step: 0
    property int walk: 0

    property var frames: []
    property int at: 0

    readonly property real cpu: Sys.cpu < 0 ? 0 : Math.min(1, Sys.cpu)
    readonly property real energy: Math.max(0, Math.min(1, (crab.cpu - 0.25) / 0.5))
    readonly property bool calm: Power.present && Power.plugged
    readonly property real speed: crab.calm ? 0.8 : 1 + crab.energy * 1.2

    function blinkAct() {
        return Math.random() < 0.2
            ? [{ shut: true }, { shut: false }, {}, { shut: true }, { shut: false }]
            : [{ shut: true }, { shut: false }];
    }

    function lookAct() {
        const d = Math.random() < 0.5 ? -1 : 1;
        const f = [{ lookX: d }];
        for (let i = 0; i < 9; i++) f.push({});
        f.push({ lookX: 0 });
        return f;
    }

    function walkAct() {
        const d = Math.random() < 0.5 ? -1 : 1;
        const n = Math.max(2, Math.round((6 + Math.random() * 4) / crab.p));
        const f = [{ lookX: d, ms: 200 }];
        for (let i = 1; i <= n; i++)
            f.push({ walk: d * i, step: i % 2, ms: 200 });
        f.push({ step: 0, ms: 200 });
        const wait = 4 + Math.floor(Math.random() * 8);
        for (let i = 0; i < wait; i++)
            f.push(i === 2 && Math.random() < 0.5 ? { shut: true, ms: 110 } : { shut: false, ms: 110 });
        f.push({ lookX: -d, ms: 200 });
        for (let i = n - 1; i >= 0; i--)
            f.push({ walk: d * i, step: i % 2, ms: 200 });
        f.push({ lookX: 0, step: 0, ms: 200 });
        return f;
    }

    function shuffleAct() {
        return [{ sway: -1, step: 1 }, { sway: 0, step: 0 }, { sway: 1, step: 1 }, { sway: 0, step: 0 },
                { sway: -1, step: 1 }, { sway: 0, step: 0 }, { sway: 1, step: 1 }, { sway: 0, step: 0 }];
    }

    function patterAct() {
        const f = [];
        const n = 8 + Math.round(crab.energy * 10);
        for (let i = 0; i < n; i++)
            f.push({ step: i % 2, ms: 70 });
        f.push({ step: 0 });
        return f;
    }

    function clawAct() {
        return Math.random() < 0.6
            ? [{ liftL: 1, liftR: 1 }, { liftL: 0, liftR: 0 }, { liftL: 1, liftR: 1 }, { liftL: 0, liftR: 0 }]
            : [{ liftL: 1 }, { liftL: 0, liftR: 1 }, { liftL: 1, liftR: 0 }, { liftL: 0, liftR: 1 }, { liftR: 0 }];
    }

    function hopAct() {
        return [{ hop: 1, liftL: 1, liftR: 1 }, { hop: 0, liftL: 0, liftR: 0 }];
    }

    function acts() {
        const e = crab.energy;
        if (crab.calm)
            return [
                { w: 7, f: crab.blinkAct },
                { w: 3, f: crab.lookAct },
                { w: 1, f: crab.clawAct }
            ];
        return [
            { w: 5, f: crab.blinkAct },
            { w: 4, f: crab.lookAct },
            { w: 3, f: crab.walkAct },
            { w: 2, f: crab.shuffleAct },
            { w: 2, f: crab.clawAct },
            { w: 1 + e * 6, f: crab.patterAct },
            { w: 1, f: crab.hopAct }
        ];
    }

    function rest() {
        crab.lookX = 0; crab.shut = false; crab.joy = false; crab.liftL = 0; crab.liftR = 0;
        crab.sway = 0; crab.hop = 0; crab.step = 0; crab.walk = 0;
    }

    function pick() {
        const list = crab.acts();
        let total = 0;
        for (const a of list) total += a.w;
        let r = Math.random() * total;
        for (const a of list) {
            r -= a.w;
            if (r <= 0) return a.f();
        }
        return list[0].f();
    }

    function run(f) {
        crab.frames = f;
        crab.at = 0;
        crab.tick();
    }

    function play() {
        crab.run(crab.pick());
    }

    function nextGap() {
        let ms = 2500 + Math.random() * 5500;
        if (crab.calm)
            ms *= 1.6;
        else
            ms *= 1 - 0.6 * crab.energy;
        return ms;
    }

    function tick() {
        if (crab.at >= crab.frames.length) {
            frame.stop();
            if (crab.greeting)
                return;
            crab.rest();
            gap.interval = crab.nextGap();
            gap.restart();
            return;
        }
        const f = crab.frames[crab.at++];
        for (const k in f)
            if (k !== "ms")
                crab[k] = f[k];
        frame.interval = Math.round((f.ms || 110) / (crab.greeting ? 1 : crab.speed));
        frame.restart();
    }

    function greet() {
        gap.stop();
        frame.stop();
        metro.stop();
        land.stop();
        crab.rest();
        crab.joy = true;
        crab.run([
            { liftL: 1, liftR: 1, hop: 1, ms: 120 },
            { hop: 0, ms: 110 },
            { hop: 1, step: 1, ms: 120 },
            { hop: 0, step: 0, ms: 110 },
            { liftL: 0, liftR: 0, ms: 110 },
            { liftL: 1, liftR: 1, ms: 200 }
        ]);
    }

    property bool dancing: false
    property int move: 0
    property double lastBeat: 0
    property real punch: 0

    readonly property var moves: [
        { sway: -1, lookX: -1, liftL: 1, liftR: 0, step: 1 },
        { sway: 0, lookX: 0, liftL: 0, liftR: 0, step: 0 },
        { sway: 1, lookX: 1, liftL: 0, liftR: 1, step: 1 },
        { sway: 0, lookX: 0, liftL: 0, liftR: 0, step: 0 },
        { sway: -1, lookX: -1, liftL: 1, liftR: 1, step: 1 },
        { sway: 0, lookX: 0, liftL: 0, liftR: 0, step: 0 },
        { sway: 1, lookX: 1, liftL: 1, liftR: 1, step: 1 },
        { sway: 0, lookX: 0, liftL: 1, liftR: 1, step: 0, hop: 1 }
    ]

    function takeBeat() {
        const now = Date.now();
        if (now - crab.lastBeat < 230)
            return;
        crab.lastBeat = now;
        crab.dance();
    }

    function dance() {
        crab.move = (crab.move + 1) % crab.moves.length;
        const m = crab.moves[crab.move];
        crab.sway = m.sway;
        crab.lookX = m.lookX;
        crab.liftL = m.liftL;
        crab.liftR = m.liftR;
        crab.step = m.step;
        crab.hop = (m.hop || crab.punch > 0.75) ? 1 : 0;
        crab.shut = crab.move === 7 && Math.random() < 0.3;
        if (crab.hop || crab.shut)
            land.restart();
    }

    function wake() {
        gap.stop();
        frame.stop();
        metro.stop();
        land.stop();
        if (!crab.running)
            return;
        crab.rest();
        if (crab.greeting) {
            crab.greet();
        } else if (crab.dancing) {
            crab.move = 0;
            crab.lastBeat = 0;
            metro.start();
        } else {
            gap.interval = 900;
            gap.restart();
        }
    }

    property bool sysHeld: false

    function holdSys(on) {
        if (on === crab.sysHeld)
            return;
        crab.sysHeld = on;
        if (on)
            Sys.acquire();
        else
            Sys.release();
    }

    onRunningChanged: {
        crab.holdSys(crab.running);
        crab.wake();
    }
    onDancingChanged: if (!crab.greeting) crab.wake()
    onGreetingChanged: if (crab.greeting && crab.running) crab.greet()
    Component.onDestruction: crab.holdSys(false)

    Connections {
        target: Beat
        enabled: crab.running && crab.dancing && !crab.greeting
        function onHit() {
            crab.punch = Beat.pulse * Math.min(1, Beat.bass * 1.6);
            crab.takeBeat();
        }
    }

    Timer {
        id: metro
        interval: 545
        repeat: true
        onTriggered: if (Date.now() - crab.lastBeat > 900) crab.dance()
    }

    Timer {
        id: land
        interval: 130
        onTriggered: { crab.hop = 0; crab.shut = false; }
    }

    Timer { id: gap; onTriggered: if (!crab.dancing && !crab.greeting) crab.play() }
    Timer { id: frame; interval: 110; onTriggered: crab.tick() }

    Item {
        x: (crab.sway + crab.walk) * crab.p
        y: -crab.hop * crab.p
        width: crab.width
        height: crab.height

        Behavior on x {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        Rectangle { x: 3 * crab.p; y: crab.p; width: 8 * crab.p; height: crab.p; color: crab.body }
        Rectangle { x: 2 * crab.p; y: 2 * crab.p; width: 10 * crab.p; height: 4 * crab.p; color: crab.body }

        Rectangle { x: 0; y: (2 - crab.liftL) * crab.p; width: crab.p; height: 2 * crab.p; color: crab.body }
        Rectangle { x: crab.p; y: (3 - crab.liftL) * crab.p; width: crab.p; height: crab.p; color: crab.body }
        Rectangle { x: 13 * crab.p; y: (2 - crab.liftR) * crab.p; width: crab.p; height: 2 * crab.p; color: crab.body }
        Rectangle { x: 12 * crab.p; y: (3 - crab.liftR) * crab.p; width: crab.p; height: crab.p; color: crab.body }

        Repeater {
            model: [4, 9]
            Item {
                id: eyeSlot
                required property int modelData
                readonly property int h: Math.max(1, Math.round(crab.p / 2))
                x: (modelData + crab.lookX) * crab.p
                y: 2 * crab.p
                width: crab.p
                height: 2 * crab.p

                Rectangle {
                    visible: !crab.joy
                    y: crab.shut ? crab.p : 0
                    width: crab.p
                    height: crab.shut ? eyeSlot.h : 2 * crab.p
                    color: crab.eye
                }

                Rectangle { visible: crab.joy; x: -eyeSlot.h; y: eyeSlot.h; width: eyeSlot.h; height: eyeSlot.h; color: crab.eye }
                Rectangle { visible: crab.joy; x: 0; y: 0; width: crab.p; height: eyeSlot.h; color: crab.eye }
                Rectangle { visible: crab.joy; x: crab.p; y: eyeSlot.h; width: eyeSlot.h; height: eyeSlot.h; color: crab.eye }
            }
        }

        Repeater {
            model: [3, 5, 8, 10]
            Rectangle {
                required property int modelData
                required property int index
                x: modelData * crab.p
                y: 6 * crab.p
                width: crab.p
                height: ((index + crab.step) % 2 ? 1 : 2) * crab.p
                color: crab.body
            }
        }
    }
}
