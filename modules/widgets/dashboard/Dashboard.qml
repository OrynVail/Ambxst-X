import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.bar
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.modules.notch
import qs.modules.widgets.dashboard.widgets
import qs.modules.widgets.dashboard.controls
import qs.modules.widgets.dashboard.wallpapers
import qs.modules.widgets.dashboard.metrics
import qs.config

NotchAnimationBehavior {
    id: root

    property int leftPanelWidth

    property var state: QtObject {
        property int currentTab: GlobalStates.dashboardCurrentTab
    }

    readonly property var tabModel: [Icons.widgets, Icons.wallpapers, Icons.heartbeat]
    readonly property int tabCount: tabModel.length
    readonly property int tabSpacing: 8
    readonly property int pad: Styling.gutter

    readonly property int tabWidth: Styling.control
    readonly property real nonAnimWidth: (state.currentTab === 0 ? 600 : 400) + 16 // unified launcher tab is wider; nav no longer takes width

    implicitWidth: nonAnimWidth
    implicitHeight: 430

    // Track which tabs have been loaded (for lazy loading)
    property var loadedTabs: ({0: true}) // Tab 0 (widgets) loaded by default

    // LRU Tab Management
    property var lruAccessOrder: [0]  // Tracks access order: [0] means tab 0 is most recent
    property var lruTabsLoaded: ({0: true})  // Reflects which tabs are actually loaded

    // Update LRU on tab access
    function updateLRUAccess(tabIndex) {
        // Remove if already in list
        const idx = lruAccessOrder.indexOf(tabIndex);
        if (idx !== -1) {
            lruAccessOrder.splice(idx, 1);
        }
        // Add to end (most recent)
        lruAccessOrder.push(tabIndex);
        updateLoadedTabs();
    }

    // Determine which tabs should be loaded based on LRU and config
    function updateLoadedTabs() {
        let newLoadedTabs = {};
        
        // Always load tab 0 (WidgetsTab) to avoid "jumpy" opening
        newLoadedTabs[0] = true;
        
        // Always load current tab
        newLoadedTabs[root.state.currentTab] = true;

        if (Config.performance.dashboardPersistTabs) {
            // Load up to maxPersistentTabs most recent tabs
            const maxTabs = Math.max(1, Config.performance.dashboardMaxPersistentTabs);
            const startIdx = Math.max(0, lruAccessOrder.length - maxTabs);
            for (let i = startIdx; i < lruAccessOrder.length; i++) {
                newLoadedTabs[lruAccessOrder[i]] = true;
            }
        }

        lruTabsLoaded = newLoadedTabs;
    }

    // Check if a tab should be loaded
    function shouldTabBeLoaded(tabIndex) {
        if (tabIndex === 0) return true; // Always load WidgetsTab (Tab 0)

        if (Config.performance.dashboardPersistTabs) {
            return lruTabsLoaded[tabIndex] === true;
        } else {
            // Without persistence, only load current tab
            return root.state.currentTab === tabIndex;
        }
    }

    focus: true

    // Usar el comportamiento estándar de animaciones del notch
    isVisible: GlobalStates.dashboardOpen

    // Navegar a la pestaña seleccionada cuando se abre el dashboard
    Component.onCompleted: {
        root.state.currentTab = GlobalStates.dashboardCurrentTab;
    }

    // Focus search input when dashboard opens to different tabs
    onIsVisibleChanged: {
        if (isVisible) {
            // Check if current item supports focus, otherwise default logic for launcher
            if (stack.currentItem && stack.currentItem.focusSearchInput) {
                focusUnifiedLauncherTimer.restart();
            } else if (GlobalStates.dashboardCurrentTab === 0) {
                Notifications.hideAllPopups();
                focusUnifiedLauncherTimer.restart();
            }
        } else {
            // Reset launcher state when dashboard closes
            GlobalStates.clearLauncherState();
        }
    }

    // Timer para focus en unified launcher tab
    Timer {
        id: focusUnifiedLauncherTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (stack.currentItem && stack.currentItem.focusSearchInput) {
                stack.currentItem.focusSearchInput();
            }
        }
    }

    // Escuchar cambios en dashboardCurrentTab para navegar automáticamente
    Connections {
        target: GlobalStates
        function onDashboardCurrentTabChanged() {
            if (GlobalStates.dashboardCurrentTab !== root.state.currentTab) {
                stack.navigateToTab(GlobalStates.dashboardCurrentTab);
            }
        }

        // Focus cuando cambia el texto del launcher (por shortcuts con prefix)
        function onLauncherSearchTextChanged() {
            if (isVisible && GlobalStates.dashboardCurrentTab === 0) {
                focusUnifiedLauncherTimer.restart();
            }
        }
    }

    Column {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: Styling.tight

        // Top navigation strip
        Item {
            id: tabsContainer
            width: parent.width
            height: root.tabWidth

            // Manejo del scroll con rueda del mouse
            WheelHandler {
                id: wheelHandler
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

                onWheel: event => {
                    // Determinar dirección del scroll
                    let scrollUp = event.angleDelta.y > 0;
                    let newIndex = root.state.currentTab;

                    if (scrollUp && newIndex > 0) {
                        // Scroll hacia arriba = pestaña anterior
                        newIndex = newIndex - 1;
                    } else if (!scrollUp && newIndex < root.tabCount - 1) {
                        // Scroll hacia abajo = pestaña siguiente
                        newIndex = newIndex + 1;
                    }

                    // Navegar solo si cambió el índice
                    if (newIndex !== root.state.currentTab) {
                        stack.navigateToTab(newIndex);
                    }
                }
            }


            Row {
                id: tabs
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.tabSpacing

                Repeater {
                    model: root.tabModel

                    Button {
                        id: tabButton
                        required property int index
                        required property string modelData

                        text: modelData
                        flat: true
                        width: root.tabWidth
                        height: root.tabWidth

                        background: Rectangle {
                            color: "transparent"
                            radius: Styling.radius(4)
                        }

                        contentItem: Text {
                            text: parent.text
                            textFormat: Text.RichText
                            // Selected reads exactly as hover does — brought up
                            // out of the dimmed idle state, nothing drawn behind
                            color: Colors.overBackground
                            opacity: root.state.currentTab === tabButton.index || tabButton.hovered ? 1.0 : 0.55

                            Behavior on opacity {
                                enabled: Config.animDuration > 0
                                NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutQuart }
                            }
                            // font.family: Config.theme.font
                            font.family: Icons.font
                            // font.pixelSize: Config.theme.fontSize
                            font.pixelSize: Styling.glyph
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            Behavior on color {
                                enabled: Config.animDuration > 0
                                ColorAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        onClicked: stack.navigateToTab(index)
                    }
                }

                // Tools opens a module rather than switching tabs, so it sits
                // outside the Repeater and the travelling highlight ignores it —
                // but it reads as one of the same top-left set.
                Button {
                    id: toolsTabButton
                    flat: true
                    width: root.tabWidth
                    height: root.tabWidth

                    readonly property bool toolsActive: Visibilities.currentActiveModule === "tools"

                    background: Rectangle {
                        color: "transparent"
                        radius: Styling.radius(4)
                    }

                    contentItem: Text {
                        text: Icons.toolbox
                        color: Colors.overBackground
                        opacity: toolsTabButton.toolsActive || toolsTabButton.hovered ? 1.0 : 0.55

                        font.family: Icons.font
                        font.pixelSize: Styling.glyph
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        Behavior on opacity {
                            enabled: Config.animDuration > 0
                            NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutQuart }
                        }

                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    onClicked: Visibilities.setActiveModule(toolsTabButton.toolsActive ? "" : "tools")
                }
            }

            // LayoutSelectorButton came off the bar; it reads orientation and
            // uses barPosition to decide which way its popup opens.
            QtObject {
                id: navRailStub
                property string orientation: "horizontal"
                property string barPosition: "top"
            }

            // System group, opposite the tab group
            Row {
                id: rightGroup
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.tabSpacing

                Item {
                    width: root.tabWidth
                    height: root.tabWidth

                    LayoutSelectorButton {
                        anchors.centerIn: parent
                        width: Styling.control
                        height: Styling.control
                        bar: navRailStub
                        flat: true
                        layerEnabled: false
                    }
                }

                // Settings
                Item {
                    id: controlsButtonContainer
                    width: root.tabWidth
                    height: root.tabWidth

                    readonly property bool lit: controlsButton.hovered || GlobalStates.settingsWindowVisible

                    // Same treatment as the layout selector: nothing drawn
                    // behind it, the glyph grows and takes the accent instead
                    scale: lit ? 1.12 : 1.0

                    Behavior on scale {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration / 2
                            easing.type: Easing.OutCubic
                        }
                    }

                    Button {
                        id: controlsButton
                        anchors.fill: parent
                        flat: true
                        hoverEnabled: true

                        background: Rectangle {
                            color: "transparent"
                        }

                        contentItem: Text {
                            text: Icons.gear
                            font.family: Icons.font
                            font.pixelSize: Styling.glyph
                            font.weight: Font.Medium
                            color: controlsButtonContainer.lit ? Colors.primary : Colors.overBackground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            Behavior on color {
                                enabled: Config.animDuration > 0
                                ColorAnimation {
                                    duration: Config.animDuration / 2
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        onClicked: GlobalShortcuts.toggleSettings()
                    }
                }

            Item {
                id: powerButtonContainer
                width: root.tabWidth
                height: root.tabWidth

                readonly property bool lit: powerButton.hovered || Visibilities.currentActiveModule === "powermenu"

                scale: lit ? 1.12 : 1.0

                Behavior on scale {
                    enabled: Config.animDuration > 0
                    NumberAnimation {
                        duration: Config.animDuration / 2
                        easing.type: Easing.OutCubic
                    }
                }

                Button {
                    id: powerButton
                    anchors.fill: parent
                    flat: true
                    hoverEnabled: true

                    background: Rectangle {
                        color: "transparent"
                    }

                    contentItem: Text {
                        text: Icons.shutdown
                        font.family: Icons.font
                        font.pixelSize: Styling.glyph
                        font.weight: Font.Medium
                        color: powerButtonContainer.lit ? Colors.primary : Colors.overBackground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        Behavior on color {
                            enabled: Config.animDuration > 0
                            ColorAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    onClicked: Visibilities.setActiveModule(Visibilities.currentActiveModule === "powermenu" ? "" : "powermenu")
                }
            }
            }
        }

        Separator {
            width: parent.width
            height: 2
            vert: false
        }

            // Content area
        Rectangle {
            id: viewWrapper

            color: "transparent"

            width: parent.width
            height: parent.height - root.tabWidth - 2 - Styling.tight * 2

            clip: true

            // Custom Tab View with Lazy Loading + Persistence
            Item {
                id: stack
                anchors.fill: parent

                property int currentIndex: GlobalStates.dashboardCurrentTab

                // Update internal index when global changes
                Connections {
                    target: GlobalStates
                    function onDashboardCurrentTabChanged() {
                        stack.navigateToTab(GlobalStates.dashboardCurrentTab);
                    }
                }

                // Function to navigate to a specific tab
                function navigateToTab(index) {
                    if (index >= 0 && index < root.tabCount && index !== root.state.currentTab) {
                        // Reset launcher state when leaving unified launcher tab (tab 0)
                        if (root.state.currentTab === 0 && index !== 0) {
                            GlobalStates.clearLauncherState();
                        }

                        root.state.currentTab = index;
                        GlobalStates.dashboardCurrentTab = index;
                        
                        // Update LRU when tab is accessed
                        root.updateLRUAccess(index);

                        if (index === 0) {
                            Notifications.hideAllPopups();
                            focusUnifiedLauncherTimer.restart();
                        }
                    }
                }

                // Generic Tab Loader Component
                component TabLoader : Loader {
                    anchors.fill: parent
                    // Load based on LRU strategy or if currently active
                    active: root.shouldTabBeLoaded(index) || root.state.currentTab === index
                    
                    // Visibility handles the "switching"
                    visible: root.state.currentTab === index
                    
                    // Transitions
                    opacity: visible ? 1 : 0
                    transform: Translate {
                        y: visible ? 0 : (root.state.currentTab > index ? -20 : 20)
                        Behavior on y {
                             enabled: Config.animDuration > 0
                             NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart } 
                        }
                    }

                    Behavior on opacity {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart }
                    }

                    // Forward focus
                    onLoaded: {
                        if (visible && item && item.focusSearchInput) {
                            focusUnifiedLauncherTimer.restart();
                        }
                    }
                    
                    // Ensure focus when becoming visible
                    onVisibleChanged: {
                        if (visible && item && item.focusSearchInput) {
                            focusUnifiedLauncherTimer.restart();
                        }
                    }
                }

                // Tab 0: Unified Launcher
                TabLoader {
                    property int index: 0
                    sourceComponent: unifiedLauncherComponent
                    z: visible ? 1 : 0
                }

                // Tab 1: Wallpapers
                TabLoader {
                    property int index: 1
                    sourceComponent: wallpapersComponent
                    z: visible ? 1 : 0
                }

                // Tab 2: Metrics
                TabLoader {
                    property int index: 2
                    sourceComponent: metricsComponent
                    z: visible ? 1 : 0
                }
                
                // Helper to access current item for focus
                property var currentItem: {
                    switch(root.state.currentTab) {
                        case 0: return children[0].item;
                        case 1: return children[1].item;
                        case 2: return children[2].item;
                        default: return null;
                    }
                }

                // Gesture handling para swipe vertical
                MouseArea {
                    anchors.fill: parent
                    property real startY: 0
                    property real startX: 0
                    property bool swiping: false
                    property real swipeThreshold: 50
                    
                    // Allow clicking through to tabs
                    propagateComposedEvents: true
                    preventStealing: false

                    onPressed: mouse => {
                        startY = mouse.y;
                        startX = mouse.x;
                        swiping = false;
                        mouse.accepted = false; // Let children handle clicks
                    }

                    onPositionChanged: mouse => {
                        let deltaY = mouse.y - startY;
                        let deltaX = Math.abs(mouse.x - startX);

                        // Solo considerar swipe vertical si el movimiento horizontal es mínimo
                        if (Math.abs(deltaY) > 20 && deltaX < 30) {
                            swiping = true;
                        }
                    }

                    onReleased: mouse => {
                        if (swiping) {
                            let deltaY = mouse.y - startY;

                            if (deltaY < -swipeThreshold && root.state.currentTab < root.tabCount - 1) {
                                // Swipe hacia arriba - siguiente tab
                                stack.navigateToTab(root.state.currentTab + 1);
                            } else if (deltaY > swipeThreshold && root.state.currentTab > 0) {
                                // Swipe hacia abajo - tab anterior
                                stack.navigateToTab(root.state.currentTab - 1);
                            }
                        }
                        swiping = false;
                        mouse.accepted = false;
                    }
                }
            }
        }
    }

    // Atajos de teclado para navegación
    Shortcut {
        id: nextTabShortcut
        sequence: "Ctrl+Tab"
        enabled: GlobalStates.dashboardOpen

        onActivated: {
            let nextIndex = (root.state.currentTab + 1) % root.tabCount;
            stack.navigateToTab(nextIndex);
        }
    }

    Shortcut {
        id: prevTabShortcut
        sequence: "Ctrl+Shift+Tab"
        enabled: GlobalStates.dashboardOpen

        onActivated: {
            let prevIndex = root.state.currentTab - 1;
            if (prevIndex < 0) {
                prevIndex = root.tabCount - 1;
            }
            stack.navigateToTab(prevIndex);
        }
    }

    // Animated size properties for smooth transitions
    property real animatedWidth: implicitWidth
    property real animatedHeight: implicitHeight

    width: animatedWidth
    height: animatedHeight

    // Update animated properties when implicit properties change
    onImplicitWidthChanged: animatedWidth = implicitWidth
    onImplicitHeightChanged: animatedHeight = implicitHeight

    Behavior on animatedWidth {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
    }

    Behavior on animatedHeight {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
    }

    // Component definitions for better performance (defined once, reused)
    Component {
        id: unifiedLauncherComponent
        WidgetsTab {
            leftPanelWidth: root.leftPanelWidth
        }
    }

    Component {
        id: metricsComponent
        MetricsTab {}
    }

    Component {
        id: wallpapersComponent
        WallpapersTab {}
    }
}
