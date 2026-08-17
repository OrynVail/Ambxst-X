import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.services
import qs.modules.globals
import qs.config

// The avatar: centrepiece of the notch row. Content is whatever the user points
// ~/.face.icon at, so nothing here assumes anything about the image.
Item {
    id: root

    readonly property int avatarSize: 28

    implicitWidth: avatarSize
    implicitHeight: avatarSize

    readonly property bool hasAvatar: avatar.status === Image.Ready

    scale: mouseArea.containsMouse ? 1.08 : 1.0

    Behavior on scale {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration / 2
            easing.type: Easing.OutCubic
        }
    }

    ClippingRectangle {
        id: avatarClip
        anchors.centerIn: parent
        width: root.avatarSize
        height: root.avatarSize
        radius: width / 2
        color: Colors.surface

        Image {
            id: avatar
            anchors.fill: parent
            // GlobalStates.pickUserAvatar() bumps avatarCacheBuster after copying
            // a new file in; the query string forces a reload
            source: `file://${Quickshell.env("HOME")}/.face.icon` + (GlobalStates.avatarCacheBuster ? `?${GlobalStates.avatarCacheBuster}` : "")
            // Any aspect ratio — crop to the centre of the square
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(root.avatarSize * 3, root.avatarSize * 3)
            smooth: true
            asynchronous: true
            cache: false
        }

        // Fallback when the file is missing or unreadable
        Text {
            anchors.centerIn: parent
            visible: !root.hasAvatar
            text: Icons.user
            font.family: Icons.font
            font.pixelSize: Math.round(root.avatarSize * 0.55)
            color: Colors.overSurfaceVariant
        }
    }

    // Hairline containment edge, so both very dark and very bright avatars still
    // read as a circle against the notch
    Rectangle {
        anchors.fill: avatarClip
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: Colors.overBackground
        opacity: 0.15
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            if (Visibilities.currentActiveModule === "dashboard") {
                Visibilities.setActiveModule("overview");
            } else if (Visibilities.currentActiveModule === "overview") {
                GlobalStates.launcherCurrentTab = 0;
                Visibilities.setActiveModule("launcher");
            } else if (Visibilities.currentActiveModule === "launcher") {
                Visibilities.setActiveModule("");
            } else {
                GlobalStates.dashboardCurrentTab = 0;
                Visibilities.setActiveModule("dashboard");
            }
        }
    }
}
