pragma Singleton

import qs
import QtQuick
import Quickshell

Singleton {
    id: root

    function runSystemUpdate() {
        Quickshell.execDetached([
            "kitty", "--hold",
            "fish", "-i", "-l", "-c",
            "yay -Syu --combinedupgrade=false"
        ])
        Qt.callLater(() => GlobalStates.settingsOpen = false)
    }

    function runUpdateDots() {
        Quickshell.execDetached([
            "kitty", "--hold", "bash", "-lc",
            "exec \"$HOME/.config/quickshell/end4-pC/scripts/kritteria-update.sh\""
        ])
        Qt.callLater(() => GlobalStates.settingsOpen = false)
    }
}
