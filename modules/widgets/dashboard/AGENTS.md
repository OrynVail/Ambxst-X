# DASHBOARD

## OVERVIEW
The main hub, opened from the notch. Tabbed, with LRU lazy-loading of tab content.

## STRUCTURE
- `Dashboard.qml` — tab strip, LRU logic, open/close animation.
- `DashboardView.qml` — **the sizing authority**. Every dimension derives from the constants
  at the top; nothing downstream picks its own numbers.
- Tabs: `widgets/`, `wallpapers/`, `metrics/`, plus `clipboard/`, `notes/`, `tmux/`,
  `emoji/` reached through the launcher, and `controls/` for the settings panels.

## LAYOUT
`widgets/WidgetsTab.qml` is three columns over a control rail:

| | |
|---|---|
| Column 1 | `FullPlayer` — disc, metadata, transport |
| Column 2 | five toggles sitting on the calendar |
| Column 3 | `NotificationHistory` |
| Rail | volume bar + knob · brightness knob (window centre) · mic knob + bar |

Columns are divided by hairline `Separator`s, not nested cards. `bodyHeight` in
`DashboardView.qml` is the one hard number — the columns are exactly that tall and
everything else is measured off it, so the player is never what gets squeezed.

## WHERE TO LOOK
| Task | Location |
|------|----------|
| Any dimension | `DashboardView.qml` |
| Tab loading | `Dashboard.qml` — `shouldTabBeLoaded(index)` |
| Shell/notch settings UI | `controls/ShellPanel.qml` |
| Theme settings UI | `controls/ThemePanel.qml` |
| Keybindings | `controls/BindsPanel.qml` |

## CONVENTIONS
- Use `Loader.active` via `shouldTabBeLoaded(index)`; tabs evict past the cache limit.
- Components expose `focusSearchInput()` so the root can forward focus on open.
- Containers are `StyledRect` variants, never raw `Rectangle`.
- Bind to service singletons directly; no prop-drilling.
- The toggle row is sized from the calendar width, so those two are coupled.

## ANTI-PATTERNS
- Picking a size locally instead of deriving it in `DashboardView.qml`.
- Tab content without `TabLoader` / LRU integration.
- `StyledSlider` assigns its own `value`; a plain binding to a service breaks on first drag.
  Re-establish it with a `Connections` guarded on `isDragging` — see the rail sliders.
