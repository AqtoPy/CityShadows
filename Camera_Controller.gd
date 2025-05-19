extends Camera3D

class_name CameraController

@export var mouse_sensitivity: float = 0.002
@export var min_pitch: float = -PI/2 + 0.1
@export var max_pitch: float = PI/2 - 0.1

var is_active: bool = true

func _input(event):
    if not is_active:
        return
    
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        # Горизонтальное вращение (родительский узел)
        get_parent().rotate_y(-event.relative.x * mouse_sensitivity)
        
        # Вертикальное вращение (камера)
        rotate_x(-event.relative.y * mouse_sensitivity)
        rotation.x = clamp(rotation.x, min_pitch, max_pitch)

func set_active(active: bool):
    is_active = active
    if active:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    else:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
