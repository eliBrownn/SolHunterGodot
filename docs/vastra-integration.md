# Vastra integration

## Fine generation flow — November 1, 2026

Owner direction divides grass/foliage generation into smaller real credits at
the same existing units/second and ambient-concentration scaling. Exploration
services bounded round-robin generation between ecology ticks at 0.125-second
clock steps (six per existing 0.75-second tick). The existing ecology/transfer
tick, conserved transfer packet amounts and live refill-rate setting remain
unchanged. Tick servicing credits only time not already covered by fine refill.
Ordinary fill totals match the old schedule at every original tick boundary.

Optional per-node `refill_since` records the exact credited generation time in
saves. Admission validates it against saved active time; normalization preserves
it through JSON. Pausing cannot add credits, inactive reactivation receives no
offline grant, and mid-step reload retains the uncredited fractional tail.
Incoming root reservations and queued outgoing stock still reserve capacity.
Generation remains canonical per cell; adding foliage clumps or scaling bodies
cannot multiply it. Leaf and ground appearance sample the finer generation clock.

Read-only SolHunterSource review revisited `src/systems/world/vastra_simulation.py`
and `vastra.py`, preserving bounded natural updates and separate concentration/
overload ownership from the existing pinned reconciliation. This new cadence is
the owner's explicit direction, using Godot's existing saved-clock plant ledger.

Focused Godot 4.7.2 checks cover equal-rate full accumulation, fractional
save/load, pause/reactivation and double-sized foliage: `foliage_generation_flow`
passes; existing plant circulation passes 950 checks, foliage rollout 9,150,
reserve contracts 44, leaf/ground links 35 and the rendered 3D scene 65.
The 153-definition runtime palette was rebuilt. Local receipts use
`artifacts/foliage_flow_*.log` and `artifacts/foliage_generation_flow.log`.

## Tree storage — October 31, 2026

Owner direction raises tree storage to **1,000 Vastra**. The saved plant policy's
`tree_capacity` owns that limit independently of the ordinary plant threshold
and conserved packet amount (100 by default). Arrival credit, ambient absorption,
save admission and inspection all use the same kind-specific capacity. Only
energy exceeding tree capacity enters root stock. Relay packet size/cadence,
root feeding and the 0–100 ambient concentration scale retain their contracts.
Policies saved before this field existed use the owner-approved 1,000 tree default;
explicit authored capacities remain captured in saves. Trees are not refilled
by this limit change. This supersedes earlier shared 100-unit tree-cap notes.

Read-only reference review revisited local SolHunterSource's
`src/systems/world/vastra.py` and `tests/test_vastra_foundation.py`, retaining
their separate concentration/overload and read-only inspection invariants.
The existing pinned `d6f0902d77ed46a2f7d251c354792a4cc9210bc4` reconciliation below
remains the baseline; the owner's explicit instruction supplies this storage limit.

Focused validation with Godot 4.7.2: `tests/plant_vastra.gd` passed 853 checks,
`tests/ambient_vastra.gd` passed 30, `tests/inspection_card.gd` passed 27 with
a rendered combined card, and `tests/world_interactions.gd` passed 32.
The complete controller expedition suite now passes 58 checks, including
examination and read-only battle-log navigation. Its stale `More` selector was
updated to the current battle menu; the three cascading failures are resolved.
Import/parse and scoped whitespace checks passed. Local receipts live under
`artifacts/examine_*.log`.

## Ambient overflow — October 31, 2026

The owner approved adjustable **1 transferred unit = 1 concentration point** as
the provisional conversion. This completes the approved overflow path for isolated
plants and excess tree root stock. Existing unbiased nearby-tree selection and
root feeding remain first; an isolated full plant exports only when its complete
geographic recipient query contains no eligible tree. Unknown geography defers it.

`ExpeditionState` is the sole writer. `PlantVastra` records exported units separately
from expenditure; `AmbientVastra` owns saved packets and undelivered backlog, not
another tile reserve. Export equals receipt, and receipt equals committed units
plus pending units. Concentration stays at or below 100; overflow never changes
ecological overload. Fractional conversion residue waits rather than disappearing.
Existing ambient-derived refill remains the previously approved source; this change
does not invent a debit from tile concentration during plant absorption.

Initial emissions split equally across four cardinal directions. Saturated tiles
relay their remaining packet at the captured finite transfer speed. A saved rotating
direction per visited tile avoids a fixed-direction dead end. Each tick services at
most the configured arrivals and relay visits (default 64 each), plus a bounded
flight-clock pass for combat ownership. Caps are 2,048 flights and 8,192 sparse relay
records. At a technical cap, packets/backlog remain saved and sources retain rejected
exports. No catch-up charge or whole-world flood search is introduced. Local combat
ownership freezes its paths and concentration commits; other areas continue.

The renderer consumes actual ambient packets alongside object transfers. Tile
endpoints follow the uploaded ground/water surface; object endpoints still require
their canonical rendered anatomy. Retired pond artwork remains retired and aquatic
replacement remains deferred under the current project standard. Canonical wetland
membership and simulation do not depend on a replacement body being visible.

`VastraSettings` exposes the overflow switch, concentration-per-unit conversion and
work budget, captured once per expedition. Domain save version **22** and plant
ledger version **3** include conserved overflow; older development saves require a
new expedition. Outer save format is unchanged. Source evidence remains the read-only
Vastra foundation at SolHunterSource commit
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`; the Bible and owner decision above govern
the new routing/accounting rules rather than importing legacy generation.

`tests/ambient_vastra.gd` covers conservation, finite arrivals, exact-once service,
JSON continuation, corruption rejection, adjustable conversion with residue,
saturation routing, local combat freeze and bounded backpressure. The generated
six-biome audit is `tools/audit_vastra_biomes.gd`; ignored reports live under
`artifacts/nature_alpha/`. Generation 16 / seed 2601026 passes strict snapshots for
all six sampled areas, with actual water and sand transfers after previously zero
circulation. This is representative coverage, not an exhaustive world-coordinate
or target-device claim.

## Approved ecology delivery — October 31, 2026

Planned extension under the [Bible](reference/SolHunter_Worldbuilding_Bible.md),
supporting [N1/N4/N5](world-exploration-roadmap.md#nature-delivery-sequence).
Earlier implementation checkpoints remain baseline evidence, not completion of
these approved rules. Keep one writer at the expedition transaction boundary.

| Slice | Required behavior | Acceptance before connected rollout |
| --- | --- | --- |
| V1: reserve presentation | Plant/tree leaf saturation and lifted posture read individual reserve; depleted is pastel, not necessarily damaged | Known low/mid/full states, species palette retained, wind additive, clumps/camera cannot multiply reserves |
| V2: circulation | Plants/trees emit actual surplus outward; tiles cap ambient concentration at 100 and spread incoming excess outward at finite speed until capacity exists | Conservation across sources, destinations and in-flight/backlog; saturated neighborhoods, unload/load, retry and bounded work; no silent energy loss |
| V3: signal overload | Persistent disturbance produces alarms faster than resolution; information creates no energy | Original identity/expiry/replay retained; removing disturbance settles signals; Regulators/healing accelerate recovery; no false new alarms from own response |
| V4: escalation | Disruption -> alarms -> response -> aggressive release -> ecological overload -> storm risk | Every causal step observable; no guarantee of a storm; ordinary overflow remains safe; source removal does not erase existing ecological damage |
| V5: combat boundary | Separate confrontation-based battle storms from environmental 3x3/chance storms | Battle-local freeze/ownership and current-world completion agree with C4/C5; no double repair, origin or reward |

Stored reserves, ambient concentration, signed ecological overload and signal
overload remain separate. Define ambient debit and finite transfer/backlog units
before V2: existing concentration-scaled grass refill does not itself implement
conserved ambient harvesting. No global scan, extra tile reserve or automatic
fullness-to-overload conversion. Overflow cannot independently create distortion.

Signal settling, ecological recovery, temporary-condition recovery and permanent
affinity imprints have distinct lifetimes. Exposure uses turbulence/protection;
high reserve is not itself damage. Natural weather remains a separate owner.
Detonation requires Sol instability AND an exceptional severe environmental surge
or deliberate core interference. It can injure; death is exceptional and the
starter is protected. Specific trigger thresholds, energy source, prevention and
injury/recovery consequences remain blocked authoring work, not production pilot
defaults. Learned warning recognition does not imply a guaranteed intervention
window. Keep current storm activation defaults until the lifecycle is delivered.

Reference baseline: this chat inspected source vastra.py at
`115f3e87acc1716c7113523567c01e1666681885`; it separates concentration/overload
but has unsigned legacy storage and no approved new overflow/signal mechanics.
Later owner rules govern; preserve existing signed recovery and accounting
evidence below. Consult callers/tests before implementation, not a literal port.

## Generic foliage on existing emanator cells — October 30, 2026

The generic-foliage rollout uses the existing grass/emanator cell owner. Grass
blades and a selected foliage body share `flora_id`, region, reserve and activity;
visual patches never admit extra records. The foliage body supplies its ground
intake/emission anatomy to the same presentation endpoint, with grass kept around
it. Receiver specialists keep their own cells and anchors clear. Unclassed
receiving foliage remains a draft anatomy study, not a new live receiver rule.
Coverage, model size alternatives and camera/streaming reconstruction do not
change membership, reserves or transactions. The source evidence, placement
contract and focused validation are indexed in the current
[foliage rollout](procedural-plants.md#generic-foliage-world-rollout--october-30-2026).

Performance follow-up: flora neighbor queries use bounded, kind-indexed caches
invalidated by completed-region admission and eviction. Missing neighborhoods
still return null; callers receive independent results. Active IDs are cached
until membership/focus changes, and identical active sets do not rebuild the
expedition's regional index. These are derived lookups, not new ecology rules.
Conserved-transfer curves are cached by endpoints, path seed and geometry tuning,
with a 256-entry bound and terrain/rebuild invalidation. Caller copies protect
cached paths from root-path adjustments. See the
[optimization evidence](research/world-optimization.md).

## Generated vegetation registration and system hierarchy

Owner requirement, October 29, 2026: **every generated living plant belongs to
Vastra through its canonical geographic cell**. This includes grass, flowers,
shrubs, ferns, fungi used as living vegetation, reeds/rushes, trees, and the
existing authored pond's lilies/bank plants. This is a required integration
contract for future plant content, model replacements and biome additions.

Plants are infrastructure for circulation, root recipients, paid repair and the
classified vegetation/Vessel ecology. Missing registration leaves visible life
outside those systems; registering each graphical clump separately would instead
invent extra reserves, charge and repair capacity. Neither outcome is acceptable.
Membership does not mean a plant is currently charged, acting, visible or within
the bounded active simulation area.

| Owner / hierarchy | Responsibility and required link |
| --- | --- |
| Godot geography → generated habitat/site → absolute cell (`WorldTerrain`) | Decides canonical flora membership through `flora_kind`; all four land biomes participate. Protected access and slope admission remain mandatory. |
| Geographic 12-cell region → flora definition (`FloraCatalog`) | Enumerates stable cell IDs and kinds without needing render chunks. Complete neighborhoods prevent camera-order bias; active area plus tree halo bounds work. |
| Expedition → saved flora policy/ledger → cell reserve (`ExpeditionState`) | Sole live/saved writer; admits each definition once at zero reserve, retains identity and conserved energy through reload, eviction and reactivation. |
| `FloraTraits`, `PlantVastra` and `VesselEcology` | Resolve existing functional roles and paid, bounded transactions using those same registered cells. Affinity remains independently owned. |
| Scenery resource → generated instance → chunk endpoint | Explicit `NatureAssetEntry.living` declares vegetation; each living endpoint carries `flora_id = FloraCatalog.id_for(cell)`. Many clumps in a cell share its reserve. Chunk ownership is rendering ownership only. |
| Vastra presentation | Reads saved transfers and endpoint anchors. Particle density, visibility, camera, foliage toggles and model filenames cannot register energy or change recipients. |

`NatureComposition` rejects living dressing outside canonical membership. Ground
specialists and meadow grass already consume `flora_kind`; fallback undergrowth
now does too. Living membership no longer uses botanical filename keywords, so
numbered/custom replacement models remain connected. Rocks, fallen logs and dead
wood use explicit nonliving entries; tree art uses `NatureSettings.nonliving_trees`.
A dead visual variant does not delete its canonical tree-slot state or turn the
render palette into an ecological writer.

The fixed `resources/scenery/bounded_composition.tres` pond placement definition
is also generation evidence for its existing water/bank vegetation.
`WorldTerrain.authored_wetland_flora` reconstructs those exact admitted living
placements with rendering absent. Bare water/sand gains no blanket terrestrial
population. This narrow authored exception preserves its existing coordinates,
footprint, pond level and clearance checks; active art settings do not own the
registration. Aquatic/bank bodies retain their original art rather than being
replaced by a land specialist. Changes to this fixed definition's living coverage
must be reviewed as generation/admission changes, not merely cosmetic edits.

Registration remains lazy and budgeted: generated definitions outside the active
area need not all occupy the saved ledger at once. Trees in the query halo and
plants in the active geographic area follow the established admission policy.
No offline refill, duplicate cell reserves, global unbounded simulation, new
plant abilities or save-format migration is introduced by fixing missing coverage.
Previously omitted generated wetland plants enter at zero on ordinary admission.

Content acceptance must prove arbitrary asset names register, nonliving art does
not, each generated living endpoint resolves to its canonical cell, clump count
cannot duplicate a reserve, and camera-free catalogue admission plus save/load
preserve membership. Existing energy/repair/root/feeding checks remain required
when those mechanics change. See `tests/plant_vastra.gd` and
`tests/biome_scenery.gd` for the connected coverage.

Source reference rechecked read-only at SolHunterSource commit
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`: `vastra.py` and
`tests/test_vastra_foundation.py` preserve sparse state, detached reads and
validated persistence. Existing plant-cycle reconciliation below still applies;
this work fixes generated membership and ownership, without importing another
world generator or inventing new circulation rules.

### Registration verification — October 29, 2026

Godot 4.7.2: plant hierarchy/circulation/save journey **812 checks passed**, including
the real Direct3D 12 renderer; generated biome coverage **3,892 passed**; Vessel
ecology **73 passed**; Vastra integration **38 passed**. The plant suite now uses
`-- --capture-plants`, avoiding the production scene's separate `--capture`
routine, which otherwise rebuilt fixtures during the rendered journey. Captures
under `artifacts/plant-vastra/` cover charge, travel, arrival and outward root flow.
Hierarchy documentation links and scoped whitespace checks passed.

The final editor import found an unrelated mixed tab/space parse error in
`tools/development_workstation.gd:185`. The affected plant/biome/Vastra suites
above pass; this is not a claim that the full-project import or full validator
passes. The workstation file was left unchanged by that registration work.
The later [temporary lab-world integration](development-workstation.md#temporary-lab-world-from-the-game)
corrected its indentation; editor import then passed. The earlier blocker is
historical, not a remaining import failure.

## Root overflow and Sol feeding — October 29, 2026

Owner direction: object reserves must not accumulate beyond 100; trees expel excess
around them like roots, nearby Sols absorb it as food, and visible strands carry
actual quantities from source to destination. This is a real conservation change,
not a cosmetic source of new energy. The owner explicitly approved the save-format
change and the resulting need for a new expedition with older development saves.

The implementation caps each plant/tree's stored reserve at its configured
threshold (100 by default). Preserve received excess in a separate saved stock
around a tree's roots. Root strands debit that stock and deliver bounded, finite
packets to canonical nearby plants; incoming root packets reserve capacity so
ambient refill cannot fill their destination first. Nearby available wild Sols
and the active field companion consume this excess at a bounded provisional rate,
with the consumed food recorded against the existing individual ID. This first
feeding slice grants no HP, XP, stat bonuses or invented hunger/starvation rules.

Accounting must include object reserves, root stock, in-flight packets, paid repair
and energy eaten by Sols. Recipient credit occurs once on arrival; unavailable
destinations or work-budget limits must retain energy safely. Camera, visibility,
particle budget, pause and save/load cannot duplicate or destroy energy.

Saved format: expedition snapshot 20 and plant ledger 2; per-node
`roots`, a `fed` map by Sol identity, a root/ordinary packet discriminator and saved
root/feeding rates and radius. Provisional defaults: 8 units/active second
root distribution, 4 units/active second per Sol, 3-cell feeding radius. Existing
ordinary tree recipient selection remains unbiased. Existing development saves
are rejected with the current new-expedition message, with no deletion or
automatic rewrite. This follows PROJECT_STANDARD.md's October 27 policy that old
test saves are disposable and migrations are out of scope. No old save is deleted
or automatically rewritten. The field companion uses the player's authoritative
field cell as its feeding anchor; wild Sols use saved roaming cells. Stored,
sealed, unavailable and battling individuals do not feed from the field.

Strand heads use saved departure/arrival ticks and reach the actual recipient
before the tail clears. Finite filaments taper with metric distance; longer routes
become thinner while retaining the broader irregular wiggle envelope. Pixel-sized
coverage preserves a visible arrival. Real root packets use ground-level endpoints
and curves rather than the tree-crown attachment mode.

Source reconciliation: inspected SolHunterSource at
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`, including
`src/systems/world/vastra.py`, `vastra_simulation.py`,
`tests/test_vastra_foundation.py` and targeted systems/tests/docs searches. Its
concentration/overload separation, sparse read-only inspection and bounded
transactions remain relevant. No tree-root overflow/Sol food implementation was
found in that targeted lookup. The owner's direction supplies the new rule;
Godot retains generation authority. Required checks are conservation through
simultaneous arrivals, excess expulsion, plant capacity reservations, bounded
nearby feeding, pause/inactive behavior, exactly-once delivery, save validation,
JSON mid-flight resume and a rendered root-transfer review. This supersedes the
version-19 notes below that allowed reserves over capacity as queued relay energy.

Validation with Godot 4.7.2: plant/root/feeding journey 330 checks, current rendering
295, inspection 22, persistent foundation 76 and owned companion 40, all passing.
The final Direct3D 12 root journey completed with no engine/script errors; captures
under `artifacts/plant-vastra/`, including `root-overflow.png`, were inspected.
`artifacts/vastra-roots-render.log` records the final 330-check rendered run.
The live save/load test needed access to Godot's disposable `user://` test-save
folder; its successful retry is `artifacts/vastra-root-persistence.log`.
The scoped whitespace check passed. These are focused checks, not a full-suite
or target-device pass. Earlier full-suite limitations remain documented below.

If the arrival work budget is busy, the packet remains visible at its destination
until the actual credit, then clears its tail from that delivery time. These
rendering annotations are derived and never saved as extra energy transactions.

Owner direction: [October 28 combat/restoration retcon](decisions/2026-10-28-vastra-combat-and-restoration.md).
This connects the current expedition and battle systems; it does not declare the
storm rescue or D2/D6 complete.

## Connected behavior

`SolMove` exports whether an ability is Vastra-powered, whether an otherwise
support/terrain effect is aggressive, and positive overload/restoration points.
Damage, poison and debuff abilities are inherently aggressive when Vastra-powered.
Offensive terrain entries in the shared move library are marked explicitly.
Default move values are two overload points or four restoration points per
actually affected tile, independent of damage/HP healed. Values are provisional.
Non-Vastra abilities produce no Vastra change. Healing at full HP is legal while
it can restore the environment; a fully saturated restorative tile with no HP
healing available remains a no-effect action. Normal action/turn costs still apply.

`TacticalBattle` tracks signed tile values as abilities resolve, clamped per
application to the development envelope -100..100. It does not add the actor's
tile to target effects or double-count repeated cells in an area. Conditions,
affinity imprints and overload remain independent channels. Enemy abilities use
the same path. Illegal actions produce no environmental changes.

Battle outcome persistence atomically commits the signed values with party,
capture/progression and imprints for victory, exhaustion, capture and retreat.
Failed commits retain the existing retry flow; replaying a completed serial cannot
apply changes again. Concentration is preserved, including sparse partial deltas.
World-state schema 16 identifies signed overload; earlier positive-only state
remains readable through the pre-existing loader. Negative values marked as older
schemas are invalid. No new legacy migration is implemented.

Natural recovery uses the saved bounded queue and active exploration clock.
Both signs relax toward zero without crossing it. A combat sign change starts a
new relaxation epoch; repeated effects of the same sign retain elapsed progress.
Pause and offline time do not grant progress. Human harvesting/disturbance also
works on restorative tiles and retains receipt replay protection.

Restorative assistance uses `maximum_bonus * magnitude / (magnitude + half_strength)`.
It accelerates existing lingering terrain-condition recovery and vacant authored
Sol-home recovery, without spawning wildlife from a read or creating carrying
capacity. Terrain condition stage intervals are rounded upward, minimum one tick.
Wildlife assistance services at most 32 saved homes every eight active ticks,
reducing pending deadlines by the rounded-down bonus. Saved same-tick service
prevents duplicate assistance on reload. This is a bounded first expression of
habitat/population recovery, not a new world-wide habitat-health simulation.

Outgoing direct damage receives a provisional linear concentration bonus only
when ground affinity matches the individual Sol's affinity. It never changes
permanent stats, and move affinity does not substitute for individual affinity.
The current tactical system uses one occupied tile per unit. Broader footprint
combat remains future work. Existing class bonuses remain separate.

## Presentation

October 29 world foundation: geographic cells (12 terrain cells per side) own
vegetation-supported regions independently of render chunks and explorer position.
Only complete scenery coverage is admitted. Stable sampling selects up to 16
vegetation anchors per geographic owner; Sols only clear the visual field. Loaded
scenery supplies evidence of actual living plants, never ecological writes.

The renderer selects a bounded set of regions for the camera, retains seeded
geometry and region-owned phases, and converts absolute positions to the floating
render origin. Selection does not change retained region membership, density or
phase. Broad quiet refractive volumes surround shared living groups; smaller
connections bridge groups. Separate geometry/materials carry intermittent wisps.
The carrier never oscillates. Local concentration supplies strength and inward
signal potential, local affinity supplies complementary optics, and existing sun
and saved active time supply lighting and motion. Soft depth/camera intersections
replace the removed explorer-centered radius fade. Raw concentration and revealed
field heatmaps remain separate, read-only diagnostics.

Inspection shows signed overload and describes restorative conditions. Matching
combat affinity retains the short rising current and percentage cue. See the
[resource evaluation](research/vastra-resource-evaluation.md#world-foundation-delivery)
for current validation and performance evidence. Later optimization notes below
are historical measurements of the replaced renderer, not current performance.

## Tuning and acceptance

`resources/vastra_settings.tres` connects natural recovery, restorative assistance,
environmental damage scaling and local current settings. `resources/move_library.tres`
connects per-ability effects. Restart to change current enable/count; other visual settings refresh within
0.5 seconds. The live simulation reads settings on active ticks. Saved movebooks retain their authored
move snapshots; omitted new fields use documented defaults. Start a fresh
expedition to review newly authored move flags in the library.

`tests/vastra_integration.gd` covers signed persistence, natural relaxation,
human receipt replay, healing at full HP, legal/illegal affected areas, independent
concentration, atomic battle results, diminishing recovery and signed inspection.
It is registered in `tools/validate.ps1`; results are recorded after execution.

### October 28 validation checkpoint

Godot 4.7.2 stable import completed. Eight focused headless suites passed with
459 checks and zero failures: Vastra integration (38), natural Vastra (93), human
activity (80), affinity moves (70), wild population recovery (53), combat
sequencing (39), combat consequences (64), and inspection cards (22).

The complete validator did not pass: it stopped at three movement/action-budget
assertions in `first_playable_battle.gd` while another active chat changed the
combat action-point system. A separate `battle_feedback.gd` run reported three
failures in expected heal/enemy-damage cue counts, expected post-field enemy
damage, and the tied-affinity recap. These fixtures depend on the changing turn
flow; their failures are recorded rather than changing that other work here.
Source hashes in `artifacts/vastra-validation-start.json` and
`artifacts/vastra-validation-drift.json` identify concurrent code/test drift.
Results describe the evolving shared checkout, not a frozen-revision full pass.

A rendered Direct3D 12 / Forward+ check on the development RTX 3070 completed
without engine/script errors; the inspected capture is
`artifacts/vastra-world-review.png`. It uses explicit runtime fixture areas at
positive and negative overload, ordinary render settings, and no player-save
writes. Smooth/surging currents and negative inspection readings were visible.
This is visual verification, not owner art acceptance, a frame-time comparison
or AYN Thor acceptance. The authored opening remains unimplemented below.

The storm opening, mask/exposure/failure rules, the chosen rescue trio, companion
discovery sequence, refuge barrier visuals, procedural storms and spatial
propagation remain subsequent connected content/systems work. Their approved
direction is retained in the decision record. No exposure rules were invented.

## Current-rendering optimization — October 28

The default 24 ribbons now share one MultiMesh and material, retaining independent
terrain anchors, phases, affinity colors, strength and disturbance. A single
shader-clock update animates the batch; the same shader keeps the unbatched combat
cue path. Explicit batch bounds include the maximum animated displacement. Instance transforms
remain local to the current sample center so distant world coordinates do not
reduce GPU animation precision or inflate culling bounds.

Generated concentration, height and placement are cached in a bounded 256-entry
FIFO. New terrain and rebuilds invalidate that derived cache. Live signed values
remain uncached: local environment changes, battle outcomes, pending combat actions,
state replacement and movement invalidate readings. Distant changes do not.
Idle frames update only animation, while in-place radius, opacity, refraction and
palette edits are detected within 0.5 seconds. Restart to change enable/count.
Sparse local queries inspect saved changes instead of probing empty coordinates;
dense queries retain the spatial bound and both paths retain the same row order.

`godot --headless --path . --script tools/profile_vastra.gd -- --tag=current`
measures 600 current-processing calls
after 120 warmup calls for each synthetic workload, at seed 17 and default settings.
Active time advances outside the timed section. Travel changes the sample center
every six calls; it is not a navigated journey. A paired run on the development
PC, Godot 4.7.2 stable, measured:

| Current processing | Before mean | After mean | Before p95 | After p95 |
| --- | ---: | ---: | ---: | ---: |
| Stationary | 50.81 µs | 1.48 µs | 17 µs | 2 µs |
| Synthetic travel | 193.25 µs | 29.64 µs | 1082 µs | 160 µs |
| Stationary disturbed area | 52.82 µs | 1.49 µs | 18 µs | 2 µs |

This is approximately 97% less current-processing CPU time when stationary and
85% less during this travel workload. Reports are in
`artifacts/vastra-optimization/before.json` and `after.json`. These are single paired
microbenchmarks on a non-isolated development desktop, not whole-frame FPS,
GPU-time or AYN Thor claims. World generation, saves, combat balance and recovery
rates are unchanged by the optimization.

`tests/vastra_currents.gd` covers sparse/dense equivalence, cache bounds and
invalidation, read-only behavior, state replacement and pending combat effects.
Rendered checks also read instance phase/placement and verify animation bounds.
It is registered in the shared validator. The existing integration, natural
recovery and persistent-foundation checks remain the relevant gameplay regressions.
Godot import passed; the focused runs passed 15 headless current checks, 18
rendered current checks, 38 Vastra integration checks, 93 natural recovery checks
and 76 persistent-foundation checks. The new rendered capture is
`artifacts/vastra-optimization/rendered.png`. The earlier full-suite limitations
remain recorded above; this optimization did not rerun unrelated combat suites.


October 29 owner direction reserves the asset at a strand's animated arrival end
as a future Vastra charge generator. The presentation exposes unique destination
references and a future-generator role, while rates, capacity, timing, storage,
persistent asset admission and gameplay effects remain open. No charge is generated
from render frames, visible strands or particle arrivals. See the
[height-tier visual slice](vastra-visual-roadmap.md#height-tier-strands-motes-and-deferred-charge-sources--october-29-2026)
for the source reconciliation, hook contract and current implementation limits.


## Plant energy circulation and natural repair — October 29, 2026

Owner direction establishes a stored-energy cycle: plants refill gradually from
ambient Vastra; reaching 100 can send energy to a nearby tree. Trees relay it onward.
Target selection must not favor low reserves, damage, stress or other need. The
owner clarified that “auto-level” means natural balance and repair, not growth/XP
levels. Preserve the existing ribbon, peak, tail, refraction, ripple and mote look.
This supersedes both the old concentration-seeking cosmetic flow and the deferred
“destination generates charge” label above.

### Owners and identities

`WorldTerrain.flora_kind` owns canonical living-plant/tree admission from existing
terrain decisions. One generated cell represents one grass/plant reserve or tree;
rendered clump count does not multiply energy. All four terrestrial biomes
participate, including Heath and Marsh. This is
independent of the biome's cosmetic grass/plant palette. Water and sand admit
only the fixed authored wetland's actual living placements, as specified in the
[registration contract](#generated-vegetation-registration-and-system-hierarchy). The old Meadow/Forest-only admission filter was
removed to correct biome sections with no plant Vastra activity.
`FloraCatalog` prepares complete
12-cell geographic regions within the existing frame budget, reusing exact prepared
terrain cells when available. Its queries are camera independent. Nearby candidate
search waits for every intersecting region, so partial scenery loading cannot bias
recipient choice. Halo admission stores only trees; ground plants are admitted in
the player's active geographic area. Derived catalogue memory is bounded.

`ExpeditionState` is the sole live/saved writer. `PlantVastra` prepares bounded
transactions; plants have stable world-context cell IDs, reserves, timestamps and
per-source emission serials. The saved policy and in-flight packets belong to the
expedition. Camera movement, zoom, foliage settings, current visibility and particle
count cannot emit or credit a packet. Explicit art studies use `study_mode`; normal
play never uses their autonomous prototype pulses.

### Initial policy — provisional balance

- A source reaches 100, debits one 100-unit packet and retains any queued excess.
  A source with no eligible tree keeps its reserve. All eligible nearby trees have
  equal selection probability; the deterministic seed/source/emission serial makes
  choices replayable without reading target energy or damage.
- Ambient concentration scales refill rate up to a provisional four units per
  active second at concentration 100. A reserve at/above threshold absorbs no more
  ambient energy until it has room. Concentration is an availability reading, not
  the same stored-energy unit, and is not decremented by this first refill model.
- Local repair spends ten reserve units per positive overload point, at most one
  point per serviced plant per activity tick. Repair happens before onward transfer.
  Negative restorative overload, affinity and unrelated habitat conditions are not
  consumed or rewritten. Existing natural recovery remains in force.
- Trees accept incoming packets even when full; excess is queued relay energy,
  with at most one emission per source visit/tick. Finite travel time prevents an
  instantaneous chain or loop. This is not a demand-routing system or a promise of
  a finalized global ecological equilibrium.
- Provisional travel speed is 0.35 cells per active second. The actual arrival tick
  is saved; the finite visual pulse uses that same timing and increasing phase.
  A packet is credited exactly once on arrival, independently of whether it was
  visible. Tails may remain briefly after the head arrives, without repeating it.
- Default active service is the player's current region plus one neighboring ring,
  with a 64-source/64-arrival work budget per activity tick. This scope depends on
  player geography, not the camera. Inactive-area reserves and incoming energy are
  retained; reactivation grants no offline/inactive refill. The scope is bounded
  active simulation, not an unlimited full-world/offline simulation.
- Plants start with zero reserve on first canonical admission. Numerical values are
  typed Inspector tuning captured for new expeditions; loaded expeditions keep their
  saved policy. Transfer height tiers retain approximately three-cell plant reach
  and fifteen-cell tree reach. Graphical clump positions resolve the admitted cell
  into the already approved ground/base/crown presentation.

The ledger accounts for all absorbed energy as stored reserve + in-flight energy +
energy spent repairing. Save validation rejects a broken balance, nonfinite values,
unknown nodes, invalid flight times, duplicate deliveries and malformed policy.
Snapshot version 19 adds this ledger. Earlier development snapshots are rejected
through the existing incompatible-save/new-expedition path; no user save file is
rewritten or migrated automatically.

### Mechanics evidence

Read-only source reconciliation used SolHunterSource's local
`development/world-redesign-0.2` ref at
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`, inspecting
`src/systems/world/vastra.py`, `vastra_simulation.py`, the activity caller in
`src/core/game.py`, `tests/test_vastra_foundation.py` and the regional equilibrium
audit. Existing source separates concentration/overload, keeps ambient reads
read-only and bounds active-clock updates. A targeted search of source, docs and
tests found no plant-at-100/tree-transfer implementation to port. The new owner
rule therefore supplies this missing mechanic; rates and costs above remain
provisional. The reference checkout's working-tree cleanliness was not verified.
Godot retains generation authority; no source-repository files were copied or edited.

### Review path

`tests/plant_vastra.gd` covers threshold gating, unbiased full-tree eligibility,
conserved transfers and relay cycles, paid repair, negative-overload preservation,
refill/pause/reactivation, JSON mid-flight resume, corrupt-ledger rejection and
complete deterministic catalogue admission. Its connected real-scene journey tests
99 -> charge -> emission -> finite visible strand -> one arrival credit. Run it with
Direct3D 12 and `-- --capture-plants` for the actual reserve-99, in-transit and arrival
captures under `artifacts/plant-vastra/`. The shared validator now includes it.

Final balance, larger-world service/device budgets and further plant/terrain repair
types remain open. No RPG levels, automatic Sol effects, affinity transfer, passive
human rewards, harvesting or new ecological-overload source is introduced.

### Mechanical activation validation

Godot 4.7.2 import passed. The final Direct3D 12 connected plant suite passed
282 checks with zero failures, including the populated active-clock network and
canonical save validation. The art-study current suite passed 295 checks in the
broader run. Script ownership passed with 155 mapped scripts and 155 UID sidecars;
the scoped whitespace check passed. Captures were inspected under
`artifacts/plant-vastra/`.

The complete validator is not a clean pass. It initially stopped after the stats
suite printed 3,686 passing checks but returned an unsuccessful process exit;
an isolated retry passed those checks and exited zero. Continuing the remaining
suites passed combat polish (24), then stopped at two existing enemy-hit/retained-HP
expectations in `tests/combat_sequencing.gd` (39 checks, two failures). That live
fixture keeps world simulation in smoke mode, so canonical plant admission and
circulation remain inactive. Combat files and assertions were not changed for
this feature. Logs are `full-validation.log`, `stats-exit.log`,
`remaining-validation.log` and `final-focused.log` under the same artifact folder.
Later suites were not executed; no full-suite or device-performance acceptance
is claimed.


## Vegetation and Vessel runtime pilot — October 29, 2026

Owner authorized implementation after the vegetation/Vessel design review, then
supplied tropical plants as placeholders. This is a connected prototype under the
Bible's design, not final ecology balance, species art or a completed storm system.

`FloraTraits` assigns stable grass/receiver classes independently of affinity and
rendered clump count. In activated expeditions only grass takes the existing
ambient refill; trees and specialists receive transfers. The current refill model
still scales from concentration without debiting ambient concentration; a shared
regional source-allocation budget remains future work. Generic baseline repair,
reserve cap 100, root overflow, Sol feeding and unbiased tree recipients remain.

`VesselEcology` prepares transactions; `ExpeditionState` is the only writer.
One resident group is admitted per complete active flora region, anchored to a
stable grass cell. Defaults service up to nine groups; at most 128 persistent
groups are admitted. No admissions beyond that safety cap are implied. Traveling
groups, splitting/merging and individual lifecycle are not delivered. The swarm's
reserve is capped at 100. Feeding prefers root surplus and preserves 50 units of
source reserve when drawing plant energy, preventing first-transfer starvation.

Plant expenditure includes energy transferred into swarms. The separate swarm
ledger accounts for that draw as retained swarm energy plus response consumption.
For combined accounting, subtract swarm draw from plant expenditure before adding
swarm reserves/consumption; it is not a second energy source. Mender and other
specialist costs remain direct plant expenditure. Rendering cannot change either
ledger. Specialist work rotates with the existing flora cursor; nearby queries
reuse canonical region indexes rather than scanning all nodes per group.

First class functions are bounded: Menders spend two units per extra positive
local overload point repaired; Wardens spend one per intercepted nearby Vessel
discharge point; Regulators spend one per serviced response tick and help it
settle after three response ticks. These are prototype constants. Warden protection
does not cancel direct combat ability consequences; Regulator delivery-cadence
modulation and botanical regrowth remain future work. Generic recovery is retained.

Signals carry origin node, original event identity/time, expiry and visited nodes.
A trace crosses a rooted connection only on its real packet arrival. Replays,
cycles and relays cannot refresh expiry or repeat delivery to the same node.
Signals can prompt investigation, not grant energy or remote omniscience.

Swarms investigate positive local overload increases or sustained stranded root
stock (default 300 units nearby for eight serviced ticks). Normal overflow alone
is harmless. After investigation a supplied response can escalate, adding bounded
local overload; it then enters a finite recovery period. Its own discharge is
recorded in the local baseline, not repeatedly reclassified as a new external
alarm. This natural trigger is a provisional gameplay detector, not settled lore.

Storm admission preserves the 3x3 overload footprint, protected access, suitable
clock-derived cloudy/rainy conditions and a deterministic chance per response
identity. Missing protection fails closed. `storm_chance_percent` defaults to
zero: production storm activation stays off while storm behavior is authored in
the separate storm discussion. A finite local presentation timer exists for
explicit tests/tuning; exposure, protection, storm traversal and full lifecycle
are not delivered and no HP/XP effects are invented.

The optional `ecology` extension keeps existing version-20 snapshots readable.
It captures policy once, validates references/energy/expiry and normalizes JSON
numbers. No player save file is automatically rewritten. Rebuild active geography
from canonical flora on load; inactive groups receive no invented refill/catch-up.
Shared active time runs through tactical combat; explicit pause stops it.

### Player-facing delivery

Owner-authorized particle promotion, October 29: `vessel_swarms.gd` now consumes
saved state through `scenes/vessel_particle_swarm.tscn`. Each group uses one GPU
emitter with up to 24 visual orb heads, ten fading samples per trail and two
shared billboard passes (direct radial warp mask, then orb/trail glow). The
existing group limit, picking, plant presentation and warning remain in place.
GPU paths retain state-dependent gathering, response motion and recovery height.
Stable group seeds keep visual placement independent of render-slot order.

The renderer supplies saved active seconds; the emitter's independent preview
clock is disabled. Pausing or holding that clock holds paths, trails and anger
blending; render delta/camera cannot change energy or advance swarms. Response
states request visual anger 0 normally, 0.4 responding and 1 escalating, blended
at one unit per active second. This is presentation, not a new anger mechanic.
Warp is almost imperceptible calm (0.07 px default peak), then rises quadratically
with anger to 28 px at full response. RGB separation follows anger squared too.
Actual discharges retain a single-line local warning. Storm visuals remain
inactive under the default policy. Emissive glow adds no per-orb light nodes.

The reusable particle scene exposes visual scale, flight radius/speed, wake
duration/sample count and tint/distortion tuning. Restart the game to apply
structural edits; live anger/aberration setters apply immediately. Runtime clamps
the authored visual count to 1–24 and always enforces the shared clock. Individual
affinity tint still comes from the existing environment/palette owner. No save
schema, population, feeding, storm admission or generation rule changed.

Particle promotion validation: Godot 4.7.2 headless and Forward+ / Direct3D 12
`tests/vessel_ecology.gd` passed 71 checks each, including the particle pool,
shared clock, render-state immutability and existing inspection/picking checks.
The connected capture was inspected. The rendered check used a fresh ignored
local profile after a prior stale shader-cache error; the final run was clean.

Group picking and specialist plant targets reuse existing Observe/Details actions.
Observe follows visible activity while open; neutral/idle text invents no flowing
energy or healing. Details distinguishes reserve, ambient concentration, class,
active function and a locally received trace; it reveals no unseen instigator.
Ecological targets expose compact additional facts while ordinary target Details
keeps its existing graph-only presentation. The normal ground target stays a plant;
selecting a visible swarm explicitly selects the group instead.

`VegetationAppearance` owns optional class art paths and fitted height/width,
separate from saved mechanics. Owner-supplied CraftPix models 019/015/017 serve as
Warden/Mender/Regulator artwork. Their palette is bound at presentation time.
Specialist bodies now belong to the ordinary streamed chunks,
using their stable seed/cell class identity even beyond active ecology. They
reconstruct with the same positions and models after chunk eviction. Local ecology
selects nearby activity pulses only; its nearest-24/12-cell list no longer owns
plant model creation or removal. Rendering these bodies never admits simulated
flora, adds reserves, advances time or credits packets.
Raw files
remain local-only; absent files use the existing CC0 nature fallback. See
[asset provenance](../assets/nature/PROVENANCE.md#tropical-plant-class-placeholders--october-29-2026).

Validation and next work are indexed in the world roadmap. Runtime evidence lives
under ignored `artifacts/vessel-response/`; no full-suite or target-device pass is
claimed. Balance, larger-world admission/service limits, biome/species authoring,
regional supply budgets and owner experience acceptance remain open.

Validation: [pilot evidence and remaining delivery](world-exploration-roadmap.md#pilot-validation-and-remaining-delivery).

### Grass lab functional connection review — October 30, 2026

Owner requirement: Vastra visuals must connect to the systems Vastra actually
serves. The grass fixture now exercises the existing `ExpeditionState` /
`PlantVastra` owners with eight isolated test definitions, rather than drawing
arbitrary links between grass positions. Its renderer consumes `flora_transfers`
and rejects missing/mismatched cell endpoints. Visible packets retain flight IDs,
source/destination IDs and root/energy recipient roles; reserves belong to cells,
never to graphical blades. Seeded test stock is explicitly identified in the HUD.
The current review covers grass emissions, tree receipt and root return. Specialist
repair/regulation/protection, Vessel and Sol feeding need their own actual
recipient/state projections when shown; this lab does not substitute decorative
links for those systems. Existing production `transfer_asset` already verifies
`flora_id` against each ledger node. See the grass fixture section in
[the workstation guide](development-workstation.md#grass-with-vastra-comparison--october-30-2026).

### Shared grass presentation integration — October 30, 2026

Grass is the built-in emanator presentation under `AuthoredPlantLibrary.add_cell`,
alongside authored emanators, reservoir trees and specialist receivers. The same
owner coordinates body selection, ground cover and endpoint fallback. Grass
blades and specialist ground cover share their canonical cell reserve; authored
emanators replace the default grass body. Density and visibility never admit or
remove saved flora. Weather reaches all plant renderers through the library;
plant event animations consume the same existing canonical-cell groups.

This preserves existing mechanics evidence and the generated-membership contract.
Read-only reference checked `vastra_simulation.py` and
`tests/test_vastra_foundation.py` at SolHunterSource commit
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`: ambient reads remain separate from
bounded saved activity updates. No reference files were copied or modified.
Focused integration results and the broader rendered-pair fixture limitation are
recorded in [procedural plants](procedural-plants.md#grass-under-the-shared-plant-owner--october-30-2026).

### Render-wide visibility and reserve posture — October 31, 2026

Owner requested Vastra visibility throughout render range, plus variable wind.
Live optical coverage now follows published render bounds and camera frustum,
with a regional round-robin visual allocation rather than nearest-source order.
The former 48-cell extent and few-nearby-region cap remain only in the isolated
web study. Real transfers still require their actual published endpoints;
visibility never admits flora, creates packets, changes energy, selects new
recipients or changes arrival time. Saved geographic simulation activation is
unchanged. Missing/inactive exchanges are not replaced with invented currents.
Filament culling derives from actual path points, including elevated paths;
origin precision rebases independently of the visual coverage extent.

Stored cell reserves drive reversible free-tip droop and saturation through the
shared `foliage_condition.gdshaderinc`. Full reserves retain authored posture and
pigment. Leaf attachments, species hues, bark and exchange organs remain fixed;
low reserve alone creates no permanent damage. CPU retargeting and both leaf
shaders consume the same configurable transition duration. Atmosphere Settings
owns gust strength, approximate period and spatial wavelength, evaluated using
the existing saved weather clock and absolute positions. Pause freezes motion;
camera movement does not reroll gusts or alter supply. See
[Inspector tuning](inspector-tuning.md) for defaults and apply scope.

Evidence: rendered nature contracts passed 46 checks; current coverage passed
182 (including 80-cell visibility, fair allocation, production filament bounds and
state invariance); live plant integration passed 922. Controlled plant/tree
renders at 5%, 50% and 100% reserves show distinct condition. Weather-frame
readback detects moving leaves and identical frozen-clock images. The plant
palette rebuilt 153 definitions successfully; normal editor import passed.
Captures/logs live in ignored `artifacts/step3/`. Interactive forest acceptance
and whole-game FPS remain separate from these focused checks.

### Connected circulation refinement — October 31, 2026

Owner requested playtest-resolution stage 4. The existing ledger remains the
sole owner of emission debits, destination credits, overflow, root allocation,
repair spending and Sol food. `choose_target` remains unchanged and unbiased.
Reference rechecked read-only: SolHunterSource `vastra_simulation.py` and
`tests/test_vastra_foundation.py`, checkout ref
`development/world-redesign-0.2` / `d6f0902d77ed46a2f7d251c354792a4cc9210bc4`.
Those establish bounded activity service and read-only ambient queries, not
the new optical junction spacing or emission cadence; those implement the
owner's current direction. No reference repository files were modified/copied.

Full reserves now wait for a stable seed/cell send slot. New production
expeditions capture four 0.75-second slots; the source retains its stock while
waiting. The eligibility interval spans the previous/current service ticks,
so round-robin queues cannot indefinitely miss a source's phase. At most one
packet still leaves each serviced source per tick; no catch-up emissions,
offline charge or camera-dependent service is added. The saved policy accepts
the optional validated `emission_phases` field; absent fields retain one-slot
timing. Existing saves keep their policy, and mid-flight save/load is exact.

Real nearby ground/grass packets now use seeded shared air corridors, and root
packets use separate soil corridors. Their recipient branches join common
interior spans with rounded corners. Canopy/ambient flows retain their existing
anatomical/surface routing. These are paths of existing conserved packets,
not new simulated sources or extra energy-bearing reserves. Derived junction
records sum each distinct packet amount once on each side: merging combines
those amounts, and outgoing branches retain only their own packets. Rebuilding
or overlapping optical strips cannot create another ledger credit. A corridor
may carry packets in opposite directions; each retains its own finite clock.

Tree-bound intake now selects `reservoir_ring` when present, even when a leaf
is closer. Its existing authored parent route carries the packet onward to
storage. Root flows retain root endpoints; other recipients retain anatomical
selection. No per-organ reserves, organ delivery simulation or decay is added.
Existing root-stock feeding and repair remain actual conserved sinks; no new
decorative feeding/healing exchanges are invented.

The filament renderer uses full polyline length for strip width along the
route and source-phased traveling brightness over the existing saved clock.
Both endpoints taper; terrain/body depth intersections fade softly. Packet
amount relative to saved capacity scales optical visibility, independently of
head count. The path length is uploaded only when its geometry changes, avoiding
repeated length scans in the normal particle path. Live controls and saved-policy
apply scope are indexed in [Inspector tuning](inspector-tuning.md).

Focused evidence: final current suite passed 189 checks; the Direct3D 12 plant
journey passed 847 checks with a clean exit and no logged engine/shader errors.
Checks cover conservation, unchanged unbiased selection, exact arrivals,
root/repair/feeding behavior, shared spans and junction sums, ring selection,
staggered sends, phase/work-budget aliasing, and mid-flight JSON round trips.
Counts vary with trajectory samples. Normal editor import and production startup
also exited cleanly. Inspector tuning passed 14 checks using the repository-local
validation profile; its earlier default-profile run failed because that user
save directory was unwritable, and that failed receipt is retained separately.
Logs live in `artifacts/step4/`; rendered
journey captures live in `artifacts/plant-vastra/`. The inspected in-transit
capture shows the curved, tapered stream. The root capture is largely obscured
by ground cover, and the busy-network capture does not prove forest-wide visual
rhythm. Observe connected transfers across several emission cycles during the
owner playtest; focused assertions are not visual/FPS/device acceptance.

### Slower source output and paced intake/outlet — October 31, 2026

Owner requested lower tile-fed accumulation, actual reserve drain/rise while a
stream leaves/enters, correction of premature fading, and smooth vector turns.
Production grass refill is reduced from 4 to 1 unit per active second at ambient
concentration 100. Ambient concentration itself and its natural recovery policy
are unchanged; this is the tile-fed grass output control, not a new concentration
debit or region source budget. Reference evidence remains the inspected bounded
activity/ambient separation in SolHunterSource at
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`; paced streams implement the owner's
new direction rather than a claimed source-repository rule.

Paced flights store optional validated `release_ticks` and `delivered` values.
Their full amount is committed once, protecting it from duplicate expenditure;
the undeparted share remains physically at the source. Budget `energy` excludes
that committed stock, while `flora_reading.energy` includes its undeparted share
and exposes `reserved` separately. Root reading likewise includes held root stock.
One per-tick derived cache avoids scanning all flights per plant/read frame.
The source's usable stock plus held stock determines actual storage occupancy,
so commitment cannot create refill/arrival capacity prematurely.

Travel time retains the existing finite policy. At the intake, each processed
activity tick credits only newly arrived portions. Pending root capacity subtracts
already credited portions. The conserved flight account is amount minus delivered,
including still-held, traveling and awaiting-credit energy. Full completion alone
produces the existing one-shot completion/trace event. Multiple source releases
cannot stack to bypass the paced source window. Pausing freezes time; save/load
preserves partial credit and held stock. Existing whole-packet flights remain
valid and finish under their prior contract. The two new pacing defaults apply
on loading/reapplying current expeditions; in-flight durations never get rewritten.

The renderer uses the same saved send/travel/release windows. Paced streams start
at an external outlet and finish at an external intake, without an extra internal
organ animation delay. Older flights keep their authored internal routes. Tree
collar surface metadata derives from the existing recipe/transform; geometry is
unchanged. Streams use bounded cubic vector spans, keeping exact endpoints and
terrain clearance. Mesh strips trail the leading point. Head taper/soft contact
cannot erase the final approach, nearby
Sol optical clearing retains the actual intake, and expired invisible transfers
are filtered before consuming optical slots. Delayed completion holds the intake
rather than replaying an already partially received train.

This slice does not implement new capacities/growth, fruit, pollination, distant
simulation or a shared regional source-allocation budget. Those approved/planned
contracts retain their own delivery gates. Focused receipts live in ignored
`artifacts/vastra-pacing/`. Final checks: plant energy 950, current rendering 238,
and Vessel ecology 4,827 assertions passed. The 153-definition plant palette bake,
normal editor import, production Direct3D 12 startup and controlled rendered paced
journey exited zero. Final logs contain no engine/script errors. The rendered
journey recorded recipient stock 0, 23.53, 94.12 and 100 across successive intake
checkpoints, with a pending optical layer before the last credit. Inspected the
stream captures; these focused checks do not establish whole-game FPS or owner
visual acceptance. One synthetic expired-flight check initially failed because
its missing completion timestamp was clamped to zero; the filter now only uses
that timestamp when supplied, and the final suite passes with the failed receipt
retained separately.

### Intake clipping and tree leaf outlets — November 1, 2026

Owner follow-up replaces the settling fade above with consumption at the real
intake threshold. Particle motion retains the unbounded travel fraction after
the leading point crosses. The strip samples a clamped physical path while its
fragments retain that raw fraction; crossed fragments are discarded, and only
then is the fully consumed particle hidden. The remaining tail keeps advancing.
Arrival/age fading is removed for real transfers. Strip lifetime and completed
flight filtering include the extra strip transit time. Existing optical range,
admission budgets, breathing and scene occlusion remain presentation controls.

Trees already forward conserved packets under the finite saved travel/release
policy. Their non-root onward outlet now selects only actual leaf surfaces when
available, with the nearest leaf to the destination winning. Intake remains the
integrated ring; soil exchanges remain roots. The anatomy builder records every
accepted leaf with a unique petiole/outlet pair, removing the previous one-leaf
per socket restriction. The derived graph and matching runtime palette are
rebuilt without adding geometry, reserves or random draws. A leafless/older body
retains the existing structural fallback. This is endpoint routing of existing
exchanges, not new message types, pooled reserves or cost-free signal forwarding.
Source reference remains the bounded ambient/activity implementation at
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`; the new leaf-routing requirement is
the owner's explicit direction, not a rule attributed to that reference.

Focused receipts: `artifacts/vastra-leaf-highways/`. Current rendering passed 245
checks; transformed organ attachment passed across all four biome tree samples,
including selecting every registered leaf and tracing its connection to storage.
The palette bake rebuilt 153 definitions. A controlled Direct3D 12 tree-to-tree
journey passed with 289 available source leaf outlets, a real leaf departure and
recipient intake readings 0, 23.53, 94.12 and 100. Its final pending capture shows
the strand entering the ring. These checks establish local routing/rendering,
not whole-game performance or owner visual acceptance. The first import caught
an inferred Variant/bool parse error; it was fixed with an explicit bool type,
and the failed receipt is retained separately.
The final editor import exited zero. Final current/organ/bake/render/import logs
contain no engine or script errors; scoped whitespace checks passed with CRLF
line endings recognized.

### Ground desaturation gaps and stronger biome tint blending — November 1, 2026

Owner reported saturated grass around roads/rocks across the map and requested
stronger biome blending. The terrain palette had excluded woodland from reserve
desaturation and applied an additional path mask after mixing road materials,
attenuating the underlying grass condition twice. Living turf/woodland is now
conditioned before road/rock mixing; distant ground coverage receives the same
reserve-conditioned tint. Bare earth, road and exposed stone retain their roles.
Unknown reserve texels no longer vote as full: interpolation normalizes valid
readings and uses a bounded cardinal fallback at radii 1, 2 and 4 over missing
footprints. Entirely unknown areas retain authored pigment. This does not create
plants or assign a reserve to a nonliving cell.

The biome tint kernel now includes the center and diagonals, with nine weighted
samples and a configurable four-cell default radius. Its bounded sample count
does not grow with radius. It affects detailed/streaming ground and grass through
the existing shared `ground_tint_at` owner; generated biome membership and
simulation are untouched. Inspector controls and apply scope are recorded in
[Inspector tuning](inspector-tuning.md).

Focused receipts: `artifacts/grass-reserve-blend/`. Terrain materials passed
4,897 checks, including chunk/LOD agreement and wider tint shoulders. The rendered
leaf/ground suite passed 37 checks, including a GPU regression for depleted
pigment across a missing footprint and distinct low/full color. Captures exercise
the actual meadow, woodland and road-edge terrain palette with low/mid/full
reserves. Early test-only name/mesh-array errors were corrected; retain those
failed logs separately from the final passing receipts. No whole-game FPS or
owner visual acceptance is claimed.
