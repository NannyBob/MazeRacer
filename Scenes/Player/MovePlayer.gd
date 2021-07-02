extends KinematicBody2D

var Graph:Dictionary
export (int) var speed = 200
var poss_scene = preload("res://Scenes/Player/PossTile.tscn")

var velocity = Vector2()

func _ready():
	set_physics_process(false)
	

func new_poss(pos:Vector2):
	var poss = poss_scene.instance()
	add_child(poss)
	poss.position = pos

func activate(size:Vector2,graph:Dictionary,y,z):
	Graph = graph
	get_node("Node/Trail").width = 100 /size.y
	set_physics_process(true)

func get_input():
	velocity = Vector2()
	if Input.is_action_pressed('Right'):
		velocity.x += 1
	if Input.is_action_pressed('Left'):
		velocity.x -= 1
	if Input.is_action_pressed('Down'):
		velocity.y += 1
	if Input.is_action_pressed('Up'):
		velocity.y -= 1
	velocity = velocity.normalized() * speed

func _physics_process(delta):
	get_input()
	if not velocity == Vector2.ZERO:
		get_node("Node/Trail").add()
		rotation = velocity.angle()
	velocity = move_and_slide(velocity)
