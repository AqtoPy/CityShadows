extends CanvasLayer

class_name MainMenu

@onready var main_panel = $MainPanel
@onready var settings_panel = $SettingsPanel
@onready var load_game_panel = $LoadGamePanel
@onready var new_game_button = $MainPanel/VBoxContainer/NewGameButton
@onready var load_game_button = $MainPanel/VBoxContainer/LoadGameButton
@onready var settings_button = $MainPanel/VBoxContainer/SettingsButton
@onready var quit_button = $MainPanel/VBoxContainer/QuitButton
@onready var back_button = $SettingsPanel/BackButton
@onready var save_slots_container = $LoadGamePanel/ScrollContainer/SaveSlotsContainer
@onready var version_label = $VersionLabel

func _ready():
    new_game_button.pressed.connect(_on_new_game_pressed)
    load_game_button.pressed.connect(_on_load_game_pressed)
    settings_button.pressed.connect(_on_settings_pressed)
    quit_button.pressed.connect(_on_quit_pressed)
    back_button.pressed.connect(_on_back_pressed)
    
    # Загружаем настройки
    SettingsSystem.load_settings()
    apply_settings()
    
    # Показываем версию игры
    version_label.text = "Тени Норабай v1.0"
    
    # Проверяем доступность кнопки загрузки
    update_load_button()

func _on_new_game_pressed():
    # Создаем новую игру
    var save_system = get_node("/root/SaveSystem")
    save_system.save_game(0)  # Автосохранение в слот 0
    
    # Загружаем сцену игры
    get_tree().change_scene_to_file("res://scenes/world/main.tscn")

func _on_load_game_pressed():
    show_load_game_panel()
    populate_save_slots()

func _on_settings_pressed():
    show_settings_panel()

func _on_quit_pressed():
    get_tree().quit()

func _on_back_pressed():
    show_main_panel()

func show_main_panel():
    main_panel.show()
    settings_panel.hide()
    load_game_panel.hide()

func show_settings_panel():
    main_panel.hide()
    settings_panel.show()
    load_game_panel.hide()

func show_load_game_panel():
    main_panel.hide()
    settings_panel.hide()
    load_game_panel.show()

func populate_save_slots():
    # Очищаем контейнер
    for child in save_slots_container.get_children():
        child.queue_free()
    
    # Получаем список сохранений
    var save_system = get_node("/root/SaveSystem")
    var slots = save_system.get_save_slots()
    
    if slots.is_empty():
        var label = Label.new()
        label.text = "Нет сохраненных игр"
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        save_slots_container.add_child(label)
        return
    
    # Создаем кнопки для каждого слота
    for slot in slots:
        var save_data = save_system.load_game(slot, true)  # Только метаданные
        
        var button = Button.new()
        button.text = "Слот %d - %s" % [slot, save_data.get("timestamp", "Неизвестно")]
        button.custom_minimum_size = Vector2(400, 60)
        button.pressed.connect(_on_save_slot_selected.bind(slot))
        
        save_slots_container.add_child(button)

func _on_save_slot_selected(slot: int):
    var save_system = get_node("/root/SaveSystem")
    if save_system.load_game(slot):
        get_tree().change_scene_to_file("res://scenes/world/main.tscn")

func update_load_button():
    var save_system = get_node("/root/SaveSystem")
    load_game_button.disabled = save_system.get_save_slots().is_empty()

func apply_settings():
    # Применяем настройки графики
    if SettingsSystem.get_setting("fullscreen", false):
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    
    # Применяем настройки звука
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 
        linear_to_db(SettingsSystem.get_setting("master_volume", 1.0)))
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), 
        linear_to_db(SettingsSystem.get_setting("music_volume", 0.7)))
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), 
        linear_to_db(SettingsSystem.get_setting("sfx_volume", 0.8)))
