# Technical Constraints

Status: **Accepted baseline unless superseded by ADR**

## Engine

- Godot Engine **4.7.2 stable**.
- GDScript only.
- Standard Godot build, not .NET.
- Compatibility renderer.
- Primary target: Web/itch.io.

Do not use APIs introduced after Godot 4.7 without an explicit version-upgrade decision.

## Display

- Logical design resolution: **720×1280**.
- Portrait.
- Uniform scaling.
- Preserve full required UI/gameplay area.
- Do not crop to fill.
- Extra viewport space uses background extension/letterboxing treatment.
- Mobile landscape shows rotate-device UI.

## Input

Must support:

- `QWE / ASD / ZXC`;
- numeric keypad `789 / 456 / 123`;
- mouse;
- touch;
- multitouch.

## Timing

- Song clock is authoritative.
- Runtime chart timestamps are absolute milliseconds.
- Frame delta cannot be the gameplay clock.

## Web

- Must remain compatible with itch.io HTML5 embedding/fullscreen behavior.
- Avoid native-only APIs.
- Browser focus loss auto-pauses gameplay.
- Backup import/export may use a minimal JavaScript bridge.

## Performance

The 3×3 gameplay view, simultaneous notes, Hold effects, character/table art, and UI animations must remain smooth on typical modern mobile browsers.

No fixed FPS assumption may affect score/timing.

## Continuous integration

CI installs the official Godot `4.7.2.stable` editor and matching export
templates, then runs headless project loading, the native GDScript suite, the
Python chart-import suite, strict release-content/chart validation, and the Web
release export/artifact verifier. A failing release gate remains a failing job.
The diagnostic export still runs, but artifact verification requires a
successful export and artifact upload requires every prior gate to pass.

## Licensing

Only content with confirmed redistribution rights may ship publicly. The
machine-readable release inventory is `content/release-content.json`; an
undecided project license or incomplete content evidence blocks release.
