import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.config

StyledRect {
    id: root

    required property bool isActive
    required property string iconName
    required property string tooltipText
    signal clicked
    signal rightClicked
    signal longPressed

    property bool isHovered: mouseArea.containsMouse

    // The cell stays 48 for hit area and rhythm; the chip that actually gets
    // painted is smaller, so a row with most toggles on doesn't turn into a
    // wall of discs. State is fill — the radius never changes.
    variant: "transparent"

    StyledRect {
        id: chip
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) - 8
        height: width
        radius: height / 2

        variant: {
            if (root.isActive && root.isHovered)
                return "primaryfocus";
            if (root.isActive)
                return "primary";
            if (root.isHovered)
                return "focus";
            return "transparent";
        }

        Text {
            anchors.centerIn: parent
            text: root.iconName
            color: chip.item
            opacity: root.isActive || root.isHovered ? 1.0 : 0.55
            font.family: Icons.font
            // Proportional to the chip rather than the Styling.glyph token, so
            // the glyph grows when the row is sized to a column instead of to
            // the standard control
            font.pixelSize: Math.round(chip.height * 0.55)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: Config.animDuration / 2
                    easing.type: Easing.OutQuart
                }
            }

            Behavior on color {
                enabled: Config.animDuration > 0
                ColorAnimation {
                    duration: Config.animDuration / 2
                    easing.type: Easing.OutQuart
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        pressAndHoldInterval: 1000
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.rightClicked();
            } else {
                root.clicked();
            }
        }
        onPressAndHold: root.longPressed()

        StyledToolTip {
            visible: mouseArea.containsMouse
            tooltipText: root.tooltipText
        }
    }
}
