extends Control

onready var gc = get_parent().get_parent()
var unit
var nameText
#--Stats--#
onready var movesLeft = get_node("VBoxContainer/StatsMargin/StatsList/Moves Left/moves left")
onready var moveRange = get_node("VBoxContainer/StatsMargin/StatsList/Move Range/move range")
onready var health = get_node("VBoxContainer/StatsMargin/StatsList/Health/health")
#onready var player = get_node("VBoxContainer/StatsMargin/StatsList/Player/player") - Add
#--Abilities--#
onready var settle = get_node("VBoxContainer/ButtonsMargin/ButtonsList/Settle")
onready var work = get_node("VBoxContainer/ButtonsMargin/ButtonsList/Work")
onready var buildRoad = get_node("VBoxContainer/ButtonsMargin/ButtonsList/Build Road")

func initialise(var Unit, var Name):
	unit = Unit
	nameText = get_node("VBoxContainer/Header/Name")
	nameText.text = Name
	#stats#
	movesLeft.text = str(unit.movesLeft) #Should I show this as it's dynamic- todo refresh
	moveRange.text = str(unit.moveRange)
	health.text = str(unit.health)
	#player = str(obj.player)
	#abilities#
	settle.visible = unit.abilities[3] #TODO should we just use unitType == SETTLER instead of ability bools?, or change abilities to a dict
	settleButton()
	workButton() #Not best way to do this toggle and update
	buildRoadButton()
	
func workButton():
	work.visible = unit.unitType == gc.unitTypes.WORKER
	if !unit.isWorking:
		work.text = "Work Resource" #TODO maybe get resource name?
	else:
		work.text = "Stop Working"
	work.disabled = !unit.canWorkHex()

func settleButton():
	settle.disabled = !unit.canSettleHex()

func buildRoadButton():
	buildRoad.disabled = !unit.canBuildRoad()
	#TODO display cost too

func _on_Close_pressed():
	gc.closeContext()
	gc.deselectObj()

func _on_Settle_pressed():
	if unit.currentHex.city == null:
		#gc.spawnCity(obj.currentHex)
		unit.settleHex()
	else:
		print("Can't create city here")
	settleButton() #TODO change method

func _on_Work_pressed():
	if !unit.isWorking:
		unit.workHex()
	else:
		unit.stopWork()
	workButton() #TODO change method


func _on_Build_Road_pressed():
	unit.currentHex.buildRoad() #TODO maybe change first time bool
	buildRoadButton()
