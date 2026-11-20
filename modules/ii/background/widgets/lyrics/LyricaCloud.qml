pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

// Soft, layered aurora cloud. Built from radial light volumes rather than a flat puff silhouette.
Item {
    id: root

    property color colorA: "#b7a1ff"
    property color colorB: "#8bded7"
    property color colorC: "#91b8ff"
    property real energy: 0
    property real time: 0
    property bool blurEnabled: true
    property real strength: 0.42

    opacity: strength
    visible: opacity > 0.005

    Item {
        id: volume
        anchors.fill: parent
        scale: 1 + root.energy * 0.018
        transformOrigin: Item.Center

        // Main lavender volume, broad and feathered.
        Shape {
            id: mainVolume
            x: parent.width * 0.10 + Math.sin(root.time * 0.13) * 8
            y: parent.height * 0.27 + Math.cos(root.time * 0.11) * 5
            width: parent.width * 0.80
            height: parent.height * 0.48
            rotation: -4 + Math.sin(root.time * 0.17) * 3
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: root.blurEnabled
                blur: root.blurEnabled ? 0.82 : 0.16
                blurMax: 112
                autoPaddingEnabled: true
            }
            ShapePath {
                strokeColor: "transparent"
                startX: mainVolume.width * 0.5
                startY: 0
                fillGradient: RadialGradient {
                    centerX: mainVolume.width * 0.5
                    centerY: mainVolume.height * 0.5
                    centerRadius: mainVolume.width * 0.58
                    focalX: centerX
                    focalY: centerY
                    GradientStop { position: 0.0; color: Qt.rgba(root.colorA.r, root.colorA.g, root.colorA.b, 0.40) }
                    GradientStop { position: 0.30; color: Qt.rgba(root.colorA.r, root.colorA.g, root.colorA.b, 0.23) }
                    GradientStop { position: 0.66; color: Qt.rgba(root.colorC.r, root.colorC.g, root.colorC.b, 0.10) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                PathArc { x: mainVolume.width * 0.5; y: mainVolume.height; radiusX: mainVolume.width * 0.5; radiusY: mainVolume.height * 0.5; direction: PathArc.Clockwise }
                PathArc { x: mainVolume.width * 0.5; y: 0; radiusX: mainVolume.width * 0.5; radiusY: mainVolume.height * 0.5; direction: PathArc.Clockwise }
            }
        }

        // Cool cyan bloom drifting through the upper-right side.
        Shape {
            id: cyanBloom
            x: parent.width * 0.34 + Math.sin(root.time * 0.10 + 1.7) * 12
            y: parent.height * 0.08 + Math.cos(root.time * 0.12 + 0.4) * 7
            width: parent.width * 0.48
            height: parent.height * 0.68
            rotation: 18 + Math.sin(root.time * 0.15) * 5
            opacity: 0.86
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: root.blurEnabled
                blur: root.blurEnabled ? 0.90 : 0.18
                blurMax: 128
                autoPaddingEnabled: true
            }
            ShapePath {
                strokeColor: "transparent"
                startX: cyanBloom.width * 0.5
                startY: 0
                fillGradient: RadialGradient {
                    centerX: cyanBloom.width * 0.5
                    centerY: cyanBloom.height * 0.5
                    centerRadius: cyanBloom.width * 0.60
                    focalX: centerX
                    focalY: centerY
                    GradientStop { position: 0.0; color: Qt.rgba(root.colorB.r, root.colorB.g, root.colorB.b, 0.34) }
                    GradientStop { position: 0.34; color: Qt.rgba(root.colorB.r, root.colorB.g, root.colorB.b, 0.20) }
                    GradientStop { position: 0.72; color: Qt.rgba(root.colorC.r, root.colorC.g, root.colorC.b, 0.08) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                PathArc { x: cyanBloom.width * 0.5; y: cyanBloom.height; radiusX: cyanBloom.width * 0.5; radiusY: cyanBloom.height * 0.5; direction: PathArc.Clockwise }
                PathArc { x: cyanBloom.width * 0.5; y: 0; radiusX: cyanBloom.width * 0.5; radiusY: cyanBloom.height * 0.5; direction: PathArc.Clockwise }
            }
        }

        // Smaller violet depth pocket, offset to avoid a symmetric cartoon-cloud outline.
        Shape {
            id: violetBloom
            x: parent.width * 0.02 + Math.cos(root.time * 0.14 + 2.2) * 9
            y: parent.height * 0.38 + Math.sin(root.time * 0.12 + 1.1) * 6
            width: parent.width * 0.52
            height: parent.height * 0.38
            rotation: -15 + Math.sin(root.time * 0.18 + 2.0) * 4
            opacity: 0.74
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: root.blurEnabled
                blur: root.blurEnabled ? 0.86 : 0.14
                blurMax: 104
                autoPaddingEnabled: true
            }
            ShapePath {
                strokeColor: "transparent"
                startX: violetBloom.width * 0.5
                startY: 0
                fillGradient: RadialGradient {
                    centerX: violetBloom.width * 0.5
                    centerY: violetBloom.height * 0.5
                    centerRadius: violetBloom.width * 0.60
                    focalX: centerX
                    focalY: centerY
                    GradientStop { position: 0.0; color: Qt.rgba(root.colorC.r, root.colorC.g, root.colorC.b, 0.30) }
                    GradientStop { position: 0.38; color: Qt.rgba(root.colorA.r, root.colorA.g, root.colorA.b, 0.18) }
                    GradientStop { position: 0.76; color: Qt.rgba(root.colorA.r, root.colorA.g, root.colorA.b, 0.06) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                PathArc { x: violetBloom.width * 0.5; y: violetBloom.height; radiusX: violetBloom.width * 0.5; radiusY: violetBloom.height * 0.5; direction: PathArc.Clockwise }
                PathArc { x: violetBloom.width * 0.5; y: 0; radiusX: violetBloom.width * 0.5; radiusY: violetBloom.height * 0.5; direction: PathArc.Clockwise }
            }
        }

        // A faint horizontal haze gives the cloud a floating, atmospheric base.
        Shape {
            id: lowerHaze
            x: parent.width * 0.18
            y: parent.height * 0.55 + Math.sin(root.time * 0.09) * 5
            width: parent.width * 0.66
            height: parent.height * 0.22
            opacity: 0.52
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 0.94
                blurMax: 128
                autoPaddingEnabled: true
            }
            ShapePath {
                strokeColor: "transparent"
                startX: lowerHaze.width * 0.5
                startY: 0
                fillGradient: RadialGradient {
                    centerX: lowerHaze.width * 0.5
                    centerY: lowerHaze.height * 0.5
                    centerRadius: lowerHaze.width * 0.60
                    focalX: centerX
                    focalY: centerY
                    GradientStop { position: 0.0; color: Qt.rgba(root.colorA.r, root.colorA.g, root.colorA.b, 0.20) }
                    GradientStop { position: 0.48; color: Qt.rgba(root.colorB.r, root.colorB.g, root.colorB.b, 0.10) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                PathArc { x: lowerHaze.width * 0.5; y: lowerHaze.height; radiusX: lowerHaze.width * 0.5; radiusY: lowerHaze.height * 0.5; direction: PathArc.Clockwise }
                PathArc { x: lowerHaze.width * 0.5; y: 0; radiusX: lowerHaze.width * 0.5; radiusY: lowerHaze.height * 0.5; direction: PathArc.Clockwise }
            }
        }
    }
}
