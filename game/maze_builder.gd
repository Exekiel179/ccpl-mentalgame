## MazeBuilder — random maze via iterative DFS. 15x9 rooms, 40px cells.
extends Node2D

const ROOMS_COLS: int  = 23
const ROOMS_ROWS: int  = 15
const CELL: float      = 34.0
const OFFSET_X: float  = 10.0
const OFFSET_Y: float  = 0.0

const WALL_COLOR: Color  = Color(0.08, 0.10, 0.25)
const WALL_EDGE: Color   = Color(0.15, 0.20, 0.40)
const FLOOR_COLOR: Color = Color(0.05, 0.07, 0.16)
const FLOOR_ALT: Color   = Color(0.06, 0.09, 0.18)
const EXIT_COLOR: Color  = Color(0.10, 0.75, 0.35)
const START_COLOR: Color = Color(0.15, 0.50, 0.90)

## Start room (0,0) -> display cell (1,1)
static func get_start_world() -> Vector2:
	return Vector2(OFFSET_X + 1.0 * CELL + CELL * 0.5,
				   OFFSET_Y + 1.0 * CELL + CELL * 0.5)

## Exit room (ROOMS_ROWS-1, ROOMS_COLS-1)
static func get_exit_world() -> Vector2:
	var dc: float = float(2 * (ROOMS_COLS - 1) + 1)
	var dr: float = float(2 * (ROOMS_ROWS - 1) + 1)
	return Vector2(OFFSET_X + dc * CELL + CELL * 0.5,
				   OFFSET_Y + dr * CELL + CELL * 0.5)

var _grid: Array = []

func _ready() -> void:
	_generate()
	_build()

func get_pickup_positions(count: int) -> Array:
	var floor_cells: Array = []
	var exit_dc: int = 2 * (ROOMS_COLS - 1) + 1
	var exit_dr: int = 2 * (ROOMS_ROWS - 1) + 1
	for r in range(_grid.size()):
		var grid_row: Array = _grid[r]
		for c in range(grid_row.size()):
			if int(grid_row[c]) == 0 and not (r == 1 and c == 1) and not (r == exit_dr and c == exit_dc):
				floor_cells.append(Vector2(OFFSET_X + float(c) * CELL + CELL * 0.5, OFFSET_Y + float(r) * CELL + CELL * 0.5))
	floor_cells.shuffle()
	var result: Array = []
	for i in mini(count, floor_cells.size()):
		result.append(floor_cells[i])
	return result

func _generate() -> void:
	var h: int = 2 * ROOMS_ROWS + 1
	var w: int = 2 * ROOMS_COLS + 1
	_grid = []
	for r in range(h):
		var row_arr: Array = []
		for c in range(w):
			row_arr.append(1)
		_grid.append(row_arr)
	for r in range(ROOMS_ROWS):
		for c in range(ROOMS_COLS):
			_grid[2 * r + 1][2 * c + 1] = 0
	var visited: Array = []
	for r in range(ROOMS_ROWS):
		var row_arr: Array = []
		for c in range(ROOMS_COLS):
			row_arr.append(false)
		visited.append(row_arr)
	_dfs(visited)

func _dfs(visited: Array) -> void:
	var stack: Array = [[0, 0]]
	visited[0][0] = true
	while stack.size() > 0:
		var cur: Array = stack.back()
		var row: int = cur[0]
		var col: int = cur[1]
		var dirs: Array = [[0, 1], [0, -1], [1, 0], [-1, 0]]
		dirs.shuffle()
		var moved: bool = false
		for d in dirs:
			var nr: int = row + int(d[0])
			var nc: int = col + int(d[1])
			if nr >= 0 and nr < ROOMS_ROWS and nc >= 0 and nc < ROOMS_COLS:
				if not visited[nr][nc]:
					_grid[2 * row + 1 + int(d[0])][2 * col + 1 + int(d[1])] = 0
					visited[nr][nc] = true
					stack.append([nr, nc])
					moved = true
					break
		if not moved:
			stack.pop_back()

func _build() -> void:
	var exit_dc: int = 2 * (ROOMS_COLS - 1) + 1
	var exit_dr: int = 2 * (ROOMS_ROWS - 1) + 1
	for r in range(_grid.size()):
		var grid_row: Array = _grid[r]
		for c in range(grid_row.size()):
			var wx: float = OFFSET_X + float(c) * CELL
			var wy: float = OFFSET_Y + float(r) * CELL
			var cell_val: int = int(grid_row[c])
			if cell_val == 1:
				_make_wall(wx, wy)
			else:
				_make_floor(wx, wy, r, c, exit_dc, exit_dr)

func _make_wall(wx: float, wy: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(wx + CELL * 0.5, wy + CELL * 0.5)
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(CELL - 1.0, CELL - 1.0)
	cs.shape = rs
	body.add_child(cs)
	# Outer edge highlight
	var edge := ColorRect.new()
	edge.size = Vector2(CELL, CELL)
	edge.position = Vector2(-CELL * 0.5, -CELL * 0.5)
	edge.color = WALL_EDGE
	body.add_child(edge)
	# Inner wall
	var vis := ColorRect.new()
	vis.size = Vector2(CELL - 3.0, CELL - 3.0)
	vis.position = Vector2(-CELL * 0.5 + 1.5, -CELL * 0.5 + 1.5)
	vis.color = WALL_COLOR
	body.add_child(vis)
	add_child(body)

func _make_floor(wx: float, wy: float, r: int, c: int,
				 exit_dc: int, exit_dr: int) -> void:
	var rect := ColorRect.new()
	rect.position = Vector2(wx, wy)
	rect.size = Vector2(CELL, CELL)
	if r == 1 and c == 1:
		rect.color = START_COLOR.darkened(0.4)
	elif r == exit_dr and c == exit_dc:
		rect.color = EXIT_COLOR.darkened(0.3)
	else:
		if (r + c) % 2 == 0:
			rect.color = FLOOR_COLOR
		else:
			rect.color = FLOOR_ALT
	add_child(rect)
