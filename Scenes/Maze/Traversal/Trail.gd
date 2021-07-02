extends Line2D
func _ready():
	width = 100 / get_parent().get_parent().get_parent().Size.y

func add():
	var point = get_parent().get_parent().global_position
	add_point(point)


