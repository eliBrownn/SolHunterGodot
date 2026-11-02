extends RefCounted
## Editable anatomy studies, not newly approved roster species or affinity rules.
const Recipe = preload("res://scripts/sols/presentation/sol_design_recipe.gd")
## Each row owns three deliberately different structural starting points.
const CLASSES := [
	["beast", "Beast", ["Crown listener", "quadruped", "ruff", "ears,wings"], ["Tusk roller", "quadruped", "shell", "horns,muzzle"], ["Ribbon grazer", "biped", "antlers", "tail,ears"]],
	["cinderkin", "CinderKin", ["Ash fledgling", "avian", "feathers", "wings,tail"], ["Ember coil", "serpentine", "coil", "horns,tail"], ["Hearth bearer", "quadruped", "plates", "tail"]],
	["tideborn", "Abyssal", ["Marsh paddle", "aquatic", "sail", "fins,tail"], ["Sieve swimmer", "aquatic", "frill", "fins,muzzle"], ["Tidal bell", "aquatic", "bell", "fins"]],
	["verdant", "Bloom", ["Root blossom", "biped", "petal", ""], ["Walking mycelium", "biped", "mushroom", ""], ["Thorn lattice", "serpentine", "vine", ""]],
	["stormforged", "Stormforged", ["Resonant horn", "quadruped", "ruff", "horns,tail"], ["Drum sail", "avian", "sail", "wings"], ["Coil whisker", "serpentine", "threads", "ears,tail"]],
	["frostbound", "Frostbound", ["Folded glider", "quadruped", "fold", "fins,tail"], ["Snow mantle", "biped", "veil", "ears"], ["Ice spindle", "insectoid", "crystal", "tail"]],
	["warborn", "Warborn", ["Brow sentinel", "biped", "broadarms", "horns,muzzle"], ["Reed courser", "quadruped", "centaur", "tail"], ["Knuckle crest", "biped", "plates", "horns"]],
	["blightborn", "Blight", ["Bitter frill", "quadruped", "frill", "tail"], ["Sour carrier", "biped", "pouch", "muzzle"], ["Needle crawler", "insectoid", "spines", "tail"]],
	["earthbound", "Earthbound", ["Knuckle burrower", "quadruped", "burrow", "muzzle"], ["Silt shield", "quadruped", "shell", "tail"], ["Root snout", "serpentine", "broadarms", "muzzle,tail"]],
	["skyborne", "Zephyr", ["Crest sailer", "avian", "sail", "wings,tail"], ["Whirling fan", "avian", "fan", "wings"], ["Hooked wing", "biped", "slender", "wings,muzzle"]],
	["mindweaver", "Mindweaver", ["Glass throat", "biped", "bell", "ears,tail"], ["Dream seed", "serpentine", "petal", ""], ["Watching cairn", "biped", "totem", "horns"]],
	["swarmkin", "Chitin", ["Clasp beetle", "insectoid", "shell", "horns"], ["Spindle strider", "insectoid", "web", ""], ["Shield grub", "serpentine", "plates", "tail"]],
	["eldritch", "Eldritch", ["Folded watcher", "biped", "fold", ""], ["Wheel sense", "serpentine", "wheel", ""], ["Thread wake", "aquatic", "threads", ""]],
	["wraithborn", "Wraith", ["Mourning veil", "biped", "veil", ""], ["Hushed bell", "serpentine", "bell", ""], ["Afterimage paws", "quadruped", "ribbon", "tail"]],
	["wyrmkin", "Wyrmkin", ["Pebble wyrm", "quadruped", "plates", "horns,tail"], ["Fan drake", "avian", "fan", "horns,wings,tail"], ["Coiling wyrm", "serpentine", "coil", "horns,tail"]],
	["umbral", "Umbral", ["Veiled stalker", "quadruped", "mask", "ears,tail"], ["Occult lattice", "insectoid", "cage", "horns"], ["Shadow ribbon", "serpentine", "ribbon", "tail"]],
	["construct", "Construct", ["Kiln walker", "biped", "totem", ""], ["Living cage", "quadruped", "cage", ""], ["Jointed sentinel", "insectoid", "plates", "horns"]],
	["feyborn", "Feyborn", ["Thimble hart", "quadruped", "antlers", "ears,tail"], ["Petal dancer", "biped", "petal", "wings"], ["Masked flutter", "avian", "mask", "wings,tail"]]
]

static func presets(class_id: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for row in CLASSES:
		if row[0] != class_id: continue
		for index in 3:
			var form: Array = row[index + 2]
			var value := Recipe.fresh()
			value.name = form[0]
			var settings := Recipe.authoring_defaults()
			settings.class_id = class_id
			settings.body_plan = form[1]
			settings.structure = form[2]
			for module in Recipe.MODULES: settings.modules[module] = module in str(form[3]).split(",")
			settings.modules.anatomical_head = true
			value.design = settings
			# Distinct silhouette proportions supplement each structural attachment.
			value.body_length = [1.15, 1.55, 0.85][index]
			value.body_width = [0.65, 0.9, 0.45][index]
			value.body_height = [0.7, 0.5, 1.0][index]
			value.head_size = [0.55, 0.35, 0.65][index]
			value.leg_length = [0.65, 0.4, 0.95][index]
			value.wing_span = [1.0, 1.7, 0.8][index]
			value.tail_length = [0.6, 1.1, 0.4][index]
			value.structure_size = [0.7, 1.0, 0.55][index]
			value.notes = "%s anatomy study %d / %s. Editable proposal; does not approve a species, class mechanic, or traversal capability." % [row[1], index + 1, form[0]]
			results.append(value)
	return results
