extends Spatial

#References - I feel like this is too many references for each unit and might result in overhead
onready var camera = get_viewport().get_camera()
onready var hexMap = get_parent()
onready var gc = get_parent().get_parent()
onready var pathfinder = gc.get_node("Pathfinder")
#State Keeping
var currentHex
var targetHex
var possibleHexes = []
var hexPath = []
var highlightedHexes = []
var viewedHexes = []
var selecting = false
var isSelected = false
var isMoving = false
var health = 10
var isWorking = false
#Movement
var moveRange = 2.0
var moveSpeed = 0.08
var movesLeft
var t = 0.0
var lerpCutoff = 0.05
#Unit Type
onready var objType = gc.objTypes.UNIT
var unitType
var abilities = []#[canCoast,canSea,canLand,canSettle] - change this? - TODO Why set here, why not just reference GC every time?
var viewRange = 2
var mountainViewRange = 3
#Visuals
onready var outlineMesh = get_node("Cube/Outline")

#--Operations--

func _ready():
	pass
	#newTurn() #TEST

func initialise(var pos, var hex, var UnitType, var Abilities): 
	transform.origin = pos 
	currentHex = hex
	unitType = UnitType
	abilities = Abilities
	newTurn()

func _process(delta):
	if camera.moved:
		selecting = false

func _physics_process(delta):
	if !hexPath.empty():
		if !isMoving: #When reached a hex or starting move
			highlightHexes(hexPath)
			targetHex = hexPath.pop_front()
			isMoving = true
			lookAtTarget(targetHex.pos())
	if targetHex != null:
		lerpToTarget(delta)

func newTurn():
	unHighlightHexes()
	movesLeft = moveRange
	viewHexes(currentHex)

func workHex():#(var hex): #TODO use hex or currentHex? 
	currentHex.beingWorked =  true 
	isWorking = true

func stopWork():
	currentHex.beingWorked = false
	isWorking = false
	#TODO maybe useAllMovement() but as the unit hasn't gathered anything that turn maybe not?

func settleHex():
	gc.spawnCity(currentHex)
	#TODO add visual change to worker
	unitType = gc.unitTypes.WORKER
	abilities = gc.unitData[unitType]["Abilities"]
	useAllMovement()

func useAllMovement(): #For any actions not movement that use all the units movePoints
	movesLeft = 0
	#TODO should I update the fact that you can no longer move here?
	#TEMP empty pos hexes
	unHighlightHexes()
	possibleHexes = []

func viewHexes(var hex):
	var hexes = []
	if currentHex.hexType == hexMap.MOUNTAIN:
		hexes = hexMap.getHexesWithinRangeOf(hex, mountainViewRange)
	else:
		hexes = hexMap.getHexesWithinRangeOf(hex, viewRange)
	for hex in hexes:
		hex.fog.inView(self)
	#Unview hexes
	for hex in viewedHexes:
		if !hexes.has(hex):
			hex.fog.unView(self)
	viewedHexes = hexes
	hexMap.refreshFogEdges() #Disable if using 2d Simple fog

#--Helpers--

func canWorkHex() -> bool: #TODO just use current hex? or pass hex
	var unlocked = gc.civBuffs["Can"][gc.biomeResString[currentHex.hexType]]
	return currentHex.resource != null && currentHex.city != null && unlocked

func canSettleHex() -> bool: #TODO anything else to check?
	return currentHex.city == null && currentHex.hexType != hexMap.COAST && currentHex.hexType != hexMap.SEA

func canMove() -> bool:
	if !hasMovesLeft():
		return false
	elif isWorking: 
		return false
	elif !getPosHexes().empty():
		return true
	else:
		return false

func hasMovesLeft() -> bool:
	return movesLeft > 0

func getPosHexes() -> Array:
	#var hexes = hexMap.getHexesWithinRangeOf(currentHex, moveRange)
	#Because of roads moveRange is doubled - maybe only get double range if roads are unlocked
	var hexes = hexMap.getHexesWithinRangeOf(currentHex, moveRange*2)
	var posHexes = []
	for h in hexes:
		if !canTraverse(h):
			continue
		else:
			posHexes.append(h)
	return pathfinder.oneTurnHexes(posHexes, currentHex, movesLeft) 

func canTraverse(var hex) -> bool:
	if hex.hexType == hexMap.COAST:
		return abilities[0] && gc.civBuffs["Can"]["Coast"]
	elif hex.hexType == hexMap.SEA:
		return abilities[1] && gc.civBuffs["Can"]["Sea"]
	elif hex.hexType == hexMap.MOUNTAIN:
		return abilities[2] && gc.civBuffs["Can"]["Climb"]
	return abilities[2]

func canBuildRoad() -> bool:
	if isWorking || currentHex.hasRoad || gc.playerResources[hexMap.resources.WOOD] < gc.roadCost + gc.civBuffs["Bonus"]["Road"] || currentHex.isCityCentre || !gc.civBuffs["Can"]["Road"]:#TODO add player check here and road tech - cheapest checks first
		return false #TODO should I just use 1 instead of hexMap.resources.WOOD
	elif currentHex.hexType == hexMap.MOUNTAIN || currentHex.hexType == hexMap.COAST || currentHex.hexType == hexMap.SEA:
		return false
	else: 
		var cityOrRoad = false
		var neighbours = hexMap.getNeighbours(currentHex)
		for n in neighbours:
			if n.hasRoad || n.isCityCentre:
				cityOrRoad = true
		return cityOrRoad
	#check if connects to another road?? - maybe don't allow road building just in random places, has to be contiguous 

func pos() -> Vector3:
	return currentHex.pos()

#--Movement--

func moveToHex(var hex): 
	hexPath = pathfinder.pathToHex(currentHex, hex)
	currentHex.removeUnit(self)
	unHighlightHexes()
	movesLeft -= pathfinder.costToHex(hex)
	currentHex = hex 
	hex.addUnit(self)
	#viewHexes()
	if canMove():
		possibleHexes = getPosHexes()
	else:
		possibleHexes = []
		deSelected() #TODO deselect from gamecontroller

func lerpToTarget(delta): #TODO make targetHex an input member
	if transform.origin.distance_to(targetHex.pos()) < lerpCutoff: 
		if hexPath.empty(): 
			highlightHexes(possibleHexes) #Highlight possible hexes when reached final hex
		viewHexes(targetHex)
		targetHex = null
		t = 0
		isMoving = false
	else:
		t += delta * moveSpeed
		var nextPos =  transform.origin.linear_interpolate(targetHex.pos(), moveSpeed) 
		transform.origin = Vector3(nextPos.x, transform.origin.y, nextPos.z)

func lookAtTarget(target):
	look_at(target, Vector3.UP)

#--Input--

func _on_StaticBody_input_event(camera, event, click_position, click_normal, shape_idx): #Maybe update to touch input
	if event is InputEventMouseButton:
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			selecting = true
			if event.doubleclick:
				camera.moveToObj(self) #TODO why jerky when lerping to hex??
		if Input.is_action_just_released("click") && selecting:
				gc.selectUnit(self)

func selected():
	isSelected = true
	highlight()
	if canMove(): #TEMP maybe not best method? - TODO not actually disallowing movement
		possibleHexes = getPosHexes()
		highlightHexes(possibleHexes)
	
func deSelected():
	isSelected =  false
	unHighlight()
	unHighlightHexes()

#--Visuals--
func highlight():
	outlineMesh.visible = true

func unHighlight():
	outlineMesh.visible = false

func highlightHexes(var hexes):#TODO maybe move this from unit?
	unHighlightHexes()
	highlightedHexes = []
	for hex in hexes:
		highlightedHexes.append(hex)
		hex.highlightHex(true)

func unHighlightHexes():
	for h in highlightedHexes:
		h.unHighlightHex(true)
