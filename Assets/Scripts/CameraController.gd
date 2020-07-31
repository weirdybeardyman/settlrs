extends Camera

var target = null
var moveSpeed = 0.08
var lerpCutoff = 0.88
var t = 0.0
var lastTouchPos
var touchPos
var ray_length = 150
onready var hexMap = get_parent().get_node("Map")
var maxZoom = 8
var minZoom = 4
var zoomSensitivity = 10
var zoomMulti = 0.15 #TEMP only for Testing
var events = {}
var lastDragDist = 0
var maxX 
var maxY
var minX
var minY
var moved = false
var lastPosition #is this used??

func _ready():
	pass

func moveToObj(obj):
	target = obj.pos()

func lerpToTarget(delta):
	if t >= lerpCutoff:
		target = null
		t = 0
	else:
		t += delta * moveSpeed
		var nextPos =  transform.origin.linear_interpolate(target, moveSpeed) # change that so it lerps to centre of screen
		transform.origin = Vector3(nextPos.x, transform.origin.y, nextPos.z)

func getMouseRay(var pos = null): #TODO test for mouse zooming
	var mouse_pos = get_viewport().get_mouse_position()
	var from = self.project_ray_origin(mouse_pos)
	var to = from + self.project_ray_normal(mouse_pos) * ray_length
	var space_state = get_world().get_direct_space_state()
	var results =  space_state.intersect_ray(from, to)
	if results.size() > 0:
		return results["position"]
	else:
		return pos
	
func _process(delta):
	if maxX == null && hexMap.mapGenerated:
		var extremes = hexMap.getExtremes()
		maxX = extremes[1].x
		maxY = extremes[1].z
		minX = extremes[0].x
		minY = extremes[0].z
	moved = lastPosition != transform.origin #TODO when is this used??
	lastPosition = transform.origin

func _physics_process(delta):
	if target != null:
		lerpToTarget(delta)

func moveCamera(var vector): 
	vector.x  = clamp(vector.x, minX, maxX)
	vector.y = clamp(vector.y, minZoom, maxZoom) 
	vector.z = clamp(vector.z, minY, maxY)
	transform.origin = vector

func getRayPos(var screenPos) -> Vector3:
	var from = self.project_ray_origin(screenPos)
	var to = from + self.project_ray_normal(screenPos) * ray_length
	var space_state = get_world().get_direct_space_state()
	var results =  space_state.intersect_ray(from, to)
	if results.size() > 0:
		return results["position"]
	else:
		return Vector3.ZERO #null equivilant

func getEventPos() -> Vector3:
	if events.size() == 1:
		return getRayPos(events[0].position)
	elif events.size() == 2:
		var e1 = getRayPos(events[0].position)
		var e2 = getRayPos(events[1].position)
		return e1 + (e2 - e1) / 2 #Midpoint
	else:
		return Vector3.ZERO

func getZoomDist() -> Vector3:
	var e1 = getRayPos(events[0].position)
	var e2 = getRayPos(events[1].position)
	return e1.distance_to(e2)

func _input(event):
	if event is InputEventMouseButton: 
		#TODO for testing
		if event.button_index == BUTTON_WHEEL_DOWN:
			var delta = Vector3(transform.origin - getMouseRay(transform.origin))*zoomMulti
			var dir = transform.origin + delta
			moveCamera(dir)
		if event.button_index == BUTTON_WHEEL_UP:
			var delta = Vector3(transform.origin - getMouseRay(transform.origin))*zoomMulti
			var dir = transform.origin - delta
			moveCamera(dir)

func _unhandled_input(event):
	#Touch
	if event is InputEventScreenTouch:
		if event.pressed:
			events[event.index] = event
			target = null
			#reset touch positions
			touchPos = getEventPos()
			lastTouchPos = touchPos
			if events.size() == 2:
#				#Zoom Reset
				var dragDist = getZoomDist()
				lastDragDist = dragDist
		else:
			events.erase(event.index)
			touchPos = getEventPos()
			lastTouchPos = touchPos
	
	#Pan and Zoom
	if event is InputEventScreenDrag:
		events[event.index] = event
		if events.size() < 3: 
			touchPos = getEventPos()
			var touchDelta = lastTouchPos - touchPos
			var dir = Vector3(transform.origin.x + touchDelta.x, transform.origin.y, transform.origin.z + touchDelta.z)
			moveCamera(dir)
			lastTouchPos = getEventPos()
			if events.size() == 2:
				#Zoom
				var eventPos = getEventPos()
				var dragDist = getZoomDist()
				if lastDragDist == 0:
					lastDragDist = dragDist
				var zoomDelta = dragDist - lastDragDist
				var delta = Vector3(transform.origin - eventPos) * (zoomDelta/dragDist)
				moveCamera(transform.origin - delta)
				lastDragDist = getZoomDist()
