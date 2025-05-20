# Возвращает массив номеров слотов с существующими сохранениями
func get_save_slots() -> Array:
    var slots = []
    var dir = DirAccess.open(SAVE_PATH)
    
    # Если папка сохранений не существует - возвращаем пустой массив
    if not dir:
        return slots
    
    # Получаем список файлов в папке сохранений
    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    while file_name != "":
        # Проверяем что файл имеет правильное расширение
        if file_name.ends_with(SAVE_EXTENSION):
            # Извлекаем номер слота из имени файла
            var slot_str = file_name.trim_suffix(SAVE_EXTENSION).trim_prefix("save_")
            if slot_str.is_valid_int():
                slots.append(slot_str.to_int())
        
        file_name = dir.get_next()
    
    # Сортируем слоты по возрастанию
    slots.sort()
    return slots

# Дополнительная функция для получения времени сохранения
func get_save_time(slot: int) -> String:
    var file_path = SAVE_PATH + "save_" + str(slot) + SAVE_EXTENSION
    if not FileAccess.file_exists(file_path):
        return "Нет данных"
    
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file:
        var save_data = file.get_var()
        file.close()
        return save_data.get("timestamp", "Неизвестно")
    return "Ошибка"
