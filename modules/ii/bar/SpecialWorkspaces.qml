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
    property color contentColor: Appearance.colors.colOnLayer1
    property bool contentColorOverridden: false
    readonly property real barThickness: vertical
        ? Appearance.sizes.verticalBarWidth
        : Appearance.sizes.barHeight
    readonly property real workspaceButtonWidth: (Config.options.bar.cornerStyle === 3
        || Config.options.bar.cornerStyle === 4) ? 30 : 26
    readonly property real activeWorkspaceMargin: 2
    readonly property real activeWorkspaceSize: workspaceButtonWidth - activeWorkspaceMargin * 2
    readonly property var specialNames: Config.options.bar.specialWorkspaces ?? ["chat", "musica"]
    readonly property int slotCount: specialNames.length

    WorkspaceModel {
        id: wsModel
        screen: root.QsWindow.window?.screen
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
            property bool hovered: false
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

            StyledRectangle {
                anchors {
                    verticalCenter: root.vertical ? undefined : parent.verticalCenter
                    horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                }
                x: root.vertical ? undefined : root.activeWorkspaceMargin
                y: root.vertical ? root.activeWorkspaceMargin : undefined
                implicitWidth: root.activeWorkspaceSize
                implicitHeight: root.activeWorkspaceSize
                radius: root.activeWorkspaceSize / 2
                color: specialSlot.active ? Appearance.colors.colPrimary : "transparent"

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }

            StateOverlay {
                anchors.centerIn: parent
                width: root.activeWorkspaceSize
                height: root.activeWorkspaceSize
                radius: root.activeWorkspaceSize / 2
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
                    : (root.contentColorOverridden ? root.contentColor : Appearance.colors.colOnLayer1)
                opacity: specialSlot.hovered ? 0 : (specialSlot.exists || specialSlot.active ? 1 : 0.55)
                text: specialSlot.iconName

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 1
                anchors.topMargin: 1
                width: 15
                height: 15
                radius: 8
                color: Appearance.colors.colPrimary
                opacity: specialSlot.hovered ? 1 : 0
                visible: opacity > 0
                z: 5

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "add"
                    iconSize: 12
                    color: Appearance.colors.colOnPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const names = root.specialNames.slice();
                        let number = 1;
                        let newName = "extra" + number;
                        while (names.includes(newName)) {
                            number++;
                            newName = "extra" + number;
                        }
                        names.push(newName);
                        Config.options.bar.specialWorkspaces = names;
                        const command = Hyprland.usingLua
                            ? "hl.dsp.workspace.toggle_special('" + newName + "')"
                            : "togglespecialworkspace " + newName;
                        Hyprland.dispatch(command);
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onEntered: specialSlot.hovered = true
                onExited: specialSlot.hovered = false

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        if ((mouse.modifiers & Qt.MetaModifier) !== 0) {
                            // Remove the slot from the bar without closing its windows.
                            const remaining = root.specialNames.filter(name => name !== specialSlot.modelData);
                            Config.options.bar.specialWorkspaces = remaining;
                            if (specialSlot.active) {
                                const command = Hyprland.usingLua
                                    ? `hl.dsp.workspace.toggle_special('${specialSlot.modelData}')`
                                    : `togglespecialworkspace ${specialSlot.modelData}`;
                                Hyprland.dispatch(command);
                            }
                        } else if (specialSlot.active) {
                            // Right-click closes the currently visible special workspace.
                            const command = Hyprland.usingLua
                                ? "hl.dsp.workspace.toggle_special('" + specialSlot.modelData + "')"
                                : "togglespecialworkspace " + specialSlot.modelData;
                            Hyprland.dispatch(command);
                        }
                        return;
                    }

                    const command = Hyprland.usingLua
                        ? `hl.dsp.workspace.toggle_special('${specialSlot.modelData}')`
                        : `togglespecialworkspace ${specialSlot.modelData}`;
                    Hyprland.dispatch(command);
                }
            }
        }
    }

}
