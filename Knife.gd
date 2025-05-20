extends Node3D

@export var damage: int = 25
@export var attack_range: float = 1.5
@export var attack_cooldown: float = 0.8

var can_attack: bool = true

func attack():
    if can_attack:
        can_attack = false
        $AnimationPlayer.play("stab")
        var space = get_world_3d().direct_space_state
        var query = PhysicsRayQueryParameters3D.create(
            global_position,
            global_position + global_transform.basis.z * attack_range
        )
        var result = space.intersect_ray(query)
        if result:
            var body = result.collider
            if body.has_method("take_damage"):
                body.take_damage(damage)
        $CooldownTimer.start(attack_cooldown)

func _on_cooldown_timer_timeout():
    can_attack = true
