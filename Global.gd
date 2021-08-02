extends Node


var Maze_Size:Vector2 = Vector2(20,20)
var Scale:Vector2
enum TRAVERSAL { Dijkstra,A_Star,Best_First }
enum BUILDING {Kruskal,Depth_First,Aldous_Broder}
var Building_Algo
var Traversal_Algo_1
var Traversal_Algo_2
var Horiz_Bias
var Vert_Bias
