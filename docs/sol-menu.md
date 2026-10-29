# Sol companion menu: phase 4 first slice

Owner direction: October 27, 2026. Use Pokémon as an interaction reference while
keeping original SolHunter styling, terms, models and gameplay. The reference is
Nintendo's [Scarlet/Violet tips](https://www.nintendo.com/au/news-and-articles/12-spoiler-free-tips-to-kickstart-your-pokemon-scarlet-and-pokemon-violet/),
particularly select companion → summary → moves/stats and separate collection
navigation. No Pokémon art or interface assets are used.

## Implemented behavior

Open Sols with C or R → Sols. Party and Storage have visible companion lists with
name, level, HP and an active marker. Inspecting a row does not change the next
battler. Set active explicitly chooses the [exploration companion](owned-companion.md)
and next battler; storage and party capacity
restrictions remain owned by ExpeditionState. After a transfer, inspection follows
the same individual into its destination view. The last inspected individual,
filter, detail tab and scroll positions survive ordinary menu navigation; new/load
clears the old identity. These presentation choices do not enter expedition saves.

Summary, Moves and Training separate existing information and commands. Summary
keeps HP visible and offers XP/stats on the model hover card; Moves uses existing remembered/equipped pools,
with effect descriptions and tooltips before selection. Training retains exact
IVs, earned allocations and the existing reset-item confirmation. A reset dialog
binds to its original individual/state rather than a later inspected companion.
Unimplemented relationship/evolution meters are not invented.

Starter rows inspect before granting anything. A separate Choose button commits
the one-time starter choice; existing 1–3 shortcuts remain supported.

## Model window

The selected individual is displayed in a dedicated SubViewport with its own
3D world, light, environment and camera. It instantiates the actual SolOrb model
used in the game with the individual's assigned affinity and effects. Current
owner-approved Sol models are affinity orbs; no replacement creature art is implied.
The camera fits model diameter/effect margin to the preview window's aspect ratio,
including tall/narrow windows. Preview rendering and animation never mutate
collection, movement, progression or saves. Hidden previews stop updating.
The legacy standalone loadout and encounter starter chooser also include the
same preview component. Menu-owned confirmations close with their menu so an
encounter cannot leave a hidden personal-screen dialog blocking battle input.

Interface → Menu Settings exposes Preview Height (140–320 logical pixels, default
140) and Preview Framing (2–4 diameters, default 2.5). Reopen the page after editing
these defaults. Shared Sol Visual Settings continues to own model diameter,
affinity palette and effects.

## Text and responsive layout

Options → Text size adjusts interface text from 100–200%, independently of
the existing compact menu scale. Larger text grows the menu within the viewport;
list/detail columns stack when space is tight, and content remains scrollable.
Typography stores original font sizes to avoid multiplying scale every frame.
The optional text_scale preference is validated atomically and defaults correctly
for older version-1 preference files. No expedition save schema changes.

The October 28 blocker pass extends this preference across exploration, combat,
encounters, pause, context menus, confirmations and result recaps. Personal
navigation and scrolled content remain reachable in the tested large-text layouts.
Complete controller and physical-device accessibility acceptance remain open.
The live R menu, Escape pause and automatic screen fitting remain in place.

## Mechanics evidence

Read-only SolHunterSource development/world-redesign-0.2 at
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4` was consulted through
`src/systems/tactics/party.py`, `party_switching.py`, and
`tests/test_party_transfer_safety.py`. Stable individual selection and safe
transfers are preserved through the existing Godot collection authority. No new
party limit, storage rule or battle switching rule is introduced.

## Validation

The new tests/sol_menu.gd covers starter inspection, actual-affinity models,
read-only previews, explicit active selection, party/storage transfers, move
information, tab/selection retention, responsive large text and preference safety.
Run with -- --capture-sol-menu for ignored artifacts/sol-menu/ screenshots.
Godot 4.7.2 import and the full validator passed 11,158 checks across 35 reported
suites. The new companion suite passed 25 checks headless and rendered, including
native mouse selection. The final stats/training suite separately passed 3,685
checks after dialog-lifecycle review. Starter, summary and large-text screenshots
were inspected; logs are under ignored artifacts/phase4-*.log. Scripted/rendered
checks do not establish exported-build or new-player acceptance.

## UI cleanup: information on hover

The visible companion page prioritizes the model, name, affinity, HP and actions.
Class/level details, party/storage counts and action restrictions are available
through hover tooltips. Repeated headings, numbered navigation, drag instructions,
permanent help paragraphs and duplicate party-count rows were removed. Recovery
appears as a compact action when relevant. Exact stats are available on the model hover card, and detailed training remains
behind its tab. Move descriptions
are available on the equipment controls/popups instead of repeated paragraphs.

Exploration HUD branding/control paragraphs and battle move metadata were also
trimmed. Capture chance, target damage previews, status effects and enemy intent
remain visible; move range/effect and testing-supply explanations use hover details.
A native tooltip capture is available at artifacts/sol-menu/hover.png.

The follow-up thin pass uses shorter controls, narrower flat navigation, smaller
padding/corners and lighter button surfaces. The active section retains a gold
text indicator. XP and summary stat numbers are on the model hover card; the
Training tab retains the full explicit stat/allocation view. Success messages
fade from the layout after three seconds without deleting their recorded text.

## Extensive information: Details tab

The clean Summary/hover view is complemented by an explicit, scrollable Details
tab. It reports saved species, individual affinity/class, form, footprint, party
location, HP, level/cap, total XP and remaining XP to the next threshold. It shows
the actual class ability description and individual potency, all six resolved
stats with IVs/training bonuses/untrained comparisons, training budgets, equipped
and remembered move descriptions, future authored moves and recorded unlock levels.
Recorded sightings and relationship notes appear when available; unknown trust
or unlock levels are identified as unrecorded instead of invented.

Stat explanations follow TacticalBattle's physical/special damage and opening
initiative calculations. SolStats supplies the saved IV/training breakdown and
current-form capacities. The private source's older genetics/training code was
consulted at the previously recorded commit for the separation of individual
potential and training; no legacy numeric formulas were imported over Godot's
existing approved/saved values. Details is read-only and inspection never switches
the active companion. Starter Details shows the authored species baseline and
class ability without claiming that individual IVs/potency already exist.

The shared validator passed 11,166 checks across 35 reported suites. The final
rendered companion suite passed 34 checks, including additional starter-detail
coverage, real stat/ability/move values, saved field notes, unknown relationship
ratings and snapshot immutability. Details was visually inspected; evidence is
artifacts/sol-details-validation.log and artifacts/sol-details-render.log.

## Expanded information system

Sols now opens its information-rich Details overview by default on a fresh session,
new expedition or load. Quick Summary remains available, and ordinary menu visits
retain the user's chosen page. Details has direct Overview, Combat, Growth, Moves
and History selectors rather than one long undifferentiated dossier. Its model
window is more compact and redundant action/health rows are omitted there to put
information above the fold.

Overview adds readiness, missing HP, physical/special offense and defense, opening
initiative, and the distinction between the individual's affinity and equipped
move affinities. Combat adds the authored passive, the individual's potency and
current configured passive limits, plus damaging/support move coverage and longest
equipped range. It does not invent opponent-independent exact damage or a type chart.
Growth compares next-level stats using SolStats.resolve with saved IVs, growth and
current training; it labels the fixed-species/training assumption. Highest/lowest
IVs and the individual's saved potential range explain differences between Sols.
Moves separates equipped, remembered and future authored abilities. History reports
actual sightings/memories and explicitly identifies missing evidence.

Progression/relationship reference use at the recorded SolHunterSource commit is
read-only. Existing Godot saved-stat, class-passive and move implementations remain
the numerical authority for these views; no injury, temperament, evolution, trust
or ecology rules are invented to fill gaps. New UI classifications and projections
are presentation only and cannot select a companion or commit a gameplay change.

Expanded-system verification: the full validator passed all reported suites,
including the checkout's terrain suites and both exploration journeys. The final
rendered Sol-menu suite passed 41 checks, covering default information-page entry,
category navigation, saved potential comparisons, real next-level projections,
current passive limits and read-only browsing. Overview, Combat and Growth captures
were visually inspected. Logs: artifacts/sol-info-expanded-validation.log and
artifacts/sol-info-expanded-render-final.log. The last presentation refinements
were checked in the focused rendered suite. New-player/export acceptance remains
separate from these automated/rendered checks.

Training allocation/reset now refreshes the surrounding Sol screen on committed
state changes, retaining selection and scroll and restoring usable focus. Roster
HP, model tooltip/profile, the health meter and dossier read the same current
resolved stats without requiring a tab switch. Training rules and saves are unchanged.
See [UI/UX roadmap](ui-ux-roadmap.md) for regression evidence.
