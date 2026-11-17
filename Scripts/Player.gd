extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.0025

var max_look_angle: float = 89.0
var pitch := 0.0
var camera_yaw := 0.0
var rotating_camera: bool = false
var direction: Vector3

@onready var pivot: Node3D = $Pivot

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotating_camera = true
		camera_yaw -= event.relative.x * MOUSE_SENSITIVITY
		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, deg_to_rad(-max_look_angle), deg_to_rad(max_look_angle))

func _process(delta: float) -> void:
	if direction:
		rotation.y = lerp_angle(rotation.y, camera_yaw, 10.0 * delta)
	elif not rotating_camera:
		rotation.y = lerp_angle(rotation.y, camera_yaw, 3.0 * delta)
	pivot.rotation.y = camera_yaw - rotation.y
	pivot.rotation.x = pitch

	rotating_camera = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
