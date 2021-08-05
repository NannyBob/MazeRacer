extends HSlider

export(NodePath) var label_path
onready var label = get_node(label_path)
export(String) var Text


func _on_value_changed(value):
	label.text = Text + String(value)
