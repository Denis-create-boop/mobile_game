extends Control

var game
var premium_models: Dictionary = {}
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
var render_surface: TextureRect
var render_size: Vector2i = Vector2i.ZERO
var resize_clock: float = 0.0
var crates: Array = []
var dirt_marks: Array = []
var delivery_boxes: Array = []
var tick: float = 0.0
var build_pads: Array = []
var annex: Node3D
var land_wings: Array[Node3D] = []
var land_signs: Array[Node3D] = []
var parking: Node3D
var parking_sign: Node3D
var traffic: Array[Node3D] = []
var traffic_rng := RandomNumberGenerator.new()
var traffic_timers: Array[float] = [0.2, 1.1, 0.7, 1.8, 2.4, 3.1]
var road_parts: Array[Node3D] = []
var cross_roots: Array[Node3D] = []
var signal_lamps: Array[MeshInstance3D] = []
var main_cross_marks: Array[MeshInstance3D]=[]
var street_people: Array[Node3D] = []
var signal_phase: int = 0
var signal_time: float = 0.0
var district_models: Array[Node3D] = []
var facade_title: Label3D
var facade_tiers: Array[Node3D] = []
var expansion_base: Node3D
var adjacent_plots: Array[Node3D] = []
var plot_markers: Array[Node3D] = []
var growth_tiles: Array[Node3D] = []
var last_road: int = 0
var last_cross: int = -1
const CROSS_X: float = -3.4
var traffic_speeds: Dictionary = {}
var built_racks: Array = []
var built_items: Array = []
var truck: Node3D
var warehouse_extra: Array = []
var orbit: float = 0.65
var camera_zoom: float = 16.5
var popups: Array = []
var last_placements: Array = []
var mouse_down := Vector2.ZERO
var pointer_travel: float = 0.0
var last_build_kind: int = -1
var status_label: Label
var sales_label: Label

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	viewport = SubViewport.new()
	viewport.size = Vector2i(960,640)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_DISABLED if OS.has_feature("web") else Viewport.MSAA_2X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	render_surface=TextureRect.new()
	render_surface.texture=viewport.get_texture()
	render_surface.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	render_surface.stretch_mode=TextureRect.STRETCH_SCALE
	render_surface.mouse_filter=Control.MOUSE_FILTER_IGNORE
	render_surface.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(render_surface)
	render_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage = Node3D.new()
	viewport.add_child(stage)
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#353b43")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#f0f2f5")
	e.ambient_light_energy = 0.48
	env.environment = e
	stage.add_child(env)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-57,-38,0)
	light.light_energy = 0.64
	light.light_color=Color("#fff8ef")
	scene_light=light
	light.shadow_enabled = not OS.has_feature("web")
	light.directional_shadow_max_distance=30.0
	light.shadow_bias=0.10
	light.shadow_normal_bias=1.0
	stage.add_child(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near=0.1
	camera.far=400.0
	camera.size = 10.8
	camera.position = Vector3(10,12,14)
	stage.add_child(camera)
	camera.look_at_from_position(Vector3(16,15,18),Vector3(3,0.3,0))
	camera.current = true
	load_premium_models()
	build_store()
	build_extension()
	if not premium_models.has("shell"):
		decorate_store()
		add_details()
	add_landscaping()
	build_city()
	build_neighborhood()
	build_infrastructure()
	build_district()
	if not premium_models.has("shelf"):
		add_merchandising()
	build_architecture()
	reset_view()
	print("Market assets loaded: ",asset_library.catalog.get("market",{}).size())
	status_label = Label.new()
	status_label.position = Vector2(12,53)
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
	camera_zoom=12.5
	zoom_goal=12.5
	focus=Vector3(-0.5,0.5,0.3)
	focus_goal=focus
	update_camera()

func overview():
	focus_goal=Vector3(3,0.5,5)
	zoom_goal=62.0

func zoom(factor: float):
	zoom_goal=clampf(zoom_goal*factor,4.5,72.0)

func rotate_view(direction: int):
	orbit=wrapf(orbit+direction*0.35,-PI,PI)
	update_camera()

func update_camera():
	camera.size=clampf(camera_zoom,4.5,72.0)
	var target=focus
	var distance: float=maxf(1.0,camera.size/14.0)
	camera.look_at_from_position(target+Vector3(sin(orbit)*17,14,cos(orbit)*17)*distance,target)

func pan_map(relative: Vector2):
	if camera==null or size.y<2:
		return
	var right: Vector3=camera.global_transform.basis.x
	var up: Vector3=camera.global_transform.basis.y
	right.y=0
	up.y=0
	var units: float=camera_zoom/size.y
	var offset: Vector3=(-right.normalized()*relative.x+up.normalized()*relative.y)*units
	focus_goal+=offset
	focus_goal.x=clampf(focus_goal.x,-32.0,42.0)
	focus_goal.z=clampf(focus_goal.z,-32.0,36.0)
	focus=focus_goal
	update_camera()

func _gui_input(event):
	if event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_RIGHT)!=0:
			orbit=wrapf(orbit-event.relative.x*0.004,-PI,PI)
			update_camera()
			accept_event()
		elif (event.button_mask & MOUSE_BUTTON_MASK_LEFT)!=0 or (event.button_mask & MOUSE_BUTTON_MASK_MIDDLE)!=0:
			pointer_travel+=event.relative.length()
			pan_map(event.relative)
			accept_event()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP:
			zoom(0.9)
		elif event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
			zoom(1.1)
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				mouse_down=event.position
				pointer_travel=0.0
			elif pointer_travel<8.0 and mouse_down.distance_to(event.position)<8.0:
				select_pad(event.position)
		accept_event()
	elif event is InputEventScreenDrag:
		pointer_travel+=event.relative.length()
		pan_map(event.relative)
		accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			mouse_down=event.position
			pointer_travel=0.0
		elif pointer_travel<8.0 and mouse_down.distance_to(event.position)<8.0:
			select_pad(event.position)
		accept_event()

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
	m.roughness = 0.67
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
		b.radial_segments=12 if OS.has_feature("web") else 20
		b.rings=6 if OS.has_feature("web") else 10
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
	var wood = Color("#9c714a")
	var mint = Color("#343b43")
	var cream = Color("#8d959d")
	if not spawn_premium("shell",stage,Vector3.ZERO,0.0):
		box(stage,Vector3(0,-0.32,0),Vector3(10.4,0.5,8.4),Color("#8f969b"))
		make_floor(stage,Vector3(0,-0.05,0),Vector2(10,8),Color("#545e66"))
		box(stage,Vector3(0,0.95,-4.0),Vector3(10.3,1.9,0.18),cream)
		box(stage,Vector3(-5,0.95,0),Vector3(0.18,1.9,8),cream)
		box(stage,Vector3(0,1.98,-4.0),Vector3(10.45,0.17,0.29),mint)
		box(stage,Vector3(-5,1.98,0),Vector3(0.29,0.17,8.1),mint)
		for x in [-3.6,-0.1,3.4]:
			box(stage,Vector3(x,1.05,-3.88),Vector3(2.2,1.15,0.05),Color("#c7cdd2"))
			box(stage,Vector3(x,1.05,-3.84),Vector3(2.0,0.96,0.06),Color("#93b7ce"))
			box(stage,Vector3(x,1.05,-3.79),Vector3(0.06,0.96,0.04),cream)
			box(stage,Vector3(x,1.05,-3.79),Vector3(2.0,0.06,0.04),cream)
	for i in range(3):
		var x = -3.25 + i*3.1
		var section_color: Color=[Color("#c98b42"),Color("#4386ad"),Color("#6f9855")][i]
		var shelf = Node3D.new()
		stage.add_child(shelf)
		shelf.position = Vector3(x,0,-2.1)
		var fixture_ok: bool=spawn_premium("cold" if i==1 else "shelf",shelf,Vector3.ZERO,0.0)
		if not fixture_ok:
			fixture_ok=asset_library.spawn("market",["shelfboxes" if i!=1 else "freezersstanding"],shelf,Vector3.ZERO,Vector3(2.5,1.82,0.95))!=null
		if not fixture_ok:
			box(shelf,Vector3(0,0.9,-0.38),Vector3(2.4,1.8,0.12),wood)
			for y in [0.22,0.83,1.44]:
				box(shelf,Vector3(0,y,0),Vector3(2.5,0.11,0.95),cream)
				box(shelf,Vector3(0,y,0.48),Vector3(2.5,0.12,0.055),mint)
			for edge in [-1.19,1.19]:
				box(shelf,Vector3(edge,0.9,0),Vector3(0.10,1.8,0.94),wood)
			box(shelf,Vector3(0,1.87,0),Vector3(2.5,0.28,0.95),mint)
		box(shelf,Vector3(0,1.88,0.48),Vector3(2.5,0.23,0.12),section_color)
		sign_text(shelf,Vector3(0,1.88,0.55),game.GOODS[i],Color.WHITE,0.0045)
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
		if not spawn_premium("checkout",counter,Vector3.ZERO,PI/2) and asset_library.spawn("market",["checkout","cashregister","counter"],counter,Vector3.ZERO,Vector3(2.3,1.3,0.85))==null:
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
	var wood=Color("#66584c")
	var trim=Color("#34475a")
	var gold=Color("#c8a46c")
	# Storefront lettering, wall trim and a small entrance mat.
	box(stage,Vector3(0,2.35,-3.84),Vector3(4.8,0.62,0.20),trim)
	sign_text(stage,Vector3(0,2.35,-3.72),"MARKET EMPIRE",Color("#f4f4f4"),0.008)
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
	var cream=Color("#8d959d")
	var mint=Color("#343b43")
	var wood=Color("#a98c72")
	# Connected strips along the right edge of the original shop.
	expansion_base=Node3D.new()
	stage.add_child(expansion_base)
	annex=Node3D.new()
	stage.add_child(annex)
	for i in range(4):
		var strip=Node3D.new()
		stage.add_child(strip)
		var x: float=6.5+i*3.0
		box(strip,Vector3(x,-0.25,0.8),Vector3(3.0,0.4,9.6),Color("#a4a8a9"))
		make_floor(strip,Vector3(x,-0.05,0.8),Vector2(3.0,9.6),Color("#e8e4dc"))
		box(strip,Vector3(x,1.0,-4.0),Vector3(3.0,2.0,0.18),cream)
		box(strip,Vector3(x,2.08,-4.0),Vector3(3.0,0.16,0.25),mint)
		adjacent_plots.append(strip)
		var marker=Node3D.new()
		stage.add_child(marker)
		box(marker,Vector3(x,-0.28,0.8),Vector3(2.94,0.13,9.54),Color("#afbb91"))
		for z in [-3.9,5.5]:
			box(marker,Vector3(x,-0.18,z),Vector3(2.9,0.035,0.08),Color("#f9e4a3"))
		var tag=Label3D.new()
		tag.text="РАСШИРЕНИЕ"
		tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		tag.font_size=42
		tag.pixel_size=0.009
		marker.add_child(tag)
		tag.position=Vector3(x,0.45,1.0)
		plot_markers.append(marker)
	for i in range(24):
		var center: Vector3=game.build_slot(i)
		var pad=box(stage,center+Vector3(0,0.015,0),Vector3(2.4,0.035,1.65),Color("#92b5d5"))
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
	var color=Color("#63a9c4") if kind in [1,3,8,11] else Color("#343b43")
	var cream=Color("#f1e8d4")
	var height=1.15 if kind in [2,7] else 1.8
	var fixture_names=["displayfruit"] if kind in [2,7] else (["freezersstanding"] if kind in [1,3,8,11] else ["shelfboxes"])
	var fixture_ok: bool=spawn_premium("cold" if kind in [1,3,8,11] else "shelf",rack,Vector3.ZERO,0.0,Vector3(0.90,1.0,1.0))
	if not fixture_ok:
		fixture_ok=asset_library.spawn("market",fixture_names,rack,Vector3.ZERO,Vector3(2.25,height,0.9))!=null
	if not fixture_ok:
		box(rack,Vector3(0,height/2,-0.36),Vector3(2.25,height,0.12),color)
		for x in [-1.09,1.09]:
			box(rack,Vector3(x,height/2,0),Vector3(0.1,height,0.9),color)
	var items: Array=[]
	for y in [0.22,0.75,1.28]:
		var yy: float=y if premium_models.has("shelf") else (y*0.62 if kind in [2,7] else y)
		if not fixture_ok:
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
	var p=Node3D.new()
	stage.add_child(p)
	var serial: int=character_serial
	character_serial+=1
	var stature: float=[0.96,1.02,1.09,1.0][serial%4]
	p.scale=Vector3(stature,stature,stature)
	var skin: Color=[Color("#e8bc99"),Color("#bc8968"),Color("#8e6046"),Color("#d6a582")][serial%4]
	var hair: Color=[Color("#3c2b24"),Color("#272427"),Color("#806044"),Color("#b49b79")][serial%4]
	var pants: Color=[Color("#303e49"),Color("#545653"),Color("#38444d")][serial%3]
	var shoe=Color("#292d31")
	for side in [-1,1]:
		var leg=Node3D.new()
		p.add_child(leg)
		leg.position=Vector3(side*0.105,0.79,0)
		var thigh=cylinder(leg,Vector3(0,-0.19,0),0.092,0.38,pants)
		thigh.scale.z=0.93
		var shin=Node3D.new()
		leg.add_child(shin)
		shin.position=Vector3(0,-0.38,0)
		cylinder(shin,Vector3(0,-0.17,0),0.071,0.34,pants)
		ball(shin,Vector3(0,-0.33,0.06),Vector3(0.18,0.13,0.31),shoe)
		p.set_meta("left" if side==-1 else "right",leg)
		p.set_meta("left_knee" if side==-1 else "right_knee",shin)
	ball(p,Vector3(0,0.81,0),Vector3(0.40,0.22,0.27),pants)
	ball(p,Vector3(0,1.09,0),Vector3(0.43,0.55,0.29),color)
	box(p,Vector3(0,0.88,0.13),Vector3(0.31,0.035,0.035),pants)
	var seam=color.darkened(0.25)
	box(p,Vector3(0,1.10,0.151),Vector3(0.012,0.38,0.012),seam)
	for side in [-1,1]:
		var arm=Node3D.new()
		p.add_child(arm)
		arm.position=Vector3(side*0.225,1.28,0)
		arm.rotation.z=side*0.11
		ball(arm,Vector3(0,-0.13,0),Vector3(0.15,0.31,0.16),color)
		cylinder(arm,Vector3(0,-0.34,0.015),0.057,0.22,color.darkened(0.05))
		ball(arm,Vector3(0,-0.49,0.025),Vector3(0.12,0.16,0.115),skin)
		p.set_meta("left_arm" if side==-1 else "right_arm",arm)
		var collar=box(p,Vector3(side*0.075,1.34,0.11),Vector3(0.12,0.08,0.025),color.lightened(0.24))
		collar.rotation.z=side*0.35
	cylinder(p,Vector3(0,1.39,0),0.074,0.14,skin)
	ball(p,Vector3(0,1.53,0.012),Vector3(0.245,0.30,0.245),skin)
	ball(p,Vector3(0,1.62,-0.018),Vector3(0.26,0.17,0.25),hair)
	if serial%3==1:
		ball(p,Vector3(0,1.47,-0.095),Vector3(0.25,0.32,0.11),hair)
	for side in [-1,1]:
		ball(p,Vector3(side*0.119,1.53,0),Vector3(0.045,0.068,0.045),skin)
		ball(p,Vector3(side*0.044,1.55,0.122),Vector3(0.027,0.015,0.014),Color("#35302d"))
	ball(p,Vector3(0,1.51,0.131),Vector3(0.035,0.049,0.043),skin)
	if serial%4==0:
		box(p,Vector3(-0.11,1.18,0.15),Vector3(0.095,0.052,0.016),Color("#eee5d5"))
	return p

func add_carry(p: Node3D):
	var b=box(p,Vector3(0,0.93,0.33),Vector3(0.32,0.28,0.28),Color("#c99458"))
	b.visible=false
	p.set_meta("carry",b)

func actor(p: Node3D, target: Vector3, carrying: bool, dt: float):
	var direction=target-p.position
	var walking=direction.length()>0.001
	if walking:
		p.rotation.y=atan2(direction.x,direction.z)
	if p.has_meta("left"):
		var stride: float=sin(tick*10.0)*0.40 if walking else 0.0
		p.get_meta("left").rotation.x=stride
		p.get_meta("right").rotation.x=-stride
		if p.has_meta("left_knee"):
			p.get_meta("left_knee").rotation.x=maxf(0.0,-stride)*0.65
			p.get_meta("right_knee").rotation.x=maxf(0.0,stride)*0.65
			p.get_meta("left_arm").rotation.x=-stride*0.75 if not carrying else -0.85
			p.get_meta("right_arm").rotation.x=stride*0.75 if not carrying else -0.85
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
	resize_clock+=delta
	if resize_clock>=0.20:
		resize_clock=0.0
		update_render_resolution()
	if game.build_kind!=last_build_kind:
		last_build_kind=game.build_kind
		if game.build_kind>=0:
			focus_goal=Vector3(8.4,0.5,float(game.area_level-1)*2.5)
			zoom_goal=maxf(zoom_goal,11.5+float(game.area_level-1)*4.0)
	focus=focus.lerp(focus_goal,minf(1,delta*4))
	camera_zoom=lerpf(camera_zoom,zoom_goal,minf(1,delta*6))
	update_camera()
	var displayed=[12,12,12,0,0,0,0,0,0,0,0,0]
	var owned: int=ceili(float(game.active_slots())/6.0)
	for i in range(adjacent_plots.size()):
		adjacent_plots[i].visible=i<owned
		plot_markers[i].visible=i==owned
	var tier: int=0
	match game.business_name():
		"Магазин": tier=1
		"Мини-маркет": tier=2
		"Супермаркет": tier=3
		"Торговый центр": tier=4
	facade_title.text=game.business_name().to_upper()
	for i in range(facade_tiers.size()):
		facade_tiers[i].visible=i==tier
	annex.visible=game.area_level>=2
	for i in range(land_wings.size()):
		land_wings[i].visible=game.area_level>=i+3
		land_signs[i].visible=not land_wings[i].visible
	parking.visible=game.parking_owned
	parking_sign.visible=not game.parking_owned
	for i in range(district_models.size()):
		district_models[i].visible=game.district_units[i]
	for i in range(growth_tiles.size()):
		growth_tiles[i].visible=game.land_steps>=19+i
	update_infrastructure(delta)
	update_traffic(delta)
	update_neighborhood_traffic(delta)
	for i in range(24):
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
	status_label.text=("МАГАЗИН ОТКРЫТ" if game.running else "МАГАЗИН ЗАКРЫТ")+" | V33 • 3D: %d / резерв: %d" % [asset_library.loaded_count,asset_library.fallback_count]
	sales_label.position=Vector2(12,size.y-26)
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
		box(stage,Vector3(-4.6+i*0.3,2.14,3.85),Vector3(0.29,0.09,0.54),cream if i%2==0 else Color("#536e89"))
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
	viewport.msaa_3d=Viewport.MSAA_2X if quality_high and not OS.has_feature("web") else Viewport.MSAA_DISABLED
	scene_light.shadow_enabled=quality_high and not OS.has_feature("web")
	update_render_resolution()

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
 float aa=max(fwidth(edge),0.001);
 float grout=smoothstep(0.009-aa,0.016+aa,edge);
 float variation=fract(sin(dot(cell,vec2(12.9898,78.233)))*43758.5453);
 float grain=0.0;
 vec3 tile_color=tint*(0.92+variation*0.10+grain);
 ALBEDO=mix(tint*0.79,tile_color,grout);
 ROUGHNESS=0.86;
}"""
	var material=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("tint",base)
	tile.material_override=material

func add_landscaping():
	var asphalt=Color("#41454a")
	var grass=Color("#52604b")
	var concrete=Color("#7c8185")
	if not spawn_premium("street",stage,Vector3(2,-0.22,1),0.0):
		box(stage,Vector3(2,-0.56,1),Vector3(85,0.2,70),Color("#555b60"))
	box(stage,Vector3(2,-0.39,19.5),Vector3(42,0.15,5.4),asphalt)
	box(stage,Vector3(2,-0.20,16.4),Vector3(42,0.18,1.5),concrete)
	for i in range(22):
		box(stage,Vector3(-18+i*1.8,-0.300,19.5),Vector3(0.9,0.025,0.07),Color("#e4d9aa"))
	for pos in [Vector3(-8.5,-0.3,-4.7),Vector3(3.9,-0.3,-5.1),Vector3(12.8,-0.3,-4.8)]:
		cylinder(stage,pos+Vector3(0,0.8,0),0.13,1.6,Color("#805d43"))
		ball(stage,pos+Vector3(0,1.9,0),Vector3(1.5,1.75,1.5),grass.darkened(0.12))
		ball(stage,pos+Vector3(0.36,1.6,0.13),Vector3(0.9,1.0,1.0),grass.lightened(0.12))
	# Warm metal bins and a little storefront bench.
	if not spawn_premium("bench",stage,Vector3(-0.8,0,4.65),0.0):
		box(stage,Vector3(-0.8,0.28,4.12),Vector3(1.7,0.13,0.42),Color("#a8794b"))
	for x in [-1.5,-0.1]:
		box(stage,Vector3(x,0.03,4.12),Vector3(0.1,0.45,0.35),Color("#39494c"))


func add_merchandising():
	var teal=Color("#334b65")
	var ivory=Color("#fff0d4")
	var accent=Color("#d4ae68")
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
	if asset_library.spawn("market",["shoppingbasket"],display,Vector3.ZERO,Vector3(0.62,0.55,0.62))==null:
		box(display,Vector3(0,0.17,0),Vector3(0.58,0.34,0.48),teal)
		box(display,Vector3(0,0.36,0),Vector3(0.60,0.05,0.50),accent)

func build_city():
	var stone=Color("#c6c8c5")
	var metal=Color("#35454d")
	var glass=Color("#91c8d8")
	box(stage,Vector3(-3.4,-0.16,10.0),Vector3(2.8,0.25,12.8),stone)
	for i in range(6):
		var x: float=-16.0+i*6.5
		cylinder(stage,Vector3(x,1.4,16.4),0.055,3.1,metal)
		box(stage,Vector3(x,2.95,16.65),Vector3(0.18,0.12,0.65),metal)
		box(stage,Vector3(x,2.89,16.86),Vector3(0.16,0.035,0.24),Color("#fff1c8"))
	traffic_rng.randomize()
	for i in range(24):
		var car=Node3D.new()
		stage.add_child(car)
		car.position=Vector3(-24,-0.3,20.85)
		car.hide()
		build_vehicle(car,i)
		traffic.append(car)
	parking=Node3D.new()
	stage.add_child(parking)
	box(parking,Vector3(-9,-0.20,11.0),Vector3(8,0.14,9),Color("#60696c"))
	for i in range(4):
		var x: float=-12.6+i*2.4
		box(parking,Vector3(x,-0.12,11),Vector3(0.055,0.025,4.6),Color.WHITE)
	parking_sign=Node3D.new()
	stage.add_child(parking_sign)
	box(parking_sign,Vector3(-9,-0.20,11),Vector3(8,0.12,9),Color("#a2a8a0"))
	var notice=Label3D.new()
	notice.text="ПАРКОВКА • 350 мон."
	notice.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	notice.font_size=48
	notice.pixel_size=0.012
	parking_sign.add_child(notice)
	notice.position=Vector3(-9,0.5,11)
	# Open front facade: glass side panels preserve the cutaway view.
	for x in [-4.82,-2.0]:
		box(stage,Vector3(x,1.05,4.04),Vector3(0.12,2.1,0.16),metal)
	# Front identity is built in build_architecture().

# Independent arrival clocks for each lane; following cars keep a safe gap.
func update_traffic(delta: float):
	for lane in range(game.road_level*2):
		var direction: float=1.0 if lane%2==0 else -1.0
		var lane_z: float=20.85+floori(lane/2.0)*2.7 if lane%2==0 else 18.15-floori(lane/2.0)*2.7
		var entry: float=-10.0 if direction>0 else 23.0
		var exit: float=23.0 if direction>0 else -10.0
		var moving: Array[Node3D]=[]
		for car in traffic:
			if car.visible and int(car.get_meta("lane",-1))==lane:
				moving.append(car)
		moving.sort_custom(func(a: Node3D,b: Node3D): return a.position.x*direction>b.position.x*direction)
		var front: float=INF
		for car in moving:
			var progress: float=car.position.x*direction
			var desired: float=float(traffic_speeds[car])
			var speed: float=float(car.get_meta("speed",0.0))
			var gap: float=front-progress-4.8
			if game.crossing_mode==0 and signal_phase!=0 and progress<=CROSS_X*direction-3.3:
				gap=minf(gap,CROSS_X*direction-3.3-progress)
			desired=minf(desired,sqrt(maxf(0.0,gap)*5.0))
			speed=move_toward(speed,desired,delta*(2.0 if desired>speed else 5.0))
			car.set_meta("speed",speed)
			var advance: float=speed*delta
			var next: float=minf(progress+advance,front-4.8)
			var stop_at: float=CROSS_X*direction-3.3
			if game.crossing_mode==0 and signal_phase!=0 and progress<=stop_at:
				next=minf(next,stop_at)
			car.position.x=maxf(progress,next)*direction
			if car.position.x*direction>=exit*direction:
				car.hide()
				traffic_speeds.erase(car)
			else:
				front=car.position.x*direction
		traffic_timers[lane]-=delta
		if traffic_timers[lane]>0.0:
			continue
		if front-entry*direction<5.5:
			traffic_timers[lane]=0.35
			continue
		var available: Array[Node3D]=[]
		for car in traffic:
			if not car.visible:
				available.append(car)
		if available.is_empty():
			traffic_timers[lane]=0.5
			continue
		var car: Node3D=available[traffic_rng.randi_range(0,available.size()-1)]
		car.set_meta("lane",lane)
		car.position=Vector3(entry,-0.3,lane_z)
		car.rotation.y=0.0 if direction>0 else PI
		car.set_meta("speed",0.0)
		traffic_speeds[car]=traffic_rng.randf_range(2.0,4.0) if int(car.get_meta("kind",0))==5 else traffic_rng.randf_range(3.2,7.2)
		car.show()
		traffic_timers[lane]=traffic_rng.randf_range(1.4,7.5)

func crossing_open() -> bool:
	return game.crossing_mode!=0 or signal_phase==3

func build_infrastructure():
	var asphalt=Color("#41454a")
	var white=Color("#f6f2e9")
	var steel=Color("#536a73")
	for tier in range(3):
		var root=Node3D.new()
		stage.add_child(root)
		if tier>0:
			for side in [-1,1]:
				var z: float=19.5+side*(1.35+tier*2.7)
				box(root,Vector3(2,-0.39,z),Vector3(42,0.15,2.7),asphalt)
				for j in range(22):
					box(root,Vector3(-18+j*1.8,-0.300,z-side*1.35),Vector3(0.9,0.025,0.07),white)
		road_parts.append(root)
	for mode in range(3):
		var root=Node3D.new()
		stage.add_child(root)
		cross_roots.append(root)
		if mode==0:
			for j in range(27):
				var z: float=19.5+(j-13)*0.6
				var mark=box(root,Vector3(CROSS_X,-0.301,z),Vector3(2.4,0.015,0.28),white)
				main_cross_marks.append(mark)
			for side in [-1,1]:
				var x: float=CROSS_X+side*2.1
				var z: float=19.5+side*7.9
				cylinder(root,Vector3(x,1.2,z),0.08,3.0,steel)
				var head=Node3D.new()
				root.add_child(head)
				head.position=Vector3(x,2.5,z)
				head.rotation.y=PI/2 if side==1 else -PI/2
				box(head,Vector3.ZERO,Vector3(0.42,1.05,0.27),Color("#273136"))
				for j in range(3):
					var lamp=ball(head,Vector3(0,0.32-j*0.32,0.15),Vector3(0.22,0.22,0.08),white)
					lamp.material_override=StandardMaterial3D.new()
					signal_lamps.append(lamp)
		elif mode==1:
			box(root,Vector3(CROSS_X,3.3,19.5),Vector3(2.6,0.28,17.0),steel)
			for x in [-4.65,-2.15]:
				box(root,Vector3(x,3.95,19.5),Vector3(0.08,1.0,17.0),Color("#94c5d1"))
			for side in [-1,1]:
				for j in range(14):
					box(root,Vector3(CROSS_X,0.12+j*0.23,19.5+side*(11.3-j*0.25)),Vector3(2.4,0.24,0.32),steel)
				box(root,Vector3(CROSS_X,1.5,19.5+side*8.2),Vector3(0.22,3.0,0.22),steel)
		else:
			for side in [-1,1]:
				var z: float=19.5+side*9.2
				box(root,Vector3(CROSS_X,0.04,z),Vector3(3.0,0.22,2.7),Color("#273d47"))
				for x in [-4.85,-1.95]:
					box(root,Vector3(x,0.55,z),Vector3(0.18,1.2,2.7),steel)
				sign_text(root,Vector3(CROSS_X,1.25,z),"ПОДЗЕМНЫЙ",white,0.006)

func update_infrastructure(delta: float):
	if last_road!=game.road_level or last_cross!=game.crossing_mode:
		last_road=game.road_level
		last_cross=game.crossing_mode
		for mark in main_cross_marks:
			mark.visible=absf(mark.position.z-19.5)+0.14<=float(last_road)*2.7
		for i in range(road_parts.size()):
			road_parts[i].visible=i<last_road
		for i in range(cross_roots.size()):
			cross_roots[i].visible=i==last_cross
	signal_time+=delta
	if signal_phase==0 and signal_time>=game.signal_green:
		signal_phase=1
		signal_time=0.0
	elif signal_phase==1 and signal_time>=2.0:
		signal_phase=2
		signal_time=0.0
	elif signal_phase==2:
		var clear: bool=true
		for car in traffic:
			if car.visible and absf(car.position.x-CROSS_X)<3.2:
				clear=false
		if clear and signal_time>=1.0:
			signal_phase=3
			signal_time=0.0
	elif signal_phase==3 and signal_time>=6.0+game.road_level*2.0 and not pedestrians_on_road():
		signal_phase=0
		signal_time=0.0
	var colors: Array[Color]=[Color("#ff3636"),Color("#ffc238"),Color("#4bec80")]
	for i in range(signal_lamps.size()):
		var j: int=i%3
		var on: bool=(signal_phase==0 and j==2) or (signal_phase==1 and j==1) or (signal_phase>=2 and j==0)
		var material: StandardMaterial3D=signal_lamps[i].material_override
		material.albedo_color=colors[j] if on else colors[j].darkened(0.8)
		material.emission_enabled=on
		material.emission=colors[j]
	while street_people.size()<game.street_queue.size():
		var p=person(Color("#6b93b7"))
		add_carry(p)
		street_people.append(p)
	while street_people.size()>game.street_queue.size():
		street_people.pop_back().queue_free()
	for i in range(street_people.size()):
		var p: Dictionary=game.street_queue[i]
		var target: Vector3=p["pos"]
		actor(street_people[i],target,false,delta)

func build_district():
	var trim=Color("#355f59")
	var stone=Color("#d2c4ae")
	for i in range(72):
		var tile=Node3D.new()
		stage.add_child(tile)
		var p=Vector3(17.725+float(i%6)*1.45,-0.05,-3.275+float(floori(i/6.0))*1.45)
		box(tile,p,Vector3(1.44,0.10,1.44),stone.lightened(float(i%3)*0.025))
		growth_tiles.append(tile)
	for i in range(3):
		var root=Node3D.new()
		stage.add_child(root)
		root.position=Vector3(20.75+i*7.5,-0.05,-6.5)
		var accent: Color=[Color("#b87949"),Color("#637eaa"),Color("#977487")][i]
		box(root,Vector3(0,0.03,0),Vector3(7.5,0.12,5.1),stone)
		box(root,Vector3(0,1.55,-2.35),Vector3(7.3,3.0,0.22),stone)
		for x in [-3.5,3.5]:
			box(root,Vector3(x,1.55,0),Vector3(0.22,3.0,4.8),stone)
			box(root,Vector3(x,1.55,2.35),Vector3(0.23,3.0,0.23),trim)
		box(root,Vector3(0,3.2,2.35),Vector3(7.4,0.75,0.35),accent)
		sign_text(root,Vector3(0,3.2,2.55),["КАФЕ","ОДЕЖДА","ОБУВЬ"][i],Color.WHITE,0.012)
		for x in [-2.3,0.0,2.3]:
			box(root,Vector3(x,0.55,-1.5),Vector3(1.7,1.05,0.8),accent)
			box(root,Vector3(x,1.11,-1.5),Vector3(1.8,0.08,0.9),stone)
			if i==0:
				cylinder(root,Vector3(x,0.65,0.9),0.55,0.12,trim)
				cylinder(root,Vector3(x,0.3,0.9),0.09,0.6,trim)
			else:
				for j in range(3):
					box(root,Vector3(x-0.5+j*0.5,1.25,-1.5),Vector3(0.34,0.24,0.38),accent.lightened(j*0.15))
		district_models.append(root)
		root.hide()

func build_architecture():
	var brick=Color("#777e85")
	var dark=Color("#293a40")
	var cream=Color("#a7aaad")
	var glass=Color("#7fa7b6")
	# Paved forecourt, with a low kerb and alternating stone joints.
	box(stage,Vector3(0,-0.15,5.0),Vector3(10.5,0.18,1.75),Color("#b6b6ad"))
	make_floor(stage,Vector3(0,-0.10,5.0),Vector2(10.4,1.7),Color("#c7c1b6"))
	box(stage,Vector3(0,-0.05,5.85),Vector3(10.5,0.16,0.14),cream)
	# Real depth on the cutaway walls, brick courses and dark window frames.
	for x in [-4.8,-2.45,0.95,4.8]:
		box(stage,Vector3(x,1.08,-3.73),Vector3(0.20,2.15,0.22),brick)
	for y in [0.23,0.42,0.61]:
		box(stage,Vector3(0,y,-3.77),Vector3(9.8,0.025,0.06),cream)
	for x in [-3.6,-0.1,3.4]:
		for side in [-1,1]:
			box(stage,Vector3(x+side*1.06,1.06,-3.68),Vector3(0.09,1.13,0.10),dark)
		for y in [0.52,1.60]:
			box(stage,Vector3(x,y,-3.68),Vector3(2.12,0.09,0.10),dark)
		box(stage,Vector3(x,0.48,-3.58),Vector3(2.25,0.08,0.32),cream)
	# Front shop window and door frames; no opaque roof over gameplay.
	for x in [-4.82,-2.02,4.78]:
		box(stage,Vector3(x,1.23,4.10),Vector3(0.18,2.46,0.22),dark)
	for x in [-1.78,4.55]:
		box(stage,Vector3(x,0.52,4.08),Vector3(0.25,1.04,0.25),brick)
	box(stage,Vector3(-3.4,2.60,4.10),Vector3(3.12,0.63,0.28),dark)
	facade_title=Label3D.new()
	facade_title.font_size=64
	facade_title.pixel_size=0.006
	facade_title.modulate=cream
	facade_title.outline_size=0
	stage.add_child(facade_title)
	facade_title.position=Vector3(-3.4,2.60,4.26)
	# Each business stage gets its own distinct frontage.
	for tier in range(5):
		var root=Node3D.new()
		stage.add_child(root)
		var accent: Color=[Color("#b84d42"),Color("#2e7c70"),Color("#356da0"),Color("#664a88"),Color("#b48a38")][tier]
		var width: float=3.2+float(tier)*1.6
		var center: float=-3.4+float(tier)*0.8
		box(root,Vector3(center,2.13,4.40),Vector3(width,0.13,1.00),accent)
		for j in range(ceili(width/0.32)):
			var x: float=center-width*0.5+0.16+float(j)*0.32
			box(root,Vector3(x,2.02,4.89),Vector3(0.30,0.20,0.09),cream if j%2==0 else accent)
		if tier>0:
			box(root,Vector3(center,2.92,-3.92),Vector3(width,0.42,0.30),accent)
			for j in range(tier+1):
				box(root,Vector3(center-width*0.4+j*width*0.8/maxi(1,tier),2.48,-3.90),Vector3(0.12,0.7,0.28),dark)
		facade_tiers.append(root)
		root.hide()
	# Planters, varied foliage and street furniture along the storefront.
	for x in [-5.0,4.8]:
		box(stage,Vector3(x,0.18,5.3),Vector3(0.75,0.46,0.75),brick)
		box(stage,Vector3(x,0.42,5.3),Vector3(0.82,0.08,0.82),cream)
		for j in range(5):
			var angle: float=j*TAU/5.0
			ball(stage,Vector3(x+cos(angle)*0.22,0.72+0.09*(j%2),5.3+sin(angle)*0.22),Vector3(0.43,0.60,0.43),Color("#48704d").lightened(j*0.06))
	for x in [0.0,2.0]:
		box(stage,Vector3(x,0.25,5.3),Vector3(1.25,0.12,0.38),Color("#a77952"))
		for j in [-1,1]:
			box(stage,Vector3(x+j*0.49,0.05,5.3),Vector3(0.10,0.32,0.34),dark)

# Match the actual screen-space rectangle, including window stretch and high-DPI.
func update_render_resolution():
	if viewport==null or size.x<2 or size.y<2:
		return
	var transform_scale: Vector2=get_global_transform_with_canvas().get_scale().abs()
	var screen_size: Vector2=size*transform_scale
	var scale_factor: float=1.0 if quality_high else 0.8
	var target: Vector2=screen_size*scale_factor
	var limit: float=1920.0 if quality_high else 1280.0
	if OS.has_feature("web"):
		limit=1280.0
		# Quantize dimensions to avoid repeated framebuffer reallocations.
		target=Vector2(roundf(target.x/16.0)*16.0,roundf(target.y/16.0)*16.0)
	if maxf(target.x,target.y)>limit:
		target*=limit/maxf(target.x,target.y)
	var wanted=Vector2i(maxi(2,roundi(target.x)),maxi(2,roundi(target.y)))
	if wanted!=render_size:
		render_size=wanted
		viewport.size=wanted

func pedestrians_on_road() -> bool:
	for p in game.street_queue:
		if bool(p.get("crossing",false)):
			return true
	return false

func load_premium_models():
	for kind in ["shell","shelf","cold","checkout","street","plant","bench"]:
		var path: String="res://assets/premium/"+kind+".glb"
		if ResourceLoader.exists(path):
			var resource=load(path)
			if resource is PackedScene:
				premium_models[kind]=resource
	print("Premium Blender modules: ",premium_models.size())

func spawn_premium(kind: String, parent: Node3D, pos: Vector3, angle: float, dimensions_scale: Vector3=Vector3.ONE) -> bool:
	if not premium_models.has(kind):
		return false
	var node: Node3D=premium_models[kind].instantiate()
	parent.add_child(node)
	node.position=pos
	node.rotation.y=angle
	node.scale=dimensions_scale
	return true

func apply_shell_palette(root: Node):
	if root is MeshInstance3D:
		var n: String=String(root.name).to_lower()
		var color: Color=Color("#424952")
		if "porcelain" in n:
			color=Color("#505861")
		elif "wall" in n and not "cap" in n:
			color=Color("#7d848b")
		elif "mullion" in n:
			color=Color("#50555b")
		elif "foundation" in n or "cap" in n or "lintel" in n or "plinth" in n:
			color=Color("#2b3037")
		root.material_override=mat(color)
	for child in root.get_children():
		apply_shell_palette(child)

# Surrounding streets are independent of the player's upgradeable main road.
var neighborhood_cars: Array[Node3D]=[]
var neighborhood_time: float=0.0

func build_neighborhood():
	var district=Node3D.new()
	stage.add_child(district)
	var asphalt=Color("#383d43")
	var paving=Color("#777b7e")
	var stripe=Color("#d5d4cd")
	var steel=Color("#343a40")
	var lawn=Color("#485747")
	# Leave the entire shop expansion area (x=5..34) clear.
	box(district,Vector3(-17,-0.39,0),Vector3(5.6,0.15,65),asphalt)
	box(district,Vector3(39,-0.39,0),Vector3(5.6,0.15,65),asphalt)
	box(district,Vector3(11,-0.39,-15),Vector3(56,0.15,5.6),asphalt)
	box(district,Vector3(31,-0.39,19.5),Vector3(16,0.15,5.4),asphalt)
	for x in [-17.0,39.0]:
		for z in range(-30,31,3):
			if absf(z-19.5)>5 and absf(z+15)>5:
				box(district,Vector3(x,-0.303,z),Vector3(0.075,0.014,1.45),stripe)
		for side in [-1,1]:
			var curb_x: float=x+side*3.55
			for section in [Vector2(-24,12),Vector2(2.0,28),Vector2(28,7)]:
				box(district,Vector3(curb_x,-0.27,section.x),Vector3(1.25,0.21,section.y),paving)
				box(district,Vector3(x+side*2.96,-0.23,section.x),Vector3(0.13,0.23,section.y),stripe)
	for x in range(-14,38,3):
		box(district,Vector3(x,-0.30,-15),Vector3(1.45,0.014,0.075),stripe)
	for z in [-18.55,-11.45]:
		box(district,Vector3(11,-0.27,z),Vector3(49,0.21,1.25),paving)
	for cross in [Vector3(-17,0,-15),Vector3(39,0,-15),Vector3(-17,0,19.5),Vector3(39,0,19.5)]:
		for j in range(7):
			var d: float=-2.4+j*0.8
			for side in [-1,1]:
				box(district,cross+Vector3(d,-0.297,side*4.0),Vector3(0.38,0.015,1.6),stripe)
				if (cross.x<0.0 and side==1) or (cross.x>0.0 and side==-1):
					box(district,cross+Vector3(side*4.0,-0.297,d),Vector3(1.6,0.015,0.38),stripe)
	# Residential and office blocks, well away from the shop.
	for i in range(5):
		var x: float=-8.0+i*9.4
		var h: float=4.5+float(i%3)*1.7
		neighborhood_building(district,Vector3(x,-0.3,-24),h,i)
	for i in range(3):
		neighborhood_building(district,Vector3(-25,-0.3,-6+i*10),5.2+float(i%2)*2.0,i+5)
	# Pocket park, benches, lamps and a bus shelter.
	box(district,Vector3(-10,-0.28,-7.5),Vector3(7.5,0.13,6.0),paving)
	box(district,Vector3(-10,-0.18,-7.5),Vector3(6.6,0.10,4.9),lawn)
	for pos in [Vector3(-12,-0.12,-9),Vector3(-8,-0.12,-9),Vector3(-12,-0.12,-6),Vector3(-8,-0.12,-6)]:
		spawn_premium("plant",district,pos,0.0,Vector3(1.8,1.8,1.8))
	spawn_premium("bench",district,Vector3(-10,-0.12,-5.9),0.0)
	var shelter=Vector3(8,-0.1,15.5)
	box(district,shelter+Vector3(0,2.25,0),Vector3(3.6,0.13,1.35),steel)
	for x in [-1.65,1.65]:
		box(district,shelter+Vector3(x,1.05,-0.55),Vector3(0.10,2.1,0.10),steel)
	box(district,shelter+Vector3(0,1.1,-0.58),Vector3(3.3,1.8,0.08),Color("#647d86"))
	spawn_premium("bench",district,shelter+Vector3(0,0,-0.2),0.0)
	sign_text(district,shelter+Vector3(0,2.32,0.7),"ОСТАНОВКА",stripe,0.005)
	for x in [-13.2,35.2]:
		for z in [-25.0,-8.0,3.0,13.0,27.0]:
			cylinder(district,Vector3(x,1.25,z),0.055,3.0,steel)
			box(district,Vector3(x,2.72,z),Vector3(0.52,0.13,0.22),steel)
			box(district,Vector3(x,2.64,z),Vector3(0.40,0.035,0.16),Color("#e9d6a8"))
	build_junctions(district)

func neighborhood_building(parent: Node3D, pos: Vector3, h: float, variant: int):
	var root=Node3D.new()
	parent.add_child(root)
	root.position=pos
	var facade: Color=[Color("#777a7c"),Color("#9b9387"),Color("#676e76")][variant%3]
	var frame=Color("#333b43")
	var glass=Color("#536e7d")
	box(root,Vector3(0,0.12,0),Vector3(7.8,0.24,7.0),Color("#777b80"))
	box(root,Vector3(0,h/2,0),Vector3(6.8,h,5.8),facade)
	box(root,Vector3(0,h+0.1,0),Vector3(7.0,0.2,6.0),frame)
	for floor_index in range(maxi(1,int(h/1.5))):
		var y: float=0.85+floor_index*1.5
		for x in [-2.2,0.0,2.2]:
			box(root,Vector3(x,y,2.93),Vector3(1.38,0.92,0.08),frame)
			box(root,Vector3(x,y,2.98),Vector3(1.20,0.75,0.04),glass)
	box(root,Vector3(0,0.95,3.02),Vector3(1.2,1.9,0.12),frame)
	box(root,Vector3(0,2.03,3.32),Vector3(2.0,0.12,0.7),frame)


# Controlled T-junctions on the rear street. Each junction grants one vehicle
# at a time through the conflict zone and has an exclusive pedestrian phase.
var junctions: Array[Dictionary]=[]
var city_vehicles: Array[Dictionary]=[]
var city_pedestrians: Array[Dictionary]=[]
var city_spawn_clock: float=0.0

func build_vehicle(car: Node3D, serial: int):
	var kind: int=serial%6
	car.set_meta("kind",kind)
	var paint: Color=[Color("#a23736"),Color("#d8dbdc"),Color("#355d86"),Color("#b8a06f"),Color("#303941"),Color("#5e8275"),Color("#b96b3a")][serial%7]
	var rubber=Color("#25282b")
	var glass=Color("#4c697a")
	var metal=Color("#a2a8ac")
	if kind>=4:
		var wheel_r: float=0.32 if kind==4 else 0.38
		for x in [-0.70,0.70]:
			cylinder(car,Vector3(x,wheel_r,0),wheel_r,0.16 if kind==4 else 0.065,rubber).rotation.x=PI/2
			cylinder(car,Vector3(x,wheel_r,0),wheel_r*0.65,0.17 if kind==4 else 0.075,metal).rotation.x=PI/2
		box(car,Vector3(0,0.52,0),Vector3(1.28,0.12,0.15),paint)
		box(car,Vector3(0.53,0.78,0),Vector3(0.10,0.65,0.10),metal).rotation.z=0.22
		box(car,Vector3(0.54,1.08,0),Vector3(0.14,0.07,0.54),metal)
		box(car,Vector3(-0.35,0.81,0),Vector3(0.43,0.10,0.24),rubber)
		if kind==4:
			ball(car,Vector3(0.08,0.69,0),Vector3(0.63,0.38,0.38),paint)
		# Rider and helmet.
		ball(car,Vector3(-0.08,1.11,0),Vector3(0.43,0.52,0.34),Color("#414e58"))
		ball(car,Vector3(0.05,1.47,0),Vector3(0.32,0.33,0.32),paint)
		for side in [-1,1]:
			box(car,Vector3(-0.15,0.72,side*0.16),Vector3(0.24,0.44,0.14),Color("#34414c"))
			box(car,Vector3(0.28,1.13,side*0.15),Vector3(0.45,0.11,0.11),Color("#414e58")).rotation.z=-0.18
		return
	var length: float=[3.25,3.55,3.8,4.1][kind]
	var width: float=1.42 if kind<2 else 1.60
	var height: float=[0.48,0.62,0.70,0.76][kind]
	box(car,Vector3(0,0.37,0),Vector3(length,0.45,width),paint)
	var cabin_length: float=length*(0.50 if kind==0 else 0.68)
	box(car,Vector3(-0.13,0.62+height/2,0),Vector3(cabin_length,height,width*0.91),paint)
	for side in [-1,1]:
		box(car,Vector3(-0.13,0.70+height*0.40,side*width*0.46),Vector3(cabin_length*0.84,height*0.56,0.025),glass)
		box(car,Vector3(-0.1,0.70+height*0.40,side*width*0.48),Vector3(0.065,height*0.58,0.03),paint)
		for x in [-length*0.32,length*0.32]:
			cylinder(car,Vector3(x,0.26,side*width*0.49),0.27,0.19,rubber).rotation.x=PI/2
			cylinder(car,Vector3(x,0.26,side*width*0.55),0.16,0.05,metal).rotation.x=PI/2
		box(car,Vector3(length/2,0.43,side*width*0.32),Vector3(0.04,0.17,0.27),Color("#fff2d2"))
		box(car,Vector3(-length/2,0.43,side*width*0.32),Vector3(0.04,0.16,0.25),Color("#a93637"))
	box(car,Vector3(cabin_length/2-0.12,0.62+height*0.55,0),Vector3(0.045,height*0.62,width*0.82),glass)
	box(car,Vector3(-cabin_length/2-0.14,0.62+height*0.55,0),Vector3(0.045,height*0.62,width*0.82),glass)
	if kind==3:
		box(car,Vector3(-0.68,0.91,0),Vector3(1.8,1.15,width*0.92),paint)

func build_junctions(parent: Node3D):
	for index in range(4):
		var left: bool=index%2==0
		var rear: bool=index<2
		var center=Vector3(-17.0 if left else 39.0,-0.30,-15.0 if rear else 19.5)
		var approaches: Array[Vector3]=[Vector3(0,0,-1),Vector3(0,0,1),Vector3(1 if left else -1,0,0)]
		var lamps: Array=[]
		var walk_lamps: Array[MeshInstance3D]=[]
		for dir in approaches:
			var right=Vector3(-dir.z,0,dir.x)
			var pole=center+dir*4.8+right*3.25
			cylinder(parent,pole+Vector3(0,1.4,0),0.075,2.8,Color("#454d55"))
			var head=Node3D.new()
			parent.add_child(head)
			head.position=pole+Vector3(0,2.55,0)
			head.rotation.y=atan2(dir.x,dir.z)
			box(head,Vector3.ZERO,Vector3(0.34,0.92,0.25),Color("#252b30"))
			var lights: Array[MeshInstance3D]=[]
			for k in range(3):
				var lamp=ball(head,Vector3(0,0.30-k*0.30,0.15),Vector3(0.21,0.21,0.07),Color.WHITE)
				lamp.material_override=StandardMaterial3D.new()
				lights.append(lamp)
			lamps.append(lights)
			var walk=box(head,Vector3(0.38,-0.20,0.08),Vector3(0.24,0.28,0.15),Color("#252b30"))
			walk.material_override=StandardMaterial3D.new()
			walk_lamps.append(walk)
			box(parent,center+dir*5.7-right*1.4+Vector3(0,0.016,0),Vector3(2.55,0.012,0.12) if absf(dir.z)>0.5 else Vector3(0.12,0.012,2.55),Color("#d9d7ce"))
		junctions.append({"center":center,"dirs":approaches,"lamps":lamps,"walk":walk_lamps,"clock":float(index)*5.0,"owner":-1})
		for k in range(3):
			var pedestrian=person([Color("#9a7359"),Color("#637f89"),Color("#746c88")][k])
			pedestrian.hide()
			city_pedestrians.append({"node":pedestrian,"junction":index,"offset":float(k)*0.8,"side":1.0 if k%2==0 else -1.0})
	for i in range(16):
		var vehicle=Node3D.new()
		parent.add_child(vehicle)
		build_vehicle(vehicle,i+24)
		vehicle.hide()
		city_vehicles.append({"node":vehicle,"active":false,"speed":0.0,"max_speed":3.0,"junction":0,"approach":0,"exit":1,"segment":0,"points":[]})

func city_phase(j: Dictionary) -> int:
	var t: float=float(j["clock"])
	if t<9.0: return 0
	if t<11.0: return 1
	if t<13.0: return 2
	if t<21.0: return 3
	if t<23.0: return 4
	if t<25.0: return 5
	return 6

func city_lamp(lamp: MeshInstance3D, color: Color, enabled: bool):
	var material: StandardMaterial3D=lamp.material_override
	material.albedo_color=color if enabled else color.darkened(0.82)
	material.emission_enabled=enabled
	material.emission=color
	material.emission_energy_multiplier=1.3

func start_city_vehicle(index: int, junction_id: int, approach: int):
	var j: Dictionary=junctions[junction_id]
	var dirs: Array=j["dirs"]
	var center: Vector3=j["center"]
	var incoming: Vector3=dirs[approach]
	var exit_index: int=(approach+1+traffic_rng.randi_range(0,1))%3
	if junction_id==2:
		exit_index=1-approach
	var outgoing: Vector3=dirs[exit_index]
	var side_in=Vector3(incoming.z,0,-incoming.x)*1.4
	var side_out=Vector3(-outgoing.z,0,outgoing.x)*1.4
	var entry=center+incoming*3.3+side_in
	var leave=center+outgoing*3.3+side_out
	var route: Array[Vector3]=[center+incoming*13.0+side_in,center+incoming*5.7+side_in,entry]
	for k in range(1,7):
		var t: float=float(k)/6.0
		route.append(entry.lerp(center,t).lerp(center.lerp(leave,t),t))
	route.append(center+outgoing*6.5+side_out)
	route.append(center+outgoing*13.0+side_out)
	var car: Dictionary=city_vehicles[index]
	var node: Node3D=car["node"]
	car.merge({"active":true,"junction":junction_id,"approach":approach,"exit":exit_index,"segment":0,"points":route,"speed":0.0,"max_speed":traffic_rng.randf_range(1.8,3.4) if int(node.get_meta("kind"))==5 else traffic_rng.randf_range(3.3,6.5)},true)
	node.position=route[0]
	node.rotation.y=atan2(incoming.z,-incoming.x)
	node.show()

func update_neighborhood_traffic(delta: float):
	delta=minf(delta,0.12)
	for ji in range(junctions.size()):
		var j: Dictionary=junctions[ji]
		var t: float=float(j["clock"])+delta
		# Red clearance remains active until the previous vehicle exits.
		if (t>=13.0 and t<13.0+delta or t>=25.0 and t<25.0+delta) and int(j["owner"])>=0:
			t-=delta
		j["clock"]=fposmod(t,34.0)
		var phase: int=city_phase(j)
		var lamps: Array=j["lamps"]
		for approach in range(lamps.size()):
			var horizontal: bool=approach==2
			var green: bool=(horizontal and phase==3) or (not horizontal and phase==0)
			var yellow: bool=(horizontal and phase==4) or (not horizontal and phase==1)
			city_lamp(lamps[approach][0],Color("#e53a39"),not green and not yellow)
			city_lamp(lamps[approach][1],Color("#efb536"),yellow)
			city_lamp(lamps[approach][2],Color("#55d878"),green)
			city_lamp(j["walk"][approach],Color("#55d878") if phase==6 else Color("#e53a39"),true)
	for ped in city_pedestrians:
		var j: Dictionary=junctions[int(ped["junction"])]
		var node: Node3D=ped["node"]
		var elapsed: float=float(j["clock"])-25.0-float(ped["offset"])
		if elapsed>=-7.0 and elapsed<=6.5:
			var center: Vector3=j["center"]
			var side: float=float(ped["side"])
			var walk: float=clampf(elapsed/6.5,0.0,1.0)
			node.show()
			node.position=center+Vector3(lerpf(-3.5,3.5,walk)*side,0.05,4.0+float(ped["offset"])*0.22)
			node.rotation.y=PI/2*side
			if node.has_meta("left") and node.has_meta("right"):
				var left_leg: Node3D=node.get_meta("left")
				var right_leg: Node3D=node.get_meta("right")
				var swing: float=sin(elapsed*9.0)*0.42 if elapsed>0 else 0.0
				left_leg.rotation.x=swing
				right_leg.rotation.x=-swing
		else:
			node.hide()
	city_spawn_clock-=delta
	if city_spawn_clock<=0.0:
		city_spawn_clock=traffic_rng.randf_range(0.9,3.8)
		var ji: int=traffic_rng.randi_range(0,junctions.size()-1)
		var approach: int=traffic_rng.randi_range(0,1 if ji==2 else 2)
		var free_entry: bool=true
		for car in city_vehicles:
			if car["active"] and int(car["junction"])==ji and int(car["approach"])==approach and int(car["segment"])==0:
				var node: Node3D=car["node"]
				var route: Array=car["points"]
				if node.position.distance_to(route[0])<5.0:
					free_entry=false
		if free_entry:
			for i in range(city_vehicles.size()):
				if not city_vehicles[i]["active"]:
					start_city_vehicle(i,ji,approach)
					break
	for i in range(city_vehicles.size()):
		var car: Dictionary=city_vehicles[i]
		if not car["active"]: continue
		var node: Node3D=car["node"]
		var j: Dictionary=junctions[int(car["junction"])]
		var points: Array=car["points"]
		var segment: int=int(car["segment"])
		var target: Vector3=points[segment+1]
		var offset: Vector3=target-node.position
		var distance: float=offset.length()
		var desired: float=float(car["max_speed"])
		var max_advance: float=distance
		var phase: int=city_phase(j)
		var green: bool=(int(car["approach"])==2 and phase==3) or (int(car["approach"])!=2 and phase==0)
		if segment==0:
			desired=minf(desired,sqrt(maxf(distance-0.04,0.0)*5.0))
			for other in city_vehicles:
				if other==car or not other["active"] or int(other["junction"])!=int(car["junction"]) or int(other["approach"])!=int(car["approach"]): continue
				var other_node: Node3D=other["node"]
				var ahead: float=(other_node.position-node.position).dot(offset.normalized())
				if ahead>0.0 and ahead<5.0 and int(other["segment"])<=1:
					desired=minf(desired,maxf(0.0,(ahead-4.3)*2.0))
					max_advance=minf(max_advance,maxf(0.0,ahead-4.3))
		elif segment==1 and int(j["owner"])!=i:
			desired=0.0
			if green and int(j["owner"])<0:
				j["owner"]=i
				desired=float(car["max_speed"])*0.65
			else:
				car["speed"]=0.0
				continue
		elif segment<9:
			desired=minf(desired,3.1)
		var speed: float=move_toward(float(car["speed"]),desired,delta*(2.1 if desired>float(car["speed"]) else 5.0))
		car["speed"]=speed
		if distance>0.02:
			var direction: Vector3=offset/distance
			node.rotation.y=lerp_angle(node.rotation.y,atan2(-direction.z,direction.x),minf(delta*9.0,1.0))
			node.position+=direction*minf(max_advance,speed*delta)
		if distance<=0.09:
			if segment==0:
				car["speed"]=0.0
			car["segment"]=segment+1
			if segment>=9:
				if int(j["owner"])==i: j["owner"]=-1
				node.hide()
				car["active"]=false
