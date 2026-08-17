import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.services
import qs.modules.notch
import qs.modules.components
import qs.modules.bar
import qs.modules.bar.clock
import qs.config

Item {
    id: root
    anchors.top: parent.top
    focus: false

    required property var screen

    // Layout constants
    readonly property int notificationPadding: 16
    readonly property int notificationPaddingBottom: Config.notchTheme === "island" ? 20 : 16
    readonly property int notificationPaddingTop: 8

    // State
    readonly property bool hasActiveNotifications: Notifications.popupList.length > 0
    property bool notchHovered: false
    property bool parentHoverActive: false
    property bool isNavigating: false

    // Position detection
    readonly property string notchPosition: Config.notchPosition ?? "top"
    readonly property bool isBottom: notchPosition === "bottom"

    HoverHandler {
        id: contentHoverHandler
    }

    readonly property bool expandedState: contentHoverHandler.hovered || notchHovered || parentHoverActive || isNavigating

    // Keep the notch revealed while one of its own popups is open — otherwise it
    // auto-hides the moment the pointer leaves the notch to reach the popup.
    readonly property bool childPopupOpen: clockWidget.popupOpen || batteryWidget.popupOpen
    onChildPopupOpenChanged: Visibilities.notchPopupOpen = childPopupOpen

    // Clock and BatteryIndicator were written for the bar; they only read
    // orientation, plus barPosition for popup direction.
    QtObject {
        id: notchBarStub
        property string orientation: "horizontal"
        property string barPosition: root.notchPosition
    }

    property real mainRowMargin: 16

    Behavior on mainRowMargin {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }

    // Clear space either side of the avatar, so it reads as surrounded rather
    // than as one more item in a list
    readonly property int moat: 16

    // Both flanks reserve the same width, which is what pins the avatar to the
    // notch's true centre — it cannot drift as workspaces come and go. The
    // lighter flank's spare room is invisible inside a solid notch.
    readonly property real flankWidth: Math.max(leftFlank.implicitWidth, rightFlank.implicitWidth)
    readonly property real rowContentWidth: userInfo.implicitWidth + moat * 2 + flankWidth * 2

    // Computed dimensions — width now follows the row's real content
    readonly property real mainRowContentWidth: rowContentWidth + mainRowMargin * 2
    // Sized to the tallest element (28px avatar, ~30px hover-scaled) rather than
    // the 36px bar buttons this row used to hold
    readonly property real mainRowHeight: 36
    readonly property real notificationMinWidth: expandedState ? 420 : 320
    readonly property real notificationContainerHeight: notificationView.implicitHeight + notificationPaddingTop + notificationPaddingBottom

    implicitWidth: Math.round(hasActiveNotifications ? Math.max(notificationMinWidth + (notificationPadding * 2), mainRowContentWidth) : mainRowContentWidth)

    implicitHeight: hasActiveNotifications ? mainRowHeight + notificationContainerHeight : mainRowHeight

    Behavior on implicitWidth {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.2
        }
    }

    Item {
        anchors.fill: parent

        // mainRow container: left flank | avatar | right flank.
        // state on the left, you in the middle, actions on the right.
        Item {
            id: mainRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: root.isBottom ? undefined : parent.top
            anchors.bottom: root.isBottom ? parent.bottom : undefined
            width: root.rowContentWidth
            height: root.mainRowHeight
            z: 2 // Stay above notifications if they ever overlap

            UserInfo {
                id: userInfo
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
            }

            RowLayout {
                id: leftFlank
                anchors.right: userInfo.left
                anchors.rightMargin: root.moat
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                NotchWorkspaces {
                    id: workspaces
                    screen: root.screen
                    Layout.alignment: Qt.AlignVCenter
                }

                Clock {
                    id: clockWidget
                    bar: notchBarStub
                    flat: true
                    layerEnabled: false
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            RowLayout {
                id: rightFlank
                anchors.left: userInfo.right
                anchors.leftMargin: root.moat
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                ToolsButton {
                    flat: true
                    enableShadow: false
                    Layout.alignment: Qt.AlignVCenter
                }

                BatteryIndicator {
                    id: batteryWidget
                    bar: notchBarStub
                    flat: true
                    layerEnabled: false
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // Notification container with its own padding
        Item {
            id: notificationContainer
            width: parent.width
            height: root.hasActiveNotifications ? root.notificationContainerHeight : 0
            visible: root.hasActiveNotifications

            anchors.top: root.isBottom ? undefined : mainRow.bottom
            anchors.bottom: root.isBottom ? mainRow.top : undefined

            NotchNotificationView {
                id: notificationView
                anchors.fill: parent
                anchors.topMargin: root.notificationPaddingTop
                anchors.leftMargin: root.notificationPadding
                anchors.rightMargin: root.notificationPadding
                anchors.bottomMargin: root.notificationPaddingBottom
                visible: root.hasActiveNotifications
                opacity: visible ? 1 : 0
                notchHovered: root.expandedState
                onIsNavigatingChanged: root.isNavigating = isNavigating

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }
        }
    }
}
