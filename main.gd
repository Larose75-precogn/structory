extends Node2D

@onready var flow: Node2D = $Flow
@onready var ui: CanvasLayer = $UI

var phase2_timer := 0.0
var transitioning_to_phase3 := false


func _ready():
	flow.flow_clicked.connect(_on_flow_clicked)


func _process(delta):
	if transitioning_to_phase3:
		phase2_timer += delta
		if phase2_timer >= Constants.PHASE2_TO_PHASE3_DELAY:
			transitioning_to_phase3 = false
			_enter_phase3()


func _on_flow_clicked():
	_enter_phase2()


func _enter_phase2():
	transitioning_to_phase3 = true
	phase2_timer = 0.0


func _enter_phase3():
	ui.show_content()
