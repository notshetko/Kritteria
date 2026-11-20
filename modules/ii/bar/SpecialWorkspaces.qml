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
    readonly property int slotSize: 28
    readonly property int slotGap: 2

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

    readonly property int slotsLength: specialNames.length * slotSize
        + Math.max(0, specialNames.length - 1) * slotGap + 8

    implicitWidth: vertical ? slotSize + 8 : slotsLength
    implicitHeight: vertical ? slotsLength : slotSize + 8

    StyledRectangle {
        anchors.fill: parent
        radius: height / 2
        color: ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.4)
    }

    Repeater {
        model: root.specialNames

        delegate: Item {
            id: specialSlot
            required property int index
            required property string modelData

            readonly property bool active: wsModel.specialWorkspaceName === modelData
            readonly property bool exists: (Hyprland.workspaces?.values ?? [])
                .some(workspace => workspace?.name === "special:" + modelData)

            x: root.vertical ? 4 : 4 + index * (root.slotSize + root.slotGap)
            y: root.vertical ? 4 + index * (root.slotSize + root.slotGap) : 4
            width: root.slotSize
            height: root.slotSize

            Pill {
                anchors.fill: parent
                anchors.margins: 2
                color: specialSlot.active ? Appearance.colors.colPrimary : "transparent"
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }

            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: 17
                color: specialSlot.active ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                opacity: specialSlot.exists || specialSlot.active ? 1 : 0.55
                text: {
                    const name = specialSlot.modelData.toLowerCase();
                    if (name === "chat" || name.includes("discord")) return "forum";
                    if (name === "musica" || name.includes("music") || name.includes("spotify")) return "music_note";
                    return "widgets";
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
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
