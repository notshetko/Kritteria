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
import qs.services

// SekaiPop-inspired lyric wheel. Uses end4-pC's normal desktop-widget drag and resize behavior.
AbstractBackgroundWidget {
    id: root
    configEntryName: "lyrics"
    needsColText: false
    hoverEnabled: true

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
    property real audioEnergy: 0.08
    property real lyricBounce: 0
    property bool songDone: false
    property bool settingsOpen: false
    property int activeWordIndex: -1
    property real activeWordProgress: 0
    property real lyricProgress: 0
    property real karaokeHop: 0
    property bool transitionMark: false
    property bool instrumentalNow: false
    property bool instrumentalCandidate: false
    readonly property bool activeLineWordSynced: LyricsService.activeIndex >= 0 && (LyricsService.lyricsLines[LyricsService.activeIndex]?.words || []).length > 1
    readonly property int centerSlot: LyricsService.before
    readonly property bool blurEnabled: configEntry.enableBlur ?? true
    readonly property bool bounceEnabled: configEntry.enableBounce ?? true
    readonly property bool backgroundEnabled: configEntry.enableBackground ?? true
    readonly property bool glitchEnabled: configEntry.enableGlitch ?? true
    readonly property bool particlesEnabled: configEntry.enableParticles ?? true
    readonly property bool karaokeBallEnabled: configEntry.enableKaraokeBall ?? true
    readonly property bool spectrumRingEnabled: configEntry.enableSpectrumRing ?? true
    readonly property bool orbitNotesEnabled: configEntry.enableOrbitNotes ?? true
    readonly property bool lyricProgressEnabled: configEntry.enableLyricProgress ?? true
    readonly property real motionIntensity: Math.max(0, Math.min(2, Number(configEntry.motionIntensity ?? 1.0)))
    readonly property real wheelIntensity: Math.max(0, Math.min(1.8, Number(configEntry.wheelIntensity ?? 1.0)))
    readonly property real glowIntensity: Math.max(0.2, Math.min(1.5, Number(configEntry.glowIntensity ?? 1.0)))
    readonly property real karaokeBallSize: Math.max(0.65, Math.min(1.7, Number(configEntry.karaokeBallSize ?? 1.0)))
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

    readonly property string lyricFont: "M PLUS Rounded 1c"
    readonly property string albumArtUrl: String(LyricsService.activePlayer?.trackArtUrl ?? "")
    // Canvas samples the current MPRIS artwork into a tiny palette. Text and outlines follow the album,
    // with the outline always darker than the foreground for contrast. Material colors are fallback only.
    property color albumBaseColor: "#b7a1ff"
    property color albumSecondaryColor: "#9d8ac7"
    readonly property color albumGlowColor: root.albumBaseColor
    readonly property color lyricColor: {
        if (String(root.configEntry.accentMode ?? "album") === "custom") return root.configEntry.customAccentColor ?? "#b7a1ff"
        if (String(root.configEntry.accentMode ?? "album") === "theme") return Appearance.colors.colPrimary ?? "#b7a1ff"
        const c = root.albumBaseColor
        const luminance = c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
        return luminance < 0.40 ? Qt.lighter(c, 2.55) : luminance > 0.82 ? Qt.darker(c, 1.18) : Qt.lighter(c, 1.25)
    }
    readonly property color accentColor: {
        const mode = String(root.configEntry.accentMode ?? "album")
        if (mode === "theme") return Appearance.colors.colPrimary ?? "#b7a1ff"
        if (mode === "custom") return root.configEntry.customAccentColor ?? "#b7a1ff"
        return root.albumSecondaryColor
    }
    readonly property color mutedColor: Qt.lighter(root.albumBaseColor, 1.42)
    readonly property color shadowColor: Qt.darker(root.lyricColor, 2.8)
    readonly property color albumCloudColorA: Qt.lighter(root.albumBaseColor, 1.42)
    readonly property color albumCloudColorB: root.albumBaseColor
    readonly property color albumCloudColorC: root.albumSecondaryColor


    function featureEnabled(key) {
        if (key === "spectrum") return root.spectrumRingEnabled
        if (key === "orbit") return root.orbitNotesEnabled
        if (key === "progress") return root.lyricProgressEnabled
        if (key === "blur") return root.blurEnabled
        if (key === "bounce") return root.bounceEnabled
        if (key === "background") return root.backgroundEnabled
        if (key === "glitch") return root.glitchEnabled
        if (key === "particles") return root.particlesEnabled
        if (key === "karaoke") return root.karaokeBallEnabled
        return false
    }

    function toggleFeature(key) {
        if (key === "spectrum") root.configEntry.enableSpectrumRing = !root.spectrumRingEnabled
        else if (key === "orbit") root.configEntry.enableOrbitNotes = !root.orbitNotesEnabled
        else if (key === "progress") root.configEntry.enableLyricProgress = !root.lyricProgressEnabled
        else if (key === "blur") root.configEntry.enableBlur = !root.blurEnabled
        else if (key === "bounce") root.configEntry.enableBounce = !root.bounceEnabled
        else if (key === "background") root.configEntry.enableBackground = !root.backgroundEnabled
        else if (key === "glitch") root.configEntry.enableGlitch = !root.glitchEnabled
        else if (key === "particles") root.configEntry.enableParticles = !root.particlesEnabled
        else if (key === "karaoke") root.configEntry.enableKaraokeBall = !root.karaokeBallEnabled
        root.configEntryChanged()
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

    // Optional live spectrum from CAVA; gracefully falls back to a soft glow.
    Process {
        id: spectrumProcess
        command: ["bash", "-lc", "command -v cava >/dev/null 2>&1 && exec cava -p \"$HOME/.config/quickshell/end4-pC/lyrics-cava.conf\""]
        running: root.visible && LyricsService.playing
        stdout: SplitParser {
            onRead: data => {
                const values = String(data).trim().split(/[;,\s]+/).map(v => Number(v)).filter(v => Number.isFinite(v))
                if (values.length) {
                    const normalized = values.map(v => Math.max(0, Math.min(1, v / 100)))
                    root.audioEnergy = Math.max(0.04, Math.min(1, normalized.reduce((a, b) => a + b, 0) / normalized.length * 1.7))
                }
            }
        }
    }

    // Keep the widget available as soon as lyrics arrive, not only after the first timestamp.
    visible: !!LyricsService.activePlayer && LyricsService.status === "ok" && LyricsService.synced && LyricsService.lyricsLines.length > 0
    opacity: (LyricsService.playing || root.songDone) ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
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
            root.audioEnergy = Math.max(0.04, root.audioEnergy * 0.9925)
            root.beatPulse = root.audioEnergy
            // Subtle, music-reactive motion: lyrics lead the cloud, but never jump.
            root.lyricBounce = root.bounceEnabled ? Math.max(0, Math.min(1, (root.audioEnergy - 0.22) * 0.85 * root.motionIntensity)) : 0
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
                const progressEnd = Number(line.end) > start ? Number(line.end) : end
                root.lyricProgress = Math.max(0, Math.min(1, (now - start) / Math.max(0.1, progressEnd - start)))
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
            } else { root.activeWordIndex = -1; root.activeWordProgress = 0; root.lyricProgress = 0; root.instrumentalCandidate = true }
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
        root.albumBaseColor = "#b7a1ff"
        root.albumSecondaryColor = "#9d8ac7"
        paletteSampler.requestPaint()
    }
    onAlbumArtUrlChanged: {
        resetAlbumPalette()
        albumArtSource.source = ""
        albumArtSource.source = root.albumArtUrl
        paletteRetry.restart()
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
        Image {
            id: albumArtSource
            x: -32
            y: -32
            width: 16
            height: 16
            opacity: 0
            visible: true
            asynchronous: true
            cache: true
            source: root.albumArtUrl
            sourceSize.width: 48
            sourceSize.height: 48
            fillMode: Image.PreserveAspectCrop
            onSourceChanged: if (source && source.toString().length > 0) paletteRetry.restart()
            onStatusChanged: if (status === Image.Ready) paletteSampler.requestPaint()
        }
        Timer {
            id: paletteRetry
            interval: 120
            repeat: false
            onTriggered: if (albumArtSource.status === Image.Ready) paletteSampler.requestPaint()
        }
        Canvas {
            id: paletteSampler
            x: -32
            y: -32
            width: 12
            height: 12
            opacity: 0
            visible: true
            onPaint: {
                if (albumArtSource.status !== Image.Ready) return
                const ctx = getContext("2d")
                try {
                    ctx.clearRect(0, 0, width, height)
                    ctx.drawImage(albumArtSource, 0, 0, width, height)
                    const data = ctx.getImageData(0, 0, width, height).data
                    const bins = Array.from({length: 12}, () => ({score: 0, r: 0, g: 0, b: 0, count: 0}))
                    for (let i = 0; i < data.length; i += 4) {
                        const r = data[i] / 255, g = data[i + 1] / 255, b = data[i + 2] / 255
                        const maxc = Math.max(r, g, b), minc = Math.min(r, g, b), delta = maxc - minc
                        const sat = maxc <= 0 ? 0 : delta / maxc
                        const lum = r * 0.2126 + g * 0.7152 + b * 0.0722
                        if (data[i + 3] < 128 || sat < 0.16 || lum < 0.055 || lum > 0.96) continue
                        let h = 0
                        if (delta > 0) {
                            if (maxc === r) h = ((g - b) / delta) % 6
                            else if (maxc === g) h = (b - r) / delta + 2
                            else h = (r - g) / delta + 4
                            h = (h / 6 + 1) % 1
                        }
                        // Exclude saturated yellow/gold (roughly 36–68°): it clashes with the lavender studio palette.
                        if (h > 0.10 && h < 0.19) continue
                        const bucket = bins[Math.min(11, Math.floor(h * 12))]
                        const weight = sat * (0.45 + lum * 0.55)
                        bucket.score += weight
                        bucket.r += r * weight; bucket.g += g * weight; bucket.b += b * weight
                        bucket.count++
                    }
                    bins.sort((a, b) => b.score - a.score)
                    const toColor = bucket => {
                        if (!bucket || bucket.score <= 0) return null
                        return Qt.rgba(bucket.r / bucket.score, bucket.g / bucket.score, bucket.b / bucket.score, 1)
                    }
                    const primary = toColor(bins[0])
                    const secondary = toColor(bins.find((b, i) => i > 0 && b.score > 0 && (!bins[0] || b.score > bins[0].score * 0.18)))
                    if (primary) root.albumBaseColor = primary
                    if (secondary) root.albumSecondaryColor = secondary
                } catch (e) {
                    // Some platform backends do not expose pixel readback; palette fallback remains usable.
                }
            }
        }

        // GPU procedural cloud: fluid noise and motes are animated continuously, not reset by keyframes.
        // The old vector cloud below remains as a fallback when qsb/ShaderEffect is unavailable.
        ShaderEffect {
            id: cloudShader
            anchors.fill: parent
            visible: root.backgroundEnabled && status === ShaderEffect.Compiled && (LyricsService.playing || opacity > 0.01)
            // Transparent outside the central stylized cloud; never paint the widget bounds.
            opacity: root.backgroundEnabled && LyricsService.playing ? Number(root.configEntry.cloudOpacity ?? 0.72) : 0
            fragmentShader: Qt.resolvedUrl("lyrics-cloud.frag.qsb")
            property real uTime: root.shimmer
            property real uEnergy: root.audioEnergy
            property real uParticles: root.particlesEnabled ? 1.0 : 0.0
            property color uColorA: root.albumCloudColorA
            property color uColorB: root.albumCloudColorB
            property color uColorC: root.albumCloudColorC
            Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutSine } }
        }

        // Organic QML fallback for systems where the optional shader could not be compiled.
        Item {
            id: lyricGlowCloud
            visible: root.backgroundEnabled && cloudShader.status !== ShaderEffect.Compiled
            anchors.centerIn: parent
            // Compact, soft, stylized puff behind the focused lines; not a full-widget wash.
            width: parent.width * 0.54
            height: parent.height * 0.38
            opacity: root.backgroundEnabled && LyricsService.playing ? 0.48 : 0
            scale: 1 + root.audioEnergy * 0.022
            Behavior on opacity { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Shape {
                id: cloudBlobA
                x: width * -0.06 + Math.sin(root.shimmer * 0.19) * 7
                y: height * 0.03 + Math.cos(root.shimmer * 0.17) * 5
                width: lyricGlowCloud.width * 0.92
                height: lyricGlowCloud.height * 0.91
                rotation: -7 + Math.sin(root.shimmer * 0.48) * 6
                opacity: 0.28 + root.audioEnergy * 0.05
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: root.blurEnabled; blur: root.blurEnabled ? 0.88 : 0; blurMax: 72; autoPaddingEnabled: true }
                ShapePath {
                    fillColor: root.albumCloudColorA
                    strokeColor: "transparent"
                    startX: cloudBlobA.width * 0.06; startY: cloudBlobA.height * 0.58
                    PathCubic { x: cloudBlobA.width * 0.12; y: cloudBlobA.height * 0.32; control1X: cloudBlobA.width * 0.00; control1Y: cloudBlobA.height * 0.49; control2X: cloudBlobA.width * 0.03; control2Y: cloudBlobA.height * 0.34 }
                    PathCubic { x: cloudBlobA.width * 0.26; y: cloudBlobA.height * 0.20; control1X: cloudBlobA.width * 0.14; control1Y: cloudBlobA.height * 0.19; control2X: cloudBlobA.width * 0.20; control2Y: cloudBlobA.height * 0.15 }
                    PathCubic { x: cloudBlobA.width * 0.35; y: cloudBlobA.height * 0.07; control1X: cloudBlobA.width * 0.27; control1Y: cloudBlobA.height * 0.10; control2X: cloudBlobA.width * 0.31; control2Y: cloudBlobA.height * 0.02 }
                    PathCubic { x: cloudBlobA.width * 0.47; y: cloudBlobA.height * 0.16; control1X: cloudBlobA.width * 0.39; control1Y: cloudBlobA.height * 0.02; control2X: cloudBlobA.width * 0.44; control2Y: cloudBlobA.height * 0.08 }
                    PathCubic { x: cloudBlobA.width * 0.62; y: cloudBlobA.height * 0.09; control1X: cloudBlobA.width * 0.52; control1Y: cloudBlobA.height * 0.12; control2X: cloudBlobA.width * 0.57; control2Y: cloudBlobA.height * 0.04 }
                    PathCubic { x: cloudBlobA.width * 0.75; y: cloudBlobA.height * 0.25; control1X: cloudBlobA.width * 0.68; control1Y: cloudBlobA.height * 0.08; control2X: cloudBlobA.width * 0.73; control2Y: cloudBlobA.height * 0.12 }
                    PathCubic { x: cloudBlobA.width * 0.90; y: cloudBlobA.height * 0.29; control1X: cloudBlobA.width * 0.81; control1Y: cloudBlobA.height * 0.21; control2X: cloudBlobA.width * 0.86; control2Y: cloudBlobA.height * 0.23 }
                    PathCubic { x: cloudBlobA.width * 0.97; y: cloudBlobA.height * 0.51; control1X: cloudBlobA.width * 0.96; control1Y: cloudBlobA.height * 0.36; control2X: cloudBlobA.width * 0.99; control2Y: cloudBlobA.height * 0.44 }
                    PathCubic { x: cloudBlobA.width * 0.88; y: cloudBlobA.height * 0.70; control1X: cloudBlobA.width * 0.97; control1Y: cloudBlobA.height * 0.64; control2X: cloudBlobA.width * 0.93; control2Y: cloudBlobA.height * 0.70 }
                    PathCubic { x: cloudBlobA.width * 0.76; y: cloudBlobA.height * 0.82; control1X: cloudBlobA.width * 0.84; control1Y: cloudBlobA.height * 0.71; control2X: cloudBlobA.width * 0.80; control2Y: cloudBlobA.height * 0.79 }
                    PathCubic { x: cloudBlobA.width * 0.60; y: cloudBlobA.height * 0.79; control1X: cloudBlobA.width * 0.71; control1Y: cloudBlobA.height * 0.85; control2X: cloudBlobA.width * 0.66; control2Y: cloudBlobA.height * 0.83 }
                    PathCubic { x: cloudBlobA.width * 0.47; y: cloudBlobA.height * 0.93; control1X: cloudBlobA.width * 0.56; control1Y: cloudBlobA.height * 0.84; control2X: cloudBlobA.width * 0.52; control2Y: cloudBlobA.height * 0.91 }
                    PathCubic { x: cloudBlobA.width * 0.31; y: cloudBlobA.height * 0.83; control1X: cloudBlobA.width * 0.42; control1Y: cloudBlobA.height * 0.95; control2X: cloudBlobA.width * 0.36; control2Y: cloudBlobA.height * 0.89 }
                    PathCubic { x: cloudBlobA.width * 0.17; y: cloudBlobA.height * 0.85; control1X: cloudBlobA.width * 0.26; control1Y: cloudBlobA.height * 0.81; control2X: cloudBlobA.width * 0.21; control2Y: cloudBlobA.height * 0.88 }
                    PathCubic { x: cloudBlobA.width * 0.07; y: cloudBlobA.height * 0.71; control1X: cloudBlobA.width * 0.11; control1Y: cloudBlobA.height * 0.84; control2X: cloudBlobA.width * 0.05; control2Y: cloudBlobA.height * 0.80 }
                    PathCubic { x: cloudBlobA.width * 0.06; y: cloudBlobA.height * 0.58; control1X: cloudBlobA.width * 0.02; control1Y: cloudBlobA.height * 0.65; control2X: cloudBlobA.width * 0.03; control2Y: cloudBlobA.height * 0.60 }
                }
            }
            Shape {
                id: cloudBlobB
                x: lyricGlowCloud.width * (0.12 + 0.06 * (0.5 + 0.5 * Math.sin(root.shimmer * 0.15 + 1.1)))
                y: lyricGlowCloud.height * 0.02 + Math.sin(root.shimmer * 0.13 + 2.0) * 5
                width: lyricGlowCloud.width * 0.82
                height: lyricGlowCloud.height * 0.86
                rotation: 12 + Math.sin(root.shimmer * 0.37 + 1.8) * 8
                opacity: 0.22 + root.audioEnergy * 0.045
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 0.90; blurMax: 72; autoPaddingEnabled: true }
                ShapePath {
                    fillColor: root.albumCloudColorB
                    strokeColor: "transparent"
                    startX: cloudBlobB.width * 0.08; startY: cloudBlobB.height * 0.53
                    PathCubic { x: cloudBlobB.width * 0.15; y: cloudBlobB.height * 0.30; control1X: cloudBlobB.width * 0.02; control1Y: cloudBlobB.height * 0.42; control2X: cloudBlobB.width * 0.06; control2Y: cloudBlobB.height * 0.31 }
                    PathCubic { x: cloudBlobB.width * 0.31; y: cloudBlobB.height * 0.20; control1X: cloudBlobB.width * 0.21; control1Y: cloudBlobB.height * 0.18; control2X: cloudBlobB.width * 0.25; control2Y: cloudBlobB.height * 0.14 }
                    PathCubic { x: cloudBlobB.width * 0.37; y: cloudBlobB.height * 0.07; control1X: cloudBlobB.width * 0.31; control1Y: cloudBlobB.height * 0.10; control2X: cloudBlobB.width * 0.33; control2Y: cloudBlobB.height * 0.01 }
                    PathCubic { x: cloudBlobB.width * 0.51; y: cloudBlobB.height * 0.13; control1X: cloudBlobB.width * 0.42; control1Y: cloudBlobB.height * 0.03; control2X: cloudBlobB.width * 0.47; control2Y: cloudBlobB.height * 0.07 }
                    PathCubic { x: cloudBlobB.width * 0.64; y: cloudBlobB.height * 0.20; control1X: cloudBlobB.width * 0.56; control1Y: cloudBlobB.height * 0.16; control2X: cloudBlobB.width * 0.60; control2Y: cloudBlobB.height * 0.21 }
                    PathCubic { x: cloudBlobB.width * 0.79; y: cloudBlobB.height * 0.12; control1X: cloudBlobB.width * 0.69; control1Y: cloudBlobB.height * 0.12; control2X: cloudBlobB.width * 0.74; control2Y: cloudBlobB.height * 0.07 }
                    PathCubic { x: cloudBlobB.width * 0.93; y: cloudBlobB.height * 0.31; control1X: cloudBlobB.width * 0.85; control1Y: cloudBlobB.height * 0.14; control2X: cloudBlobB.width * 0.92; control2Y: cloudBlobB.height * 0.20 }
                    PathCubic { x: cloudBlobB.width * 0.90; y: cloudBlobB.height * 0.51; control1X: cloudBlobB.width * 0.98; control1Y: cloudBlobB.height * 0.42; control2X: cloudBlobB.width * 0.96; control2Y: cloudBlobB.height * 0.47 }
                    PathCubic { x: cloudBlobB.width * 0.84; y: cloudBlobB.height * 0.68; control1X: cloudBlobB.width * 0.92; control1Y: cloudBlobB.height * 0.59; control2X: cloudBlobB.width * 0.88; control2Y: cloudBlobB.height * 0.66 }
                    PathCubic { x: cloudBlobB.width * 0.68; y: cloudBlobB.height * 0.81; control1X: cloudBlobB.width * 0.78; control1Y: cloudBlobB.height * 0.76; control2X: cloudBlobB.width * 0.73; control2Y: cloudBlobB.height * 0.81 }
                    PathCubic { x: cloudBlobB.width * 0.53; y: cloudBlobB.height * 0.79; control1X: cloudBlobB.width * 0.62; control1Y: cloudBlobB.height * 0.84; control2X: cloudBlobB.width * 0.58; control2Y: cloudBlobB.height * 0.81 }
                    PathCubic { x: cloudBlobB.width * 0.43; y: cloudBlobB.height * 0.90; control1X: cloudBlobB.width * 0.49; control1Y: cloudBlobB.height * 0.77; control2X: cloudBlobB.width * 0.47; control2Y: cloudBlobB.height * 0.90 }
                    PathCubic { x: cloudBlobB.width * 0.28; y: cloudBlobB.height * 0.83; control1X: cloudBlobB.width * 0.37; control1Y: cloudBlobB.height * 0.91; control2X: cloudBlobB.width * 0.31; control2Y: cloudBlobB.height * 0.88 }
                    PathCubic { x: cloudBlobB.width * 0.16; y: cloudBlobB.height * 0.88; control1X: cloudBlobB.width * 0.23; control1Y: cloudBlobB.height * 0.84; control2X: cloudBlobB.width * 0.19; control2Y: cloudBlobB.height * 0.90 }
                    PathCubic { x: cloudBlobB.width * 0.05; y: cloudBlobB.height * 0.70; control1X: cloudBlobB.width * 0.08; control1Y: cloudBlobB.height * 0.84; control2X: cloudBlobB.width * 0.02; control2Y: cloudBlobB.height * 0.79 }
                    PathCubic { x: cloudBlobB.width * 0.08; y: cloudBlobB.height * 0.53; control1X: cloudBlobB.width * 0.01; control1Y: cloudBlobB.height * 0.63; control2X: cloudBlobB.width * 0.03; control2Y: cloudBlobB.height * 0.56 }
                }
            }
            Shape {
                id: cloudBlobC
                x: lyricGlowCloud.width * 0.18
                y: lyricGlowCloud.height * 0.13 + Math.sin(root.shimmer * 0.15 + 0.7) * 4
                width: lyricGlowCloud.width * 0.65
                height: lyricGlowCloud.height * 0.67
                rotation: -18 + Math.sin(root.shimmer * 0.31 + 3.0) * 10
                opacity: 0.18 + root.audioEnergy * 0.04
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: root.blurEnabled; blur: root.blurEnabled ? 0.88 : 0; blurMax: 64; autoPaddingEnabled: true }
                ShapePath {
                    fillColor: root.albumCloudColorC
                    strokeColor: "transparent"
                    startX: cloudBlobC.width * 0.08; startY: cloudBlobC.height * 0.50
                    PathCubic { x: cloudBlobC.width * 0.18; y: cloudBlobC.height * 0.25; control1X: cloudBlobC.width * 0.04; control1Y: cloudBlobC.height * 0.39; control2X: cloudBlobC.width * 0.10; control2Y: cloudBlobC.height * 0.27 }
                    PathCubic { x: cloudBlobC.width * 0.34; y: cloudBlobC.height * 0.12; control1X: cloudBlobC.width * 0.24; control1Y: cloudBlobC.height * 0.13; control2X: cloudBlobC.width * 0.29; control2Y: cloudBlobC.height * 0.07 }
                    PathCubic { x: cloudBlobC.width * 0.47; y: cloudBlobC.height * 0.19; control1X: cloudBlobC.width * 0.38; control1Y: cloudBlobC.height * 0.14; control2X: cloudBlobC.width * 0.42; control2Y: cloudBlobC.height * 0.20 }
                    PathCubic { x: cloudBlobC.width * 0.61; y: cloudBlobC.height * 0.06; control1X: cloudBlobC.width * 0.52; control1Y: cloudBlobC.height * 0.18; control2X: cloudBlobC.width * 0.56; control2Y: cloudBlobC.height * 0.04 }
                    PathCubic { x: cloudBlobC.width * 0.77; y: cloudBlobC.height * 0.22; control1X: cloudBlobC.width * 0.67; control1Y: cloudBlobC.height * 0.05; control2X: cloudBlobC.width * 0.73; control2Y: cloudBlobC.height * 0.10 }
                    PathCubic { x: cloudBlobC.width * 0.90; y: cloudBlobC.height * 0.35; control1X: cloudBlobC.width * 0.84; control1Y: cloudBlobC.height * 0.22; control2X: cloudBlobC.width * 0.91; control2Y: cloudBlobC.height * 0.26 }
                    PathCubic { x: cloudBlobC.width * 0.94; y: cloudBlobC.height * 0.57; control1X: cloudBlobC.width * 0.98; control1Y: cloudBlobC.height * 0.44; control2X: cloudBlobC.width * 0.96; control2Y: cloudBlobC.height * 0.51 }
                    PathCubic { x: cloudBlobC.width * 0.80; y: cloudBlobC.height * 0.76; control1X: cloudBlobC.width * 0.92; control1Y: cloudBlobC.height * 0.68; control2X: cloudBlobC.width * 0.87; control2Y: cloudBlobC.height * 0.76 }
                    PathCubic { x: cloudBlobC.width * 0.68; y: cloudBlobC.height * 0.86; control1X: cloudBlobC.width * 0.75; control1Y: cloudBlobC.height * 0.81; control2X: cloudBlobC.width * 0.72; control2Y: cloudBlobC.height * 0.88 }
                    PathCubic { x: cloudBlobC.width * 0.54; y: cloudBlobC.height * 0.80; control1X: cloudBlobC.width * 0.63; control1Y: cloudBlobC.height * 0.85; control2X: cloudBlobC.width * 0.58; control2Y: cloudBlobC.height * 0.78 }
                    PathCubic { x: cloudBlobC.width * 0.39; y: cloudBlobC.height * 0.92; control1X: cloudBlobC.width * 0.49; control1Y: cloudBlobC.height * 0.83; control2X: cloudBlobC.width * 0.44; control2Y: cloudBlobC.height * 0.92 }
                    PathCubic { x: cloudBlobC.width * 0.26; y: cloudBlobC.height * 0.79; control1X: cloudBlobC.width * 0.34; control1Y: cloudBlobC.height * 0.93; control2X: cloudBlobC.width * 0.29; control2Y: cloudBlobC.height * 0.84 }
                    PathCubic { x: cloudBlobC.width * 0.13; y: cloudBlobC.height * 0.82; control1X: cloudBlobC.width * 0.21; control1Y: cloudBlobC.height * 0.79; control2X: cloudBlobC.width * 0.16; control2Y: cloudBlobC.height * 0.86 }
                    PathCubic { x: cloudBlobC.width * 0.04; y: cloudBlobC.height * 0.64; control1X: cloudBlobC.width * 0.06; control1Y: cloudBlobC.height * 0.78; control2X: cloudBlobC.width * 0.02; control2Y: cloudBlobC.height * 0.71 }
                    PathCubic { x: cloudBlobC.width * 0.08; y: cloudBlobC.height * 0.50; control1X: cloudBlobC.width * 0.01; control1Y: cloudBlobC.height * 0.58; control2X: cloudBlobC.width * 0.04; control2Y: cloudBlobC.height * 0.52 }
                }
                scale: 1.01 + 0.085 * (0.5 + 0.5 * Math.sin(root.shimmer * 0.12 + 3.0))
            }
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
            visible: root.backgroundEnabled && cloudShader.status !== ShaderEffect.Compiled
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

        // New effect 1: a circular, audio-reactive spectrum surrounding (not covering) the lyric stack.
        Item {
            id: spectrumHalo
            anchors.fill: parent
            visible: root.spectrumRingEnabled && LyricsService.playing && !root.instrumentalNow
            opacity: 0.72
            Repeater {
                model: 40
                delegate: Rectangle {
                    required property int index
                    readonly property real angle: index * (360 / 40)
                    readonly property real wave: 0.5 + 0.5 * Math.sin(root.shimmer * 2.1 + index * 0.73)
                    width: 3
                    height: 5 + root.audioEnergy * 24 + wave * (3 + root.audioEnergy * 12)
                    radius: 2
                    x: spectrumHalo.width * 0.5 + Math.cos(angle * Math.PI / 180) * spectrumHalo.width * 0.315 - width * 0.5
                    y: spectrumHalo.height * 0.5 + Math.sin(angle * Math.PI / 180) * spectrumHalo.height * 0.245 - height * 0.5
                    rotation: angle + 90
                    transformOrigin: Item.Center
                    color: index % 5 === 0 ? root.accentColor : root.albumBaseColor
                    opacity: 0.20 + root.audioEnergy * 0.34 + wave * 0.10
                }
            }
        }

        // New effect 2: small music glyphs orbit the focused lyrics with slow parallax.
        Item {
            id: orbitLayer
            anchors.fill: parent
            visible: root.orbitNotesEnabled && LyricsService.playing && !root.instrumentalNow
            Repeater {
                model: 8
                delegate: Text {
                    required property int index
                    readonly property real phase: root.shimmer * (0.22 + (index % 3) * 0.035) + index * Math.PI / 4
                    text: ["♪", "✧", "♫", "·", "♬", "˚", "✦", "♪"][index]
                    x: orbitLayer.width * 0.5 + Math.cos(phase) * orbitLayer.width * (0.34 + (index % 2) * 0.035) - width / 2
                    y: orbitLayer.height * 0.5 + Math.sin(phase * 0.82) * orbitLayer.height * 0.31 - height / 2
                    color: index % 3 === 0 ? root.accentColor : root.albumBaseColor
                    font.pixelSize: 12 + (index % 3) * 5
                    opacity: 0.18 + 0.12 * (0.5 + 0.5 * Math.sin(phase * 1.4))
                    rotation: Math.sin(phase) * 12
                }
            }
        }

        // New effect 3: a fine progress rail that fills as the active lyric line is sung.
        Item {
            id: lyricProgressRail
            anchors.fill: parent
            visible: root.lyricProgressEnabled && LyricsService.playing && !root.instrumentalNow && !root.songDone
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.685
                width: parent.width * 0.34
                height: 2
                radius: 2
                color: root.albumBaseColor
                opacity: 0.18
            }
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: (parent.width - width) / 2
                y: parent.height * 0.685
                width: parent.width * 0.34 * root.lyricProgress
                height: 2
                radius: 2
                color: root.accentColor
                opacity: 0.88
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: root.accentColor
                    shadowBlur: 0.35
                    shadowOpacity: 0.55
                }
                Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
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
            scale: root.bounceEnabled ? 1 + root.beatPulse * 0.006 : 1
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
                    readonly property real wheelTilt: current ? 0 : (index < root.centerSlot ? -1 : 1) * Math.min(8, dist * 2.15 * root.wheelIntensity)
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
                        // Place the marker over the glyph tops, then add a small hop on each word transition.
                        const localY = Math.max(5, romanizedMain.height * 0.30) - Math.sin(root.activeWordProgress * Math.PI) * 1.8 - root.karaokeHop * 5.5
                        return romanizedMain.mapToItem(row, localX, localY)
                    }
                    readonly property real measuredWordX: row.measuredWordPoint.x
                    readonly property real measuredWordY: row.measuredWordPoint.y
                    Rectangle {
                        z: 80
                        visible: root.karaokeBallEnabled && row.current && !row.hanOnlyText && root.activeLineWordSynced && row.wordGeometryValid && root.activeWordIndex >= 0 && !root.instrumentalNow
                        width: 18 * root.karaokeBallSize
                        height: 18 * root.karaokeBallSize
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
                        width: 8 * root.karaokeBallSize
                        height: 8 * root.karaokeBallSize
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
                                x: 0
                                y: row.hanOnlyText ? 0 : (parent.height - height) / 2
                                width: parent.width
                                height: row.hanOnlyText ? Math.max(20, parent.height - 15) : parent.height
                                scale: root.bounceEnabled ? 1 + Math.max(0, root.lyricBounce) * 0.006 + root.audioEnergy * 0.003 : 1
                                transformOrigin: Item.Center
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: root.shadowColor
                                    shadowBlur: 0.306
                                    shadowHorizontalOffset: 0
                                    shadowVerticalOffset: 3 + root.audioEnergy * 0.15
                                    shadowOpacity: Math.max(0.25, Math.min(1, 0.94 * root.glowIntensity))
                                }
                                Behavior on y { NumberAnimation { duration: 95; easing.type: Easing.OutCubic } }
                                Behavior on scale { NumberAnimation { duration: 95; easing.type: Easing.OutCubic } }
                                text: row.displayText
                                color: row.current ? root.lyricColor : root.mutedColor
                                font.family: root.lyricFont
                                font.pixelSize: row.current ? Math.min(36, root.rowHeight * 0.47) : row.dist === 1 ? Math.min(26, root.rowHeight * 0.35) : Math.min(21, root.rowHeight * 0.29)
                                font.weight: row.current ? Font.DemiBold : Font.Medium
                                font.letterSpacing: row.current ? 0.15 : 0
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideNone
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                fontSizeMode: Text.Fit
                                minimumPixelSize: 11
                                opacity: root.instrumentalNow ? 0.09 : row.fade * row.lyricFade
                                style: Text.Outline
                                // Subtle +2% outline weight/intensity, keeping the existing look.
                                styleColor: Qt.rgba(Qt.darker(row.current ? root.lyricColor : root.mutedColor, 2.35).r, Qt.darker(row.current ? root.lyricColor : root.mutedColor, 2.35).g, Qt.darker(row.current ? root.lyricColor : root.mutedColor, 2.35).b, 0.98)
                                Behavior on opacity { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 360 } }
                                Behavior on font.pixelSize { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
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
                            Text {
                                id: karaokeHighlight
                                anchors.fill: romanizedMain
                                visible: row.current && !row.hanOnlyText && root.activeLineWordSynced && row.wordGeometryValid && root.activeWordIndex >= 0 && !root.instrumentalNow
                                textFormat: Text.RichText
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                font: romanizedMain.font
                                color: root.lyricColor
                                text: {
                                    const line = LyricsService.activeIndex >= 0 ? LyricsService.lyricsLines[LyricsService.activeIndex] : null
                                    const words = line && line.words ? line.words : []
                                    if (!words.length || !row.hasRomanization || row.hanOnlyText) return ""
                                    return root.highlightedLyricHtml(row.displayText, words, root.activeWordIndex, root.accentColor)
                                }
                            }

                            // Continuous, faint RGB split on the outermost visible rows (4th above/below focus).
                            // These overlays live inside the rotated lyric Column, so wheel tilt is inherited exactly.
                            Text {
                                z: 20
                                x: romanizedMain.x + Math.sin(root.shimmer * 2.2 + row.index * 0.7) * 2.0
                                y: romanizedMain.y + Math.cos(root.shimmer * 1.7 + row.index) * 0.55
                                width: romanizedMain.width
                                height: romanizedMain.height
                                visible: root.glitchEnabled && row.dist === 3 && row.lyricText.length > 0 && !root.instrumentalNow && !root.songDone
                                text: row.displayText
                                font: romanizedMain.font
                                horizontalAlignment: romanizedMain.horizontalAlignment
                                verticalAlignment: romanizedMain.verticalAlignment
                                wrapMode: romanizedMain.wrapMode
                                maximumLineCount: romanizedMain.maximumLineCount
                                fontSizeMode: romanizedMain.fontSizeMode
                                minimumPixelSize: romanizedMain.minimumPixelSize
                                elide: Text.ElideNone
                                color: "#ff75c8"
                                opacity: 0.20 + 0.09 * (0.5 + 0.5 * Math.sin(root.shimmer * 1.3 + row.index * 0.4))
                                layer.enabled: true
                                layer.effect: MultiEffect { blurEnabled: root.blurEnabled; blur: root.blurEnabled ? 0.12 : 0; blurMax: 8 }
                            }
                            Text {
                                z: 19
                                x: romanizedMain.x + Math.cos(root.shimmer * 2.0 + row.index * 0.8) * 1.65
                                y: romanizedMain.y + Math.sin(root.shimmer * 1.45 + row.index) * 0.5
                                width: romanizedMain.width
                                height: romanizedMain.height
                                visible: root.glitchEnabled && row.dist === 3 && row.lyricText.length > 0 && !root.instrumentalNow && !root.songDone
                                text: row.displayText
                                font: romanizedMain.font
                                horizontalAlignment: romanizedMain.horizontalAlignment
                                verticalAlignment: romanizedMain.verticalAlignment
                                wrapMode: romanizedMain.wrapMode
                                maximumLineCount: romanizedMain.maximumLineCount
                                fontSizeMode: romanizedMain.fontSizeMode
                                minimumPixelSize: romanizedMain.minimumPixelSize
                                elide: Text.ElideNone
                                color: "#77f3ff"
                                opacity: 0.15 + 0.08 * (0.5 + 0.5 * Math.cos(root.shimmer * 1.1 + row.index * 0.5))
                                layer.enabled: true
                                layer.effect: MultiEffect { blurEnabled: root.blurEnabled; blur: root.blurEnabled ? 0.12 : 0; blurMax: 8 }
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
                        { key: "spectrum", on: "equalizer", off: "equalizer", tooltip: "Espectro circular reactivo al audio." },
                        { key: "orbit", on: "motion_photos_on", off: "motion_photos_off", tooltip: "Notas flotantes en órbita." },
                        { key: "progress", on: "linear_scale", off: "linear_scale", tooltip: "Progreso de la línea sincronizado." },
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
        width: Math.max(220, Math.min(390, root.width - 28))
        height: Math.max(180, Math.min(root.height - 58, 440))
        z: 100
        configEntry: root.configEntry
        notifyConfigChanged: () => { root.configEntryChanged() }
        open: root.settingsOpen && !Config.options.background.widgetsLocked
        accent: root.accentColor
        surfaceColor: Appearance.colors.colSurfaceContainer ?? Appearance.colors.colLayer1 ?? "#281c38"
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
