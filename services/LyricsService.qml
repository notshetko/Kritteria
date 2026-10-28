pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    readonly property MprisPlayer activePlayer: MprisController.activePlayer

    property var lyricsLines: []
    property int activeIndex: -1
    property string status: "loading"
    property var slots: ["", "", "", "", "", "", ""]
    property var romajiSlots: ["", "", "", "", "", "", ""]
    property var translationSlots: ["", "", "", "", "", "", ""]
    property string sourceLabel: ""

    readonly property int before: 3
    readonly property int after:  3
    readonly property int total:  7

    function buildSlots(idx) {
        let result = []
        for (let i = 0; i < root.total; i++) {
            let lineIdx = idx - root.before + i
            if (lineIdx >= 0 && lineIdx < root.lyricsLines.length)
                result.push(root.lyricsLines[lineIdx].text || "♪")
            else
                result.push("")
        }
        return result
    }

    function buildRomajiSlots(idx) {
        let result = []
        for (let i = 0; i < root.total; i++) {
            const lineIdx = idx - root.before + i
            result.push(lineIdx >= 0 && lineIdx < root.lyricsLines.length ? (root.lyricsLines[lineIdx].romaji || "") : "")
        }
        return result
    }

    function buildTranslationSlots(idx) {
        let result = []
        for (let i = 0; i < root.total; i++) {
            const lineIdx = idx - root.before + i
            result.push(lineIdx >= 0 && lineIdx < root.lyricsLines.length ? (root.lyricsLines[lineIdx].translation || "") : "")
        }
        return result
    }

    readonly property bool playing: root.activePlayer?.isPlaying ?? false
    readonly property bool synced: root.status === "ok" && root.lyricsLines.length > 0
    readonly property real leadSeconds: 0.1

    property real basePosition: 0
    property real baseTime: Date.now()

    function currentPosition() {
        return root.playing ? root.basePosition + (Date.now() - root.baseTime) / 1000 : root.basePosition
    }

    function resync() {
        if (!root.activePlayer) return
        root.activePlayer.positionChanged()
        readPositionTimer.restart()
    }

    function indexAt(pos) {
        const lines = root.lyricsLines
        let low = 0
        let high = lines.length - 1
        let result = -1
        while (low <= high) {
            const mid = (low + high) >> 1
            if (lines[mid].time <= pos) {
                result = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return result
    }

    function update() {
        boundaryTimer.stop()
        if (!root.synced) return
        const idx = root.currentPosition() < 1.0 ? 0 : Math.max(0, root.indexAt(root.currentPosition() + root.leadSeconds))
        if (idx !== root.activeIndex) {
            root.activeIndex = idx
            root.slots = root.buildSlots(idx)
            root.romajiSlots = root.buildRomajiSlots(idx)
            root.translationSlots = root.buildTranslationSlots(idx)
        }
        if (root.currentPosition() < 1.0) {
            boundaryTimer.interval = 1000
            boundaryTimer.start()
            return
        }
        const next = root.lyricsLines[idx + 1]
        if (!root.playing || !next) return
        const delay = (next.time - root.leadSeconds - root.currentPosition()) * 1000
        boundaryTimer.interval = Math.max(1, Math.ceil(delay))
        boundaryTimer.start()
    }

    Timer {
        id: readPositionTimer
        interval: 80
        onTriggered: {
            root.basePosition = root.activePlayer?.position ?? 0
            root.baseTime = Date.now()
            root.update()
        }
    }

    Timer {
        id: boundaryTimer
        onTriggered: root.update()
    }

    Timer {
        id: driftTimer
        interval: 4000
        repeat: true
        running: root.synced && root.playing
        onTriggered: root.resync()
    }

    Process {
        id: lyricsProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim()
                if (trimmed === "not_found") { root.status = "not_found"; return }
                if (trimmed === "no_info")   { root.status = "no_info";   return }

                const parts = trimmed.split("§")
                if (parts.length < 3) return
                if (parts[parts.length - 1].trim() !== "ok") return

                let lines = []
                const sourceAt = parts.indexOf("__SOURCE__")
                const dataEnd = sourceAt >= 0 ? sourceAt : parts.length - 1
                try { root.sourceLabel = sourceAt >= 0 && sourceAt + 1 < parts.length ? decodeURIComponent(parts[sourceAt + 1] || "") : "" } catch (_) { root.sourceLabel = "" }
                for (let i = 0; i + 4 < dataEnd; i += 5) {
                    const t = parseFloat(parts[i])
                    let txt = "", romaji = "", translation = ""
                    try { txt = decodeURIComponent(parts[i + 1] || "") } catch (_) { txt = parts[i + 1] || "" }
                    try { romaji = decodeURIComponent(parts[i + 2] || "") } catch (_) { romaji = parts[i + 2] || "" }
                    try { translation = decodeURIComponent(parts[i + 3] || "") } catch (_) { translation = parts[i + 3] || "" }
                    const wordRaw = parts[i + 4] || ""
                    const words = []
                    for (const pair of wordRaw.split("~")) {
                        const values = pair.split(",")
                        const start = parseFloat(values[0])
                        const end = parseFloat(values[1])
                        if (values.length >= 2 && !isNaN(start) && !isNaN(end) && end > start) {
                            let wordText = "", wordRomaji = ""
                            try { wordText = decodeURIComponent(values[2] || "") } catch (_) {}
                            try { wordRomaji = decodeURIComponent(values[3] || "") } catch (_) {}
                            words.push({ start: start, end: end, text: wordText, romaji: wordRomaji })
                        }
                    }
                    if (!isNaN(t)) lines.push({ time: t, text: txt, romaji: romaji, translation: translation, words: words })
                }

                if (lines.length === 0) { root.status = "not_found"; return }

                root.lyricsLines = lines
                root.activeIndex = -1
                root.slots = root.buildSlots(-1)
                root.romajiSlots = root.buildRomajiSlots(-1)
                root.status = "ok"
                root.resync()
            }
        }
    }

    function restartLyrics() {
        lyricsProc.running = false
        boundaryTimer.stop()
        root.lyricsLines = []
        root.activeIndex = -1
        root.slots = ["", "", "", "", "", "", ""]
        root.romajiSlots = ["", "", "", "", "", "", ""]
        root.sourceLabel = ""
        root.status = "loading"

        const title    = root.activePlayer?.trackTitle  ?? ""
        const artist   = root.activePlayer?.trackArtist ?? ""
        const duration = root.activePlayer?.length       ?? 0

        if (!title || !artist) { root.status = "no_info"; return }

        lyricsProc.command = [
            "bash",
            `${Directories.scriptPath}/lyrics/lyrics-runner.sh`,
            title, artist, String(Math.floor(duration)), root.activePlayer?.trackAlbum ?? ""
        ]
        lyricsProc.running = true
    }

    Timer {
        id: restartDebounce
        interval: 150
        onTriggered: root.restartLyrics()
    }

    onActivePlayerChanged: restartDebounce.restart()

    Connections {
        target: root.activePlayer
        function onTrackTitleChanged() { root.restartLyrics() }
        function onTrackArtistChanged() { restartDebounce.restart() }
        function onPlaybackStateChanged() { root.resync() }
    }

    Component.onCompleted: root.restartLyrics()
}