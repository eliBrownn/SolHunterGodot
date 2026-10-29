# Story event tools

October 28, 2026. First implementation slice, authorized alongside exploration,
companions, combat, performance/controller polish and connected validation.
The owner continues authoring [the story](story.md); preview text is a development
fixture and establishes no campaign facts.

## Try the writing preview

Open `scenes/story_workshop.tscn` and press F6. The two upper-right buttons open
dialogue and its conditional follow-up over the actual expedition. Leave records
nothing; explicit acknowledgment unlocks the follow-up. Dialogue suspends movement
and active exploration time. Mouse and the existing controller navigation can
choose or leave; controller focus starts on Leave.

The workshop routes its field-menu and F5/F9 saves to
`artifacts/story-preview/expedition.json`, separate from the normal expedition.
Start a new expedition to reset preview decisions. The normal F5 game creates no
campaign conversation or automatic story triggers.

## Author an interaction

Create a `StoryEvent` Resource with a stable lower-case ID, title, optional speaker,
plain text and up to eight `StoryChoice` resources. Each choice has its own stable
ID and label. `requires` compares explicit saved string facts; `sets` assigns
facts only when that choice commits. For example, a recipient-specific
`refuge.resident_a.heard_grove = yes` can distinguish telling that person from
simply witnessing something. This is an example of storage, not approved content.

Edit `resources/story_preview/arrival.tres` and `follow_up.tres` in the Inspector
for examples, or add an event to the workshop's Preview Events list. Runtime
callers use `host.story.play(event_resource)` at an authored interaction point;
the call returns false when prerequisites or safe interaction conditions fail.

Each event accepts one explicit decision per expedition. Use distinct event IDs
for later conversations; revising prose must retain IDs. Leaving can reopen the
same unanswered event. Conditions are rechecked at selection; completed events
cannot commit twice. A decision and its facts commit together, subject to bounded
save validation. `ExpeditionState.story_changed` and the director's `finished`
signal expose successful choices. Neither signal grants gameplay rewards.

World-state version 17 stores facts and event/choice/tick records inside the
existing expedition save. Views are copies. Unknown saved event IDs are retained
so editing the current content list cannot erase previous history. New expeditions
start empty. This foundation does not implement quest objectives, rewards, trust,
cutscenes, automatic triggers, pending-dialogue resumption or campaign branches.
New consequential mechanics still require their own authored specifications.

## Mechanics evidence

Read-only source: `eliBrownn/SolHunterSource`,
`development/world-redesign-0.2`, commit
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`:
`src/systems/ai/quest_contracts.py`, `src/systems/ai/dialogue.py` and
`tests/test_quest_state_contracts.py`. These establish explicit persisted decisions,
prerequisite checks, rejected decisions leaving state unchanged and terminal
completion without repeated rewards. This Godot foundation reuses those safety
properties, without importing generated quests, objective rules or reward values.
The source's reversible ordinary quest declines do not specify the campaign's
permanent legendary refusal; no such choice is implemented here.

## First connected polish pass

- Exploration: the camera endpoint stays above terrain at low orbits; losing
  window focus releases mouse orbit.
- Companions: captions sit above species bounds and follow terrain/flight height;
  routine Following/Resting subtitles are optional, while blocked-route and
  personality captions remain visible.
- Combat: selected legal moves preview their AP cost and remaining AP; a fully
  spent movement/action budget visibly points to End turn. Compact HUD remains.
- Performance/controller: avoid repeated unchanged player overlay assignments;
  controller focus memory is bounded, empty pages clear stale selection, read-only
  sliders are skipped, and delayed focus scrolling tolerates rebuilt pages.
- Story tools and persistence: conditional dialogue and atomic, once-per-event
  decisions save/load through the same expedition authority as Sol identities.

These are first increments across the six work areas, not final acceptance of
visual cohesion, companionship, combat pacing or handheld performance. No FPS
improvement or physical-controller/Thor acceptance is claimed.

## Validation

Pinned Godot 4.7.2: `tests/connected_polish.gd` passed 32 focused headless checks;
the existing `tests/smoke.gd -- --scene=res://scenes/world_3d.tscn` passed 2,506
checks covering travel and current-format save/load. Final focused and journey
logs contain no engine/script errors. The full validator was not run for this
first pass, per the owner's request to keep testing proportionate.

A targeted rendered OpenGL preview opened a visible, embedded 620×440 dialogue;
the capture was inspected for prose, choices and initial Leave focus. A prior
combined render also provided the compact spent-budget combat capture. Visual
checking caught and corrected sizing from the hidden simulation viewport, and
preview scene construction was corrected to avoid replacing an already-created
world script and leaking its initial nodes. Final focused/preview runs exited
cleanly. Logs and captures are under `artifacts/connected-polish/`.
