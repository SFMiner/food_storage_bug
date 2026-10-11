extends SceneTree
## Keyboard use and the sims-site keyboard exit (SPEC section 6): Tab walks the controls in order, Tab past the
## last and Shift+Tab before the first leave the game, Escape closes the open panel first and then leaves,
## arrows/WASD move the bug, and music does not start before the first key.

var _passed: int = 0
var _failed: int = 0
var _main: Node = null


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
	_main = (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(_main)
	for i: int in range(3):
		await process_frame
	var music: AudioStreamPlayer = _main.music
	_check(not music.playing, "music is silent before any key or click")
	_check(not music.autoplay, "music does not autoplay")

	# Tutorial is open: its button has focus; Tab goes to the music switch, then past it leaves
	_check(_main.tutorial_active, "tutorial is open at start")
	var focus: Control = get_root().gui_get_focus_owner()
	_check(focus == _main.tutorial_close_button, "tutorial Close button has focus at start")
	var before: int = _main.leave_count
	await _key(KEY_TAB)
	_check(get_root().gui_get_focus_owner() == _main.music_button, "Tab moves from Close to the music switch")
	_check(_main.leave_count == before, "that Tab does not leave")
	_check(music.playing, "music starts after the first key")
	await _key(KEY_TAB)
	_check(_main.leave_count == before + 1, "Tab past the last control leaves the game")
	_check(get_root().gui_get_focus_owner() == null, "focus is released after leaving")

	# Shift+Tab from nothing focused starts at the last control, then moves back, then leaves before the first
	await _key(KEY_TAB, true)
	_check(get_root().gui_get_focus_owner() == _main.music_button, "Shift+Tab from nothing lands on the last control")
	before = _main.leave_count
	await _key(KEY_TAB, true)
	_check(_main.leave_count == before and get_root().gui_get_focus_owner() == _main.tutorial_close_button, "Shift+Tab on the last control moves back")
	await _key(KEY_TAB, true)
	_check(_main.leave_count == before + 1, "Shift+Tab before the first control leaves the game")

	# Every Tab stop has the visible focus outline
	for c: Control in [_main.music_button, _main.tutorial_close_button, _main.close_button]:
		_check(c.has_theme_stylebox_override("focus") and c.focus_mode == Control.FOCUS_ALL, "%s has the focus outline" % c.name)

	# Escape closes the tutorial first (starting the game), the next Escape leaves
	before = _main.leave_count
	await _key(KEY_ESCAPE)
	_check(not _main.tutorial_active and _main.leave_count == before, "Escape closes the tutorial without leaving")
	await _key(KEY_ESCAPE)
	_check(_main.leave_count == before + 1, "Escape with nothing open leaves")

	# Arrow keys and WASD move the bug (one action, one glucose)
	_main.enemies.clear()
	_main.food_positions.clear()
	var start: Vector2i = _main.player_pos
	var glucose: int = _main.glucose
	await _key(KEY_RIGHT)
	_check(_main.player_pos == start + Vector2i(_main.max_movement, 0), "Right arrow jumps max_movement tiles right (got %s)" % str(_main.player_pos))
	_check(_main.glucose == glucose - 1, "a keyboard move costs one glucose")
	_main.player_is_moving = false
	var here: Vector2i = _main.player_pos
	await _key(KEY_S, false)
	_check(_main.player_pos == here + Vector2i(0, _main.max_movement), "S moves down")
	_main.player_is_moving = false
	here = _main.player_pos
	await _key(KEY_LEFT, true)
	_check(_main.player_pos == here + Vector2i(-1, 0), "Shift+Left moves one tile")

	# Level-complete panel: its button takes focus, Escape continues to level 2
	_main.complete_level()
	_check(get_root().gui_get_focus_owner() == _main.close_button, "Continue button gets focus when a level ends")
	await _key(KEY_ESCAPE)
	_check(not _main.level_complete_panel.visible and _main.current_level == 2, "Escape on the level-complete panel continues to level 2")

	# The music switch turns music off and on from the keyboard
	_main.music_button.grab_focus()
	await _key(KEY_ENTER)
	_check(not _main.music.playing and _main.music_button.text == "Music: Off", "Enter on the music switch turns music off")
	await _key(KEY_SPACE)
	_check(_main.music.playing and _main.music_button.text == "Music: On", "Space turns it back on")
	_finish()


func _finish() -> void:
	print("Test Results: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _key(code: Key, shift: bool = false) -> void:
	for pressed: bool in [true, false]:
		var e: InputEventKey = InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.shift_pressed = shift
		e.pressed = pressed
		get_root().push_input(e)
	await process_frame
	await process_frame
