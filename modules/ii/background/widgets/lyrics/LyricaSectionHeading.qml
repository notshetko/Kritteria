import QtQuick
Column {
 id: root
 required property string heading
 required property string description
 width: parent ? parent.width : implicitWidth
 spacing: 4
 Text { text: root.heading; color: "#f5f6ff"; font.pixelSize: 16; font.weight: Font.DemiBold }
 Text { text: root.description; color: "#aeb7ce"; font.pixelSize: 12; wrapMode: Text.Wrap; width: parent.width }
}
