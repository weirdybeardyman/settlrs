extends Spatial

onready var camera = get_node("Camera")
onready var hexMap = get_node("Map")
export (PackedScene) var unit1
export (PackedScene) var city1

var units = [] #should I just have all this in hexmap?
var cities = []
var selectedObj
onready var playerResources = {hexMap.resources.FOOD:0,hexMap.resources.WOOD:5,hexMap.resources.ORE:0,hexMap.resources.GOLD:0}
#TODO move to some UI element - player resources UI
onready var foodTxt = get_node("Control/Inventory GUI/HBoxContainer/Food/HSplitContainer/Label")
onready var woodTxt = get_node("Control/Inventory GUI/HBoxContainer/Wood/HSplitContainer/Label")
onready var oreTxt = get_node("Control/Inventory GUI/HBoxContainer/Ore/HSplitContainer/Label")
onready var goldTxt = get_node("Control/Inventory GUI/HBoxContainer/Gold/HSplitContainer/Label")
onready var resourceTxts = {hexMap.resources.FOOD:foodTxt,hexMap.resources.WOOD:woodTxt,hexMap.resources.ORE:oreTxt,hexMap.resources.GOLD:goldTxt}
#TODO because these are enums I could just use an array???
enum objTypes {HEX,UNIT,CITY}
enum unitTypes {SETTLER,WORKER,SAILOR} #TODO trader
onready var unitData = getJSON(dataPath + unitDataPath) #TODO add unit models to this - currently array of units [dict with keys "name,cost,abillities"]
#var abilities = [canCoast,canSea,canLand,canSettle] - canClimb will now just be canLand and then check civBuffs
onready var unitModels = {unitTypes.SETTLER:unit1,unitTypes.WORKER:unit1,unitTypes.SAILOR:unit1}

var cityExpansionCost = 20 #TODO Increase over time? - as city expands but modify with tech, maybe per city??
var roadCost = 5 #Also change with tech

export (PackedScene) var hexMenu
export (PackedScene) var unitMenu
export (PackedScene) var cityMenu
export (PackedScene) var techTreeMenu
var menu
onready var biomeNames = {hexMap.SEA:"Sea",hexMap.COAST:"Coast",hexMap.GRASS:"Grass",hexMap.MOUNTAIN:"Mountain",hexMap.DESERT:"Desert",hexMap.FOREST:"Forest",hexMap.TUNDRA:"Tundra"}

const dataPath = "res://Assets/Data/" #TODO for saving things maybe use user:// for the standard writeable folder
const cityNamesPath = "cityNames.json"
const techTreePath = "techTree.json"
const civBuffsPath = "civBuffs.json"
const unitDataPath = "unitData.json"

#var techTree
var techTreeUI
onready var civBuffs = getJSON(dataPath + civBuffsPath)
onready var biomeResString = {hexMap.SEA:"Fish",hexMap.COAST:"Fish",hexMap.GRASS:"Wheat",hexMap.MOUNTAIN:"Ore",hexMap.DESERT:"Gold",hexMap.FOREST:"Wood",hexMap.TUNDRA:"Gold"}
#Individual player stats
var player
var civilization = "China"

func _ready():
	loadTechTree()
	#loadCivBuffs()

func _process(delta):
	if hexMap.mapGenerated && units.size() == 0:
		spawnUnit(hexMap.getHexAt(5,5), unitTypes.SETTLER)

func nextTurn():
	for u in units:
		u.newTurn()
	for c in cities:
		c.newTurn()
	print("Next Turn")
	
#--Spawning--

func spawnUnit(var hex, var unitType):
	#TEST
	if playerResources[hexMap.resources.FOOD] > 0:
		spendResource(hexMap.resources.FOOD, unitData[unitType]["Cost"])#unitCosts[unitType])
	var obj = unitModels[unitType]
	var u = obj.instance()
	get_node("Map").add_child(u)
	u.initialise(hex.pos(), hex, unitType, unitData[unitType]["Abilities"])
	hex.addUnit(u)
	units.append(u)
	print("Spawned Unit")

func spawnCity(var hex): 
	var c = city1.instance()
	get_node("Map").add_child(c)
	hex.makeCityCentre()
	c.initialise(hex.pos(), hex, getCityName()) #TODO city name
	cities.append(c)
	print("Created City")

func selectHex(var hex):
	if selectedObj == null:
		selectObj(hex)
		print("Hex selected")
	elif selectedObj.objType == objTypes.UNIT:
		if selectedObj.possibleHexes.has(hex) && selectedObj.canMove():
			selectedObj.moveToHex(hex)
			return
	elif selectedObj.objType == objTypes.CITY:
		if selectedObj.expandableHexes.has(hex):
			selectedObj.expandCity(hex)
			return
	selectObj(hex)
	print("Hex selected")

func selectUnit(var unit):
	selectObj(unit)
	print("Selected unit")

func selectCity(var city):
	selectObj(city)
	print("City selected")

func selectObj(obj):
	closeContext()
	openContext(obj)
	if selectedObj != null:
		selectedObj.deSelected()
	selectedObj = obj
	selectedObj.selected()

func deselectObj(): #NEEDED??
	selectedObj.deSelected()
	selectedObj = null

func gatherResources(var resources): #TODO change
	for r in resources:
		playerResources[r] += resources[r]
	updateResourcesUI()

func spendResource(var resource, var amt):
	playerResources[resource] -= amt
	updateResourcesUI()

func updateResourcesUI():
	for r in playerResources:
		resourceTxts[r].text = str(playerResources[r])

#TEST context menus
func openContext(var obj): #TODO use seperate functions to reduce checks
	var objName
	if obj.objType == objTypes.HEX:
		menu = hexMenu.instance()
		objName = biomeNames[obj.hexType] 
	elif obj.objType == objTypes.UNIT:
		menu = unitMenu.instance()
		objName = unitData[obj.unitType]["Name"]
	elif obj.objType == objTypes.CITY:
		menu = cityMenu.instance()
		objName = obj.cityName
	get_node("Control").add_child(menu)
	menu.initialise(obj, objName)
	
func closeContext(): #Just put at start of openContext?
	if menu != null:
		menu.queue_free()
		menu = null

func updateContext():
	pass

func getCityName() -> String:
	var parsed = getJSON(dataPath + cityNamesPath)
	var nameArray = parsed.get(civilization)
	return nameArray[hexMap.rng.randi_range(0,nameArray.size()-1)] #TODO don't grab rng from hexMap???

func loadTechTree(): #TODO change method && concisify naming scheme (t,tech,technology,tree)
	var trees = getJSON(dataPath + techTreePath)
	var tt = techTreeMenu.instance()
	#get_node("Control"). TODO should be instanced on to control???
	add_child(tt)
	tt.populateTechTree(trees)
	techTreeUI = tt

func getJSON(var path):
	var file = File.new()
	if not file.file_exists(path):
		print(path + "JSON not found - Loading")
		return null
	file.open(path, file.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	return data

func setJSON(var path, var data):
	var file = File.new()
	if not file.file_exists(path):
		print(path + "JSON not found - Saving")
		return null
	file.open(path, file.WRITE)
	file.store_line(data.to_json())
	file.close()

func _on_Next_Turn_pressed():
	nextTurn()

func _on_OpenTechTree_pressed():
	techTreeUI.openMenu()


func _on_Close_pressed():
	get_tree().quit() #TODO not correct way of doing this on Android if I remember
