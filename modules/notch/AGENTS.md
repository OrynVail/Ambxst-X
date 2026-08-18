# NOTCH

## OVERVIEW
The shell surface. There is no bar — this is it. StackView navigation between modules,
two themes (`default` / `island`), and the notification popup system.

## STRUCTURE
| File | Purpose |
|------|---------|
| `Notch.qml` | The island itself: StackView, corner masking, theme rendering, animations |
| `NotchContent.qml` | Per-screen wrapper: hover detection, reveal logic, persistent Loaders |
| `NotchAnimationBehavior.qml` | Shared animation behaviour |
| `NotchNotificationView.qml` | Notification display with wheel navigation |
| `NotchWorkspaces.qml` | Workspace pills in the main row |
| `NotchWindow.qml` | PanelWindow wrapper — disabled |

Idle content is `modules/widgets/defaultview/DefaultView.qml`: logo, workspaces, clock,
systray, battery. Its `notchBarStub` is what feeds `bar`-expecting widgets.

## WHERE TO LOOK
- **Reveal / auto-hide** — `NotchContent.qml`, driven by `keepHidden`, notch position and
  fullscreen state; a delay timer stops flicker on mouse leave.
- **Width** — `DefaultView.qml` `mainRowContentWidth` follows the row's real content, so the
  notch grows and shrinks with what is in it rather than holding a reserved width.
- **Popup coordination** — `childPopupOpen` keeps the notch revealed while a child popup is
  open, otherwise it auto-hides the moment the pointer leaves to reach it.

## ANTI-PATTERNS
- Hardcoding notch dimensions — use `Config.notchTheme`, `Config.roundness`,
  `Config.notchPosition`.
- Manipulating the stack directly — go through `Visibilities`.
- Pushing to StackView from `Connections` without `Qt.callLater()`.
