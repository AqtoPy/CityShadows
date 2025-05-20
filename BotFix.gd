extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var map_ready: bool = false

func _ready():
    # Ждем готовности навигации
    NavigationServer3D.map_changed.connect(_on_navigation_map_changed)
    _setup_patrol_points()

func _on_navigation_map_changed(map_rid):
    if map_rid == get_world_3d().navigation_map:
        map_ready = true
        start_patrol()

func _setup_patrol_points():
    # Генерация точек патрулирования
    patrol_points = [
        global_position + Vector3(5, 0, 0),
        global_position + Vector3(0, 0, 5),
        global_position + Vector3(-5, 0, 0),
        global_position + Vector3(0, 0, -5)
    ]

func start_patrol():
    if map_ready and patrol_points.size() > 0:
        _update_navigation_target()

func patrol():
    if not map_ready:
        return
    
    if navigation_agent.is_navigation_finished():
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
        _update_navigation_target()
    
    var next_location = navigation_agent.get_next_path_position()
    var direction = (next_location - global_position).normalized()
    velocity = direction * speed
    move_and_slide()

func _update_navigation_target():
    if patrol_points.size() > current_patrol_index:
        navigation_agent.target_position = patrol_points[current_patrol_index]
