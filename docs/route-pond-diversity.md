# Route and pond diversity

Follow-up: [water appearance and shoreline continuity](water-appearance.md) fixes
the visible triangular bank-mask seams and updates the water treatment without
changing generation 7 geography or its save contract.

Implemented October 28, 2026, under the owner's bounded T6 priority. Normal F5
play uses generation 7. Start a new expedition: generation 6 and older development
saves reject with the existing new-expedition message and preserve the running
expedition. No old generator or conversion path is shipped. Save format remains 3.

## Geography contract

`terrain_geography.gd` derives absolute descriptors from the seed and saved terrain
settings. A geographic district is 128 cells, independent of 16-cell render chunks.
Each has a displaced dry hub, an east link, a seeded north link, an optional spur,
and a main-approach connection in the adjacent districts. Each link tests five
33-point bends, rejects pond/bank conflicts using world-cell clearance around
the full pond extent (including road width and sampling allowance), and scores
remaining candidates by distance and raw relief change. Unavailable optional links
are omitted. This is
a bounded district graph, not connected river drainage or a guarantee that every
optional road supports every footprint under every experimental relief setting.

The refuge `(0,0)` and waystone `(78,-2)` anchors remain. The winding essential
approach has a protected corridor and still passes the existing new-expedition
3x3 admission/fallback. Its seeded centerline has a derivative below one cell per
cell, so rounding cannot introduce two-row jumps. The four-cell inner corridor
retains the gentle raw grade, with a smooth outer bank blend. This fixes the
seed-19 regression where an admitted pond's bank made required 3x3 travel too steep;
the seed is covered directly rather than being avoided in travel checks.
Road centers are no longer repeated 96-cell rows/columns.
Road texture edges still follow cell geometry; this pass changes geography rather
than introducing a new continuous road material or movement-cost rule.

Districts test zero to three pond candidates. The starting district tries at least
one smaller seeded pond near the bounded wetland composition. Rotated, independently
varied radii and three-/five-lobed radial modulation replace repeated ovals.
Conflicting candidates are omitted around authored places/main travel and earlier
ponds. Each descriptor owns one horizontal level. Final ground triangles shape
the bed and rising banks; water polygons are clipped from those same triangles.
The old square bank/rim boxes are absent from generated terrain. The texture-only
null-terrain geometry fixture retains its simple box adapter.

The water category uses the cell-center mask. At a partial shoreline cell, the
rendered plane covers only ground below its level. `display_height` and terrain
rays return the actual upper surface at the queried point. Swimming/flight keep
their existing interfaces and their own admission authority. No water becomes
ordinary walkable ground, and no new encounter or battle rule is introduced.
Floating dressing additionally requires its bounds to remain below the water plane.

Pond queries inspect at most nine districts. Road tile preparation inspects at
most 25 districts; no search grows with travel history. Derived FIFO caches hold
256 pond districts, road districts and prepared road tiles each, plus 32,768 cell
basin/road samples each. They are disposable, never saved and do not own individuals,
ecology or terrain settings. Existing height/normal/slope cache changes are preserved.

## Godot controls

World root → Expedition Tuning → Terrain Settings (normally
`resources/terrain_rolling.tres`) exposes Route Bend (0.5–1.5), Pond Scale (0.6–1.2)
and Pond Candidates (1–3). Defaults are provisional. They apply to new expeditions;
loaded expeditions retain the validated saved values. Generation 7 validates these
settings alongside the relief controls; fractional candidate counts are rejected.
The compact woodland/dryland/wetland palettes remain bounded. The pond orientation
sign moves to `(28,16)` because the old point now lies on the winding approach.

## Evidence and remaining acceptance

Current evidence lives under ignored `artifacts/geography/` and adjacent
`artifacts/geography-*.log`. Matched 1280×800 player-scale fixtures use seed 2601026,
the same camera angles and generation-6 before images versus generation-7 after
images. The fixed `(32,32)` comparison becomes water and `(32,3)` is now off the
road in generation 7: these are geography camera fixtures, **not** legal standing
position evidence. Additional current-approach/dry-bank views and the actual
journey establish accessible viewing/travel separately.

The normal-AI input-action journey completed outbound/return, negative-coordinate
travel, pause and full snapshot save/new/load with zero failures. It opened no
automatic contacts; encounter and battle admission therefore have separate suite
coverage. Automated journeys are not owner comfort/visual acceptance or Thor/export
qualification. Numeric performance budgets and full connected river drainage remain
outside this bounded implementation.

Focused validation after the essential-approach fix: 8,853 geography checks (including independent
positive/negative production borders, forced cell-cache turnover, connected tuning
and the pinned generation-7 fingerprint); eleven-seed generation checks (127), bounded
composition reconstruction (1,712), flight/swimming integration (84), encounter
initiation (26) and first battle admission (60) passed. After the final stricter
optional-road clearance change, rendered terrain integration (3,565), solid geometry
(19) and full-3D (44) passed. These counts describe automated coverage, not
owner/device acceptance.

Current combined-build limits remain explicit. Our first shared run stopped after
`sol_creature_models.gd` printed 93 passing assertions but exited unsuccessfully.
The species chat fixed that shutdown issue, and its later
`artifacts/sol_air_water/validate_complete.log` completed the headless shared validator.
That run overlapped the final approach fix: its early generation suite used ten
seeds/118 checks and its later geography suite used the current 8,853 checks. The
separate current eleven-seed/127-check run and final rendered normal-AI connected
review cover the changed approach. Do not call that shared run a frozen-source
whole-build certification.

Rendered presentation ran all 24 checks and failed two silhouette-pixel checks (foreground geometry and imported
foliage produced zero changed pixels). Terrain geometry/shore assertions passed,
but this is **not** a fully passing rendered presentation result. The
wetland camera can still hide the trainer/nearby Sol behind existing tree canopies;
orbit exposes the battle positions. Do not close visibility acceptance from frustum
counts, a visible warning panel, or successful deployment alone.

## Measured cost

`artifacts/geography/cpu_manifest.json` records the pinned engine, AMD Ryzen 7
5800XT, source hashes before/after, archived pre-change geography hash and workload.
There were no other Godot validation processes at either end of the measurement;
the editor remained open. Source hashes were unchanged. Three alternating pairs
used fresh generator instances in one fresh headless process, with the same current
dependencies. Five fixed chunks were extracted cold, then sampled again warm.
The generation-6 source is an ignored historical measurement artifact, never a
shipped save fallback or maintained legacy generator. OS caches were retained.

| Median CPU workload | Archived geography 6 | Geography 7 |
| --- | ---: | ---: |
| Generator setup | 1.21 ms | 102.06 ms |
| Five cold chunks | 25.30 ms | 58.16 ms |
| Same five warm chunks | 13.40 ms | 12.28 ms |

The additional cold descriptor work is real. These CPU samples do not establish
frame-rate acceptance, a causal whole-game speedup, a GPU-memory budget or Thor
performance. The earlier rendered journey timings were gathered during concurrent
development and are functional evidence, not a strict matched timing comparison.
Wider palettes remain gated; this pass does not waive T5 budgets or device review.

Final normal-AI connected evidence is `artifacts/geography/approach-review/`:
zero failures, real-input sample travel and waystone/refuge return, actual pointer
deployment in each treatment, observations and three safe-retreat receipts,
warning panels visible in daylight/night/rain, and exact saved-state reconstruction.
The final player-scale captures are `artifacts/geography/current/`; map comparisons
are `map-v6.png`/`map-v7.png` under the geography artifact directory. Existing canopy
occlusion remains a recorded presentation gap rather than a reason to hide blockers.
