extends SceneTree
## Smoke test: main.tscn loads, the tutorial closes, level 1 starts, frames run, and a click move works.

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	_run()


func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		print("FAIL: " + label)


func _run() -> void:
	await get_root().ready
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(main)
	for i: int in range(5):
		await process_frame
	_check(main.tutorial_panel.visible, "tutorial shows at start")
	main.tutorial_close_button.pressed.emit()
	for i: int in range(60):
		await process_frame
	_check(main.current_level == 1 and main.glucose == main.MAX_GLUCOSE, "level 1 starts with full glucose")
	_check(main.food_positions.size() == 3, "three food items spawn")
	_check(main.enemies.size() == 2, "two spiders on level 1")
	var start: Vector2i = main.player_pos
	main.try_move_to(start + Vector2i(3, 0))
	_check(main.player_pos == start + Vector2i(3, 0) or main.is_dying, "a move reaches the target (or hits a spider)")
	if not main.is_dying:
		_check(main.glucose <= main.MAX_GLUCOSE - 1 or main.food_collected > 0, "the move costs glucose")
	main.start_level(2)
	for i: int in range(30):
		await process_frame
	_check(main.enemies.size() == 3, "three spiders on level 2")
	_check(main.max_movement == 5, "level 2 starts at full movement")
	print("Test Results: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
