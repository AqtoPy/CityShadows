extends Node

class_name AchievementSystem

const ACHIEVEMENTS_PATH = "user://achievements.cfg"

enum AchievementType {
    FIRST_KILL,
    FACTION_MASTER,
    COMPLETE_ALL_QUESTS,
    MILLIONAIRE,
    TRAITOR
}

var achievements = {
    AchievementType.FIRST_KILL: {
        "name": "Первая кровь",
        "description": "Устраните первого врага",
        "unlocked": false,
        "hidden": false
    },
    AchievementType.FACTION_MASTER: {
        "name": "Мастер фракций",
        "description": "Достигните максимального уровня во всех фракциях",
        "unlocked": false,
        "hidden": false
    },
    AchievementType.COMPLETE_ALL_QUESTS: {
        "name": "Исполнитель",
        "description": "Выполните все доступные задания",
        "unlocked": false,
        "hidden": false
    },
    AchievementType.MILLIONAIRE: {
        "name": "Миллионер",
        "description": "Заработайте 1,000,000 кредитов",
        "unlocked": false,
        "hidden": false
    },
    AchievementType.TRAITOR: {
        "name": "Предатель",
        "description": "Поменяйте фракцию 3 раза",
        "unlocked": false,
        "hidden": true
    }
}

func _ready():
    load_achievements()

func unlock_achievement(type: AchievementType):
    if not achievements.has(type) or achievements[type]["unlocked"]:
        return
    
    achievements[type]["unlocked"] = true
    save_achievements()
    
    show_achievement_popup(achievements[type]["name"], achievements[type]["description"])
    
    print("Достижение разблокировано: ", achievements[type]["name"])

func load_achievements():
    var config = ConfigFile.new()
    var err = config.load(ACHIEVEMENTS_PATH)
    
    if err != OK:
        return
    
    for type in achievements:
        var key = AchievementType.keys()[type]
        achievements[type]["unlocked"] = config.get_value("achievements", key, false)

func save_achievements():
    var config = ConfigFile.new()
    
    for type in achievements:
        var key = AchievementType.keys()[type]
        config.set_value("achievements", key, achievements[type]["unlocked"])
    
    config.save(ACHIEVEMENTS_PATH)

func show_achievement_popup(title: String, description: String):
    var popup = preload("res://scenes/ui/achievement_popup.tscn").instantiate()
    popup.title = title
    popup.description = description
    get_tree().root.add_child(popup)
    popup.show_popup()

func reset_achievements():
    for type in achievements:
        achievements[type]["unlocked"] = false
    save_achievements()

func get_unlocked_achievements() -> Array:
    var unlocked = []
    for type in achievements:
        if achievements[type]["unlocked"]:
            unlocked.append({
                "type": type,
                "name": achievements[type]["name"],
                "description": achievements[type]["description"]
            })
    return unlocked

func get_all_achievements() -> Array:
    var all = []
    for type in achievements:
        if not achievements[type]["hidden"] or achievements[type]["unlocked"]:
            all.append({
                "type": type,
                "name": achievements[type]["name"],
                "description": achievements[type]["description"],
                "unlocked": achievements[type]["unlocked"],
                "hidden": achievements[type]["hidden"]
            })
    return all
