func _on_weather_changed(new_weather):
    # Настройка визуальных эффектов под погоду
    match new_weather:
        WeatherSystem.WeatherType.RAIN:
            get_node("/root/AudioManager").play_ambient("rain")
        WeatherSystem.WeatherType.STORM:
            get_node("/root/AudioManager").play_ambient("storm")
        _:
            get_node("/root/AudioManager").stop_ambient()
