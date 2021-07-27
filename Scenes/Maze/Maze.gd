extends TileMap

var Maze_Made:bool = false
var Making_Maze:bool = false
export (Vector2) var Size = Vector2(8,8)
export (float) var Delay = 0.01
export(float) var  Vert_bias =1
export (float) var Horiz_bias =1
var Empty:bool = true
var Graph:={}
var Indicator
var Traversal_Algo:String = "dijkstra"
var Generation_Algo:String

func _ready():
	Empty = false
	randomize()
	# adds the current tile indicator
	var indicator_scene = load("res://Scenes/Maze/CurrentTile.tscn")
	Indicator = indicator_scene.instance()
	add_child(Indicator)
	gen_base()

func rand_cell():
	return Vector2(randi()%int(Size.x),randi()%int(Size.y))

func horiz():
	#returns true or false based on the biases
	var total = Vert_bias+Horiz_bias
	var rand = randf()*total
	return Horiz_bias >= rand

func gen_base():
	scale = (Vector2(1,1)/Size.y)*30
	#generates a basic maze, full of either empties or walls is
	#also fills Graph, a dictionary of dictionaries
	for x in Size.x:
		for y in Size.y:
			var idx = 0
			if Empty: idx = 15
			set_cellv(Vector2(x,y),idx)
			
			#if true, there is a path, if false there is not
			Graph[Vector2(x,y)] = {
				Vector2.UP : Empty,
				Vector2.DOWN : Empty,
				Vector2.LEFT : Empty,
				Vector2.RIGHT : Empty
			}
			update_tile(Vector2(x,y))

func update_tile(tile:Vector2):
	#updates how a specific tile looks
	Indicator.position = map_to_world(tile)+ Vector2(16,16)
	var idx = 0
	if Graph[tile][Vector2.UP]:idx+=1
	if Graph[tile][Vector2.RIGHT]:idx+=2
	if Graph[tile][Vector2.DOWN]:idx+=4
	if Graph[tile][Vector2.LEFT]:idx+=8
	idx = 15-idx
	set_cellv(tile,idx)

func finished_maze():
	#creates the players tile map
	Maze_Made = true
	var map2 :TileMap= get_node("PlayerTileMap")
	for x in Size.x:
		for y in Size.y:
			map2.set_cell(x,y,get_cell(x,y))
	map2.activate(Size.y,Graph)


func _unhandled_input(event):
	if event.is_action_released("Go"):
		#when enter pressed
		#if this is the first time, starts making the maze
		#if the maze is still being made it removes all delay
		# if the maze is finished, starts the player and traverser
		if not Maze_Made:
			if Making_Maze:
				Delay = 0
				return
			Making_Maze = true
			gen_maze_kruskal()
		else:
			var start = rand_cell()
			var end = rand_cell()
			get_node("Start").visible = true
			get_node("End").visible = true
			get_node("PlayerTileMap/Start2").visible = true
			get_node("PlayerTileMap/End2").visible = true
			get_node("PlayerTileMap/Player").position = map_to_world(start)+cell_size/2
			get_node("Start").position = map_to_world(start)+cell_size/2
			get_node("End").position = map_to_world(end)+cell_size/2
			get_node("PlayerTileMap/Start2").position = map_to_world(start)+cell_size/2
			get_node("PlayerTileMap/End2").position = map_to_world(end)+cell_size/2
			get_node("PlayerTileMap/Player").activate(Size,Graph,start,end)
			get_node("Traverser").activate(Graph,start,end,Traversal_Algo)



##kruskal from here
#uses a basic array instead of a set
class Wall:
	var coord: Vector2
	#wether the wall is to the right of the cell or bottom
	var horiz: bool
	
	func _init(coord,horiz):
		self.coord = coord
		self.horiz = horiz

class Disjoint_Set_Forest:
	#Class containing a dictionary implementation of a disjoint set forest
	#(I know it's not quite the same, but it works well)
	var elements :Dictionary= {}
	
	func add_set(x):
		#adds an element and sets self as parent
		if not elements.has(x):
			elements[x] = x
	
	func find(x):
		#returns root of x, also implements path compression 
		if elements.has(x):
			if elements[x] == x:
				return x
			else:
				elements[x] = find(elements[x])
				return elements[x]
	
	func union(x,y):
		#combines two sets
		#sets parent of x as parent of y
		#or vice versa, is random right now
		x = find(x)
		y = find(y)
		if x==y:
			return false
		else:
			if randi()%2:elements[y] = x
			else: elements[x] = y
			return true



func make_cell_sets():
	#makes an array of arrays, one array for each cell
	var forest = Disjoint_Set_Forest.new()
	for x in Size.x:
		for y in Size.y:
			forest.add_set(Vector2(x,y))
	return forest

func make_wall_list():
	#returns an array containing
	# a horizontal wall array and a vertical wall array
	
	# each wall is represented as a wall object
	
	var horiz_walls = []
	var vert_walls = []
	for x in Size.x-1:
		for y in Size.y-1:
			
			#the bottom walls
			var wall1 = Wall.new(Vector2(x,y),false)
			vert_walls.append(wall1)
			
			#the right walls
			var wall2 = Wall.new(Vector2(x,y),true)
			horiz_walls.append(wall2)
		
		#the outlying bottom and walls
		var wall = Wall.new(Vector2(x,Size.y-1),true)
		horiz_walls.append(wall)
	for y in Size.y-1:
		var wall = Wall.new(Vector2(Size.x-1,y),false)
		vert_walls.append(wall)
	return [horiz_walls,vert_walls]


func gen_maze_kruskal():
	var cells = make_cell_sets()
	var walls = make_wall_list()
	walls.shuffle()
	
	#generates maze
	#cycles through every wall in the two arrays
	while not (walls[0].empty() or walls[1].empty()):
		
		#this part chooses the next wall, then removes it from the correct array
		var wall
		if horiz() and (not walls[0].empty()):
			var idx = randi()%walls[0].size()
			wall = walls[0][idx]
			walls[0].remove(idx)
		else:
			var idx = randi()%walls[1].size()
			wall = walls[1][idx]
			walls[1].remove(idx)
		
		#calculates which two cells the wall connects
		var cell1 = wall.coord
		var cell2 = wall.coord + Vector2.DOWN
		if wall.horiz:
			cell2 = wall.coord + Vector2.RIGHT
		
		#if the cells can union, updates them
		if cells.union(cell1,cell2):
			if wall.horiz:
				Graph[cell1][Vector2.RIGHT] = true
				update_tile(cell1)
				Graph[cell2][Vector2.LEFT] = true
				update_tile(cell2)
			else:
				Graph[cell1][Vector2.DOWN] = true
				update_tile(cell1)
				Graph[cell2][Vector2.UP] = true
				update_tile(cell2)
			
		#delay
		if Delay:
			var t = Timer.new()
			t.set_wait_time(Delay)
			t.set_one_shot(true)
			self.add_child(t)
			t.start()
			yield(t, "timeout")
			t.queue_free()
	finished_maze()



## Depth First From Here
func calc_dir(poss_dir):
	#calculates which direction the next will be, based on the bias
	var total=0
	var dirs :Dictionary={}
	for i in poss_dir:
		if i == Vector2.LEFT or i == Vector2.RIGHT:
			total += Horiz_bias
			dirs[total] = i
		if i == Vector2.UP or i == Vector2.DOWN:
			total += Vert_bias
			dirs[total] = i
	var rand = randf()*total
	var keys = dirs.keys()
	keys.sort()
	for i in keys:
		if rand < i:
			return dirs[i]
	return dirs

func fill_visited():
	#returns dictionary filled with falses to all cells
	var dict:={}
	for x in Size.x:
		for y in Size.y:
			dict[Vector2(x,y)] = false
	return dict

func gen_maze_depth_first():
	randomize()
	var visited :Dictionary= fill_visited()
	
	#generates the stack depth first
	var directions = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
	
	var stack := []
	var current := Vector2(randi()%int(Size.x),randi()%int(Size.y))
	stack.push_back(current)
	visited[current] = true
	
	while not stack.empty():
		update_tile(current)
		#finds unvisited neigbours
		var temp_directions = directions
		temp_directions.shuffle()
		var dir:=Vector2.ZERO
		var poss_dir := []
		for i in directions:
			var new = i + current
			#if not within maze, skip
			if new.x <0 or new.x >= Size.x or new.y<0 or new.y >= Size.y:continue
			#if visited, skip
			if visited[new]: continue
			poss_dir.append(i)
		
		#if a direction is found, create a path between the two cells and mark
		# the new one as current and visited and adds it to the stack
		if not poss_dir.empty():
			dir = calc_dir(poss_dir)
			Graph[current][dir] = true
			update_tile(current)
			current+=dir
			Graph[current][dir*-1] = true
			visited[current] = true
			stack.push_back(current)
		else:
			#otherwise, pops the last item of the stack
			current = stack.pop_back()
		#waits
		if Delay:
			var t = Timer.new()
			t.set_wait_time(Delay)
			t.set_one_shot(true)
			self.add_child(t)
			t.start()
			yield(t, "timeout")
			t.queue_free()
	finished_maze()

