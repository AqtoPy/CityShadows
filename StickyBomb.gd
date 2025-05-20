extends RigidBody3D

@export var explosion_damage: int = 80
@export var explosion_radius: float = 5.0
@export var fuse_time: float = 3.0

var stuck_to: Node3D = null

func _ready():
    $Timer.start(fuse_time)
    $StickArea.body_entered.connect(_on_stick)

func _on_stick(body: Node3D):
    if stuck_to == null and body.is_in_group("sticky_surface"):
        freeze = true
        stuck_to = body
        global_transform = body.global_transform

func _on_timer_timeout():
    explode()

func explode():
    var explosion = preload("res://effects/explosion.tscn").instantiate()
    explosion.damage = explosion_damage
    explosion.radius = explosion_radius
    get_parent().add_child(explosion)
    explosion.global_position = global_position
    queue_free()
