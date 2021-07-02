extends TileMap
export var Speed = 100
var Target_Pos

func _process(delta):
	var new_pos:Vector2 = position+Vector2.RIGHT*delta*Speed
	if new_pos.x> Target_Pos.x:
		position = Target_Pos
		set_process(false)
	else:
		position = new_pos

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)

func activate(size,graph):
	Target_Pos = Vector2(32*size,0)
	set_process(true)


func _on_Area2D_body_entered(body):
	pass
