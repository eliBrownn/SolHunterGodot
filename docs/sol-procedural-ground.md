# Procedural ground locomotion

October 28, 2026. First slice of step four in the [Sol Bible](reference/sol_bible.md).
This adds movement-driven posing and support contact solving to Crown-Ear,
Reedback and Bellroot. The subsequent [flight and swimming pass](sol-flight-and-swimming.md)
now supplies wild air/water navigation and transitions; this page records the
ground support implementation and its validation scope.

## Inputs and ownership

The existing `SolMotionTrack` still replays committed legal cells. The creature
receives its absolute display position, elapsed movement time and the world's
actual ground-height sampler. The camera-relative mesh position is never used
to detect movement. The driver chooses no destination, changes no occupied cell,
and writes no saved data. The current ground navigation and encounter rules are
preserved, including the distinction between a paused exploration clock during
combat and the separate combat presentation clock.

`SolGroundMotion` holds runtime support anchors, alternating diagonal support
groups, swing progress and visual heading. Motion moves a swing foot toward a
new sampled contact; the support feet retain absolute anchors. Two-bone solving
rotates the registered hip/knee controls toward those targets. The torso settles
slightly to leave joint bend available. Neutral transforms restore every frame,
so repeated posing does not accumulate rotation or scale errors. Contact pads
stay level. Slopes sample each foot's own terrain location.

Heading responds smoothly to actual displacement. A stopped or blocked actor
finishes its current swing, plants, and starts no further steps. Zero elapsed
movement time freezes stride progress. Culling and route relocation reset support
history; reappearance/load never invents unobserved steps. The small pose state
is reconstructed, while individual traits and the existing legal route remain
under their original authorities.

Battle creatures also replay the existing movement-step records through their
visual track using the current battle presentation duration. This adds no new
combat delay or path permission. Unit rings follow the displayed model, while
interaction metadata retains the committed tactical cell. Attack and hit accents
continue blending before the final support solve. Uncatalogued orb presentations
keep their existing behavior.

## Controls and authoring

Select a creature root in `scenes/sols/`:

| Field | Units / effect | Timing |
| --- | --- | --- |
| Step Distance | Metres before the next support group takes a step; scaled with art size | Reconstruct model views after scene edits |
| Step Lift | Metres of swing-foot lift | Reconstruct views |
| Turn Response | Inverse seconds; higher values approach the movement heading faster | Reconstruct views |

Model Scale, idle controls and action duration remain connected. Packed-scene
configuration validation rejects non-finite or out-of-range movement controls.
For a new body, register nonzero hip/knee/foot chains and diagonal groups; see
[the creation guide](creating-sol-models.md). The shared base exposes
`build_model()`, `animate_features()` and `preview_bounds()` overrides, so an
additional body need not alter any pilot's builder.

Open [the workshop](../scenes/sol_model_workshop.tscn) with F6. It offers Rest,
Walk, Turns and Slope, with pause/reset. Its artificial route exercises geometry
without registering a species or writing expedition saves. In the normal pilot
expedition, movement comes from the existing authoritative replay instead.

The solver clamps unreachable targets rather than stretching the leg or moving
the actor. Very fast tactical dashes, steep local surface changes, unusual art
scale or extreme step tuning can exceed a short limb's reach; those cases require
art review and may show residual contact error. This does not certify arbitrary
rigs, all slopes or target-device performance. No automatic Skeleton3D retargeting,
wing membrane skinning, flight or swimming is provided by this ground solver.

## Evidence

Source reference: SolHunterSource `src/systems/world/entity_motion.py` at
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4` retains bounded display-only route
replay and snaps relocations; `src/systems/ai/behavior.py` at
`115f3e87acc1716c7113523567c01e1666681885` keeps walkability/navigation in
the decision authority. These were read through the GitHub connector. Procedural
joint solving is new Godot presentation work under the owner's explicit request,
without importing source generation or changing mechanics.

`tests/sol_procedural_ground.gd` covers flat contact error at 30/60/144 FPS and
0.3 m/s plus the normal 1.33 m/s expedition speed, idle stability, actual swing,
stop/settle, pause, camera rebasing, visual turns, independent slope samples,
relocation and live-world route/culling/encounter integration. Existing model
and catalog journeys cover essential poses, ownership and save/load. The full
validator includes the new suite. `tools/review_sol_ground.gd` saves actual
workshop renders for all three creatures on flat and sloped ground.

Validation: 222 ground checks passed headless and rendered with D3D12; the final
catalog journey passed 108 checks. Full `tools/validate.ps1` passed import,
all suites and both scene journeys. The guide's custom builder sample also
compiled and walked with the actual driver. Logs and six workshop images are
local ignored evidence under `artifacts/sol_procedural_ground/`. See the Bible
for the delivery record and scope limitations.
