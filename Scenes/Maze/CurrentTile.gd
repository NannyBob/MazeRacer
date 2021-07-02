extends Sprite


var Last_pos

func _on_Timer_timeout():
	if position == Last_pos:queue_free()
	Last_pos = position
