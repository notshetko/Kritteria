import QtQuick
import qs.modules.common

Item {
    id: root

    property real cardRadius: 0
    property real topLeftRadius: cardRadius
    property real topRightRadius: cardRadius
    property real bottomRightRadius: cardRadius
    property real bottomLeftRadius: cardRadius
    property color tint: "transparent"
    property bool glassEnabled: true
    property bool fullscreenSurface: false
    // end4-pC's original subtle glass tint level; the compositor provides the live blur.
    property real tintStrength: 0.30
    // Kept for compatibility with existing bar/panel callers.
    property real flareLeft: 0
    property real flareRight: 0
    property real hangLeft: 0
    property real hangRight: 0
    property int edge: 0

    readonly property real materialAlpha: Math.max(0, Math.min(1, root.tint.a * root.tintStrength))

    Rectangle {
        anchors.fill: parent
        visible: root.glassEnabled
            && (Config.options?.background?.widgets?.glass?.enable ?? false)
            && root.materialAlpha > 0.005
        radius: root.cardRadius
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomRightRadius: root.bottomRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        antialiasing: true
        color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, root.materialAlpha)
        border.width: 0
    }
}
