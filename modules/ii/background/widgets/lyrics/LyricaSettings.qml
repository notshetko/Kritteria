pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    required property var configEntry
    property bool open: false
    property color accent: "#a9baff"
    property int activeTab: 0

    visible: open
    opacity: open ? 1 : 0
    radius: 24
    color: "#ee141a29"
    border.width: 1
    border.color: "#45a9baff"
    clip: true
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    function value(key, fallback) {
        const v = root.configEntry[key]
        return v === undefined || v === null ? fallback : v
    }

    function resetDefaults() {
        root.configEntry.accentMode = "album"
        root.configEntry.customAccentColor = "#a9baff"
        root.configEntry.enableBlur = true
        root.configEntry.enableBounce = true
        root.configEntry.bounceIntensity = 1.6
        root.configEntry.lyricFontWeight = 750
        root.configEntry.enableWaveLetters = false
        root.configEntry.waveIntensity = 0.38
        root.configEntry.waveSpeed = 1.0
        root.configEntry.enableBackground = true
        root.configEntry.cloudOpacity = 0.42
        root.configEntry.enableParticles = true
        root.configEntry.enableKaraokeBall = true
    }




    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    text: "LYRICA STUDIO"
                    color: "#f6f7ff"
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    font.letterSpacing: 1.1
                }
                Text {
                    text: "Diseña cómo se sienten tus letras"
                    color: "#aeb7ce"
                    font.pixelSize: 12
                }
            }
            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 14
                color: "#1da9baff"
                border.color: "#45a9baff"
                Text { anchors.centerIn: parent; text: "✦"; color: root.accent; font.pixelSize: 20 }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 7
            Repeater {
                model: [
                    { title: "LETRAS", sub: "Tipografía", index: 0 },
                    { title: "MOVIMIENTO", sub: "Audio y ritmo", index: 1 },
                    { title: "AMBIENTE", sub: "Color y fondo", index: 2 }
                ]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 12
                    color: root.activeTab === modelData.index ? "#2ca9baff" : "#0dffffff"
                    border.width: 1
                    border.color: root.activeTab === modelData.index ? "#75a9baff" : "#18ffffff"
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.title
                            color: root.activeTab === modelData.index ? "#f7f8ff" : "#aeb7ce"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 0.5
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.sub
                            color: "#9ba5bd"
                            font.pixelSize: 10
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = modelData.index
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#20ffffff" }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.activeTab

            Flickable {
                clip: true
                contentWidth: width
                contentHeight: typography.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                Column {
                    id: typography
                    width: parent.width
                    spacing: 13
                    LyricaSectionHeading {
                        heading: "Presencia tipográfica"
                        description: "Ajusta el peso de la línea enfocada y el color que acompaña a la canción."
                    }
                    LyricaSettingRow {
                        label: "Grosor de la línea principal"
                        valueText: String(Math.round(Number(root.value("lyricFontWeight", 750))))
                        accent: root.accent
                    }
                    LyricaStudioSlider {
                        width: parent.width
                        from: 400; to: 900; stepSize: 50
                        value: Number(root.value("lyricFontWeight", 750))
                        accent: root.accent
                        onMoved: next => root.configEntry.lyricFontWeight = next
                    }
                    Rectangle {
                        width: parent.width
                        height: 76
                        radius: 14
                        color: "#0effffff"
                        border.color: "#1effffff"
                        Column {
                            anchors.centerIn: parent
                            spacing: 3
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Your secret inside"
                                color: "#f6f7ff"
                                font.family: Appearance.font.family.main
                                font.pixelSize: 20
                                font.weight: Number(root.value("lyricFontWeight", 750))
                            }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Vista previa en vivo"; color: "#aeb7ce"; font.pixelSize: 10 }
                        }
                    }
                    Text { text: "Color de acento"; color: "#e7eaf6"; font.pixelSize: 13; font.weight: Font.Medium }
                    Row {
                        width: parent.width
                        spacing: 6
                        Repeater {
                            model: [{ title: "Carátula", key: "album" }, { title: "Tema", key: "theme" }, { title: "Personalizado", key: "custom" }]
                            delegate: Rectangle {
                                required property var modelData
                                width: (parent.width - 12) / 3
                                height: 36
                                radius: 10
                                color: String(root.value("accentMode", "album")) === modelData.key ? "#2ca9baff" : "#0dffffff"
                                border.color: String(root.value("accentMode", "album")) === modelData.key ? "#75a9baff" : "#20ffffff"
                                Text { anchors.centerIn: parent; text: modelData.title; color: "#edf0fb"; font.pixelSize: 11 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.configEntry.accentMode = modelData.key }
                            }
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: 42
                        radius: 10
                        color: "#0effffff"
                        visible: String(root.value("accentMode", "album")) === "custom"
                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10
                            Text { text: "HEX"; color: "#aeb7ce"; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 11 }
                            TextInput {
                                width: parent.width - 45
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(root.value("customAccentColor", "#a9baff"))
                                color: "#f5f6ff"
                                font.pixelSize: 13
                                selectByMouse: true
                                onEditingFinished: if (/^#[0-9a-fA-F]{6}$/.test(text)) root.configEntry.customAccentColor = text
                            }
                        }
                    }
                    Row {
                        width: parent.width
                        height: 32
                        spacing: 10
                        Text { text: "Bola de seguimiento karaoke"; color: "#e7eaf6"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60 }
                        LyricaStudioToggle { checked: root.value("enableKaraokeBall", true); anchors.verticalCenter: parent.verticalCenter; onToggled: next => root.configEntry.enableKaraokeBall = next }
                    }
                }
            }

            Flickable {
                clip: true
                contentWidth: width
                contentHeight: motion.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                Column {
                    id: motion
                    width: parent.width
                    spacing: 13
                    LyricaSectionHeading {
                        heading: "Respuesta al sonido"
                        description: "La línea principal sigue la energía grave y los golpes del ritmo, con ataque rápido y caída suave."
                    }
                    Row {
                        width: parent.width
                        height: 32
                        Text { text: "Rebote musical"; color: "#e7eaf6"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60 }
                        LyricaStudioToggle { checked: root.value("enableBounce", true); anchors.verticalCenter: parent.verticalCenter; onToggled: next => root.configEntry.enableBounce = next }
                    }
                    LyricaSettingRow {
                        label: "Intensidad del rebote"
                        valueText: Math.round(Number(root.value("bounceIntensity", 1.6)) * 100) + "%"
                        accent: root.accent
                    }
                    LyricaStudioSlider {
                        width: parent.width
                        from: 0.5; to: 2.5; stepSize: 0.05
                        value: Number(root.value("bounceIntensity", 1.6))
                        accent: root.accent
                        onMoved: next => root.configEntry.bounceIntensity = next
                    }
                    Rectangle { width: parent.width; height: 1; color: "#20ffffff" }
                    Row {
                        width: parent.width
                        height: 32
                        Text { text: "Onda serpenteante"; color: "#e7eaf6"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60 }
                        LyricaStudioToggle { checked: root.value("enableWaveLetters", false); anchors.verticalCenter: parent.verticalCenter; onToggled: next => root.configEntry.enableWaveLetters = next }
                    }
                    LyricaSettingRow {
                        label: "Intensidad de onda"
                        valueText: Math.round(Number(root.value("waveIntensity", 0.38)) * 100) + "%"
                        accent: root.accent
                    }
                    LyricaStudioSlider {
                        width: parent.width
                        from: 0; to: 1; stepSize: 0.025
                        value: Number(root.value("waveIntensity", 0.38))
                        accent: root.accent
                        onMoved: next => root.configEntry.waveIntensity = next
                    }
                    LyricaSettingRow {
                        label: "Velocidad de onda"
                        valueText: Number(root.value("waveSpeed", 1.0)).toFixed(2) + "×"
                        accent: root.accent
                    }
                    LyricaStudioSlider {
                        width: parent.width
                        from: 0.25; to: 2.0; stepSize: 0.05
                        value: Number(root.value("waveSpeed", 1.0))
                        accent: root.accent
                        onMoved: next => root.configEntry.waveSpeed = next
                    }
                }
            }

            Flickable {
                clip: true
                contentWidth: width
                contentHeight: ambience.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                Column {
                    id: ambience
                    width: parent.width
                    spacing: 13
                    LyricaSectionHeading {
                        heading: "Escenario ambiental"
                        description: "Modifica el ambiente sin reducir el contraste ni la legibilidad de las letras."
                    }
                    Row {
                        width: parent.width
                        height: 32
                        Text { text: "Nube de fondo"; color: "#e7eaf6"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60 }
                        LyricaStudioToggle { checked: root.value("enableBackground", true); anchors.verticalCenter: parent.verticalCenter; onToggled: next => root.configEntry.enableBackground = next }
                    }
                    LyricaSettingRow {
                        label: "Opacidad de la nube"
                        valueText: Math.round(Number(root.value("cloudOpacity", 0.42)) * 100) + "%"
                        accent: root.accent
                    }
                    LyricaStudioSlider {
                        width: parent.width
                        from: 0; to: 1; stepSize: 0.025
                        value: Number(root.value("cloudOpacity", 0.42))
                        accent: root.accent
                        onMoved: next => root.configEntry.cloudOpacity = next
                    }
                    Row {
                        width: parent.width
                        height: 32
                        Text { text: "Partículas ambientales"; color: "#e7eaf6"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60 }
                        LyricaStudioToggle { checked: root.value("enableParticles", true); anchors.verticalCenter: parent.verticalCenter; onToggled: next => root.configEntry.enableParticles = next }
                    }
                    Row {
                        width: parent.width
                        height: 32
                        Text { text: "Desenfoque ambiental"; color: "#e7eaf6"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60 }
                        LyricaStudioToggle { checked: root.value("enableBlur", true); anchors.verticalCenter: parent.verticalCenter; onToggled: next => root.configEntry.enableBlur = next }
                    }
                    Rectangle { width: parent.width; height: 1; color: "#20ffffff" }
                    Text {
                        text: "Los cambios se guardan directamente en la configuración del widget."
                        color: "#9ba5bd"
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                        width: parent.width
                    }
                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: 11
                        color: "#20a9baff"
                        border.color: "#55a9baff"
                        Text { anchors.centerIn: parent; text: "Restaurar valores recomendados"; color: "#f4f6ff"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.resetDefaults() }
                    }
                }
            }
        }
    }
}
