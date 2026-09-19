# ADR-009 — ScreenRouter Boundary

Status: **Accepted**

## Decision

Keep `ScreenRouter` as an AutoLoad responsible strictly for navigation and scene
transitions.

It must not own selection or run state, audio, persistence, gameplay rules, or
screen-local behavior.

## Why

Centralizing the small fixed scene graph makes transitions consistent without
turning the router into a general-purpose global manager.

