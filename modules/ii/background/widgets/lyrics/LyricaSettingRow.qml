import QtQuick
Row {
 id: root
 required property string label
 property string valueText: ""
 property color accent: "#a9baff"
 width: parent ? parent.width : implicitWidth
 spacing: 8
 Text { text: root.label; color: "#e7eaf6"; font.pixelSize: 13; font.weight: Font.Medium; width: parent.width - 70; anchors.verticalCenter: parent.verticalCenter }
 Text { text: root.valueText; color: root.accent; font.pixelSize: 12; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight; width: 62 }
}
