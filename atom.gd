extends Node2D

var angle := 0.0
var orbiting := false
var orbit_speed := Constants.ATOM_ORBIT_SPEED
var orbit_radius := Constants.ATOM_ORBIT_RADIUS
var target_alpha := 1.0
var current_alpha := 0.0
var halo_alpha := 0.0
var center_position := Vector2.ZERO
var atom_color := Color.WHITE
var atom_index := 0


func _ready():
	atom_color = _get_atom_color(atom_index)


func _process(delta):
	if orbiting:
		angle += orbit_speed * delta
		position = center_position + Vector2.from_angle(angle) * orbit_radius

	# Fade in
	current_alpha = lerp(current_alpha, target_alpha, delta * 3.0)
	# Halo fades in
	halo_alpha = lerp(halo_alpha, 0.3 if orbiting else 0.0, delta * 2.0)

	queue_redraw()


func start_orbit():
	orbiting = true
	target_alpha = 1.0


func _get_atom_color(index: int) -> Color:
	match index:
		0: return Color(0.247, 0.725, 0.314, 1.0)  # Green - Objects
		1: return Color(0.314, 0.620, 0.725, 1.0)  # Blue - Flows
		2: return Color(0.725, 0.620, 0.314, 1.0)  # Gold - Time
		3: return Color(0.725, 0.314, 0.420, 1.0)  # Rose - Rules
		_: return Color.WHITE


func _draw():
	if current_alpha <= 0.01:
		return

	# Halo
	var halo_color := Color(atom_color.r, atom_color.g, atom_color.b, halo_alpha * current_alpha)
	draw_circle(Vector2.ZERO, Constants.ATOM_RADIUS + 15.0, halo_color)
	draw_circle(Vector2.ZERO, Constants.ATOM_RADIUS + 8.0,
		Color(atom_color.r, atom_color.g, atom_color.b, halo_alpha * current_alpha * 1.5))

	# Core
	var core_color := Color(atom_color.r, atom_color.g, atom_color.b, current_alpha)
	draw_circle(Vector2.ZERO, Constants.ATOM_RADIUS, core_color)

	# Bright center
	var bright := Color(1.0, 1.0, 1.0, current_alpha * 0.8)
	draw_circle(Vector2.ZERO, Constants.ATOM_RADIUS * 0.4, bright)

	# Trail toward center
	if orbiting:
		var to_center := (center_position - position).normalized() * orbit_radius * 0.3
		var trail_color := Color(atom_color.r, atom_color.g, atom_color.b, current_alpha * 0.1)
		draw_line(Vector2.ZERO, -to_center, trail_color, 1.0)
