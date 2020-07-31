extends Spatial

var q
var r 
var s

export (PackedScene) var hexHighlight
export (PackedScene) var road
onready var highlight = get_node("hexHighlight2")
onready var camera = get_viewport().get_camera()
onready var gc = get_parent().get_parent()
onready var hexMap = get_parent()
onready var objType = gc.objTypes.HEX
var hexType
var selecting = false
var isSelected = false
var baseMovementCost
var units = []
var beingWorked = false
var city
var isCityCentre
var resource
var resourceAmt
var edges = [] #edgeType, dir
var hasRoad = false
var roads = []
var cityConnections = []

const hexHeight = 2 #Should this be a const or func - radius = 1, height = radius *2
const widthMulti = sqrt(3) / 2

func hexWidth(): #Maybe rename to horizOff
	return widthMulti * hexHeight
func vertOff():
	return hexHeight * 0.75

func _ready():
	pass

func _process(delta):
	if camera.moved:
		selecting = false

func setup(var Q, var R, var Type, var moveCost, var resourceType, var resourceAmount):
	q = Q
	r = R
	s = -(Q+R)
	hexType = Type
	resource = resourceType
	resourceAmt = resourceAmount
	baseMovementCost = moveCost
	transform.origin = pos()

func pos() -> Vector3:
	var xPos = hexWidth()*(q + float(r)/2)
	var yPos = vertOff() * r
	return Vector3(xPos,0,yPos)

func addUnit(var u):
	units.append(u)

func removeUnit(var u):
	units.erase(u)

func addCity(var c):
	city = c 
	highlight.madeCity()

func makeCityCentre():
	isCityCentre = true
	if resource != null:
		get_node("res").queue_free() #TODO not best way of grabbing resource object
		resource = null
	resourceAmt = 0

func hasCity() -> bool:
	return city != null

func buildRoad(var lastHex = null): 
	hasRoad = true
	gc.spendResource(hexMap.resources.WOOD, gc.roadCost + gc.civBuffs["Bonus"]["Road"])#TODO should I just use 1 not reference?
	for dir in range(hexMap.directions.size()):
		#var n = hexMap.getNeighbour(self, hexMap.directions[dir])
		var n = hexMap.getNeighbour(q, r, hexMap.directions[dir])
		if n.isCityCentre:
			if !cityConnections.has(n.city):
				cityConnections.append(n.city)
				n.city.connectCities(cityConnections)
			var roadTile = road.instance()
			add_child(roadTile)
			roads.append(roadTile)
			roadTile.rotate_y(deg2rad(hexMap.rotations[dir]))
		if n.hasRoad:
			var roadTile = road.instance()
			add_child(roadTile)
			roads.append(roadTile)
			roadTile.rotate_y(deg2rad(hexMap.rotations[dir]))
			for city in n.cityConnections:
				if !cityConnections.has(n.city):
					cityConnections.append(n.city)
			if n != lastHex:
				n.updateRoad(self)

func updateRoad(var lastHex = null):
	for r in roads:
		remove_child(r)
	roads = []
	buildRoad(lastHex)

func movementCost() -> float:
	if hasRoad:
		return baseMovementCost/2
	else:
		return baseMovementCost

func _on_StaticBody_input_event(camera, event, click_position, click_normal, shape_idx): #Maybe update to touch input
	if event is InputEventMouseButton:
		if Input.is_action_just_released("click") && selecting:
				gc.selectHex(self)
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			selecting = true
			if event.doubleclick:
				camera.moveToObj(self)

func selected(): #TODO when selecting hex maybe select the city it belongs to if it belongs to any
	isSelected = true
	print("selected hex")
	highlightHex(false)
	
func deSelected():
	isSelected =  false
	print("deselected hex")
	unHighlightHex(false)

func highlightHex(var pos):
#	highlight = hexHighlight.instance()
#	add_child(highlight)
	if pos:
		highlight.possible()
	else:
		highlight.select()

func unHighlightHex(var pos):
	if pos:
		highlight.dePossible()
	else:
		highlight.deSelect()
