import QtQuick
import QtQuick.Controls

Slider {
    id: control
    property color accent: "#a9baff"
    implicitHeight: 34
    implicitWidth: 180
    padding: 0
    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.availableWidth
        height: 5
        radius: 3
        color: "#394258"
        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: 3
            color: control.accent
        }
    }
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: 17
        height: 17
        radius: 9
        color: control.pressed ? "#ffffff" : "#e9edff"
        border.width: 3
        border.color: control.accent
    }
}
