# Input Specification

Status: **Draft baseline**

## Logical pads

```text
7 8 9
4 5 6
1 2 3
```

Each pad is one logical action with multiple physical sources.

`InputRouter` is scene-local. It emits `pad_pressed(pad)` and
`pad_released(pad)` and accepts opaque source IDs rather than owning pad visuals
or gameplay judgments.

## Keyboard mapping

| Pad | Main keyboard | Numeric keypad |
|---:|---|---|
| 7 | Q | KP 7 |
| 8 | W | KP 8 |
| 9 | E | KP 9 |
| 4 | A | KP 4 |
| 5 | S | KP 5 |
| 6 | D | KP 6 |
| 1 | Z | KP 1 |
| 2 | X | KP 2 |
| 3 | C | KP 3 |

The implementation SHOULD use physical keypad keys where exposed by Godot/browser/OS so keypad play remains usable with Num Lock enabled or disabled.

Do not globally remap navigation keys such as Home/PageUp as keypad substitutes.

## Pointer/touch mapping

- Mouse click directly on a pad.
- Touch directly on a pad.
- Multitouch may activate multiple pads at once.

A finger is permanently bound to its starting pad until lifted. Dragging does not activate another pad.

## Multiple sources on one pad

A logical pad tracks active physical sources as a set.

Example:

```text
press Q        -> pad 7 pressed
press KP7      -> no second logical press
release Q      -> pad 7 remains held
release KP7    -> pad 7 released
```

Rules:

- Emit logical `pressed` only on active-source count `0 → 1`.
- Emit logical `released` only on active-source count `1+ → 0`.
- A Tap requires a new logical `pressed` transition.
- Holding equivalent inputs is valid and must not duplicate judgments.

## Chords

Multiple logical pads may be pressed simultaneously.

A Hold on one pad must not block Tap/Hold input on other pads.

## Focus and pause

On browser/app focus loss:

- Clear all physical input sources and emit one logical release for each active
  pad before the gameplay layer pauses.
- Pause gameplay.
- Never generate MISS judgments while unfocused.
- Resume only after explicit action and countdown.

## Known hardware limitation

Keyboard ghosting is external to the game. Supporting both `QWE/ASD/ZXC` and numpad reduces, but cannot eliminate, hardware-specific simultaneous-key limits.
