#player.gd
# Добавить в начало
@export var base_mouse_sensitivity = 0.002

func _ready():
    apply_settings()

func apply_settings():
    var sensitivity = SettingsSystem.get_setting("gameplay/mouse_sensitivity", 0.5)
    mouse_sensitivity = base_mouse_sensitivity * sensitivity
    
    if SettingsSystem.get_setting("gameplay/invert_y", false):
        mouse_sensitivity *= -1

func set_mouse_sensitivity(value: float):
    mouse_sensitivity = base_mouse_sensitivity * value

#faction_manager.gd
signal faction_changed(player, old_faction, new_faction)

func change_player_faction(player, new_faction):
    var old_faction = player.faction
    player.faction = new_faction
    emit_signal("faction_changed", player, old_faction, new_faction)

#quest_system.gd
signal all_quests_completed(player)

func complete_quest(quest_id: String):
    # ... существующий код ...
    
    if get_available_quests(quest["data"]["faction"]).size() == 0:
        emit_signal("all_quests_completed", quest["player"])

#hud.gd
func show_achievement(title: String, description: String):
    var achievement_popup = preload("res://scenes/ui/achievement_popup.tscn").instantiate()
    achievement_popup.title = title
    achievement_popup.description = description
    add_child(achievement_popup)
    achievement_popup.show_popup()

#main.gd
# В главной сцене (main.gd)
func _ready():
    # Настройка связей для достижений
    $FactionManager.faction_changed.connect(_on_faction_changed)
    $QuestSystem.all_quests_completed.connect(_on_all_quests_completed)
    
    # Проверка первого убийства
    var player = $Player
    if player.has_signal("enemy_killed"):
        player.enemy_killed.connect(_on_enemy_killed)

func _on_faction_changed(player, old_faction, new_faction):
    if player.faction_changes >= 3:
        $AchievementSystem.unlock_achievement(AchievementSystem.AchievementType.TRAITOR)

func _on_all_quests_completed(player):
    $AchievementSystem.unlock_achievement(AchievementSystem.AchievementType.COMPLETE_ALL_QUESTS)

func _on_enemy_killed():
    $AchievementSystem.unlock_achievement(AchievementSystem.AchievementType.FIRST_KILL)
