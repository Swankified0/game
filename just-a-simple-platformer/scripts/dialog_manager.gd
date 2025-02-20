extends Node

@onready var text_box_scene = preload("res://scenes/textBox.tscn")

var dialogLines: Array[String] = []
var currentLineIndex = 0

var textBox
var textBoxPos: Vector2

var isDialogActive = false
var canAdvanceLine = false

signal dialog_finished()

func startDialog(position: Vector2, lines: Array[String]):
	if isDialogActive:
		return
	
	dialogLines = lines
	textBoxPos = position
	_show_text_box()
	
	isDialogActive = true

func _show_text_box():
	textBox = text_box_scene.instantiate()
	textBox.finished_displaying.connect(_on_text_box_finished_displaying)
	get_tree().root.add_child(textBox)
	textBox.global_position = textBoxPos
	textBox.displayText(dialogLines[currentLineIndex])
	canAdvanceLine = false

func _on_text_box_finished_displaying():
	canAdvanceLine = true

func _unhandled_input(event):
	if (
		event.is_action_pressed("interact") and
		isDialogActive and
		canAdvanceLine
	):
		textBox.queue_free()
		
		currentLineIndex += 1
		if currentLineIndex >= dialogLines.size():
			isDialogActive = false
			currentLineIndex = 0
			dialog_finished.emit()
			return
		
		_show_text_box()
