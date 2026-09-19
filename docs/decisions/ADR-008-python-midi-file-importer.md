# ADR-008 — Python MIDI-File Importer

Status: **Accepted**

## Decision

Implement chart authoring as a deterministic Python CLI that converts an
existing MIDI file plus explicit configuration into runtime chart JSON.

Live MIDI capture is out of scope. The importer must respect the MIDI tempo map,
use configurable note-to-pad mappings and authoring thresholds, and produce the
same JSON for the same inputs.

## Why

A file-based CLI is portable, testable, and independent from controller drivers
and real-time device behavior. Python has mature MIDI parsing support and keeps
the authoring tool separate from the Web runtime.

