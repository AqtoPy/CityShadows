extends CanvasLayer

class_name DialogueSystem

@export var dialogue_font: FontFile
@export var npc_font_color: Color = Color.SKY_BLUE
@export var player_font_color: Color = Color.WHITE

var current_dialogue: Array = []
var current_line: int = 0
var is_dialogue_active: bool = false
var current_npc: Node = null

@onready var dialogue_box = $DialogueBox
@onready var dialogue_label = $DialogueBox/MarginContainer/DialogueLabel
@onready var name_label = $DialogueBox/NameLabel
@onready var options_container = $DialogueBox/OptionsContainer

func _ready():
    hide_dialogue()

func start_dialogue(npc: Node, dialogue: Array):
    if is_dialogue_active:
        return
    
    current_npc = npc
    current_dialogue = dialogue
    current_line = 0
    is_dialogue_active = true
    
    show_dialogue()
    show_next_line()

func show_dialogue():
    dialogue_box.visible = true
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_dialogue():
    dialogue_box.visible = false
    options_container.hide()
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    is_dialogue_active = false

func show_next_line():
    if current_line >= current_dialogue.size():
        end_dialogue()
        return
    
    var line_data = current_dialogue[current_line]
    
    if line_data.has("name"):
        name_label.text = line_data["name"]
        
        if line_data["name"] == "Игрок":
            name_label.add_theme_color_override("font_color", player_font_color)
            dialogue_label.add_theme_color_override("font_color", player_font_color)
        else:
            name_label.add_theme_color_override("font_color", npc_font_color)
            dialogue_label.add_theme_color_override("font_color", npc_font_color)
    
    if line_data.has("text"):
        dialogue_label.text = line_data["text"]
    
    if line_data.has("options"):
        show_options(line_data["options"])
    else:
        options_container.hide()
    
    current_line += 1

func show_options(options: Array):
    # Очищаем предыдущие варианты
    for child in options_container.get_children():
        child.queue_free()
    
    # Создаем новые кнопки
    for option in options:
        var button = Button.new()
        button.text = option["text"]
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.custom_minimum_size = Vector2(300, 40)
        
        if dialogue_font:
            button.add_theme_font_override("font", dialogue_font)
        
        button.pressed.connect(_on_option_selected.bind(option))
        options_container.add_child(button)
    
    options_container.show()

func _on_option_selected(option: Dictionary):
    if option.has("response"):
        current_dialogue.insert(current_line, {
            "name": current_npc.get_display_name(),
            "text": option["response"]
        })
    
    if option.has("action"):
        match option["action"]:
            "join_faction":
                if current_npc.has_method("recruit_to_faction"):
                    current_npc.recruit_to_faction()
            "give_quest":
                if current_npc.has_method("give_quest"):
                    current_npc.give_quest()
            "trade":
                if current_npc.has_method("open_trade"):
                    current_npc.open_trade()
    
    show_next_line()

func end_dialogue():
    if current_npc and current_npc.has_method("on_dialogue_end"):
        current_npc.on_dialogue_end()
    
    hide_dialogue()

func _input(event):
    if is_dialogue_active and event.is_action_pressed("interact"):
        if options_container.visible:
            return
        show_next_line()
