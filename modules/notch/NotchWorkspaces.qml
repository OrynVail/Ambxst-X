pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.bar.workspaces
import qs.modules.services
import qs.modules.theme
import qs.config

// Workspace indicator for the notch idle row.
// Only occupied workspaces (plus the active one) take up space. Slots are never
// created or destroyed — empty ones collapse to zero width so the row animates
// instead of popping items in and out.
Item {
    id: root

    required property var screen

    readonly property int slotCount: Math.max(1, Config.workspaces.shown)
    readonly property int dotWidth: 5
    readonly property int capsuleWidth: 20
    readonly property int gap: 5
    readonly property int rowHeight: 10

    readonly property var monitor: AxctlService.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
    readonly property int group: Math.floor((activeId - 1) / slotCount)

    function workspaceId(index) {
        return root.group * root.slotCount + index + 1;
    }

    // Trailing gap trimmed so the row stays optically centred
    implicitWidth: Math.max(0, slotRow.implicitWidth - gap)
    implicitHeight: rowHeight

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (event.angleDelta.y < 0)
                AxctlService.dispatch(`workspace r+1`);
            else if (event.angleDelta.y > 0)
                AxctlService.dispatch(`workspace r-1`);
        }
    }

    Row {
        id: slotRow
        anchors.centerIn: parent
        // Gap lives inside each slot, so collapsed slots leave no phantom space
        spacing: 0

        Repeater {
            model: root.slotCount

            Item {
                id: slot
                required property int index

                readonly property int wsId: root.workspaceId(index)
                readonly property bool isActive: wsId === root.activeId
                readonly property bool isOccupied: CompositorData.workspaceOccupationMap[wsId] ?? false
                readonly property bool shown: isActive || isOccupied

                readonly property int bodyWidth: isActive ? root.capsuleWidth : root.dotWidth

                width: shown ? bodyWidth + root.gap : 0
                height: root.rowHeight
                opacity: shown ? 1 : 0

                Behavior on width {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.1
                    }
                }

                Behavior on opacity {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration / 2
                        easing.type: Easing.OutCubic
                    }
                }

                Item {
                    id: body
                    width: slot.bodyWidth
                    height: root.rowHeight
                    // Centred within the slot, ignoring the trailing gap
                    x: (slot.width - root.gap - width) / 2
                    clip: true

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: slot.isActive ? root.rowHeight : root.dotWidth
                        radius: height / 2
                        // State is carried by shape alone — the accent is reserved
                        // for interaction (hover / open popup) elsewhere in the row
                        color: Colors.overBackground
                        opacity: slot.isActive ? 0.85 : 0.35

                        Behavior on height {
                            enabled: Config.animDuration > 0
                            NumberAnimation {
                                duration: Config.animDuration
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.1
                            }
                        }
                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration / 2
                            }
                        }
                        Behavior on opacity {
                            enabled: Config.animDuration > 0
                            NumberAnimation {
                                duration: Config.animDuration / 2
                            }
                        }
                    }

                }

                MouseArea {
                    width: body.width
                    height: parent.height
                    x: body.x
                    enabled: slot.shown
                    cursorShape: Qt.PointingHandCursor
                    onPressed: AxctlService.dispatch(`workspace ${slot.wsId}`)
                }
            }
        }
    }
}
