# ADR-003 — Authoritative Song Clock

Status: **Accepted**

## Decision

Gameplay timing is derived from compensated audio playback time. Frame delta and note visual scale never determine judgment timing.

## Why

Rhythm gameplay must remain synchronized despite rendering variance, frame drops, pause/resume, and browser timing behavior.
