extends Node2D
export(float) var Delay = 0.5
var Cell_Queue = []
var Paths:={}
var Start
var End
var Finished:bool = false

func _ready():
	get_node("Sprite/Particles2D").emitting = false
	visible = false
	

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
		if val<lowest and x in unvisited:
			lowest = val
			cell = x
	return cell

func find_lowest_astar(distances:Dictionary,unvisited:Array):
	var lowest = INF
	var cell
	for x in unvisited:
		var val = distances[x] +x.distance_to(End)
		if val<lowest and x in unvisited and distances[x]!= INF:
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
			end()
	else:
		var temp = (Cell_Queue.pop_back()+Vector2(0.5,0.5))*32
		get_node("Sprite").position = temp
		get_node("Trail").add_point(temp)
	

func activate(graph:Dictionary,start:Vector2,end:Vector2, algo):
	get_node("Timer").start(Delay)
	Start = start
	End = end
	dijkstra(graph,start,end,algo)


func dijkstra(graph:Dictionary,start:Vector2,end:Vector2,algo):
	visible = true
	
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
					Paths[current+dir] = current 
		if algo == Global.TRAVERSAL.Best_First:
			current = find_lowest_best_first(distance_from_start,unvisited)
		elif algo == Global.TRAVERSAL.A_Star:
			current = find_lowest_astar(distance_from_start,unvisited)
		elif algo == Global.TRAVERSAL.Dijkstra:
			current = find_lowest_dijkstra(distance_from_start,unvisited)
	
	Finished = true
	Cell_Queue.push_front(end)

func end():
	get_node("Sprite/Particles2D").emitting = true
	var line = get_node("Trail")
	var current :Vector2= End
	var path:=[]
	while current != Start:
		path.append(current)
		current = Paths[current]
	path.append(Start)
	line.clear_points()
	for i in path:
		line.add_point((i+Vector2(0.5,0.5))*32)
