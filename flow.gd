extends Node2D

signal flow_clicked

const AtomScene = preload("res://Atom.tscn")

var exploded := false
var t := 0.0
var breath_time := 0.0
var flow_alpha := 1.0
var is_exploding := false
var explode_progress := 0.0
var clickable_radius := Constants.FLOW_BASE_RADIUS + 20.0


func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)


func _process(delta):
	t += delta
	breath_time += delta * Constants.FLOW_BREATH_SPEED

	if is_exploding:
		_handle_explode(delta)
	else:
		_handle_breathing()

	queue_redraw()


func _handle_breathing():
	# Respiration organique : combinaison de sinusoïdes
	var breath_offset := sin(breath_time * TAU) * Constants.FLOW_BREATH_AMPLITUDE
	var secondary := sin(breath_time * TAU * 0.3) * 4.0

	# Alpha qui respire - presque disparaît
	flow_alpha = lerp(
		Constants.FLOW_MIN_ALPHA,
		Constants.FLOW_MAX_ALPHA,
		(sin(breath_time * TAU * 0.5) + 1.0) / 2.0
	)


func _handle_explode(delta):
	explode_progress += delta / 0.6
	flow_alpha = max(0.0, 1.0 - explode_progress)
	if explode_progress >= 1.0:
		visible = false


func explode():
	is_exploding = true
	explode_progress = 0.0


func _draw():
	if flow_alpha <= 0.01:
		return

	var center := get_viewport_rect().size / 2
	var base_radius := Constants.FLOW_BASE_RADIUS
	var breath_offset := sin(breath_time * TAU) * Constants.FLOW_BREATH_AMPLITUDE
	var secondary := sin(breath_time * TAU * 0.3) * 4.0
	var radius := base_radius + breath_offset + secondary

	var color := Constants.COLOR_FLOW

	# Glow externe
	draw_circle(center, radius + 20.0, Color(color.r, color.g, color.b, flow_alpha * 0.05))
	draw_circle(center, radius + 12.0, Color(color.r, color.g, color.b, flow_alpha * 0.1))
	draw_circle(center, radius + 6.0, Color(color.r, color.g, color.b, flow_alpha * 0.2))

	# Cercle principal
	draw_circle(center, radius, Color(color.r, color.g, color.b, flow_alpha * 0.8))

	# Coeur brillant
	draw_circle(center, radius * 0.3, Color(color.r, color.g, color.b, flow_alpha))

	# Tendrils organiques
	_draw_tendrils(center, radius)


func _draw_tendrils(center: Vector2, base_radius: float):
	var tendril_count := 6
	var color := Constants.COLOR_FLOW

	for i in tendril_count:
		var angle := (TAU / tendril_count) * i + breath_time * 0.3
		var wave := sin(breath_time * TAU + i * 1.5) * 0.3
		var length := base_radius * (0.8 + wave)

		var start := center
		var end := center + Vector2.from_angle(angle) * length

		# Série de points pour effet organique
		var steps := 12
		for s in steps:
			var t := float(s) / float(steps)
			var pos := start.lerp(end, t)
			var perp := Vector2.from_angle(angle + PI / 2.0)
			var wave_offset := sin(t * TAU + breath_time * 2.0 + i) * 3.0
			pos += perp * wave_offset

			var dot_alpha: float = flow_alpha * (1.0 - t) * 0.6
			var dot_size: float = lerp(3.0, 1.0, t)
			draw_circle(pos, dot_size, Color(color.r, color.g, color.b, dot_alpha))


func _input(event):
	if exploded:
		return

	if event is InputEventMouseButton and event.pressed:
		var mouse_pos: Vector2 = event.position
		var center: Vector2 = get_viewport_rect().size / 2
		var dist: float = center.distance_to(mouse_pos)

		if dist <= clickable_radius:
			exploded = true
			explode()
			flow_clicked.emit()

			# Spawn 4 atomes
			for i in range(4):
				var atom = AtomScene.instantiate()
				atom.atom_index = i
				atom.angle = i * PI / 2.0
				atom.center_position = get_viewport_rect().size / 2
				atom.start_orbit()
				add_child(atom)
