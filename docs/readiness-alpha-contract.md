# Nature alpha runtime contract

October 31, 2026. Owner requested implementation of the five alpha steps and
authorized adjustable provisional combat defaults. These values are an internal
playtest specification, not final balance or new story canon. The
[world roadmap](world-exploration-roadmap.md) retains acceptance authority.

## Owners and persistence

- `WorldTerrain` still owns geography and canonical plant admission. The area
  survey reads the actual main scene's Exploration relief and shelter overrides;
  it no longer assumes the script's Rolling defaults describe normal play.
- `ExpeditionState` owns durable findings, return preparation, health and battle
  receipts and conserved ambient overflow. Domain version 22 deliberately rejects
  incompatible development saves. Save format 5 is unchanged; generation is now
  16 under its existing world-generation owner. First-area hints check both seed
  and generation so future generator changes cannot silently reuse old coordinates.
- `FieldFindings` validates six authored knowledge IDs independently of the
  120-row recent-sighting feed. First evidence is immutable; reads are detached.
  Catalog admission is finite, with no silent eviction or arbitrary free-form
  archive. Saved coordinates, source, target, value and posture text are historical observations, not
  proof a target is still available. Future findings extend this catalog and
  must retain stable IDs; no second journal or quest-save owner is introduced.
- `nature_expedition.gd` adapts actual observation and explicit companion actions
  to those transactions. It owns no creatures, reserves, movement or trust.
  Completion rechecks state instance, selected identity, target and proximity.
  Walking away, changing selection/loading or entering an encounter interrupts.
  Ordinary pause freezes an in-progress action. The follower owns its gesture
  and caption. No action costs, energy gains, trust or captures are invented.
- The existing plant animation owner keeps event transforms. Reserve appearance
  is an independent bounded consumer of the same canonical cell: registered
  foliage MultiMeshes carry reserve transitions in custom instance data, so shared
  materials never become reserve owners. Grass blades and unrelated materials
  retain their buffer format. Low reserves desaturate leaves and lower their free
  tips slightly; full reserves retain authored color and posture. Wind remains
  additive and depletion does not assert damage.
  Chunk cell lists are retained through weak references and refreshed incrementally;
  the exported per-frame cell budget bounds reads, and a frozen tick is sampled once.

## First-area actions and preparation

Current authored sample seed: 2601026. Normal-game geography admits the grove
approach `(0,10)` and bank `(19,30)`; the eastern territorial Seedmote near its
home `(48,2)` supplies a real guarding situation. This is a territorial warning,
not manufactured ecological damage. Situation references and current actors are
resolved from existing generation/state. Other seeds retain free exploration;
the authored first-area hints are not asserted for unverified geography.

Observe admitted plants to retain reserve knowledge, observe a reachable bank
for the waterside lead, and observe actual warning conditions/territorial contact
for warning knowledge. Field Guide displays retained findings alongside recent
sightings. Inspecting details/opening the guide remains read-only. Re-observation
does not repeat rewards or replace first evidence.

Initial authored cooperation uses existing Crown-Ear listening and Bellroot
plant inspection. Settings select species independently of affinity. The player
and an already legally placed, stationary follower must both be nearby; no
teleport is used to make a command succeed. Listening concerns an actually visible
local Sol up to six cells away (ordinary close observation is three), with its
actual identity and current posture rechecked on completion; inspection reports
an actual admitted plant's reserve. Both supply a
short species gesture, caption, explicit response and retained observation place.
They grant no claim about unseen creatures or hidden causes.

The existing camp supports ordinary party HP/exhaustion recovery and existing
party/loadout/save controls without an NPC. A new expedition starts prepared for
one return; exhaustion/blackout consumes that preparation. Recover party at camp
renews it, including when the team is already healthy. A subsequent confrontation
requires renewed preparation. This is a provisional authored return arrangement
to the existing camp, not a universal rescue system or a new supply economy.
Recall preserves identities and remaining HP; recovery is a separate action.
Exceptional injuries, detonation and general severe-exposure treatment remain
outside this first implementation, rather than becoming automatic HP healing.

## Readiness execution

`ReadinessTimeline` owns battle time and schedules authoritative operations on
the existing `TacticalBattle`; `BattlePlayback` presents snapshots. Effects do
not run when a step is selected and animation callbacks never resolve damage.
The old turn domain remains explicitly selectable for historical regression
fixtures; the normal scene selects readiness through its exported settings.

Provisional rules:

1. Both units begin ready. The first ally planning gate freezes battle time;
   the opponent commits its legal AI plan when execution starts. Later readiness
   is individual. Existing shared AP, Speed-based free movement, move costs,
   damage, finite uses, class passives and centralized outcomes are reused.
2. A draft contains at most 12 ordered movement/move/Seal steps. Reordering or
   removing a step rebuilds the nominal preview with the same legality owner;
   invalid edits leave the prior plan intact. HP bars and solid bodies remain
   authoritative; a gold marker shows the planned destination. Previewed success
   assumes the opponent and terrain remain as currently known.
3. Commit freezes the ordered plan and aim. Cardinal movement takes 0.25 seconds
   per cell, preparation to impact takes 0.5 seconds, and post-plan recovery is
   `1.5 * 10 / effective Speed` seconds, bounded below by 0.05 seconds. Timings
   settings are captured for the battle; effective Speed determines recovery when
   the plan is committed. The resource labels the defaults provisional.
4. Events sort by due time then insertion serial. Both actor plans use the same
   event queue and movement costs. Equal-time destination conflicts resolve in
   that stable order; footprints cannot overlap units or the commander. Larger
   footprints expand the bounded arena and require actual multi-cell terrain fit.
5. At impact, the existing move authority rechecks the committed cell. A moved,
   blocked or invalid target is not chased. A failed committed attack consumes
   its reserved AP/use if still available. Blocked movement does not teleport or
   trigger replanning; later steps retain their original aim. AP not used by the
   committed plan is discarded at the next readiness.
6. Status/recipient-turn passives tick once when that actor completes an
   activation. Field-round effects tick after both actors have completed another
   activation. They are not multiplied by the number of steps or blindly converted
   to seconds. Simultaneous effects follow the same stable event order.
7. Seal attempts occur at scheduled impact. Their actual chance is rechecked
   then, and deterministic attempt-indexed rolls cannot be rerolled by clearing
   or editing a draft. Failure does not grant an extra planning gate. Successful
   final capture ends the confrontation; permanent imprints/overload are not reset.
8. Withdrawal is a whole readiness plan. Provisional success requires being
   beyond every equipped opponent move's reach at impact. A failed withdrawal
   spends the readiness opportunity; no free retry or replacement attack occurs.

Example trace: move one cell then attack schedules movement at 0.25s and impact
at 0.75s. A Speed-20 actor next becomes ready at 1.50s. If the target leaves its
committed cell before 0.75s, the attack misses and spends one use. No effect can
occur before its scheduled event. Enemy movement, impact or recovery can be
interrupted by a new ally planning gate; all participants resume from the same
local time after commitment. World activity outside the battle continues.

## Storm, exposure, ownership and outcomes

The confrontation establishes its boundary from actual arena geography before
high ecological overload is required. A restrained boundary view is presentation
only; it creates no energy and does not originate a natural-weather storm.

Live turbulence accrues exposure, reduced by the equipped alpha field-kit
protection fraction (default 25%). Warning/severe stages begin at 50%/80% of the
120-unit blackout threshold. Limited gear warns before entry and permits choosing
the risk. Planning, replacement selection and explicit pause accrue no exposure.
The threshold event is exact across frame partitions. A healthy reserve receives
three seconds of live buffer after replacement. These are adjustable playtest
values, not final gear progression, protective affinities or injury rules.

When a deployed ally is exhausted, healthy existing party members can be selected
under tactical pause. The transaction retains the exhausted individual's zero HP,
uses the selected reserve's existing identity/profile/movebook and admits no new
creature. Commander blackout instead performs emergency recall even if the
released companion is healthy. The once-only battle receipt records that cause
without converting healthy HP to exhaustion. The prepared return reaches camp;
camp recovery is then an explicit separate choice.

Combat reserves its local tile keys in `ExpeditionState`. Background tile writes
and recovery are held there; condition/recovery timestamps do not accrue catch-up
debt. Plant circulation continues, but plant/mender repair cannot pay against
reserved overload. Unrelated world activity continues. Completion merges battle
outcomes through the existing current-state transaction and releases reservations;
it never replaces the entire expedition with an old battle-start snapshot.
Capture/training/imprints and outcome retries retain their existing single writer.

## Mechanics evidence and validation

Read-only local SolHunterSource branch `development/world-redesign-0.2`, commit
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`: inspected `sol_identity.py`,
`journal.py`, `tactics/party.py`, `tactics/healing.py`, the `game.py` observation/
recovery callers and journal UI tests. This supports stable identity, first-seen
journal events, caller-admitted recovery and existing party ownership. Its
120-entry eviction is retained for sightings, superseded by the owner's durable
knowledge requirement for findings. Its camp/station healing numbers and memory
awards are not silently imported. The combat roadmap already records inspected
turn mechanics; the later owner decisions and this provisional trace own new
timing. Godot generation remains authoritative.

Focused checks live in `tests/nature_alpha_contracts.gd`,
`tests/nature_field_actions.gd` and `tests/readiness_expedition.gd`; configured
validation includes them without removing historical assertions. Historical turn
UI fixtures explicitly select turn settings, so their old timing expectations
cannot accidentally certify readiness. The normal-input rendered outing uses
`tools/review_nature_alpha.gd`; reports/screenshots are ignored artifacts.

Regression fixture reconciliation preserves the assertions and the established
runtime contracts. Mouse feedback projects actual raised terrain/bodies, frames
the arena and uses visible legal releases; approach uses legal tactical movement.
Follower checks await streamed clearance and advance the admission retry clock,
without relocating the follower or treating unknown geometry as clear. Natural
movement enters and withdraws through the real preview owner. Orb/recovery wording
checks reflect the existing shared-world clock. Biome checks inspect the production
`ground` mesh and reconstruct foliage with production coverage/variation values.
These changes classify obsolete fixture assumptions; they do not remove corruption,
identity, collision, pause, damage, endpoint or shared-vertex requirements.

Acceptance still requires the combined validator, normal-camera review, deliberate
withdrawal/capture/defeat/revisit evidence and owner feedback. No test count is a
claim of fun, approved balance, clean-clone assets or public-release readiness.

October 31 local evidence: focused contracts originally passed 37 headless / 39
rendered checks, with 41 rendered checks after the concurrent reserve-transition
integration. Field actions pass 14 and readiness integration passes 16. The controlled readiness
fixture includes final capture, exhausted-party replacement, withdrawal and healthy
companion recall on commander blackout. The normal-input D3D12 route passes with
three retained findings and a value-preserving save/load round trip. Its optional
`--combat` replay also records a real automatic contact, actual Seedmote capture
through readiness and return to camp with no altered HP, rolls or simulation speed.
The explicit review policy uses the existing unlimited testing Seals; this is not
resource-economy or owner experience acceptance. JSON comparison normalizes numeric
representation on both full snapshots rather than comparing integer/float text.
Foreground foliage partially obscures the guarded-crossing camera and still needs
visual follow-up.
Logs are under ignored `artifacts/nature_alpha/`; the combined run remains separately
tracked. These are working-tree results, not a pinned release revision.

### Biome follow-up and current validation

The owner approved adjustable 1:1 ambient conversion after the all-biome audit
found water/shore plants registering and filling but lacking nearby tree recipients.
The [overflow contract](vastra-integration.md#ambient-overflow--october-31-2026)
records the conserved bounded path and current save versions. Representative
generation-16 areas in all six biomes now transfer Vastra and pass strict snapshot
validation. This confirms simulation, not replacement pond artwork: aquatic art
remains deferred. The audit separates canonical membership, presentation anchors,
rendered bodies and actual emissions rather than calling every anchor a visible body.

Current overflow evidence: 30 conservation/backpressure checks, 824 plant-circulation
checks, 39 headless / 41 rendered alpha checks pass. The broader frozen pre-overflow
audit is not a green combined validator: it encountered stale derived palette
inputs, historical fixture assumptions and native cleanup errors. Its stalled
scenery-site subprocess was bounded and terminated; the other tail checks finished.
The failed/interrupted checks remain visible under ignored audit logs.
Earlier generation-15 outing evidence above does not certify the current generation
or overflow. Current route/save/field/readiness evidence must be recorded separately.

The current generation-16 / state-22 D3D12 normal-input replay completes with three
findings, one real contact, actual Seedmote capture, return to camp and complete
save/load equality (zero failures, `ambient-journey-final.log`). Readiness integration
passes 16; field actions pass all 14 original assertions, air/water traversal saves
pass 85, historical first-battle lifecycle passes 60, and species catalog passes
243. First-battle mouse projection now uses actual raised geometry and a visible
legal release; air/water disk fixtures create their own artifact directory. Known
historical Canvas/ObjectDB shutdown warnings remain visible. A discovered resource-resave defect had removed
required move/behavior lists from all 18 species; only missing lists were restored
from the verified pre-resave snapshot, preserving other resource edits. Current
catalog configuration validates. The companion fixture now selects published legal
body clearance and a nearby canonical plant instead of assuming a fixed road cell
remains suitable after art changes. These local results do not close the broader
combined-validator or owner experience gates.

### Validation resolution — October 31, 2026

The follow-up uses an independent source/resource/static-asset/import-cache copy
under ignored `artifacts/alpha_resolution/runtime`, without junctions or hardlinks.
Initial-copy drift was detected in derived palette files during another bake;
the isolated palette was rebuilt against its own source and reviewed definitions.
The original copy manifest and subsequent correction hashes remain separate.
Current checks retain the canonical validator's assertions and ordering. A bounded
diagnostic continuation records individual exits, engine/script errors and timeouts;
it does not replace CI or treat a completed assertion count as a successful exit.

Resolved causes: grass jitter could place neighboring clump roots closer than the
existing spacing requirement; half-slot jitter now guarantees separation without
changing canonical cells/reserves. Palette comparisons select the actual low-detail
cover recipe. The composition fixture separates current plant-library identifiers
from retained nonliving bounded dressing, preserving retirement and reconstruction
checks. Habitat-specific dressing yields when current generated terrain no longer
matches the old sample. Shelter publication uses a seed independently proven to
admit the site; the production x=224 search may lawfully reject non-woodland terrain.
The geographic fingerprint is explicitly pinned to verified generation 16, replacing
the historical generation-7 hash. Save-cache fixtures create their own output
directory, and distant-eviction fixtures update the actual 3D camera before planning.

Focused results: 813 live-plant checks, 399 composition checks, 356 shelter checks,
26 generation-cache save checks and 41 rendered alpha checks pass. The isolated
normal-input replay again completes three findings, actual capture, return and full
save/load equality with zero failures. Combined validation and current-workspace bake
synchronization are still in progress; no final all-green or owner acceptance claim
is made by these intermediate results.

The continuation exposed a second live defect: leaf grass had acquired per-clump
solid picking/clearance boxes and repeated full anatomy in placement history.
That blocked legal companion paths and exhausted memory during the widest streaming
review. Grass again uses terrain/canonical-cell interaction without solid leaf
obstacles; functional plant bodies, trees and props retain their physical clearance.
The living source owns one full connected organ graph per cell; placement history
does not duplicate it. Live integration passes 815, owned companion lifecycle passes
37 and the formerly crashing 3D view passes 6,801 checks with clean process exit.
Species behavior filters lost during resource resaving were restored only where
missing; negative hierarchy checks now reject another species' signature/response.
The four-species anatomy integration passes 151 and behavior hierarchy passes 28.

The human-base tests now inspect the owner-supplied skin material and retargeted
human calf instead of the retired grave knight's texture/bone names (65 checks).
Grass distance checks recognize the cover's own draw-distance policy (62 checks).
Bake checks reconstruct stable palette variants independently of editable recipe
parameters/size class, compare actual geometry rather than conservative soil padding,
and allow measured float roundoff while retaining exact triangle-count checks.
Distant eviction uses the configured stream capacity instead of a fixed 100-cell
assumption; the corrected solid journey passes 2,612 checks.

Owner follow-up removes labs from normal gameplay. No lab adapter, footer buttons
or lab F8/F9 handlers are installed at startup. Lab code/scenes remain standalone;
explicit adapter tests pass 32 checks. Lazy overlay allocation also fixes the two
previously leaked CanvasLayers. Existing game save/load shortcuts are preserved.
The subsequent canonical end-to-end result and closeout are recorded below;
its exit/error scan, not these individual counts, determines automated completion.

The subsequent current-workspace gate caught a typed-array initialization error
in the updated grass-understory path despite passing assertions. Explicit typed
initialization fixes it; current live-plant integration passes 920 checks without
engine errors. The interaction fixtures now synchronize and frame the real camera
above foreground plants before projecting their clicks, retaining normal occlusion
and picking; world interactions pass 32 and mouse-first UI passes 29.
The palette comparison releases each completed specimen's derived builder/index
caches instead of retaining the entire source palette. Its previously observed
native allocation failure is followed by 1,582 headless checks and a clean exit,
with every geometry/anatomy/index comparison retained. The final 18-suite audit
continuation passes, including 41,109 shoreline and 2,612 solid-scene smoke checks.

Shutdown investigation also recorded intermittent Windows access violations after
all 54 recovery assertions passed. Native inspection identifies GDScript teardown;
the character and cache theories were not established. Speculative production
workarounds were removed. Five deferred-exit diagnostic runs and three original-exit
controls both pass, so those results do not establish deferred exit as a fix.
The strict combined gate still requires a clean process exit on consistent current
inputs; this historical failure is not converted to a pass by its assertion count.

### Alpha implementation closeout — October 31, 2026

The five authorized implementation steps are ready for owner playtest on Godot
4.7.2 stable. This closes implementation, not owner experience acceptance or public
release readiness. Labs are absent from normal startup while their code and
standalone scenes remain available. Adjustable provisional rules remain adjustable.

The current strict canonical run stops at recovery: all 54 assertions complete,
then an intermittent native Windows access violation produces a nonzero exit.
The full validation gate therefore remains red. Native evidence implicates
GDScript teardown, but the exact upstream cause is not proven. Cache, character,
deferred-exit and alternative scene-lifecycle experiments did not establish a
fix; speculative production workarounds were discarded. Owner direction permits
this observed shutdown issue to remain separate from alpha implementation closeout.
The engine pin and strict exit/error checks remain unchanged. Beta evaluation is
stopped; any future preview testing needs a specific material reason explained
before running, as recorded in the project standard.

The canonical remainder records 55 suites: 53 passed directly and two exposed
fixture assumptions subsequently corrected. Companion travel now waits within a
bounded deadline for actual published clearance (41 checks, clean exit), without
changing movement rules. Wilderness presentation reads explicit visibility groups
and independently configured draw distances (61 checks, clean exit). Current
focused stable checks additionally cover living plants, terrain materials, reserve
appearance, weather and visible Vastra transfer allocation. The independent
snapshot and individual exit/error receipts are retained under ignored
`artifacts/alpha_resolution`; historical failures remain visible.

The stable D3D12 normal-input journey records three findings, one real contact,
Seedmote capture, return to camp and full save/load equality with zero failures
(`stable-alpha-journey.log` and `stable_alpha_review/report.json`). The current
palette bake and editor import exit cleanly on 4.7.2. Owner play review of pacing,
legibility, useful choices and the next goal remains required by the world roadmap.
