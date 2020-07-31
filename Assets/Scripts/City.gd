extends Spatial

#references
onready var gc = get_parent().get_parent()
onready var hexMap = get_parent()

onready var objType = gc.objTypes.CITY
var centreHex
var hexes = []
var startingHexes = 7
var selecting = false
var isSelected = false
var resources = {}
var baseRadius = 1
var maxRadius = 3
var expandableHexes = []
var cityName
var connectedCities = []

#Visuals
onready var outlineMesh = get_node("Cube_003/Outline")

#--Operations--
func initialise(var pos, var centre, var cityname):
	transform.origin = pos
	centreHex = centre
	hexes = hexMap.getHexesWithinRangeOf(centreHex,baseRadius) 
	hexes.append(centreHex) #TODO should resources be gathered from centre hex
	for hex in hexes:
		if hex.city != null:  #Could do reverse logic?
			hexes.erase(hex)
			continue
		hex.addCity(self)
		getTileResources(hex)
		if hex.hasRoad:
			hex.updateRoad()
	cityName = cityname

func newTurn():
	gc.gatherResources(gather())

func gather() -> Dictionary: #New resource gathering mechanic, maybe tweak old method, maybe have a dict of worked resources instead of having to loop through all hexes each turn
	var workedResources = {}
	for hex in hexes:
		if hex.resource == null: #TODO reverse logic?
			continue
		if hex.beingWorked:
			if workedResources.has(hex.resource):
				workedResources[hex.resource] += hex.resourceAmt + bonusResource(hex)
			else:
				workedResources[hex.resource] = hex.resourceAmt + bonusResource(hex)
	#TEMP - outside of functions scope, maybe move later into collect tax function
	var gold = hexMap.resources.GOLD
	if workedResources.has(gold):
		workedResources[gold] += cityLevel() #TODO should there be a bonus for GOLD?
	else:
		workedResources[gold] = cityLevel()
	return workedResources

func bonusResource(var hex) -> int: 
	return gc.civBuffs["Bonus"][gc.biomeResString[hex.hexType]]

func expandCity(var hex): #Every three hexes added level up the city
	gc.spendResource(hexMap.resources.WOOD, gc.cityExpansionCost + gc.civBuffs["Bonus"]["City"])
	unHighlightHexes()
	expandableHexes = []
	hex.addCity(self)
	hexes.append(hex)
	getTileResources(hex)
	highlightHexes()

func getTileResources(var hex):
	if hex.resource != null:
		if resources.has(hex.resource):
			resources[hex.resource] += hex.resourceAmt
		else:
			resources[hex.resource] = hex.resourceAmt

func connectCities(var cities):
	for city in cities:
		if city == self || connectedCities.has(city):
			continue
		else:
			connectedCities.append(city)
			print("Connected -")
			print(city)

func changeName(var newName):
	cityName = newName

#--Helpers--
func pos() -> Vector3:
	return centreHex.pos()

func expandableHexes() -> Array:
	var maxHexes = hexMap.getHexesWithinRangeOf(centreHex, maxRadius) #Change to get only allow hexes within certain steps
	var neighbours = []
	for hex in hexes:
		for neighbour in hexMap.getNeighbours(hex):
			if !hexes.has(neighbour) && !neighbours.has(neighbour) && neighbour.city == null && maxHexes.has(neighbour):
				neighbours.append(neighbour)
	print(cityLevel())
	return neighbours

func canExpand() -> bool:
	if gc.playerResources[1] < gc.cityExpansionCost + gc.civBuffs["Bonus"]["City"]: #TODO change to not use hardcoded wood
		return false
	return expandableHexes().size() > 0

func cityLevel() -> int:
	return 1 + int(floor((hexes.size()-startingHexes)/3))

#--Input--
func _on_StaticBody_input_event(camera, event, click_position, click_normal, shape_idx): #Maybe update to touch input
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			selecting = true
			if event.doubleclick:
				camera.moveToObj(self) #Sometimes jerk
		if Input.is_action_just_released("click") && selecting: 
				gc.selectCity(self)

func selected():
	isSelected = true
	highlight()
	highlightHexes()
	
func deSelected():
	isSelected =  false
	unHighlight()
	unHighlightHexes()
	print("deselected city")

#--Visuals
func highlight():
	outlineMesh.visible = true

func unHighlight():
	outlineMesh.visible = false

func highlightHexes():
	for hex in hexes:
		hex.highlightHex(false)
	for hex in expandableHexes:
		hex.highlightHex(true)

func unHighlightHexes():
	for hex in hexes:
		hex.unHighlightHex(false)
	for hex in expandableHexes:
		hex.unHighlightHex(true)
