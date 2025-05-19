extends Node

class_name SaveSystem

const SAVE_PATH = "user://saves/"
const SAVE_EXTENSION = ".save"

func save_game(slot: int = 0):
    var save_data = {
        "timestamp": Time.get_datetime_string_from_system(),
        "player": get_player_data(),
        "world": get_world_data(),
        "quests": get_quests_data(),
        "factions": get_factions_data()
    }
    
    var dir = DirAccess.open("user://")
    if not dir.dir_exists("saves"):
        dir.make_dir("saves")
    
    var file_path = SAVE_PATH + "save_" + str(slot) + SAVE_EXTENSION
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    
    if file:
        file.store_var(save_data)
        file.close()
        return true
    return false

func load_game(slot: int = 0):
    var file_path = SAVE_PATH + "save_" + str(slot) + SAVE_EXTENSION
    if not FileAccess.file_exists(file_path):
        return null
    
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file:
        var save_data = file.get_var()
        file.close()
        apply_save_data(save_data)
        return save_data
    return null

func get_player_data() -> Dictionary:
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        return {}
    
    return {
        "position": player.global_transform.origin,
        "rotation": player.rotation,
        "health": player.health,
        "armor": player.armor,
        "money": player.money,
        "faction": player.faction,
        "inventory": player.inventory.save_inventory() if player.has_method("save_inventory") else {},
        "equipped_weapon": player.get_equipped_weapon_data() if player.has_method("get_equipped_weapon_data") else null
    }

func get_world_data() -> Dictionary:
    var event_manager = get_tree().get_first_node_in_group("event_manager")
    var time_manager = get_tree().get_first_node_in_group("time_manager")
    
    return {
        "active_events": event_manager.get_active_events() if event_manager else [],
        "game_time": time_manager.get_current_time() if time_manager else 0.0,
        "weather": get_weather_data()
    }

func get_quests_data() -> Dictionary:
    var quest_system = get_tree().get_first_node_in_group("quest_system")
    if not quest_system:
        return {}
    
    return {
        "active_quests": quest_system.get_active_quests(),
        "completed_quests": quest_system.get_completed_quests()
    }

func get_factions_data() -> Dictionary:
    var faction_manager = get_tree().get_first_node_in_group("faction_manager")
    var reputation_system = get_tree().get_first_node_in_group("reputation_system")
    
    return {
        "relations": faction_manager.get_all_relations() if faction_manager else {},
        "reputations": reputation_system.get_all_reputations() if reputation_system else {}
    }

func get_weather_data() -> Dictionary:
    var weather_system = get_tree().get_first_node_in_group("weather_system")
    if weather_system and weather_system.has_method("get_current_weather"):
        return weather_system.get_current_weather()
    return {}

func apply_save_data(save_data: Dictionary):
    if not save_data:
        return
    
    # Восстановление игрока
    var player = get_tree().get_first_node_in_group("player")
    if player and save_data.has("player"):
        var player_data = save_data["player"]
        player.global_transform.origin = player_data["position"]
        player.rotation = player_data["rotation"]
        player.health = player_data["health"]
        player.armor = player_data["armor"]
        player.money = player_data["money"]
        player.faction = player_data["faction"]
        
        if player.has_method("load_inventory") and player_data.has("inventory"):
            player.load_inventory(player_data["inventory"])
        
        if player.has_method("equip_weapon") and player_data.has("equipped_weapon"):
            player.equip_weapon(player_data["equipped_weapon"])
    
    # Восстановление мира
    if save_data.has("world"):
        var world_data = save_data["world"]
        
        var event_manager = get_tree().get_first_node_in_group("event_manager")
        if event_manager and world_data.has("active_events"):
            event_manager.load_events(world_data["active_events"])
        
        var time_manager = get_tree().get_first_node_in_group("time_manager")
        if time_manager and world_data.has("game_time"):
            time_manager.set_current_time(world_data["game_time"])
        
        var weather_system = get_tree().get_first_node_in_group("weather_system")
        if weather_system and world_data.has("weather"):
            weather_system.set_weather(world_data["weather"])
    
    # Восстановление квестов
    if save_data.has("quests"):
        var quest_system = get_tree().get_first_node_in_group("quest_system")
        if quest_system:
            quest_system.load_quest
