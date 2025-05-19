extends Node

class_name RadioController

@export var stations = {
    "Норабай FM": {
        "stream": preload("res://assets/radio/stations/norabay_fm.ogg"),
        "volume": -10.0
    },
    "Полицейская волна": {
        "stream": preload("res://assets/radio/stations/police_radio.ogg"),
        "volume": -5.0
    },
    "Военное радио": {
        "stream": preload("res://assets/radio/stations/military_radio.ogg"),
        "volume": -8.0
    }
}

@export var max_static_volume = -20.0
@export var min_static_volume = -40.0
@export var static_change_speed = 2.0

var current_station = ""
var is_radio_on = false
var static_volume = min_static_volume
var target_static_volume = min_static_volume

@onready var music_player = $MusicPlayer
@onready var static_player = $StaticPlayer

func _ready():
    music_player.volume_db = -80.0
    static_player.volume_db = static_volume

func _process(delta):
    # Плавное изменение громкости шума
    static_volume = lerp(static_volume, target_static_volume, delta * static_change_speed)
    static_player.volume_db = static_volume
    
    # Автоматическое переключение станций в машине
    if is_radio_on and current_station == "" and randf() < delta * 0.1:
        var available_stations = stations.keys()
        if available_stations.size() > 0:
            change_station(available_stations[randi() % available_stations.size()])

func toggle_radio():
    is_radio_on = !is_radio_on
    
    if is_radio_on:
        target_static_volume = max_static_volume
        if current_station == "":
            change_station(stations.keys()[0])
    else:
        target_static_volume = min_static_volume
        music_player.volume_db = -80.0
        current_station = ""

func change_station(station_name: String):
    if not stations.has(station_name) or station_name == current_station:
        return
    
    # Плавное угасание текущей станции
    if music_player.playing:
        var tween = create_tween()
        tween.tween_property(music_player, "volume_db", -80.0, 0.5)
        await tween.finished
    
    current_station = station_name
    
    if is_radio_on:
        music_player.stream = stations[station_name]["stream"]
        music_player.play()
        var tween = create_tween()
        tween.tween_property(music_player, "volume_db", stations[station_name]["volume"], 1.0)

func get_current_station() -> Dictionary:
    if current_station == "":
        return {"name": "Выкл", "volume": 0.0}
    return {
        "name": current_station,
        "volume": music_player.volume_db
    }

func set_radio_state(on: bool, station: String = ""):
    if on != is_radio_on:
        toggle_radio()
    
    if station != "" and station != current_station:
        change_station(station)

func _on_vehicle_entered():
    # Улучшение приема в транспорте
    static_change_speed = 5.0
    max_static_volume = -25.0

func _on_vehicle_exited():
    # Ухудшение приема вне транспорта
    static_change_speed = 2.0
    max_static_volume = -20.0
