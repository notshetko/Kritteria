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
    property bool enableBlur: true
    property bool enableBounce: true
    property bool enableBackground: true
    property bool enableParticles: true
    property bool enableKaraokeBall: true
    property bool enableWaveLetters: false
    property real bounceIntensity: 0.55
    property real lyricFontWeight: 750
    property real waveIntensity: 0.38
    property real waveSpeed: 1.0
    property real cloudOpacity: 0.42
    property string accentMode: "album"
    property string customAccentColor: "#a9baff"
    signal settingChanged(string key, var value)

    visible: open
    opacity: open ? 1 : 0
    radius: 24
    color: "#ee141a29"
    border.width: 1
    border.color: "#45a9baff"
    clip: true
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    function setValue(key, value) { root.settingChanged(key, value) }

    function resetDefaults() {
        setValue("accentMode", "album")
        setValue("customAccentColor", "#a9baff")
        setValue("enableBlur", true)
        setValue("enableBounce", true)
        setValue("bounceIntensity", 0.55)
        setValue("lyricFontWeight", 750)
        setValue("enableWaveLetters", false)
        setValue("waveIntensity", 0.38)
        setValue("waveSpeed", 1.0)
        setValue("enableBackground", true)
        setValue("cloudOpacity", 0.42)
        setValue("enableParticles", true)
        setValue("enableKaraokeBall", true)
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
                        valueText: String(Math.round(Number(root.lyricFontWeight)))
                        accent: root.accent
                    }
                    LyricaStudioSlider {
                        id: fontWeightSlider
                        width: parent.width
                        from: 400; to: 900; stepSize: 0; snapMode: Slider.NoSnap
                        value: Number(root.lyricFontWeight)
                        accent: root.accent
                        onMoved: root.setValue("lyricFontWeight", fontWeightSlider.value)
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
                                font.weight: Math.round(Number(root.lyricFontWeight))
                                font.variableAxes: ({ "wght": Number(root.lyricFontWeight), "wdth": Number(Appearance.font.variableAxes.main.wdth ?? 100) })
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
                                color: String(root.accentMode) === modelData.key ? "#2ca9baff" : "#0dffffff"
                                border.color: String(root.accentMode) === modelData.key ? "#75a9baff" : "#20ffffff"
                                Text { anchors.centerIn: parent; text: modelData.title; color: "#edf0fb"; font.pixelSize: 11 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setValue("accentMode", modelData.key) }
                            }
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: 42
                        radius: 10
                        color: "#0effffff"
                        visible: String(root.accentMode) === "custom"
                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10
                            Text { text: "HEX"; color: "#aeb7ce"; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 11 }
                            TextInput {
                                width: parent.width - 45
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(root.customAccentColor)
                                color: "#f5f6ff"
                                font.pixelSize: 13
                                selectByMouse: true
                                onEditingFinished: if (/^#[0-9a-fA-F]{6}$/.test(text)) root.setValue("customAccentColor", text)
                            }
                        }
                    }
                    Row {
                        width: parent.width
                        height: 32
                        spacing: 10
                        Text { text: "Bola de seguimiento karaoke"; color: "#e7eaf6"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60 }
                        LyricaStudioToggle { id: karaokeBallToggle; checked: root.enableKaraokeBall; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setValue("enableKaraokeBall", karaokeBallToggle.checked) }
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
                        LyricaStudioToggle { id: bounceToggle; checked: root.enableBounce; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setValue("enableBounce", bounceToggle.checked) }
                    }
                    LyricaSettingRow {
                        label: "Intensidad del rebote"
                        valueText: Math.round(Number(root.bounceIntensity) * 100) + "%"
                        accent: root.accent
                    }
                    LyricaStudioSlider {
                        id: bounceIntensitySlider
                        width: parent.width
                        from: 0.1; to: 1.0; stepSize: 0.05
                        value: Number(root.bounceIntensity)
                        accent: root.accent
                        onMoved: root.setValue("bounceIntensity", bounceIntensitySlider.value)
                    }
                    Rectangle { width: parent.width; height: 1; color: "#20ffffff" }
                    Row {
                        width: parent.width
                        height: 32
                        Text { text: "Onda serpenteante"; color: "#e7eaf6"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60 }
                        LyricaStudioToggle { id: waveToggle; checked: root.enableWaveLetters; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setValue("enableWaveLetters", waveToggle.checked) }
                    }
                    LyricaSettingRow {
                        label: "Intensidad de onda"
                        valueText: Math.round(Number(root.waveIntensity) * 100) + "%"
                        accent: root.accent
                    }
                    LyricaStudioSlider {
                        id: waveIntensitySlider
                        width: parent.width
                        from: 0; to: 1; stepSize: 0.025
                        value: Number(root.waveIntensity)
                        accent: root.accent
                        onMoved: root.setValue("waveIntensity", waveIntensitySlider.value)
                    }
                    LyricaSettingRow {
                        label: "Velocidad de onda"
                        valueText: Number(root.waveSpeed).toFixed(2) + "×"
                        accent: root.accent
                    }
                    LyricaStudioSlider {
                        id: waveSpeedSlider
                        width: parent.width
                        from: 0.25; to: 2.0; stepSize: 0.05
                        value: Number(root.waveSpeed)
                        accent: root.accent
                        onMoved: root.setValue("waveSpeed", waveSpeedSlider.value)
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
                        LyricaStudioToggle { id: backgroundToggle; checked: root.enableBackground; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setValue("enableBackground", backgroundToggle.checked) }
                    }
                    LyricaSettingRow {
                        label: "Opacidad de la nube"
                        valueText: Math.round(Number(root.cloudOpacity) * 100) + "%"
                        accent: root.accent
                    }
                    LyricaStudioSlider {
                        id: cloudOpacitySlider
                        width: parent.width
                        from: 0; to: 1; stepSize: 0.025
                        value: Number(root.cloudOpacity)
                        accent: root.accent
                        onMoved: root.setValue("cloudOpacity", cloudOpacitySlider.value)
                    }
                    Row {
                        width: parent.width
                        height: 32
                        Text { text: "Partículas ambientales"; color: "#e7eaf6"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60 }
                        LyricaStudioToggle { id: particlesToggle; checked: root.enableParticles; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setValue("enableParticles", particlesToggle.checked) }
                    }
                    Row {
                        width: parent.width
                        height: 32
                        Text { text: "Desenfoque ambiental"; color: "#e7eaf6"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60 }
                        LyricaStudioToggle { id: blurToggle; checked: root.enableBlur; anchors.verticalCenter: parent.verticalCenter; onToggled: root.setValue("enableBlur", blurToggle.checked) }
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
