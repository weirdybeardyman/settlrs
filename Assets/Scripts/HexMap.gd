extends Node

export (PackedScene) var hexGrass
export (PackedScene) var hexDesert
export (PackedScene) var hexForest
export (PackedScene) var hexMountain
export (PackedScene) var hexTundra
export (PackedScene) var hexSea
export (PackedScene) var hexCoast
onready var biomes = [hexSea, hexCoast, hexGrass, hexMountain, hexDesert, hexForest, hexTundra]
enum {SEA,COAST,GRASS,MOUNTAIN,DESERT,FOREST,TUNDRA}
enum resources {FOOD,WOOD,ORE,GOLD}
#TODO array of moisture and elevation to hexType
export (Array, PackedScene) var wheatModels
export (Array, PackedScene) var fishModels
export (Array, PackedScene) var woodModels
export (Array, PackedScene) var oreModels
export (Array, PackedScene) var goldModels
onready var resourceModels = {GRASS:wheatModels,SEA:fishModels,COAST:fishModels,FOREST:woodModels,MOUNTAIN:oreModels,TUNDRA:goldModels,DESERT:goldModels}
var movementCosts = {SEA:2.0,COAST:1.0,GRASS:1.0,MOUNTAIN:2.0,DESERT:1.0,FOREST:2.0,TUNDRA:1.0}
var biomeResources = {SEA:resources.FOOD,COAST:resources.FOOD,GRASS:resources.FOOD,MOUNTAIN:resources.ORE,DESERT:resources.GOLD,FOREST:resources.WOOD,TUNDRA:resources.GOLD}
#TODO make biome and tile data a JSON?

export (Array, PackedScene) var edgeModels #coast, sea, ground, beach

var mapCols = 30 #TODO Change just to mapRadius or Diameter
var mapRows = 30
var hexes = [] 
var directions = [[1,-1], [1,0], [0,1],[-1,1],[-1,0],[0,-1]]
var rotations = [0,-60,-120,-180,-240,-300] #Could just do i*60
#var rotations = [0,PI/3,(PI*2)/3,PI,(PI*4)/3,(PI*5)/3] #in radians
#generators
var rng = RandomNumberGenerator.new()
var noise = OpenSimplexNoise.new()
var terraMap
var tempMap

var seaLevel = 0
var deepSeaLevel = -0.1
var hillHeight = 0.25
var mountainHeight = 0.4
var desertTemp = 0.25
var tundraTemp = -0.2

var mapGenerated = false

func _ready():
	rng.randomize()
	terraMap = genNoiseMap(20,-168) 		#TODO simplify? TEMP seed
	tempMap = genNoiseMap(20,-152) 		#---  simplify
	genMap()						#--- unify with noisemap?

#Map Generation

func genNoiseMap(var detail = 20, var s = rng.randi_range(-200,200)):
	noise.seed = s
	print(s)
	noise.octaves = 4
	noise.period = detail
	noise.persistence = 0.8
	#return hexagonMap() #- have to adjust genTerrain and other loops to fit this
	return rhombusMap()

func rhombusMap():
	var tiles = []
	for q in range(mapCols):
		tiles.append([])
		for r in range(mapRows):
			tiles[q].append(noise.get_noise_2d(q,r))
	return tiles
	
#func hexagonMap():
#	var tiles = []
#	for q in range(mapCols): 
#		tiles.append([])
#		var r1 = max(0, -q - mapRows)
#		var r2 = min(mapRows, -q + mapRows)
#		for r in range(r1,r2):
#			tiles[q].append(noise.get_noise_2d(q,r))
#	return tiles

#rectangle map

func genMap():
	for q in range(terraMap.size()):
		hexes.append([])
		for r in range(terraMap[q].size()):
			var type = tileType(q,r)
			var resourceType = biomeResources[type]
			var resource = null
			var resourceAmt = 0
			if resourceType == resources.GOLD: #TODO change and simplify method
				resourceAmt = rng.randi_range(0,6)-3#(0,24)-21 - TEMP common for debugging
			else:
				resourceAmt = rng.randi_range(0,6)-3 #TODO change from hard coded values like this
			if resourceAmt > 0:
				resource =  resourceType
			else:
				resourceAmt = 0
				#TEMP forest method
				if type == FOREST:
					resourceAmt = 1
					resource = biomeResources[type]
			var h = biomes[type].instance() #TODO maybe move these out to instance tile func for saveloading as well
			hexes[q].append(h)
			add_child(h)
			h.setup(q,r,type,movementCosts[type],resource,resourceAmt) #using the the q,r like this means I probs can't use an iterator for different map shapes
			#TODO - maybe put on hex?
			if resourceAmt > 0 && resource != null:
				var res = resourceModels[type][resourceAmt-1].instance()
				h.add_child(res)
				res.name = "res"
				#res.transform.origin = h.pos()
	genEdges()
	mapGenerated = true

func tileType(var q, var r):
	#Elevation
	var elevation = terraMap[q][r]
	if  elevation < deepSeaLevel: #-0.1
		return SEA
	elif elevation < seaLevel: #0
		return COAST
	#Temperature
	var temp = tempMap[q][r]
	if elevation < hillHeight:  
		if temp > desertTemp: 
			return DESERT
		else:
			return GRASS
	elif elevation < mountainHeight:
		if temp > tundraTemp:
			return FOREST
		else:
			return TUNDRA
	else:
		return MOUNTAIN

#TODO need to store in hex for saving probably
func genEdges(): #Do just per hex? but has to be done after complete map generation
	for q in hexes:
		for hex in q:
			for dir in range(directions.size()):
				#var n = getNeighbour(hex, directions[dir])
				var n = getNeighbour(hex.q, hex.r, directions[dir])
				if n == null:
					if hex.hexType == COAST: #instance 0 - Coast edge
						instanceEdge(hex,0,dir)
					elif hex.hexType == SEA: #instance 1 - Sea edge
						instanceEdge(hex,1,dir)
					else: #instance 2 - ground edge
						instanceEdge(hex,2,dir)
				elif hex.hexType != COAST && hex.hexType != SEA:
					if n.hexType == COAST || n.hexType == SEA: #instance 3 - beach edge
						instanceEdge(hex,3,dir)

func instanceEdge(var hex, var edgeType, var dir):
	var edge = edgeModels[edgeType].instance()
	hex.add_child(edge)
	edge.rotate_y(deg2rad(rotations[dir]))
	hex.edges.append([edgeType,dir])

#Accesing Map helper functions

func getHexAt(var q, var r):
	if hexes == null:
		print("Trying to get hex before map is created")
	if q < hexes.size() && q > -1:
		if r < hexes[q].size() && r > -1:
			return hexes[q][r] #this func is essentially just this with some error checking
		else:
			return null

func getNeighbours(var hex): #Duplicate code from pathfinderGraph - TODO check if necessary
	var hexArr = []
	for dir in range(directions.size()):
		var h = getHexAt(hex.q + directions[dir][0], hex.r + directions[dir][1])
		if h != null:
			hexArr.append(h)
	return hexArr

#func getNeighbour(var hex, var dir):  -TODO which is better? passing hex or passing ints?
#	return getHexAt(hex.q + dir[0], hex.r + dir[1])

func getNeighbour(var q, var r, var dir):
	return getHexAt(q + dir[0], r + dir[1])

func getHexesWithinRangeOf(var centre, var rg):
	rg += 1  #Is the +1 apropriate? - because this is including the centre hex
	var hexArr = []
	for dq in range(-rg,rg-1):
		for dr in range(max(-rg+1,-dq-rg), min(rg,-dq+rg-1)):
			var h = getHexAt(centre.q + dq+1, centre.r + dr)
			if h != null:
				hexArr.append(h)
	return hexArr

func distance(var hexA, var hexB): #Needed?
	var dists = [abs(hexA.q - hexB.q),abs(hexA.r - hexB.r),abs(hexA.s - hexB.s)]
	return dists.max()
	
func getExtremes(): #TODO should actually be easy to calculate just using q and r values, recheck how hex.pos() works
	var extremes = []
	#extremes.append(getHexAt(0,0).pos())
	extremes.append(hexes[0][0].pos()) #TODO make four points if using rhombus map
	extremes.append(hexes[-1][-1].pos())
	return extremes
