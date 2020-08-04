extends Spatial

var hex
var hexMap
var resource
#var units #TODO maybe should be just one??
var city

var fog
export (PackedScene) var edge
export (Material) var fogMat
export (Material) var halfFogMat
var isDiscovered = false
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
#	checkEdges()

func inView(var viewer):
	if !viewers.has(viewer):
		viewers.append(viewer)
	if isDiscovered:
		show()
	else:
		discover()

func unView(var viewer):
	viewers.erase(viewer)
	hide()

func show():
	hex.visible = true
	for unit in hex.units:
		unit.visible = true
	fog.visible = false
	#Edge
#	if !hexMap.edgeFog.has(self):
#		if isOnEdge():
#			hexMap.edgeFog.append(self)
	
func hide():
	if !isInView():
		fog.visible = true
		for unit in hex.units:
			unit.visible = false
	
	#Edge
#	if !hexMap.edgeFog.has(self):
#		if isOnEdge():
#			hexMap.edgeFog.append(self)
#	else:
#		if !isOnEdge():
#			hexMap.edgeFog.erase(self)
#			checkEdges()

	#check if neighbours should now be added to edges
#	for dir in range(hexMap.directions.size()): #NOT SURE IF NECESSARY
#		var neighbour = hexMap.getNeighbour(hex.q,hex.r,hexMap.directions[dir])
#		if neighbour != null:
#			var nFog = neighbour.fog
#			if !hexMap.edgeFog.has(nFog):
#				if isOnEdge():
#					hexMap.edgeFog.append(nFog)

func discover():
	isDiscovered = true
	fog.set_surface_material(0,halfFogMat)
	show()

#func checkEdges(): #TODO getting duplicate edges becuase instancing edges for self and neighbour?
#	for edge in edges.keys():
#		removeEdge(edge)
#
#	for dir in range(hexMap.directions.size()):
#		var neighbour = hexMap.getNeighbour(hex.q,hex.r,hexMap.directions[dir])
#		if neighbour != null:
#			var nFog = neighbour.fog
#			if !nFog.isInView():
#				if isInView():
#						instanceEdge(dir, nFog.isDiscovered) #TODO instancing double on edge of half fog
#				else:
#						if isDiscovered && !nFog.isDiscovered:
#							instanceEdge(dir, nFog.isDiscovered)
#		else: #We know we're at the edge of the map
#			if !isInView():
#				instanceEdge(dir, isDiscovered)


#func isOnEdge() -> bool:
#	for dir in range(hexMap.directions.size()):
#		var neighbour = hexMap.getNeighbour(hex.q,hex.r,hexMap.directions[dir])
#		if neighbour != null:
#			var nFog = neighbour.fog
#			if isInView() && !nFog.isInView():
#				return true
#			if !isInView() && !nFog.isInView():
#				if isDiscovered && !nFog.isDiscovered:
#					return true
#	return false 

#func instanceEdge(var dir, var discovered):
#	var e = edge.instance()
#	add_child(e)
#	if discovered:
#		e.get_node("Circle").set_surface_material(0,halfFogMat)
#	e.rotate_y(deg2rad(hexMap.rotations[dir]))
#	edges[dir] = e

#func removeEdge(var dir):
#	if edges.has(dir):
#		var e = edges[dir]
#		edges.erase(dir)
#		e.queue_free()

func isInView() -> bool:
	return !viewers.empty()
