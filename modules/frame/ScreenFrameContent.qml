import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.modules.components
import qs.modules.corners
import qs.modules.services
import qs.modules.theme
import qs.config
import qs.modules.globals

Item {
    id: root

    required property ShellScreen targetScreen
    property bool hasFullscreenWindow: false

    // State source: Singletons and Registry
    readonly property bool frameEnabled: Config.frame?.enabled ?? false
    readonly property string notchPos: Config.notchPosition ?? "top"
    
    readonly property var barPanel: Visibilities.barPanels[targetScreen.name]
    readonly property var dockPanel: Visibilities.dockPanels[targetScreen.name]
    
    // Effective Reveal States
    readonly property bool dockReveal: dockPanel ? dockPanel.reveal : true
    readonly property bool notchReveal: barPanel ? barPanel.notchReveal : true

    // Hover States for Restoration Logic
    readonly property bool notchHovered: barPanel ? (barPanel.notchHoverActive || barPanel.notchOpen) : false
    readonly property bool dockHovered: dockPanel ? (dockPanel.reveal && (dockPanel.activeWindowFullscreen || dockPanel.keepHidden || !dockPanel.pinned)) : false

    readonly property real baseThickness: {
        const base = Config.frame?.thickness ?? 6;
        return Math.max(0, Math.min(Math.round(base), 40));
    }

    // --- Animation Synchronization ---
    
    property real _dockAnimProgress: dockReveal ? 1.0 : 0.0
    Behavior on _dockAnimProgress {
        enabled: Config.animDuration > 0
        NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutCubic }
    }

    property real _notchAnimProgress: notchReveal ? 1.0 : 0.0
    Behavior on _notchAnimProgress {
        enabled: Config.animDuration > 0
        NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutCubic }
    }

    // --- Side-Specific Thickness Restoration ---

    readonly property int topThickness: calculateSideThickness("top")
    readonly property int bottomThickness: calculateSideThickness("bottom")
    readonly property int leftThickness: calculateSideThickness("left")
    readonly property int rightThickness: calculateSideThickness("right")

    function calculateSideThickness(side) {
        let t = baseThickness;
        if (hasFullscreenWindow) {
            let restore = false;
            let progress = 0.0;

            if (notchPos === side && notchHovered) { restore = true; progress = Math.max(progress, _notchAnimProgress); }
            if (dockPanel && dockPanel.position === side && dockHovered) { restore = true; progress = Math.max(progress, _dockAnimProgress); }
            
            t = restore ? (baseThickness * progress) : 0;
        }
        
        return Math.round(t);
    }

    // --- Corner Logic ---
    
    readonly property real targetInnerRadius: {
        if (!root.hasFullscreenWindow) return Styling.radius(4);
        if (!notchHovered && !dockHovered) return 0;

        let progress = Math.max(_dockAnimProgress, _notchAnimProgress);
        return Styling.radius(4) * progress;
    }
    
    property real innerRadius: targetInnerRadius

    // --- Visuals ---

    StyledRect {
        id: frameFill
        anchors.fill: parent
        variant: "bg"
        radius: 0
        enableBorder: false
        visible: root.frameEnabled
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: frameMask
            maskInverted: true
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }

    Item {
        id: frameMask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            id: maskRect
            x: root.leftThickness
            y: root.topThickness
            width: parent.width - (root.leftThickness + root.rightThickness)
            height: parent.height - (root.topThickness + root.bottomThickness)
            radius: root.innerRadius
            color: "white"
            visible: width > 0 && height > 0
        }
    }
}
