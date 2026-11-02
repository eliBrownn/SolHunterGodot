# Real-time combat trial

October 31, 2026. Owner-requested disposable experiment for deciding where to
invest combat effort. This does not approve replacing tactical combat or revise
the Bible. The normal expedition and its saves remain independent.

## Open and play

From normal gameplay, press **F8**, then choose **Combat / real-time experiment**
in the Development Lab's station selector. Controls appear in the station panel.
Return with F8. Restart the game to discover the new station in an already-open lab.

For a larger dedicated window, run `tools/open_combat_trial.ps1`, or open
`scenes/realtime_combat_trial.tscn` in Godot 4.7.2 and press F6.
The encounter waits for **Start encounter / Space**, so you can read and tune first.

- Direct mode: WASD moves Ashquill; mouse aims; left-click or 1 uses Strike.
- Command mode: left-click sends the Sol to a destination, routing around cover;
  mouse aims and 1 attacks. This tests commanding one Sol, not a playable hunter.
- 2 uses the experimental ranged-area adaptation of Cinder Claw; 3 heals.
- Orange filled circles show the enemy's locked target area. Leave before impact,
  or use the central stone to break line of sight. Blue ground halves both actors'
  movement. Cyan filled circles show the player's committed attack area.
- Space starts/pauses; R or Restart resets to the ready screen. Move buttons are clickable.
- Sliders change movement, enemy warning, attack cooldown and simulation speed.
  Changes apply immediately, except a windup/cooldown already in progress retains
  its committed duration. Restart for comparable runs. Typing notes suppresses
  movement and combat shortcuts.
- Save trial notes writes a uniquely named JSON under `user://combat_trials/`
  with settings, current result, duration, hits/attempts, avoided attacks and notes.
  In-progress attempts are recorded with an empty outcome; they are not victories.

Try a direct-control fight, restart and try commanding, then compare a slower
warning/simulation setting. Judge whether movement and attacks feel satisfying,
whether cover changes a decision, and whether commanding feels like cooperation.
Compare with the existing tactical owner session in `combat-playtest-session.md`.
There is no automatic winner or accepted pacing target.

## Experimental scope and evidence

The fixture reuses Ashquill/Rattlehorn presentation and the current move library's
Strike, Cinder Claw and Renewing Current names, powers and encounter-use limits.
The synthetic loadout is not species learnset admission. HP 44, flat move-power
damage, continuous distances, windups, global cooldown, slow terrain, enlarged
presentation and the single opponent's chase/area attack are **temporary trial
rules**, not production balance or a port of the full damage calculation.
No affinity damage bonus, tile imprints, overload, class passives, capture,
progression, hunter control or controller support is implemented in this trial.
The aim is control/pacing evidence before expanding mechanics or final animation.

Read-only mechanics reference: SolHunterSource
`115f3e87acc1716c7113523567c01e1666681885`,
`docs/coordination/combat-architecture.md` and
`src/systems/tactics/sol_combat.py` (combatant/move contracts), plus
`tests/test_combat_loop.py` (path spending and rejected-action regressions). They establish
separate placement, battle rules, coordination and durable outcome ownership;
they do not supply approved real-time timing rules. The current Godot tactical
domain remains unchanged. This fixture owns only disposable local state and never
constructs ExpeditionState or calls its completion/save paths.

Validation: Godot 4.7.2 focused tests cover rejected commands, single resolution,
pause, cover, slow terrain, healing supply, command navigation, terminal gating
and restart. Rendered review is separate from owner feel acceptance. Reproduce:

```powershell
godot --headless --path . --script tests/realtime_combat_trial.gd
godot --path . --script tests/realtime_combat_trial.gd -- --capture
godot --path . --script tests/realtime_combat_trial.gd -- --hosted --capture
```

Recorded result: 22 focused checks and 7 rendered workstation checks passed.
Standalone and docked screenshots were inspected on the development PC using
OpenGL compatibility, with the final standalone 22-check run and image also
passing on Direct3D 12 / Forward+. The launcher selects Direct3D 12 explicitly
to avoid this machine's Vulkan-to-D3D fallback diagnostics. Editor import passed
using the pinned engine. The ownership
audit reports 192 mapped scripts/UIDs and zero failures. This is scoped validation,
not a full-project validator run or owner acceptance. Initial sandboxed editor
imports encountered editor-directory/safe-save permission errors; the final import
with normal editor-directory access completed without those errors.
