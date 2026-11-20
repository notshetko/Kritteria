import QtQuick

Item {
    id: root
    property bool checked: false
    signal toggled(bool nextValue)
    implicitWidth: 44
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: 13
        color: root.checked ? "#6579b5" : "#3b4358"
        border.width: 1
        border.color: root.checked ? "#9eb0ef" : "#596178"
        Rectangle {
            width: 18
            height: 18
            radius: 9
            y: 3
            x: root.checked ? parent.width - width - 4 : 4
            color: "#f6f7ff"
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
