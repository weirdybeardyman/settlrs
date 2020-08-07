extends Spatial

var hex
var hexMap
var resource
var city

var fog
export (PackedScene) var edge
export (Material) var halfFogMat
var isDiscovered = false
var onEdge
var viewers = []
var edges = {}

func initialise(var Hex): #TODO send discovered when loading game - arr of booleans 
	hex = Hex
	hexMap = hex.hexMap
	#units = hex.units
	fog = get_node("Circle")
	hex.visible = false
	for unit in hex.units: #Currently occuring before test unit is spawned in
		unit.visible = false

func inView(var viewer):
	if !viewers.has(viewer):
		viewers.append(viewer)
	if isDiscovered:
		show()
	else:
		discover()

func unView(var viewer):
	viewers.erase(viewer)
	if !isInView():
		hide()

func show():
	hex.visible = true
	for unit in hex.units:
		unit.visible = true
	fog.visible = false
	
func hide():
	fog.visible = true
	for unit in hex.units:
		unit.visible = false

func discover():
	isDiscovered = true
	hexMap.fog.append(self) #Small optimisation - only check edges if have been discovered - will bloat as you explore map
	fog.set_surface_material(0,halfFogMat)
	show()

func refreshEdges(): #Disable if using 2d Simple fog
	clearEdges()
	for dir in range(hexMap.directions.size()):
		var neighbour = hexMap.getNeighbour(hex.q,hex.r,hexMap.directions[dir])
		if neighbour != null:
			var nFog = neighbour.fog
			if !nFog.isInView():
				if isInView():
						instanceEdge(dir, nFog.isDiscovered)
				else:
						if isDiscovered && !nFog.isDiscovered:
							instanceEdge(dir, nFog.isDiscovered)
		else: #We know we're at the edge of the map
			if !isInView():
				instanceEdge(dir, isDiscovered)

func clearEdges():
	for edge in edges.keys():
		removeEdge(edge)

func instanceEdge(var dir, var discovered): #Disable if using 2d Simple fog
	var e = edge.instance()
	add_child(e)
	if discovered:
		e.get_node("Circle").set_surface_material(0,halfFogMat)
	e.rotate_y(deg2rad(hexMap.rotations[dir]))
	edges[dir] = e

func removeEdge(var dir): #Disable if using 2d Simple fog
	if edges.has(dir):
		var e = edges[dir]
		edges.erase(dir)
		e.queue_free()

func isInView() -> bool:
	return !viewers.empty()
