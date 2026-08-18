# NOTCH WIDGETS

## OVERVIEW
Widgets that used to make up the bar. The bar is gone; these are consumed by the notch and
the dashboard. The directory name is kept because everything imports `qs.modules.bar.*`.

## STRUCTURE
| File | Purpose |
|------|---------|
| `clock/Clock.qml` | Time, date, weather; drives its own popup |
| `clock/Pomodoro.qml` | Pomodoro timer with an `IpcHandler` on target `pomodoro` |
| `systray/SysTray.qml` | SNI tray. Collapses to zero width when empty |
| `systray/SysTrayItem.qml` | Individual tray entry with hover chip |
| `workspaces/Workspaces.qml` | Workspace pills |
| `BatteryIndicator.qml` | Battery readout and popup |
| `LayoutSelector.qml` / `LayoutSelectorButton.qml` | Compositor layout switcher |

## CONVENTIONS
- These take a `bar` property expecting `orientation` and `barPosition`. Callers pass a
  `QtObject` stub — see `notchBarStub` in `modules/widgets/defaultview/DefaultView.qml`.
- `flat: true` opts into the deboxed treatment: nothing drawn at rest, glyph grows or takes
  the accent on hover. `layerEnabled: false` disables the shadow layer.
- Handle both `horizontal` and `vertical` orientation — the notch supports top and bottom.
- Popups register with `Visibilities` so the notch stays revealed while one is open.
