extends Node3D

enum PEN_STATE {PEN_DOWN,PEN_UP} 

@onready var line_3d: Node3D = $Line3D
@onready var particles: CPUParticles3D = $particles


var current_pen_state = PEN_STATE.PEN_UP

func _ready() -> void:
	particles.mesh.material.albedo_color = line_3d.color

func _process(delta: float) -> void:

	if Input.is_action_just_pressed("pen_down"):
		start_pen_down()

	match current_pen_state:
		PEN_STATE.PEN_DOWN:
			handle_pen_down()
		PEN_STATE.PEN_UP:
			particles.emitting = false

func start_pen_down():
	line_3d.start()
	current_pen_state = PEN_STATE.PEN_DOWN

func handle_pen_down():
	particles.emitting = true
	if get_parent().is_on_floor() and Input.is_action_pressed("pen_down"):
		line_3d.add_point(global_position)
	else:
		current_pen_state = PEN_STATE.PEN_UP
