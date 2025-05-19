extends Node

class_name EventManager

enum EventType { 
    BANK_ROBBERY, 
    POLICE_RAID, 
    MILITARY_CHECKPOINT, 
    GANG_WAR, 
    PRISON_BREAK 
}

@export var event_cooldown: float = 300.0  # 5 минут
@export var min_event_duration: float = 120.0  # 2 минуты
@export var max_event_duration: float = 300.0  # 5 минут

var current_event: Dictionary = {}
var event_timer: Timer = null
var cooldown_timer: Timer = null
var active_events: Array = []
var event_locations: Dictionary = {}

func _ready():
    event_timer = Timer.new()
    event_timer.one_shot = true
    add_child(event_timer)
    event_timer.timeout.connect(_on_event_end)
    
    cooldown_timer = Timer.new()
    cooldown_timer.one_shot = true
    add_child(cooldown_timer)
    cooldown_timer.timeout.connect(_on_cooldown_end)
    
    initialize_event_locations()
    start_event_cooldown()

func initialize_event_locations():
    # Эти точки должны быть размечены на карте
    event_locations = {
        EventType.BANK_ROBBERY: get_tree().get_nodes_in_group("bank_location"),
        EventType.POLICE_RAID: get_tree().get_nodes_in_group("hideout_location"),
        EventType.MILITARY_CHECKPOINT: get_tree().get_nodes_in_group("street_location"),
        EventType.GANG_WAR: get_tree().get_nodes_in_group("territory_location"),
        EventType.PRISON_BREAK: get_tree().get_nodes_in_group("prison_location")
    }

func start_event_cooldown():
    cooldown_timer.start(event_cooldown)

func start_random_event():
    if active_events.size() >= 2:  # Максимум 2 события одновременно
        return
    
    var available_events = []
    for event in EventType.values():
        if not event in active_events and event_locations[event].size() > 0:
            available_events.append(event)
    
    if available_events.size() == 0:
        return
    
    var random_event = available_events[randi() % available_events.size()]
    var event_location = event_locations[random_event][randi() % event_locations[random_event].size()]
    
    current_event = {
        "type": random_event,
        "location": event_location.global_position,
        "duration": randf_range(min_event_duration, max_event_duration),
        "participants": []
    }
    
    active_events.append(random_event)
    event_timer.start(current_event["duration"])
    
    spawn_event_participants(random_event, event_location.global_position)
    emit_signal("event_started", current_event)

func spawn_event_participants(event_type: EventType, location: Vector3):
    match event_type:
        EventType.BANK_ROBBERY:
            spawn_group("bandits", 5, location)
            spawn_group("police", 3, location + Vector3(5, 0, 5))
        
        EventType.POLICE_RAID:
            spawn_group("police", 6, location)
            spawn_group("bandits", 4, location + Vector3(3, 0, 3))
        
        EventType.MILITARY_CHECKPOINT:
            spawn_group("military", 4, location)
        
        EventType.GANG_WAR:
            spawn_group("bandits", 5, location)
            spawn_group("bandits", 5, location + Vector3(10, 0, 0), "rival_band")
        
        EventType.PRISON_BREAK:
            spawn_group("prisoners", 3, location)
            spawn_group("police", 4, location + Vector3(2, 0, 2))

func spawn_group(faction: String, count: int, position: Vector3, special_group: String = ""):
    var bot_scene = load("res://entities/bot.tscn")
    
    for i in range(count):
        var bot = bot_scene.instantiate()
        bot.faction = faction
        bot.global_position = position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
        
        if special_group != "":
            bot.add_to_group(special_group)
        
        get_tree().current_scene.add_child(bot)
        current_event["participants"].append(bot)

func _on_event_end():
    if current_event.is_empty():
        return
    
    # Удаляем участников события
    for participant in current_event["participants"]:
        if is_instance_valid(participant):
            participant.queue_free()
    
    emit_signal("event_ended", current_event)
    active_events.erase(current_event["type"])
    current_event = {}
    start_event_cooldown()

func _on_cooldown_end():
    start_random_event()

signal event_started(event_data: Dictionary)
signal event_ended(event_data: Dictionary)
