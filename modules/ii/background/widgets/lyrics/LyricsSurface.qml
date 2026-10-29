pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets.lyrics

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: lyricsSurface
        required property var modelData

        screen: modelData
        visible: Config.ready
            && Config.options.background.widgets.lyrics.enable
            && (Config.options.background.screenList.length === 0
                || Config.options.background.screenList.includes(modelData.name))
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:lyrics"
        // When desktop widgets are unlocked, place this masked surface above the full-screen
        // background surface so its MouseArea receives drag events. Return to Bottom when locked.
        WlrLayershell.layer: (!Config.options.background.widgetsLocked && !GlobalStates.screenLocked)
            ? WlrLayer.Top
            : WlrLayer.Bottom
        WlrLayershell.keyboardFocus: GlobalStates.desktopWidgetKeyboardFocus
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Kritteria isolated lyrics surface; only the lyrics widget belongs here.
        // The input region follows only this widget; other desktop widgets remain untouched.
        mask: Region {
            item: lyricsWidget
        }

        WidgetCanvas {
            id: lyricCanvas
            anchors.fill: parent

            LyricsDesktopWidget {
                id: lyricsWidget
                screenWidth: lyricsSurface.modelData.width
                screenHeight: lyricsSurface.modelData.height
                scaledScreenWidth: lyricsSurface.modelData.width
                scaledScreenHeight: lyricsSurface.modelData.height
                wallpaperScale: 1
            }
        }
    }
}
