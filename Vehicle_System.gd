extends RigidBody3D

class_name Vehicle

@export var max_speed = 20.0
@export var acceleration = 5.0
@export var steering_speed = 2.0
@export var brake_force = 10.0

var current_speed = 0.0
var steering_angle = 0.0
var is_player_inside = false
var player_ref = null

@onready var enter_position = $EnterPosition
@onready var exit_position = $ExitPosition
@onready var camera_pivot = $CameraPivot

func _physics_process(delta):
    if is_player_inside and player_ref:
        process_vehicle_controls(delta)
        update_camera()

func process_vehicle_controls(delta):
    # Управление
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    
    # Разгон/торможение
    if input_dir.y > 0:
        current_speed = lerp(current_speed, max_speed * input_dir.y, acceleration * delta)
    elif input_dir.y < 0:
        current_speed = lerp(current_speed, max_speed * input_dir.y * 0.5, acceleration * delta)
    else:
        current_speed = lerp(current_speed, 0.0, brake_force * delta)
    
    # Поворот
    steering_angle = input_dir.x * deg_to_rad(30.0)
    rotation.y = lerp_angle(rotation.y, rotation.y + steering_angle * steering_speed, delta * 2.0)
    
    # Применение движения
    var forward_dir = -transform.basis.z
    linear_velocity = forward_dir * current_speed

func update_camera():
    if player_ref and player_ref.camera:
        player_ref.camera.global_transform = camera_pivot.global_transform

func enter_vehicle(player):
    if is_player_inside:
        return
    
    player_ref = player
    is_player_inside = true
    
    # Скрываем игрока
    player.visible = false
    player.process_mode = Node.PROCESS_MODE_DISABLED
    
    # Настраиваем камеру
    if player.camera:
        player.camera.current = false
    $Camera3D.current = true

func exit_vehicle():
    if not is_player_inside or not player_ref:
        return
    
    # Возвращаем игрока
    player_ref.global_transform = exit_position.global_transform
    player_ref.visible = true
    player_ref.process_mode = Node.PROCESS_MODE_INHERIT
    
    # Возвращаем камеру
    $Camera3D.current = false
    if player_ref.camera:
        player_ref.camera.current = true
    
    is_player_inside = false
    player_ref = null

func _input(event):
    if is_player_inside and event.is_action_pressed("interact"):
        exit_vehicle()

func _on_interaction_area_body_entered(body):
    if body.is_in_group("player") and not is_player_inside:
        body.show_interaction_text("Нажмите E чтобы сесть в транспорт")
        body.interaction_object = self

func _on_interaction_area_body_exited(body):
    if body.is_in_group("player"):
        body.hide_interaction_text()
        if body.interaction_object == self:
            body.interaction_object = null
