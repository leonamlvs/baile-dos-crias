# ADR-007 — Native GDScript Test Runner

Status: **Accepted**

## Decision

Use a dependency-free, headless GDScript test runner for the MVP. The runner
extends `SceneTree`, prints deterministic results, and exits nonzero when any
validation or test fails.

Do not add an external Godot test framework during the MVP.

## Why

The deterministic rules can be tested with small Godot-native suites. Avoiding
an external framework keeps the Web-first project baseline and contributor setup
small while retaining automation through the standard Godot CLI.

