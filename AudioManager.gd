extends Node
class_name AudioManager

const SOUNDS = {
    "rain": preload("res://assets/audio/ambient/rain.ogg"),
    "storm": preload("res://assets/audio/ambient/storm.ogg")
}

var current_ambient: AudioStreamPlayer

func play_ambient(sound_name: String):
    stop_ambient()
    if SOUNDS.has(sound_name):
        current_ambient = AudioStreamPlayer.new()
        current_ambient.stream = SOUNDS[sound_name]
        current_ambient.volume_db = -10
        add_child(current_ambient)
        current_ambient.play()

func stop_ambient():
    if current_ambient:
        current_ambient.stop()
        current_ambient.queue_free()
