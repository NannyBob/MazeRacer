extends Line2D

func _ready():
	pass

func add():
	var point = get_parent().get_parent().global_position
	add_point(point)
