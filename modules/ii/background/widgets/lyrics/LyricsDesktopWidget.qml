pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.visualizer
import qs.services

// SekaiPop-inspired lyric wheel. Uses end4-pC's normal desktop-widget drag and resize behavior.
AbstractBackgroundWidget {
    id: root
    configEntryName: "lyrics"
    needsColText: false
    hoverEnabled: true
    // While Studio is open, let its controls receive pointer and keyboard input
    // instead of allowing the desktop-widget drag handler to grab the interaction.
    draggable: placementStrategy === "free" && !Config.options.background.widgetsLocked && !settingsOpen

    width: root.widgetWidth
    height: root.widgetHeight
    implicitWidth: root.widgetWidth
    implicitHeight: root.widgetHeight
    property real widgetWidth: configEntry.width ?? 1240
    property real widgetHeight: configEntry.height ?? 560
    property real resizeStartHeight: -1
    property real resizeStartWidth: -1
    property real shimmer: 0
    property real beatPulse: 0
    property real audioEnergy: 0.04
    property real audioTargetEnergy: 0
    property real lineProgress: 0
    property real lyricBounce: 0
    property bool songDone: false
    property bool settingsOpen: false
    property int activeWordIndex: -1
    property real activeWordProgress: 0
    property real karaokeHop: 0
    property bool transitionMark: false
    property bool instrumentalNow: false
    property bool instrumentalCandidate: false
    readonly property bool activeLineWordSynced: LyricsService.activeIndex >= 0 && (LyricsService.lyricsLines[LyricsService.activeIndex]?.words || []).length > 1
    readonly property int centerSlot: LyricsService.before
    // Mutable live state is intentional: Config.options stores nested JS data, whose member
    // mutations do not reliably notify QML bindings. Studio changes are relayed explicitly.
    property bool blurEnabled: configEntry.enableBlur ?? true
    property bool bounceEnabled: configEntry.enableBounce ?? true
    property bool backgroundEnabled: configEntry.enableBackground ?? true
    readonly property bool glitchEnabled: configEntry.enableGlitch ?? true
    property bool particlesEnabled: configEntry.enableParticles ?? true
    property bool karaokeBallEnabled: configEntry.enableKaraokeBall ?? true
    property bool waveLettersEnabled: configEntry.enableWaveLetters ?? false
    property real bounceIntensity: Math.max(0, Math.min(1, Number(configEntry.bounceIntensity ?? 0.55)))
    property real waveIntensity: Number(configEntry.waveIntensity ?? 0.38)
    property real waveSpeed: Number(configEntry.waveSpeed ?? 1.0)
    property real cloudOpacity: Number(configEntry.cloudOpacity ?? 0.55)
    property string accentMode: String(configEntry.accentMode ?? "album")
    readonly property real rowHeight: Math.max(44, Math.min(90, (root.height - 30) / 7))
    onActiveWordIndexChanged: {
        if (root.karaokeBallEnabled && root.activeWordIndex >= 0)
            karaokeHopAnimation.restart()
    }
    SequentialAnimation {
        id: karaokeHopAnimation
        NumberAnimation { target: root; property: "karaokeHop"; to: 1; duration: 62; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "karaokeHop"; to: 0; duration: 148; easing.type: Easing.InOutCubic }
    }

    readonly property string lyricFont: Appearance.font.family.main
    property real lyricFontWeight: Math.max(400, Math.min(900, Number(root.configEntry.lyricFontWeight ?? 700)))
    readonly property string albumArtUrl: String(LyricsService.activePlayer?.trackArtUrl ?? "")
    // Canvas samples the current MPRIS artwork into a tiny palette. Text and outlines follow the album,
    // with the outline always darker than the foreground for contrast. Material colors are fallback only.
    property color albumBaseColor: Appearance.colors.colPrimary ?? "#b7a1ff"
    property color albumSecondaryColor: Appearance.colors.colSecondary ?? "#8bc8ff"
    readonly property color albumGlowColor: root.albumBaseColor
    readonly property color lyricColor: {
        if (root.accentMode === "theme") return Appearance.colors.colPrimary ?? "#b7a1ff"
        const c = root.albumBaseColor
        const luminance = c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
        return luminance < 0.40 ? Qt.lighter(c, 2.55) : luminance > 0.82 ? Qt.darker(c, 1.18) : Qt.lighter(c, 1.25)
    }
    readonly property color accentColor: {
        const mode = root.accentMode
        if (mode === "theme") return Appearance.colors.colPrimary ?? "#b7a1ff"
        return root.albumSecondaryColor
    }
    readonly property color mutedColor: Qt.lighter(root.albumBaseColor, 1.42)
    readonly property color shadowColor: Qt.darker(root.lyricColor, 2.8)
    readonly property color albumCloudColorA: Qt.lighter(root.albumBaseColor, 1.42)
    readonly property color albumCloudColorB: root.albumBaseColor
    readonly property color albumCloudColorC: root.albumSecondaryColor


    function featureEnabled(key) {
        if (key === "blur") return root.blurEnabled
        if (key === "bounce") return root.bounceEnabled
        if (key === "background") return root.backgroundEnabled
        if (key === "glitch") return root.glitchEnabled
        if (key === "particles") return root.particlesEnabled
        if (key === "karaoke") return root.karaokeBallEnabled
        return false
    }

    function toggleFeature(key) {
        if (key === "blur") root.applyStudioSetting("enableBlur", !root.blurEnabled)
        else if (key === "bounce") root.applyStudioSetting("enableBounce", !root.bounceEnabled)
        else if (key === "background") root.applyStudioSetting("enableBackground", !root.backgroundEnabled)
        else if (key === "glitch") root.configEntry.enableGlitch = !root.glitchEnabled
        else if (key === "particles") root.applyStudioSetting("enableParticles", !root.particlesEnabled)
        else if (key === "karaoke") root.applyStudioSetting("enableKaraokeBall", !root.karaokeBallEnabled)
    }

    function applyStudioSetting(key, value) {
        if (key === "enableBlur") { root.blurEnabled = !!value; root.configEntry.enableBlur = !!value }
        else if (key === "enableBounce") { root.bounceEnabled = !!value; root.configEntry.enableBounce = !!value }
        else if (key === "enableBackground") { root.backgroundEnabled = !!value; root.configEntry.enableBackground = !!value }
        else if (key === "enableParticles") { root.particlesEnabled = !!value; root.configEntry.enableParticles = !!value }
        else if (key === "enableKaraokeBall") { root.karaokeBallEnabled = !!value; root.configEntry.enableKaraokeBall = !!value }
        else if (key === "enableWaveLetters") { root.waveLettersEnabled = !!value; root.configEntry.enableWaveLetters = !!value }
        else if (key === "bounceIntensity") { root.bounceIntensity = Number(value); root.configEntry.bounceIntensity = Number(value) }
        else if (key === "lyricFontWeight") { root.lyricFontWeight = Number(value); root.configEntry.lyricFontWeight = Number(value) }
        else if (key === "waveIntensity") { root.waveIntensity = Number(value); root.configEntry.waveIntensity = Number(value) }
        else if (key === "waveSpeed") { root.waveSpeed = Number(value); root.configEntry.waveSpeed = Number(value) }
        else if (key === "cloudOpacity") { root.cloudOpacity = Number(value); root.configEntry.cloudOpacity = Number(value) }
        else if (key === "accentMode") { root.accentMode = String(value); root.configEntry.accentMode = String(value) }
    }

    function normalizeLyricGeometry(value) {
        return String(value || "").toLocaleLowerCase()
            .replace(/\s+/g, "")
            .replace(/[.,!?;:·…—\-]/g, "")
            .replace(/[，。！？、：；・]/g, "")
            .replace(/[()\[\]{}'"’“”]/g, "")
    }

    // Map timed provider tokens onto the exact characters rendered by Text.
    // This avoids inventing spaces between fragments such as "de" + "vil's".
    function wordSpanInLine(displayed, words, wordIndex) {
        const source = String(displayed || "")
        if (!words || wordIndex < 0 || wordIndex >= words.length) return null
        const visibleIndexes = []
        for (let i = 0; i < source.length; i++) {
            const ch = source[i]
            if (!/\s/.test(ch) && !/[.,!?;:·…—\-()\[\]{}\'\"，。！？、：；・]/.test(ch)) visibleIndexes.push(i)
        }
        const tokenTexts = words.map(w => normalizeLyricGeometry(String(w.romaji || w.text || w.word || "")))
        const normalizedDisplay = normalizeLyricGeometry(source)
        if (tokenTexts.join("") !== normalizedDisplay || tokenTexts[wordIndex].length === 0) return null
        let startOffset = 0
        for (let i = 0; i < wordIndex; i++) startOffset += tokenTexts[i].length
        const endOffset = startOffset + tokenTexts[wordIndex].length
        if (startOffset >= visibleIndexes.length || endOffset > visibleIndexes.length) return null
        return { start: visibleIndexes[startOffset], end: visibleIndexes[endOffset - 1] + 1 }
    }

    function wordPrefixText(displayed, words, wordIndex) {
        const span = wordSpanInLine(displayed, words, wordIndex)
        return span ? String(displayed).slice(0, span.start) : ""
    }

    function wordSliceText(displayed, words, wordIndex) {
        const span = wordSpanInLine(displayed, words, wordIndex)
        return span ? String(displayed).slice(span.start, span.end) : ""
    }

    function highlightedLyricHtml(displayed, words, wordIndex, highlightColor) {
        const source = String(displayed || "")
        const span = wordSpanInLine(source, words, wordIndex)
        if (!span) return ""
        let out = "", active = false
        const esc = ch => ch.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        for (let i = 0; i < source.length; i++) {
            const nextActive = i >= span.start && i < span.end
            if (nextActive !== active) {
                out += nextActive ? "<font color='" + highlightColor + "'>" : "</font>"
                active = nextActive
            }
            out += esc(source[i])
        }
        if (active) out += "</font>"
        return out
    }

    Process {
        id: clearLyricsCache
        command: ["bash", "-lc", "$HOME/.config/quickshell/end4-pC/scripts/lyrics/lyrics-runner.sh --clear-cache"]
    }

    VisualizerEngine {
        id: lyricAudioEngine
        active: true
        sensitivity: 1.0
        maxValue: 1000
    }



    // Reuse the shell's existing CAVA stream; no second process or separate parser.
    // Keep Lyrica mounted even while MPRIS changes tracks or LyricsService fetches lyrics.
    visible: true
    opacity: 1
    clip: false

    Behavior on widgetWidth { animation: Appearance.animation.elementResize.numberAnimation.createObject(root) }
    Behavior on widgetHeight { animation: Appearance.animation.elementResize.numberAnimation.createObject(root) }

    function clampWidth(value) { return Math.max(500, Math.min(2000, value)); }
    function clampHeight(value) { return Math.max(280, Math.min(1000, value)); }

    Timer {
        interval: 16
        repeat: true
        running: root.visible
        onTriggered: {
            root.shimmer = root.shimmer + 0.013
            // Use the shell visualizer's own smoothed bass bands and transient beat pulse.
            const levels = lyricAudioEngine.levels
            let lowBands = 0
            let spectrumMean = 0
            let spectrumPeak = 0
            for (let i = 0; i < levels.length; i++) {
                const level = Math.max(0, Math.min(1, Number(levels[i] || 0)))
                if (i < 4) lowBands += level / 4
                spectrumMean += level / Math.max(1, levels.length)
                spectrumPeak = Math.max(spectrumPeak, level)
            }
            const beat = Math.max(0, Math.min(1, Number(lyricAudioEngine.bass || 0)))
            const target = Math.max(0, Math.min(1, lowBands * 1.25 + beat * 1.35 + spectrumMean * 0.35 + spectrumPeak * 0.12))
            root.audioTargetEnergy = target
            const response = target > root.audioEnergy ? 0.68 : 0.12
            root.audioEnergy += (target - root.audioEnergy) * response
            root.beatPulse = Math.max(root.audioEnergy, beat)
            root.lyricBounce = root.bounceEnabled
                ? Math.min(0.24, Math.pow(root.audioEnergy, 0.72) * root.bounceIntensity * 0.30)
                : 0
            const active = LyricsService.activeIndex
            const line = active >= 0 ? LyricsService.lyricsLines[active] : null
            const next = active >= 0 ? LyricsService.lyricsLines[active + 1] : null
            const start = Number(line?.time ?? 0)
            const end = Number(next?.time ?? (start + 4))
            root.lineProgress = end > start ? Math.max(0, Math.min(1, (LyricsService.currentPosition() - start) / (end - start))) : 0
            const idx = LyricsService.activeIndex
            const lines = LyricsService.lyricsLines
            const now = LyricsService.currentPosition()
            const lastLine = lines.length ? lines[lines.length - 1] : null
            const lyricFinish = lastLine ? (Number(lastLine.end) > Number(lastLine.time) ? Number(lastLine.end) : Number(lastLine.time) + 4) + 0.20 : 0
            const trackLength = Number(LyricsService.activePlayer?.length ?? 0)
            const trackFinish = trackLength > 1 ? Math.max(Number(lastLine?.time) || 0, trackLength - 0.35) : lyricFinish
            root.songDone = !!(idx === lines.length - 1 && lastLine && now >= trackFinish)
            if (idx >= 0 && idx < lines.length) {
                const line = lines[idx]
                const start = Number(line.time) || 0
                const end = idx + 1 < lines.length ? Number(lines[idx + 1].time) : start + 4
                const words = line.words || []
                if (words.length > 1) {
                    let activeWord = -1
                    let within = 0
                    for (let i = 0; i < words.length; i++) {
                        if (now >= Number(words[i].start) && now < Number(words[i].end)) {
                            activeWord = i
                            within = Math.max(0, Math.min(1, (now - Number(words[i].start)) / Math.max(0.03, Number(words[i].end) - Number(words[i].start))))
                            break
                        }
                    }
                    if (activeWord < 0) {
                        const upcoming = words.findIndex(w => now < Number(w.start))
                        if (upcoming > 0) {
                            // Preserve the last real fragment at its end during a short provider timestamp gap.
                            activeWord = upcoming - 1
                            within = 1
                        } else if (upcoming === 0) {
                            activeWord = 0
                            within = 0
                        } else if (now >= Number(words[words.length - 1].end)) {
                            activeWord = words.length - 1
                            within = 1
                        }
                    }
                    root.activeWordIndex = activeWord
                    root.activeWordProgress = within
                    root.instrumentalCandidate = false
                } else {
                    root.activeWordIndex = -1
                    root.activeWordProgress = 0
                    const nextStart = idx >= 0 && idx + 1 < lines.length ? Number(lines[idx + 1].time) : start + 4
                    const lineEnd = Number(line.end) > start ? Number(line.end) : start + Math.min(5.0, Math.max(1.5, end - start))
                    const silenceUntilNext = nextStart - lineEnd
                    root.instrumentalCandidate = idx >= 0 && idx + 1 < lines.length && silenceUntilNext >= 2.8 && now >= lineEnd + 0.45 && now < nextStart - 0.25
                }
            } else { root.activeWordIndex = -1; root.activeWordProgress = 0; root.instrumentalCandidate = true }
        }
    }

    // Avoid intrusive instrumental effects: wait 1 s before entering, leave 0.5 s early.
    onInstrumentalCandidateChanged: {
        if (instrumentalCandidate) {
            instrumentalOffDelay.stop()
            if (!instrumentalNow) instrumentalOnDelay.restart()
        } else {
            instrumentalOnDelay.stop()
            if (instrumentalNow) instrumentalOffDelay.restart()
        }
    }
    Timer { id: instrumentalOnDelay; interval: 1000; onTriggered: { if (root.instrumentalCandidate) root.instrumentalNow = true } }
    Timer { id: instrumentalOffDelay; interval: 500; onTriggered: { if (!root.instrumentalCandidate) root.instrumentalNow = false } }

    function resetAlbumPalette() {
        // Reset immediately on track/art change so the previous song's palette never sticks.
        root.albumBaseColor = "#a9baff"
        root.albumSecondaryColor = "#8bded7"
        paletteSampler.sourceUrl = root.albumArtUrl
        if (root.albumArtUrl) paletteSampler.loadImage(root.albumArtUrl)
    }
    onAlbumArtUrlChanged: {
        resetAlbumPalette()
        paletteSampler.sourceUrl = root.albumArtUrl
        if (root.albumArtUrl) paletteSampler.loadImage(root.albumArtUrl)
    }
    Connections {
        target: LyricsService.activePlayer
        function onTrackTitleChanged() {
            root.songDone = false
            root.transitionMark = true
            root.resetAlbumPalette()
            transitionTimer.restart()
        }
    }
    Timer { id: transitionTimer; interval: 850; onTriggered: root.transitionMark = false }

    Item {
        anchors.fill: parent

        // Source artwork remains hidden; its sampled colors drive the lyric fill, darker stroke and cloud.
        // Canvas loads the MPRIS art URL directly, then samples its pixels on the GUI side.
        // Keep the sampler inside the widget: off-screen/zero-opacity canvases can skip paint on some backends.
        Canvas {
            id: paletteSampler
            x: 0
            y: 0
            width: 32
            height: 32
            opacity: 0.001
            visible: true
            property string sourceUrl: root.albumArtUrl

            onSourceUrlChanged: {
                if (sourceUrl && sourceUrl.length > 0) {
                    loadImage(sourceUrl)
                }
            }
            onImageLoaded: requestPaint()

            onPaint: {
                if (!sourceUrl || sourceUrl.length === 0) return
                if (!isImageLoaded(sourceUrl)) {
                    loadImage(sourceUrl)
                    return
                }

                const ctx = getContext("2d")
                try {
                    ctx.clearRect(0, 0, width, height)
                    ctx.drawImage(sourceUrl, 0, 0, width, height)
                    const data = ctx.getImageData(0, 0, width, height).data
                    const bins = Array.from({length: 18}, () => ({score: 0, r: 0, g: 0, b: 0}))
                    let chromaPixels = 0

                    for (let i = 0; i < data.length; i += 4) {
                        if (data[i + 3] < 128) continue
                        const r = data[i] / 255
                        const g = data[i + 1] / 255
                        const b = data[i + 2] / 255
                        const maxc = Math.max(r, g, b)
                        const minc = Math.min(r, g, b)
                        const delta = maxc - minc
                        const sat = maxc <= 0 ? 0 : delta / maxc
                        const lum = r * 0.2126 + g * 0.7152 + b * 0.0722

                        // Ignore near-white/near-black noise, but retain muted album colors.
                        if (sat < 0.075 || lum < 0.035 || lum > 0.985) continue
                        let hue = 0
                        if (delta > 0) {
                            if (maxc === r) hue = ((g - b) / delta) % 6
                            else if (maxc === g) hue = (b - r) / delta + 2
                            else hue = (r - g) / delta + 4
                            hue = (hue / 6 + 1) % 1
                        }

                        const bucket = bins[Math.min(17, Math.floor(hue * 18))]
                        const weight = (0.25 + sat * 1.15) * (0.65 + 0.35 * (1 - Math.abs(lum - 0.55)))
                        bucket.score += weight
                        bucket.r += r * weight
                        bucket.g += g * weight
                        bucket.b += b * weight
                        chromaPixels++
                    }

                    bins.sort((a, b) => b.score - a.score)
                    const toColor = bucket => bucket && bucket.score > 0
                        ? Qt.rgba(bucket.r / bucket.score, bucket.g / bucket.score, bucket.b / bucket.score, 1)
                        : null

                    const primary = toColor(bins[0])
                    const secondary = toColor(bins.find((bucket, index) => index > 0 && bucket.score > bins[0].score * 0.10))
                    if (primary && chromaPixels > 0) {
                        root.albumBaseColor = primary
                        root.albumSecondaryColor = secondary || Qt.lighter(primary, 1.42)
                    }
                } catch (error) {
                    // Keep the cool lilac/teal fallback when a backend blocks Canvas pixel readback.
                }
            }
        }

        // Layered radial-volume cloud ported from the HTML/CSS prototype.
        // The old compiled puff shader is deliberately bypassed; QML owns the live blurred volumes.
        LyricaCloud {
            anchors.fill: parent
            z: 0
            time: root.shimmer
            energy: root.audioEnergy
            colorA: root.albumBaseColor
            colorB: root.albumSecondaryColor
            colorC: root.albumCloudColorC
            blurEnabled: root.blurEnabled
            strength: root.backgroundEnabled && LyricsService.playing ? root.cloudOpacity : 0
        }

        Item {
            anchors.fill: parent
            readonly property int idx: LyricsService.activeIndex
            readonly property var lines: LyricsService.lyricsLines
            readonly property real nowPos: LyricsService.currentPosition()
            readonly property bool instrumental: root.backgroundEnabled && LyricsService.playing && LyricsService.synced && root.instrumentalNow && !root.songDone
            opacity: instrumental ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.InOutSine } }
            Repeater {
                model: 5
                delegate: Text {
                    required property int index
                    readonly property real phase: root.shimmer * 0.62 + index * 1.23
                    text: ["♫", "♪", "♬", "·", "✧"][index]
                    x: root.width * (0.12 + index * 0.18) + Math.sin(phase) * 22
                    y: root.height * (0.25 + (index % 3) * 0.22) + Math.sin(phase * 0.72 + index) * 15
                    color: root.albumBaseColor
                    font.pixelSize: index === 0 ? 36 : 20 + (index % 3) * 5
                    opacity: index === 0 ? 0.38 + 0.16 * (0.5 + 0.5 * Math.sin(phase)) : 0.24 + 0.18 * (0.5 + 0.5 * Math.sin(phase))
                }
            }
            Text {
                anchors.centerIn: parent
                text: "𝄞"
                color: root.albumGlowColor
                font.pixelSize: 76 + root.beatPulse * 5
                opacity: 0.26
                scale: 1 + Math.sin(root.shimmer * 0.7) * 0.035
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.5 + Math.sin(root.shimmer * 0.8) * 14
                width: parent.width * 0.74
                height: 2
                radius: 2
                color: root.accentColor
                opacity: 0.10
                scale: 1 + Math.sin(root.shimmer) * 0.035
            }
        }

        Repeater {
            model: root.particlesEnabled ? 24 : 0
            visible: root.backgroundEnabled
            delegate: Text {
                required property int index
                readonly property real phase: root.shimmer + index * 1.41
                text: index % 5 === 0 ? "✧" : (index % 3 === 0 ? "✦" : (index % 3 === 1 ? "·" : "˚"))
                x: root.width / 2 + Math.sin(index * 2.2) * root.width * 0.36 + Math.cos(phase * 0.8) * (8 + index % 5 * 2)
                y: root.height / 2 + Math.cos(index * 1.7) * root.height * 0.37 + Math.sin(phase) * (7 + index % 4 * 2)
                color: index % 4 === 0 ? root.lyricColor : root.albumBaseColor
                font.pixelSize: index % 5 === 0 ? 15 : (index % 3 === 0 ? 11 : 15)
                opacity: 0.035 + (0.085 * (0.5 + 0.5 * Math.sin(phase + index * 0.21)))
            }
        }

        Item {
            id: lyricStatus
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.82, 440)
            height: statusLabel.implicitHeight + 34
            visible: LyricsService.lyricsLines.length === 0
            z: 40

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#171522"
                opacity: 0.88
                border.width: 1
                border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.42)
            }
            Rectangle {
                width: 7
                height: 7
                radius: 4
                anchors.left: parent.left
                anchors.leftMargin: 17
                anchors.verticalCenter: parent.verticalCenter
                color: root.accentColor
                opacity: 0.95
            }
            Text {
                id: statusLabel
                anchors.fill: parent
                anchors.leftMargin: 34
                anchors.rightMargin: 18
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                text: LyricsService.activePlayer
                    ? (LyricsService.status === "error" ? "No se encontraron letras para esta canción" : "Buscando letras…")
                    : "Lyrica está lista · reproduce música para comenzar"
                color: "#F7F4FF"
                font.family: root.lyricFont
                font.pixelSize: 18
                font.weight: Font.DemiBold
                style: Text.Outline
                styleColor: "#171522"
                opacity: 1
            }
        }

        Column {
            id: stack
            anchors.fill: parent
            anchors.topMargin: 14
            anchors.bottomMargin: 10
            spacing: 0
            opacity: root.songDone ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
            scale: root.bounceEnabled ? 1 + root.lyricBounce * 0.035 : 1
            transformOrigin: Item.Center
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: root.blurEnabled && root.instrumentalNow
                blur: root.blurEnabled && root.instrumentalNow ? 0.72 : 0
                blurMax: 40
            }

            Repeater {
                model: 7
                delegate: Item {
                    id: row
                    required property int index
                    width: stack.width
                    height: root.rowHeight
                    clip: false
                    readonly property int dist: Math.abs(index - root.centerSlot)
                    readonly property bool current: dist === 0
                    readonly property real fade: root.instrumentalNow ? (current ? 0.12 : dist === 1 ? 0.08 : 0.045) : current ? 1 : dist === 1 ? 0.52 : dist === 2 ? 0.25 : 0.105
                    readonly property real wheelTilt: current ? 0 : (index < root.centerSlot ? -1 : 1) * Math.min(8, dist * 2.15)
                    readonly property string lyricText: LyricsService.slots[index] || ""
                    readonly property string romanizedText: LyricsService.romajiSlots[index] || ""
                    // Han without kana is treated as Chinese for display; romanize() uses pinyin for it.
                    readonly property bool hanOnlyText: /[\u3400-\u9fff]/.test(lyricText) && !/[\u3040-\u30ff\uac00-\ud7af]/.test(lyricText)
                    readonly property string displayText: hanOnlyText ? lyricText : (romanizedText.length > 0 ? romanizedText : lyricText)
                    readonly property bool hasRomanization: romanizedText.length > 0 || (lyricText.length > 0 && !row.hanOnlyText)
                    property real lyricFade: 1
                    property real lyricOffset: 0
                    property real enterTilt: 0
                    Behavior on lyricOffset { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }

                    onLyricTextChanged: {
                        if (!lyricText) return
                        lyricFade = 0
                        lyricOffset = 5
                        enterTilt = 0
                        lyricFadeTimer.restart()
                    }
                    Timer {
                        id: lyricFadeTimer
                        interval: 24
                        onTriggered: {
                            row.lyricFade = 1
                            row.lyricOffset = 0
                            row.enterTilt = 0
                        }
                    }

                    readonly property var timedWords: root.activeLineWordSynced && LyricsService.activeIndex >= 0 ? (LyricsService.lyricsLines[LyricsService.activeIndex].words || []) : []
                    readonly property string timedWordLine: root.normalizeLyricGeometry(timedWords.map(w => String(w.romaji || w.text || w.word || "")).join(""))
                    readonly property string displayedWordLine: root.normalizeLyricGeometry(row.displayText || row.lyricText || "")
                    readonly property bool wordGeometryValid: !!row.hasRomanization && timedWords.length > 1 && timedWordLine.length > 0 && timedWordLine === displayedWordLine && timedLineMetrics.width <= romanizedMain.width
                    TextMetrics {
                        id: wordPrefixMetrics
                        font: romanizedMain.font
                        text: root.wordPrefixText(row.displayText, row.timedWords, root.activeWordIndex)
                    }
                    TextMetrics {
                        id: activeWordMetrics
                        font: romanizedMain.font
                        text: root.wordSliceText(row.displayText, row.timedWords, root.activeWordIndex)
                    }
                    TextMetrics {
                        id: timedLineMetrics
                        font: romanizedMain.font
                        text: row.displayText
                    }
                    readonly property var measuredWordPoint: {
                        const lineLeft = (romanizedMain.width - timedLineMetrics.width) / 2
                        const localX = lineLeft + wordPrefixMetrics.width + activeWordMetrics.width * root.activeWordProgress
                        const localY = Math.max(5, romanizedMain.height * 0.30) - Math.sin(root.activeWordProgress * Math.PI) * 1.8 - root.karaokeHop * 5.5
                        return romanizedMain.mapToItem(row, localX, localY)
                    }
                    // In wave mode, the karaoke marker follows the same per-glyph displacement
                    // as the character currently under the marker instead of crossing the static baseline.
                    readonly property int waveBallGlyphIndex: Math.max(0, Math.min((row.displayText || "").length - 1,
                        root.wordPrefixText(row.displayText, row.timedWords, root.activeWordIndex).length
                        + Math.floor(root.wordSliceText(row.displayText, row.timedWords, root.activeWordIndex).length * root.activeWordProgress)))
                    readonly property real waveBallOffset: root.waveLettersEnabled && row.current
                        ? Math.sin(root.shimmer * root.waveSpeed + row.waveBallGlyphIndex * 0.58) * root.waveIntensity * 8
                            - root.lyricBounce * 12
                        : 0
                    readonly property real measuredWordX: row.measuredWordPoint.x
                    readonly property real measuredWordY: row.measuredWordPoint.y + row.waveBallOffset
                    Rectangle {
                        z: 80
                        visible: root.karaokeBallEnabled && row.current && !row.hanOnlyText && root.activeLineWordSynced && row.wordGeometryValid && root.activeWordIndex >= 0 && !root.instrumentalNow
                        width: 18
                        height: 18
                        radius: width / 2
                        x: row.measuredWordX - width / 2
                        y: row.measuredWordY - height / 2
                        color: root.accentColor
                        opacity: 0.17
                        scale: 1 + root.karaokeHop * 0.10
                    }
                    Rectangle {
                        id: phraseBall
                        z: 81
                        visible: root.karaokeBallEnabled && row.current && !row.hanOnlyText && root.activeLineWordSynced && row.wordGeometryValid && root.activeWordIndex >= 0 && !root.instrumentalNow
                        width: 8
                        height: 8
                        radius: width / 2
                        x: row.measuredWordX - width / 2
                        y: row.measuredWordY - height / 2
                        color: root.accentColor
                        border.width: 1
                        border.color: Qt.lighter(root.accentColor, 1.7)
                        opacity: 1
                        scale: (1 + root.audioEnergy * 0.035) + root.karaokeHop * 0.22
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: root.accentColor
                            shadowBlur: 0.45
                            shadowOpacity: 0.80
                        }
                        // X follows the word timestamp at frame rate; only the hop/scale animates, avoiding positional lag.
                        Behavior on scale { NumberAnimation { duration: 75; easing.type: Easing.OutBack } }
                    }
                    Column {
                        anchors.centerIn: parent
                        width: parent.width - Math.max(36, root.width * 0.07)
                        spacing: 1
                        rotation: row.wheelTilt
                        scale: row.current ? 1 : (row.dist === 1 ? 0.985 : 0.955)
                        transform: Translate { y: row.lyricOffset }
                        Behavior on rotation { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    


                        // Keep the original Japanese script faintly behind its romanization; Chinese is shown natively.
                        Item {
                            width: parent.width
                            height: row.current ? Math.min(68, root.rowHeight * 0.88) : Math.min(30, root.rowHeight * 0.40)
                            Text {
                                id: lyricOriginal
                                width: parent.width
                                height: parent.height
                                y: romanizedMain.y
                                scale: romanizedMain.scale
                                transformOrigin: Item.Bottom
                                text: row.lyricText
                                color: root.albumGlowColor
                                font.family: root.lyricFont
                                font.pixelSize: row.current ? Math.min(36, root.rowHeight * 0.47) : row.dist === 1 ? Math.min(26, root.rowHeight * 0.35) : Math.min(21, root.rowHeight * 0.29)
                                fontSizeMode: Text.Fit
                                minimumPixelSize: 11
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideNone
                                opacity: !row.hanOnlyText && row.hasRomanization && /[\u3040-\u30ff]/.test(row.lyricText) && !/[\uac00-\ud7af]/.test(row.lyricText) ? (root.instrumentalNow ? 0.015 : row.fade * 0.105) : 0
                                style: Text.Outline
                                styleColor: Qt.rgba(Qt.darker(root.albumGlowColor, 1.45).r, Qt.darker(root.albumGlowColor, 1.45).g, Qt.darker(root.albumGlowColor, 1.45).b, 0.72)
                            }
                            Text {
                                id: romanizedMain
                                x: row.current && root.bounceEnabled ? Math.sin(root.shimmer * 0.7) * root.lyricBounce * 0.65 : 0
                                y: (row.hanOnlyText ? 0 : (parent.height - height) / 2) - (row.current ? root.lyricBounce * 2 : 0)
                                width: parent.width
                                height: row.hanOnlyText ? Math.max(20, parent.height - 15) : parent.height
                                scale: root.bounceEnabled ? 1 + root.lyricBounce * 0.12 : 1
                                transformOrigin: Item.Center
                                transform: Rotation {
                                    origin.x: romanizedMain.width / 2
                                    origin.y: romanizedMain.height / 2
                                    axis.x: 1
                                    axis.y: 0
                                    axis.z: 0
                                    angle: row.current && root.bounceEnabled ? -root.lyricBounce * 5 : 0
                                }
                                Behavior on y { NumberAnimation { duration: 95; easing.type: Easing.OutCubic } }
                                Behavior on scale { NumberAnimation { duration: 95; easing.type: Easing.OutCubic } }
                                text: row.displayText
                                color: row.current ? root.lyricColor : root.mutedColor
                                font.family: root.lyricFont
                                font.pixelSize: row.current ? Math.min(36, root.rowHeight * 0.47) : row.dist === 1 ? Math.min(26, root.rowHeight * 0.35) : Math.min(21, root.rowHeight * 0.29)
                                font.weight: Math.round(row.current ? root.lyricFontWeight : Math.max(400, root.lyricFontWeight - 200))
                                font.variableAxes: ({ "wght": row.current ? Number(root.lyricFontWeight) : Math.max(400, Number(root.lyricFontWeight) - 200), "wdth": Number(Appearance.font.variableAxes.main.wdth ?? 100) })
                                font.letterSpacing: row.current ? 0.15 : 0
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideNone
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                fontSizeMode: Text.Fit
                                minimumPixelSize: 11
                                opacity: root.waveLettersEnabled && row.current ? 0 : (root.instrumentalNow ? 0.09 : row.fade * row.lyricFade)
                                style: Text.Outline
                                // Subtle +2% outline weight/intensity, keeping the existing look.
                                styleColor: Qt.rgba(Qt.darker(row.current ? root.lyricColor : root.mutedColor, 2.35).r, Qt.darker(row.current ? root.lyricColor : root.mutedColor, 2.35).g, Qt.darker(row.current ? root.lyricColor : root.mutedColor, 2.35).b, 0.98)
                                Behavior on opacity { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 360 } }
                                Behavior on font.pixelSize { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
                            }
                            // In wave mode this Text is measurement-only; the Row is the sole visible renderer.
                            Item {
                                id: waveGlyphLayer
                                visible: row.current && root.waveLettersEnabled && !root.instrumentalNow && !root.songDone
                                x: 0
                                y: romanizedMain.y
                                width: parent.width
                                height: romanizedMain.height
                                scale: romanizedMain.scale
                                transformOrigin: Item.Center
                                transform: Rotation {
                                    origin.x: waveGlyphLayer.width / 2
                                    origin.y: waveGlyphLayer.height / 2
                                    axis.x: 1
                                    axis.y: 0
                                    axis.z: 0
                                    angle: row.current && root.bounceEnabled ? -root.lyricBounce * 8 : 0
                                }
                                Row {
                                    anchors.centerIn: parent
                                    width: implicitWidth
                                    height: implicitHeight
                                    scale: Math.min(1, parent.width / Math.max(1, implicitWidth))
                                    spacing: 0
                                    Repeater {
                                        model: Array.from(row.displayText || "")
                                        delegate: Text {
                                            required property int index
                                            required property string modelData
                                            text: modelData === " " ? "\u00a0" : modelData
                                            font: romanizedMain.font
                                            color: romanizedMain.color
                                            style: Text.Outline
                                            styleColor: romanizedMain.styleColor
                                            y: Math.sin(root.shimmer * root.waveSpeed + index * 0.58)
                                                * root.waveIntensity * 8
                                                - root.lyricBounce * 12
                                            Behavior on y { NumberAnimation { duration: 80; easing.type: Easing.OutSine } }
                                        }
                                    }
                                }
                            }
                            Item {
                                visible: row.current && !root.instrumentalNow && !root.songDone
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: romanizedMain.bottom
                                anchors.topMargin: 2
                                width: Math.min(parent.width * 0.42, 280)
                                height: 3
                                Rectangle { anchors.fill: parent; radius: 2; color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16) }
                                Rectangle {
                                    width: parent.width * root.lineProgress
                                    height: parent.height
                                    radius: 2
                                    color: root.accentColor
                                    opacity: 0.82
                                    Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.Linear } }
                                }
                            }
                            Text {
                                id: chinesePinyin
                                visible: row.hanOnlyText && row.hasRomanization && row.romanizedText !== row.lyricText && !root.instrumentalNow
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 15
                                text: row.romanizedText
                                color: root.mutedColor
                                font.family: root.lyricFont
                                font.pixelSize: 13
                                fontSizeMode: Text.Fit
                                minimumPixelSize: 9
                                maximumLineCount: 1
                                elide: Text.ElideNone
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                opacity: 0.64 * row.lyricFade
                            }


                            // Multi-layer signal breakup: chromatic ghosts, sliced scan bands,
                            // pixel blocks and short horizontal sync tears. Kept on the distant row.
                            Item {
                                z: 22
                                anchors.fill: romanizedMain
                                visible: root.glitchEnabled && row.dist === 3 && row.lyricText.length > 0 && !root.instrumentalNow && !root.songDone
                                clip: true

                                // Full-frame chromatic ghosts only flare during a glitch burst.
                                Text {
                                    z: 1
                                    width: parent.width
                                    height: parent.height
                                    text: row.displayText
                                    font: romanizedMain.font
                                    horizontalAlignment: romanizedMain.horizontalAlignment
                                    verticalAlignment: romanizedMain.verticalAlignment
                                    color: "#ff4fb8"
                                    x: Math.sin(root.shimmer * 8.1 + row.index) * 5
                                    opacity: Math.pow(Math.max(0, Math.sin(root.shimmer * 3.7 + row.index * 1.9)), 10) * 0.82
                                }
                                Text {
                                    z: 2
                                    width: parent.width
                                    height: parent.height
                                    text: row.displayText
                                    font: romanizedMain.font
                                    horizontalAlignment: romanizedMain.horizontalAlignment
                                    verticalAlignment: romanizedMain.verticalAlignment
                                    color: "#5cf6ff"
                                    x: Math.cos(root.shimmer * 7.3 + row.index * 0.6) * 6
                                    opacity: Math.pow(Math.max(0, Math.sin(root.shimmer * 4.1 + row.index * 2.4 + 1.2)), 9) * 0.78
                                }

                                // Thin horizontal slices move independently, like damaged video sync.
                                Repeater {
                                    model: 6
                                    delegate: Item {
                                        required property int index
                                        readonly property real bandHeight: Math.max(3, romanizedMain.height * (0.045 + (index % 3) * 0.018))
                                        x: 0
                                        y: (parent.height - height) * (index / 5)
                                        width: parent.width
                                        height: bandHeight
                                        clip: true
                                        opacity: {
                                            const pulse = Math.sin(root.shimmer * (5.4 + index * 0.31) + row.index * 1.7 + index * 2.1)
                                            return pulse > 0.52 ? Math.min(1, (pulse - 0.52) * 2.8) : 0
                                        }
                                        Text {
                                            text: row.displayText
                                            font: romanizedMain.font
                                            horizontalAlignment: romanizedMain.horizontalAlignment
                                            verticalAlignment: romanizedMain.verticalAlignment
                                            width: romanizedMain.width
                                            height: romanizedMain.height
                                            x: Math.sin(root.shimmer * (9.0 + index) + row.index) * (7 + index * 2)
                                            y: -parent.y + Math.cos(root.shimmer * 6.2 + index * 1.8) * 2
                                            color: index % 3 === 0 ? "#ff4fb8" : index % 3 === 1 ? "#5cf6ff" : "#f7f5ff"
                                            opacity: 0.92
                                        }
                                    }
                                }

                                // Short data blocks and scanline cuts add hard, pixel-like interruptions.
                                Repeater {
                                    model: 7
                                    delegate: Rectangle {
                                        required property int index
                                        readonly property real pulse: Math.sin(root.shimmer * (6.7 + index * 0.37) + row.index * 2.3 + index * 1.6)
                                        x: Math.abs(Math.sin(row.index * 13.1 + index * 7.7 + root.shimmer * 2.6)) * Math.max(1, parent.width - width)
                                        y: Math.abs(Math.cos(row.index * 4.3 + index * 5.1)) * Math.max(1, parent.height - height)
                                        width: Math.max(5, parent.width * (0.035 + Math.abs(Math.sin(index * 8.2)) * 0.12))
                                        height: index % 3 === 0 ? 4 : 2
                                        color: index % 3 === 0 ? "#ff4fb8" : index % 3 === 1 ? "#5cf6ff" : "#f7f5ff"
                                        opacity: pulse > 0.58 ? Math.min(0.95, (pulse - 0.58) * 2.9) : 0
                                    }
                                }

                                // Brief white scan cuts, deliberately sparse so the lyric remains readable.
                                Repeater {
                                    model: 3
                                    delegate: Rectangle {
                                        required property int index
                                        width: parent.width
                                        height: 1
                                        y: parent.height * (0.22 + index * 0.27)
                                        color: "#eafcff"
                                        opacity: Math.max(0, Math.sin(root.shimmer * 11.0 + row.index + index * 2.7) - 0.88) * 0.8
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Material Symbols Rounded check-circle replaces the finished lyric stack.
        Text {
            anchors.centerIn: parent
            text: "check_circle"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 78
            font.weight: Font.Normal
            color: root.accentColor
            visible: root.songDone
            opacity: root.songDone ? 0.92 : 0
            scale: 1 + Math.sin(root.shimmer * 0.8) * 0.018
            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        }

        // Compact Material You controls appear only in edit/unlocked mode.
        Rectangle {
            id: sourcePill
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 5
            anchors.rightMargin: 20
            visible: !Config.options.background.widgetsLocked
            radius: 14
            color: Appearance.colors.colSurfaceContainer ?? Appearance.colors.colLayer1 ?? "#281c38"
            opacity: 0.92
            width: controls.implicitWidth + 20
            height: 34
            border.width: 1
            border.color: root.accentColor
            Row {
                id: controls
                anchors.centerIn: parent
                spacing: 7
                Text {
                    visible: root.transitionMark
                    text: "check_circle"
                    color: root.accentColor
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                }
                Repeater {
                    model: [
                        { key: "blur", on: "blur_on", off: "blur_off", tooltip: "Desenfoque: suaviza el brillo y los bordes." },
                        { key: "bounce", on: "motion_photos_on", off: "motion_photos_off", tooltip: "Rebote: expansión sutil del texto con la música." },
                        { key: "background", on: "cloud", off: "cloud_off", tooltip: "Nube procedural de fondo." },
                        { key: "glitch", on: "graphic_eq", off: "linear_scale", tooltip: "Glitch RGB en las líneas más lejanas." },
                        { key: "particles", on: "flare", off: "flare", tooltip: "Partículas decorativas dentro de la nube." },
                        { key: "karaoke", on: "lyrics", off: "lyrics", tooltip: "Bola de karaoke sincronizada por palabra." }
                    ]
                    delegate: Text {
                        required property var modelData
                        readonly property bool enabledFeature: root.featureEnabled(modelData.key)
                        text: enabledFeature ? modelData.on : modelData.off
                        color: root.accentColor
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 17
                        opacity: enabledFeature ? 1.0 : 0.42
                        scale: toggleMouse.containsMouse ? 1.10 : 1.0
                        anchors.verticalCenter: parent.verticalCenter
                        ToolTip.text: modelData.tooltip
                        ToolTip.visible: toggleMouse.containsMouse
                        ToolTip.delay: 420
                        ToolTip.timeout: 2600
                        Behavior on opacity { NumberAnimation { duration: 130 } }
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                        MouseArea {
                            id: toggleMouse
                            anchors.fill: parent
                            anchors.margins: -3
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleFeature(modelData.key)
                        }
                    }
                }
                Text {
                    id: settingsToggle
                    text: root.settingsOpen ? "close" : "tune"
                    color: root.accentColor
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                    anchors.verticalCenter: parent.verticalCenter
                    ToolTip.text: "Abrir Lyrica Studio"
                    ToolTip.visible: settingsMouse.containsMouse
                    ToolTip.delay: 350
                    MouseArea {
                        id: settingsMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.settingsOpen = !root.settingsOpen
                    }
                }
                Rectangle { width: 1; height: 18; color: root.accentColor; opacity: 0.36; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    id: sourceToggle
                    text: (root.configEntry.showSource ?? true) ? "closed_caption" : "info"
                    color: root.accentColor
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 17
                    anchors.verticalCenter: parent.verticalCenter
                    scale: sourceMouse.containsMouse ? 1.08 : 1.0
                    ToolTip.text: (root.configEntry.showSource ?? true) ? "Ocultar el proveedor actual" : "Mostrar el proveedor actual"
                    ToolTip.visible: sourceMouse.containsMouse
                    ToolTip.delay: 420
                    ToolTip.timeout: 2600
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    MouseArea {
                        id: sourceMouse
                        anchors.fill: parent
                        anchors.margins: -3
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.configEntry.showSource = !(root.configEntry.showSource ?? true)
                    }
                }
                Text {
                    id: sourceText
                    visible: root.configEntry.showSource ?? true
                    text: LyricsService.sourceLabel || "LYRICS"
                    color: root.accentColor
                    font.pixelSize: 10
                    font.letterSpacing: 0.45
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "delete_sweep"
                    color: root.accentColor
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 17
                    anchors.verticalCenter: parent.verticalCenter
                    scale: cacheMouse.containsMouse ? 1.08 : 1.0
                    ToolTip.text: "Borrar caché de letras para volver a buscarlas"
                    ToolTip.visible: cacheMouse.containsMouse
                    ToolTip.delay: 420
                    ToolTip.timeout: 2600
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    MouseArea {
                        id: cacheMouse
                        anchors.fill: parent
                        anchors.margins: -3
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: clearLyricsCache.running = true
                    }
                }
            }
        }
    }

    LyricaSettings {
        id: lyricaSettings
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 46
        anchors.rightMargin: 20
        width: Math.min(480, Math.max(400, root.width * 0.40))
        height: Math.min(root.height - 58, 540)
        z: 100
        configEntry: root.configEntry
        open: root.settingsOpen && !Config.options.background.widgetsLocked
        accent: "#a9baff"
        enableBlur: root.blurEnabled
        enableBounce: root.bounceEnabled
        enableBackground: root.backgroundEnabled
        enableParticles: root.particlesEnabled
        enableKaraokeBall: root.karaokeBallEnabled
        enableWaveLetters: root.waveLettersEnabled
        bounceIntensity: root.bounceIntensity
        lyricFontWeight: root.lyricFontWeight
        waveIntensity: root.waveIntensity
        waveSpeed: root.waveSpeed
        cloudOpacity: root.cloudOpacity
        accentMode: root.accentMode
        onSettingChanged: (key, value) => root.applyStudioSetting(key, value)
    }

    ResizeHandler {
        anchorItem: root
        hoverActive: root.containsMouse
        locked: Config.options.background.widgetsLocked
        currentWidth: root.widgetWidth
        resizeMode: "diagonal"
        onResizedXY: (dx, dy, startWidth) => {
            if (root.resizeStartWidth < 0) {
                root.resizeStartWidth = startWidth
                root.resizeStartHeight = root.widgetHeight
            }
            root.widgetWidth = root.clampWidth(root.resizeStartWidth + dx)
            root.widgetHeight = root.clampHeight(root.resizeStartHeight + dy)
        }
        onResizeFinished: {
            root.configEntry.width = root.widgetWidth
            root.configEntry.height = root.widgetHeight
            root.resizeStartWidth = -1
            root.resizeStartHeight = -1
        }
    }
}
