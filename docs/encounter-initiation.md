# Encounter initiation and withdrawal prototype

Press **R** near a settled, available Sol to approach deliberately. Per the
[owner's decision](decisions/2026-10-27-encounter-initiation.md), the third trail
sighting (guarding Seedmote near x=48) also supports automatic contact: first a
nonmodal warning, then a later completed player step within contact distance.
The first Seedmote and Bramblepup remain non-hostile.

The face-to-face panel offers **Record sighting** and **Withdraw**. Escape also
withdraws. This is encounter-entry groundwork, not tactical combat: no allied
starter, arena actions, damage, capture, escape roll, or reward is introduced.
Observation uses the existing saved journal and does not grant trust or ownership.

## Source and warning contract

Source evidence: SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885`, specifically
`src/systems/ai/encounters.py`, `src/core/game.py` encounter entry,
`docs/coordination/warning-movement-continuity.md`, and
`docs/coordination/encounter-persistence.md`. These establish target identity,
warn-before-contact, movement continuity, and actual combat persistence guards.
Godot terrain generation is unchanged. Private source instructions are reference
evidence, not permission to modify that repository.

The nearest hostile target is selected by Manhattan distance then stable ID.
Warnings arm only after `RenderingServer.frame_post_draw` acknowledges a visible,
uncovered exploration warning. Hidden HUD, open Field Notes, pause, or confirmation
dialogs prevent acknowledgement. A changed/cleared target loses its presentation
status. Headless tests explicitly simulate the post-draw seam; ordinary gameplay
uses the actual rendering callback.

Only a later completed player step can trigger automatic entry. Idle refreshes,
AI ticks, partial movement, rendering, loading, or first entering the warning band
cannot do so. Warning refresh never resets a partial stride or held directions.
Moving away before contact remains possible. Refuge cells suppress automatic
entry. Deterministic smoke mode suppresses automatic warnings/contact so isolated
journey fixtures remain deterministic; the new integration suite tests entry
with normal exploration behavior.

## Context, withdrawal, and persistence

The runtime controller retains the selected stable wild ID and owning state;
owned/unavailable targets cannot be selected. Repeated entry cannot replace an
active target. State/ownership changes invalidate the active preview safely.
Entering pauses exploration and hides the ordinary pause/journal panels; ongoing
clock/ecological/local-Sol updates stop. Withdraw leaves the player at the settled
contact position and resumes exploration without clearing held directions.

Prototype withdrawal grants three successful exploration steps of protection
from automatic re-entry by default. Deliberate approach remains available.
Blocked steps, idle time, and read refreshes do not consume it. This is reversible
anti-chain tuning inspired by the source's three-step post-battle protection,
applied here to a preview; it is not a finalized battle escape/protection rule.

Warning acknowledgement, preview context, and this preview-only protection are
runtime state and are deliberately reset on load/new expedition. The save schema
does not change (outer format 2, domain 5). Load must show a fresh warning before
any later automatic contact; it does not resume an armed encounter.

World save/load/new-expedition methods and the confirmation path reject while
the preview is active, before reading/writing a slot or replacing domain state.
The standalone codec remains a pure validated-exploration-snapshot writer; it
has no runtime preview context. This is not a claim that a future combat controller
can bypass its own persistence guard. Actual combat will require the source's
no-mid-combat rule across its authoritative entry points before it is enabled.

## Godot controls

Root **Expedition Tuning → Encounter Settings** assigns
`resources/encounter_settings.tres`:

| Setting | Default / range | Effect |
| --- | --- | --- |
| Enabled | true | Enable new manual/automatic preview entry. |
| Automatic Contact | true | Enable warnings and later contact for the authored hostile guard. |
| Warning Distance | 3 / 1–6 cells | Manhattan warning band; must cover Contact Distance. |
| Contact Distance | 1 / 0–1 cells | Automatic entry only on a later completed contact step. |
| Interaction Distance | 3 / 1–6 cells | Manual R selection range, also limited by sighting visibility. |
| Withdrawal Safe Steps | 3 / 1–8 steps | Prototype automatic re-entry protection after withdrawal. |

Settings apply to current/loaded exploration without changing identity. Invalid
initial resources fall back with a warning; invalid runtime settings prevent new
entry. An already-open panel can always withdraw. Disabling does not delete Sols.

## Verification

`tests/encounter_initiation.gd` checks held-direction/partial-stride continuity,
nonmodal warning presentation, later contact, no idle/unpresented trigger,
retreat, uncovered-HUD acknowledgement, manual neutral selection, ownership
rejection, runtime load reset, protected steps, Inspector switches, paused activity,
journal-only outcomes, and preview save/load/new-seed/confirmation guards.
The final shared Godot 4.7.2 validator passed import and all 6,277 headless
assertions, including both scene journeys and 26 entry checks. The rendered
entry suite separately passed 26 checks. Existing GPU-only checks from other
suites remain outside the headless total.
Rendered warning and panel captures were inspected on Godot 4.7.2/OpenGL/RTX 3070:

```powershell
godot --path . --script tests/encounter_initiation.gd -- --capture-encounter
```

Outputs: `artifacts/encounter/warning.png` and `panel.png`. These are scripted
input-routing/rendered checks, not physical-input, accessibility, device-budget,
or full D3/D4 acceptance. Tactical battle remains the next separate slice.
