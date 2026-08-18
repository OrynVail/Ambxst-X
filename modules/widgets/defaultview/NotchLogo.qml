import QtQuick
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.config

// Centrepiece of the notch row: the shell logo. Falls back to the bundled
// floki mark when no custom icon is set. Tint options let it follow the
// generated colour scheme instead of shipping as a fixed-colour image.
ToggleButton {
    id: root

    readonly property int logoSize: Config.notch?.logoSize ?? 23

    buttonIcon: (Config.notch?.logoIcon || "") !== "" ? Config.notch.logoIcon : Qt.resolvedUrl("../../../assets/floki/floki-bolt.svg").toString().replace("file://", "")
    iconTint: Config.notch?.logoTint ?? false
    iconFullTint: Config.notch?.logoFullTint ?? false
    iconSize: logoSize

    // Sits flat in the notch like the rest of the row: no background, grows on hover
    flat: true
    enableShadow: false
    tooltipText: "Dashboard"

    implicitWidth: logoSize + 8
    implicitHeight: logoSize + 8

    // Same cycle the avatar used to drive
    onToggle: function () {
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
