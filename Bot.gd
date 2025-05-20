extends CharacterBody3D

class_name Bot

enum State { IDLE, PATROL, CHASE, ATTACK, FLEE, INVESTIGATE, SEARCH }
enum Faction { POLICE, BANDITS, MILITARY, CIVILIAN }

@export var faction: Faction = Faction.CIVILIAN
@export var move_speed: float = 3.0
@export var run_speed: float = 5.0
@export var health: int = 100
@export var max_health: int = 100
@export var is_traitor: bool = false
@export var patrol_radius: float = 15.0
@export var vision_angle: float = 70.0  # Угол обзора в градусах
@export var damage: int = 10
@export var attack_cooldown: float = 0.5
@export var accuracy: float = 0.8  # Точность стрельбы (0.0-1.0)

var current_state: State = State.IDLE
var target: Node3D = null
var nav_agent: NavigationAgent3D
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var last_known_player_position: Vector3 = Vector3.ZERO
var time_in_state: float = 0.0
var attack_timer: float = 0.0
var is_player_visible: bool = false
var suspicion_level: float = 0.0  # Уровень подозрения (0-100)
var search_points: Array[Vector3] = []
var current_search_index: int = 0

@onready var detection_area = $DetectionArea
@onready var weapon = $WeaponPivot/Weapon
@onready var vision_ray = $VisionRay
@onready var state_label = $StateLabel
@onready var health_bar = $HealthBar

func _ready():
    nav_agent = $NavigationAgent3D
    initialize_patrol_points()
    set_state(State.PATROL)
    health_bar.max_value = max_health
    health_bar.value = health
    
    # Настройка области обнаружения
    detection_area.body_entered.connect(_on_detection_area_body_entered)
    detection_area.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta):
    time_in_state += delta
    update_vision()
    update_suspicion(delta)
    update_health_display()
    
    match current_state:
        State.IDLE:
            idle_behavior(delta)
        State.PATROL:
            patrol_behavior()
        State.CHASE:
            chase_behavior()
        State.ATTACK:
            attack_behavior(delta)
        State.FLEE:
            flee_behavior()
        State.INVESTIGATE:
            investigate_behavior()
        State.SEARCH:
            search_behavior()
    
    move_and_slide()
    
    # Обновление метки состояния для отладки
    if state_label:
        state_label.text = State.keys()[current_state] + "\nSuspicion: " + str(snapped(suspicion_level, 0.1))

func set_state(new_state: State):
    if current_state == new_state:
        return
    
    # Действия при выходе из состояния
    match current_state:
        State.ATTACK:
            if weapon and weapon.has_method("stop_shooting"):
                weapon.stop_shooting()
    
    current_state = new_state
    time_in_state = 0.0
    
    # Действия при входе в состояние
    match new_state:
        State.PATROL:
            current_patrol_index = randi() % patrol_points.size()
        State.SEARCH:
            generate_search_points()
            current_search_index = 0
        State.IDLE:
            velocity = Vector3.ZERO

func update_vision():
    if not target or not is_instance_valid(target):
        is_player_visible = false
        return
    
    # Проверка нахождения в поле зрения
    var direction_to_target = (target.global_position - global_position).normalized()
    var forward = -global_transform.basis.z.normalized()
    var angle = rad_to_deg(forward.angle_to(direction_to_target))
    
    if angle > vision_angle:
        is_player_visible = false
        return
    
    # Проверка прямой видимости
    vision_ray.look_at(target.global_position)
    vision_ray.force_raycast_update()
    
    if vision_ray.is_colliding():
        var collider = vision_ray.get_collider()
        is_player_visible = collider == target
    else:
        is_player_visible = false

func update_suspicion(delta):
    if is_player_visible:
        suspicion_level = min(suspicion_level + delta * 20, 100)
    else:
        suspicion_level = max(suspicion_level - delta * 5, 0)
    
    # Переход в состояние INVESTIGATE при среднем уровне подозрения
    if suspicion_level > 30 and current_state == State.PATROL:
        set_state(State.INVESTIGATE)

func update_health_display():
    if health_bar:
        health_bar.value = health

func idle_behavior(delta):
    # Случайный переход в патрулирование
    if time_in_state > 3.0 and randf() < 0.1:
        set_state(State.PATROL)

func patrol_behavior():
    if patrol_points.is_empty():
        return
    
    var target_point = patrol_points[current_patrol_index]
    nav_agent.target_position = target_point
    
    if global_position.distance_to(target_point) < 1.5:
        # Случайное время ожидания на точке
        if time_in_state > 2.0 and randf() < 0.3:
            set_state(State.IDLE)
        elif time_in_state > 1.0:
            current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
    
    var next_location = nav_agent.get_next_path_position()
    var direction = (next_location - global_position).normalized()
    velocity = direction * move_speed
    
    # Плавный поворот в направлении движения
    if velocity.length() > 0.1:
        look_at(global_position + velocity, Vector3.UP, true)

func chase_behavior():
    if not target or not is_instance_valid(target):
        set_state(State.INVESTIGATE)
        return
    
    nav_agent.target_position = target.global_position
    last_known_player_position = target.global_position
    
    var next_location = nav_agent.get_next_path_position()
    var direction = (next_location - global_position).normalized()
    velocity = direction * run_speed
    
    # Плавный поворот к цели
    if velocity.length() > 0.1:
        look_at(global_position + velocity, Vector3.UP, true)
    
    # Проверка расстояния для атаки
    if global_position.distance_to(target.global_position) < 7.0 and is_player_visible:
        set_state(State.ATTACK)
    elif not is_player_visible and time_in_state > 5.0:
        set_state(State.SEARCH)

func attack_behavior(delta):
    if not target or not is_instance_valid(target):
        set_state(State.SEARCH)
        return
    
    # Остановка при атаке
    velocity = Vector3.ZERO
    
    # Наведение на цель
    look_at(target.global_position, Vector3.UP, true)
    
    # Стрельба с учетом точности
    attack_timer += delta
    if attack_timer >= attack_cooldown and weapon and weapon.has_method("shoot"):
        var aim_point = target.global_position
        if accuracy < 1.0:
            # Добавление случайного отклонения
            var deviation = Vector3(
                randf_range(-1.0, 1.0),
                randf_range(-1.0, 1.0),
                randf_range(-1.0, 1.0)
            ) * (10.0 * (1.0 - accuracy))
            aim_point += deviation
        
        weapon.shoot(aim_point)
        attack_timer = 0.0
    
    # Проверка условий для смены состояния
    if global_position.distance_to(target.global_position) > 10.0 or not is_player_visible:
        if is_player_visible:
            set_state(State.CHASE)
        else:
            set_state(State.SEARCH)
    
    # Проверка здоровья для отступления
    if health < max_health * 0.3 and randf() < 0.1:
        set_state(State.FLEE)

func flee_behavior():
    if not target or not is_instance_valid(target):
        set_state(State.PATROL)
        return
    
    # Бег в противоположном направлении от цели
    var flee_direction = (global_position - target.global_position).normalized()
    var flee_target = global_position + flee_direction * 20.0
    
    nav_agent.target_position = flee_target
    var next_location = nav_agent.get_next_path_position()
    var direction = (next_location - global_position).normalized()
    velocity = direction * run_speed
    
    # Плавный поворот в направлении движения
    if velocity.length() > 0.1:
        look_at(global_position + velocity, Vector3.UP, true)
    
    # Возврат к патрулированию после отступления
    if time_in_state > 10.0 or global_position.distance_to(target.global_position) > 30.0:
        set_state(State.PATROL)

func investigate_behavior():
    if last_known_player_position == Vector3.ZERO:
        set_state(State.PATROL)
        return
    
    nav_agent.target_position = last_known_player_position
    
    var next_location = nav_agent.get_next_path_position()
    var direction = (next_location - global_position).normalized()
    velocity = direction * move_speed
    
    # Плавный поворот в направлении движения
    if velocity.length() > 0.1:
        look_at(global_position + velocity, Vector3.UP, true)
    
    # Проверка достижения точки
    if global_position.distance_to(last_known_player_position) < 1.5:
        if suspicion_level > 50:
            set_state(State.SEARCH)
        else:
            set_state(State.PATROL)

func search_behavior():
    if search_points.is_empty():
        generate_search_points()
    
    if current_search_index >= search_points.size():
        set_state(State.PATROL)
        return
    
    var target_point = search_points[current_search_index]
    nav_agent.target_position = target_point
    
    if global_position.distance_to(target_point) < 1.5:
        # Осмотр точки
        if time_in_state > 2.0:
            current_search_index += 1
            if current_search_index >= search_points.size():
                set_state(State.PATROL)
                return
    
    var next_location = nav_agent.get_next_path_position()
    var direction = (next_location - global_position).normalized()
    velocity = direction * move_speed
    
    # Плавный поворот в направлении движения
    if velocity.length() > 0.1:
        look_at(global_position + velocity, Vector3.UP, true)

func generate_search_points():
    search_points.clear()
    var center = last_known_player_position
    for i in range(5):
        var angle = i * (2 * PI / 5)
        var offset = Vector3(cos(angle), 0, sin(angle)) * (3.0 + randf() * 3.0)
        search_points.append(center + offset)

func initialize_patrol_points():
    patrol_points.clear()
    for i in range(4):
        var angle = i * (2 * PI / 4)
        var offset = Vector3(cos(angle), 0, sin(angle)) * (patrol_radius * 0.7 + randf() * patrol_radius * 0.3)
        patrol_points.append(global_position + offset)

func take_damage(amount: int, attacker: Node = null):
    if health <= 0:
        return
    
    health -= amount
    health = max(health, 0)
    
    if health_bar:
        health_bar.value = health
    
    if attacker and is_instance_valid(attacker):
        target = attacker
        last_known_player_position = attacker.global_position
        suspicion_level = 100
        
        if current_state in [State.IDLE, State.PATROL, State.INVESTIGATE]:
            set_state(State.CHASE)
    
    if health <= 0:
        die()

func die():
    # Эффекты смерти, анимация и т.д.
    queue_free()

func _on_detection_area_body_entered(body):
    if body.is_in_group("player") and should_attack_player(body):
        target = body
        last_known_player_position = body.global_position
        suspicion_level = 100
        set_state(State.CHASE)

func _on_detection_area_body_exited(body):
    if body == target:
        suspicion_level = 80
        if current_state == State.CHASE:
            set_state(State.SEARCH)

func should_attack_player(player) -> bool:
    if not player.has_method("get_faction"):
        return false
    
    var player_faction = player.get_faction()
    
    match faction:
        Faction.POLICE:
            return player_faction == "bandits" or (is_traitor and player_faction != "police")
        Faction.BANDITS:
            return player_faction == "police" or player_faction == "civilian" or (is_traitor and player_faction != "bandits")
        Faction.MILITARY:
            return player_faction == "bandits" or (is_traitor and player_faction != "military")
        Faction.CIVILIAN:
            return is_traitor and player_faction != "civilian"
        _:
            return false
