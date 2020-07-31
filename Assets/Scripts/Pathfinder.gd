extends Node

onready var graph = load("res://Assets/Scripts/PathfinderGraph.gd").new()

func oneTurnHexes(var hexes, var start, var moveRange): 
	#init
	graph.populate(hexes, start)
	var frontier = []
	frontier.append([start,0])
	var cameFrom = {}
	cameFrom[start] = null
	var costSoFar = {}
	costSoFar[start] = 0
	
	while not frontier.empty():
		var current = frontier.pop_front()[0] #TODO should I use the index?
		for next in graph.getNeighbours(current): 
			var newCost = costSoFar[current] + next.movementCost()#graph.cost(next) #TODO change
			if !next in costSoFar or newCost < costSoFar[next]:
				costSoFar[next] = newCost
				var priority = newCost
				frontier.append([next, priority])
				cameFrom[next] = current
		frontier.sort_custom(self,"queueSort")
	
	graph.costSoFar = {}
	for cost in costSoFar: 
		if costSoFar[cost] <= moveRange && cost != start:
			graph.costSoFar[cost] = costSoFar[cost]
	
	graph.cameFrom = cameFrom 
	return  graph.costSoFar.keys()

func costToHex(var goal): 
	return graph.costSoFar[goal]

func pathToHex(var start, var goal):
	var current = goal
	var path = []
	while current != start:
		path.append(current)
		current =  graph.cameFrom[current]
	path.invert()
	return path

static func queueSort(a,b):
	if a[1] < b[1]:
		return true
	return false
