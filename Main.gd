extends Node3D

class_name GameWorld

@onready var player = $Player
@onready var faction_manager = $FactionManager
@onready var quest_system = $QuestSystem
@onready var event_manager = $EventManager
@onready var weather_system = $WeatherSystem
@onready var hud = $CanvasLayer/HUD
@onready var dialogue_ui = $CanvasLayer/DialogueUI
@onready var pause_menu = $CanvasLayer/PauseMenu

var is_paused = false

func _ready():
    # Инициализация систем
    init_player()
    init_managers()
    init_ui()
    
    # Загрузка сохранения
    load_game_data()
    
    # Начальное событие
    event_manager.start_random_event()
    
    # Настройка погоды
    weather_system.set_random_weather()

func _process(delta):
    if Input.is_action_just_pressed("pause"):
        toggle_pause()

func init_player():
    player.health_changed.connect(hud.update_health)
    player.armor_changed.connect(hud.update_armor)
    player.ammo_changed.connect(hud.update_ammo)
    player.interaction_started.connect(hud.show_interaction_prompt)
    player.interaction_ended.connect(hud.hide_interaction_prompt)
    player.faction_changed.connect(_on_player_faction_changed)

func init_managers():
    faction_manager.player = player
    quest_system.player = player
    event_manager.player = player
    
    faction_manager.faction_relation_changed.connect(_on_faction_relation_changed)
    quest_system.quest_started.connect(_on_quest_started)
    quest_system.quest_completed.connect(_on_quest_completed)
    event_manager.event_started.connect(_on_event_started)
    event_manager.event_ended.connect(_on_event_ended)
    weather_system.weather_changed.connect(_on_weather_changed)

func init_ui():
    hud.visible = true
    dialogue_ui.visible = false
    pause_menu.visible = false
    
    hud.set_faction(player.faction)
    hud.update_health(player.health, player.max_health)
    hud.update_armor(player.armor, player.max_armor)

func load_game_data():
    var save_system = get_node("/root/SaveSystem")
    if save_system.has_save():
        save_system.load_game()

func save_game():
    var save_system = get_node("/root/SaveSystem")
    save_system.save_game()

func toggle_pause():
    is_paused = !is_paused
    get_tree().paused = is_paused
    pause_menu.visible = is_paused
    
    if is_paused:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    else:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_player_faction_changed(new_faction):
    hud.set_faction(new_faction)
    faction_manager.update_faction_relations()

func _on_faction_relation_changed(faction1, faction2, relation):
    # Обновляем ИИ ботов при изменении отношений
    for bot in get_tree().get_nodes_in_group("bots"):
        if bot.faction == faction1 or bot.faction == faction2:
            bot.update_behavior()

func _on_quest_started(quest_data):
    hud.show_quest_notification("Начато: %s" % quest_data["title"])
    AchievementSystem.check_quest_achievements()

func _on_quest_completed(quest_data):
    hud.show_quest_notification("Завершено: %s" % quest_data["title"])
    player.add_money(quest_data["reward"])

func _on_event_started(event_data):
    hud.show_event_alert(event_data["type"])

func _on_event_ended(event_data):
    pass  # Можно добавить обработку завершения событий

func _on_weather_changed(new_weather):
    # Настройка визуальных эффектов под погоду
    match new_weather:
        WeatherSystem.WeatherType.RAIN:
            AudioManager.play_ambient("rain")
        WeatherSystem.WeatherType.STORM:
            AudioManager.play_ambient("storm")
        _:
            AudioManager.stop_ambient()

func _on_dialogue_started(npc, dialogue):
    dialogue_ui.start_dialogue(npc, dialogue)
    dialogue_ui.visible = true
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_dialogue_ended():
    dialogue_ui.visible = false
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_achievement_unlocked(title, description):
    $CanvasLayer/AchievementPopup.show_achievement(title, description)

func _notification(what):
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        save_game()
