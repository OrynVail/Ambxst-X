import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.modules.theme
import qs.modules.components
import qs.config

Item {
    id: root

    Layout.fillHeight: true

    required property var player

    onPlayerChanged: {
        if (!player) {
            value = 0;
        }
    }

    property bool isPlaying: player?.playbackState === MprisPlaybackState.Playing
    property real position: player?.position ?? 0.0
    property real length: player?.length ?? 1.0

    property alias value: slider.value
    property alias isDragging: slider.isDragging

    // Opt out of the wavy progress line (flat bar instead)
    property bool wavy: true

    // Propiedades opcionales para sobrescribir colores
    property color customProgressColor: Styling.srItem("overprimary")
    property color customBackgroundColor: Colors.shadow
    property bool useCustomColors: false

    StyledSlider {
        id: slider
        anchors.fill: parent

        value: root.length > 0 ? Math.min(1.0, root.position / root.length) : 0
        progressColor: root.useCustomColors ? root.customProgressColor : Styling.srItem("overprimary")
        backgroundColor: root.useCustomColors ? root.customBackgroundColor : Colors.shadow
        wavy: root.wavy // CarouselProgress logic, unless opted out
        playing: root.isPlaying // Control animation state via playing property
        wavyAmplitude: (root.wavy && root.isPlaying) ? 1 : 0.0
        wavyFrequency: (root.wavy && root.isPlaying) ? 8 : 0
        heightMultiplier: root.player ? 8 : 4
        smoothDrag: true
        scroll: false
        tooltip: false
        updateOnRelease: true

        onValueChanged: {
            if (isDragging && root.player && root.player.canSeek) {
                root.player.position = value * root.length;
            }
        }
    }
}
