extends RefCounted
## Read-only dossier built from the selected individual's actual saved data.
const GROUPS := {
	"overview": ["Health and progression", "Combat profile", "Readiness", "Identity", "Affinity and moves"],
	"combat": ["Combat profile", "Class ability", "Individual stats", "Loadout coverage"],
	"growth": ["Growth projection", "Individual potential", "Training capacity", "Health and progression"],
	"moves": ["Loadout coverage", "Equipped moves", "Other remembered moves", "Future species moves"],
	"history": ["Field notes", "Relationship record"]
}
static func sections(state: ExpeditionState, identity: String, controller: Node) -> Dictionary:
	var companion := state.companion_view(identity)
	if companion.is_empty():
		return {}
	var profile: Dictionary = companion.profile
	var record := state.individual_view(identity)
	var traits := state.stat_view(identity)
	var result := {}
	var active := state.active_sol_view()
	result["Identity"] = "Species: %s\n%s affinity · %s class\nForm %d · Footprint %d × %d tiles · %s%s" % [str(profile.display_name), str(record.affinity).capitalize(), SolSpeciesCatalog.class_display_name(record.class_id), int(record.ordinary_form), int(record.footprint), int(record.footprint), str(record.location).capitalize(), " · Active companion" if active.get("id", "") == identity else ""]
	result["Health and progression"] = "HP: %d / %d\nLevel: %d / %d\nTotal XP: %d" % [companion.hp, profile.max_hp, profile.level, controller.progression.level_cap, companion.xp]
	if int(profile.level) < controller.progression.level_cap:
		var threshold: int = controller.progression.threshold_factor * int(profile.level) * int(profile.level)
		result["Health and progression"] += "\nNext level: %d XP remaining (%d total required)" % [maxi(0, threshold - int(companion.xp)), threshold]
	else:
		result["Health and progression"] += "\nCurrent level cap reached."
	var missing := int(profile.max_hp) - int(companion.hp)
	result["Readiness"] = "Exhausted: recover at the refuge before deployment." if int(companion.hp) <= 0 else ("In storage: return to the party before deployment." if record.location != "party" else "Available for the next encounter.")
	result["Readiness"] += "\nMissing HP: %d" % missing
	result["Combat profile"] = "Physical offense: %d · Special offense: %d\nPhysical defense: %d · Special defense: %d\nSpeed: %d (opening initiative)" % [profile.attack, profile.special_attack, profile.defense, profile.special_defense, profile.speed]
	var definition: ClassBuffDefinition = controller.settings.class_buffs.definition(record.class_id)
	if definition != null:
		result["Class ability"] = definition.display_name + "\n" + definition.description
		if not traits.is_empty() and record.class_id != "earthbound":
			var unit := " tiles" if record.class_id == "skyborne" else (" turns" if record.class_id == "feyborn" else "%")
			result["Class ability"] += "\nThis individual's potency: %d%s" % [int(traits.potency), unit]
	if result.has("Class ability"):
		var settings: ClassBuffSettings = controller.settings.class_buffs
		match str(record.class_id):
			"verdant": result["Class ability"] += "\nCurrent battle healing cap: %d%% of maximum HP." % settings.verdant_healing_cap
			"cinderkin": result["Class ability"] += "\nCurrent accumulated bonus cap: %d%%." % settings.kindling_cap
			"stormforged": result["Class ability"] += "\nCurrent movement requirement: %d tiles." % settings.momentum_tiles
			"frostbound": result["Class ability"] += "\nCurrent health threshold: at or below %d%%." % settings.low_health_percent
			"wyrmkin": result["Class ability"] += "\nCurrent target threshold: above %d%% HP." % settings.wyrm_health_percent
			"wraithborn": result["Class ability"] += "\nCurrent minimum attack distance: %d tiles." % settings.wraith_distance
			"umbral": result["Class ability"] += "\nCurrent isolation radius: %d tiles." % settings.isolation_distance
	var stats := PackedStringArray()
	var natural: Dictionary = {}
	if not traits.is_empty():
		natural = traits.duplicate(true)
		for stat in SolStats.STATS:
			natural.training[stat] = 0
		natural = SolStats.resolve(natural, int(profile.level))
	for stat in SolStats.STATS:
		var name := "Maximum HP" if stat == "max_hp" else str(stat).replace("_", " ").capitalize()
		var text := "%s: %d" % [name, int(profile[stat])]
		if not traits.is_empty():
			text += " · IV %d%% · %d training points (+%.1f%%)" % [int(traits.ivs[stat]), int(traits.training[stat]), SolStats.bonus(traits, stat)]
			if natural.has(stat):
				text += " · %d without training" % int(natural[stat])
		stats.append(text)
	result["Individual stats"] = "\n\n".join(stats) + "\n\nAttack and Defense govern physical damage; Special attack and Special defense govern special damage. Speed determines opening initiative. IVs are this individual’s permanent potential; the without-training value includes its current level growth."
	if not traits.is_empty():
		var cap := SolStats.capacity(traits, int(record.ordinary_form))
		result["Training capacity"] = "Earned: %d\nAllocated: %d\nUnspent: %d\nCurrent form capacity: %d total / %d per stat\nRetraining items: %d\nIVs are lifelong potential; training is allocated separately. Use the Training tab to allocate or reset points." % [int(traits.earned), SolStats.spent(traits), int(traits.earned) - SolStats.spent(traits), int(cap.total), int(cap.stat), state.retraining_items()]
		var high := -1
		var low := 10000
		var highest := PackedStringArray()
		var lowest := PackedStringArray()
		for stat in SolStats.STATS:
			var value := int(traits.ivs[stat])
			var name := "HP" if stat == "max_hp" else str(stat).replace("_", " ").capitalize()
			if value > high:
				high = value
				highest.clear()
			if value == high:
				highest.append(name)
			if value < low:
				low = value
				lowest.clear()
			if value == low:
				lowest.append(name)
		result["Individual potential"] = "Highest IV: %s (%d%%)\nLowest IV: %s (%d%%)\nSaved potential range: %d–%d%%\nPotential never rerolls when stored, selected or trained." % [", ".join(highest), high, ", ".join(lowest), low, int(traits.policy.iv_min), int(traits.policy.iv_max)]
		if int(profile.level) < controller.progression.level_cap:
			var next := SolStats.resolve(traits, int(profile.level) + 1)
			var changes := PackedStringArray()
			for stat in SolStats.STATS:
				if next.has(stat):
					changes.append("%s: %d → %d" % ["HP" if stat == "max_hp" else str(stat).replace("_", " ").capitalize(), int(profile[stat]), int(next[stat])])
			result["Growth projection"] = "Next level, with current species and training:\n" + "\n".join(changes) + "\nThis comparison does not predict evolution or new training allocations."
		else:
			result["Growth projection"] = "Current level cap reached. No further level growth is projected."
	var book := state.movebook(identity)
	if not book.is_empty():
		var range_max := 0
		var affinities := PackedStringArray()
		var damage := PackedStringArray()
		var support := PackedStringArray()
		for id in book.equipped:
			var move: Dictionary = book.learned.get(id, {})
			if move.is_empty():
				continue
			range_max = maxi(range_max, int(move.reach))
			if not affinities.has(str(move.affinity).capitalize()):
				affinities.append(str(move.affinity).capitalize())
			if move.effect == "damage":
				damage.append("%s (%s, power %d)" % [move.name, str(move.get("category", "physical")), int(move.power)])
			else:
				support.append("%s (%s)" % [move.name, str(move.effect).capitalize()])
		result["Loadout coverage"] = "%d / 4 slots equipped\nLongest equipped move range: %d tiles\nDamage: %s\nSupport: %s\nTarget legality still depends on terrain, range and the move's effect." % [book.equipped.size(), range_max, "; ".join(damage) if not damage.is_empty() else "No damaging move equipped", "; ".join(support) if not support.is_empty() else "No support move equipped"]
		result["Affinity and moves"] = "Individual affinity: %s\nEquipped move affinities: %s\nA move keeps its own affinity; selecting a Sol does not convert its moves to that individual's affinity." % [str(record.affinity).capitalize(), ", ".join(affinities) if not affinities.is_empty() else "None"]
		var equipped := PackedStringArray()
		for slot in range(book.equipped.size()):
			var id: String = book.equipped[slot]
			var move: Dictionary = book.learned.get(id, {})
			if not move.is_empty():
				equipped.append("Slot %d · %s" % [slot + 1, controller.move_description(move)])
		result["Equipped moves"] = "\n\n".join(equipped) if not equipped.is_empty() else "No moves equipped."
		var remembered := PackedStringArray()
		for id in book.learned:
			if not book.equipped.has(id):
				remembered.append(controller.move_description(book.learned[id]))
		result["Other remembered moves"] = "\n\n".join(remembered) if not remembered.is_empty() else "All remembered moves are currently equipped."
		var future := PackedStringArray()
		for id in book.pool:
			if book.learned.has(id):
				continue
			var move: Dictionary = controller.library.find(id)
			if move.is_empty():
				continue
			future.append("%s · %s\n%s" % [move.name, "Level %d" % int(companion.unlocks[id]) if companion.unlocks.has(id) else "Unlock level not recorded", controller.move_description(move)])
		result["Future species moves"] = "\n\n".join(future) if not future.is_empty() else "No further moves in the current authored species pool."
	for entry in state.discovery_entries():
		if entry.key == identity:
			var notes: String = entry.description
			for text: String in entry.details:
				notes += "\n" + text
			result["Field notes"] = "First recorded at %d, %d\n%s" % [int(entry.first_seen[0]), int(entry.first_seen[1]), notes]
			break
	var relationship: Variant = state.relationship_view(identity)
	if relationship != null:
		result["Relationship record"] = "No trust rating is recorded." if relationship.trust == null else "Recorded trust: %d / 100" % int(relationship.trust)
		for memory in relationship.memories:
			result["Relationship record"] += "\n%s · %s" % [str(memory.kind).replace("_", " ").capitalize(), memory.note]
	if not result.has("Field notes"):
		result["Field notes"] = "No field observation is recorded for this individual."
	if not result.has("Relationship record"):
		result["Relationship record"] = "No relationship evidence is recorded for this individual."
	return result
static func build(screen: Node, target: VBoxContainer) -> Dictionary:
	var data := sections(screen.world.persistent_state, screen.menu.sol_selection, screen.controller)
	var navigation := HFlowContainer.new()
	target.add_child(navigation)
	for group in GROUPS:
		var control: Button = screen.menu.button(str(group).capitalize(), screen.set_info_section.bind(group), navigation)
		screen.info_groups[group] = control
		control.toggle_mode = true
		control.set_pressed_no_signal(screen.menu.sol_info_section == group)
		control.tooltip_text = ", ".join(GROUPS[group])
	var headings: Array = GROUPS.get(screen.menu.sol_info_section, GROUPS.overview)
	for heading in headings:
		if data.has(heading):
			target.add_child(screen.menu.caption(heading, 18, screen.menu.settings.accent))
			target.add_child(screen.menu.caption(str(data[heading]), 16))
	return data
static func build_starter(screen: Node, target: VBoxContainer, profile: Dictionary) -> void:
	target.add_child(screen.menu.caption("Starting species profile", 18, screen.menu.settings.accent))
	target.add_child(screen.menu.caption("Individual potential and class potency are assigned when this companion joins.", 16))
	for stat in SolStats.STATS:
		target.add_child(screen.menu.caption("%s: %d" % ["HP" if stat == "max_hp" else str(stat).replace("_", " ").capitalize(), int(profile[stat])], 16))
	var ability: ClassBuffDefinition = screen.controller.settings.class_buffs.definition(profile.class_id)
	if ability != null:
		target.add_child(screen.menu.caption(ability.display_name, 18, screen.menu.settings.accent))
		target.add_child(screen.menu.caption(ability.description, 16))
