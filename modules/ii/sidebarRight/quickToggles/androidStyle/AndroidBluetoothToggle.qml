import qs.services
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Bluetooth

AndroidQuickToggleButton {
    id: root

    // Bypass the nested toggle -> delegate chooser -> panel signal chain.
    // SidebarRightContent already listens to this global request signal.
    function requestDeviceDialog() {
        GlobalStates.requestBluetoothDialog();
    }

    toggleModel: BluetoothToggle {
        mainAction: () => root.requestDeviceDialog()
    }

    onOpenMenu: root.requestDeviceDialog()
}
