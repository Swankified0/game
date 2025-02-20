extends Node2D

@onready var interaction_area: InteractionArea = $interactionArea

const lines: Array[String] = [
	"line 1",
	"line 2",
	"line 3 omegaLaugh"
]

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")

func _on_interact():
	DialogManager.startDialog(global_position, lines)
	await  DialogManager.dialog_finished
