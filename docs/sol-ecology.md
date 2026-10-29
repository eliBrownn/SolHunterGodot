# Species behavior and individual variation

October 27, 2026 — phase 4 of the [Sol behavior roadmap](sol-behavior-roadmap.md).
These are provisional profiles for the existing prototype species, not final
species canon or a new roster. Godot terrain/traversal remains authoritative.

## Inherited behavior library — October 28, 2026

Owner direction: shared base mechanics with species/class/affinity-specific child
behaviors. `SightingSettings.behavior_library` now connects the editable
`resources/sol_ecology/behavior_library.tres` to live decisions. This replaces the
flat-only whitelist with reusable branches while preserving existing balance.

The decision hierarchy is: movement/home safety, urgent response, finite attention
and safe routine, then patrol/rest. The authoring hierarchy is separate:

```text
flee -> seedmote_flee -> additional authored class/affinity specializations
approach -> bramblepup_curiosity
guard -> seedmote_territorial
patrol
idle
```

Species profiles pull one to three branch IDs from this library. Roots own an
implemented primitive; children select `inherit` and cannot replace that primitive.
The shipped species children reuse existing tuning. No class/affinity-specific
ability or new temperament is assigned by this change. Territorial aggression
uses `guard`; hostile pursuit/chase still needs a separate implementation before
it can become another root. The source distinguishes guard from chase, so a guard
is not silently presented as pursuit.

Each definition has an ID, optional parent ID, independent Species IDs, Class IDs,
and Affinity IDs filters, and Priority (-100–100). Empty filters match all;
nonempty lists match any listed value. All ancestor filters must also match.
Species, class and affinity are composable constraints, not a biological
inheritance chain. Existing profiles select a broad branch, allowing its eligible
children; they may instead select a particular child branch to narrow the choice.
If no node in a selected restricted branch matches, that branch contributes no
response. Idle remains the policy's safe fallback.

One eligible descendant wins per branch: highest leaf Priority, greatest count of
nonempty filters along its ancestry, greatest depth, then alphabetical behavior
ID. Resource ordering does not affect the result. This is explicit deterministic
authoring, not random behavior selection. `selected_behaviors` in resolved ecology
reports the chosen IDs for inspection. The profile still allows at most one
response primitive, consistent with its temperament, and requires idle; selecting
two branches of the same primitive rejects rather than double-applying tuning.

Response roots/children expose inherited overrides with `-1` meaning inherit:
Reaction Distance (1–6), Flee Release Distance (2–8), Reaction Release Distance
(2–12), Comfort Distance (1–3), Approach Resume Distance (2–6), Guard Standoff
Distance (1–3), Attention Ticks (0–16), Routine Ticks (1–16), and Reposition
Cooldown Ticks (1–16). Distances use Manhattan cells; ticks are 0.75 active seconds.
Ancestors apply first, then descendants. Existing individual variation applies
afterward, preserving valid release/comfort ordering. Patrol/rest scales remain
on the species profile. Ambient roots reject unused response overrides.

Changes to nested values or filters invalidate the live ecology cache on its next
update; editor-file changes still require restarting play unless edited through
Godot's live remote resource. Existing saved deadlines finish first. Definitions
and choices are authored data, not new saved identity fields: domain 14, save
format 3 and generation 6 stay unchanged. Missing parents, cycles, duplicate IDs,
unknown primitives/selections, replaced child primitives, and invalid ranges
reject through settings validation. Safety return, collision, reservations and
warn-before-contact remain owned by the existing policies/controllers.

Read-only reference: local SolHunterSource ref
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`,
`src/systems/ai/behavior.py`, `src/systems/ai/roaming.py`,
`src/systems/world/ecology_profiles.py`, and `tests/test_ecology_profiles.py`.
These establish shared primitives, response whitelists and identity separation.
The inheritance/filter resolution is this owner's new direction, not a claim
that the source already implements that hierarchy. Local checkout cleanliness
was not independently verified. No private reference files are copied.

`tests/sol_behavior_hierarchy.gd` covers 26 checks, including real response changes,
ancestor filtering, fallback, overlap resolution, resource order, malformed graphs,
home-return priority, stable samples and nested edits in the actual loaded world.
Validation: 394 focused checks passed; the hierarchy's 26 checks also passed in
the rendered OpenGL world without engine errors. The complete pinned-engine
validator then passed 16,305 checks, import and both scene journeys
(`artifacts/sol_hierarchy_validation_retry.log`). The first broad attempt read a
temporarily invalid scene file; the successful retry includes that geometry suite.
These are functional checks on the development PC, not AYN Thor performance or
owner acceptance of species behavior feel.

## Connected profiles

Under **Expedition Tuning > Sighting Settings > Species Behavior**, Species Profiles
Enabled turns profile resolution on/off and Ecology Profiles holds editable
`SolEcologyProfile` resources under `resources/sol_ecology/`.

| Resource | Temperament / patterns | Provisional routine |
| --- | --- | --- |
| `seedmote.tres` | avoidant; patrol, idle, flee | Global patrol radius × 0.65; rest durations × 1.5. |
| `bramblepup.tres` | neutral; patrol, idle, approach | Global patrol radius × 1.3; rest durations × 0.75. |
| `trail_guard.tres` | assertive; patrol, idle, guard | Explicit guard override; global patrol/rest scales × 1 after the activity correction. |

The guard is an authored individual exception, not a species-wide change and not
an affinity-based temperament. The sighting manifest explicitly selects
`trail_guard`. Profile resolution does not alter the existing hostile flag or
encounter rules. A species without a default, or an unavailable named override,
retains its original authored reaction and global tuning.

Profiles require idle as a safe fallback, one to three distinct behaviors, and at
most one response. Avoidant permits flee; neutral permits approach or guard;
assertive permits guard. Chase, social activity, and other future mechanics are
rejected rather than exposed as unused controls. Legal home return remains a
movement safety operation regardless of the whitelist. Removing patrol stops
autonomous wandering; removing the response leaves watchful idle behavior.

## Adjustable parameters

| Profile property | Default / valid range | Runtime effect |
| --- | --- | --- |
| Profile ID / Species ID | Authored identifier, maximum 80 characters | Profile lookup and species association; does not create or rename Sol identities. |
| Species Default | true | Only one default per species; explicit overrides use their own profile key. |
| Temperament | neutral; avoidant/neutral/assertive | Validates the allowed response and supplies authored ecology classification. |
| Behaviors | patrol, idle, approach; 1–3 branch IDs | Pull eligible inherited behaviors from the library, including idle fallback. |
| Caution Variation Cells | 1 / 0–2 Manhattan cells | Stable symmetric offsets to detection, flight release, and alert release distances. |
| Spacing Variation Cells | 1 / 0–1 Manhattan cells | Stable symmetric offsets to comfort and approach-resumption distances. |
| Activity Variation | 0.25 / 0–0.75 | Symmetric fractional variation of rest duration scaling. |
| Patrol Radius Scale | 1 / 0.25–2 | Multiply global wander radius; round to cells and clamp to 1–5, then respect Home Radius. |
| Rest Duration Scale | 1 / 0.25–4 | Multiply global rest range and individual activity factor; round and clamp to 1–64 ticks. |

The three supplied resources override the routine scales as shown above. All
defaults are reversible tuning. Integer offsets are a deliberate Godot adaptation
of source variation for the current cell-based simulation. Distances are clamped
to the global valid ranges while preserving release/comfort ordering. One active
tick remains 0.75 seconds; movement speed/cadence still uses the existing global
controls. The cached resolved settings also retain all connected global controls.

Edits apply to existing loaded individuals on the next decision/view update.
Existing patrol goals and rest/settling deadlines finish under the established
policy; the next goal/rest uses new values. A reduced Home Radius still causes
legal gradual return. Invalid profiles or duplicate keys/defaults suspend local
AI and hide invalid views under existing settings validation. Profile resources
are shared authoring defaults; duplicate a resource when creating an independent
override. No affinity, class, ownership, combat stat, or relationship tuning is
introduced by the original phase-4 profiles. The inherited library above adds
optional identity filters without assigning new class/affinity mechanics.

## Stable traits and ownership

`SolEcologyProfile` contains validated authoring data. `SolEcology` resolves the
profile, generates independent identity samples, and enforces the behavior set
around the existing roaming/reaction policies. The sighting controller caches
resolved settings and invalidates them when exported global/profile properties
change. Each decision still commits through `ExpeditionState`; navigation and
encounter ownership remain separate.

Three SHA-256 streams in the fixed `sol-ecology-v1` namespace derive caution,
spacing, and activity samples from the saved individual ID alone. This consumes
no global RNG and depends on neither affinity/class nor visibility, visit order,
resource enumeration order, or load timing. Trait samples survive save/load and
view reconstruction by derivation; no new save schema or identity inputs are
needed. The profile delivery used domain 12; the subsequent
[natural movement pass](sol-natural-movement.md) uses domain 13 for its patrol
counter while retaining these trait streams. The [activity correction](sol-activity.md)
now uses domain 14 for attention/retry state. Changing a profile changes live balance
values, not the individual's samples. Changing the sample namespace/derivation
requires an explicit versioned identity-compatibility decision, not a balance edit.

## Source and validation

Read SolHunterSource `115f3e87acc1716c7113523567c01e1666681885`,
`src/systems/world/ecology_profiles.py`, through the GitHub connector. Local
reference checkout `d6f0902d77ed46a2f7d251c354792a4cc9210bc4` supplied the full
profile validator, trait resolution, `src/systems/ai/roaming.py` callers, and
`tests/test_ecology_profiles.py`. These establish small whitelisted behavior sets,
temperament validation, bounded stable identity variation, and separation from
combat/capture identity. The supplied Godot routine defaults and integer offsets
are provisional authoring, not a claim that the source fixed these species values.
No private catalog or source documents are copied into this repository.

`tests/sol_ecology.gd` covers profile validation, fixed identity-stream output,
variation bounds and real decision differences, affinity/class independence,
global RNG isolation, named overrides, live cache invalidation, actual save/load,
real patrol/idle behavior, invalid runtime tuning, and unchanged combat/identity
state. Earlier local movement/reaction suites disable profiles to isolate their
global-setting contracts. Phase-4 defaults remain enabled in normal exploration.
Rendered capture: `artifacts/ecology/species.png`. Final results are recorded in
the roadmap; owner playtesting remains the acceptance for behavior feel.
