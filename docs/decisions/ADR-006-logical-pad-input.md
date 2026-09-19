# ADR-006 — Logical Pad Input Aggregation

Status: **Accepted**

## Decision

Each of the nine pads is a logical input fed by multiple physical sources. Logical press occurs on source count `0→1`; logical release occurs on `1+→0`.

Touch contacts remain bound to the pad where they began until lifted.

## Why

This resolves equivalent-key conflicts, enables numpad + QWERTY + pointer + multitouch consistently, and prevents duplicate hits when two equivalent inputs are held.
