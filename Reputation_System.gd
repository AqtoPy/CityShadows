extends Node

class_name ReputationSystem

@export var max_reputation: int = 100
@export var min_reputation: int = -100
@export var decay_rate: float = 0.1  # Потеря репутации в минуту

var faction_reputation: Dictionary = {
    "police": 0,
    "bandits": 0,
    "military": 0,
    "civilians": 0
}

var decay_timer: Timer = Timer.new()

func _ready():
    decay_timer.wait_time = 60.0  # 1 минута
    decay_timer.timeout.connect(_on_decay_timeout)
    add_child(decay_timer)
    decay_timer.start()

func update_reputation(faction: String, amount: int):
    if not faction in faction_reputation:
        return
    
    faction_reputation[faction] = clamp(
        faction_reputation[faction] + amount,
        min_reputation,
        max_reputation
    )
    
    emit_signal("reputation_changed", faction, faction_reputation[faction])

func get_reputation(faction: String) -> int:
    return faction_reputation.get(faction, 0)

func get_relation_between(faction1: String, faction2: String) -> float:
    if faction1 == faction2:
        return 1.0
    
    var rep1 = get_reputation(faction1)
    var rep2 = get_reputation(faction2)
    
    # Среднее значение репутации между двумя фракциями
    return (rep1 + rep2) / (2.0 * max_reputation)

func _on_decay_timeout():
    for faction in faction_reputation:
        if faction_reputation[faction] > 0:
            update_reputation(faction, -ceil(decay_rate))
        elif faction_reputation[faction] < 0:
            update_reputation(faction, ceil(decay_rate))

signal reputation_changed(faction: String, new_value: int)
