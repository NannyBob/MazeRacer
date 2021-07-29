extends TileMap

export (Vector2) var Size = Vector2(8,8)
var Indicator



func _ready():
	# adds the current tile indicator
	var indicator_scene = load("res://Scenes/Maze/CurrentTile.tscn")
	Indicator = indicator_scene.instance()
	add_child(Indicator)

func update_tile(tile:Vector2,tile_dict:Dictionary):
	#updates how a specific tile looks
	Indicator.position = map_to_world(tile)+ Vector2(16,16)
	var idx = 0
	if tile_dict[Vector2.UP]:idx+=1
	if tile_dict[Vector2.RIGHT]:idx+=2
	if tile_dict[Vector2.DOWN]:idx+=4
	if tile_dict[Vector2.LEFT]:idx+=8
	idx = 15-idx
	set_cellv(tile,idx)

func place_start_n_end(start:Vector2,end:Vector2):
	get_node("Start").position =map_to_world(start)
	get_node("Start").visible = true
	get_node("End").position =map_to_world(end)
	get_node("End").visible = true
