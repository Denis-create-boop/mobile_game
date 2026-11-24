extends SubViewportContainer

var game
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
var crates: Array = []
var dirt_marks: Array = []
var delivery_boxes: Array = []
var tick: float = 0.0
var status_label: Label
var sales_label: Label

func _ready():
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport = SubViewport.new()
	viewport.size = Vector2i(640,420)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	stage = Node3D.new()
	viewport.add_child(stage)
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("#b9d5cb")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#edf7ef")
	e.ambient_light_energy = 0.45
	env.environment = e
	stage.add_child(env)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-57,-38,0)
	light.light_energy = 0.8
	light.shadow_enabled = true
	stage.add_child(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 11.8
	camera.position = Vector3(10,12,14)
	stage.add_child(camera)
	camera.look_at(Vector3(0,0.3,0))
	camera.current = true
	build_store()
	status_label = Label.new()
	status_label.position = Vector2(12,8)
	status_label.add_theme_font_size_override("font_size",18)
	status_label.add_theme_color_override("font_color",Color("#193d36"))
	add_child(status_label)
	sales_label = Label.new()
	sales_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	sales_label.position = Vector2(12, size.y-30)
	sales_label.add_theme_color_override("font_color",Color("#193d36"))
	add_child(sales_label)

func mat(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.82
	return m

func mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.mesh = shape
	n.material_override = mat(color)
	parent.add_child(n)
	n.position = pos
	return n

func box(parent: Node3D, pos: Vector3, dims: Vector3, color: Color) -> MeshInstance3D:
	var b = BoxMesh.new()
	b.size = dims
	return mesh(parent,b,pos,color)

func ball(parent: Node3D, pos: Vector3, dims: Vector3, color: Color) -> MeshInstance3D:
	var b = SphereMesh.new()
	b.radius = 0.5
	b.height = 1.0
	b.radial_segments = 16
	b.rings = 8
	var n = mesh(parent,b,pos,color)
	n.scale = dims
	return n

func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var b = CylinderMesh.new()
	b.top_radius = radius
	b.bottom_radius = radius
	b.height = height
	b.radial_segments = 16
	return mesh(parent,b,pos,color)

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
	var cream = Color("#f7ead1")
	box(stage,Vector3(0,-0.32,0),Vector3(10.4,0.5,8.4),Color("#688e82"))
	for x in range(10):
		for z in range(8):
			var shade = Color("#f3ecdf") if (x+z)%2==0 else Color("#d9e5d8")
			box(stage,Vector3(x-4.5,-0.04,z-3.5),Vector3(0.98,0.08,0.98),shade)
	box(stage,Vector3(0,0.95,-4.0),Vector3(10.3,1.9,0.18),cream)
	box(stage,Vector3(-5,0.95,0),Vector3(0.18,1.9,8),cream)
	box(stage,Vector3(0,1.98,-4.0),Vector3(10.45,0.17,0.29),mint)
	box(stage,Vector3(-5,1.98,0),Vector3(0.29,0.17,8.1),mint)
	for x in [-3.6,-0.1,3.4]:
		box(stage,Vector3(x,1.05,-3.88),Vector3(2.2,1.15,0.05),Color("#fdfbf2"))
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
			if i==0:
				ball(item,Vector3(0,0.15,0),Vector3(0.42,0.3,0.55),Color("#c88a43"))
				for k in range(3):
					var mark = box(item,Vector3(-0.12+k*0.12,0.29,0),Vector3(0.04,0.015,0.21),Color("#f3cc87"))
					mark.rotation.y = 0.5
			elif i==1:
				box(item,Vector3(0,0.20,0),Vector3(0.29,0.4,0.28),Color("#f7fbff"))
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
	loader=person(Color("#cf913c"))
	add_carry(loader)
	cleaner=person(Color("#758fc7"))
	var broom=box(cleaner,Vector3(0.34,0.45,0.16),Vector3(0.055,0.95,0.055),wood)
	broom.rotation.z=-0.3
	box(cleaner,Vector3(0.48,0.08,0.16),Vector3(0.25,0.12,0.2),Color("#c59e65"))

func person(color: Color) -> Node3D:
	var p = Node3D.new()
	stage.add_child(p)
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
	for direction in [-1,1]:
		var arm = cylinder(p,Vector3(direction*0.27,0.70,0),0.07,0.38,color)
		arm.rotation.z = direction*0.22
		ball(p,Vector3(direction*0.30,0.48,0),Vector3(0.13,0.15,0.13),skin)
	cylinder(p,Vector3(0,1.00,0),0.085,0.13,skin)
	ball(p,Vector3(0,1.19,0),Vector3(0.36,0.40,0.35),skin)
	ball(p,Vector3(0,1.30,-0.055),Vector3(0.38,0.26,0.34),Color("#574137"))
	for direction in [-1,1]:
		ball(p,Vector3(direction*0.07,1.21,0.16),Vector3(0.035,0.045,0.025),Color("#3f3530"))
	return p

func add_carry(p: Node3D):
	var b=box(p,Vector3(0,0.72,0.3),Vector3(0.32,0.28,0.28),Color("#c99458"))
	b.visible=false
	p.set_meta("carry",b)

func actor(p: Node3D, target: Vector3, carrying: bool, dt: float):
	var direction=target-p.position
	if direction.length()>0.001:
		p.rotation.y=atan2(direction.x,direction.z)
		p.get_meta("left").rotation.x=sin(tick*12)*0.5
		p.get_meta("right").rotation.x=-sin(tick*12)*0.5
	else:
		p.get_meta("left").rotation.x=0
		p.get_meta("right").rotation.x=0
	p.position=target
	p.get_meta("carry").visible=carrying

func _process(delta):
	if not is_instance_valid(game) or status_label==null:
		return
	tick+=delta
	for i in range(3):
		for j in range(products[i].size()):
			products[i][j].visible=j<game.stock[i]
		for k in range(2):
			extras[i][k].visible=game.shelf_levels[i]>k+1
		for j in range(extra_goods[i].size()):
			extra_goods[i][j].visible=j+12<game.stock[i]
		employees[i].visible=i<game.workers
		counters[i].visible=i<game.workers
		if i<game.sellers.size():
			var s=game.sellers[i]
			actor(employees[i],s["pos"],s["carry"],delta)
		delivery_boxes[i].visible=game.delivery[0]+game.delivery[1]+game.delivery[2]>i*5
	for i in range(crates.size()):
		crates[i].visible=game.storage[0]+game.storage[1]+game.storage[2]>i*4
	for i in range(dirt_marks.size()):
		dirt_marks[i].visible=game.dirt>i*15+8
	loader.visible=game.loaders>0
	cleaner.visible=game.cleaners>0
	actor(loader,game.loader_pos,game.loader_amount>0,delta)
	var clean_target: Vector3=game.cleaner_pos
	update_cleaner(clean_target)
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

func update_cleaner(target: Vector3):
	var d=target-cleaner.position
	if d.length()>0.001:
		cleaner.rotation.y=atan2(d.x,d.z)
		cleaner.get_meta("left").rotation.x=sin(tick*10)*0.35
		cleaner.get_meta("right").rotation.x=-sin(tick*10)*0.35
	cleaner.position=target
