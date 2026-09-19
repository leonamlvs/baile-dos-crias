# ADR-004 — MIDI Authoring, JSON Runtime

Status: **Accepted**

## Decision

Use MIDI as an optional human-friendly chart authoring source and versioned JSON with absolute millisecond timestamps as the runtime chart.

## Why

MPC users can perform charts naturally, while runtime remains deterministic, reviewable, simple to validate, and independent from MIDI tempo interpretation.
