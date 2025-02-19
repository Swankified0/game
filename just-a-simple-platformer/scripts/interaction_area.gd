extends Area2D
class_name InteractionArea

@export var actionName: String = "interact"

var interact: Callable = func():
	pass


func _on_body_entered(body) -> void:
	print("what")
	InteractionManager.registerArea(self)


func _on_body_exited(body):
	print("how")
	InteractionManager.unregisterArea(self)
