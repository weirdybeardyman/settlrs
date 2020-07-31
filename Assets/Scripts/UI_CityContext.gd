extends Control

onready var gc = get_parent().get_parent()
var city
var nameText
#--Stats--#
onready var level = get_node("VBoxContainer/StatsMargin/StatsList/City Level/Text")
onready var tiles = get_node("VBoxContainer/StatsMargin/StatsList/City Tiles/Text")
#onready var player = get_node("VBoxContainer/StatsMargin/StatsList/Player/Text") - Add
#-Resources-#
export (PackedScene) var resourceUI
export (Array, Texture) var resourceImgs
#--Abilities--#
onready var buttonList = get_node("VBoxContainer/ButtonsMargin/ButtonsList")
onready var expand = get_node("VBoxContainer/ButtonsMargin/ButtonsList/Expand City")
#Unit spawning
export (PackedScene) var spawnButton

func initialise(var City, var Name):
	city = City
	nameText = get_node("VBoxContainer/Header/Name")
	nameText.text = Name
	#stats#
	level.text = str(city.cityLevel())
	tiles.text = str(city.hexes.size())
	#player = str(obj.player)
	#resources#
	var stats = get_node("VBoxContainer/StatsMargin/StatsList")
	for resource in city.resources:
		var resUI = resourceUI.instance()
		stats.add_child(resUI)
		var resourceTxt = resUI.get_node("ResourceAmt")
		resourceTxt.text = str(city.resources[resource])
		var resourceImg = resUI.get_node("ResourceTex")
		resourceImg.texture = resourceImgs[resource]
	#abilities#
	expand.visible = true #TODO only show expand city button if you can expand - Obselete
	expand.disabled = !city.canExpand()
	
	for unit in gc.unitTypes.values(): #TODO unlocked or not
		var unitButton = spawnButton.instance()
		buttonList.add_child(unitButton)
		var cost = gc.unitData[unit]["Cost"]
		var unitTxt = gc.unitData[unit]["Name"] + " - " + str(cost) #TODO if don't call enum.values() it gives string name
		unitButton.text = unitTxt
		#connection
		unitButton.connect("pressed",self,"_on_Spawn_Unit_pressed",[unit])
		#TODO change when I merge food resources together - also change from hardcoded value
		unitButton.disabled = !gc.playerResources[0] >= cost #TODO disable or visible, Also disable if not unlocked tech yet, alo change use of 0
		
func _on_Close_pressed():
	gc.closeContext()
	gc.deselectObj()

func _on_Expand_City_pressed():
	city.expandableHexes = city.expandableHexes()
	city.unHighlightHexes()
	city.highlightHexes()

func _on_Spawn_Unit_pressed(var unit):
	gc.spawnUnit(city.centreHex, unit)

func _on_Name_text_entered(new_text):
	city.changeName(new_text)
