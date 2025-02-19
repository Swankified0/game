extends Area2D

@onready var timer: Timer = $Timer
@onready var game_manager: Node = %gameManager



func _on_body_entered(player: Node2D) -> void:
	game_manager.die()
	print("You died")
	
	#player.get_node("AnimatedSprite2D").queue_free()
	
	
	Engine.time_scale = 0.5
	timer.start()

func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
