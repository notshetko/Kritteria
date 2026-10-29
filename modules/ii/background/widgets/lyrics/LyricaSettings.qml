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
    color: Qt.darker(surfaceColor, 1.03)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.7)
    clip: true
    Behavior on opacity { NumberAnimation { duration: 170 } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 1
                Label { text: "Lyrica Studio"; font.pixelSize: 20; font.bold: true; color: "white" }
                Label { text: "Personaliza cada detalle"; font.pixelSize: 11; color: "#bcb5ca" }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                radius: 10; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.17)
                width: 38; height: 30
                Label { anchors.centerIn: parent; text: "✦"; color: root.accent; font.pixelSize: 17 }
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28) }
        ScrollView {
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ColumnLayout {
                width: parent.width
                spacing: 13
                Label { text: "APARIENCIA"; color: root.accent; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.4 }
                Label { text: "Paleta de acento"; color: "white"; font.bold: true }
                ComboBox {
                    Layout.fillWidth: true
                    model: ["Carátula dinámica", "Tema del sistema", "Color personalizado"]
                    currentIndex: ({"album": 0, "theme": 1, "custom": 2})[String(root.configEntry.accentMode ?? "album")] ?? 0
                    onActivated: index => root.configEntry.accentMode = ["album", "theme", "custom"][index]
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Color personalizado"; color: "#ddd6e8"; Layout.fillWidth: true }
                    TextField {
                        Layout.preferredWidth: 112
                        text: String(root.configEntry.customAccentColor ?? "#b7a1ff")
                        placeholderText: "#b7a1ff"
                        onEditingFinished: if (/^#[0-9a-fA-F]{6}$/.test(text)) root.configEntry.customAccentColor = text
                    }
                }
                Label { text: "Intensidad del movimiento"; color: "white"; font.bold: true }
                Slider {
                    Layout.fillWidth: true; from: 0; to: 2; stepSize: 0.1
                    value: Number(root.configEntry.motionIntensity ?? 1.0)
                    onMoved: root.configEntry.motionIntensity = value
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Nube de fondo"; color: "#ddd6e8"; Layout.fillWidth: true }
                    Label { text: Math.round(Number(root.configEntry.cloudOpacity ?? 0.72) * 100) + "%"; color: root.accent }
                }
                Slider {
                    Layout.fillWidth: true; from: 0; to: 1; stepSize: 0.05
                    value: Number(root.configEntry.cloudOpacity ?? 0.72)
                    onMoved: root.configEntry.cloudOpacity = value
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff18" }
                Label { text: "EFECTOS"; color: root.accent; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.4 }
                Switch { Layout.fillWidth: true; text: "Desenfoque suave"; checked: root.configEntry.enableBlur ?? true; onToggled: root.configEntry.enableBlur = checked }
                Switch { Layout.fillWidth: true; text: "Reacción al ritmo"; checked: root.configEntry.enableBounce ?? true; onToggled: root.configEntry.enableBounce = checked }
                Switch { Layout.fillWidth: true; text: "Nube pastel"; checked: root.configEntry.enableBackground ?? true; onToggled: root.configEntry.enableBackground = checked }
                Switch { Layout.fillWidth: true; text: "Glitch cromático"; checked: root.configEntry.enableGlitch ?? true; onToggled: root.configEntry.enableGlitch = checked }
                Switch { Layout.fillWidth: true; text: "Partículas"; checked: root.configEntry.enableParticles ?? true; onToggled: root.configEntry.enableParticles = checked }
                Switch { Layout.fillWidth: true; text: "Bola karaoke"; checked: root.configEntry.enableKaraokeBall ?? true; onToggled: root.configEntry.enableKaraokeBall = checked }
                Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff18" }
                Label { text: "LETRAS Y FUENTES"; color: root.accent; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.4 }
                Switch { Layout.fillWidth: true; text: "Mostrar fuente actual"; checked: root.configEntry.showSource ?? true; onToggled: root.configEntry.showSource = checked }
                Label { text: "Precarga de letras"; color: "white"; font.bold: true }
                Switch { Layout.fillWidth: true; text: "Preparar próximas canciones cuando sea posible"; checked: root.configEntry.prefetchEnabled ?? true; onToggled: root.configEntry.prefetchEnabled = checked }
                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: "La precarga depende de si el reproductor expone la cola. Lyrica conservará las letras en caché para evitar repetir búsquedas."
                    color: "#bcb5ca"; font.pixelSize: 11
                }
                RowLayout {
                    Layout.fillWidth: true
                    Button {
                        text: "Restaurar ajustes"
                        onClicked: {
                            root.configEntry.accentMode = "album"
                            root.configEntry.customAccentColor = "#b7a1ff"
                            root.configEntry.motionIntensity = 1.0
                            root.configEntry.cloudOpacity = 0.72
                            root.configEntry.enableBlur = true
                            root.configEntry.enableBounce = true
                            root.configEntry.enableBackground = true
                            root.configEntry.enableGlitch = true
                            root.configEntry.enableParticles = true
                            root.configEntry.enableKaraokeBall = true
                            root.configEntry.showSource = true
                            root.configEntry.prefetchEnabled = true
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Label { text: "LYRICA 1.0"; color: root.accent; font.pixelSize: 10 }
                }
            }
        }
    }
}
