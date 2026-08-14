extends Node2D

const AtomScene = preload("res://Atom.tscn")

var exploded = false
var t := 0.0

func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)

func _process(delta):
	t += delta
	queue_redraw()

func _draw():
	var center = get_viewport_rect().size / 2
	var radius = 50.0 * (sin(t * 2.0) + 1.0) / 2.0
	draw_circle(center, radius, Color.WHITE)

func _input(event):
	if exploded:
		return

	if event is InputEventMouseButton and event.pressed:
		exploded = true

		for i in range(4):
			var atom = AtomScene.instantiate()

			var angle = i * PI / 2.0
			var distance = 60.0

			atom.position = Vector2(
				cos(angle) * distance,
				sin(angle) * distance
			)

			add_child(atom)
