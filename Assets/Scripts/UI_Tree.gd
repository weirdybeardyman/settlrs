extends Control

export (PackedScene) var techScene
var techs = []
onready var rows = get_node("Rows")
onready var treeName = get_node("Rows/TreeName")

func populateTree(var tree, var TreeName):
	treeName.text = str(TreeName)
	var parent = null #TODO JSON's don't keep order so will need to encode parent data in JSON
	for tech in tree:
		var t = techScene.instance()
		rows.add_child(t)
		techs.append(t)
		t.technology = tech
		var techData  = tree[tech]
		t.cost = techData[0] 
		t.unlocked = techData[1]
		t.contextTxt = techData[2]
		t.buffType = techData[3]
		t.buffKey = techData[4]
		t.buffValue = techData[5]
		t.parent = parent
		parent = t
	updateTree()

func updateTree():
	for tech in techs:
		tech.update()
