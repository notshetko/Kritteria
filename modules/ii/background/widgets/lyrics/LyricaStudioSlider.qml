import QtQuick
Item {
 id: slider
 property real from: 0
 property real to: 1
 property real value: 0
 property real stepSize: 0.01
 property color accent: "#a9baff"
 signal moved(real nextValue)
 implicitHeight: 30
 implicitWidth: 180
 readonly property real normalized: Math.max(0, Math.min(1, (value - from) / Math.max(0.0001, to - from)))
 Rectangle {
  anchors.left: parent.left
  anchors.right: parent.right
  anchors.verticalCenter: parent.verticalCenter
  height: 5
  radius: 3
  color: "#394258"
  Rectangle { width: parent.width * slider.normalized; height: parent.height; radius: parent.radius; color: slider.accent }
 }
 Rectangle {
  width: 17; height: 17; radius: 9
  x: Math.max(0, Math.min(parent.width - width, slider.normalized * parent.width - width / 2))
  anchors.verticalCenter: parent.verticalCenter
  color: "#f5f6ff"; border.width: 3; border.color: slider.accent
 }
 MouseArea {
  anchors.fill: parent; hoverEnabled: true; preventStealing: true
  cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
  function updateValue(mouseX) {
   const raw = slider.from + Math.max(0, Math.min(1, mouseX / Math.max(1, width))) * (slider.to - slider.from)
   const stepped = slider.from + Math.round((raw - slider.from) / Math.max(0.000001, slider.stepSize)) * slider.stepSize
   slider.moved(Math.max(slider.from, Math.min(slider.to, stepped)))
  }
  onPressed: mouse => updateValue(mouse.x)
  onPositionChanged: mouse => { if (pressed) updateValue(mouse.x) }
 }
}
