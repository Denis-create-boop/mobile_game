extends SubViewportContainer

var game
var asset_library=preload("res://asset_library.gd").new()
var character_serial: int=0
var viewport: SubViewport
var stage: Node3D
var camera: Camera3D
var products: Array = []
var people: Array = []
var employees: Array = []
var last_stock: Array = []
var last_workers: int = -1
var extras: Array = []
var extra_goods: Array = []
var counters: Array = []
var loader: Node3D
var cleaner: Node3D
var loader_models: Array = []
var cleaner_models: Array = []
var focus := Vector3(0,0.5,0)
var focus_goal := Vector3(0,0.5,0)
var zoom_goal: float = 10.8
var floor_material: StandardMaterial3D
var materials: Dictionary = {}
var mesh_cache: Dictionary = {}
var scene_light: DirectionalLight3D
var quality_high: bool = true
var crates: Array = []
var dirt_marks: Array = []
var delivery_boxes: Array = []
var tick: float = 0.0
var build_pads: Array = []
var annex: Node3D
var built_racks: Array = []
var built_items: Array = []
var truck: Node3D
var warehouse_extra: Array = []
var orbit: float = 0.65
var camera_zoom: float = 16.5
var popups: Array = []
var last_placements: Array = []
var mouse_down := Vector2.ZERO
var status_label: Label
var sales_label: Label

func _ready():
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	viewport = SubViewport.new()
	viewport.size = Vector2i(640,420)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	stage = Node3D.new()
	viewport.add_child(stage)
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#a9c4cd")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#c4d5d4")
	e.ambient_light_energy = 0.48
	env.environment = e
	stage.add_child(env)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-57,-38,0)
	light.light_energy = 0.82
	scene_light=light
	light.shadow_enabled = true
	light.directional_shadow_max_distance=30.0
	light.shadow_bias=0.25
	light.shadow_normal_bias=1.0
	stage.add_child(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.8
	camera.position = Vector3(10,12,14)
	stage.add_child(camera)
	camera.look_at_from_position(Vector3(16,15,18),Vector3(3,0.3,0))
	camera.current = true
	build_store()
	build_extension()
	decorate_store()
	add_details()
	add_landscaping()
	add_merchandising()
	reset_view()
	status_label = Label.new()
	status_label.position = Vector2(12,8)
	status_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	status_label.add_theme_font_size_override("font_size",18)
	status_label.add_theme_color_override("font_color",Color("#fff1d8"))
	status_label.add_theme_color_override("font_shadow_color",Color("#172b32"))
	status_label.add_theme_constant_override("shadow_offset_x",1)
	status_label.add_theme_constant_override("shadow_offset_y",2)
	add_child(status_label)
	sales_label = Label.new()
	sales_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	sales_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	sales_label.position = Vector2(12, size.y-30)
	sales_label.add_theme_color_override("font_color",Color("#ffffff"))
	sales_label.add_theme_color_override("font_shadow_color",Color("#172b32"))
	sales_label.add_theme_constant_override("shadow_offset_x",1)
	sales_label.add_theme_constant_override("shadow_offset_y",2)
	add_child(sales_label)

func reset_view():
	orbit=0.70
	camera_zoom=10.5
	zoom_goal=10.5
	focus=Vector3(-0.5,0.5,0.3)
	focus_goal=focus
	update_camera()

func overview():
	focus_goal=Vector3(2.5,0.5,0)
	zoom_goal=17.0

func zoom(factor: float):
	zoom_goal=clampf(zoom_goal*factor,6,23)

func rotate_view(direction: int):
	orbit=clampf(orbit+direction*0.35,-0.45,1.45)
	update_camera()

func update_camera():
	camera.size=camera_zoom
	var target=focus
	camera.look_at_from_position(target+Vector3(sin(orbit)*17,14,cos(orbit)*17),target)

func _gui_input(event):
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT)!=0 and game.build_kind<0:
		orbit=clampf(orbit-event.relative.x*0.004,-0.45,1.45)
		update_camera()
	elif event is InputEventScreenDrag and game.build_kind<0:
		orbit=clampf(orbit-event.relative.x*0.004,-0.45,1.45)
		update_camera()
	if event is InputEventMouseButton:
		if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP:
			zoom(0.9)
		elif event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			zoom(1.1)
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				mouse_down=event.position
			elif mouse_down.distance_to(event.position)<12:
				select_pad(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			mouse_down=event.position
		elif mouse_down.distance_to(event.position)<12:
			select_pad(event.position)

func select_pad(pos: Vector2):
	if game.build_kind<0 or camera==null:
		return
	var pixel=pos*Vector2(viewport.size)/size
	var origin=camera.project_ray_origin(pixel)
	var direction=camera.project_ray_normal(pixel)
	if absf(direction.y)<0.001:
		return
	var point=origin+direction*(-origin.y/direction.y)
	for i in range(game.active_slots()):
		var pad: Vector3=game.build_slot(i)
		if absf(point.x-pad.x)<1.18 and absf(point.z-pad.z)<0.85:
			game.place_equipment(i)
			return

func mat(color: Color) -> StandardMaterial3D:
	if materials.has(color):
		return materials[color]
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.82
	materials[color]=m
	return m

func mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.mesh = shape
	n.material_override = mat(color)
	parent.add_child(n)
	n.position = pos
	return n

func box(parent: Node3D, pos: Vector3, dims: Vector3, color: Color) -> MeshInstance3D:
	var key="box:"+str(dims)
	if not mesh_cache.has(key):
		var b=BoxMesh.new()
		b.size=dims
		mesh_cache[key]=b
	return mesh(parent,mesh_cache[key],pos,color)

func ball(parent: Node3D, pos: Vector3, dims: Vector3, color: Color) -> MeshInstance3D:
	if not mesh_cache.has("sphere"):
		var b=SphereMesh.new()
		b.radius=0.5
		b.height=1.0
		b.radial_segments=20
		b.rings=10
		mesh_cache["sphere"]=b
	var n=mesh(parent,mesh_cache["sphere"],pos,color)
	n.scale = dims
	return n

func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var key="cylinder:"+str(radius)+":"+str(height)
	if not mesh_cache.has(key):
		var b=CylinderMesh.new()
		b.top_radius=radius
		b.bottom_radius=radius
		b.height=height
		b.radial_segments=16
		mesh_cache[key]=b
	return mesh(parent,mesh_cache[key],pos,color)

func sign_text(parent: Node3D, pos: Vector3, value: String, color: Color, pixel: float = 0.006):
	var n = Label3D.new()
	n.text = value
	n.font_size = 48
	n.pixel_size = pixel
	n.modulate = color
	n.outline_size = 0
	n.no_depth_test = false
	parent.add_child(n)
	n.position = pos

func build_store():
	var wood = Color("#bb8961")
	var mint = Color("#398675")
	var cream = Color("#cdbda2")
	box(stage,Vector3(0,-0.32,0),Vector3(10.4,0.5,8.4),Color("#688e82"))
	make_floor(stage,Vector3(0,-0.05,0),Vector2(10,8),Color("#c3ae91"))
	box(stage,Vector3(0,0.95,-4.0),Vector3(10.3,1.9,0.18),cream)
	box(stage,Vector3(-5,0.95,0),Vector3(0.18,1.9,8),cream)
	box(stage,Vector3(0,1.98,-4.0),Vector3(10.45,0.17,0.29),mint)
	box(stage,Vector3(-5,1.98,0),Vector3(0.29,0.17,8.1),mint)
	for x in [-3.6,-0.1,3.4]:
		box(stage,Vector3(x,1.05,-3.88),Vector3(2.2,1.15,0.05),Color("#d0c9b5"))
		box(stage,Vector3(x,1.05,-3.84),Vector3(2.0,0.96,0.06),Color("#88c2cf"))
		box(stage,Vector3(x,1.05,-3.79),Vector3(0.06,0.96,0.04),cream)
		box(stage,Vector3(x,1.05,-3.79),Vector3(2.0,0.06,0.04),cream)
	for i in range(3):
		var x = -3.25 + i*3.1
		var shelf = Node3D.new()
		stage.add_child(shelf)
		shelf.position = Vector3(x,0,-2.1)
		box(shelf,Vector3(0,0.9,-0.38),Vector3(2.4,1.8,0.12),wood)
		for y in [0.22,0.83,1.44]:
			box(shelf,Vector3(0,y,0),Vector3(2.5,0.11,0.95),cream)
			box(shelf,Vector3(0,y,0.48),Vector3(2.5,0.12,0.055),mint)
		for edge in [-1.19,1.19]:
			box(shelf,Vector3(edge,0.9,0),Vector3(0.10,1.8,0.94),wood)
		box(shelf,Vector3(0,1.87,0),Vector3(2.5,0.28,0.95),mint)
		sign_text(shelf,Vector3(0,1.88,0.49),game.GOODS[i],Color.WHITE,0.0045)
		var row: Array = []
		for j in range(12):
			var item = Node3D.new()
			shelf.add_child(item)
			item.position = Vector3(-0.88+(j%4)*0.58,0.29+floori(j/4.0)*0.61,0.07)
			if asset_library.food(i,item,Vector3.ZERO)!=null:
				pass
			elif i==0:
				ball(item,Vector3(0,0.15,0),Vector3(0.42,0.3,0.55),Color("#c88a43"))
				for k in range(3):
					var mark = box(item,Vector3(-0.12+k*0.12,0.29,0),Vector3(0.04,0.015,0.21),Color("#f3cc87"))
					mark.rotation.y = 0.5
			elif i==1:
				box(item,Vector3(0,0.20,0),Vector3(0.29,0.4,0.28),Color("#d9e5df"))
				box(item,Vector3(0,0.20,0.15),Vector3(0.28,0.17,0.02),Color("#64a8d7"))
				cylinder(item,Vector3(0,0.43,0),0.07,0.06,Color("#438cb8"))
			else:
				for k in range(2):
					ball(item,Vector3(-0.10+k*0.20,0.13,0),Vector3(0.24,0.25,0.25),Color("#d85b50").lightened(k*0.12))
					box(item,Vector3(-0.10+k*0.20,0.27,0),Vector3(0.025,0.06,0.025),wood)
					ball(item,Vector3(-0.06+k*0.20,0.27,0),Vector3(0.11,0.035,0.06),mint)
			row.append(item)
		products.append(row)
		var expansions: Array = []
		var more_goods: Array = []
		for k in range(2):
			var extra = Node3D.new()
			stage.add_child(extra)
			extra.position = Vector3(x,0,-2.1-float(k+1)*0.48)
			# Expanded rack rises above the original shelf.
			box(extra,Vector3(0,2.15+k*0.45,0.25),Vector3(2.5,0.12,0.8),mint)
			for j in range(12):
				var product = Node3D.new()
				extra.add_child(product)
				product.position=Vector3(-0.96+(j%6)*0.38,2.30+k*0.45,0.08+floori(j/6.0)*0.3)
				ball(product,Vector3.ZERO,Vector3(0.25,0.25,0.25),game.COLORS[i])
				more_goods.append(product)
			extra.visible=false
			expansions.append(extra)
		extras.append(expansions)
		extra_goods.append(more_goods)
	for i in range(3):
		var counter = Node3D.new()
		stage.add_child(counter)
		counter.position = game.counter(i)
		if asset_library.spawn("market",["checkout","cashregister","counter"],counter,Vector3.ZERO,Vector3(2.3,1.3,0.85))==null:
			box(counter,Vector3(0,0.48,0),Vector3(2.2,0.96,0.8),mint)
			box(counter,Vector3(0,1.0,0),Vector3(2.3,0.13,0.85),cream)
			box(counter,Vector3(-0.3,1.09,0),Vector3(1.2,0.07,0.6),Color("#39484b"))
			box(counter,Vector3(0.7,1.27,0),Vector3(0.45,0.35,0.12),Color("#263b42"))
		sign_text(counter,Vector3(0,0.55,0.43),"КАССА "+str(i+1),Color.WHITE,0.005)
		counters.append(counter)
		counter.visible = i<game.workers
	# Warehouse and delivery zone.
	box(stage,Vector3(-4.4,0.06,1.2),Vector3(0.95,0.1,1.4),Color("#b69367"))
	sign_text(stage,Vector3(-4.4,1.1,1.4),"СКЛАД",Color("#243841"),0.006)
	for i in range(9):
		var crate=box(stage,Vector3(-4.6+(i%2)*0.43,0.27+floori(i/4.0)*0.42,0.65+(floori(i/2.0)%2)*0.48),Vector3(0.39,0.4,0.43),wood)
		crates.append(crate)
	box(stage,Vector3(-4.4,0.04,-0.4),Vector3(0.95,0.08,1.0),Color("#e7bb69"))
	sign_text(stage,Vector3(-4.4,0.65,-0.2),"ПОСТАВКА",Color("#243841"),0.004)
	for i in range(3):
		delivery_boxes.append(box(stage,Vector3(-4.4,0.25+i*0.38,-0.45),Vector3(0.65,0.36,0.6),wood))
	for i in range(6):
		dirt_marks.append(ball(stage,Vector3(-3+i*0.95,0.012,0.3+sin(i)*0.7),Vector3(0.45,0.02,0.3),Color("#98876c")))
	for pos in [Vector3(-4.25,0,3),Vector3(4.3,0,-3.15)]:
		cylinder(stage,pos+Vector3(0,0.22,0),0.25,0.44,wood)
		for j in range(5):
			var angle = j*TAU/5
			ball(stage,pos+Vector3(cos(angle)*0.18,0.65+0.06*(j%2),sin(angle)*0.18),Vector3(0.27,0.68,0.23),mint.lightened(j*0.05))
	for i in range(3):
		var employee = person(Color("#408e7c"))
		employee.position = Vector3(3.8-i*1.1,0,1.3)
		employee.visible = false
		employees.append(employee)
		add_carry(employee)
	for i in range(3):
		var model=person(Color("#cb8b42"))
		add_carry(model)
		model.visible=false
		loader_models.append(model)
		var janitor=person(Color("#718fc1"))
		var broom=box(janitor,Vector3(0.34,0.45,0.16),Vector3(0.055,0.95,0.055),wood)
		broom.rotation.z=-0.3
		box(janitor,Vector3(0.48,0.08,0.16),Vector3(0.25,0.12,0.2),Color("#c59e65"))
		add_carry(janitor)
		janitor.visible=false
		cleaner_models.append(janitor)

func decorate_store():
	var wood=Color("#886449")
	var trim=Color("#3c7264")
	var gold=Color("#d7ad68")
	# Storefront lettering, wall trim and a small entrance mat.
	box(stage,Vector3(0,2.35,-3.84),Vector3(4.8,0.62,0.20),trim)
	sign_text(stage,Vector3(0,2.35,-3.72),"MARKET EMPIRE",Color("#f3dfb0"),0.008)
	box(stage,Vector3(-3.5,0.025,3.44),Vector3(1.8,0.03,0.75),trim)
	for x in [-4.75,4.75,12.3]:
		box(stage,Vector3(x,0.12,-3.65),Vector3(0.22,0.25,0.45),wood)
	# Warehouse racks in separate rear service zone.
	box(stage,Vector3(-6.65,0.85,-3.75),Vector3(2.8,1.7,0.18),Color("#9daca5"))
	box(stage,Vector3(-8.0,0.85,0),Vector3(0.18,1.7,7.5),Color("#9daca5"))
	sign_text(stage,Vector3(-6.65,1.45,-3.6),"DELIVERY",Color("#f1d3a0"),0.006)
	for z in [0.6,2.0]:
		for y in [0.18,0.85]:
			box(stage,Vector3(-7.5,y,z),Vector3(0.65,0.10,1.2),wood)
		for dz in [-0.54,0.54]:
			box(stage,Vector3(-7.5,0.5,z+dz),Vector3(0.07,1.0,0.07),trim)
	for x in [-2.0,1.0,4.0,7.0,10.0]:
		box(stage,Vector3(x,0.018,3.9),Vector3(0.65,0.025,0.07),gold)

func build_extension():
	var cream=Color("#cdbda2")
	var mint=Color("#398675")
	var wood=Color("#b88c62")
	# Additional retail wing with accessible construction pads.
	box(stage,Vector3(8.6,-0.29,0),Vector3(8.2,0.48,8.4),Color("#688e82"))
	make_floor(stage,Vector3(8.6,-0.05,0),Vector2(8.2,8),Color("#c3ae91"))
	box(stage,Vector3(8.6,0.85,-4),Vector3(8.3,1.7,0.18),cream)
	box(stage,Vector3(8.6,1.77,-4),Vector3(8.3,0.12,0.26),mint)
	annex=Node3D.new()
	stage.add_child(annex)
	box(annex,Vector3(8.6,-0.29,5.8),Vector3(8.2,0.48,4.4),Color("#688e82"))
	make_floor(annex,Vector3(8.6,-0.05,5.8),Vector2(8.2,4.4),Color("#c3ae91"))
	for i in range(12):
		var center: Vector3=game.build_slot(i)
		var pad=box(stage,center+Vector3(0,0.015,0),Vector3(2.4,0.035,1.65),Color("#91bdab"))
		build_pads.append(pad)
		built_racks.append(null)
		built_items.append([])
	# External loading bay, vehicle and warehouse extension.
	box(stage,Vector3(-6.65,-0.25,0),Vector3(3.0,0.4,8.4),Color("#a6adac"))
	box(stage,Vector3(-6.65,0.02,-0.4),Vector3(2.6,0.08,5.8),Color("#bdc4be"))
	for i in range(2):
		var unit=Node3D.new()
		stage.add_child(unit)
		unit.position=Vector3(-6.3,0,1.8+i*1.15)
		box(unit,Vector3(0,0.1,0),Vector3(1.8,0.18,1.05),wood)
		for j in range(4):
			box(unit,Vector3(-0.42+(j%2)*0.82,0.45+floori(j/2.0)*0.54,0),Vector3(0.76,0.5,0.8),wood.lightened(j*0.035))
		warehouse_extra.append(unit)
	truck=Node3D.new()
	stage.add_child(truck)
	box(truck,Vector3(0,0.56,0),Vector3(1.45,0.3,3.2),Color("#46535a"))
	box(truck,Vector3(0,1.22,-0.35),Vector3(1.5,1.25,2.05),cream)
	box(truck,Vector3(0,0.98,1.02),Vector3(1.48,1.08,0.95),mint)
	box(truck,Vector3(0,1.23,1.51),Vector3(1.25,0.37,0.04),Color("#90c8dd"))
	for x in [-0.74,0.74]:
		for z in [-0.95,1.05]:
			var wheel=cylinder(truck,Vector3(x,0.35,z),0.32,0.18,Color("#253238"))
			wheel.rotation.z=PI/2
	sign_text(truck,Vector3(0,1.32,-1.39),"MARKET",mint,0.004)
	truck.visible=false

func install_rack(slot: int, kind: int):
	var rack=Node3D.new()
	stage.add_child(rack)
	rack.position=game.build_slot(slot)
	var color=Color("#63a9c4") if kind in [1,3,8,11] else Color("#398675")
	var cream=Color("#f1e8d4")
	var height=1.15 if kind in [2,7] else 1.8
	box(rack,Vector3(0,height/2,-0.36),Vector3(2.25,height,0.12),color)
	for x in [-1.09,1.09]:
		box(rack,Vector3(x,height/2,0),Vector3(0.1,height,0.9),color)
	var items: Array=[]
	for y in [0.22,0.75,1.28]:
		var yy: float=y*0.62 if kind in [2,7] else y
		box(rack,Vector3(0,yy,0),Vector3(2.25,0.09,0.9),cream)
		for j in range(4):
			var p=Vector3(-0.79+j*0.52,yy+0.18,0.04)
			var item: Node3D=asset_library.food(kind,rack,p-Vector3(0,0.16,0))
			if item!=null:
				pass
			elif kind==1:
				item=box(rack,p,Vector3(0.29,0.32,0.27),Color("#a5d4ea"))
			elif kind==0:
				item=ball(rack,p,Vector3(0.4,0.26,0.46),Color("#d39b54"))
			elif kind==2:
				item=ball(rack,p,Vector3(0.31,0.3,0.31),Color("#d85b50"))
			else:
				var colors=[Color("#e9bf61"),Color("#f29b4d"),Color("#704b36"),Color("#874b51"),Color("#71a85c"),Color("#d2a3c6"),Color("#568a63"),Color("#dbb56d"),Color("#8ecedb")]
				if kind in [7]:
					item=ball(rack,p,Vector3(0.34,0.27,0.34),colors[kind-3])
				else:
					item=box(rack,p,Vector3(0.28,0.32,0.25),colors[kind-3])
			items.append(item)
	box(rack,Vector3(0,height+0.04,0),Vector3(2.25,0.16,0.92),color)
	sign_text(rack,Vector3(0,height+0.04,0.47),game.GOODS[kind],Color.WHITE,0.004)
	built_racks[slot]=rack
	built_items[slot]=items

func person(color: Color) -> Node3D:
	var p = Node3D.new()
	stage.add_child(p)
	p.scale=Vector3(1.18,1.18,1.18)
	var names: Array=[]
	var entries: Dictionary=asset_library.catalog.get("people",{})
	for key in entries:
		if not String(key).contains("wheelchair") and not String(key).contains("skeleton") and not String(key).contains("animation"):
			names.append(key)
	if not names.is_empty():
		var model=asset_library.spawn("people",[names[character_serial%names.size()]],p,Vector3.ZERO,Vector3(0.70,1.46,0.66))
		character_serial+=1
		if model!=null:
			p.set_meta("model",model)
			var animations=model.find_children("*","AnimationPlayer",true,false)
			if not animations.is_empty():
				p.set_meta("animation",animations[0])
			return p
	var skin = Color("#eac1a2")
	var pants = Color("#364d60")
	var left = Node3D.new()
	var right = Node3D.new()
	p.add_child(left)
	p.add_child(right)
	left.position = Vector3(-0.13,0.5,0)
	right.position = Vector3(0.13,0.5,0)
	for leg in [left,right]:
		cylinder(leg,Vector3(0,-0.20,0),0.085,0.4,pants)
		ball(leg,Vector3(0,-0.42,0.045),Vector3(0.2,0.15,0.31),Color("#293b40"))
	p.set_meta("left",left)
	p.set_meta("right",right)
	ball(p,Vector3(0,0.72,0),Vector3(0.47,0.57,0.32),color)
	box(p,Vector3(0,0.51,0),Vector3(0.35,0.065,0.28),Color("#263d43"))
	box(p,Vector3(-0.10,0.82,0.16),Vector3(0.10,0.075,0.015),Color("#eee4d3"))
	for direction in [-1,1]:
		var arm = cylinder(p,Vector3(direction*0.27,0.70,0),0.07,0.38,color)
		arm.rotation.z = direction*0.22
		ball(p,Vector3(direction*0.30,0.48,0),Vector3(0.13,0.15,0.13),skin)
	cylinder(p,Vector3(0,1.00,0),0.085,0.13,skin)
	ball(p,Vector3(0,1.19,0),Vector3(0.36,0.40,0.35),skin)
	ball(p,Vector3(0,1.30,-0.055),Vector3(0.38,0.26,0.34),Color("#574137"))
	ball(p,Vector3(0,1.14,0.17),Vector3(0.055,0.07,0.055),skin.darkened(0.08))
	for side in [-1,1]:
		ball(p,Vector3(side*0.18,1.18,0),Vector3(0.07,0.11,0.08),skin)
	for direction in [-1,1]:
		ball(p,Vector3(direction*0.07,1.21,0.16),Vector3(0.035,0.045,0.025),Color("#3f3530"))
	return p

func add_carry(p: Node3D):
	var b=box(p,Vector3(0,0.72,0.3),Vector3(0.32,0.28,0.28),Color("#c99458"))
	b.visible=false
	p.set_meta("carry",b)

func actor(p: Node3D, target: Vector3, carrying: bool, dt: float):
	var direction=target-p.position
	var walking=direction.length()>0.001
	if walking:
		p.rotation.y=atan2(direction.x,direction.z)
	if p.has_meta("left"):
		p.get_meta("left").rotation.x=sin(tick*12)*0.5 if walking else 0
		p.get_meta("right").rotation.x=-sin(tick*12)*0.5 if walking else 0
	elif p.has_meta("animation"):
		var player: AnimationPlayer=p.get_meta("animation")
		var wanted="walk" if walking else "idle"
		for animation in player.get_animation_list():
			if String(animation).to_lower().contains(wanted):
				if player.current_animation!=animation or not player.is_playing():
					player.play(animation)
				break
	p.position=target
	p.get_meta("carry").visible=carrying

func _process(delta):
	if not is_instance_valid(game) or status_label==null:
		return
	tick+=delta
	if game.build_kind>=0:
		focus_goal=Vector3(8.4,0.5,2.2 if game.area_level>=2 else 0)
		zoom_goal=maxf(zoom_goal,14.0 if game.area_level>=2 else 11.5)
	elif focus_goal.x>5:
		focus_goal=Vector3(0,0.5,0)
		zoom_goal=10.8
	focus=focus.lerp(focus_goal,minf(1,delta*4))
	camera_zoom=lerpf(camera_zoom,zoom_goal,minf(1,delta*6))
	update_camera()
	var displayed=[12,12,12,0,0,0,0,0,0,0,0,0]
	annex.visible=game.area_level>=2
	for i in range(12):
		var kind: int=game.placements[i]
		build_pads[i].visible=game.build_kind>=0 and kind<0 and i<game.active_slots()
		if kind>=0:
			if built_racks[i]==null:
				install_rack(i,kind)
			for j in range(built_items[i].size()):
				built_items[i][j].visible=displayed[kind]+j<game.stock[kind]
			displayed[kind]+=12
	for i in range(warehouse_extra.size()):
		warehouse_extra[i].visible=game.warehouse_level>i+1
	var at_dock: bool=game.sum_items(game.delivery)>0 or game.unloading()
	truck.visible=game.delivery_eta>0 or at_dock
	truck.position=Vector3(-6.6,0,lerpf(-1.6,7.0,clampf(game.delivery_eta/game.delivery_duration,0,1))) if game.delivery_eta>0 and not at_dock else Vector3(-6.6,0,-1.6)
	for event in game.payment_events:
		var tag=Label3D.new()
		tag.text="+"+str(event["amount"])
		tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		tag.font_size=64
		tag.pixel_size=0.009
		tag.modulate=Color("#f7d26a")
		tag.outline_size=8
		stage.add_child(tag)
		tag.position=event["pos"]+Vector3(0,2,0)
		popups.append({"node":tag,"life":1.6})
	game.payment_events.clear()
	for popup in popups:
		popup["life"]-=delta
		popup["node"].position.y+=delta*0.8
		if popup["life"]<=0:
			popup["node"].queue_free()
	popups=popups.filter(func(p): return p["life"]>0)
	for i in range(3):
		for j in range(products[i].size()):
			products[i][j].visible=j<game.stock[i]
		for k in range(2):
			extras[i][k].visible=false
		for j in range(extra_goods[i].size()):
			extra_goods[i][j].visible=j+12<game.stock[i]
		employees[i].visible=i<game.workers
		counters[i].visible=i<game.workers
		if i<game.sellers.size():
			var s=game.sellers[i]
			actor(employees[i],s["pos"],s["carry"],delta)
		delivery_boxes[i].visible=game.sum_items(game.delivery)>i*5
	for i in range(crates.size()):
		crates[i].visible=game.sum_items(game.storage)>i*4
	for i in range(dirt_marks.size()):
		dirt_marks[i].visible=game.dirt>i*15+8
	for i in range(3):
		loader_models[i].visible=i<game.loader_tasks.size()
		cleaner_models[i].visible=i<game.cleaner_tasks.size()
		if i<game.loader_tasks.size():
			var task=game.loader_tasks[i]
			actor(loader_models[i],task["pos"],task["amount"]>0,delta)
		if i<game.cleaner_tasks.size():
			var task=game.cleaner_tasks[i]
			actor(cleaner_models[i],task["pos"],false,delta)
	while people.size()<game.customers.size():
		var p=person(Color("#d78c71").lerp(Color("#759cc9"),float(people.size()%4)/3.0))
		add_carry(p)
		var tag=Label3D.new()
		tag.position=Vector3(0,1.8,0)
		tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		tag.font_size=42
		tag.pixel_size=0.006
		tag.modulate=Color("#fff5cc")
		tag.outline_modulate=Color("#263b42")
		tag.outline_size=8
		p.add_child(tag)
		p.set_meta("order",tag)
		people.append(p)
	while people.size()>game.customers.size():
		people.pop_back().queue_free()
	for i in range(people.size()):
		var c=game.customers[i]
		actor(people[i],c["pos"],c["carry"],delta)
		var tag: Label3D=people[i].get_meta("order")
		tag.text=game.GOODS[c["item"]] if c["phase"]<4 and not c["carry"] else ("Оплата" if c["carry"] and c["phase"]<4 else "")
	status_label.text="МАГАЗИН ОТКРЫТ" if game.running else "МАГАЗИН ЗАКРЫТ"
	sales_label.position=Vector2(12,size.y-28)
	sales_label.text="Выручка: %d мон. | Клиентов: %d" % [game.revenue,game.customers.size()]


func add_details():
	var dark=Color("#314a4b")
	var wood=Color("#a17b50")
	var cream=Color("#e5d3b0")
	# Platform skirt, front entrance and shop identity.
	box(stage,Vector3(0,-0.14,4.13),Vector3(10.3,0.27,0.12),dark)
	for x in [-4.7,-2.1]:
		box(stage,Vector3(x,0.95,3.8),Vector3(0.16,1.9,0.20),dark)
	box(stage,Vector3(-3.4,1.96,3.8),Vector3(2.75,0.18,0.24),dark)
	for i in range(9):
		box(stage,Vector3(-4.6+i*0.3,2.14,3.85),Vector3(0.29,0.09,0.54),cream if i%2==0 else Color("#4d8a76"))
	# Price strips, shelf labels, support legs and floor skirting.
	for i in range(3):
		var x=-3.25+i*3.1
		for y in [0.22,0.83,1.44]:
			for j in range(4):
				box(stage,Vector3(x-0.87+j*0.58,y, -1.59),Vector3(0.22,0.08,0.025),cream)
		for dx in [-1.0,1.0]:
			box(stage,Vector3(x+dx,0.07,-2.1),Vector3(0.12,0.14,0.64),dark)
	box(stage,Vector3(0,0.11,-3.79),Vector3(10.1,0.20,0.12),wood)
	# Customer baskets and nested handles near the entrance.
	for i in range(3):
		var y=0.12+i*0.13
		box(stage,Vector3(-2.5,y,3.65),Vector3(0.46,0.13,0.35),Color("#b67948"))
		for x in [-0.18,0.18]:
			box(stage,Vector3(-2.5+x,y+0.09,3.65),Vector3(0.035,0.17,0.035),dark)
		box(stage,Vector3(-2.5,y+0.17,3.65),Vector3(0.38,0.035,0.035),dark)
	# Loading bay road markings and cardboard packing tape.
	for z in [-2.8,-1.6,-0.4,0.8,2.0,3.2]:
		box(stage,Vector3(-5.4,0.025,z),Vector3(0.07,0.025,0.65),cream)
	for crate in crates:
		box(crate,Vector3(0,0.205,0),Vector3(0.08,0.012,0.43),Color("#ddc18c"))

func toggle_quality():
	quality_high=not quality_high
	viewport.msaa_3d=Viewport.MSAA_4X if quality_high else Viewport.MSAA_DISABLED
	scene_light.shadow_enabled=quality_high
	stretch_shrink=1 if quality_high else 2

# A single textured floor surface replaces hundreds of individual tile meshes.
func make_floor(parent: Node3D, pos: Vector3, dimensions: Vector2, base: Color):
	var plane=PlaneMesh.new()
	plane.size=dimensions
	var tile=mesh(parent,plane,pos+Vector3(0,0.055,0),base)
	var shader=Shader.new()
	shader.code="""shader_type spatial;
render_mode diffuse_burley;
uniform vec3 tint : source_color;
varying vec3 world_position;
void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 coord=world_position.xz;
 vec2 cell=floor(coord);
 vec2 uv=fract(coord);
 float edge=min(min(uv.x,1.0-uv.x),min(uv.y,1.0-uv.y));
 float grout=smoothstep(0.012,0.028,edge);
 float variation=fract(sin(dot(cell,vec2(12.9898,78.233)))*43758.5453);
 float grain=0.0;
 vec3 tile_color=tint*(0.92+variation*0.10+grain);
 ALBEDO=mix(tint*0.60,tile_color,grout);
 ROUGHNESS=0.86;
}"""
	var material=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("tint",base)
	tile.material_override=material

func add_landscaping():
	var asphalt=Color("#526366")
	var grass=Color("#658b68")
	var concrete=Color("#b7b2a2")
	box(stage,Vector3(2,-0.56,1),Vector3(24,0.2,17),grass)
	box(stage,Vector3(2,-0.43,6.5),Vector3(23.5,0.13,4.7),asphalt)
	box(stage,Vector3(2,-0.33,4.45),Vector3(23.5,0.18,0.65),concrete)
	for i in range(12):
		box(stage,Vector3(-8+i*1.8,-0.35,7.2),Vector3(0.9,0.025,0.07),Color("#e4d9aa"))
	for pos in [Vector3(-8.5,-0.3,-4.7),Vector3(3.9,-0.3,-5.1),Vector3(12.8,-0.3,-4.8)]:
		cylinder(stage,pos+Vector3(0,0.8,0),0.13,1.6,Color("#805d43"))
		ball(stage,pos+Vector3(0,1.9,0),Vector3(1.5,1.75,1.5),grass.darkened(0.12))
		ball(stage,pos+Vector3(0.36,1.6,0.13),Vector3(0.9,1.0,1.0),grass.lightened(0.12))
	# Warm metal bins and a little storefront bench.
	box(stage,Vector3(-0.8,0.28,4.12),Vector3(1.7,0.13,0.42),Color("#a8794b"))
	for x in [-1.5,-0.1]:
		box(stage,Vector3(x,0.03,4.12),Vector3(0.1,0.45,0.35),Color("#39494c"))


func add_merchandising():
	var teal=Color("#225d57")
	var ivory=Color("#fff0d4")
	var accent=Color("#e6a64e")
	for i in range(3):
		var x=-3.25+i*3.1
		box(stage,Vector3(x,2.04,-2.1),Vector3(2.52,0.08,0.98),teal)
		for j in range(4):
			for y in [0.22,0.83,1.44]:
				box(stage,Vector3(x-0.88+j*0.58,y,-1.60),Vector3(0.19,0.065,0.018),ivory)
		box(stage,Vector3(x,0.015,-1.36),Vector3(2.35,0.018,0.14),accent)
	for x in [-3.5,0.0,3.5]:
		box(stage,Vector3(x,1.72,-3.74),Vector3(1.55,0.09,0.15),teal)
		box(stage,Vector3(x,1.68,-3.65),Vector3(1.40,0.045,0.06),ivory)
	var display=Node3D.new()
	stage.add_child(display)
	display.position=Vector3(-4.38,0,-3.22)
	if asset_library.spawn("market",["basket","shoppingbasket"],display,Vector3.ZERO,Vector3(0.62,0.55,0.62))==null:
		box(display,Vector3(0,0.17,0),Vector3(0.58,0.34,0.48),teal)
		box(display,Vector3(0,0.36,0),Vector3(0.60,0.05,0.50),accent)
