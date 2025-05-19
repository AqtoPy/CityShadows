extends Node

class_name SettingsSystem

const SETTINGS_PATH = "user://settings.cfg"

var default_settings = {
    "graphics": {
        "fullscreen": true,
        "resolution": "1920x1080",
        "vsync": true,
        "brightness": 1.0,
        "fov": 75.0
    },
    "audio": {
        "master_volume": 1.0,
        "music_volume": 0.7,
        "sfx_volume": 0.8,
        "radio_volume": 0.6
    },
    "gameplay": {
        "mouse_sensitivity": 0.5,
        "invert_y": false,
        "subtitles": true,
        "language": "ru"
    }
}

var current_settings = {}

func _ready():
    load_settings()

func load_settings():
    var config = ConfigFile.new()
    var err = config.load(SETTINGS_PATH)
    
    if err != OK:
        # Если файла нет, используем настройки по умолчанию
        current_settings = default_settings.duplicate(true)
        save_settings()
        return
    
    # Загружаем настройки из файла
    current_settings = {}
    
    for section in default_settings:
        current_settings[section] = {}
        for key in default_settings[section]:
            current_settings[section][key] = config.get_value(section, key, default_settings[section][key])

func save_settings():
    var config = ConfigFile.new()
    
    for section in current_settings:
        for key in current_settings[section]:
            config.set_value(section, key, current_settings[section][key])
    
    config.save(SETTINGS_PATH)

func get_setting(path: String, default = null):
    var parts = path.split("/")
    if parts.size() == 1:
        parts = path.split("_")  # Для обратной совместимости
    
    if parts.size() == 1:
        if current_settings.has(parts[0]):
            return current_settings[parts[0]]
    elif parts.size() == 2:
        if current_settings.has(parts[0]) and current_settings[parts[0]].has(parts[1]):
            return current_settings[parts[0]][parts[1]]
    
    return default

func set_setting(path: String, value):
    var parts = path.split("/")
    if parts.size() == 1:
        parts = path.split("_")  # Для обратной совместимости
    
    if parts.size() == 1:
        current_settings[parts[0]] = value
    elif parts.size() == 2:
        if not current_settings.has(parts[0]):
            current_settings[parts[0]] = {}
        current_settings[parts[0]][parts[1]] = value
    
    save_settings()
    apply_setting(path, value)

func apply_setting(path: String, value):
    match path:
        "graphics/fullscreen":
            DisplayServer.window_set_mode(
                DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED
            )
        "graphics/vsync":
            DisplayServer.window_set_vsync_mode(
                DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED
            )
        "audio/master_volume":
            AudioServer.set_bus_volume_db(
                AudioServer.get_bus_index("Master"), 
                linear_to_db(value)
            )
        "audio/music_volume":
            AudioServer.set_bus_volume_db(
                AudioServer.get_bus_index("Music"), 
                linear_to_db(value)
            )
        "audio/sfx_volume":
            AudioServer.set_bus_volume_db(
                AudioServer.get_bus_index("SFX"), 
                linear_to_db(value)
            )
        "gameplay/mouse_sensitivity":
            if get_tree().has_group("player"):
                for player in get_tree().get_nodes_in_group("player"):
                    if player.has_method("set_mouse_sensitivity"):
                        player.set_mouse_sensitivity(value)
