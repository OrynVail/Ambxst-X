import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.modules.globals
import qs.config

StyledRect {
    id: player
    variant: "transparent"

    property real playerRadius: Config.roundness > 0 ? Config.roundness + 4 : 0
    property bool playersListExpanded: false

    visible: true
    radius: playerRadius

    // Content-driven, with room to breathe now that the profile row is gone
    implicitHeight: content.implicitHeight + 56

    readonly property bool isDragging: seekBar.isDragging

    property bool isPlaying: MprisController.activePlayer?.playbackState === MprisPlaybackState.Playing
    property real position: MprisController.activePlayer?.position ?? 0.0
    property real length: MprisController.activePlayer?.length ?? 1.0
    property bool hasArtwork: (MprisController.activePlayer?.trackArtUrl ?? "") !== ""
    property string wallpaperPath: {
        if (!GlobalStates.wallpaperManager) return "";
        let path = GlobalStates.wallpaperManager.currentWallpaper;
        let frame = GlobalStates.wallpaperManager.getLockscreenFramePath(path);
        return frame ? "file://" + frame : "";
    }
    property bool hasActivePlayer: MprisController.activePlayer !== null
    property bool isSeeking: false

    Timer {
        id: seekUnlockTimer
        interval: 1000
        repeat: false
        onTriggered: player.isSeeking = false
    }

    function formatTime(seconds) {
        const totalSeconds = Math.floor(seconds);
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const secs = totalSeconds % 60;

        if (hours > 0) {
            return hours + ":" + (minutes < 10 ? "0" : "") + minutes + ":" + (secs < 10 ? "0" : "") + secs;
        } else {
            return minutes + ":" + (secs < 10 ? "0" : "") + secs;
        }
    }

    // Function to sync seekBar with current media position
    function syncSeekBarPosition() {
        if (!seekBar.isDragging && !player.isSeeking) {
            if (player.hasActivePlayer) {
                seekBar.value = player.length > 0 ? player.position / player.length : 0;
            } else {
                seekBar.value = 0;
            }
        }
    }

    Timer {
        running: player.isPlaying && player.visible
        interval: 1000
        repeat: true
        onTriggered: {
            syncSeekBarPosition();
            MprisController.activePlayer?.positionChanged();
        }
    }

    Connections {
        target: MprisController.activePlayer
        function onPositionChanged() {
            syncSeekBarPosition();
        }
    }

    Component.onCompleted: {
        syncSeekBarPosition();
    }

    Connections {
        target: MprisController
        function onActivePlayerChanged() {
            Qt.callLater(syncSeekBarPosition);
        }
    }

    Connections {
        target: GlobalStates
        function onDashboardOpenChanged() {
            if (GlobalStates.dashboardOpen) {
                Qt.callLater(syncSeekBarPosition);
            }
        }
    }

    // Background with blur effect

    Image {
        mipmap: true
        id: backgroundArtBlurred
        anchors.fill: parent
        source: (MprisController.activePlayer?.trackArtUrl ?? "") !== "" ? MprisController.activePlayer.trackArtUrl : player.wallpaperPath
        sourceSize: Qt.size(64, 64)
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
    }

    MultiEffect {
        id: blurredEffect
        anchors.fill: parent
        source: backgroundArtBlurred
        blurEnabled: true
        blurMax: 32
        blur: 1.0
        opacity: (player.hasArtwork || player.wallpaperPath !== "") ? 0.25 : 0.0
        visible: player.hasArtwork || player.wallpaperPath !== ""
        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutQuart
            }
        }
    }

    Image {
        mipmap: true
        id: backgroundArtFull
        anchors.fill: parent
        source: (MprisController.activePlayer?.trackArtUrl ?? "") !== "" ? MprisController.activePlayer.trackArtUrl : player.wallpaperPath
        fillMode: Image.PreserveAspectCrop
        visible: false
        asynchronous: true
    }

    MultiEffect {
        id: fullArtEffect
        anchors.fill: parent
        source: backgroundArtFull
        maskEnabled: true
        maskSource: innerAreaMask
        maskInverted: true
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
        opacity: (player.hasArtwork || player.wallpaperPath !== "") ? 1.0 : 0.0
        visible: player.hasArtwork || player.wallpaperPath !== ""
        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutQuart
            }
        }
    }

    Item {
        id: innerAreaMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            x: 4
            y: 4
            width: parent.width - 8
            height: parent.height - 8
            radius: player.radius - 4
            color: "white"
        }
    }

    // Playback Controls

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 8

        // Title only — album/artist/duration dropped to keep the card compact
        Text {
            Layout.fillWidth: true
            text: player.hasActivePlayer ? (MprisController.activePlayer?.trackTitle ?? "") : "Nothing Playing"
            color: Colors.overBackground
            font.pixelSize: Config.theme.fontSize
            font.weight: Font.Bold
            font.family: Config.theme.font
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        // Flat seek bar (replaces the circular ring)
        PositionSlider {
            id: seekBar
            player: MprisController.activePlayer
            wavy: false
            Layout.fillWidth: true
            Layout.preferredHeight: 8
            Layout.topMargin: 2
            Layout.bottomMargin: 2
            opacity: MprisController.activePlayer !== null ? 1.0 : 0.4
        }


        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

        // Player Selector
        MediaIconButton {
            icon: player.getPlayerIcon(MprisController.activePlayer)
            opacity: player.hasActivePlayer ? 1.0 : 0.5
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) {
                    MprisController.cyclePlayer(1);
                } else if (mouse.button === Qt.RightButton) {
                    player.playersListExpanded = !player.playersListExpanded;
                }
            }
        }

        // Previous
        MediaIconButton {
            icon: Icons.previous
            enabled: MprisController.canGoPrevious
            opacity: player.hasActivePlayer ? (enabled ? 1.0 : 0.3) : 0.5
            onClicked: MprisController.previous()
        }

        // Play/Pause
        StyledRect {
            id: playPauseBtn
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            variant: "primary"
            opacity: player.hasActivePlayer ? 1.0 : 0.5

            animateRadius: false
            radius: Styling.radius(16)

            states: [
                State {
                    name: "playing"
                    when: player.isPlaying && player.hasActivePlayer
                    PropertyChanges {
                        target: playPauseBtn
                        radius: Styling.radius(0)
                    }
                },
                State {
                    name: "paused"
                    when: (!player.isPlaying || !player.hasActivePlayer)
                    PropertyChanges {
                        target: playPauseBtn
                        radius: Styling.radius(16)
                    }
                }
            ]

            transitions: Transition {
                NumberAnimation {
                    properties: "radius"
                    duration: 300
                    easing.type: Easing.OutBack
                }
            }

            Text {
                anchors.centerIn: parent
                text: !player.hasActivePlayer ? Icons.stop : (player.isPlaying ? Icons.pause : Icons.play)
                font.family: Icons.font
                font.pixelSize: 22
                color: playPauseBtn.item
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: player.hasActivePlayer
                onClicked: MprisController.togglePlaying()
            }
        }

        // Next
        MediaIconButton {
            icon: Icons.next
            enabled: MprisController.canGoNext
            opacity: player.hasActivePlayer ? (enabled ? 1.0 : 0.3) : 0.5
            onClicked: MprisController.next()
        }

        // Mode
        MediaIconButton {
            icon: {
                if (MprisController.hasShuffle)
                    return Icons.shuffle;
                if (MprisController.loopState === MprisLoopState.Track)
                    return Icons.repeatOnce;
                if (MprisController.loopState === MprisLoopState.Playlist)
                    return Icons.repeat;
                return Icons.shuffle;
            }
            opacity: player.hasActivePlayer ? ((MprisController.shuffleSupported || MprisController.loopSupported) ? 1.0 : 0.3) : 0.5
            onClicked: {
                if (MprisController.hasShuffle) {
                    MprisController.setShuffle(false);
                    MprisController.setLoopState(MprisLoopState.Playlist);
                } else if (MprisController.loopState === MprisLoopState.Playlist) {
                    MprisController.setLoopState(MprisLoopState.Track);
                } else if (MprisController.loopState === MprisLoopState.Track) {
                    MprisController.setLoopState(MprisLoopState.None);
                } else {
                    MprisController.setShuffle(true);
                }
            }
            }
        }

    }

    // Players List Overlay
    Item {
        id: overlayLayer
        anchors.fill: parent
        visible: player.playersListExpanded
        z: 100

        // Scrim
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.4
            radius: player.radius

            MouseArea {
                anchors.fill: parent
                onClicked: player.playersListExpanded = false
            }
        }

        // List Container
        StyledRect {
            id: playersListContainer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 4
            implicitHeight: Math.min(160, playersListView.contentHeight + 8)
            variant: "pane"
            radius: player.radius - 4

            ListView {
                id: playersListView
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                model: MprisController.filteredPlayers

                delegate: StyledRect {
                    id: playerItem
                    required property var modelData
                    required property int index

                    width: playersListView.width
                    height: 40
                    variant: delegateMouseArea.containsMouse ? "focus" : "transparent"
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Text {
                            text: player.getPlayerIcon(modelData)
                            font.family: Icons.font
                            font.pixelSize: 18
                            color: Colors.overBackground
                        }

                        Text {
                            Layout.fillWidth: true
                            text: (modelData?.trackTitle || modelData?.identity || "Unknown Player")
                            color: Colors.overBackground
                            font.family: Config.theme.font
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: delegateMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            MprisController.setActivePlayer(modelData);
                            player.playersListExpanded = false;
                        }
                    }
                }
            }
        }
    }

    // Internal component for small buttons
    component MediaIconButton: Text {
        property string icon: ""
        signal clicked(var mouse)

        text: icon
        font.family: Icons.font
        font.pixelSize: 20
        color: mouseArea.containsMouse ? Colors.primary : Colors.overBackground

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => parent.clicked(mouse)
        }
    }

    function getPlayerIcon(player) {
        if (!player)
            return Icons.player;
        const dbusName = (player.dbusName || "").toLowerCase();
        const desktopEntry = (player.desktopEntry || "").toLowerCase();
        const identity = (player.identity || "").toLowerCase();

        if (dbusName.includes("spotify") || desktopEntry.includes("spotify") || identity.includes("spotify"))
            return Icons.spotify;
        if (dbusName.includes("chromium") || dbusName.includes("chrome") || desktopEntry.includes("chromium") || desktopEntry.includes("chrome"))
            return Icons.chromium;
        if (dbusName.includes("firefox") || desktopEntry.includes("firefox"))
            return Icons.firefox;
        if (dbusName.includes("telegram") || desktopEntry.includes("telegram") || identity.includes("telegram"))
            return Icons.telegram;
        return Icons.player;
    }
}
