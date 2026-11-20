pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common

Item {
    id: root

    property color contentColor: Appearance.colors.colOnLayer1
    property bool contentColorOverridden: false
    signal styleEditorRequested()

    readonly property bool vertical: Config.options.bar.vertical
    readonly property real capsuleGap: 6

    Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical

    implicitWidth: vertical
        ? Math.max(workspacesLoader.implicitWidth, specialLoader.implicitWidth)
        : workspacesLoader.implicitWidth + capsuleGap + specialLoader.implicitWidth
    implicitHeight: vertical
        ? workspacesLoader.implicitHeight + capsuleGap + specialLoader.implicitHeight
        : Math.max(workspacesLoader.implicitHeight, specialLoader.implicitHeight)

    Loader {
        id: workspacesLoader
        source: Qt.resolvedUrl("./WorkspacesBase.qml")
        x: root.vertical ? (root.width - width) / 2 : 0
        y: 0

        Binding {
            target: workspacesLoader.item
            property: "contentColor"
            value: root.contentColor
            when: !!workspacesLoader.item
        }
        Binding {
            target: workspacesLoader.item
            property: "contentColorOverridden"
            value: root.contentColorOverridden
            when: !!workspacesLoader.item
        }
        Connections {
            target: workspacesLoader.item
            ignoreUnknownSignals: true
            function onStyleEditorRequested() {
                root.styleEditorRequested();
            }
        }
    }

    Loader {
        id: specialLoader
        source: Qt.resolvedUrl("./SpecialWorkspaces.qml")
        x: root.vertical ? (root.width - width) / 2 : workspacesLoader.width + root.capsuleGap
        y: root.vertical ? workspacesLoader.height + root.capsuleGap : (root.height - height) / 2
    }
}
