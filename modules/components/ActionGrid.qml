import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.theme
import qs.modules.components
import qs.config

FocusScope {
    id: root

    property alias actions: repeater.model
    property string layout: "row" // "row" or "grid"
    property int buttonSize: 48
    property int iconSize: 20
    property int spacing: 4
    property int columns: 3
    property int textSpacing: 8

    // Deboxed: no chrome at rest, dimmed idle glyphs, circular tiles
    property bool flat: false

    signal actionTriggered(var action)

    property int currentIndex: 0

    function getNextValidIndex(current, step) {
        let next = current;
        let limit = actions.length;
        for (let i = 0; i < limit; i++) {
            next = (next + step + limit) % limit;
            let action = actions[next];
            let isEnabled = (action.enabled !== undefined ? action.enabled : true);
            if ((!action.type || action.type !== "separator") && isEnabled)
                return next;
        }
        return current;
    }

    implicitWidth: container.implicitWidth
    implicitHeight: container.implicitHeight

    Component.onCompleted: {
        root.forceActiveFocus();
        if (repeater.count > 0) {
            repeater.itemAt(0).forceActiveFocus();
        }
    }

    onActiveFocusChanged: {
        if (activeFocus && repeater.count > 0) {
            Qt.callLater(() => {
                let item = repeater.itemAt(currentIndex);
                if (item)
                    item.forceActiveFocus();
            });
        }
    }

    Keys.onPressed: event => {
        let nextIndex = currentIndex;

        if (layout === "row") {
            if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                nextIndex = getNextValidIndex(currentIndex, 1);
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                nextIndex = getNextValidIndex(currentIndex, -1);
            }
        } else {
            // grid layout
            if (event.key === Qt.Key_Right) {
                nextIndex = Math.min(currentIndex + 1, actions.length - 1);
            } else if (event.key === Qt.Key_Left) {
                nextIndex = Math.max(currentIndex - 1, 0);
            } else if (event.key === Qt.Key_Down) {
                nextIndex = Math.min(currentIndex + columns, actions.length - 1);
            } else if (event.key === Qt.Key_Up) {
                nextIndex = Math.max(currentIndex - columns, 0);
            }
        }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
            if (repeater.itemAt(currentIndex)) {
                repeater.itemAt(currentIndex).triggerAction();
            }
            event.accepted = true;
        } else if (nextIndex !== currentIndex) {
            currentIndex = nextIndex;
            let item = repeater.itemAt(currentIndex);
            if (item)
                item.forceActiveFocus();
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Grid {
            id: container
            anchors.centerIn: parent
            columns: root.layout === "row" ? root.actions.length : root.columns
            rows: root.layout === "row" ? 1 : Math.ceil(root.actions.length / root.columns)
            columnSpacing: root.spacing
            rowSpacing: root.spacing

            Repeater {
                id: repeater

                delegate: Item {
                    id: delegateWrapper
                    readonly property bool isSeparator: (modelData.type === "separator")
                    readonly property int itemIndex: index
                    property var actionModel: modelData

                    implicitWidth: isSeparator ? (root.layout === "row" ? 2 : root.buttonSize) : (root.buttonSize + (hasText ? textMetrics.width + root.textSpacing : 0))
                    implicitHeight: isSeparator ? (root.layout === "row" ? root.buttonSize : 2) : root.buttonSize
                    z: 1

                    readonly property bool hasText: {
                        if (!modelData)
                            return false;
                        if (typeof modelData.text === "string")
                            return modelData.text.length > 0;
                        return false;
                    }

                    TextMetrics {
                        id: textMetrics
                        text: delegateWrapper.hasText ? modelData.text : ""
                        font.family: Config.defaultFont
                        font.pixelSize: root.iconSize * 0.7
                        font.weight: Font.DemiBold
                    }

                    function triggerAction() {
                        if (!isSeparator)
                            actionButton.triggerAction();
                    }

                    Button {
                        id: actionButton
                        anchors.fill: parent
                        visible: !delegateWrapper.isSeparator
                        enabled: !delegateWrapper.isSeparator && (modelData.enabled !== undefined ? modelData.enabled : true)
                        opacity: enabled ? 1.0 : 0.5

                        Process {
                            id: commandProcess
                            command: ["bash", "-c", delegateWrapper.actionModel.command || ""]
                            running: false
                        }

                        function triggerAction() {
                            if (!enabled) return;
                            root.actionTriggered(delegateWrapper.actionModel);
                            if (delegateWrapper.actionModel.command) {
                                commandProcess.running = true;
                            }
                        }

                        background: StyledRect {
                            id: actionBg
                            radius: root.flat && root.layout === "grid" ? height / 2 : Styling.radius(4)
                            variant: {
                                const declared = delegateWrapper.actionModel ? delegateWrapper.actionModel.variant : "";
                                if (declared)
                                    return declared;
                                if (actionButton.pressed)
                                    return "primary";
                                if (actionButton.hovered)
                                    return "focus";
                                // Keyboard cursor lives here, not behind the buttons
                                if (root.activeFocus && delegateWrapper.itemIndex === root.currentIndex)
                                    return "primary";
                                return root.flat ? "transparent" : "internalbg";
                            }
                        }

                        contentItem: Item {
                            anchors.fill: parent

                            // Icon holds the base cell, pinned left
                            Text {
                                width: root.buttonSize
                                height: parent.height
                                anchors.left: parent.left
                                text: modelData.icon || ""
                                textFormat: Text.RichText
                                font.family: Icons.font
                                font.pixelSize: root.iconSize
                                color: actionBg.item
                                opacity: !root.flat || actionButton.hovered || actionButton.pressed ? 1.0 : 0.55
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

                            // Label sits to the right of it
                            Text {
                                visible: delegateWrapper.hasText
                                text: visible ? modelData.text : ""
                                anchors.left: parent.left
                                anchors.leftMargin: root.buttonSize
                                anchors.verticalCenter: parent.verticalCenter

                                font.family: Config.defaultFont
                                font.pixelSize: root.iconSize * 0.7
                                font.weight: Font.DemiBold
                                color: actionBg.item
                                verticalAlignment: Text.AlignVCenter

                                Behavior on color {
                                    enabled: Config.animDuration > 0
                                    ColorAnimation {
                                        duration: Config.animDuration / 2
                                        easing.type: Easing.OutQuart
                                    }
                                }
                            }
                        }

                        onClicked: triggerAction()

                        onHoveredChanged: {
                            if (hovered && actionButton.enabled) {
                                root.currentIndex = index;
                            }
                        }

                        onActiveFocusChanged: {
                            if (activeFocus) {
                                root.currentIndex = index;
                            }
                        }

                        StyledToolTip {
                            visible: parent.hovered
                            tooltipText: modelData.tooltip || ""
                            delay: 500
                        }
                    }

                    Item {
                        anchors.fill: parent
                        visible: delegateWrapper.isSeparator
                        Separator {
                            anchors.centerIn: parent
                            vert: root.layout === "row"
                        }
                    }
                }
            }
        }
    }
}
