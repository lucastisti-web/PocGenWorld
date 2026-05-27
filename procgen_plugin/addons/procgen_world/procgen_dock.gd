@tool
extends Control

# ─── Riferimento editor ──────────────────────────────────────
var editor_plugin = null

# ─── Lingue ──────────────────────────────────────────────────
var current_lang: String = "en"
const STRINGS := {
	"en": {
		"title":        "ProcGen World Generator",
		"tab_generate": "🌍 Generate",
		"tab_tileset":  "🧱 Tilesets",
		"tab_help":     "❓ Help",
		"world_size":   "World Size",
		"width":        "Width (tiles)",
		"height":       "Height (tiles)",
		"seed":         "Seed",
		"random_seed":  "🎲 Random",
		"terrain":      "Terrain",
		"sea_level":    "Sea Level",
		"roughness":    "Roughness",
		"deco_density": "Decoration Density",
		"biomes":       "Active Biomes",
		"btn_generate": "▶ Generate on TileMap",
		"btn_clear":    "🗑 Clear",
		"generating":   "Generating...",
		"done":         "✅ Done! World generated.",
		"no_tilemap":   "⚠ No TileMap found in the open scene.",
		"tileset_title":"Custom Tilesets",
		"tileset_info": "Add your own tilesets to extend the generator.",
		"help_text":    "1. Open a scene with a TileMap node\n2. Set your parameters\n3. Press Preview to see the result\n4. Press Generate to place tiles\n\nTip: Use Seed to reproduce the same world.",
	},
	"it": {
		"title":        "Generatore di Mondo Procedurale",
		"tab_generate": "🌍 Genera",
		"tab_tileset":  "🧱 Tileset",
		"tab_help":     "❓ Aiuto",
		"world_size":   "Dimensione Mondo",
		"width":        "Larghezza (tile)",
		"height":       "Altezza (tile)",
		"seed":         "Seed",
		"random_seed":  "🎲 Casuale",
		"terrain":      "Terreno",
		"sea_level":    "Livello del Mare",
		"roughness":    "Rugosità",
		"deco_density": "Densità Decorazioni",
		"biomes":       "Biomi Attivi",
		"btn_generate": "▶ Genera su TileMap",
		"btn_clear":    "🗑 Pulisci",
		"generating":   "Generazione in corso...",
		"done":         "✅ Fatto! Mondo generato.",
		"no_tilemap":   "⚠ Nessun TileMap trovato nella scena aperta.",
		"tileset_title":"Tileset Personalizzati",
		"tileset_info": "Aggiungi i tuoi tileset per estendere il generatore.",
		"help_text":    "1. Apri una scena con un nodo TileMap\n2. Imposta i parametri\n3. Premi Anteprima per vedere il risultato\n4. Premi Genera per piazzare i tile\n\nSuggerimento: usa il Seed per riprodurre lo stesso mondo.",
	}
}

# ─── Colori biomi per preview ─────────────────────────────────
const BIOME_COLORS := {
	"sky":        Color(0.53, 0.81, 0.98),
	"grass":      Color(0.30, 0.69, 0.31),
	"dirt":       Color(0.47, 0.33, 0.28),
	"stone":      Color(0.47, 0.47, 0.47),
	"water":      Color(0.13, 0.59, 0.95),
	"snow":       Color(0.90, 0.96, 1.00),
	"lava":       Color(1.00, 0.34, 0.13),
	"decoration": Color(0.20, 0.42, 0.12),
}

# ─── Nodi UI ─────────────────────────────────────────────────
var tab_container   : TabContainer
var status_label    : Label


# Parametri
var spin_width      : SpinBox
var spin_height     : SpinBox
var spin_seed       : SpinBox
var slider_sea      : HSlider
var slider_rough    : HSlider
var slider_deco    : HSlider
var label_sea       : Label
var label_rough     : Label
var label_deco     : Label

# Biome buttons
var biome_buttons   : Dictionary = {}
var biome_zones     : Dictionary = {}
var custom_mode     : bool = false
var zones_container : VBoxContainer

# Labels da aggiornare con la lingua
var ui_labels       : Dictionary = {}

# Strutture
var slider_struct   : HSlider
var label_struct    : Label
var presets_list    : VBoxContainer
var preset_name_input : LineEdit
var presets_data    : Dictionary = {}

# Strutture template [dx, dy, tile_id, tileset]
# Tile industrial: 16 colonne, id->atlas: col=id%16, row=id//16
const STRUCTURES := {
	# Torre: 68-52-36 sx, 69-53-37 centro, 70-54-38 dx
	"tower": [
		[0,-3,"i36"],[1,-3,"i37"],[2,-3,"i38"],
		[0,-2,"i52"],[1,-2,"i53"],[2,-2,"i54"],
		[0,-1,"i68"],[1,-1,"i69"],[2,-1,"i70"],
	],
	# Portale senza tubo: solo 2 colonne cartello 74-58-42-26
	"portal": [
		[0,-4,"i26"],[3,-4,"i26"],
		[0,-3,"i42"],[3,-3,"i42"],
		[0,-2,"i58"],[3,-2,"i58"],
		[0,-1,"i74"],[3,-1,"i74"],
	],
	# Muro/rovine: base 0-1-2-3, struttura 4-5-6
	"ruins": [
		[0,-2,"i4"],[1,-2,"i5"],[2,-2,"i6"],
		[0,-1,"i0"],[1,-1,"i1"],[2,-1,"i2"],[3,-1,"i3"],
	],
	# Edificio: 20-21-22 tetto, 66-67-83 finestre, 0-1-2 base
	"building": [
		[0,-3,"i20"],[1,-3,"i21"],[2,-3,"i22"],
		[0,-2,"i66"],[1,-2,"i67"],[2,-2,"i83"],
		[0,-1,"i0"],[1,-1,"i1"],[2,-1,"i2"],
	],
	# Cartello singolo: 1 colonna 74-58-42-26
	"sign": [
		[0,-4,"i26"],
		[0,-3,"i42"],
		[0,-2,"i58"],
		[0,-1,"i74"],
	],
	# Tubo nel terreno: 108-109-110-111 orizzontale dentro il suolo
	"pipe": [
		[0,0,"i108"],[1,0,"i109"],[2,0,"i110"],[3,0,"i111"],
	],
}

# ─── Stato ───────────────────────────────────────────────────
var world_data      : Array = []
var world_w         : int = 100
var world_h         : int = 60

# ─────────────────────────────────────────────────────────────
func _init() -> void:
	custom_minimum_size = Vector2(300, 180)

func _ready() -> void:
	_build_ui()

func t(key: String) -> String:
	return STRINGS[current_lang].get(key, key)

# ─────────────────────────────────────────────────────────────
#  Costruzione UI
# ─────────────────────────────────────────────────────────────
func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# ── Toolbar ──
	var toolbar := HBoxContainer.new()
	root.add_child(toolbar)

	var title := Label.new()
	title.text = "🌍 ProcGen World"
	title.add_theme_color_override("font_color", Color(0.3, 0.85, 0.5))
	title.add_theme_font_size_override("font_size", 13)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(title)

	# Switch lingua
	var lang_btn := Button.new()
	lang_btn.text = "🇮🇹 ITA"
	lang_btn.pressed.connect(func():
		current_lang = "it" if current_lang == "en" else "en"
		lang_btn.text = "🇬🇧 ENG" if current_lang == "it" else "🇮🇹 ITA"
		_update_labels()
	)
	toolbar.add_child(lang_btn)

	# ── Tab container ──
	tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tab_container)

	_build_tab_generate()
	_build_tab_tileset()
	_build_tab_presets()
	_build_tab_help()

	# ── Status ──
	status_label = Label.new()
	status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.add_theme_font_size_override("font_size", 11)
	root.add_child(status_label)

# ─────────────────────────────────────────────────────────────
#  Tab: Genera
# ─────────────────────────────────────────────────────────────
func _build_tab_generate() -> void:
	var tab := ScrollContainer.new()
	tab.name = t("tab_generate")
	tab.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_container.add_child(tab)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	tab.add_child(vbox)

	# ── Dimensioni ──
	var size_lbl := Label.new()
	size_lbl.text = t("world_size")
	size_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.5))
	ui_labels["world_size"] = size_lbl
	vbox.add_child(size_lbl)

	var size_row := HBoxContainer.new()
	vbox.add_child(size_row)

	var lbl_w := Label.new()
	lbl_w.text = t("width") + ":"
	ui_labels["width"] = lbl_w
	size_row.add_child(lbl_w)

	spin_width = SpinBox.new()
	spin_width.min_value = 20
	spin_width.max_value = 500
	spin_width.value = 100
	spin_width.step = 10
	size_row.add_child(spin_width)

	var lbl_h := Label.new()
	lbl_h.text = "  " + t("height") + ":"
	ui_labels["height"] = lbl_h
	size_row.add_child(lbl_h)

	spin_height = SpinBox.new()
	spin_height.min_value = 20
	spin_height.max_value = 300
	spin_height.value = 60
	spin_height.step = 10
	size_row.add_child(spin_height)

	# ── Seed ──
	var seed_row := HBoxContainer.new()
	vbox.add_child(seed_row)

	var lbl_seed := Label.new()
	lbl_seed.text = t("seed") + ":"
	ui_labels["seed"] = lbl_seed
	seed_row.add_child(lbl_seed)

	spin_seed = SpinBox.new()
	spin_seed.min_value = 0
	spin_seed.max_value = 99999
	spin_seed.value = 42
	spin_seed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_row.add_child(spin_seed)

	var rand_btn := Button.new()
	rand_btn.text = t("random_seed")
	ui_labels["random_seed"] = rand_btn
	rand_btn.pressed.connect(func(): spin_seed.value = randi() % 99999)
	seed_row.add_child(rand_btn)

	# ── Sliders terreno ──
	var terrain_lbl := Label.new()
	terrain_lbl.text = t("terrain")
	terrain_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.5))
	ui_labels["terrain"] = terrain_lbl
	vbox.add_child(terrain_lbl)

	# Sea level
	var sea_row := HBoxContainer.new()
	vbox.add_child(sea_row)
	label_sea = Label.new()
	label_sea.text = t("sea_level") + ": 70%"
	label_sea.custom_minimum_size = Vector2(160, 0)
	ui_labels["sea_level"] = label_sea
	sea_row.add_child(label_sea)
	slider_sea = HSlider.new()
	slider_sea.min_value = 10
	slider_sea.max_value = 90
	slider_sea.value = 70
	slider_sea.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_sea.value_changed.connect(func(v): label_sea.text = t("sea_level") + ": %d%%" % v)
	sea_row.add_child(slider_sea)

	# Roughness
	var rough_row := HBoxContainer.new()
	vbox.add_child(rough_row)
	label_rough = Label.new()
	label_rough.text = t("roughness") + ": 50%"
	label_rough.custom_minimum_size = Vector2(160, 0)
	ui_labels["roughness"] = label_rough
	rough_row.add_child(label_rough)
	slider_rough = HSlider.new()
	slider_rough.min_value = 1
	slider_rough.max_value = 100
	slider_rough.value = 50
	slider_rough.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_rough.value_changed.connect(func(v): label_rough.text = t("roughness") + ": %d%%" % v)
	rough_row.add_child(slider_rough)

	# Cave density
	var deco_row := HBoxContainer.new()
	vbox.add_child(deco_row)
	label_deco = Label.new()
	label_deco.text = t("deco_density") + ": 30%"
	label_deco.custom_minimum_size = Vector2(160, 0)
	ui_labels["deco_density"] = label_deco
	deco_row.add_child(label_deco)
	slider_deco = HSlider.new()
	slider_deco.min_value = 0
	slider_deco.max_value = 100
	slider_deco.value = 30
	slider_deco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_deco.value_changed.connect(func(v): label_deco.text = t("deco_density") + ": %d%%" % v)
	deco_row.add_child(slider_deco)

	# Struct density
	var struct_row := HBoxContainer.new()
	vbox.add_child(struct_row)
	label_struct = Label.new()
	label_struct.text = "Structures: 0%"
	label_struct.custom_minimum_size = Vector2(160, 0)
	struct_row.add_child(label_struct)
	slider_struct = HSlider.new()
	slider_struct.min_value = 0
	slider_struct.max_value = 100
	slider_struct.value = 0
	slider_struct.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_struct.value_changed.connect(func(v): label_struct.text = "Structures: %d%%" % v)
	struct_row.add_child(slider_struct)

	# ── Biome buttons ──
	var biome_lbl := Label.new()
	biome_lbl.text = t("biomes")
	biome_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.5))
	ui_labels["biomes"] = biome_lbl
	vbox.add_child(biome_lbl)

	var biome_row := HBoxContainer.new()
	biome_row.add_theme_constant_override("separation", 4)
	vbox.add_child(biome_row)

	var biome_defs := [
		["grass",  "🌿", Color(0.30, 0.69, 0.31)],
		["water",  "💧", Color(0.13, 0.59, 0.95)],
		["snow",   "❄️",  Color(0.80, 0.90, 1.00)],
		["lava",   "🌋", Color(1.00, 0.34, 0.13)],
	]
	# Terra attiva di default
	for bd in biome_defs:
		var btn := Button.new()
		btn.text = bd[1]
		btn.tooltip_text = bd[0]
		btn.toggle_mode = true
		btn.button_pressed = true
		btn.custom_minimum_size = Vector2(42, 32)
		# Colori ON/OFF chiari
		var style_on := StyleBoxFlat.new()
		style_on.bg_color = bd[2]
		style_on.border_width_top = 2
		style_on.border_width_bottom = 2
		style_on.border_width_left = 2
		style_on.border_width_right = 2
		style_on.border_color = Color(1,1,1,0.8)
		style_on.corner_radius_top_left = 4
		style_on.corner_radius_top_right = 4
		style_on.corner_radius_bottom_left = 4
		style_on.corner_radius_bottom_right = 4
		var style_off := StyleBoxFlat.new()
		style_off.bg_color = Color(0.15, 0.15, 0.15)
		style_off.border_width_top = 2
		style_off.border_width_bottom = 2
		style_off.border_width_left = 2
		style_off.border_width_right = 2
		style_off.border_color = Color(0.4, 0.4, 0.4)
		style_off.corner_radius_top_left = 4
		style_off.corner_radius_top_right = 4
		style_off.corner_radius_bottom_left = 4
		style_off.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", style_off)
		btn.add_theme_stylebox_override("pressed", style_on)
		btn.add_theme_stylebox_override("hover", style_off)
		btn.add_theme_font_size_override("font_size", 16)
		biome_buttons[bd[0]] = btn
		biome_row.add_child(btn)

	# ── Toggle Random / Custom ──
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	vbox.add_child(mode_row)

	var mode_lbl := Label.new()
	mode_lbl.text = "Biome Mode:"
	mode_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.5))
	mode_row.add_child(mode_lbl)

	var random_mode_btn := Button.new()
	random_mode_btn.text = "🎲 Random"
	random_mode_btn.toggle_mode = true
	random_mode_btn.button_pressed = true
	var custom_mode_btn := Button.new()
	custom_mode_btn.text = "🎛 Custom Zones"
	custom_mode_btn.toggle_mode = true
	custom_mode_btn.button_pressed = false
	mode_row.add_child(random_mode_btn)
	mode_row.add_child(custom_mode_btn)

	# ── Container zone custom (nascosto di default) ──
	zones_container = VBoxContainer.new()
	zones_container.visible = false
	vbox.add_child(zones_container)

	var zones_lbl := Label.new()
	zones_lbl.text = "Zones per biome (0 = disabled):"
	zones_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	zones_lbl.add_theme_font_size_override("font_size", 11)
	zones_container.add_child(zones_lbl)

	var zone_biomes := [
		["grass", "🌿 Grass"],
		["water", "💧 Water"],
		["snow",  "❄️ Snow"],
		["lava",  "🌋 Lava"],
	]
	for zb in zone_biomes:
		var row := HBoxContainer.new()
		zones_container.add_child(row)
		var lbl := Label.new()
		lbl.text = zb[1]
		lbl.custom_minimum_size = Vector2(100, 0)
		row.add_child(lbl)
		var spin := SpinBox.new()
		spin.min_value = 0
		spin.max_value = 50
		spin.value = 5 if zb[0] == "grass" else 2
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spin)
		biome_zones[zb[0]] = spin

	# Toggle logica
	random_mode_btn.pressed.connect(func():
		custom_mode = false
		random_mode_btn.button_pressed = true
		custom_mode_btn.button_pressed = false
		zones_container.visible = false
	)
	custom_mode_btn.pressed.connect(func():
		custom_mode = true
		custom_mode_btn.button_pressed = true
		random_mode_btn.button_pressed = false
		zones_container.visible = true
	)

	# ── Bottoni azione ──
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	vbox.add_child(btn_row)

	var gen_btn := Button.new()
	gen_btn.text = t("btn_generate")
	gen_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_labels["btn_generate"] = gen_btn
	gen_btn.pressed.connect(_on_generate_pressed)
	btn_row.add_child(gen_btn)

	var clr_btn := Button.new()
	clr_btn.text = t("btn_clear")
	ui_labels["btn_clear"] = clr_btn
	clr_btn.pressed.connect(_on_clear_pressed)
	btn_row.add_child(clr_btn)

# ─────────────────────────────────────────────────────────────
#  Tab: Tileset
# ─────────────────────────────────────────────────────────────
func _build_tab_tileset() -> void:
	var tab := VBoxContainer.new()
	tab.name = t("tab_tileset")
	tab.add_theme_constant_override("separation", 8)
	tab_container.add_child(tab)

	var lbl := Label.new()
	lbl.text = t("tileset_info")
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	ui_labels["tileset_info"] = lbl
	tab.add_child(lbl)

	var included := Label.new()
	included.text = "✅ Included: Pixel Platformer (Kenney CC0)"
	included.add_theme_color_override("font_color", Color(0.3, 0.85, 0.5))
	tab.add_child(included)

	var sep := HSeparator.new()
	tab.add_child(sep)

	var custom_lbl := Label.new()
	custom_lbl.text = t("tileset_title")
	custom_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.5))
	ui_labels["tileset_title"] = custom_lbl
	tab.add_child(custom_lbl)

	var info2 := Label.new()
	info2.text = "Edit tileset_config.json to add custom tilesets.\nLocation: res://addons/procgen_world/tileset_config.json"
	info2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info2.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info2.add_theme_font_size_override("font_size", 11)
	tab.add_child(info2)

	var sep2 := HSeparator.new()
	tab.add_child(sep2)

	var setup_lbl := Label.new()
	setup_lbl.text = "⚙ Quick Setup"
	setup_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.5))
	tab.add_child(setup_lbl)

	var setup_info := Label.new()
	setup_info.text = "Creates a TileMap in the open scene and configures the TileSet automatically."
	setup_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	setup_info.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	setup_info.add_theme_font_size_override("font_size", 11)
	tab.add_child(setup_info)

	var setup_btn := Button.new()
	setup_btn.text = "⚙ Create TileMap + TileSet"
	setup_btn.pressed.connect(_setup_tilemap)
	tab.add_child(setup_btn)

# ─────────────────────────────────────────────────────────────
#  Tab: Presets
# ─────────────────────────────────────────────────────────────
func _build_tab_presets() -> void:
	var tab := VBoxContainer.new()
	tab.name = "💾 Presets"
	tab.add_theme_constant_override("separation", 6)
	tab_container.add_child(tab)

	var lbl := Label.new()
	lbl.text = "Save / Load settings"
	lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 0.5))
	tab.add_child(lbl)

	# Riga salvataggio
	var save_row := HBoxContainer.new()
	tab.add_child(save_row)

	preset_name_input = LineEdit.new()
	preset_name_input.placeholder_text = "Preset name..."
	preset_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_row.add_child(preset_name_input)

	var save_btn := Button.new()
	save_btn.text = "💾 Save"
	save_btn.pressed.connect(_save_preset)
	save_row.add_child(save_btn)

	var sep := HSeparator.new()
	tab.add_child(sep)

	var list_lbl := Label.new()
	list_lbl.text = "Saved presets:"
	list_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	list_lbl.add_theme_font_size_override("font_size", 11)
	tab.add_child(list_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab.add_child(scroll)

	presets_list = VBoxContainer.new()
	presets_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(presets_list)

	_load_presets_from_file()
	_refresh_presets_ui()

func _save_preset() -> void:
	var name: String = preset_name_input.text.strip_edges()
	if name.is_empty():
		status_label.text = "⚠ Enter a preset name first!"
		return

	var data: Dictionary = {
		"seed":           int(spin_seed.value),
		"sea_level":      slider_sea.value,
		"roughness":      slider_rough.value,
		"deco_density":   slider_deco.value,
		"struct_density": slider_struct.value,
		"custom_mode":    custom_mode,
		"biomes": {},
		"zones": {},
	}
	for key in biome_buttons:
		data["biomes"][key] = biome_buttons[key].button_pressed
	for key in biome_zones:
		data["zones"][key] = int(biome_zones[key].value)

	presets_data[name] = data
	_save_presets_to_file()
	_refresh_presets_ui()
	preset_name_input.text = ""
	status_label.text = "Preset saved: " + name

func _load_preset(name: String) -> void:
	if not presets_data.has(name):
		return
	var d: Dictionary = presets_data[name]
	spin_seed.value     = d.get("seed", 42)
	slider_sea.value    = d.get("sea_level", 70)
	slider_rough.value  = d.get("roughness", 50)
	slider_deco.value   = d.get("deco_density", 30)
	slider_struct.value = d.get("struct_density", 0)
	custom_mode         = d.get("custom_mode", false)

	var biomes: Dictionary = d.get("biomes", {})
	for key in biomes:
		if biome_buttons.has(key):
			biome_buttons[key].button_pressed = biomes[key]

	var zones: Dictionary = d.get("zones", {})
	for key in zones:
		if biome_zones.has(key):
			biome_zones[key].value = zones[key]

	status_label.text = "Preset loaded: " + name

func _delete_preset(name: String) -> void:
	presets_data.erase(name)
	_save_presets_to_file()
	_refresh_presets_ui()

func _refresh_presets_ui() -> void:
	for child in presets_list.get_children():
		child.queue_free()

	if presets_data.is_empty():
		var empty := Label.new()
		empty.text = "No presets saved yet."
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty.add_theme_font_size_override("font_size", 11)
		presets_list.add_child(empty)
		return

	for pname in presets_data.keys():
		var row := HBoxContainer.new()
		presets_list.add_child(row)

		var name_lbl := Label.new()
		name_lbl.text = pname
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_lbl)

		var load_btn := Button.new()
		load_btn.text = "📂"
		load_btn.tooltip_text = "Load"
		var pname_ref: String = pname
		load_btn.pressed.connect(func(): _load_preset(pname_ref))
		row.add_child(load_btn)

		var del_btn := Button.new()
		del_btn.text = "🗑"
		del_btn.tooltip_text = "Delete"
		del_btn.pressed.connect(func(): _delete_preset(pname_ref))
		row.add_child(del_btn)

func _save_presets_to_file() -> void:
	var file: FileAccess = FileAccess.open("res://addons/procgen_world/presets.json", FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(presets_data, "	"))
	file.close()

func _load_presets_from_file() -> void:
	var path: String = "res://addons/procgen_world/presets.json"
	if not FileAccess.file_exists(path):
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		presets_data = json.get_data()
	file.close()

# ─────────────────────────────────────────────────────────────
#  Tab: Help
# ─────────────────────────────────────────────────────────────
func _build_tab_help() -> void:
	var tab := VBoxContainer.new()
	tab.name = t("tab_help")
	tab_container.add_child(tab)

	var help := Label.new()
	help.text = t("help_text")
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	ui_labels["help_text"] = help
	tab.add_child(help)

	var sep := HSeparator.new()
	tab.add_child(sep)

	var credits := Label.new()
	credits.text = "ProcGen World v1.0.0\nby xStrix — CC0\nTiles: Kenney.nl (CC0)"
	credits.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	credits.add_theme_font_size_override("font_size", 11)
	tab.add_child(credits)

# ─────────────────────────────────────────────────────────────
#  Aggiorna labels lingua
# ─────────────────────────────────────────────────────────────
func _update_labels() -> void:
	for key in ui_labels:
		var node = ui_labels[key]
		if node is Label or node is Button:
			node.text = t(key) if key != "random_seed" else t("random_seed")
	label_sea.text   = t("sea_level")   + ": %d%%" % int(slider_sea.value)
	label_rough.text = t("roughness")   + ": %d%%" % int(slider_rough.value)
	label_deco.text = t("deco_density") + ": %d%%" % int(slider_deco.value)
	tab_container.set_tab_title(0, t("tab_generate"))
	tab_container.set_tab_title(1, t("tab_tileset"))
	if tab_container.get_tab_count() > 3:
		tab_container.set_tab_title(3, t("tab_help"))

# ─────────────────────────────────────────────────────────────
#  Generazione procedurale (Perlin Noise)
# ─────────────────────────────────────────────────────────────
func _generate_world() -> void:
	var seed_val  := int(spin_seed.value)
	var roughness: float = slider_rough.value / 100.0
	var deco_density: float = slider_deco.value / 100.0
	var sea_pct   := slider_sea.value / 100.0

	# Leggi dimensione finestra di gioco da ProjectSettings
	var tile_size: int = 18
	var game_w: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var game_h: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	if game_w > 0 and game_h > 0:
		world_w = int(game_w / tile_size)
		world_h = int(game_h / tile_size)
	else:
		world_w = int(spin_width.value)
		world_h = int(spin_height.value)
	if world_w < 10: world_w = 60
	if world_h < 5: world_h = 30
	spin_width.value  = world_w
	spin_height.value = world_h

	# Biomi attivi
	var use_grass: bool = biome_buttons.get("grass", null) != null and biome_buttons["grass"].button_pressed
	var use_water: bool = biome_buttons.get("water", null) != null and biome_buttons["water"].button_pressed
	var use_snow:  bool = biome_buttons.get("snow",  null) != null and biome_buttons["snow"].button_pressed
	var use_lava:  bool = biome_buttons.get("lava",  null) != null and biome_buttons["lava"].button_pressed
	
	# Costruisci lista biomi superficie attivi
	var active_biomes: Array = []
	if use_grass: active_biomes.append("grass")
	if use_water: active_biomes.append("water")
	if use_snow:  active_biomes.append("snow")
	if use_lava:  active_biomes.append("lava")

	# Nessun bioma attivo = non generare nulla
	if active_biomes.is_empty():
		status_label.text = "⚠ Select at least one biome!"
		world_data.clear()
		return

	# Pesi biomi — Random o Custom
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val + 777
	var weights: Array = []
	var total_weight: float = 0.0

	if custom_mode:
		# Modalità custom: usa le zone impostate dall'utente
		# Ricostruisci active_biomes in base alle zone > 0
		active_biomes.clear()
		var zone_keys: Array = ["grass", "water", "snow", "lava"]
		for key in zone_keys:
			if biome_zones.has(key):
				var zones: int = int(biome_zones[key].value)
				if zones > 0:
					active_biomes.append(key)
					weights.append(float(zones))
					total_weight += float(zones)
		if active_biomes.is_empty():
			status_label.text = "⚠ Set at least one zone > 0!"
			world_data.clear()
			return
	else:
		# Modalità random: erba peso doppio
		for i in range(active_biomes.size()):
			var base: float = 2.0 if active_biomes[i] == "grass" else 1.0
			var w: float = base * rng.randf_range(0.6, 1.0)
			weights.append(w)
			total_weight += w

	# Normalizza pesi cumulativi
	var cumulative: Array = []
	var cum: float = 0.0
	for w in weights:
		cum += w / total_weight
		cumulative.append(cum)

	var noise := FastNoiseLite.new()
	noise.seed = seed_val
	noise.frequency = 0.005 + roughness * 0.08
	noise.noise_type = FastNoiseLite.TYPE_PERLIN

	var biome_noise := FastNoiseLite.new()
	biome_noise.seed = seed_val + 999
	biome_noise.frequency = 0.04
	biome_noise.noise_type = FastNoiseLite.TYPE_PERLIN

	var cave_noise := FastNoiseLite.new()
	cave_noise.seed = seed_val + 1337
	cave_noise.frequency = 0.06
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN

	var deco_noise := FastNoiseLite.new()
	deco_noise.seed = seed_val + 555
	deco_noise.frequency = 0.15
	deco_noise.noise_type = FastNoiseLite.TYPE_PERLIN

	var sea_level   := int(world_h * sea_pct)
	var dirt_layers: int = 4

	world_data.clear()
	world_data.resize(world_w * world_h)
	for i in range(world_data.size()):
		world_data[i] = "sky"

	for x in range(world_w):
		# Superficie con Perlin
		var surface_n: float = noise.get_noise_2d(float(x), 0.0)
		var surface_y: int = sea_level + int(surface_n * world_h * (0.05 + roughness * 0.35))
		surface_y = clamp(surface_y, 3, world_h - dirt_layers - 2)

		# Scegli bioma superficie
		if active_biomes.is_empty():
			continue
		var surface_biome: String = active_biomes[active_biomes.size() - 1]
		if custom_mode:
			# Modalità custom: divide la mappa in segmenti proporzionali
			# Mescola i segmenti con un noise leggero per renderli naturali
			var segment_noise: float = biome_noise.get_noise_2d(float(x), 0.0) * 0.08
			var pos: float = clamp(float(x) / float(world_w) + segment_noise, 0.0, 0.9999)
			for i in range(cumulative.size()):
				if pos <= cumulative[i]:
					surface_biome = active_biomes[i]
					break
		else:
			# Modalità random: usa biome_noise
			var bv: float = (biome_noise.get_noise_2d(float(x), 0.0) + 1.0) * 0.5
			for i in range(cumulative.size()):
				if bv <= cumulative[i]:
					surface_biome = active_biomes[i]
					break

		# Piazza superficie
		world_data[surface_y * world_w + x] = surface_biome

		# Acqua: solo superficie, come neve e lava
		# (nessun riempimento sopra)

		# Decorazioni sopra la superficie (su qualsiasi bioma tranne acqua)
		# Decorazioni — barra da 0% a 100%, funziona in Random e Custom
		if deco_density > 0.0 and surface_y > 1:
			var skip_biomes: Array = ["water", "lava", "decoration"]
			if not (surface_biome in skip_biomes):
				var dv: float = (deco_noise.get_noise_2d(float(x), 0.0) + 1.0) * 0.5
				if dv > (1.0 - deco_density):
					world_data[(surface_y - 1) * world_w + x] = "decoration"

		# Strati terra sotto superficie
		for dy in range(1, dirt_layers + 1):
			var ty: int = surface_y + dy
			if ty < world_h:
				world_data[ty * world_w + x] = "dirt"

		# Caverne
		for y in range(surface_y + 2, world_h - 2):
			var cn: float = (cave_noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			if cn < 0.1:  # caverne fisse minime
				world_data[y * world_w + x] = "sky"

		# Lava: non viene piazzata separatamente in fondo
		# appare solo come bioma superficie come gli altri

# ─────────────────────────────────────────────────────────────
#  Genera su TileMap
# ─────────────────────────────────────────────────────────────
func _on_generate_pressed() -> void:
	_generate_world()
	if world_data.is_empty():
		return

	if editor_plugin == null:
		status_label.text = t("no_tilemap")
		return

	var scene_root = editor_plugin.get_editor_interface().get_edited_scene_root()
	if scene_root == null:
		status_label.text = t("no_tilemap")
		return

	var tilemap: TileMap = _find_tilemap(scene_root)
	if tilemap == null:
		status_label.text = t("no_tilemap")
		return

	status_label.text = t("generating")

	# Piazza i tile con tile ID fissi per ogni tipo
	for y in range(world_h):
		for x in range(world_w):
			var tile_type : String = world_data[y * world_w + x]
			if tile_type == "sky":
				tilemap.erase_cell(0, Vector2i(x, y))
				continue

			var atlas_coord: Vector2i = _get_atlas_coord(tile_type, x, y)
			tilemap.set_cell(0, Vector2i(x, y), 0, atlas_coord)

	# Piazza strutture
	var struct_density: float = slider_struct.value / 100.0
	if struct_density > 0.0:
		_place_structures(tilemap, struct_density)

	status_label.text = t("done")

func _get_atlas_coord(tile_type: String, x: int, y: int) -> Vector2i:
	# Tile fissi e corretti per ogni tipo di terreno
	# pixel_platformer 20 colonne x 9 righe, tile 18x18
	match tile_type:
		"grass":
			# Riga 0: tile erba superficie (col 1,2,3)
			var variants := [Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)]
			return variants[(x * 3 + y) % variants.size()]
		"dirt":
			# Riga 2: terra pura solida (col 0,1,2,3)
			var variants := [Vector2i(2,2), Vector2i(3,2)]
			return variants[x % variants.size()]
		"water":
			# Riga 1: acqua (col 13,14,15)
			var variants := [Vector2i(13,1), Vector2i(14,1), Vector2i(15,1)]
			return variants[(x + y) % variants.size()]
		"snow":
			# Riga 4: neve (col 0,1,2)
			var variants := [Vector2i(0,4), Vector2i(1,4), Vector2i(2,4)]
			return variants[x % variants.size()]
		"lava":
			# Riga 0: lava (col 12,13,14,15)
			var variants := [Vector2i(12,0), Vector2i(13,0)]
			return variants[x % variants.size()]
		"stone":
			var variants := [Vector2i(0,1), Vector2i(1,1), Vector2i(2,1), Vector2i(3,1)]
			return variants[x % variants.size()]
		"decoration":
			# Tile decorazione: riga 5-6 pixel_platformer
			var variants := [Vector2i(4,5), Vector2i(5,5), Vector2i(6,5), Vector2i(4,6), Vector2i(5,6)]
			return variants[x % variants.size()]
		_:
			return Vector2i(2,2)

func _place_structures(tilemap: TileMap, density: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(spin_seed.value) + 9999
	var struct_names: Array = STRUCTURES.keys()
	var min_spacing: int = 10
	var last_x: int = -min_spacing
	var industrial_source_id: int = 1

	for x in range(2, world_w - 8):
		if x - last_x < min_spacing:
			continue
		var chance: float = rng.randf()
		if chance > density * 0.3:
			continue
		var surface_y: int = -1
		for y in range(world_h):
			var tile: String = world_data[y * world_w + x]
			if tile != "sky" and tile != "decoration":
				surface_y = y
				break
		if surface_y < 0:
			continue
		var sname: String = struct_names[rng.randi() % struct_names.size()]
		var struct_tiles: Array = STRUCTURES[sname]
		for td in struct_tiles:
			var dx: int = td[0]
			var dy: int = td[1]
			var tile_id: String = td[2]
			var tx: int = x + dx
			var ty: int = surface_y + dy
			if tx < 0 or tx >= world_w or ty < 0 or ty >= world_h:
				continue
			if tile_id.begins_with("i"):
				var id: int = int(tile_id.substr(1))
				var ac := Vector2i(id % 16, id / 16)
				tilemap.set_cell(0, Vector2i(tx, ty), industrial_source_id, ac)
			else:
				var ac: Vector2i = _get_atlas_coord(tile_id, tx, ty)
				tilemap.set_cell(0, Vector2i(tx, ty), 0, ac)
		last_x = x

func _find_tilemap(node: Node) -> TileMap:
	if node is TileMap:
		return node
	for child in node.get_children():
		var result: TileMap = _find_tilemap(child)
		if result:
			return result
	return null

func _load_tileset_config() -> Dictionary:
	var path: String = "res://addons/procgen_world/tileset_config.json"
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	if json.parse(file.get_as_text()) == OK:
		return json.get_data()
	return {}

func _pick_tile(tile_type: String, config: Dictionary, x: int, y: int) -> int:
	if not config.has("terrain_types"):
		return _fallback_tile(tile_type)
	var terrain : Dictionary = config["terrain_types"]
	if not terrain.has(tile_type):
		return _fallback_tile(tile_type)
	var tiles : Array = terrain[tile_type]["tiles"]
	if tiles.is_empty():
		return _fallback_tile(tile_type)
	# Usa posizione per variazione deterministica
	var idx := (x * 7 + y * 13) % tiles.size()
	return tiles[idx]

func _fallback_tile(tile_type: String) -> int:
	match tile_type:
		"grass": return 1
		"dirt":  return 40
		"water": return 33
		"snow":  return 80
		"lava":  return 12
		_:       return 40

func _id_to_atlas(tile_id: int, columns: int) -> Vector2i:
	return Vector2i(tile_id % columns, tile_id / columns)

# ─────────────────────────────────────────────────────────────
#  Pulisci TileMap
# ─────────────────────────────────────────────────────────────
func _on_clear_pressed() -> void:
	if editor_plugin == null:
		return
	var scene_root = editor_plugin.get_editor_interface().get_edited_scene_root()
	if scene_root == null:
		return
	var tilemap: TileMap = _find_tilemap(scene_root)
	if tilemap:
		tilemap.clear()
		world_data.clear()
		status_label.text = "🗑 Cleared."

# ─────────────────────────────────────────────────────────────
#  Setup TileMap automatico
# ─────────────────────────────────────────────────────────────
func _setup_tilemap() -> void:
	if editor_plugin == null:
		status_label.text = "⚠ Editor not available."
		return

	var scene_root = editor_plugin.get_editor_interface().get_edited_scene_root()
	if scene_root == null:
		status_label.text = "⚠ Open a scene first!"
		return

	# Controlla se esiste già un TileMap
	var tilemap: TileMap = _find_tilemap(scene_root)
	if tilemap == null:
		tilemap = TileMap.new()
		tilemap.name = "WorldTileMap"
		scene_root.add_child(tilemap)
		tilemap.owner = scene_root

	# Carica il PNG
	var texture_path := "res://addons/procgen_world/pixel_platformer.png"
	var texture = load(texture_path)
	if texture == null:
		status_label.text = "⚠ Cannot find pixel_platformer.png"
		return

	# Crea TileSet
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(18, 18)

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(18, 18)

	# Aggiunge tutti i 180 tile
	for row in range(9):
		for col in range(20):
			source.create_tile(Vector2i(col, row))

	tileset.add_source(source, 0)

	# Aggiungi tileset industrial come source 1
	var ind_texture = load("res://addons/procgen_world/industrial_tileset.png")
	if ind_texture != null:
		var ind_source := TileSetAtlasSource.new()
		ind_source.texture = ind_texture
		ind_source.texture_region_size = Vector2i(18, 18)
		for row in range(7):
			for col in range(16):
				ind_source.create_tile(Vector2i(col, row))
		tileset.add_source(ind_source, 1)

	tilemap.tile_set = tileset

	# Salva come risorsa dentro l'addon
	var save_path := "res://addons/procgen_world/world_tileset.tres"
	ResourceSaver.save(tileset, save_path)

	status_label.text = "✅ TileMap + TileSet created! Now press Generate."
