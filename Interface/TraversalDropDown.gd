extends OptionButton

var Items = {"Best-First":"res://Scenes/Maze/Traversal/BestFirst.gd"}

# Called when the node enters the scene tree for the first time.
func _ready():
	add_items()

func add_items():
	for i in Items.keys():
		add_item(i)

