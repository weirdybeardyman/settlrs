extends Control

export (PackedScene) var treeScene

var trees = []
onready var columns = get_node("Container/Columns")

func populateTechTree(var techDict):
	for tree in techDict:
		var t = treeScene.instance()
		columns.add_child(t)
		trees.append(t)
		t.populateTree(techDict[tree], tree)

#--Visuals--#

func updateTechTree():
	for tree in trees:
		tree.updateTree()

func openMenu():
	updateTechTree()
	visible = true

func _on_Close_pressed():
	visible = false
