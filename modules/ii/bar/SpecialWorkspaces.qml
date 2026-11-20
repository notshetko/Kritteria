pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets

Item {
    id: root

    readonly property bool vertical: Config.options.bar.vertical
    readonly property real barThickness: vertical
        ? Appearance.sizes.verticalBarWidth
        : Appearance.sizes.barHeight
    readonly property real workspaceButtonWidth: (Config.options.bar.cornerStyle === 3
        || Config.options.bar.cornerStyle === 4) ? 30 : 26
    readonly property real activeWorkspaceMargin: 2
    readonly property real activeWorkspaceSize: workspaceButtonWidth - activeWorkspaceMargin * 2
    readonly property real workspaceIconSize: workspaceButtonWidth * 0.50
    readonly property int slotCount: specialNames.length

    WorkspaceModel {
        id: wsModel
        screen: root.QsWindow.window?.screen
    }

    // Keep Kritteria's chat/music spaces visible and append any other named specials.
    readonly property var specialNames: {
        const names = ["chat", "musica"];
        const workspaces = Hyprland.workspaces?.values ?? [];
        for (let i = 0; i < workspaces.length; i++) {
            const name = workspaces[i]?.name ?? "";
            if (!name.startsWith("special:")) continue;
            const shortName = name.slice("special:".length);
            if (shortName && !names.includes(shortName)) names.push(shortName);
        }
        return names;
    }

    implicitWidth: vertical ? barThickness : slotCount * workspaceButtonWidth
    implicitHeight: vertical ? slotCount * workspaceButtonWidth : barThickness

    Repeater {
        model: root.specialNames

        delegate: Item {
            id: specialSlot

            required property int index
            required property string modelData

            readonly property bool active: wsModel.specialWorkspaceName === modelData
            readonly property bool exists: (Hyprland.workspaces?.values ?? [])
                .some(workspace => workspace?.name === "special:" + modelData)
            readonly property string iconName: {
                const name = modelData.toLowerCase();
                if (name === "chat" || name.includes("discord")) return "forum";
                if (name === "musica" || name.includes("music") || name.includes("spotify")) return "music_note";
                return "widgets";
            }

            x: root.vertical ? 0 : index * root.workspaceButtonWidth
            y: root.vertical ? index * root.workspaceButtonWidth : 0
            width: root.vertical ? root.barThickness : root.workspaceButtonWidth
            height: root.vertical ? root.workspaceButtonWidth : root.barThickness

            // Same active pill geometry and primary color as the regular workspaces.
            Pill {
                anchors {
                    verticalCenter: root.vertical ? undefined : parent.verticalCenter
                    horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                }
                x: root.vertical ? 0 : root.activeWorkspaceMargin
                y: root.vertical ? root.activeWorkspaceMargin : 0
                implicitWidth: root.vertical ? root.activeWorkspaceSize : root.activeWorkspaceSize
                implicitHeight: root.vertical ? root.activeWorkspaceSize : root.activeWorkspaceSize
                opacity: specialSlot.active ? 1 : 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            // Reuse the same hover/press overlay as the original workspace indicators.
            StateOverlay {
                anchors.fill: parent
                radius: Math.min(width, height) / 2
                hover: mouseArea.containsMouse
                press: mouseArea.containsPress
                drag: true
                contentColor: Appearance.colors.colPrimary
            }

            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: root.workspaceIconSize
                color: specialSlot.active
                    ? Appearance.colors.colOnPrimary
                    : Appearance.colors.colOnLayer1
                opacity: specialSlot.exists || specialSlot.active ? 1 : 0.55
                text: specialSlot.iconName

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    const command = Hyprland.usingLua
                        ? `hl.dsp.workspace.toggle_special('${specialSlot.modelData}')`
                        : `togglespecialworkspace ${specialSlot.modelData}`;
                    Hyprland.dispatch(command);
                }
            }
        }
    }
}
