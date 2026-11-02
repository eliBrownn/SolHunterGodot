# Nature alpha: first area intake

October 31, 2026. First-area runtime intake and a normal-input outing are implemented;
owner experience acceptance remains open. The
[world roadmap](world-exploration-roadmap.md#nature-delivery-sequence) owns gates
and the Bible owns design. The [runtime contract](readiness-alpha-contract.md)
records implemented finding/cooperation/readiness owners and provisional rules.

## Reproducible geography evidence

Current refresh: generation **16**, seed **2601026** still reaches 8,646 one-cell
and 5,712 three-cell positions inside the survey. Both directions of the grove
`(0,10)` and bank `(19,30)` paths validate against the actual main-scene settings.
The version-15 intake below is historical evidence. Runtime hints now require both
the authored seed and generation version. The separate six-biome Vastra audit
confirms actual circulation, including isolated water/shore plants; see the
[overflow contract](vastra-integration.md#ambient-overflow--october-31-2026).

Run the pinned Godot 4.7.2 console engine from the repository root:

```powershell
& '<Godot_console.exe>' --headless --path . --script tools/survey_nature_alpha.gd
```

Output: ignored `artifacts/nature_alpha/n0-survey.json`. The tool reads the normal
startup seed and climate, the main scene's actual Exploration relief/shelter overrides, and plant-community
parameters. It does not load or change player saves. Its report captures those
parameters and SHA-256 fingerprints of world/scenery scripts and relevant settings.
Survey bounds are x=-12..96, y=-24..64. Cardinal paths use `terrain.can_step`, with
independent one-cell and three-cell searches and reverse-edge checks. Paths stay
inside the survey, including their full footprint. This does not certify dynamic
obstacles, body collision or a normal-input outing.

Inspected baseline: HEAD `2812938`, generation 15, seed `2601026`, plus existing
uncommitted terrain/community/runtime and roadmap work. Branch
`codex/alpha-n0-survey` retains that working tree; those dependencies are not
silently included in this change or claimed reviewed. The source register must
still pin a reviewed combined revision, bake/catalog and asset set before acceptance.

The initial default-Rolling survey was superseded after inspecting the actual
main-scene overrides. The corrected survey found 8,646 reachable one-cell anchors
and 5,712 three-cell anchors, with bidirectional validation. Candidate selection
now stays within 48 cells of camp. These counts cover the bounded survey, not
the whole world; source fingerprints distinguish the superseded run.

## Candidate situation sheets

| Situation | Verified geography and references | First useful decision | Remaining runtime evidence |
| --- | --- | --- | --- |
| Return/preparation origin | Existing camp `(0,0)`; survey reference `2601026/cell/0:0` | Recover ordinary party HP, renew the prepared return, change legal party/loadout and save | Existing menu/transaction owners are retained; the readiness integration fixture covers recall, return and explicit recovery |
| Circulation grove | Stand at `(0,10)`; reference `2601026/cell/0:10`; tree-cell keys `-3:9`, `-3:13`, `1:13` within a three-cell square radius | Compare actual plant reserves; watch real transfers or leave for another finding | Normal travel and admitted reserve readings recorded; saturation is not proof of health or a fabricated disturbance |
| Waterside habitat | Stand at `(19,30)`; reference `2601026/cell/19:30`; basin normalized distance approximately 1.489 | Observe Reedback/local activity from dry ground, then approach respectfully or back away | Rendered outing records actual moving individuals/identity references; special shelter behavior is not inferred merely from being beside water |
| Guarded crossing | Existing territorial Seedmote, home `(48,2)`, ID `2601026:48:2:seedmote` | Read a real territory warning, observe, approach or leave; battle is optional | Existing guard/contact owner supplies the warning. This is territorial disturbance, not invented ecological damage or a guaranteed forced encounter |

The generated report includes both footprint paths for each selected location.
For the grove, the approach goes south from camp toward `(0,10)`; the report
retains the actual footprint-specific paths rather than assuming the same route
fits both bodies. Return reverses those steps. Grove selection scores nearby canonical
tree cells and proximity, preferring large-companion access. Waterside selection
chooses a reachable bank near camp, preferring that same clearance. These are
authoring heuristics, not runtime generation changes or new geographic identities.
The survey references are seed/cell locators, not newly persisted site records.

Leaving interrupts pending cooperation. Learned findings persist immediately,
independently of recent sightings; revisiting reads current state rather than
resetting first evidence or awarding repeat rewards. Existing local routines,
population and reserves own recurrence. No reward reset or automatic reserve refill
is introduced. Owner review must still assess whether these choices are worthwhile.

## Validation and next work

- Godot 4.7.2: corrected main-scene survey passed with valid return edges.
- Headless editor import passed after allowing access to normal Godot editor
  directories; the sandboxed attempt failed on those directories. The existing
  nested-project warning under ignored `builds/` remains.
- Ownership/UID checks include the new owners and retain the existing move-map authority.
- The final D3D12 normal-input route (`journey-final.log`) returned through all
  six waypoints without traversal failures, retained plant/bank/warning findings
  and passed save/load comparison. The optional `--combat` replay
  (`journey-combat-final.log`) adds an actual automatic contact and scheduled
  capture of the real territorial Seedmote, then returns to camp with all state
  values retained. It uses the existing testing Seals without altering HP, rolls
  or simulation speed; controlled defeat/reserve fixtures remain separate.
  The guarded-crossing screenshot still shows
  foreground foliage obscuring part of the normal view.
- No full-suite or owner play acceptance claimed; known combined-build failures
  remain tracked in the alpha register.

`tools/review_nature_alpha.gd` performs a normal real-time input-action outing
through the grove, bank, guarded trail and return, with live AI/ecology, actual
observations and save/load. It does not teleport, disable contact or alter HP.
Reports and normal-camera screenshots live under ignored `artifacts/nature_alpha/`.
Focused field/readiness fixtures are explicitly controlled tests, not that outing.
See the runtime contract for the separate capture, withdrawal, reserve and blackout
acceptance coverage. Owner play feedback and the broad combined gate remain separate.
