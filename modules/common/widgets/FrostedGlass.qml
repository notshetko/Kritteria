import QtQuick

// True translucent material. No wallpaper file, screenshot, or QML texture capture.
// Hyprland supplies the live backdrop blur for this surface, clipped by this item alpha.
Item {
    id: root
    // Compatibility only: old call sites may pass this, but it is never sampled.
    property Item blurSource: null
    property real cardRadius: 30
    property real topLeftRadius: cardRadius
    property real topRightRadius: cardRadius
    property real bottomRightRadius: cardRadius
    property real bottomLeftRadius: cardRadius
    property color tint: "#242531"
    property real tintOpacity: 0.48
    property real trackX: 0
    property real trackY: 0
    property real flareLeft: 0
    property real flareRight: 0
    property real hangLeft: 0
    property real hangRight: 0
    property int edge: 0

    readonly property real materialAlpha: Math.max(0, Math.min(1, root.tintOpacity * root.tint.a))

    Rectangle {
        anchors.fill: parent
        radius: root.cardRadius
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomRightRadius: root.bottomRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        antialiasing: true
        color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, root.materialAlpha)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.18 * root.materialAlpha)
    }

    // Fine highlight, inset to follow the same rounded card rather than making a second edge.
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Math.max(root.topLeftRadius * 0.72, 5)
        anchors.rightMargin: Math.max(root.topRightRadius * 0.72, 5)
        height: 1
        radius: 0.5
        color: Qt.rgba(1, 1, 1, 0.16 * root.materialAlpha)
        visible: parent.height > 3 && root.materialAlpha > 0.05
    }
}
