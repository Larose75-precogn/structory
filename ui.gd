extends CanvasLayer

@onready var title_label: Label = $Content/Title
@onready var tagline_label: Label = $Content/Tagline
@onready var blocks_container: VBoxContainer = $Content/BuildingBlocks
@onready var description_label: Label = $Content/Description
@onready var cta_label: Label = $Content/CallToAction
@onready var footer_label: Label = $Footer/FooterText
@onready var phase1_label: Label = $Phase1Text

var ui_elements: Array[Control] = []
var current_fade_index := 0
var is_fading := false


func _ready():
	ui_elements = [
		title_label,
		tagline_label,
		blocks_container,
		description_label,
		cta_label,
	]

	# Hide everything initially
	for elem in ui_elements:
		elem.modulate.a = 0.0

	# Phase 1 text visible
	phase1_label.modulate.a = 1.0

	# Footer
	footer_label.modulate.a = 0.5

	# Setup building blocks
	_setup_building_blocks()


func _process(delta):
	if is_fading and current_fade_index < ui_elements.size():
		var elem := ui_elements[current_fade_index]
		elem.modulate.a = lerp(elem.modulate.a, 1.0, delta * 2.0)
		if elem.modulate.a > 0.98:
			elem.modulate.a = 1.0
			current_fade_index += 1
			if current_fade_index >= ui_elements.size():
				is_fading = false


func show_content():
	# Hide phase 1 text
	phase1_label.modulate.a = 0.0
	# Start sequential fade-in
	is_fading = true
	current_fade_index = 0


func _setup_building_blocks():
	for child in blocks_container.get_children():
		child.queue_free()

	for block_name in Constants.BUILDING_BLOCKS:
		var label := Label.new()
		label.text = block_name
		label.add_theme_color_override("font_color", Constants.COLOR_ACCENT)
		label.add_theme_font_size_override("font_size", 18)
		blocks_container.add_child(label)
