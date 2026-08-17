pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.bar
import qs.modules.bar.systray
import qs.modules.components
import qs.modules.globals
import qs.modules.theme
import qs.config

// The system tray, rehomed from the bar.
StyledRect {
    id: root
    variant: "pane"
    radius: Styling.radius(4)

    implicitHeight: column.implicitHeight + 16

    // SysTray only reads bar.orientation
    QtObject {
        id: barStub
        property string orientation: "horizontal"
        property string barPosition: "top"
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // System tray — the one bar widget with nowhere else to go.
        // Wrapped so SysTray's `height: parent.height` resolves against a plain
        // Item instead of fighting the ColumnLayout.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: tray.visible ? tray.implicitHeight : 0
            visible: tray.visible

            SysTray {
                id: tray
                bar: barStub
                anchors.left: parent.left
                anchors.right: parent.right
                radius: Styling.radius(0)
            }
        }
    }
}
