extends Node2D

signal isTalking(value: bool)

@onready var player = get_tree().get_first_node_in_group("player")
@onready var label: Label = $Label

const baseText = "[C] to "

var active_areas = []
var canInteract: bool = true

#Receive Signals
	#Declare variables
var isGrounded: bool
var isMoving: bool

	#Handler Functions for Signals
func _on_isGrounded_signal(value: bool):
	isGrounded = value
func _on_isMoving_signal(value: bool):
	isMoving = value

func _ready():
	#Connect player state signals
	var player = get_node("/root/Game/Player")
	
	player.isGrounded.connect(_on_isGrounded_signal)
	player.isMoving.connect(_on_isMoving_signal)

#Register Area
func registerArea(area: InteractionArea):
	print("area registered")
	active_areas.push_back(area)

func unregisterArea(area: InteractionArea):
	print("area unregistered")
	var index = active_areas.find(area)
	
	if index != -1:
		active_areas.remove_at(index)

func _process(delta):
	if active_areas.size() > 0 and canInteract:
		active_areas.sort_custom(_sort_by_distance_to_player)
		
		label.text = baseText + active_areas[0].actionName
		label.global_position = active_areas[0].global_position
		label.global_position.y -= 36
		label.global_position.x -= label.size.x / 2
		label.show()
	
	else:
		label.hide()

func _sort_by_distance_to_player(area1, area2):
	var area1_to_player = player.global_position.distance_to(area1.global_position)
	var area2_to_player = player.global_position.distance_to(area2.global_position)
	
	return area1_to_player < area2_to_player

func _input(event):
	if event.is_action_pressed("interact") and canInteract and isGrounded and not isMoving:
		if active_areas.size() > 0:
			print(".")
			canInteract = false
			label.hide()
			
			emit_signal("isTalking", true)
			
			await active_areas[0].interact.call()
			
			canInteract = true
			emit_signal("isTalking", false)
