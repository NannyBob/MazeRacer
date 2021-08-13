extends Node2D
export(float) var Delay = 0.5
var Cell_Queue = []
var Shortest_Paths:={}
var Start
var End
var Finished:bool = false
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
	print(cell)
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


func _on_Timer_timeout():
	#if cell queue is empty, then the end has been reached
	#otherwise it takes the traverser to the pos at the front of the queue
	#and updates the trail
	
	if Cell_Queue.empty():
		if Finished:
			get_node("Timer").stop()
			if is_shortest_path(Algo):
				end_shortest_path()
			else:
				end_success()
	else:
		var temp = (Cell_Queue.pop_back()+Vector2(0.5,0.5))*32
		get_node("Sprite").position = temp
		get_node("Trail").add_point(temp)
	

func activate(graph:Dictionary,start:Vector2,end:Vector2, algo):
	Algo = algo
	get_node("Timer").start(Delay)
	Start = start
	End = end
	visible = true
	if is_shortest_path(algo):
		shortest_path(graph,start,end,algo)
	elif algo == Global.TRAVERSAL.Wall_Follower:
		wall_follower(graph,start,end)


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
		Cell_Queue.push_front(current)
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
	
	Finished = true
	Cell_Queue.push_front(end)

func end_success():
	get_node("Sprite/Particles2D").emitting = true

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

func wall_follower(graph:Dictionary,start:Vector2,end:Vector2):
	var visited =[]
	var facing:Vector2=Vector2.UP
	var current:Vector2=start
	Cell_Queue.push_front(current)
	while current != end:
		var dir_order = wall_follower_dir_order(facing)
		for dir in dir_order:
			if graph[current][dir]:
				if [current,dir] in visited:
					print("failure")
				else:
					visited.append([current,dir])
				current = current+dir
				facing = dir
				Cell_Queue.push_front(current)
				break
	Finished = true
