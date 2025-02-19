extends Node2D

@onready var interaction_area: InteractionArea = $interactionArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const LINES: Array[String] = [
	"test line 1",
	"test line 2",
	"test line 3"
	]

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	print("sign")

func _on_interact():
	print("huh")
	DialogManager.startDialog(global_position, LINES)
	
	await DialogManager.dialog_finished
	#animation_player.play("textPopup")
