extends Node2D

export (float) var Delay = 0.05
var Empty_Base:bool = false
var Graph:Dictionary ={}
var Start_Cell:Vector2
var End_Cell:Vector2
var Mazes_Built:bool = false
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	gen_base()
	Start_Cell= random_cell()
	End_Cell = random_cell()
	
	#redoes it until they are different
	while Start_Cell == End_Cell:
		End_Cell == random_cell()

func horiz():
	#returns true or false based on the biases
	var total = Global.Vert_Bias+Global.Horiz_Bias
	var rand = randf()*total
	return Global.Horiz_Bias >= rand

func gen_base():
	get_node("Maze").scale = (Vector2(1,1)/Global.Maze_Size.y)*30
	Global.Scale = get_node("Maze").scale
	#generates a basic maze, full of either empties or walls is
	#also fills Graph, a dictionary of dictionaries
	for x in Global.Maze_Size.x:
		for y in Global.Maze_Size.y:
			#if true, there is a path, if false there is not
			Graph[Vector2(x,y)] = {
				Vector2.UP : Empty_Base,
				Vector2.DOWN : Empty_Base,
				Vector2.LEFT : Empty_Base,
				Vector2.RIGHT : Empty_Base
			}
			get_node("Maze").update_tile(Vector2(x,y),Graph[Vector2(x,y)])

func _input(event):
	if event.is_action_pressed("Go"):
		if not Mazes_Built:
			if Global.Building_Algo == Global.BUILDING.Kruskal:
				gen_maze_kruskal()
			elif Global.Building_Algo == Global.BUILDING.Depth_First:
				gen_maze_depth_first()
			elif Global.Building_Algo == Global.BUILDING.Aldous_Broder:
				gen_maze_aldous_broder()
			elif Global.Building_Algo == Global.BUILDING.Eller:
				gen_maze_eller()
			elif Global.Building_Algo == Global.BUILDING.Prim:
				gen_maze_prim()
		else:
			print("here2")
			get_node("Maze").place_start_n_end(Start_Cell,End_Cell)
			get_node("Maze2").place_start_n_end(Start_Cell,End_Cell)
			get_node("Maze/Traverser").activate(Graph,Start_Cell,End_Cell,Global.Traversal_Algo_1)
			get_node("Maze2/Traverser").activate(Graph,Start_Cell,End_Cell,Global.Traversal_Algo_2)

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
	for x in Global.Maze_Size.x:
		for y in Global.Maze_Size.y:
			forest.add_set(Vector2(x,y))
	return forest

func make_wall_list():
	#returns an array containing
	# a horizontal wall array and a vertical wall array
	
	# each wall is represented as a wall object
	
	var horiz_walls = []
	var vert_walls = []
	for x in Global.Maze_Size.x-1:
		for y in Global.Maze_Size.y-1:
			
			#the bottom walls
			var wall1 = Wall.new(Vector2(x,y),false)
			vert_walls.append(wall1)
			
			#the right walls
			var wall2 = Wall.new(Vector2(x,y),true)
			horiz_walls.append(wall2)
		
		#the outlying bottom and walls
		var wall = Wall.new(Vector2(x,Global.Maze_Size.y-1),true)
		horiz_walls.append(wall)
	for y in Global.Maze_Size.y-1:
		var wall = Wall.new(Vector2(Global.Maze_Size.x-1,y),false)
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
				get_node("Maze").update_tile(cell1,Graph[cell1])
				Graph[cell2][Vector2.LEFT] = true
				get_node("Maze").update_tile(cell2,Graph[cell2])
			else:
				Graph[cell1][Vector2.DOWN] = true
				get_node("Maze").update_tile(cell1,Graph[cell1])
				Graph[cell2][Vector2.UP] = true
				get_node("Maze").update_tile(cell2,Graph[cell2])
			
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

func calc_dir(poss_dir):
	#calculates which direction the next will be, based on the bias
	var total=0
	var dirs :Dictionary={}
	for i in poss_dir:
		if i == Vector2.LEFT or i == Vector2.RIGHT:
			total += Global.Horiz_Bias
			dirs[total] = i
		if i == Vector2.UP or i == Vector2.DOWN:
			total += Global.Vert_Bias
			dirs[total] = i
	var rand = randf()*total
	var keys = dirs.keys()
	keys.sort()
	for i in keys:
		if rand < i:
			return dirs[i]
	return dirs

func poss_dir(cell):
	#returns all possible directions of the cell
	var poss_dir :=[]
	var directions = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
	for i in directions:
		var new = i + cell
		#if not within maze, skip
		if new.x <0 or new.x >= Global.Maze_Size.x or new.y<0 or new.y >= Global.Maze_Size.y:continue
		poss_dir.append(i)
	return poss_dir

func fill_dict_false_all_cells(Size:Vector2):
	#returns dictionary filled with falses to all cells
	var dict:={}
	for x in Size.x:
		for y in Size.y:
			dict[Vector2(x,y)] = false
	return dict

func gen_maze_depth_first():
	randomize()
	var visited :Dictionary= fill_dict_false_all_cells(Global.Maze_Size)
	
	#generates the stack depth first
	var directions = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
	
	var stack := []
	var current := Vector2(randi()%int(Global.Maze_Size.x),randi()%int(Global.Maze_Size.y))
	stack.push_back(current)
	visited[current] = true
	
	while not stack.empty():
		get_node("Maze").update_tile(current,Graph[current])
		#finds unvisited neigbours
		var temp_directions = directions
		temp_directions.shuffle()
		var dir:=Vector2.ZERO
		var poss_dir := []
		for i in directions:
			var new = i + current
			#if not within maze, skip
			if new.x <0 or new.x >= Global.Maze_Size.x or new.y<0 or new.y >= Global.Maze_Size.y:continue
			#if visited, skip
			if visited[new]: continue
			poss_dir.append(i)
		
		#if a direction is found, create a path between the two cells and mark
		# the new one as current and visited and adds it to the stack
		if not poss_dir.empty():
			dir = calc_dir(poss_dir)
			Graph[current][dir] = true
			get_node("Maze").update_tile(current,Graph[current])
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

func gen_maze_aldous_broder():
	var directions = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]
	
	var unvisited:=[]
	for x in Global.Maze_Size.x:
		for y in Global.Maze_Size.y:
			unvisited.append(Vector2(x,y))
	
	var current:Vector2 = random_cell()
	unvisited.erase(current)
	
	while not unvisited.empty():
		var poss_dir = poss_dir(current)
		var dir = poss_dir[randi()%poss_dir.size()]
		if current+dir in unvisited:
			Graph[current][dir] = true
			Graph[current+dir][dir*-1] = true
			unvisited.erase(current+dir)
			print(unvisited.size())
		current = current+dir
		get_node("Maze").update_tile(current-dir,Graph[current-dir])
		if Delay:
			var t = Timer.new()
			t.set_wait_time(Delay)
			t.set_one_shot(true)
			self.add_child(t)
			t.start()
			yield(t, "timeout")
			t.queue_free()
	get_node("Maze").update_tile(current,Graph[current])
	finished_maze()

func gen_maze_eller():
	#really enjoyed programming this one
	var maze = get_node("Maze")
	var forest :Disjoint_Set_Forest= Disjoint_Set_Forest.new()
	for y in Global.Maze_Size.y-1:
		for x in Global.Maze_Size.x:
			#adds all in row to forest as unique set, won't get added if it already exists
			forest.add_set(Vector2(x,y))
		
		for x in Global.Maze_Size.x-1:
			#randomly connects adjacent cells if they do not exist in the same sets
			if forest.find(Vector2(x,y))!=forest.find(Vector2(x+1,y)) and randi()%2==0:
				forest.union(Vector2(x,y),Vector2(x+1,y))
				
				Graph[Vector2(x,y)][Vector2.RIGHT] = true
				Graph[Vector2(x+1,y)][Vector2.LEFT] = true
				
				maze.update_tile(Vector2(x,y),Graph[Vector2(x,y)])
				maze.update_tile(Vector2(x+1,y),Graph[Vector2(x+1,y)])
				if Delay:
					var t = Timer.new()
					t.set_wait_time(Delay)
					t.set_one_shot(true)
					self.add_child(t)
					t.start()
					yield(t, "timeout")
					t.queue_free()
		
		
		#this section randomly creates vertical connections downward to the next row. 
		#It makes sure each disjoint set has at least one connection downwards
		
		var row = range(Global.Maze_Size.x)
		var parents:=[]
		while not row.empty():
			var x = row[randi()%row.size()]
			row.erase(x)
			var parent = forest.find(Vector2(x,y))
			#for every new set it finds(sets that arent in parents) it always gives that cell a downward connection 
			if not parent in parents:
				parents.append(parent)
				forest.add_set(Vector2(x,y+1))
				forest.union(Vector2(x,y),Vector2(x,y+1))
				
				Graph[Vector2(x,y)][Vector2.DOWN] = true
				Graph[Vector2(x,y+1)][Vector2.UP] = true
				
				maze.update_tile(Vector2(x,y),Graph[Vector2(x,y)])
				maze.update_tile(Vector2(x,y+1),Graph[Vector2(x,y+1)])
			elif randi()%4==0:
				forest.add_set(Vector2(x,y+1))
				forest.union(Vector2(x,y),Vector2(x,y+1))
				
				Graph[Vector2(x,y)][Vector2.DOWN] = true
				Graph[Vector2(x,y+1)][Vector2.UP] = true
				
				maze.update_tile(Vector2(x,y),Graph[Vector2(x,y)])
				maze.update_tile(Vector2(x,y+1),Graph[Vector2(x,y+1)])
			
			if Delay:
					var t = Timer.new()
					t.set_wait_time(Delay)
					t.set_one_shot(true)
					self.add_child(t)
					t.start()
					yield(t, "timeout")
					t.queue_free()
		
	#for the last row
	var y = Global.Maze_Size.y-1
	forest.add_set(Vector2(0,y))
	for x in Global.Maze_Size.x-1:
		forest.add_set(Vector2(x+1,y))
		# connects adjacent cells if they do not exist in the same sets
		if forest.find(Vector2(x,y))!=forest.find(Vector2(x+1,y)):
			forest.union(Vector2(x,y),Vector2(x+1,y))
			
			Graph[Vector2(x,y)][Vector2.RIGHT] = true
			Graph[Vector2(x+1,y)][Vector2.LEFT] = true
			
			maze.update_tile(Vector2(x,y),Graph[Vector2(x,y)])
			maze.update_tile(Vector2(x+1,y),Graph[Vector2(x+1,y)])
			if Delay:
					var t = Timer.new()
					t.set_wait_time(Delay)
					t.set_one_shot(true)
					self.add_child(t)
					t.start()
					yield(t, "timeout")
					t.queue_free()
	finished_maze()

func disjoint(cell:Vector2,poss_dir:Array):
	#checks if a cell is not connected to any others
	for dir in poss_dir:
		if Graph[cell][dir]:
			return false
	return true


func gen_maze_prim():
	var maze = get_node("Maze")
	var worth_a_visit := {}
	var current:Vector2 = random_cell()
	var poss_dir = poss_dir(current)
	for dir in poss_dir:
		worth_a_visit[current+dir] = dir*-1
	while not worth_a_visit.keys().empty():
		current = worth_a_visit.keys()[randi()%worth_a_visit.size()]
		var dir_to_maze = worth_a_visit[current]
		worth_a_visit.erase(current)
		
		Graph[current][dir_to_maze] = true
		Graph[current+dir_to_maze][dir_to_maze*-1]=true
		
		maze.update_tile(current,Graph[current])
		maze.update_tile(current+dir_to_maze,Graph[current+dir_to_maze])
		
		if Delay:
			var t = Timer.new()
			t.set_wait_time(Delay)
			t.set_one_shot(true)
			self.add_child(t)
			t.start()
			yield(t, "timeout")
			t.queue_free()
		
		
		poss_dir = poss_dir(current)
		for dir in poss_dir:
			if disjoint(current+dir,poss_dir(current+dir)):
				worth_a_visit[current+dir] = dir*-1
	finished_maze()



func finished_maze():
	var maze2 = get_node("Maze2")
	maze2.scale = (Vector2(1,1)/Global.Maze_Size.y)*30
	maze2.modulate = Color.bisque
	maze2.get_node("CurrentTile").visible = false
	get_node("Maze/CurrentTile").visible = false
	maze2.visible = true
	maze2.position= Vector2((Global.Maze_Size.x/2)*32*maze2.scale.x*2,0)
	for x in Global.Maze_Size.x:
		for y in Global.Maze_Size.y:
			maze2.update_tile(Vector2(x,y),Graph[Vector2(x,y)])
	Mazes_Built = true



func random_cell():
	return Vector2(randi()%int(Global.Maze_Size.x),randi()%int(Global.Maze_Size.y))
