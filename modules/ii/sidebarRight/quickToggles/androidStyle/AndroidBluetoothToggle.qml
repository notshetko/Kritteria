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

    // This tile is the entry point to the nearby-device list.
    // A normal click must open the dialog instead of only toggling the adapter.
    toggleModel: BluetoothToggle {
        mainAction: () => root.openMenu()
    }
}
