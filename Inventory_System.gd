extends Node

class_name InventorySystem

@export var max_items = 20
@export var max_weight = 50.0

var items: Array[Dictionary] = []
var current_weight = 0.0
var equipped_weapon = null

signal inventory_updated
signal weapon_changed(weapon_data)

func add_item(item_data: Dictionary) -> bool:
    if items.size() >= max_items or current_weight + item_data.get("weight", 1.0) > max_weight:
        return false
    
    # Объединение стакаемых предметов
    if item_data.get("stackable", false):
        for existing_item in items:
            if existing_item["id"] == item_data["id"]:
                existing_item["quantity"] += item_data.get("quantity", 1)
                current_weight += item_data.get("weight", 1.0)
                inventory_updated.emit()
                return true
    
    items.append(item_data.duplicate())
    current_weight += item_data.get("weight", 1.0)
    inventory_updated.emit()
    return true

func remove_item(item_index: int, quantity: int = 1) -> Dictionary:
    if item_index < 0 or item_index >= items.size():
        return {}
    
    var item = items[item_index]
    
    if item.get("stackable", false) and item["quantity"] > quantity:
        item["quantity"] -= quantity
        current_weight -= item.get("weight", 1.0) * quantity
        inventory_updated.emit()
        return item.duplicate()
    else:
        current_weight -= item.get("weight", 1.0) * item.get("quantity", 1)
        var removed_item = items.pop_at(item_index)
        inventory_updated.emit()
        return removed_item

func equip_weapon(item_index: int):
    if item_index < 0 or item_index >= items.size():
        return
    
    var item = items[item_index]
    if not item.get("is_weapon", false):
        return
    
    # Если уже экипировано оружие - возвращаем его в инвентарь
    if equipped_weapon:
        add_item(equipped_weapon)
    
    equipped_weapon = remove_item(item_index)
    weapon_changed.emit(equipped_weapon)

func use_item(item_index: int):
    if item_index < 0 or item_index >= items.size():
        return
    
    var item = items[item_index]
    
    match item["type"]:
        "health":
            if owner.has_method("heal"):
                owner.heal(item["amount"])
                remove_item(item_index)
        "armor":
            if owner.has_method("add_armor"):
                owner.add_armor(item["amount"])
                remove_item(item_index)
        "ammo":
            if equipped_weapon and equipped_weapon["ammo_type"] == item["ammo_type"]:
                equipped_weapon["current_ammo"] += item["amount"]
                remove_item(item_index)
                weapon_changed.emit(equipped_weapon)

func get_items_by_type(type: String) -> Array:
    return items.filter(func(item): return item["type"] == type)

func has_item(item_id: String) -> bool:
    return items.any(func(item): return item["id"] == item_id)

func sort_by_weight():
    items.sort_custom(func(a, b): return a.get("weight", 0.0) < b.get("weight", 0.0))
    inventory_updated.emit()

func sort_by_name():
    items.sort_custom(func(a, b): return a["name"] < b["name"])
    inventory_updated.emit()

func save_inventory() -> Dictionary:
    return {
        "items": items.duplicate(true),
        "equipped_weapon": equipped_weapon.duplicate(true) if equipped_weapon else null,
        "current_weight": current_weight
    }

func load_inventory(data: Dictionary):
    items = data.get("items", [])
    equipped_weapon = data.get("equipped_weapon", null)
    current_weight = data.get("current_weight", 0.0)
    inventory_updated.emit()
    if equipped_weapon:
        weapon_changed.emit(equipped_weapon)
