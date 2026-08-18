import QtQuick
import qs.modules.widgets.dashboard
import qs.modules.services
import qs.modules.theme

Item {
    // Every dimension is derived, not chosen. Columns are as wide as their
    // contents need: the media column fits the player disc, the calendar
    // exactly seven day cells, and notifications takes the remainder.
    readonly property int mediaColumn: 216
    // The calendar was grown to fill the body height; keeping its aspect meant
    // widening it by the same 17%, and that width comes out of notifications so
    // the player and the divider after it do not move.
    readonly property int calendarColumn: 263
    readonly property int notificationColumn: 280

    // The one hard number every column is measured against: FullPlayer's own
    // implicitHeight of 400, less 10%. The card centres content that runs to
    // roughly 290, so it still has clearance and is never the thing squeezed.
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
