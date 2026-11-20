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

    visible: open
    opacity: open ? 1 : 0
    radius: 22
    color: Qt.darker(surfaceColor, 1.04)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.24)
    clip: true
    Behavior on opacity { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }

    function value(key, fallback) {
        const v = root.configEntry[key]
        return v === undefined || v === null ? fallback : v
    }

    component SectionTitle: Label {
        Layout.fillWidth: true
        color: root.accent
        font.pixelSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 1.35
        topPadding: 7
        bottomPadding: 2
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 2
                Label { text: "LYRICA"; color: "#f7f3ff"; font.pixelSize: 19; font.weight: Font.DemiBold }
                Label { text: "Personalización del escenario"; color: "#a9a1b8"; font.pixelSize: 11 }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 34; height: 34; radius: 12
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.13)
                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.24)
                Text { anchors.centerIn: parent; text: "✦"; color: root.accent; font.pixelSize: 17 }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff18" }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                width: parent.width
                spacing: 12

                SectionTitle { text: "APARIENCIA" }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Color de acento"; color: "#f5f1fb"; font.pixelSize: 12; Layout.fillWidth: true }
                    ComboBox {
                        id: paletteMode
                        Layout.preferredWidth: 156
                        model: ["Carátula", "Tema", "Personalizado"]
                        currentIndex: ({"album":0,"theme":1,"custom":2})[String(root.value("accentMode","album"))] ?? 0
                        onActivated: index => root.configEntry.accentMode = ["album","theme","custom"][index]
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    visible: String(root.value("accentMode","album")) === "custom"
                    Label { text: "Color HEX"; color: "#c9c1d5"; font.pixelSize: 11; Layout.fillWidth: true }
                    TextField {
                        Layout.preferredWidth: 126
                        text: String(root.value("customAccentColor","#b7a1ff"))
                        onEditingFinished: if (/^#[0-9a-fA-F]{6}$/.test(text)) root.configEntry.customAccentColor = text
                    }
                }

                SectionTitle { text: "MOVIMIENTO" }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Reacción al audio"; color: "#f5f1fb"; font.pixelSize: 12; Layout.fillWidth: true }
                    Switch { checked: root.value("enableBounce",true); onToggled: root.configEntry.enableBounce = checked }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Intensidad"; color: "#c9c1d5"; font.pixelSize: 11; Layout.fillWidth: true }
                    Label { text: Math.round(Number(root.value("bounceIntensity",1))*100)+"%"; color: root.accent; font.pixelSize: 11 }
                }
                Slider {
                    Layout.fillWidth: true
                    from: 0; to: 2.5; stepSize: 0.05
                    value: Number(root.value("bounceIntensity",1))
                    onMoved: root.configEntry.bounceIntensity = value
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Letras serpenteantes"; color: "#f5f1fb"; font.pixelSize: 12; Layout.fillWidth: true }
                    Switch { checked: root.value("enableWaveLetters",true); onToggled: root.configEntry.enableWaveLetters = checked }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Intensidad de onda"; color: "#c9c1d5"; font.pixelSize: 11; Layout.fillWidth: true }
                    Label { text: Math.round(Number(root.value("waveIntensity",0.35))*100)+"%"; color: root.accent; font.pixelSize: 11 }
                }
                Slider {
                    Layout.fillWidth: true
                    from: 0; to: 1; stepSize: 0.025
                    value: Number(root.value("waveIntensity",0.35))
                    onMoved: root.configEntry.waveIntensity = value
                    enabled: root.value("enableWaveLetters",true)
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Velocidad de onda"; color: "#c9c1d5"; font.pixelSize: 11; Layout.fillWidth: true }
                    Label { text: Number(root.value("waveSpeed",0.75)).toFixed(2)+"×"; color: root.accent; font.pixelSize: 11 }
                }
                Slider {
                    Layout.fillWidth: true
                    from: 0.25; to: 1.8; stepSize: 0.05
                    value: Number(root.value("waveSpeed",0.75))
                    onMoved: root.configEntry.waveSpeed = value
                    enabled: root.value("enableWaveLetters",true)
                }

                SectionTitle { text: "LETRAS Y KARAOKE" }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Bola de seguimiento"; color: "#f5f1fb"; font.pixelSize: 12; Layout.fillWidth: true }
                    Switch { checked: root.value("enableKaraokeBall",true); onToggled: root.configEntry.enableKaraokeBall = checked }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Mostrar proveedor"; color: "#f5f1fb"; font.pixelSize: 12; Layout.fillWidth: true }
                    Switch { checked: root.value("showSource",true); onToggled: root.configEntry.showSource = checked }
                }

                SectionTitle { text: "AMBIENTE" }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Nube de fondo"; color: "#f5f1fb"; font.pixelSize: 12; Layout.fillWidth: true }
                    Switch { checked: root.value("enableBackground",true); onToggled: root.configEntry.enableBackground = checked }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Opacidad"; color: "#c9c1d5"; font.pixelSize: 11; Layout.fillWidth: true }
                    Label { text: Math.round(Number(root.value("cloudOpacity",0.55))*100)+"%"; color: root.accent; font.pixelSize: 11 }
                }
                Slider {
                    Layout.fillWidth: true
                    from: 0; to: 1; stepSize: 0.025
                    value: Number(root.value("cloudOpacity",0.55))
                    onMoved: root.configEntry.cloudOpacity = value
                    enabled: root.value("enableBackground",true)
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Partículas"; color: "#f5f1fb"; font.pixelSize: 12; Layout.fillWidth: true }
                    Switch { checked: root.value("enableParticles",true); onToggled: root.configEntry.enableParticles = checked }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Desenfoque"; color: "#f5f1fb"; font.pixelSize: 12; Layout.fillWidth: true }
                    Switch { checked: root.value("enableBlur",true); onToggled: root.configEntry.enableBlur = checked }
                }

                SectionTitle { text: "MANTENIMIENTO" }
                Label {
                    Layout.fillWidth: true
                    text: "Las letras descargadas se guardan en caché para acelerar los cambios de canción."
                    color: "#a9a1b8"; font.pixelSize: 10; wrapMode: Text.Wrap
                }
                Button {
                    Layout.fillWidth: true
                    text: "Restaurar valores recomendados"
                    onClicked: {
                        root.configEntry.accentMode = "album"
                        root.configEntry.customAccentColor = "#b7a1ff"
                        root.configEntry.enableBlur = true
                        root.configEntry.enableBounce = true
                        root.configEntry.bounceIntensity = 1
                        root.configEntry.enableWaveLetters = true
                        root.configEntry.waveIntensity = 0.35
                        root.configEntry.waveSpeed = 0.75
                        root.configEntry.enableBackground = true
                        root.configEntry.cloudOpacity = 0.55
                        root.configEntry.enableParticles = true
                        root.configEntry.enableKaraokeBall = true
                        root.configEntry.showSource = true
                    }
                }
                Item { Layout.fillWidth: true; implicitHeight: 4 }
            }
        }
    }
}