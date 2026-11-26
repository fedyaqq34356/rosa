import QtQuick
import "root:/design"

Item {
    id: sp

    visible: false

    property real target: 0
    property real value: 0
    property real velocity: 0

    property real response: Motion.isleOpenResponse
    property real damping:  Motion.isleOpenDamping
    property int  closeMs:  Motion.isleCloseMs
    property bool springBack: false
    property bool softClose: false

    property bool enabled: true

    property real epsilon: 0.0005

    readonly property bool running: tick.running

    property bool closing: false
    property real closeFrom: 0
    property real closeStart: 0

    onTargetChanged: sp.kick()

    onEnabledChanged: {
        if (sp.enabled)
            return;
        tick.running = false;
        sp.closing = false;
        sp.velocity = 0;
        sp.value = sp.target;
    }

    function settle(v) {
        tick.running = false;
        sp.closing = false;
        sp.velocity = 0;
        sp.target = v;
        sp.value = v;
    }

    function land() {
        tick.running = false;
        sp.closing = false;
        sp.velocity = 0;
        sp.value = sp.target;
    }

    function kick() {
        if (!sp.enabled) {
            sp.value = sp.target;
            return;
        }
        const down = sp.target < sp.value;
        sp.closing = down && !sp.springBack;
        if (sp.closing) {
            sp.closeFrom = sp.value;
            sp.closeStart = Date.now();
            sp.closeV = sp.velocity;
        }
        tick.running = true;
    }

    property real closeV: 0

    Timer {
        interval: 0
        running: true
        repeat: false
        onTriggered: if (sp.value !== sp.target) sp.kick()
    }

    FrameAnimation {
        id: tick
        running: false

        onTriggered: {
            if (sp.closing) {
                const T = Math.max(1, sp.closeMs) / 1000;
                const k = Math.min(1, (Date.now() - sp.closeStart) / (T * 1000));
                const d = sp.target - sp.closeFrom;
                let m0 = (sp.softClose ? 0 : 3 * d) + sp.closeV * T;
                m0 = d < 0 ? Math.max(m0, 3 * d) : Math.min(m0, 3 * d);
                const k2 = k * k;
                const k3 = k2 * k;
                sp.value = sp.closeFrom + d * (3 * k2 - 2 * k3) + m0 * (k3 - 2 * k2 + k);
                sp.velocity = (d * (6 * k - 6 * k2) + m0 * (3 * k2 - 4 * k + 1)) / T;
                if (k >= 1) {
                    sp.value = sp.target;
                    sp.velocity = 0;
                    sp.closing = false;
                    running = false;
                }
                return;
            }

            const w = 2 * Math.PI / Math.max(0.05, sp.response);
            const z = sp.damping;

            const dt = Math.min(frameTime, 0.05);
            const steps = Math.max(1, Math.ceil(dt / 0.004));
            const h = dt / steps;

            for (let i = 0; i < steps; i++) {
                const a = -w * w * (sp.value - sp.target) - 2 * z * w * sp.velocity;
                sp.velocity += a * h;
                sp.value += sp.velocity * h;
            }

            if (Math.abs(sp.value - sp.target) < sp.epsilon
                && Math.abs(sp.velocity) < sp.epsilon * w) {
                sp.value = sp.target;
                sp.velocity = 0;
                running = false;
            }
        }
    }
}
