extends Area2D

@onready var game_manager: Node = %gameManager
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _on_body_entered(body: Node2D) -> void:
	game_manager.addPoint()
	animation_player.play("Pickup")
