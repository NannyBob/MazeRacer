extends OptionButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	for i in Global.BUILDING:
		add_item(i)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
