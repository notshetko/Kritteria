import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property color contentColor: Appearance.colors.colOnLayer0
    property bool contentColorOverridden: false
    property bool isMaterial: Config.options.bar.cornerStyle === 3 || Config.options.bar.cornerStyle === 4
    property bool vertical: Config.options.bar.vertical

    implicitWidth: root.isMaterial ? 32 : 22
    implicitHeight: root.isMaterial ? 32 : 22

    // BarGroup's Loader fills the group's height. Keep the actual button at
    // icon size so its ripple/background cannot stretch into a misplaced pill.
    RippleButton {
        id: button
        anchors.centerIn: parent
        width: root.isMaterial ? 32 : 22
        height: root.isMaterial ? 32 : 22

        buttonRadius: Appearance.rounding.full
        colBackground: "transparent"
        colBackgroundHover: Appearance.colors.colLayer1Hover
        colRipple: Appearance.colors.colLayer1Active

        onPressed: {
            GlobalStates.sessionOpen = !GlobalStates.sessionOpen
        }

        MaterialSymbol {
            anchors.centerIn: parent
            visible: !root.isMaterial
            text: "power_settings_new"
            iconSize: 18
            color: root.contentColorOverridden ? root.contentColor : Appearance.colors.colOnLayer0
        }

        MaterialShapeWrappedMaterialSymbol {
            anchors.centerIn: parent
            visible: root.isMaterial
            text: "power_settings_new"
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnPrimary
            colSymbol: Appearance.colors.colPrimary
            wrappedShape: MaterialShape.Shape.Cookie12Sided
            padding: 2
        }
    }
}