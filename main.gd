extends Node2D

# ============ CONSTANTS ============
const GRID_WIDTH = 30
const GRID_HEIGHT = 20
const CELL_SIZE = 32

const MAX_GLUCOSE = 5
const MAX_FAT = 5
const FOOD_GLUCOSE_VALUE = 3

const LEVEL_1_FOOD_GOAL = 10
const LEVEL_2_FOOD_GOAL = 20
const LEVEL_2_FAT_GOAL = 2

const PLAYER_JUMP_DURATION = 0.2
const PLAYER_JUMP_HEIGHT = 10.0
const ENEMY_SPEED_CELLS_PER_SEC = 3.0
const GRID_ALPHA = 0.0

# ============ GAME STATE ============
var current_level = 1
var player_pos = Vector2i(GRID_WIDTH / 2, GRID_HEIGHT / 2)

var glucose = 5
var fat = 0
var food_collected = 0

var max_movement = 5
var player_visual_pos = Vector2.ZERO
var player_move_start = Vector2.ZERO
var player_move_end = Vector2.ZERO
var player_move_elapsed = 0.0
var player_is_moving = false
var enemies_moving = false
var tutorial_active = true
var tutorial_shown = false

# ============ ENTITIES ============
var food_positions = []
var enemies = []  # Array of {pos: Vector2i, path: Array[Vector2i], path_index: int}

# ============ NODES ============
@onready var camera = $Camera2D
@onready var ui_label = $UI/Label
@onready var level_complete_panel = $UI/LevelCompletePanel
@onready var tutorial_panel = $UI/TutorialPanel
@onready var tutorial_close_button = $UI/TutorialPanel/CloseButton
@onready var close_button = $UI/LevelCompletePanel/CloseButton

# ============ SOUND NODES ============
@onready var sound_click: AudioStreamPlayer = $sound_click
@onready var sound_eat: AudioStreamPlayer = $sound_eat
@onready var sound_convert: AudioStreamPlayer = $sound_convert
@onready var sound_death: AudioStreamPlayer = $sound_death

# ============================================
# INITIALIZATION
# ============================================

func _ready():
	randomize()
	setup_camera()
	setup_ui()
	close_button.pressed.connect(_on_level_complete_close_pressed)
	tutorial_close_button.pressed.connect(_on_tutorial_close_pressed)
	if tutorial_shown:
		tutorial_active = false
		tutorial_panel.hide()
		start_level(1)
	else:
		set_process(false)
		tutorial_panel.show()
		update_ui()

func setup_camera():
	var world_width = GRID_WIDTH * CELL_SIZE
	var world_height = GRID_HEIGHT * CELL_SIZE
	camera.position = Vector2(world_width / 2, world_height / 2)



func load_sound(player: AudioStreamPlayer, path: String):
	if ResourceLoader.exists(path):
		player.stream = load(path)

func play_sound(player: AudioStreamPlayer):
	if player.stream:
		player.play()

func setup_ui():
	level_complete_panel.hide()

# ============================================
# LEVEL MANAGEMENT
# ============================================

func start_level(level: int):
	current_level = level
	player_pos = Vector2i(GRID_WIDTH / 2, GRID_HEIGHT / 2)
	glucose = MAX_GLUCOSE
	fat = 0
	food_collected = 0
	player_is_moving = false
	player_move_elapsed = 0.0
	player_visual_pos = tile_to_world(player_pos)
	enemies_moving = false
	
	food_positions.clear()
	enemies.clear()
	
	# Spawn initial food
	spawn_food()
	spawn_food()
	spawn_food()
	
	# Spawn enemies
	spawn_enemies()
	
	update_max_movement()
	update_ui()
	queue_redraw()

func spawn_enemies():
	var enemy_count = 2 if current_level == 1 else 3
	
	for i in range(enemy_count):
		var enemy_data = create_enemy_with_patrol()
		enemies.append(enemy_data)

func create_enemy_with_patrol() -> Dictionary:
	# Create a random patrol path
	var start_x = randi() % GRID_WIDTH
	var start_y = randi() % GRID_HEIGHT
	
	var path = []
	var patrol_length = 4 + randi() % 4  # 4-7 waypoints
	
	# Create a simple rectangular or line patrol
	if randf() < 0.5:
		# Rectangular patrol
		var width = 3 + randi() % 5
		var height = 3 + randi() % 5
		path.append(Vector2i(start_x, start_y))
		path.append(Vector2i(start_x + width, start_y))
		path.append(Vector2i(start_x + width, start_y + height))
		path.append(Vector2i(start_x, start_y + height))
	else:
		# Line patrol back and forth
		var dx = (randi() % 2) * 2 - 1  # -1 or 1
		var dy = (randi() % 2) * 2 - 1
		var length = 5 + randi() % 8
		path.append(Vector2i(start_x, start_y))
		path.append(Vector2i(start_x + dx * length, start_y + dy * length))
	
	# Clamp path to grid
	for i in range(path.size()):
		path[i].x = clamp(path[i].x, 0, GRID_WIDTH - 1)
		path[i].y = clamp(path[i].y, 0, GRID_HEIGHT - 1)
	
	return {
		"pos": path[0],
		"path": path,
		"path_index": 0,
		"visual_pos": tile_to_world(path[0]),
		"from_pos": path[0],
		"to_pos": path[0],
		"move_elapsed": 0.0,
		"move_duration": 0.0
	}

func tile_to_world(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * CELL_SIZE + CELL_SIZE / 2, pos.y * CELL_SIZE + CELL_SIZE / 2)

func _process(delta):
	update_player_animation(delta)
	update_enemy_movement(delta)
	queue_redraw()

func update_player_animation(delta):
	if player_is_moving:
		player_move_elapsed += delta
		var t = min(player_move_elapsed / PLAYER_JUMP_DURATION, 1.0)
		var eased = t * t * (3.0 - 2.0 * t)
		var base_pos = player_move_start.lerp(player_move_end, eased)
		var jump_offset = sin(t * PI) * PLAYER_JUMP_HEIGHT
		player_visual_pos = base_pos + Vector2(0, -jump_offset)
		if t >= 1.0:
			player_is_moving = false
			player_visual_pos = player_move_end
	else:
		player_visual_pos = tile_to_world(player_pos)

func update_enemy_movement(delta):
	if enemies_moving:
		var all_done = true
		for enemy in enemies:
			enemy.move_elapsed += delta
			var t = min(enemy.move_elapsed / enemy.move_duration, 1.0)
			var from_world = tile_to_world(enemy.from_pos)
			var to_world = tile_to_world(enemy.to_pos)
			enemy.visual_pos = from_world.lerp(to_world, t)
			if t < 1.0:
				all_done = false
		if all_done:
			for enemy in enemies:
				enemy.pos = enemy.to_pos
				enemy.visual_pos = tile_to_world(enemy.pos)
			enemies_moving = false
			if check_enemy_collision():
				player_death()
			else:
				start_enemy_step()
	else:
		start_enemy_step()

func start_enemy_step():
	if enemies.is_empty():
		return
	enemies_moving = true
	for enemy in enemies:
		enemy.from_pos = enemy.pos
		enemy.path_index = (enemy.path_index + 1) % enemy.path.size()
		enemy.to_pos = enemy.path[enemy.path_index]
		enemy.move_elapsed = 0.0
		var cell_distance = Vector2(enemy.from_pos).distance_to(Vector2(enemy.to_pos))
		enemy.move_duration = max(cell_distance / ENEMY_SPEED_CELLS_PER_SEC, 0.01)

func spawn_food():
	var attempts = 0
	while attempts < 100:
		var x = randi() % GRID_WIDTH
		var y = randi() % GRID_HEIGHT
		var pos = Vector2i(x, y)
		
		# Don't spawn on player or existing food
		if pos != player_pos and not food_positions.has(pos):
			food_positions.append(pos)
			return
		attempts += 1

func check_level_complete() -> bool:
	if current_level == 1:
		return food_collected >= LEVEL_1_FOOD_GOAL
	else:  # Level 2
		return food_collected >= LEVEL_2_FOOD_GOAL and fat >= LEVEL_2_FAT_GOAL

func complete_level():
	if current_level == 1:
		show_level_complete_message("Level 1 Complete!\nClick to continue to Level 2")
	else:
		show_level_complete_message("You've won! You've eaten enough food to store it as fat.\n\nDid you notice any advantage to having fat in addition to glucose?\nClick to restart")

func show_level_complete_message(message: String):
	level_complete_panel.get_node("Label").text = message
	level_complete_panel.show()

func _on_level_complete_clicked():
	level_complete_panel.hide()
	if current_level == 1:
		start_level(2)
	else:
		start_level(1)

func _on_level_complete_close_pressed():
	_on_level_complete_clicked()

func _on_tutorial_close_pressed():
	tutorial_active = false
	tutorial_panel.hide()
	tutorial_shown = true
	set_process(true)
	start_level(1)

# ============================================
# INPUT HANDLING
# ============================================

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if tutorial_active:
			return
		if player_is_moving:
			return
		if level_complete_panel.visible:
			_on_level_complete_clicked()
			return
		
		# Convert screen position to grid position
		var mouse_world_pos = get_global_mouse_position()
		var grid_x = int(mouse_world_pos.x / CELL_SIZE)
		var grid_y = int(mouse_world_pos.y / CELL_SIZE)
		var target_pos = Vector2i(grid_x, grid_y)
		
		# Check if click is within grid
		if grid_x >= 0 and grid_x < GRID_WIDTH and grid_y >= 0 and grid_y < GRID_HEIGHT:
			try_move_to(target_pos)

func try_move_to(target_pos: Vector2i):
	if glucose <= 0:
		player_death()
		return  # Can't move without glucose
	
	# Calculate path and distance
	var dx = target_pos.x - player_pos.x
	var dy = target_pos.y - player_pos.y
	var distance = abs(dx) + abs(dy)  # Manhattan distance
	
	if distance == 0:
		return  # Already there
	
	# Cap movement to max_movement
	var actual_distance = min(distance, max_movement)
	if actual_distance <= 0:
		return
	
	# Calculate direction (normalized)
	var dir_x = sign(dx)
	var dir_y = sign(dy)

	var start_pos = player_pos
	
	# Spend glucose once per move action
	glucose -= 1

	# Move step by step
	var moved = 0
	while moved < actual_distance:
		var next_pos = player_pos
		
		# Alternate between x and y movement to create diagonal-ish movement
		if abs(player_pos.x - target_pos.x) > abs(player_pos.y - target_pos.y):
			next_pos.x += dir_x
		elif abs(player_pos.y - target_pos.y) > 0:
			next_pos.y += dir_y
		else:
			next_pos.x += dir_x
		
		# Clamp to grid
		next_pos.x = clamp(next_pos.x, 0, GRID_WIDTH - 1)
		next_pos.y = clamp(next_pos.y, 0, GRID_HEIGHT - 1)
		
		# Move player
		player_pos = next_pos
		moved += 1
		
		# Check for food collection
		if food_positions.has(player_pos):
			collect_food()
		
		# Check for enemy collision
		if check_enemy_collision():
			player_death()
			return
		
	# Auto-convert fat after paying move cost
	check_auto_fat_conversion()
	start_player_jump(start_pos, player_pos)
	
	play_sound(sound_click)
	update_ui()
	
	# Check level complete
	if check_level_complete():
		complete_level()
	
	queue_redraw()

# ============================================
# RESOURCE MANAGEMENT
# ============================================

func collect_food():
	food_positions.erase(player_pos)
	
	# Add glucose
	var new_glucose = glucose + FOOD_GLUCOSE_VALUE
	
	# Check for fat conversion when eating would overflow glucose.
	if current_level == 2 and new_glucose > MAX_GLUCOSE and fat < MAX_FAT:
		# Eating puts us over max, convert excess to fat.
		glucose = clamp(new_glucose - 2, 0, MAX_GLUCOSE)  # Lose 2 glucose
		fat = min(fat + 1, MAX_FAT)  # Gain 1 fat
	else:
		glucose = clamp(new_glucose, 0, MAX_GLUCOSE)
	
	food_collected += 1
	
	# Spawn new food
	spawn_food()
	
	update_max_movement()
	play_sound(sound_eat)
	update_ui()

func check_auto_fat_conversion():
	if glucose == 1 and fat > 0:
		# Auto-convert 1 fat to 5 glucose
		fat -= 1
		glucose = min(glucose + 5, MAX_GLUCOSE)
		update_max_movement()
		play_sound(sound_convert)
		update_ui()

func update_max_movement():
	if current_level == 1:
		max_movement = 5
	else:
		# Level 2: fat slows you down
		if fat <= 1:
			max_movement = 5
		elif fat <= 3:
			max_movement = 4
		else:  # fat 4-5
			max_movement = 3

func start_player_jump(from_pos: Vector2i, to_pos: Vector2i):
	player_move_start = tile_to_world(from_pos)
	player_move_end = tile_to_world(to_pos)
	player_move_elapsed = 0.0
	player_is_moving = true
	player_visual_pos = player_move_start

# ============================================
# ENEMY MANAGEMENT
# ============================================

func check_enemy_collision() -> bool:
	for enemy in enemies:
		if enemy.pos == player_pos:
			return true
	return false

func player_death():
	play_sound(sound_death)
	await get_tree().create_timer(0.5).timeout
	start_level(current_level)  # Restart current level

# ============================================
# UI
# ============================================

func update_ui():
	var goal_text = ""
	if current_level == 1:
		goal_text = "Goal: %d/%d food" % [food_collected, LEVEL_1_FOOD_GOAL]
	else:
		goal_text = "Goal: %d/%d food, %d/%d fat" % [food_collected, LEVEL_2_FOOD_GOAL, fat, LEVEL_2_FAT_GOAL]
	
	ui_label.text = "Level %d | Glucose: %d | Fat: %d | Move: %d | %s" % [
		current_level, glucose, fat, max_movement, goal_text
	]

# ============================================
# RENDERING
# ============================================

func _draw():
	# Draw grid background
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var rect = Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			var color = Color(0.1, 0.1, 0.12, GRID_ALPHA) if (x + y) % 2 == 0 else Color(0.08, 0.08, 0.1, GRID_ALPHA)
			draw_rect(rect, color)
	
	# Draw food
	for food_pos in food_positions:
		var center = Vector2(food_pos.x * CELL_SIZE + CELL_SIZE / 2, food_pos.y * CELL_SIZE + CELL_SIZE / 2)
		draw_circle(center + Vector2(2, 3), CELL_SIZE * 0.3, Color(0, 0, 0, 0.35))
		draw_circle(center, CELL_SIZE * 0.3, Color(0.3, 0.8, 0.3))
	
	# Draw enemies (spiders - red circles with legs)
	for enemy in enemies:
		var center = enemy.visual_pos
		draw_circle(center + Vector2(2, 3), CELL_SIZE * 0.35, Color(0, 0, 0, 0.4))
		draw_circle(center, CELL_SIZE * 0.35, Color(0.8, 0.1, 0.1))
		# Draw simple "legs"
		for i in range(4):
			var angle = i * PI / 2
			var leg_end = center + Vector2(cos(angle), sin(angle)) * CELL_SIZE * 0.4
			draw_line(center, leg_end, Color(0.6, 0.05, 0.05), 2)
	
	# Draw player (bug - blue/yellow)
	var player_center = player_visual_pos
	draw_circle(player_center + Vector2(2, 3), CELL_SIZE * 0.4, Color(0, 0, 0, 0.4))
	draw_circle(player_center, CELL_SIZE * 0.4, Color(0.2, 0.5, 0.9))
	# Antennae
	draw_line(player_center, player_center + Vector2(-CELL_SIZE * 0.2, -CELL_SIZE * 0.4), Color(0.8, 0.8, 0.3), 2)
	draw_line(player_center, player_center + Vector2(CELL_SIZE * 0.2, -CELL_SIZE * 0.4), Color(0.8, 0.8, 0.3), 2)
