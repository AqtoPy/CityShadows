#player.gd
signal faction_changed(new_faction)
signal enemy_killed(enemy)

var faction_changes = 0

func change_faction(new_faction):
    faction_changes += 1
    faction = new_faction
    emit_signal("faction_changed", new_faction)

#FactionManager.gd
func update_faction_relations():
    for bot in get_tree().get_nodes_in_group("bots"):
        bot.update_relations()

#HUD.gd
func show_quest_notification(text: String):
    var notif = $QuestNotification
    notif.text = text
    notif.visible = true
    $QuestNotificationTimer.start(3.0)

func show_event_alert(event_type: String):
    var alert = $EventAlert
    alert.text = "Событие: %s" % event_type
    alert.visible = true
    $EventAlertTimer.start(5.0)

#EventManager.gd
func get_active_events() -> Array:
    return active_events.duplicate()

func load_events(events: Array):
    active_events = events.duplicate()
    for event in active_events:
        spawn_event_participants(event["type"], event["location"])
