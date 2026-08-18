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
the AI integration, the bundled theme presets, and the config surface that existed to carry
them. The design language is being replaced rather than re-skinned.

---

## Status

In development, continuously, with no end state in view.

There are no instructions here yet and that is deliberate. When this is far enough from upstream
to deserve its own documentation it will get some. Until then it is for me, and Ambxst is the
one to use.
