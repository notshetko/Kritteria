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

    signal styleEditorRequested()

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

    implicitWidth: vertical ? barThickness : (slotCount + 1) * workspaceButtonWidth
    implicitHeight: vertical ? (slotCount + 1) * workspaceButtonWidth : barThickness

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
                        } else {
                            root.styleEditorRequested();
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

    // The add slot appears at the end of the list. Hover for one second to
    // reveal the plus, then click to create and open a new named special space.
    Item {
        id: addSlot

        x: root.vertical ? 0 : root.slotCount * root.workspaceButtonWidth
        y: root.vertical ? root.slotCount * root.workspaceButtonWidth : 0
        width: root.vertical ? root.barThickness : root.workspaceButtonWidth
        height: root.vertical ? root.workspaceButtonWidth : root.barThickness

        property bool revealed: false

        Timer {
            id: revealTimer
            interval: 1000
            repeat: false
            onTriggered: addSlot.revealed = true
        }

        StateOverlay {
            anchors.centerIn: parent
            width: root.activeWorkspaceSize
            height: root.activeWorkspaceSize
            radius: root.activeWorkspaceSize / 2
            hover: addMouseArea.containsMouse
            press: addMouseArea.containsPress
            contentColor: Appearance.colors.colPrimary
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "add"
            iconSize: root.workspaceButtonWidth * 0.50
            color: root.contentColorOverridden ? root.contentColor : Appearance.colors.colOnLayer1
            opacity: addSlot.revealed ? 1 : 0

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        MouseArea {
            id: addMouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            cursorShape: addSlot.revealed ? Qt.PointingHandCursor : Qt.ArrowCursor

            onEntered: {
                addSlot.revealed = false;
                revealTimer.restart();
            }
            onExited: {
                revealTimer.stop();
                addSlot.revealed = false;
            }
            onClicked: {
                if (!addSlot.revealed) return;

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
                    ? `hl.dsp.workspace.toggle_special('${newName}')`
                    : `togglespecialworkspace ${newName}`;
                Hyprland.dispatch(command);
            }
        }
    }
}