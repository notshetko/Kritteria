pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common

Rectangle {
    id: root
    required property var configEntry
    property bool open: false
    property color accent: "#b7a1ff"
    property color surfaceColor: "#281c38"
    property int activeTab: 0

    visible: open
    opacity: open ? 1 : 0
    radius: 24
    color: Qt.rgba(18 / 255, 17 / 255, 29 / 255, 0.94)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.34)
    clip: true
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    function value(key, fallback) {
        const v = root.configEntry[key]
        return v === undefined || v === null ? fallback : v
    }

    function resetDefaults() {
        root.configEntry.accentMode = "album"
        root.configEntry.customAccentColor = "#b7a1ff"
        root.configEntry.enableBlur = true
        root.configEntry.enableBounce = true
        root.configEntry.bounceIntensity = 1.8
        root.configEntry.lyricFontWeight = 700
        root.configEntry.enableWaveLetters = false
        root.configEntry.waveIntensity = 0.25
        root.configEntry.waveSpeed = 0.75
        root.configEntry.enableBackground = true
        root.configEntry.cloudOpacity = 0.42
        root.configEntry.enableParticles = true
        root.configEntry.enableKaraokeBall = true
        root.configEntry.showSource = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 13

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Label {
                    text: "LYRICA STUDIO"
                    color: "#fbf9ff"
                    font.pixelSize: 21
                    font.weight: Font.Bold
                    font.letterSpacing: 1.15
                }
                Label {
                    text: "Diseña cómo se sienten tus letras"
                    color: "#c3bdce"
                    font.pixelSize: 13
                }
            }
            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                radius: 15
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.36)
                Text {
                    anchors.centerIn: parent
                    text: "✦"
                    color: root.accent
                    font.pixelSize: 22
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 7
            Repeater {
                model: [
                    { title: "LETRAS", subtitle: "Tipografía", index: 0 },
                    { title: "MOVIMIENTO", subtitle: "Audio y ritmo", index: 1 },
                    { title: "AMBIENTE", subtitle: "Color y fondo", index: 2 }
                ]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: 13
                    color: root.activeTab === modelData.index
                        ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20)
                        : "#ffffff08"
                    border.width: 1
                    border.color: root.activeTab === modelData.index
                        ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55)
                        : "#ffffff14"
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.title
                            color: root.activeTab === modelData.index ? "#ffffff" : "#c6c0d0"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 0.55
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.subtitle
                            color: "#a9a2b5"
                            font.pixelSize: 10
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = modelData.index
                    }
                    Behavior on color { ColorAnimation { duration: 130 } }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#ffffff1c"
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.activeTab

            // TYPOGRAPHY
            Flickable {
                clip: true
                contentWidth: width
                contentHeight: typographyColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                ColumnLayout {
                    id: typographyColumn
                    width: parent.width
                    spacing: 14

                    Label {
                        text: "La línea principal"
                        color: "#ffffff"
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }
                    Label {
                        text: "Ajusta la presencia de la letra enfocada sin alterar el resto de la rueda."
                        color: "#bdb6c9"
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Grosor"; color: "#f1edf7"; font.pixelSize: 14; Layout.fillWidth: true }
                        Label {
                            text: Math.round(Number(root.value("lyricFontWeight", 700)))
                            color: root.accent
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                    }
                    Slider {
                        id: weightSlider
                        Layout.fillWidth: true
                        from: 400
                        to: 900
                        stepSize: 50
                        value: Number(root.value("lyricFontWeight", 700))
                        onMoved: root.configEntry.lyricFontWeight = value
                        background: Rectangle {
                            x: weightSlider.leftPadding
                            y: weightSlider.topPadding + weightSlider.availableHeight / 2 - height / 2
                            width: weightSlider.availableWidth
                            height: 5
                            radius: 3
                            color: "#ffffff24"
                            Rectangle {
                                width: weightSlider.visualPosition * parent.width
                                height: parent.height
                                radius: 3
                                color: root.accent
                            }
                        }
                        handle: Rectangle {
                            x: weightSlider.leftPadding + weightSlider.visualPosition * (weightSlider.availableWidth - width)
                            y: weightSlider.topPadding + weightSlider.availableHeight / 2 - height / 2
                            width: 18
                            height: 18
                            radius: 9
                            color: "#ffffff"
                            border.width: 3
                            border.color: root.accent
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 74
                        radius: 15
                        color: "#ffffff0a"
                        border.color: "#ffffff16"
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Así se verá la línea principal"
                                color: "#f8f5ff"
                                font.family: Appearance.font.family.main
                                font.pixelSize: 19
                                font.weight: Number(root.value("lyricFontWeight", 700))
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Vista previa del grosor"
                                color: "#b8b1c4"
                                font.pixelSize: 11
                            }
                        }
                    }

                    Label {
                        text: "Color de acento"
                        color: "#f1edf7"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: [
                                { title: "Carátula", key: "album" },
                                { title: "Tema", key: "theme" },
                                { title: "Propio", key: "custom" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                radius: 11
                                color: String(root.value("accentMode", "album")) === modelData.key
                                    ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
                                    : "#ffffff0a"
                                border.color: String(root.value("accentMode", "album")) === modelData.key
                                    ? root.accent : "#ffffff1a"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.title
                                    color: "#f5f1fb"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.configEntry.accentMode = modelData.key
                                }
                            }
                        }
                    }
                    TextField {
                        Layout.fillWidth: true
                        visible: String(root.value("accentMode", "album")) === "custom"
                        placeholderText: "#RRGGBB"
                        text: String(root.value("customAccentColor", "#b7a1ff"))
                        color: "#ffffff"
                        font.pixelSize: 14
                        onEditingFinished: if (/^#[0-9a-fA-F]{6}$/.test(text)) root.configEntry.customAccentColor = text
                        background: Rectangle {
                            radius: 10
                            color: "#ffffff0d"
                            border.color: "#ffffff28"
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Bola de seguimiento karaoke"; color: "#f1edf7"; font.pixelSize: 13; Layout.fillWidth: true }
                        Switch {
                            checked: root.value("enableKaraokeBall", true)
                            onToggled: root.configEntry.enableKaraokeBall = checked
                            indicator: Rectangle {
                                implicitWidth: 42; implicitHeight: 24
                                x: parent.leftPadding
                                y: parent.height / 2 - height / 2
                                radius: 12
                                color: parent.checked ? root.accent : "#55505f"
                                Rectangle {
                                    x: parent.parent.checked ? 21 : 3
                                    y: 3
                                    width: 18; height: 18; radius: 9
                                    color: "#ffffff"
                                    Behavior on x { NumberAnimation { duration: 120 } }
                                }
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Mostrar fuente de las letras"; color: "#f1edf7"; font.pixelSize: 13; Layout.fillWidth: true }
                        Switch { checked: root.value("showSource", true); onToggled: root.configEntry.showSource = checked }
                    }
                }
            }

            // MOTION
            Flickable {
                clip: true
                contentWidth: width
                contentHeight: motionColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                ColumnLayout {
                    id: motionColumn
                    width: parent.width
                    spacing: 13
                    Label {
                        text: "Reacción musical"
                        color: "#ffffff"
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }
                    Label {
                        text: "El movimiento responde al audio que ya utiliza el visualizador de Kritteria."
                        color: "#bdb6c9"
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Rebote al ritmo"; color: "#f1edf7"; font.pixelSize: 14; Layout.fillWidth: true }
                        Switch { checked: root.value("enableBounce", true); onToggled: root.configEntry.enableBounce = checked }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Intensidad del rebote"; color: "#f1edf7"; font.pixelSize: 13; Layout.fillWidth: true }
                        Label { text: Math.round(Number(root.value("bounceIntensity", 1.8)) * 100) + "%"; color: root.accent; font.pixelSize: 13; font.weight: Font.Bold }
                    }
                    Slider {
                        id: bounceSlider
                        Layout.fillWidth: true
                        from: 0.25; to: 2.5; stepSize: 0.05
                        value: Number(root.value("bounceIntensity", 1.8))
                        enabled: root.value("enableBounce", true)
                        onMoved: root.configEntry.bounceIntensity = value
                        background: Rectangle {
                            x: bounceSlider.leftPadding
                            y: bounceSlider.topPadding + bounceSlider.availableHeight / 2 - height / 2
                            width: bounceSlider.availableWidth
                            height: 5; radius: 3; color: "#ffffff24"
                            Rectangle { width: bounceSlider.visualPosition * parent.width; height: parent.height; radius: 3; color: root.accent }
                        }
                        handle: Rectangle {
                            x: bounceSlider.leftPadding + bounceSlider.visualPosition * (bounceSlider.availableWidth - width)
                            y: bounceSlider.topPadding + bounceSlider.availableHeight / 2 - height / 2
                            width: 18; height: 18; radius: 9; color: "#ffffff"; border.width: 3; border.color: root.accent
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#ffffff18"
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Onda serpenteante"; color: "#f1edf7"; font.pixelSize: 13; Layout.fillWidth: true }
                        Switch { checked: root.value("enableWaveLetters", false); onToggled: root.configEntry.enableWaveLetters = checked }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Intensidad de onda"; color: "#c8c1d2"; font.pixelSize: 12; Layout.fillWidth: true }
                        Label { text: Math.round(Number(root.value("waveIntensity", 0.25)) * 100) + "%"; color: root.accent; font.pixelSize: 12 }
                    }
                    Slider {
                        Layout.fillWidth: true
                        from: 0; to: 1; stepSize: 0.025
                        value: Number(root.value("waveIntensity", 0.25))
                        enabled: root.value("enableWaveLetters", false)
                        onMoved: root.configEntry.waveIntensity = value
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Velocidad de onda"; color: "#c8c1d2"; font.pixelSize: 12; Layout.fillWidth: true }
                        Label { text: Number(root.value("waveSpeed", 0.75)).toFixed(2) + "×"; color: root.accent; font.pixelSize: 12 }
                    }
                    Slider {
                        Layout.fillWidth: true
                        from: 0.25; to: 1.8; stepSize: 0.05
                        value: Number(root.value("waveSpeed", 0.75))
                        enabled: root.value("enableWaveLetters", false)
                        onMoved: root.configEntry.waveSpeed = value
                    }
                }
            }

            // AMBIENCE
            Flickable {
                clip: true
                contentWidth: width
                contentHeight: ambienceColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                ColumnLayout {
                    id: ambienceColumn
                    width: parent.width
                    spacing: 13
                    Label { text: "Escenario"; color: "#ffffff"; font.pixelSize: 17; font.weight: Font.DemiBold }
                    Label {
                        text: "Controla el ambiente visual que acompaña a la canción."
                        color: "#bdb6c9"; font.pixelSize: 13; wrapMode: Text.Wrap; Layout.fillWidth: true
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Nube de fondo"; color: "#f1edf7"; font.pixelSize: 13; Layout.fillWidth: true }
                        Switch { checked: root.value("enableBackground", true); onToggled: root.configEntry.enableBackground = checked }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Opacidad de la nube"; color: "#c8c1d2"; font.pixelSize: 12; Layout.fillWidth: true }
                        Label { text: Math.round(Number(root.value("cloudOpacity", 0.42)) * 100) + "%"; color: root.accent; font.pixelSize: 12 }
                    }
                    Slider {
                        Layout.fillWidth: true
                        from: 0; to: 1; stepSize: 0.025
                        value: Number(root.value("cloudOpacity", 0.42))
                        enabled: root.value("enableBackground", true)
                        onMoved: root.configEntry.cloudOpacity = value
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Partículas"; color: "#f1edf7"; font.pixelSize: 13; Layout.fillWidth: true }
                        Switch { checked: root.value("enableParticles", true); onToggled: root.configEntry.enableParticles = checked }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Desenfoque ambiental"; color: "#f1edf7"; font.pixelSize: 13; Layout.fillWidth: true }
                        Switch { checked: root.value("enableBlur", true); onToggled: root.configEntry.enableBlur = checked }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#ffffff18" }
                    Label {
                        text: "Los ajustes se guardan directamente en la configuración del widget."
                        color: "#aaa3b6"; font.pixelSize: 12; wrapMode: Text.Wrap; Layout.fillWidth: true
                    }
                    Button {
                        Layout.fillWidth: true
                        text: "Restaurar ajustes recomendados"
                        onClicked: root.resetDefaults()
                        background: Rectangle {
                            radius: 12
                            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
                            border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.42)
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#ffffff"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }
}
