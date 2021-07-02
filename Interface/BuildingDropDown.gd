extends OptionButton


var Items = {"Randomized Kruskal":"res://Scenes/Maze/RandomizedKruskal.gd",
			"Randomized Depth-First":"res://Scenes/Maze/RandomizedDepthFirst.gd"}

# Called when the node enters the scene tree for the first time.
func _ready():
	add_items()

func add_items():
	for i in Items.keys():
		add_item(i)
