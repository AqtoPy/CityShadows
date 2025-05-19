extends Node

class_name TimeWeatherSystem

@export var day_duration_minutes = 24.0  # Продолжительность суток в минутах реального времени
@export var start_hour = 12.0  # Начальное время (часы)
@export var weather_change_interval = 5.0  # Интервал смены погоды в минутах игры

enum WeatherType { CLEAR, CLOUDY, RAIN, FOG, STORM }

var current_time = 0.0  # В часах
var current_weather = WeatherType.CLEAR
var weather_transition = 0.0  # Прогресс смены погоды (0-1)
var next_weather = WeatherType.CLEAR
var time_speed = 0.0

@onready var world_environment = $WorldEnvironment
@onready var weather_particles = $WeatherParticles

func _ready():
    calculate_time_speed()
    current_time = start_hour
    set_random_weather()

func _process(delta):
    # Обновление времени
    current_time += delta * time_speed
    if current_time >= 24.0:
        current_time -= 24.0
    
    # Обновление погоды
    if weather_transition < 1.0:
        weather_transition += delta / (weather_change_interval * 60.0 / time_speed)
        update_weather_transition()
    elif randf() < delta * 0.001:  # Маленький шанс сменить погоду
        set_random_weather()

func calculate_time_speed():
    # Вычисляем скорость течения времени (часы игры в секунду реального времени)
    time_speed = 24.0 / (day_duration_minutes * 60.0)

func set_random_weather():
    var weather_weights = {
        WeatherType.CLEAR: 50,
        WeatherType.CLOUDY: 30,
        WeatherType.RAIN: 15,
        WeatherType.FOG: 10,
        WeatherType.STORM: 5
    }
    
    # Уменьшаем шанс на ту же погоду
    weather_weights[current_weather] = max(5, weather_weights[current_weather] / 2)
    
    var total_weight = weather_weights.values().reduce(func(a, b): return a + b)
    var random_value = randf_range(0, total_weight)
    var accumulated_weight = 0.0
    
    for weather in weather_weights:
        accumulated_weight += weather_weights[weather]
        if random_value <= accumulated_weight:
            next_weather = weather
            weather_transition = 0.0
            break

func update_weather_transition():
    # Плавная смена параметров окружения
    match next_weather:
        WeatherType.CLEAR:
            set_weather_parameters(
                lerp(get_weather_parameter(current_weather, "light"), 1.0, weather_transition),
                lerp(get_weather_parameter(current_weather, "fog"), 0.0, weather_transition),
                Color(1, 1, 1)
            )
            weather_particles.emitting = false
        
        WeatherType.CLOUDY:
            set_weather_parameters(
                lerp(get_weather_parameter(current_weather, "light"), 0.7, weather_transition),
                lerp(get_weather_parameter(current_weather, "fog"), 0.2, weather_transition),
                Color(0.8, 0.8, 0.8)
            )
            weather_particles.emitting = false
        
        WeatherType.RAIN:
            set_weather_parameters(
                lerp(get_weather_parameter(current_weather, "light"), 0.5, weather_transition),
                lerp(get_weather_parameter(current_weather, "fog"), 0.4, weather_transition),
                Color(0.6, 0.6, 0.7)
            )
            if weather_transition > 0.5:
                weather_particles.emitting = true
                weather_particles.process_material.set("gravity", Vector3(0, -9.8, 0))
        
        WeatherType.FOG:
            set_weather_parameters(
                lerp(get_weather_parameter(current_weather, "light"), 0.6, weather_transition),
                lerp(get_weather_parameter(current_weather, "fog"), 0.8, weather_transition),
                Color(0.7, 0.7, 0.7)
            )
            weather_particles.emitting = false
        
        WeatherType.STORM:
            set_weather_parameters(
                lerp(get_weather_parameter(current_weather, "light"), 0.3, weather_transition),
                lerp(get_weather_parameter(current_weather, "fog"), 0.5, weather_transition),
                Color(0.4, 0.4, 0.5)
            )
            if weather_transition > 0.5:
                weather_particles.emitting = true
                weather_particles.process_material.set("gravity", Vector3(randf_range(-2, 2), -9.8, randf_range(-2, 2)))
    
    if weather_transition >= 1.0:
        current_weather = next_weather

func get_weather_parameter(weather: WeatherType, parameter: String):
    match weather:
        WeatherType.CLEAR:
            return 1.0 if parameter == "light" else 0.0
        WeatherType.CLOUDY:
            return 0.7 if parameter == "light" else 0.2
        WeatherType.RAIN:
            return 0.5 if parameter == "light" else 0.4
        WeatherType.FOG:
            return 0.6 if parameter == "light" else 0.8
        WeatherType.STORM:
            return 0.3 if parameter == "light" else 0.5
    return 0.0

func set_weather_parameters(light_intensity: float, fog_density: float, ambient_color: Color):
    if world_environment:
        var env = world_environment.environment
        env.ambient_light_energy = light_intensity
        env.ambient_light_color = ambient_color
        env.fog_density = fog_density

func get_current_time() -> float:
    return current_time

func get_current_time_string() -> String:
    var hours = int(current_time)
    var minutes = int((current_time - hours) * 60)
    return "%02d:%02d" % [hours, minutes]

func get_current_weather() -> Dictionary:
    return {
        "type": current_weather,
        "name": WeatherType.keys()[current_weather].capitalize(),
        "transition": weather_transition,
        "next_weather": WeatherType.keys()[next_weather].capitalize()
    }

func set_current_time(hours: float):
    current_time = fmod(hours, 24.0)

func set_weather(weather: WeatherType):
    next_weather = weather
    weather_transition = 0.0
