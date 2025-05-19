extends Node

class_name FactionManager

enum FactionRelation { ALLY, NEUTRAL, ENEMY }

var relations = {
    "police": {
        "police": FactionRelation.ALLY,
        "bandits": FactionRelation.ENEMY,
        "military": FactionRelation.ALLY,
        "civilian": FactionRelation.NEUTRAL
    },
    "bandits": {
        "police": FactionRelation.ENEMY,
        "bandits": FactionRelation.ALLY,
        "military": FactionRelation.ENEMY,
        "civilian": FactionRelation.NEUTRAL
    },
    "military": {
        "police": FactionRelation.ALLY,
        "bandits": FactionRelation.ENEMY,
        "military": FactionRelation.ALLY,
        "civilian": FactionRelation.NEUTRAL
    }
}

var traitors = {
    "police": null,
    "bandits": null,
    "military": null
}

func set_relation(faction1: String, faction2: String, relation: FactionRelation):
    if relations.has(faction1) and relations[faction1].has(faction2):
        relations[faction1][faction2] = relation
        # Симметричное обновление
        if relations.has(faction2) and relations[faction2].has(faction1):
            relations[faction2][faction1] = relation

func get_relation(faction1: String, faction2: String) -> FactionRelation:
    if relations.has(faction1) and relations[faction1].has(faction2):
        return relations[faction1][faction2]
    return FactionRelation.NEUTRAL

func set_traitor(faction: String, bot: Node):
    if traitors.has(faction):
        traitors[faction] = bot

func is_traitor(bot: Node) -> bool:
    for faction in traitors:
        if traitors[faction] == bot:
            return true
    return false

func should_attack(attacker_faction: String, target_faction: String) -> bool:
    return get_relation(attacker_faction, target_faction) == FactionRelation.ENEMY
