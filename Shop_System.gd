extends CanvasLayer

class_name ShopSystem

@export var shop_items: Array[Dictionary] = [
    {"name": "Пистолет", "price": 500, "icon": "res://assets/icons/pistol.png", "type": "weapon"},
    {"name": "Аптечка", "price": 100, "icon": "res://assets/icons/medkit.png", "type": "health"},
    {"name": "Броня", "price": 300, "icon": "res://assets/icons/armor.png", "type": "armor"}
]

var player_ref: Node = null
var is_shop_open: bool = false

@onready var shop_panel = $ShopPanel
@onready var items_container = $ShopPanel/ScrollContainer/ItemsContainer
@onready var money_label = $ShopPanel/MoneyLabel
@onready var close_button = $ShopPanel/CloseButton

func _ready():
    close_button.pressed.connect(close_shop)
    shop_panel.hide()

func open_shop(player: Node):
    player_ref = player
    is_shop_open = true
    update_shop_display()
    shop_panel.show()
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_shop():
    is_shop_open = false
    shop_panel.hide()
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    player_ref = null

func update_shop_display():
    # Очищаем контейнер
    for child in items_container.get_children():
        child.queue_free()
    
    # Обновляем деньги игрока
    if player_ref:
        money_label.text = "Деньги: $%d" % player_ref.money
    
    # Создаем кнопки для каждого товара
    for item in shop_items:
        var item_panel = PanelContainer.new()
        item_panel.custom_minimum_size = Vector2(300, 80)
        
        var hbox = HBoxContainer.new()
        hbox.alignment = BoxContainer.ALIGNMENT_CENTER
        
        # Иконка предмета
        var texture_rect = TextureRect.new()
        texture_rect.texture = load(item["icon"])
        texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        texture_rect.custom_minimum_size = Vector2(64, 64)
        
        # Описание предмета
        var vbox = VBoxContainer.new()
        var name_label = Label.new()
        name_label.text = item["name"]
        var price_label = Label.new()
        price_label.text = "Цена: $%d" % item["price"]
        
        vbox.add_child(name_label)
        vbox.add_child(price_label)
        
        # Кнопка покупки
        var buy_button = Button.new()
        buy_button.text = "Купить"
        buy_button.pressed.connect(_on_buy_pressed.bind(item))
        
        hbox.add_child(texture_rect)
        hbox.add_child(vbox)
        hbox.add_child(buy_button)
        item_panel.add_child(hbox)
        items_container.add_child(item_panel)

func _on_buy_pressed(item: Dictionary):
    if not player_ref:
        return
    
    if player_ref.money >= item["price"]:
        player_ref.money -= item["price"]
        give_item_to_player(item)
        update_shop_display()
    else:
        show_message("Недостаточно денег!")

func give_item_to_player(item: Dictionary):
    match item["type"]:
        "weapon":
            if player_ref.has_method("equip_weapon"):
                var weapon_scene = load("res://entities/weapons/%s.tscn" % item["name"].to_lower())
                player_ref.equip_weapon(weapon_scene)
        "health":
            if player_ref.has_method("heal"):
                player_ref.heal(50)
        "armor":
            if player_ref.has_method("add_armor"):
                player_ref.add_armor(50)
    
    show_message("Приобретено: %s" % item["name"])

func show_message(text: String):
    var message = Label.new()
    message.text = text
    message.modulate = Color.GREEN_YELLOW
    items_container.add_child(message)
    get_tree().create_timer(2.0).timeout.connect(func(): message.queue_free())

func _input(event):
    if is_shop_open and event.is_action_pressed("ui_cancel"):
        close_shop()
