import QtQuick
import qs.modules.widgets.dashboard
import qs.modules.services
import qs.modules.theme

Item {
    // Every dimension is derived here, not chosen downstream.
    readonly property int mediaColumn: 216
    // Calendar keeps its aspect; the extra width comes out of notifications so
    // the player and its divider stay put
    readonly property int calendarColumn: 263
    readonly property int notificationColumn: 280

    // The one hard number. FullPlayer's implicitHeight of 400, trimmed; its
    // content runs to ~290 so the player is never what gets squeezed.
    readonly property int bodyHeight: 340

    // gutter + separator + gutter between each pair of columns
    implicitWidth: Styling.gutter * 2 + mediaColumn + (Styling.gutter * 2 + 2) * 2 + calendarColumn + notificationColumn
    // pad + band + gap + sep + gap + body + gap + sep + gap + band + pad
    implicitHeight: Styling.gutter * 2 + Styling.control * 2 + Styling.tight * 4 + 2 * 2 + bodyHeight

    readonly property int leftPanelWidth: 270

    Dashboard {
        id: dashboardItem
        anchors.fill: parent
        leftPanelWidth: parent.leftPanelWidth

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                Visibilities.setActiveModule("");
                event.accepted = true;
            } else if (event.key === Qt.Key_Space) {
                event.accepted = false;
            }
        }

        Component.onCompleted: {
            Qt.callLater(() => {
                forceActiveFocus();
            });
        }
    }
}
