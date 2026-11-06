# Landmark placeholder library

Downloaded October 29, 2026 from Kenney's official download service in response
to the owner's request for more location focal points and interaction placeholders.
These are provisional art ingredients, not approved lore, quests or final visuals.

| Pack | Version | Selected models | Official source |
| --- | --- | --- | --- |
| Fantasy Town Kit | 2.0 | 11 | https://kenney.nl/assets/fantasy-town-kit |
| Graveyard Kit | 5.0 | 8 | https://kenney.nl/assets/graveyard-kit |
| Castle Kit | 2.0 | 6 | https://kenney.nl/assets/castle-kit |

All three supplied `License.txt` files explicitly declare Creative Commons Zero
(CC0); they are preserved unchanged in each pack directory. Creator: Kenney.
`provenance.json` records official source pages, archive hashes, original archive
paths, selected model hashes and sizes. Original archives remain in the ignored
`artifacts/landmark_asset_review` directory. The 25 models total 748,272 bytes;
each pack's required `Textures/colormap.png` is included. Model bytes are unchanged;
local filenames use snake_case. No vendor scripts or demo logic were adopted.

## Location ingredients

| Provisional focal point | Assets | Possible review purpose |
| --- | --- | --- |
| Wayside meeting place | Town cart, stall, bench, lantern | Recognizable human presence; space for a later local interaction |
| Fountain clearing | Town round fountain | Distinct gathering/discovery location; no healing effect implied |
| Broken gateway | Town arch and broken wall | Visible detour destination and environmental clue |
| Old lookout | Castle square tower and top | Distant orientation landmark; no climbable interior implied |
| Stone observation site | Obelisk, column, stone altar | Placeholder for a Vastra clue; no new religion or magical rule implied |
| Weathered stone shelter | Crypt shell/door, damaged wall and bench | Localized unease; pack names do not establish SolHunter lore |
| Crossing study | Castle bridge and support | Composition candidate only; requires terrain/access/collision integration |

Windmill and watermill models are mechanism pieces, not complete buildings.
Combine with existing authored structures only after checking scale and fit.
Keep these as a small reusable library; first prove a few distinct compositions.

## Integration boundary

The assets are available under `res://assets/landmarks/` but are not scattered
into the main world. Site placement must use existing geography and site ownership,
preserve essential routes and reserve usable approach/interaction space. Cosmetic
mesh selection must not become the owner of saved place or participant identity.
Bridges and towers do not provide traversal or collision merely by being imported.
Use existing supported actions first; consult the mechanics reference before
adding interaction rules. No campaign expansion or deep future system is implied.

## Validation

Godot 4.7.2 stable imported the selected library in an isolated review project;
all 25 PackedScenes instantiated with mesh descendants. Clean import and load logs
contain no engine/script errors. Logs are under
`artifacts/landmark_asset_review/{import_clean,check_clean}.log`.
Archive structure, GLB headers, external palette dependencies and supplied licenses
were checked. World placement, visual fit, collision and interaction behavior have
not been accepted by this asset-library check.
