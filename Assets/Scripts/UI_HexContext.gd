extends Control

var hex
var nameText
export (Array, Texture) var resourceImgs #TODO move over to a UI controller
onready var resourceImg = get_node("VBoxContainer/StatsMargin/StatsList/Resources/ResourceTex")
onready var resourceTxt = get_node("VBoxContainer/StatsMargin/StatsList/Resources/ResourceAmt")
onready var resourceContainer = get_node("VBoxContainer/StatsMargin/StatsList/Resources")

#var resource
#var resourceAmtText

func initialise(var Hex, var Name):
	hex = Hex
	nameText = get_node("VBoxContainer/Header/Name")
	nameText.text = Name
	var res = hex.resource
	if res != null:
		resourceImg.texture = resourceImgs[res]
		resourceTxt.text = str(hex.resourceAmt)
	else:
		resourceContainer.visible = false

func _on_Close_pressed():
	var gc = get_parent().get_parent()
	gc.closeContext()
	gc.deselectObj()
