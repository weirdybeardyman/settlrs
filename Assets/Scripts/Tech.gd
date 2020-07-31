extends Node

onready var gc = get_node("/root/GameController")
var technology
var unlocked
var cost
var parent
var contextTxt
var buffType
var buffKey
var buffValue

#UI
onready var UILabel = get_node("Container/Label")
onready var UICost = get_node("Container/Cost")
onready var UIUnlock = get_node("Container/Unlock")
onready var UIContext = get_node("Context")
var unlockedColour = Color(1,0,0)

func isUnlockable() -> bool:
	#if already unlocked, if parent is unlocked, if we have enough gold to unlock it
	if parent == null:
		return !unlocked && gc.playerResources[gc.hexMap.resources.GOLD] >= cost
	return !unlocked && parent.unlocked && gc.playerResources[gc.hexMap.resources.GOLD] >= cost#TODO I feel like it shouldn't have to grab a reference to GC for each technology

func update():
	UILabel.text = str(technology)
	UICost.text = str(cost)
	UIContext.text = str(contextTxt)
	UIUnlock.disabled = !isUnlockable()
	if unlocked:
		UILabel.add_color_override("font_color", unlockedColour)
		UICost.add_color_override("font_color", unlockedColour)

func _on_Unlock_pressed():
	unlocked = true
	gc.spendResource(gc.hexMap.resources.GOLD,cost) #TODO tidy up references, can I make enums global??
	get_parent().get_parent().get_parent().get_parent().get_parent().updateTechTree() #TODO fix - maybe go down from root?
	gc.civBuffs[buffType][buffKey] = buffValue
