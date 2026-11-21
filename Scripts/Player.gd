extends CharacterBody3D

enum Movement_States {IDLE, RUNNING, DRAWING, ERASING, JUMPING}

#Flags:
var physics_enabled: bool = true

#Player settings:
const SPEED = 8.0
const JUMP_VELOCITY = 8.0
const MOUSE_SENSITIVITY = 0.0025

var max_look_angle: float = 89.0
var pitch := 0.0
var camera_yaw := 0.0
var rotating_camera: bool = false
var direction: Vector3 = Vector3.ZERO
var is_busy: bool = false # يمنع تداخل الانتقالات أثناء await

@onready var pencil: Node3D = $Pencil
@onready var pivot: Node3D = $Pivot
@onready var animation_player: AnimationPlayer = $Node3D/Moly/AnimationPlayer

var current_state: Movement_States = Movement_States.IDLE

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animation_player.play("Idle")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotating_camera = true
		camera_yaw -= event.relative.x * MOUSE_SENSITIVITY
		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, deg_to_rad(-max_look_angle), deg_to_rad(max_look_angle))

func _process(delta: float) -> void:
	if not direction.is_zero_approx():
		rotation.y = lerp_angle(rotation.y, camera_yaw, 10.0 * delta)
	elif not rotating_camera:
		rotation.y = lerp_angle(rotation.y, camera_yaw, 3.0 * delta)
	pivot.rotation.y = camera_yaw - rotation.y
	pivot.rotation.x = pitch

	rotating_camera = false


func _physics_process(delta: float) -> void:
	if physics_enabled and not is_on_floor():
		velocity += get_gravity() * delta

	if not is_busy:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			start_jump()
		elif Input.is_action_just_pressed("pen_down"):
			start_drawing()

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if not is_busy:
		match current_state:
			Movement_States.IDLE:
				velocity.x = move_toward(velocity.x, 0, 0.2)
				velocity.z = move_toward(velocity.z, 0, 0.2)
				if not input_dir.is_zero_approx():
					start_running()
			Movement_States.RUNNING:
				if input_dir.is_zero_approx():
					end_running()
				else:
					handle_running(direction)
			Movement_States.JUMPING:
				handle_air_movement(direction)
			Movement_States.DRAWING:
				if pencil.can_draw:
					handle_drawing()

	if physics_enabled:
		move_and_slide()

func start_idle():
	velocity.x = move_toward(velocity.x, 0, 0.2)
	velocity.z = move_toward(velocity.z, 0, 0.2)
	if animation_player.current_animation != "Idle":
		animation_player.play("Idle")
	current_state = Movement_States.IDLE

func start_running():
	current_state = Movement_States.RUNNING

func handle_running(direction: Vector3):
	if animation_player.current_animation != "Run":
		animation_player.play("Run")
	apply_movement(SPEED, direction)

func end_running():
	is_busy = true
	velocity.x = move_toward(velocity.x, 0, 0.2)
	velocity.z = move_toward(velocity.z, 0, 0.2)
	animation_player.play("End Run")
	await animation_player.animation_finished
	is_busy = false
	start_idle()

func apply_movement(speed: float, direction: Vector3):
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

func start_jump():
	is_busy = true
	velocity.y = JUMP_VELOCITY
	animation_player.play("Jump")
	await get_tree().create_timer(0.2).timeout
	current_state = Movement_States.JUMPING
	is_busy = false

func handle_air_movement(direction: Vector3):
	apply_movement(SPEED * 0.7, direction)
	if is_on_floor():
		end_jump()

func end_jump():
	start_idle()

func start_drawing():
	is_busy = true
	pencil.can_draw = false
	animation_player.play("Start-Draw")
	await animation_player.animation_finished
	current_state = Movement_States.DRAWING
	pencil.can_draw = true
	pencil.start_pen_down()
	is_busy = false

func handle_drawing():
	if pencil.current_pen_state == pencil.PEN_STATE.PEN_UP:
		end_drawing()
		return
	if animation_player.current_animation != "Static-Draw":
		animation_player.play("Static-Draw")
	apply_movement(SPEED, direction)

func end_drawing():
	is_busy = true
	pencil.can_draw = false
	velocity.x = move_toward(velocity.x, 0, 0.2)
	velocity.z = move_toward(velocity.z, 0, 0.2)
	animation_player.play("End Draw")
	await animation_player.animation_finished
	is_busy = false
	start_idle()
