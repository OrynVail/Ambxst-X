# flokshell

A Wayland shell for Hyprland, built on Quickshell. A hard fork of
[Ambxst](https://github.com/Axenide/Ambxst).

Named after my cat.

---

## Credit

**Ambxst is [Axenide](https://github.com/Axenide)'s work, and it is most of what runs here.**
The architecture, the reactive JSON configuration, the panel system, the lockscreen, the
widgets — his. I did not have to reinvent this wheel because he had already made it, and made
it well.

| | |
|---|---|
| Original project | **[Axenide/Ambxst](https://github.com/Axenide/Ambxst)** |
| Author | **Adriano Tisera (Axenide)** — [GitHub](https://github.com/Axenide), [socials](https://zaap.bio/Axenide) |
| Support him | **[Ko-fi](https://ko-fi.com/Axenide)** |
| Community | **[Discord](https://axeni.de/discord)** |
| Licence | **AGPL-3.0**, upstream copyright intact in [LICENSE](LICENSE) |

**For what this shell is and how to install it, read [Ambxst's README](https://github.com/Axenide/Ambxst).**
It is the better document, and it describes the thing that actually ships. Nothing is repeated
here.

---

## Why the fork

Ambxst is built to be extremely customisable. That is the right goal for it and it is not mine.

I wanted one opinionated configuration instead of a preset library — so a hard fork was more
honest than a pile of local overrides losing a fight with upstream on every pull. Gone so far:
the AI integration and its sidebar, the bundled theme presets, the bar, the duplicate media
players, and the config surface that existed to carry all of it. The design language is being
replaced rather than re-skinned.

---

## Weight

It does less, so it holds less.

| | Ambxst 1.1.5 | flokshell |
|---|---|---|
| QML files | 216 | 181 |
| Lines of QML | 78,160 | 66,397 |

Three inefficiencies upstream still carries are fixed here. None of them change behaviour:

- The notch built its dashboard, launcher, powermenu and tools views on first open and never
  released them — per monitor. They are released now once closed.
- Seventeen images decoded at full source resolution to fill much smaller items. A 2560×1440
  image costs 14.7 MB of memory whether or not you can see it at that size.
- Every config property change rewrote a whole JSON file atomically. Dragging one slider was a
  file rewrite per frame. Writes coalesce now.

Idle footprint went from 601 MB resident to 510 MB, and 411 MB private dirty to 326 MB, on two
monitors with nothing open.

I have not benchmarked Ambxst, so there is no honest speed figure to quote against it. Those
numbers are this shell before and after, one sample each, on my machine. The three fixes are
things I read in upstream's source, not things I measured it doing.

---

## Status

In development, continuously, with no end state in view.

There are no instructions here yet and that is deliberate. When this is far enough from upstream
to deserve its own documentation it will get some. Until then it is for me, and Ambxst is the
one to use.
