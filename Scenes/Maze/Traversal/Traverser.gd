extends Node2D
export(float) var Delay = 0.05
var Shortest_Paths:={}
var Start
var End
var Algo
var Dirs = [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]

func _ready():
	get_node("Sprite/Particles2D").emitting = false
	visible = false
	

func is_shortest_path(algo):
	return algo == Global.TRAVERSAL.A_Star or algo == Global.TRAVERSAL.Best_First or algo == Global.TRAVERSAL.Dijkstra

func find_lowest_best_first(distances:Dictionary, unvisited:Array):
	var lowest = INF
	var cell
	for x in unvisited:
		var val = x.distance_to(End)
		if val<lowest and distances[x]!= INF:
			lowest = val
			cell = x
	return cell

func find_lowest_dijkstra(distances:Dictionary, unvisited:Array):
	var lowest = INF
	var cell
	for x in unvisited:
		var val = distances[x]
		if val<lowest:
			lowest = val
			cell = x
	return cell

func find_lowest_astar(distances:Dictionary,unvisited:Array):
	var lowest = INF
	var cell
	for x in unvisited:
		if distances[x]!= INF:
			var val = distances[x] +x.distance_to(End)
			if val<lowest:
				lowest = val
				cell = x
	return cell


func move(cell:Vector2):
	var temp = (cell+Vector2(0.5,0.5))*32
	get_node("Sprite").position = temp
	get_node("Trail").add_point(temp)

func activate(graph:Dictionary,start:Vector2,end:Vector2, algo):
	Algo = algo
	Start = start
	End = end
	visible = true
	if is_shortest_path(algo):
		shortest_path(graph,start,end,algo)
	elif algo == Global.TRAVERSAL.Wall_Follower:
		wall_follower(graph,start,end)
	elif algo == Global.TRAVERSAL.Pledge:
		pledge(graph,start,end)
	elif algo == Global.TRAVERSAL.Random_Route:
		random_route(graph,start,end)


func shortest_path(graph:Dictionary,start:Vector2,end:Vector2,algo):
	
	#all possible directions (to be looped through)
	var directions =[Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]
	
	#records all unvisited nodes
	var unvisited:Array = []
	
	#records the shortest distance of each node from the start
	var distance_from_start :Dictionary ={}
	
	
	#contains the current node
	var current :Vector2= start
	for x in graph.keys():
		unvisited.append(x)
		distance_from_start[x] = INF
	distance_from_start[current] = 0
	
	while current != end:
		move(current)
		unvisited.erase(current)
		
		#if there is no wall in a direction, it adds that to the distance_from_start
		for dir in directions:
			if graph[current][dir]:
				var new_distance = distance_from_start[current]+1
				if distance_from_start[current+dir] > new_distance:
					distance_from_start[current+dir] = new_distance
					Shortest_Paths[current+dir] = current 
		if algo == Global.TRAVERSAL.Best_First:
			current = find_lowest_best_first(distance_from_start,unvisited)
		elif algo == Global.TRAVERSAL.A_Star:
			current = find_lowest_astar(distance_from_start,unvisited)
		elif algo == Global.TRAVERSAL.Dijkstra:
			current = find_lowest_dijkstra(distance_from_start,unvisited)
		
		if Delay:
			var t = Timer.new()
			t.set_wait_time(Delay)
			t.set_one_shot(true)
			self.add_child(t)
			t.start()
			yield(t, "timeout")
			t.queue_free()
		
	move(end)
	end_shortest_path()

func end_success():
	end()
	get_node("Sprite/Particles2D").emitting = true

func end():
	pass

func end_shortest_path():
	end_success()
	var line = get_node("Trail")
	var current :Vector2= End
	var path:=[]
	while current != Start:
		path.append(current)
		current = Shortest_Paths[current]
	path.append(Start)
	line.clear_points()
	for i in path:
		line.add_point((i+Vector2(0.5,0.5))*32)

func wall_follower_dir_order(facing:Vector2):
	var i = Dirs.find(facing)
	return [Dirs[(i+3)%4],Dirs[i],Dirs[(i+1)%4],Dirs[(i+2)%4]]

func wall_follower_find_left_wall(current:Vector2,graph:Dictionary):
	#looks in all 4 dirs to find the closest wall, returns a cell next to that wall
	var counter = 0
	while true:
		counter +=1
		var left = Vector2.LEFT
		if not graph[current+(left*(counter-1))][left]:
			return current+(left*(counter-1))

func wall_follower(graph:Dictionary,start:Vector2,end:Vector2):
	var visited =[]
	var facing:Vector2=Vector2.UP
	var current:Vector2=start
	move(current)
	
	var wall_adjacent = wall_follower_find_left_wall(current,graph)
	while current != wall_adjacent:
		current += Vector2.LEFT
		move(current)
	
	while current != end:
		var dir_order = wall_follower_dir_order(facing)
		for dir in dir_order:
			if graph[current][dir]:
				if [current,dir] in visited:
					return
				else:
					visited.append([current,dir])
				current = current+dir
				facing = dir
				move(current)
				break
		if Delay:
			var t = Timer.new()
			t.set_wait_time(Delay)
			t.set_one_shot(true)
			self.add_child(t)
			t.start()
			yield(t, "timeout")
			t.queue_free()
	end_success()


func pledge(graph:Dictionary,start:Vector2,end:Vector2):
	#something seems wrong about this, but I don't know what
	var visited =[]
	var mainDir = Dirs[randi()%Dirs.size()]
	var current = start
	var facing:Vector2=Vector2.UP
	var turns = 0
	move(current)
	
	var wall_adjacent = wall_follower_find_left_wall(current,graph)
	while current != wall_adjacent:
		current += Vector2.LEFT
		move(current)
	
	
	while current!=end:
		if turns == 0 and graph[current][mainDir]:
			current = mainDir+current
			facing = mainDir
			move(current)
			visited.append([current,mainDir])
		else:
			var i = Dirs.find(facing)
			
			#contains a direction, then a value to add to turns
			var dir_order = [[Dirs[(i+3)%4],-1],[Dirs[i],0],[Dirs[(i+1)%4],1],[Dirs[(i+2)%4],2]]
			for dir in dir_order:
				if graph[current][dir[0]]:
					if [current,dir] in visited:
						return
					else:
						visited.append([current,dir[0]])
					current = current+dir[0]
					facing = dir[0]
					turns +=dir[1]
					move(current)
					break
		if Delay:
			var t = Timer.new()
			t.set_wait_time(Delay)
			t.set_one_shot(true)
			self.add_child(t)
			t.start()
			yield(t, "timeout")
			t.queue_free()
	end_success()

func open_paths(graph:Dictionary,current:Vector2):
	var poss_dirs=[]
	for dir in Dirs:
		if graph[current][dir]:
			poss_dirs.append(dir)
	return poss_dirs

func random_route(graph:Dictionary,start:Vector2,end:Vector2):
	#tbf it's not fully random, always avoid going backwards
	var current = start
	var facing:Vector2
	move(current)
	while current!=end:
		var openPaths = open_paths(graph,current)
		openPaths.shuffle()
		print (openPaths)
		#if dead end
		if openPaths.size()==1:
			current += openPaths[0]
			facing = openPaths[0]
		else:
			for dir in openPaths:
				if facing.dot(dir)<0:
					continue
				current += dir
				facing = dir
				break
		move(current)
		if Delay:
			var t = Timer.new()
			t.set_wait_time(Delay)
			t.set_one_shot(true)
			self.add_child(t)
			t.start()
			yield(t, "timeout")
			t.queue_free()
		
	end_success()
