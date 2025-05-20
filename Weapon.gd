extends Node3D

class_name Weapon

@export var weapon_name: String = "Pistol"
@export var damage: float = 25.0
@export var headshot_multiplier: float = 2.0
@export var legs_multiplier: float = 0.7
@export var max_ammo: int = 12
@export var current_ammo: int = 12
@export var reload_time: float = 1.5
@export var fire_rate: float = 0.2
@export var is_automatic: bool = false
@export var bullet_range: float = 100.0
@export var spread_angle: float = 2.0 # Угол разброса в градусах
@export var can_reload_empty: bool = true # Можно ли перезаряжать с пустым магазином

var can_shoot: bool = true
var is_reloading: bool = false
var is_equipped: bool = false

@onready var raycast = $RayCast3D
@onready var muzzle_flash = $MuzzleFlash
@onready var animation_player = $AnimationPlayer
@onready var sound_player = $AudioStreamPlayer3D
@onready var reload_sound = $ReloadSound
@onready var empty_sound = $EmptySound

func _ready():
    raycast.enabled = true
    raycast.target_position = Vector3(0, 0, -bullet_range)
    muzzle_flash.emitting = false

func _process(delta):
    # Для автоматического оружия - обработка непрерывной стрельбы
    if is_automatic and is_equipped and Input.is_action_pressed("shoot"):
        shoot()

func shoot():
    if not can_shoot or is_reloading or not is_equipped:
        return
    
    if current_ammo <= 0:
        play_empty_sound()
        try_reload()
        return
    
    current_ammo -= 1
    
    # Визуальные и звуковые эффекты
    muzzle_flash.restart()
    muzzle_flash.emitting = true
    animation_player.stop()
    animation_player.play("shoot")
    sound_player.play()
    
    # Обновляем луч для выстрела с учетом разброса
    apply_bullet_spread()
    
    # Проверяем попадание
    check_hit()
    
    # Обработка задержки между выстрелами
    can_shoot = false
    get_tree().create_timer(fire_rate).timeout.connect(_on_fire_rate_timeout)

func _on_fire_rate_timeout():
    can_shoot = true

func apply_bullet_spread():
    # Сбрасываем луч в исходное положение
    raycast.target_position = Vector3(0, 0, -bullet_range)
    
    # Применяем случайный разброс
    var spread_rad = deg_to_rad(spread_angle)
    var random_angle_x = randf_range(-spread_rad, spread_rad)
    var random_angle_y = randf_range(-spread_rad, spread_rad)
    
    raycast.rotation.x = random_angle_x
    raycast.rotation.y = random_angle_y
    
    # Обновляем луч
    raycast.force_raycast_update()

func check_hit():
    if not raycast.is_colliding():
        return
    
    var collider = raycast.get_collider()
    var hit_point = raycast.get_collision_point()
    var hit_normal = raycast.get_collision_normal()
    
    # Создаем эффект попадания (можете добавить свою логику)
    spawn_hit_effect(hit_point, hit_normal)
    
    if collider.has_method("take_damage"):
        var calculated_damage = damage
        var hit_zone = "body"
        
        # Определяем зону попадания
        if collider is CharacterBody3D:
            var local_hit = collider.to_local(hit_point)
            if local_hit.y > collider.get_node("CollisionShape3D").shape.height * 0.8:
                hit_zone = "head"
                calculated_damage *= headshot_multiplier
            elif local_hit.y < collider.get_node("CollisionShape3D").shape.height * 0.3:
                hit_zone = "legs"
                calculated_damage *= legs_multiplier
        
        collider.take_damage(calculated_damage, hit_zone)

func spawn_hit_effect(position: Vector3, normal: Vector3):
    # Здесь можно создать эффект попадания (дым, искры и т.д.)
    # Пример: 
    # var hit_effect = preload("res://effects/hit_effect.tscn").instantiate()
    # get_tree().root.add_child(hit_effect)
    # hit_effect.global_position = position
    # hit_effect.look_at(position + normal)
    pass

func try_reload():
    if is_reloading or (current_ammo == max_ammo):
        return
    
    if current_ammo <= 0 and not can_reload_empty:
        return
    
    reload()

func reload():
    if is_reloading or (current_ammo == max_ammo and not can_reload_empty):
        return
    
    is_reloading = true
    animation_player.play("reload")
    reload_sound.play()
    
    await get_tree().create_timer(reload_time).timeout
    
    current_ammo = max_ammo
    is_reloading = false

func play_empty_sound():
    if empty_sound and not empty_sound.playing:
        empty_sound.play()

func equip():
    is_equipped = true
    visible = true
    # Можно добавить анимацию доставания оружия

func unequip():
    is_equipped = false
    visible = false
    # Можно добавить анимацию убирания оружия

func add_ammo(amount: int):
    current_ammo = min(current_ammo + amount, max_ammo)
