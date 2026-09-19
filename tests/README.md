# Tests

`runner.gd` is the dependency-free native GDScript test entry point. Run it with:

```powershell
godot --headless --path . --script res://tests/runner.gd
```

M0 validates project settings and placeholder scene loading. M1 adds deterministic
content, save, and logical-input suites. M2 adds authoritative clock, chart-v1
validation, and timeline traversal suites. Gameplay scoring suites are added only
as their supporting milestones are built.
