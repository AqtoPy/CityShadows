extends CharacterBody3D

class_name Bot

enum State { IDLE, PATROL, CHASE, ATTACK, FLEE, INVESTIGATE }
enum Faction { POLICE, BANDITS, MILITARY, CIVILIAN }

@export var faction: Faction = Faction.CIVILIAN
@export var move_speed: float = 3.0
@export var run_speed: float = 5.0
@export var health: int = 100
@export var is_traitor: bool = false

var current_state: State = State.PATROL
var target: Node3D = null
var nav_agent: NavigationAgent3D
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var last_known_player_position: Vector3 = Vector3.ZERO

@onready var detection_area = $DetectionArea
@onready var weapon = $WeaponPivot/Weapon

func _ready():
    nav_agent = $NavigationAgent3D
    initialize_patrol_points()
    set_state(State.PATROL)

func _physics_process(delta):
    match current_state:
        State.PATROL:
            patrol()
        State.CHASE:
            chase()
        State.ATTACK:
            attack()
        State.FLEE:
            flee()
        State.INVESTIGATE:
            investigate()

    move_and_slide()

func set_state(new_state: State):
    current_state = new_state
    # Дополнительные действия при смене состояния

func patrol():
    if patrol_points.is_empty():
        return
    
    var target_point = patrol_points[current_patrol_index]
    nav_agent.target_position = target_point
    
    if global_position.distance_to(target_point) < 1.0:
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
    
    var next_location = nav_agent.get_next_path_position()
    var direction = (next_location - global_position).normalized()
    velocity = direction * move_speed

func chase():
    if not target:
        set_state(State.INVESTIGATE)
        return
    
    nav_agent.target_position = target.global_position
    last_known_player_position = target.global_position
    
    var next_location = nav_agent.get_next_path_position()
    var direction = (next_location - global_position).normalized()
    velocity = direction * run_speed
    
    if global_position.distance_to(target.global_position) < 5.0:
        set_state(State.ATTACK)

func attack():
    if not target:
        set_state(State.INVESTIGATE)
        return
    
    look_at(target.global_position, Vector3.UP)
    
    if weapon and weapon.has_method("shoot"):
        weapon.shoot(target.global_position)
    
    if global_position.distance_to(target.global_position) > 10.0:
        set_state(State.CHASE)

func flee():
    # Логика побега
    pass

func investigate():
    nav_agent.target_position = last_known_player_position
    
    if global_position.distance_to(last_known_player_position) < 1.0:
        set_state(State.PATROL)

func initialize_patrol_points():
    # Генерация случайных точек патрулирования вокруг начальной позиции
    for i in range(4):
        var offset = Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
        patrol_points.append(global_position + offset)

func take_damage(amount: int, attacker: Node = null):
    health -= amount
    
    if health <= 0:
        die()
        return
    
    if attacker and attacker.is_in_group("player"):
        target = attacker
        set_state(State.CHASE)

func die():
    queue_free()

func _on_detection_area_body_entered(body):
    if body.is_in_group("player"):
        # Проверка фракции и отношений
        if should_attack_player(body):
            target = body
            set_state(State.CHASE)

func should_attack_player(player) -> bool:
    match faction:
        Faction.POLICE:
            return player.faction == "bandits" or (is_traitor and player.faction != "police")
        Faction.BANDITS:
            return player.faction == "police" or (is_traitor and player.faction != "bandits")
        Faction.MILITARY:
            return player.faction == "bandits" or (is_traitor and player.faction != "military")
        _:
            return false
