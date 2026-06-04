import QtQuick

MouseArea {
    id: root
    property int scrollAccumulatedY: 0

    function onWheel(event: WheelEvent): void {
    }

    Component.onCompleted: {
        wheel.connect(event => {
            if (Math.sign(event.angleDelta.y) !== Math.sign(scrollAccumulatedY))
                scrollAccumulatedY = 0;
            scrollAccumulatedY += event.angleDelta.y;

            if (Math.abs(scrollAccumulatedY) >= 120) {
                root.onWheel(event);
                scrollAccumulatedY = 0;
            }
        });
    }
}
