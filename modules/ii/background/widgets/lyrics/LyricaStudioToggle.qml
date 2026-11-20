import QtQuick
import QtQuick.Controls

Switch {
    id: control
    property color accent: "#a9baff"
    implicitWidth: 48
    implicitHeight: 30
    padding: 0
    indicator: Rectangle {
        x: control.width - width
        y: (control.height - height) / 2
        width: 44
        height: 24
        radius: 12
        color: control.checked ? Qt.darker(control.accent, 1.45) : "#3b4358"
        border.width: 1
        border.color: control.checked ? control.accent : "#596178"
        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 2
            x: control.checked ? parent.width - width - 3 : 3
            color: "#f6f7ff"
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
    }
    contentItem: Item {}
}
