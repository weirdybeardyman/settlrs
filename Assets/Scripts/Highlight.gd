extends Spatial

#onready var pos =  preload("res://Assets/Materials/posHighlight.tres")
export (Material) var black
export (Material) var white 
export (Material) var green
export (Material) var city #TODO change city colour based on civ/player

onready var baseMat = black

onready var mesh = get_node("Circle") #should this be onready? or just var

var isSelected
var isPossible
#var isCity
#func mouseOver() -> bool:
	#return get_node("Circle2").get_surface_material(0) == pos

#func possible():
#	get_node("Circle2").set_surface_material(0,pos)

func madeCity():
	baseMat = city
	if !isSelected && !isPossible:
		mesh.set_surface_material(0,baseMat)

func select():
	isSelected = true
	mesh.set_surface_material(0,white)

func deSelect():
	isSelected = false
	if isPossible:
		mesh.set_surface_material(0,green)
	else:
		mesh.set_surface_material(0,baseMat)

func possible():
	isPossible =  true
	if !isSelected:
		mesh.set_surface_material(0,green)

func dePossible():
	isPossible = false
	if !isSelected:
		mesh.set_surface_material(0,baseMat)
