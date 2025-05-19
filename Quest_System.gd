extends Node

class_name QuestSystem

enum QuestState { NOT_STARTED, IN_PROGRESS, COMPLETED, FAILED }

@export var available_quests: Array[Dictionary] = [
    {
        "id": "police_arrest",
        "title": "Арест преступника",
        "description": "Найдите и арестуйте разыскиваемого преступника",
        "faction": "police",
        "reward": 500,
        "target": "bandit_leader",
        "target_count": 1
    },
    {
        "id": "bandit_robbery",
        "title": "Ограбление магазина",
        "description": "Ограбьте местный магазин и принесите добычу",
        "faction": "bandits",
        "reward": 800,
        "target": "store_safe",
        "target_count": 1
    }
]

var active_quests: Dictionary = {}
var completed_quests: Array = []

func give_quest(quest_id: String, player: Node):
    if quest_id in active_quests or quest_id in completed_quests:
        return
    
    var quest_data = find_quest_by_id(quest_id)
    if not quest_data:
        return
    
    var quest = {
        "data": quest_data,
        "state": QuestState.IN_PROGRESS,
        "progress": 0,
        "player": player
    }
    
    active_quests[quest_id] = quest
    player.emit_signal("quest_started", quest_data)
    return quest

func find_quest_by_id(quest_id: String) -> Dictionary:
    for quest in available_quests:
        if quest["id"] == quest_id:
            return quest.duplicate()
    return {}

func update_quest_progress(quest_id: String, amount: int = 1):
    if not quest_id in active_quests:
        return
    
    var quest = active_quests[quest_id]
    quest["progress"] += amount
    
    if quest["progress"] >= quest["data"]["target_count"]:
        complete_quest(quest_id)

func complete_quest(quest_id: String):
    if not quest_id in active_quests:
        return
    
    var quest = active_quests[quest_id]
    quest["state"] = QuestState.COMPLETED
    
    # Выдача награды
    if quest["player"].has_method("add_money"):
        quest["player"].add_money(quest["data"]["reward"])
    
    # Обновление репутации
    if quest["player"].has_method("update_reputation"):
        quest["player"].update_reputation(quest["data"]["faction"], 10)
    
    completed_quests.append(quest_id)
    active_quests.erase(quest_id)
    quest["player"].emit_signal("quest_completed", quest["data"])

func fail_quest(quest_id: String):
    if not quest_id in active_quests:
        return
    
    var quest = active_quests[quest_id]
    quest["state"] = QuestState.FAILED
    
    # Штраф к репутации
    if quest["player"].has_method("update_reputation"):
        quest["player"].update_reputation(quest["data"]["faction"], -5)
    
    active_quests.erase(quest_id)
    quest["player"].emit_signal("quest_failed", quest["data"])

func get_available_quests(faction: String) -> Array:
    var result = []
    for quest in available_quests:
        if quest["faction"] == faction and not quest["id"] in active_quests and not quest["id"] in completed_quests:
            result.append(quest)
    return result

func get_active_quests() -> Array:
    return active_quests.values()

func is_quest_completed(quest_id: String) -> bool:
    return quest_id in completed_quests
