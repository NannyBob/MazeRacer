extends Node


var Maze_Size:Vector2 = Vector2(20,20)
var Scale:Vector2
enum TRAVERSAL { Dijkstra,Best_First,A_Star }
enum BUILDING {Kruskal,Depth_First}
var Building_Algo
var Traversal_Algo_1
var Traversal_Algo_2
var Horiz_Bias
var Vert_Bias
