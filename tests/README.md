# Tests

`runner.gd` is the dependency-free native GDScript test entry point. Run it with:

```powershell
godot --headless --path . --script res://tests/runner.gd
```

M0 validates project settings and placeholder scene loading. M1 adds deterministic
content, save, and logical-input suites. M2 adds authoritative clock, chart-v1
validation, and timeline traversal suites. M3 covers gameplay judgment boundaries,
note/Hold lifecycle, score/combo/multiplier, MISS streak, accuracy/rank,
success/failure, visual timing math, and clean session reset.

M4 adds deterministic navigation-boundary, runtime-selection, and product-flow
selection tests. Screen composition and browser/mobile ergonomics remain manual
validation work.

M5 invokes the standard-library Python importer suite from the native runner,
covering MIDI parsing, tempo maps, mapping configuration, Tap/Hold conversion,
strict Hold ticks, validation, and byte-identical output repeatability.
