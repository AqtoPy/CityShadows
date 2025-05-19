extends CharacterBody3D

# Настройки движения
@export var walk_speed = 5.0
@export var run_speed = 8.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.002

# Характеристики игрока
var health = 100
var max_health = 100
var armor = 0
var max_armor = 100
var money = 0
var faction = "neutral"  # police, bandits, military
var reputation = 0
var current_weapon: Node3D

# Состояния
var is_running = false
var is_crouching = false
var is_aiming = false
var is_reloading = false

@onready var camera = $Camera3D
@onready var weapon_pivot = $WeaponPivot
@onready var interaction_ray = $Camera3D/InteractionRay

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    update_hud()

func _input(event):
    # Управление камерой мышью
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera.rotate_x(-event.relative.y * mouse_sensitivity)
        camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta):
    # Движение персонажа
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    var speed = run_speed if is_running else walk_speed
    if is_crouching:
        speed *= 0.5
    
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)
    
    # Прыжок
    if is_on_floor() and Input.is_action_just_pressed("jump"):
        velocity.y = jump_velocity
    
    # Гравитация
    if not is_on_floor():
        velocity.y -= 9.8 * delta
    
    move_and_slide()
    
    # Взаимодействие
    if Input.is_action_just_pressed("interact"):
        interact()

func take_damage(damage: float, hit_zone: String = "body"):
    var multiplier = 1.0
    match hit_zone:
        "head": multiplier = 2.0
        "body": multiplier = 1.0
        "legs": multiplier = 0.5
    
    var total_damage = damage * multiplier
    
    if armor > 0:
        armor -= total_damage
        if armor < 0:
            health += armor  # Остаток урона переходит в HP
            armor = 0
    else:
        health -= total_damage
    
    if health <= 0:
        die()
    
    update_hud()

func heal(amount: int):
    health = min(health + amount, max_health)
    update_hud()

func add_armor(amount: int):
    armor = min(armor + amount, max_armor)
    update_hud()

func add_money(amount: int):
    money += amount
    update_hud()

func update_hud():
    var hud = get_node("/root/Main/CanvasLayer/HUD")
    if hud:
        hud.update_health(health, max_health)
        hud.update_armor(armor, max_armor)
        hud.update_money(money)
        hud.update_faction(faction)

func interact():
    if interaction_ray.is_colliding():
        var collider = interaction_ray.get_collider()
        if collider.has_method("on_interact"):
            collider.on_interact(self)

func die():
    # Обработка смерти игрока
    print("Player died!")
    get_tree().reload_current_scene()

func equip_weapon(weapon_scene: PackedScene):
    if current_weapon:
        current_weapon.queue_free()
    
    var new_weapon = weapon_scene.instantiate()
    weapon_pivot.add_child(new_weapon)
    current_weapon = new_weapon
