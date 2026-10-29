# Deliberate Sol observation and saved Field Notes

Approach a trail Sol, finish your movement step, and press **F** to observe it.
Within the configured Manhattan observation distance, the nearest available
individual is selected, with stable-ID ordering for ties. Its prompt changes to
Recorded after success. Open **J → Sightings** to read the saved title, observed
posture description, and first-seen target coordinates. **Session** retains the
previous temporary message log. The journal is scrollable and remains nonmodal,
as in the earlier Godot Field Notes panel.

Observation is an explicit choice, not a per-frame discovery trigger. Paused,
moving, confirmation-dialog, out-of-range, disabled, and acquired targets are
ineligible. Re-observing a retained entry does not rewrite it or emit another
discovery event. Opening/scrolling Field Notes is read-only. No trust, ownership,
items, quests, battle outcomes, or combat-stat information are awarded or inferred.

## Source contract and retention

The non-generation reference is SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885`, specifically
`src/systems/world/journal.py`, `test_discovery_journal.py`, and
`docs/coordination/journal-detail-access.md`, reconciled with Bible field-journal
and recognizable-individual guidance. Godot terrain generation is unchanged.

The journal stores one first observation per retained stable individual ID,
including title/category/description/details and first-seen coordinates. At most
120 recent distinct discoveries are retained, matching the source journal policy.
Adding the 121st retires the oldest journal row, never the individual or its
relationship history. A retired individual may later be recorded again as a new
retained discovery. This is a recent-discovery journal, not an unlimited archive.

The source truncates display strings during insertion; this Godot API instead
rejects invalid/oversized authored text before mutation. Supported bounds remain
80 characters for title, 400 for description, and eight 120-character detail lines.
This slice records only the current authored posture text; it does not populate
unsupported Wild Examine statistics or import the source quest-event system.

## Save compatibility and ownership

Domain `world_state` version 4 adds bounded `discoveries`. Outer save format
remains 2. Domain versions 1–3 load with an empty journal and unchanged individuals,
ecological deltas, clocks, and compatible scheduler/receipt state. No observation
history is invented from merely loaded or visible creatures.

Incoming/outgoing validation rejects duplicate identities, orphan references,
malformed coordinates, unknown fields, overlarge histories/text, and invalid types
before replacement/write. JSON coordinate integers normalize on restore. First
observations remain after acquisition and render rebuild. A new expedition clears
its own discovery journal. Loading preserves original file bytes and uses the
existing next-save backup policy.

`discovery_recorded` publishes only after a new retained entry commits. The world
disconnects old state subscriptions on replacement and rebuilds the visible journal
on load. Derived prompt labels and Field Notes text never own copies of game state.

## Inspector tuning and verification

Root **Expedition Tuning → Sighting Settings → Observation Distance** accepts
1–6 Manhattan cells (default 3). Visibility still bounds selectable targets.
Changing it affects loaded sightings without changing IDs or old journal records.
Other proximity/animation settings remain independent presentation controls.
The 120-row retention bound is a storage contract, not an ecological balance knob.

`tests/sol_observation.gd` supplies 38 checks covering actual F/J input routing,
pause/movement/echo/range gates, first-seen preservation, idempotence, detached
reads, no trust/ownership gains, real file reload and UI refresh, old-domain
upgrades, malformed outgoing rollback, and bounded retention without losing Sols.
The full shared validator passed Godot 4.7.2 import and 6,200 headless assertions,
including both scene journeys. A rendered OpenGL/RTX 3070 run separately passed
38 checks; the final footer/journal update was rechecked with that rendered suite.
Existing GPU-only checks from other suites are outside the headless total.

To reproduce the inspected UI capture:

```powershell
godot --path . --script tests/sol_observation.gd -- --capture-journal
```

Output: `artifacts/observation/journal.png`. This is scripted visual/input-routing
verification, not native keyboard or accessibility acceptance. The subsequent
[local-reaction slice](local-sol-reactions.md) adds bounded movement. Battle
initiation, capture interaction, and production wildlife generation remain future
work; D3 is not declared complete.
