extends Node3D

@export_group("Pencil properties")
@export_range(0.01, 1.0) var width: float = 0.01
@export_color_no_alpha var color: Color

@export_group("Points")
@export var points: PackedVector3Array = []

func start() -> void:
	points.clear()
	points.append(global_position)

func add_point(end_point: Vector3) -> void:
	var line : MeshInstance3D = MeshInstance3D.new()
	var mesh: PlaneMesh = PlaneMesh.new()
	var material: Material = StandardMaterial3D.new()

	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED 
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	mesh.material = material

	var start_point: Vector3 = points.get(points.size() -1)

	mesh.size.x = start_point.distance_to(end_point)
	mesh.size.y = width

	line.mesh = mesh
	line.position = (start_point + end_point) * 0.5

	var direction: Vector3 = end_point - start_point
	if not direction.is_zero_approx():
		line.quaternion = Quaternion(Vector3.RIGHT, direction.normalized())

	get_tree().current_scene.add_child(line)
	points.append(end_point)
