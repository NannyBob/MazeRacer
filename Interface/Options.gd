extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_GoButt_button_up():
	Global.Horiz_Bias = get_node("HSlider").value
	Global.Vert_Bias = get_node("VSlider").value
	Global.Traversal_Algo_1 = get_node("TraversalDropDown1").get_selected_id()
	Global.Traversal_Algo_2 = get_node("TraversalDropDown2").get_selected_id()
	Global.Building_Algo = get_node("BuildingDropDown").get_selected_id()
	get_tree().change_scene("res://Scenes/Main.tscn")
