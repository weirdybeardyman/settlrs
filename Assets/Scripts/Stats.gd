extends Control

onready var fpsText = get_node("FPS")

func _process(delta):
	fpsText.text = "FPS: " + String(Engine.get_frames_per_second())
