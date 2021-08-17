extends Node


var Maze_Size:Vector2 = Vector2(40,40)
var Scale:Vector2
enum TRAVERSAL { Dijkstra,A_Star,Best_First,Wall_Follower,Pledge }
enum BUILDING {Kruskal,Depth_First,Depth_First_Twice,Aldous_Broder,Eller,Prim,Sidewinder}
var Building_Algo
var Traversal_Algo_1
var Traversal_Algo_2
var Horiz_Bias
var Vert_Bias
