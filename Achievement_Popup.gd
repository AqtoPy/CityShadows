extends Control

class_name AchievementPopup

@export var display_time: float = 3.0
@export var slide_in_time: float = 0.5
@export var slide_out_time: float = 0.5

@onready var title_label = $Panel/TitleLabel
@onready var desc_label = $Panel/DescLabel
@onready var icon_texture = $Panel/IconTexture
@onready var anim_player = $AnimationPlayer

var title: String = ""
var description: String = ""

func _ready():
    title_label.text = title
    desc_label.text = description
    anim_player.play("slide_in")

func show_popup():
    visible = true
    anim_player.play("slide_in")
    await anim_player.animation_finished
    await get_tree().create_timer(display_time).timeout
    anim_player.play("slide_out")
    await anim_player.animation_finished
    queue_free()
