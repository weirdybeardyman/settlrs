#extends Node

var directions = [[1,-1], [1,0], [0,1],[-1,1],[-1,0],[0,-1]]
var start
#var hexes = {} #hex obj, cost - change to just q,r?
var hexes = []
var cameFrom = {}
var costSoFar = {}

func populate(var hexarr, var start):
#	var arr = {}
#	arr[[start.q],[start.r]] = start.movementCost
#	for hex in hexarr:
#		arr[[hex.q],[hex.r]] = hex.movementCost
	
	#hexes = arr
	hexes = hexarr
	hexes.append(start)

#func cost(var hex): #Obselete if using hex objects as nodes
#	return hex.movementCost

func getHexAt(var q, var r): #TODO change
	for hex in hexes:
		if hex.q == q && hex.r == r:
			return hex
	return null
#	TODO change implementation
#Use dictionary with q,r array as key

func getNeighbours(var hex):
	var hexArr = []
	for dir in directions:
		var neighbour = getHexAt(hex.q + dir[0], hex.r + dir[1])
		if neighbour != null:
			hexArr.append(neighbour)
	return hexArr
