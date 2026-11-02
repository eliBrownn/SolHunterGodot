class_name ExpeditionContract
extends RefCounted
## Shared persistence bounds and clock contract; no mutable expedition dependency.

const MAX_ROAMING_DISTANCE := 5 # Saved movement schema bound; tuning may choose a smaller home range.
const ACTIVITY_INTERVAL := 0.75
const MAX_SAFE_INTEGER := 9007199254740991 # Exact JSON integer range.
const MAX_INDIVIDUALS := 2048
const MAX_TILE_DELTAS := 8192
const OWNED_LOCATIONS := ["sealed", "party", "storage"]
