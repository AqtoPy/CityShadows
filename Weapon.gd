extends Node3D

class_name Weapon

@export var weapon_name: String = "Pistol"
@export var damage: float = 25.0
@export var max_ammo: int = 12
@export var current_ammo: int = 12
@export var reload_time: float = 1.5
@export var fire_rate: float = 0.2
@export var is_automatic: bool = false

var can_shoot: bool = true
var is_reloading: bool = false

@onready var raycast = $RayCast3D
@onready var muzzle_flash = $MuzzleFlash
@onready var animation_player = $AnimationPlayer
@onready var sound_player = $AudioStreamPlayer3D

func _ready():
    raycast.enabled = true

func shoot():
    if not can_shoot or is_reloading:
        return
    
    if current_ammo <= 0:
        reload()
        return
    
    current_ammo -= 1
    
    # Визуальные эффекты
    muzzle_flash.emitting = true
    animation_player.play("shoot")
    sound_player.play()
    
    # Логика попадания
    if raycast.is_colliding():
        var collider = raycast.get_collider()
        if collider.has_method("take_damage"):
            var hit_point = raycast.get_collision_point()
            var hit_normal = raycast.get_collision_normal()
            
            # Определение зоны попадания
            var hit_zone = "body"
            if collider is CharacterBody3D:
                var local_hit = collider.to_local(hit_point)
                if local_hit.y > 1.5:  # Примерное определение головы
                    hit_zone = "head"
                elif local_hit.y < 0.5:  # Примерное определение ног
                    hit_zone = "legs"
            
            collider.take_damage(damage, hit_zone)
    
    can_shoot = false
    if is_automatic:
        get_tree().create_timer(fire_rate).timeout.connect(func(): can_shoot = true)
    else:
        get_tree().create_timer(fire_rate).timeout.connect(func(): can_shoot = true)

func reload():
    if is_reloading or current_ammo == max_ammo:
        return
    
    is_reloading = true
    animation_player.play("reload")
    await get_tree().create_timer(reload_time).timeout
    current_ammo = max_ammo
    is_reloading = false
