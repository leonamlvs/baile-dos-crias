# Scripts

Implemented modules are grouped by responsibility: data and save/input foundations,
the compensated audio clock and chart runtime, and M3 gameplay rules/presentation.
Gameplay judgment, scoring, and lifecycle code remains independent from the
product-screen layer so it can be exercised deterministically in headless tests.
