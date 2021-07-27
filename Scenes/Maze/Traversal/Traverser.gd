extends Node2D
export(float) var Delay = 0.5
var Cell_Queue = []

func _ready():
	get_node("Particles2D").emitting = false
	visible = false
	

func find_lowest(distances:Dictionary,visisted:Dictionary):
	#finds the cell with the lowest recorded euclidean distance that has
	#not yet been visited
	var lowest = INF
	var cell
	for x in distances.keys():
		var val = distances[x]
		if val<lowest and not visisted[x]:
			lowest = val
			cell = x
	return cell

func find_lowest_dijkstra(distances:Dictionary, unvisited:Array):
	var lowest = INF
	var cell
	for x in distances.keys():
		var val = distances[x]
		if val<lowest and unvisited.has(x):
			lowest = val
			cell = x
	return cell


func _on_Timer_timeout():
	#if cell queue is empty, then the end has been reached
	#otherwise it takes the traverser to the pos at the front of the queue
	#and updates the trail
	if Cell_Queue.empty():
		get_node("Particles2D").emitting = true
		return
	position = (Cell_Queue.pop_back()+Vector2(0.5,0.5))*32
	get_node("Node/Trail").add()
	

func activate(graph:Dictionary,start:Vector2,end:Vector2, algo:String):
	if algo == "best first":
		best_first(graph,start,end)
	if algo == "dijkstra":
		dijkstra(graph,start,end)

func best_first(graph:Dictionary,start:Vector2,end:Vector2):
	get_node("Timer").start(Delay)
	visible = true
	
	#all possible directions (to be looped through)
	var directions =[Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]
	
	#records wether nodes have been visited
	var visited:Dictionary = {}
	
	#records the euclidean distance of each node from the end
	var distances :Dictionary ={}
	
	#contains the current node
	var current :Vector2= start
	for x in graph.keys():
		visited[x] = false
		distances[x] = INF
	distances[current] = 0
	
	while not current == end:
		
		#sets node as visited and pushes it to the travel queue
		Cell_Queue.push_front(current)
		visited[current] = true
		
		#if there is no wall in a direction, it adds that to the distances
		for dir in directions:
			if graph[current][dir]:
				distances[current+dir] = end.distance_to(current+dir)
				
		current = find_lowest(distances,visited)
	Cell_Queue.push_front(end)
	print("done")

func dijkstra(graph:Dictionary,start:Vector2,end:Vector2):
	get_node("Timer").start(Delay)
	visible = true
	
	#all possible directions (to be looped through)
	var directions =[Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]
	
	#records all unvisited nodes
	var unvisited:Array = []
	
	#records the shortest distance of each node from the start
	var distances :Dictionary ={}
	
	#contains the current node
	var current :Vector2= start
	for x in graph.keys():
		unvisited.append(x)
		distances[x] = INF
	distances[current] = 0
	
	while current != end:
		Cell_Queue.push_front(current)
		unvisited.erase(current)
		
		#if there is no wall in a direction, it adds that to the distances
		for dir in directions:
			if graph[current][dir]:
				var new_distance = distances[current]+1
				if distances[current+dir] > new_distance:
					distances[current+dir] = new_distance
		current = find_lowest_dijkstra(distances,unvisited)
	
	Cell_Queue.push_front(end)
