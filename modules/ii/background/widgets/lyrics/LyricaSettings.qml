pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Rectangle {
    id: root
    required property var configEntry
    property var notifyConfigChanged: function() {}
    property bool open: false
    property color accent: "#b7a1ff"
    readonly property color studioAccent: "#d0bcff"
    readonly property color surfaceBase: "#141218"
    readonly property color surfaceContainer: "#211f26"
    readonly property color surfaceHigh: "#2b2930"
    readonly property color onSurface: "#e6e0e9"
    readonly property color onSurfaceVariant: "#cac4d0"
    property color surfaceColor: "#211f26"

    Material.theme: Material.Dark
    Material.accent: studioAccent
    Material.primary: studioAccent
    Material.background: surfaceBase
    Material.foreground: onSurface

    function setValue(key, value) {
        root.configEntry[key] = value
        root.notifyConfigChanged()
    }

    function applyPreset(name) {
        if (name === "dreamy") {
            setValue("accentMode", "album")
            setValue("motionIntensity", 0.72)
            setValue("wheelIntensity", 0.72)
            setValue("glowIntensity", 1.15)
            setValue("karaokeBallSize", 1.0)
            setValue("cloudOpacity", 0.78)
            setValue("enableBlur", true)
            setValue("enableBounce", true)
            setValue("enableBackground", true)
            setValue("enableGlitch", false)
            setValue("enableParticles", true)
            setValue("enableKaraokeBall", true)
            setValue("enableSpectrumRing", false)
            setValue("enableOrbitNotes", true)
            setValue("enableLyricProgress", true)
        } else if (name === "aurora") {
            setValue("accentMode", "album")
            setValue("motionIntensity", 1.35)
            setValue("wheelIntensity", 1.25)
            setValue("glowIntensity", 1.35)
            setValue("karaokeBallSize", 1.25)
            setValue("cloudOpacity", 0.92)
            setValue("enableBlur", true)
            setValue("enableBounce", true)
            setValue("enableBackground", true)
            setValue("enableGlitch", true)
            setValue("enableParticles", true)
            setValue("enableKaraokeBall", true)
            setValue("enableSpectrumRing", true)
            setValue("enableOrbitNotes", true)
            setValue("enableLyricProgress", true)
        } else if (name === "minimal") {
            setValue("accentMode", "theme")
            setValue("motionIntensity", 0.25)
            setValue("wheelIntensity", 0.35)
            setValue("glowIntensity", 0.55)
            setValue("karaokeBallSize", 0.8)
            setValue("cloudOpacity", 0.28)
            setValue("enableBlur", false)
            setValue("enableBounce", false)
            setValue("enableBackground", false)
            setValue("enableGlitch", false)
            setValue("enableParticles", false)
            setValue("enableKaraokeBall", true)
            setValue("enableSpectrumRing", false)
            setValue("enableOrbitNotes", false)
            setValue("enableLyricProgress", true)
        } else if (name === "karaoke") {
            setValue("accentMode", "album")
            setValue("motionIntensity", 1.0)
            setValue("wheelIntensity", 0.85)
            setValue("glowIntensity", 1.25)
            setValue("karaokeBallSize", 1.45)
            setValue("cloudOpacity", 0.58)
            setValue("enableBlur", true)
            setValue("enableBounce", true)
            setValue("enableBackground", true)
            setValue("enableGlitch", false)
            setValue("enableParticles", false)
            setValue("enableKaraokeBall", true)
            setValue("enableSpectrumRing", true)
            setValue("enableOrbitNotes", true)
            setValue("enableLyricProgress", true)
        }
    }

    function restoreDefaults() {
        setValue("accentMode", "album")
        setValue("customAccentColor", "#b7a1ff")
        setValue("motionIntensity", 1.0)
        setValue("wheelIntensity", 1.0)
        setValue("glowIntensity", 1.0)
        setValue("karaokeBallSize", 1.0)
        setValue("cloudOpacity", 0.72)
        setValue("enableBlur", true)
        setValue("enableBounce", true)
        setValue("enableBackground", true)
        setValue("enableGlitch", true)
        setValue("enableParticles", true)
        setValue("enableKaraokeBall", true)
        setValue("showSource", true)
        setValue("prefetchEnabled", true)
        setValue("enableSpectrumRing", true)
        setValue("enableOrbitNotes", true)
        setValue("enableLyricProgress", true)
    }

    visible: open
    opacity: open ? 1 : 0
    radius: 28
    color: surfaceBase
    border.width: 1
    border.color: "#49454f"
    clip: true
    Behavior on opacity { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                width: 42
                height: 42
                radius: 22
                color: "#383342"
                border.color: "#625a70"
                Text {
                    anchors.centerIn: parent
                    text: "✦"
                    color: root.studioAccent
                    font.pixelSize: 22
                }
            }
            ColumnLayout {
                spacing: 1
                Label {
                    text: "Lyrica Studio"
                    color: root.onSurface
                    font.pixelSize: 20
                    font.bold: true
                }
                Label {
                    text: "Personaliza tu experiencia"
                    color: root.onSurfaceVariant
                    font.pixelSize: 11
                }
            }
            Item { Layout.fillWidth: true }
            Label {
                text: "MATERIAL YOU"
                color: root.studioAccent
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.3
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#49454f"
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: Math.max(0, parent.width)
                spacing: 12

                Label {
                    text: "PRESETS"
                    color: root.onSurfaceVariant
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.5
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: width < 350 ? 1 : 2
                    rowSpacing: 6
                    columnSpacing: 6
                    Repeater {
                        model: [
                            { id: "dreamy", title: "Dreamy", sub: "Suave y etéreo", glyph: "cloud" },
                            { id: "aurora", title: "Aurora", sub: "Brillo y energía", glyph: "flare" },
                            { id: "minimal", title: "Minimal", sub: "Limpio y ligero", glyph: "circle" },
                            { id: "karaoke", title: "Karaoke", sub: "Voz protagonista", glyph: "lyrics" }
                        ]
                        delegate: Rectangle {
                            id: presetCard
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 66
                            radius: 18
                            color: presetMouse.pressed
                                ? "#514765"
                                : presetMouse.containsMouse
                                    ? "#35313d"
                                    : root.surfaceContainer
                            border.width: 1
                            border.color: presetMouse.containsMouse
                                ? root.studioAccent
                                : "#49454f"
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 11
                                anchors.rightMargin: 8
                                spacing: 9
                                Rectangle {
                                    Layout.preferredWidth: 34
                                    Layout.preferredHeight: 34
                                    radius: 12
                                    color: "#383342"
                                    Label {
                                        anchors.centerIn: parent
                                        text: ["✧", "✦", "○", "♫"][index]
                                        color: root.studioAccent
                                        font.pixelSize: 17
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Label {
                                        text: presetCard.modelData.title
                                        color: root.onSurface
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Label {
                                        text: presetCard.modelData.sub
                                        color: root.onSurfaceVariant
                                        font.pixelSize: 9
                                    }
                                }
                                Label {
                                    text: "›"
                                    color: root.studioAccent
                                    font.pixelSize: 18
                                }
                            }
                            MouseArea {
                                id: presetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.applyPreset(presetCard.modelData.id)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 22
                    color: root.surfaceContainer
                    border.color: "#49454f"
                    implicitHeight: paletteColumn.implicitHeight + 20
                    ColumnLayout {
                        id: paletteColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Label {
                            text: "APARIENCIA Y COLOR"
                            color: root.studioAccent
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.0
                        }
                        Label { text: "Paleta de acento"; color: root.onSurface; font.bold: true; font.pixelSize: 12 }
                        ComboBox {
                            Material.accent: root.studioAccent
                            Layout.fillWidth: true
                            model: ["Carátula dinámica", "Tema del sistema", "Color personalizado"]
                            currentIndex: ({"album": 0, "theme": 1, "custom": 2})[String(root.configEntry.accentMode ?? "album")] ?? 0
                            onActivated: index => root.setValue("accentMode", ["album", "theme", "custom"][index])
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Color personalizado"; color: root.onSurfaceVariant; Layout.fillWidth: true; font.pixelSize: 11 }
                            TextField {
                                Material.accent: root.studioAccent
                                Layout.preferredWidth: 96
                                text: String(root.configEntry.customAccentColor ?? "#b7a1ff")
                                placeholderText: "#b7a1ff"
                                onEditingFinished: if (/^#[0-9a-fA-F]{6}$/.test(text)) root.setValue("customAccentColor", text)
                            }
                        }
                        Label { text: "Intensidad de la nube"; color: root.onSurface; font.pixelSize: 11 }
                        RowLayout {
                            Layout.fillWidth: true
                            Slider {
                                Material.accent: root.studioAccent
                                Layout.fillWidth: true
                                from: 0
                                to: 1
                                stepSize: 0.02
                                value: Number(root.configEntry.cloudOpacity ?? 0.72)
                                onMoved: root.setValue("cloudOpacity", value)
                            }
                            Label {
                                text: Math.round(Number(root.configEntry.cloudOpacity ?? 0.72) * 100) + "%"
                                color: root.studioAccent
                                font.pixelSize: 10
                                Layout.preferredWidth: 34
                            }
                        }
                        Label { text: "Resplandor de las letras"; color: root.onSurface; font.pixelSize: 11 }
                        RowLayout {
                            Layout.fillWidth: true
                            Slider {
                                Material.accent: root.studioAccent
                                Layout.fillWidth: true
                                from: 0.2
                                to: 1.5
                                stepSize: 0.05
                                value: Number(root.configEntry.glowIntensity ?? 1.0)
                                onMoved: root.setValue("glowIntensity", value)
                            }
                            Label {
                                text: Math.round(Number(root.configEntry.glowIntensity ?? 1.0) * 100) + "%"
                                color: root.studioAccent
                                font.pixelSize: 10
                                Layout.preferredWidth: 38
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 22
                    color: root.surfaceContainer
                    border.color: "#49454f"
                    implicitHeight: motionColumn.implicitHeight + 20
                    ColumnLayout {
                        id: motionColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Label {
                            text: "MOVIMIENTO Y PROFUNDIDAD"
                            color: root.studioAccent
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.2
                        }
                        Label { text: "Reacción a la música"; color: root.onSurface; font.pixelSize: 11 }
                        Slider {
                                Material.accent: root.studioAccent
                            Layout.fillWidth: true
                            from: 0
                            to: 2
                            stepSize: 0.05
                            value: Number(root.configEntry.motionIntensity ?? 1.0)
                            onMoved: root.setValue("motionIntensity", value)
                        }
                        Label { text: "Inclinación de la rueda de letras"; color: root.onSurface; font.pixelSize: 11 }
                        Slider {
                                Material.accent: root.studioAccent
                            Layout.fillWidth: true
                            from: 0
                            to: 1.8
                            stepSize: 0.05
                            value: Number(root.configEntry.wheelIntensity ?? 1.0)
                            onMoved: root.setValue("wheelIntensity", value)
                        }
                        Switch {
                            Material.accent: root.studioAccent
                            Layout.fillWidth: true; text: "Rebote sutil al ritmo"; checked: root.configEntry.enableBounce ?? true; onToggled: root.setValue("enableBounce", checked) }
                        Switch {
                            Material.accent: root.studioAccent
                            Layout.fillWidth: true; text: "Desenfoque en los silencios"; checked: root.configEntry.enableBlur ?? true; onToggled: root.setValue("enableBlur", checked) }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 15
                    color: root.surfaceContainer
                    border.color: "#49454f"
                    implicitHeight: effectsColumn.implicitHeight + 20
                    ColumnLayout {
                        id: effectsColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 7
                        Label {
                            text: "EFECTOS AMBIENTALES"
                            color: root.studioAccent
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.2
                        }
                        Switch {
                            Material.accent: root.studioAccent
                            Layout.fillWidth: true; text: "Nube pastel dinámica"; checked: root.configEntry.enableBackground ?? true; onToggled: root.setValue("enableBackground", checked) }
                        Switch {
                            Material.accent: root.studioAccent
                            Layout.fillWidth: true; text: "Partículas y destellos"; checked: root.configEntry.enableParticles ?? true; onToggled: root.setValue("enableParticles", checked) }
                        Switch {
                            Material.accent: root.studioAccent
                            Layout.fillWidth: true; text: "Glitch cromático discreto"; checked: root.configEntry.enableGlitch ?? true; onToggled: root.setValue("enableGlitch", checked) }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 20
                    color: root.surfaceContainer
                    border.color: "#49454f"
                    implicitHeight: newEffectsColumn.implicitHeight + 20
                    ColumnLayout {
                        id: newEffectsColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Label {
                            text: "NUEVOS EFECTOS VISUALES"
                            color: root.studioAccent
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.2
                        }
                        Switch {
                            Layout.fillWidth: true
                            Material.accent: root.studioAccent
                            text: "Espectro circular reactivo"
                            checked: root.configEntry.enableSpectrumRing ?? true
                            onToggled: root.setValue("enableSpectrumRing", checked)
                        }
                        Switch {
                            Layout.fillWidth: true
                            Material.accent: root.studioAccent
                            text: "Notas flotantes en órbita"
                            checked: root.configEntry.enableOrbitNotes ?? true
                            onToggled: root.setValue("enableOrbitNotes", checked)
                        }
                        Switch {
                            Layout.fillWidth: true
                            Material.accent: root.studioAccent
                            text: "Progreso luminoso de la línea"
                            checked: root.configEntry.enableLyricProgress ?? true
                            onToggled: root.setValue("enableLyricProgress", checked)
                        }
                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: "Tres capas nuevas: barras de espectro alrededor del texto, símbolos que orbitan al ritmo y una línea que avanza con la letra."
                            color: root.onSurfaceVariant
                            font.pixelSize: 10
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 15
                    color: root.surfaceContainer
                    border.color: "#49454f"
                    implicitHeight: karaokeColumn.implicitHeight + 20
                    ColumnLayout {
                        id: karaokeColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Label {
                            text: "KARAOKE Y LETRAS"
                            color: root.studioAccent
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.2
                        }
                        Switch {
                            Material.accent: root.studioAccent
                            Layout.fillWidth: true; text: "Bola sincronizada por palabra"; checked: root.configEntry.enableKaraokeBall ?? true; onToggled: root.setValue("enableKaraokeBall", checked) }
                        Label { text: "Tamaño de la bola"; color: root.onSurface; font.pixelSize: 11 }
                        Slider {
                                Material.accent: root.studioAccent
                            Layout.fillWidth: true
                            from: 0.65
                            to: 1.7
                            stepSize: 0.05
                            value: Number(root.configEntry.karaokeBallSize ?? 1.0)
                            onMoved: root.setValue("karaokeBallSize", value)
                        }
                        Switch {
                            Material.accent: root.studioAccent
                            Layout.fillWidth: true; text: "Mostrar proveedor de letras"; checked: root.configEntry.showSource ?? true; onToggled: root.setValue("showSource", checked) }
                        Switch {
                            Material.accent: root.studioAccent
                            Layout.fillWidth: true; text: "Precargar próximas letras cuando sea posible"; checked: root.configEntry.prefetchEnabled ?? true; onToggled: root.setValue("prefetchEnabled", checked) }
                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: "La precarga depende de la cola que exponga el reproductor y del proveedor disponible. Las letras encontradas se conservan en caché."
                            color: root.onSurfaceVariant
                            font.pixelSize: 10
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        Material.accent: root.studioAccent
                        text: "Restaurar valores"
                        onClicked: root.restoreDefaults()
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: "LYRICA • STUDIO"
                        color: root.studioAccent
                        font.pixelSize: 9
                        font.letterSpacing: 1.0
                    }
                }
            }
        }
    }
}
