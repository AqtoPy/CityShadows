extends CanvasLayer

class_name HUD

@onready var health_bar = $HealthBar
@onready var armor_bar = $ArmorBar
@onready var money_label = $MoneyLabel
@onready var faction_label = $FactionLabel
@onready var ammo_label = $AmmoLabel
@onready var crosshair = $Crosshair
@onready var interaction_label = $InteractionLabel

func update_health(current: float, max_health: float):
    health_bar.max_value = max_health
    health_bar.value = current

func update_armor(current: float, max_armor: float):
    armor_bar.max_value = max_armor
    armor_bar.value = current

func update_money(amount: int):
    money_label.text = "$%d" % amount

func update_faction(faction: String):
    faction_label.text = faction.capitalize()

func update_ammo(current: int, max_ammo: int):
    ammo_label.text = "%d/%d" % [current, max_ammo]

func show_interaction_text(text: String):
    interaction_label.text = text
    interaction_label.visible = true

func hide_interaction_text():
    interaction_label.visible = false

func update_crosshair(hit: bool):
    if hit:
        crosshair.color = Color.RED
    else:
        crosshair.color = Color.WHITE
