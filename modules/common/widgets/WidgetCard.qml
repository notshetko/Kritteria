import QtQuick
import qs.modules.common

Rectangle {
    id: root
    required property var widget
    property bool blurred: Config.options.background.widgets.blurWidgets
    property bool shadowed: Config.options.background.widgets.shadow
    property color tint: Appearance.colors.colLayer1
    property real tintOpacity: 0.48
    property bool glass: true

    radius: Appearance.rounding?.verylarge ?? 30
    color: root.widget?.configEntryName === "resources"
        && root.glass && Config.options.background.widgets.glass.enable
        ? "transparent" : Appearance.colors.colPrimaryContainer

    StyledRectangularShadow {
        target: root
        z: -2
        visible: root.shadowed
    }

    // Native live backdrop glass only on resource cards. Lyrics and visualizer do not use WidgetCard.
    FrostedGlass {
        anchors.fill: parent
        blurSource: null
        cardRadius: root.radius
        tint: root.tint
        tintOpacity: root.tintOpacity
        visible: root.widget?.configEntryName === "resources"
            && root.glass
            && Config.options.background.widgets.glass.enable
    }

    // The old QML FastBlur required a wallpaper texture, which Kritteria intentionally removed.
    // Native Hyprland blur replaces it; keep the compatibility setting without sampling a fake image.
    FastBlurred {
        anchors.fill: parent
        blurSource: null
        cardRadius: root.radius
        tint: root.tint
        tintOpacity: root.tintOpacity
        visible: false
    }
}
