pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
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
    readonly property int slotCount: specialNames.length

    WorkspaceModel {
        id: wsModel
        screen: root.QsWindow.window?.screen
    }

    // The module is optional in the bar layout. Keep the two named spaces available,
    // then append any additional special workspaces created in Hyprland.
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

            // Match the regular workspace active indicator; BarGroup supplies
            // the capsule/background and its own padding around this module.
            StyledRectangle {
                anchors {
                    verticalCenter: root.vertical ? undefined : parent.verticalCenter
                    horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                }
                x: root.vertical ? undefined : root.activeWorkspaceMargin
                y: root.vertical ? root.activeWorkspaceMargin : undefined
                implicitWidth: root.activeWorkspaceSize
                implicitHeight: root.activeWorkspaceSize
                radius: activeWorkspaceSize / 2
                color: specialSlot.active ? Appearance.colors.colPrimary : "transparent"

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }

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
                iconSize: root.workspaceButtonWidth * 0.50
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
