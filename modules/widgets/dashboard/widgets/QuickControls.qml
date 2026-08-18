import QtQuick
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config
import "../controls"

// Toggle row that sits above the calendar.
//
// Only the button row participates in layout. The Wi-Fi/Bluetooth drawer hangs
// below the row at an explicit size, so expanding it covers the calendar rather
// than growing the column and shoving everything down.
Item {
    id: root

    property int expandedPanel: -1 // -1: none, 0: wifi, 1: bluetooth
    property int buttonSize: 40
    property int spacing: 4

    // Set by the caller so the drawer matches the column it hangs over
    property int panelWidth: 300

    implicitWidth: buttonRow.implicitWidth
    implicitHeight: buttonSize

    onVisibleChanged: {
        if (!visible) {
            root.expandedPanel = -1;
        } else {
            BluetoothService.initialize();
        }
    }

    function togglePanel(index) {
        root.expandedPanel = root.expandedPanel === index ? -1 : index;
    }

    Item {
        id: panelArea
        width: root.panelWidth
        height: root.expandedPanel !== -1 ? 260 : 0
        y: root.buttonSize + Styling.tight
        z: 100
        clip: true
        visible: height > 0
        opacity: root.expandedPanel !== -1 ? 1 : 0

        Behavior on height {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutQuart
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutQuart
            }
        }

        // A drawer that floats over the dashboard is the one thing here that
        // still earns a surface of its own.
        StyledRect {
            variant: "pane"
            anchors.fill: parent
            radius: Styling.radius(4)
            clip: true

            Item {
                id: panelStack
                anchors.fill: parent
                anchors.margins: 8

                Loader {
                    id: wifiLoader
                    anchors.fill: parent
                    active: root.expandedPanel === 0
                    source: "../controls/WifiPanel.qml"
                    asynchronous: true

                    opacity: root.expandedPanel === 0 ? 1 : 0
                    x: root.expandedPanel === 0 ? 0 : (root.expandedPanel === 1 ? -width : width)

                    onLoaded: {
                        if (item) {
                            item.maxContentWidth = width;
                        }
                    }

                    Behavior on opacity { enabled: Config.animDuration > 0; NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart } }
                    Behavior on x { enabled: Config.animDuration > 0; NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart } }
                }

                Loader {
                    id: bluetoothLoader
                    anchors.fill: parent
                    active: root.expandedPanel === 1
                    source: "../controls/BluetoothPanel.qml"
                    asynchronous: true

                    opacity: root.expandedPanel === 1 ? 1 : 0
                    x: root.expandedPanel === 1 ? 0 : (root.expandedPanel === 0 ? width : -width)

                    onLoaded: {
                        if (item) {
                            item.maxContentWidth = width;
                        }
                    }

                    Behavior on opacity { enabled: Config.animDuration > 0; NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart } }
                    Behavior on x { enabled: Config.animDuration > 0; NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart } }
                }
            }
        }
    }

    RowLayout {
        id: buttonRow
        anchors.fill: parent
        spacing: root.spacing

        ControlButton {
            Layout.fillWidth: true
            Layout.preferredWidth: root.buttonSize
            Layout.preferredHeight: root.buttonSize
            iconName: {
                if (!NetworkService.wifiEnabled)
                    return Icons.wifiOff;
                const strength = NetworkService.networkStrength;
                if (strength === 0)
                    return Icons.wifiHigh;
                if (strength < 25)
                    return Icons.wifiNone;
                if (strength < 50)
                    return Icons.wifiLow;
                if (strength < 75)
                    return Icons.wifiMedium;
                return Icons.wifiHigh;
            }
            isActive: NetworkService.wifiEnabled || root.expandedPanel === 0
            tooltipText: NetworkService.wifiEnabled ? "Wi-Fi: On" : "Wi-Fi: Off"
            onClicked: NetworkService.toggleWifi()
            onRightClicked: root.togglePanel(0)
            onLongPressed: root.togglePanel(0)
        }

        ControlButton {
            Layout.fillWidth: true
            Layout.preferredWidth: root.buttonSize
            Layout.preferredHeight: root.buttonSize
            iconName: {
                if (!BluetoothService.enabled)
                    return Icons.bluetoothOff;
                if (BluetoothService.connected)
                    return Icons.bluetoothConnected;
                return Icons.bluetooth;
            }
            isActive: BluetoothService.enabled || root.expandedPanel === 1
            tooltipText: {
                if (!BluetoothService.enabled)
                    return "Bluetooth: Off";
                if (BluetoothService.connected)
                    return "Bluetooth: Connected";
                return "Bluetooth: On";
            }
            onClicked: BluetoothService.toggle()
            onRightClicked: root.togglePanel(1)
            onLongPressed: root.togglePanel(1)
        }

        ControlButton {
            Layout.fillWidth: true
            Layout.preferredWidth: root.buttonSize
            Layout.preferredHeight: root.buttonSize
            iconName: Icons.nightLight
            isActive: NightLightService.active
            tooltipText: NightLightService.active ? "Night Light: On" : "Night Light: Off"
            onClicked: NightLightService.toggle()
        }

        ControlButton {
            Layout.fillWidth: true
            Layout.preferredWidth: root.buttonSize
            Layout.preferredHeight: root.buttonSize
            iconName: Icons.caffeine
            isActive: CaffeineService.inhibit
            tooltipText: CaffeineService.inhibit ? "Caffeine: On" : "Caffeine: Off"
            onClicked: CaffeineService.toggleInhibit()
        }

        ControlButton {
            Layout.fillWidth: true
            Layout.preferredWidth: root.buttonSize
            Layout.preferredHeight: root.buttonSize
            iconName: Icons.gameMode
            isActive: GameModeService.toggled
            tooltipText: GameModeService.toggled ? "Game Mode: On" : "Game Mode: Off"
            onClicked: GameModeService.toggle()
        }
    }
}
