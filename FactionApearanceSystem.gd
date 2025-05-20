extends Node

# Конфигурация моделей и материалов для фракций
const FACTION_DATA = {
    "police": {
        "models": {
            1: preload("res://assets/models/police/recruit.tscn"),
            2: preload("res://assets/models/police/officer.tscn"),
            3: preload("res://assets/models/police/captain.tscn")
        },
        "materials": {
            1: preload("res://assets/materials/police_recruit.tres"),
            2: preload("res://assets/materials/police_officer.tres"),
            3: preload("res://assets/materials/police_captain.tres")
        }
    },
    "bandits": {
        "models": {
            1: preload("res://assets/models/bandits/thug.tscn"),
            2: preload("res://assets/models/bandits/enforcer.tscn"),
            3: preload("res://assets/models/bandits/boss.tscn")
        },
        "materials": {
            1: preload("res://assets/materials/bandit_thug.tres"),
            2: preload("res://assets/materials/bandit_enforcer.tres"),
            3: preload("res://assets/materials/bandit_boss.tres")
        }
    },
    "military": {
        "models": {
            1: preload("res://assets/models/military/private.tscn"),
            2: preload("res://assets/models/military/sergeant.tscn"),
            3: preload("res://assets/models/military/commander.tscn")
        },
        "materials": {
            1: preload("res://assets/materials/military_private.tres"),
            2: preload("res://assets/materials/military_sergeant.tres"),
            3: preload("res://assets/materials/military_commander.tres")
        }
    }
}

func get_model(faction: String, rank: int) -> PackedScene:
    return FACTION_DATA[faction]["models"].get(
        clamp(rank, 1, 3), 
        FACTION_DATA[faction]["models"][1]
    )

func get_material(faction: String, rank: int) -> Material:
    return FACTION_DATA[faction]["materials"].get(
        clamp(rank, 1, 3), 
        FACTION_DATA[faction]["materials"][1]
    )

func update_player_appearance(player: Node, faction: String, rank: int):
    var model_node = player.get_node("Model")
    if model_node:
        model_node.queue_free()
    
    var new_model = get_model(faction, rank).instantiate()
    new_model.name = "Model"
    new_model.set_surface_override_material(0, get_material(faction, rank))
    player.add_child(new_model)
