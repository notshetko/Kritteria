pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    required property var configEntry
    property bool open: false
    property color accent: "#b7a1ff"
    property color surfaceColor: "#281c38"

    function setValue(key, value) {
        root.configEntry[key] = value
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
    }

    visible: open
    opacity: open ? 1 : 0
    radius: 24
    color: Qt.darker(surfaceColor, 1.035)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.62)
    clip: true
    Behavior on opacity { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                width: 38
                height: 38
                radius: 13
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
                Text {
                    anchors.centerIn: parent
                    text: "✦"
                    color: root.accent
                    font.pixelSize: 22
                }
            }
            ColumnLayout {
                spacing: 1
                Label {
                    text: "Lyrica Studio"
                    color: "white"
                    font.pixelSize: 19
                    font.bold: true
                }
                Label {
                    text: "Tu escenario, a tu manera"
                    color: "#bcb5ca"
                    font.pixelSize: 11
                }
            }
            Item { Layout.fillWidth: true }
            Label {
                text: "STUDIO"
                color: root.accent
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.3
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25)
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: Math.max(0, parent.width)
                spacing: 13

                Label {
                    text: "ESCENAS"
                    color: root.accent
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.5
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 7
                    columnSpacing: 7
                    Repeater {
                        model: [
                            { id: "dreamy", title: "Dreamy", sub: "Suave y etéreo", glyph: "cloud" },
                            { id: "aurora", title: "Aurora", sub: "Brillo y energía", glyph: "flare" },
                            { id: "minimal", title: "Minimal", sub: "Limpio y ligero", glyph: "circle" },
                            { id: "karaoke", title: "Karaoke", sub: "Voz protagonista", glyph: "lyrics" }
                        ]
                        delegate: Button {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            onClicked: root.applyPreset(modelData.id)
                            background: Rectangle {
                                radius: 13
                                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.10)
                                border.width: 1
                                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25)
                            }
                            contentItem: RowLayout {
                                spacing: 8
                                Text {
                                    text: modelData.glyph
                                    color: root.accent
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 19
                                }
                                ColumnLayout {
                                    spacing: 0
                                    Label {
                                        text: modelData.title
                                        color: "white"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                    Label {
                                        text: modelData.sub
                                        color: "#bcb5ca"
                                        font.pixelSize: 9
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 15
                    color: "#ffffff08"
                    border.color: "#ffffff12"
                    implicitHeight: paletteColumn.implicitHeight + 20
                    ColumnLayout {
                        id: paletteColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Label {
                            text: "APARIENCIA Y COLOR"
                            color: root.accent
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.2
                        }
                        Label { text: "Paleta de acento"; color: "white"; font.bold: true; font.pixelSize: 12 }
                        ComboBox {
                            Layout.fillWidth: true
                            model: ["Carátula dinámica", "Tema del sistema", "Color personalizado"]
                            currentIndex: ({"album": 0, "theme": 1, "custom": 2})[String(root.configEntry.accentMode ?? "album")] ?? 0
                            onActivated: index => root.setValue("accentMode", ["album", "theme", "custom"][index])
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "Color personalizado"; color: "#ddd6e8"; Layout.fillWidth: true; font.pixelSize: 11 }
                            TextField {
                                Layout.preferredWidth: 112
                                text: String(root.configEntry.customAccentColor ?? "#b7a1ff")
                                placeholderText: "#b7a1ff"
                                onEditingFinished: if (/^#[0-9a-fA-F]{6}$/.test(text)) root.setValue("customAccentColor", text)
                            }
                        }
                        Label { text: "Intensidad de la nube"; color: "white"; font.pixelSize: 11 }
                        RowLayout {
                            Layout.fillWidth: true
                            Slider {
                                Layout.fillWidth: true
                                from: 0
                                to: 1
                                stepSize: 0.02
                                value: Number(root.configEntry.cloudOpacity ?? 0.72)
                                onMoved: root.setValue("cloudOpacity", value)
                            }
                            Label {
                                text: Math.round(Number(root.configEntry.cloudOpacity ?? 0.72) * 100) + "%"
                                color: root.accent
                                font.pixelSize: 10
                                Layout.preferredWidth: 34
                            }
                        }
                        Label { text: "Resplandor de las letras"; color: "white"; font.pixelSize: 11 }
                        RowLayout {
                            Layout.fillWidth: true
                            Slider {
                                Layout.fillWidth: true
                                from: 0.2
                                to: 1.5
                                stepSize: 0.05
                                value: Number(root.configEntry.glowIntensity ?? 1.0)
                                onMoved: root.setValue("glowIntensity", value)
                            }
                            Label {
                                text: Math.round(Number(root.configEntry.glowIntensity ?? 1.0) * 100) + "%"
                                color: root.accent
                                font.pixelSize: 10
                                Layout.preferredWidth: 38
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 15
                    color: "#ffffff08"
                    border.color: "#ffffff12"
                    implicitHeight: motionColumn.implicitHeight + 20
                    ColumnLayout {
                        id: motionColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Label {
                            text: "MOVIMIENTO Y PROFUNDIDAD"
                            color: root.accent
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.2
                        }
                        Label { text: "Reacción a la música"; color: "white"; font.pixelSize: 11 }
                        Slider {
                            Layout.fillWidth: true
                            from: 0
                            to: 2
                            stepSize: 0.05
                            value: Number(root.configEntry.motionIntensity ?? 1.0)
                            onMoved: root.setValue("motionIntensity", value)
                        }
                        Label { text: "Inclinación de la rueda de letras"; color: "white"; font.pixelSize: 11 }
                        Slider {
                            Layout.fillWidth: true
                            from: 0
                            to: 1.8
                            stepSize: 0.05
                            value: Number(root.configEntry.wheelIntensity ?? 1.0)
                            onMoved: root.setValue("wheelIntensity", value)
                        }
                        Switch { Layout.fillWidth: true; text: "Rebote sutil al ritmo"; checked: root.configEntry.enableBounce ?? true; onToggled: root.setValue("enableBounce", checked) }
                        Switch { Layout.fillWidth: true; text: "Desenfoque en los silencios"; checked: root.configEntry.enableBlur ?? true; onToggled: root.setValue("enableBlur", checked) }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 15
                    color: "#ffffff08"
                    border.color: "#ffffff12"
                    implicitHeight: effectsColumn.implicitHeight + 20
                    ColumnLayout {
                        id: effectsColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 7
                        Label {
                            text: "EFECTOS AMBIENTALES"
                            color: root.accent
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.2
                        }
                        Switch { Layout.fillWidth: true; text: "Nube pastel dinámica"; checked: root.configEntry.enableBackground ?? true; onToggled: root.setValue("enableBackground", checked) }
                        Switch { Layout.fillWidth: true; text: "Partículas y destellos"; checked: root.configEntry.enableParticles ?? true; onToggled: root.setValue("enableParticles", checked) }
                        Switch { Layout.fillWidth: true; text: "Glitch cromático discreto"; checked: root.configEntry.enableGlitch ?? true; onToggled: root.setValue("enableGlitch", checked) }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 15
                    color: "#ffffff08"
                    border.color: "#ffffff12"
                    implicitHeight: karaokeColumn.implicitHeight + 20
                    ColumnLayout {
                        id: karaokeColumn
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Label {
                            text: "KARAOKE Y LETRAS"
                            color: root.accent
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.2
                        }
                        Switch { Layout.fillWidth: true; text: "Bola sincronizada por palabra"; checked: root.configEntry.enableKaraokeBall ?? true; onToggled: root.setValue("enableKaraokeBall", checked) }
                        Label { text: "Tamaño de la bola"; color: "white"; font.pixelSize: 11 }
                        Slider {
                            Layout.fillWidth: true
                            from: 0.65
                            to: 1.7
                            stepSize: 0.05
                            value: Number(root.configEntry.karaokeBallSize ?? 1.0)
                            onMoved: root.setValue("karaokeBallSize", value)
                        }
                        Switch { Layout.fillWidth: true; text: "Mostrar proveedor de letras"; checked: root.configEntry.showSource ?? true; onToggled: root.setValue("showSource", checked) }
                        Switch { Layout.fillWidth: true; text: "Precargar próximas letras cuando sea posible"; checked: root.configEntry.prefetchEnabled ?? true; onToggled: root.setValue("prefetchEnabled", checked) }
                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: "La precarga depende de la cola que exponga el reproductor y del proveedor disponible. Las letras encontradas se conservan en caché."
                            color: "#bcb5ca"
                            font.pixelSize: 10
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Restaurar valores"
                        onClicked: root.restoreDefaults()
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: "LYRICA • STUDIO"
                        color: root.accent
                        font.pixelSize: 9
                        font.letterSpacing: 1.0
                    }
                }
            }
        }
    }
}
