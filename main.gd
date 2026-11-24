extends Control

const SAVE_PATH = "user://market.json"
const GOODS = ["Хлеб", "Молоко", "Яблоки"]
const COST = [12, 18, 10]
const PRICE = [22, 32, 19]
const COLORS = [Color("#d6a660"), Color("#91c9ed"), Color("#e17c68")]
var cash: int = 500
var stock: Array = [8, 8, 8]
var level: int = 1
var sold: int = 0
var revenue: int = 0
var workers: int = 1
var loaders: int = 0
var cleaners: int = 0
var storage: Array = [5,5,5]
var delivery: Array = [0,0,0]
var shelf_levels: Array = [1,1,1]
var placements: Array = [-1,-1,-1,-1,-1,-1]
var build_kind: int = -1
var visual: Control
var tabs: TabContainer
var delivery_eta: float = 0.0
var incoming: Array = [0,0,0]
var payment_events: Array = []
var warehouse_level: int = 1
var dirt: float = 0.0
var sellers: Array = []
var loader_pos := Vector3(-4,0,1)
var cleaner_pos := Vector3(-3,0,2)
var loader_phase: int = 0
var loader_item: int = -1
var loader_amount: int = 0
var cleaner_target := Vector3(-3,0,2)
var staff_buttons: Array[Button] = []
var shelf_buttons: Array[Button] = []
var info: Label
var running: bool = false
var elapsed: float = 0.0
var customer_x: float = 0.0
var customers: Array = []
var message: String = "Откройте магазин и обслужите первых покупателей."
var hud: Label
var hint: Label
var shop_rows: Array[Button] = []
var upgrade: Button
var hire: Button
var open_button: Button
var world: Control
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	load_game()
	for i in range(workers):
		add_seller()
	build_ui()
	refresh()

func style(bg: Color, radius: int = 12) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	return s

func label(parent: Node, value: String, size: int = 18) -> Label:
	var l = Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l

func button(parent: Node, value: String, action: Callable) -> Button:
	var b = Button.new()
	b.text = value
	b.custom_minimum_size.y = 29
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_stylebox_override("normal", style(Color("#317c69")))
	b.add_theme_stylebox_override("hover", style(Color("#39876d")))
	b.add_theme_stylebox_override("pressed", style(Color("#1a493e")))
	b.add_theme_stylebox_override("disabled", style(Color("#283b42")))
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func build_ui():
	var outer = MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:
		outer.add_theme_constant_override("margin_" + edge, 16)
	add_child(outer)
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	outer.add_child(root)
	var header = HBoxContainer.new()
	root.add_child(header)
	var title = label(header, "MARKET EMPIRE", 26)
	title.add_theme_color_override("font_color", Color("#a9e8b0"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud = label(header, "", 20)
	var row = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)
	world = Control.new()
	world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world.clip_contents = true
	
	row.add_child(world)
	visual = preload("res://store_visual.gd").new()
	visual.game = self
	world.add_child(visual)
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = 310
	panel.add_theme_stylebox_override("panel", style(Color("#213c43")))
	row.add_child(panel)
	tabs = TabContainer.new()
	panel.add_child(tabs)
	var side = tab_page("Товары")
	label(side, "ПОСТАВКИ · ПОЛКА / СКЛАД", 15)
	for i in range(GOODS.size()):
		shop_rows.append(button(side, "", buy.bind(i)))
	info = label(side, "", 13)
	button(side, "Разгрузить / пополнить вручную", manual_load)
	side = tab_page("Стройка")
	label(side, "РАЗМЕЩЕНИЕ ОБОРУДОВАНИЯ", 14)
	label(side, "Выберите товар, затем место в зале.", 12)
	for i in range(3):
		shelf_buttons.append(button(side, "", expand_shelf.bind(i)))
	button(side, "Отменить строительство", cancel_build)
	button(side, "Расширить склад · 180 мон.", expand_warehouse)
	side = tab_page("Штат")
	label(side, "ПЕРСОНАЛ", 15)
	for i in range(3):
		staff_buttons.append(button(side, "", hire_role.bind(i)))
	button(side, "Убрать магазин вручную", manual_clean)
	var toolbar = HBoxContainer.new()
	root.add_child(toolbar)
	open_button = button(toolbar, "", toggle_shop)
	button(toolbar, "Сохранить", save_game)
	button(toolbar, "−", func(): visual.zoom(1.15))
	button(toolbar, "+", func(): visual.zoom(0.87))
	button(toolbar, "Поворот влево", func(): visual.rotate_view(-1))
	button(toolbar, "Поворот вправо", func(): visual.rotate_view(1))
	button(toolbar, "Сброс камеры", func(): visual.reset_view())
	hint = label(root, "", 16)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.y = 42

func tab_page(title: String) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	scroll.add_child(content)
	return content

func build_slot(i: int) -> Vector3:
	return Vector3(5.9+(i%3)*2.7,0,-2.1+floori(i/3.0)*3.0)

func cancel_build():
	build_kind=-1
	message="Строительство отменено."
	refresh()

func place_equipment(slot: int):
	if build_kind<0 or slot<0 or slot>=placements.size() or placements[slot]!=-1:
		return
	var i=build_kind
	var cost=150*shelf_levels[i]
	if shelf_levels[i]>=3 or cash<cost:
		cancel_build()
		return
	cash-=cost
	placements[slot]=i
	shelf_levels[i]+=1
	level+=1
	build_kind=-1
	message="Оборудование установлено: "+GOODS[i]
	refresh()
	save_game()

func expand_warehouse():
	if warehouse_level>=3 or cash<180:
		message="Недостаточно средств или склад уже максимальный."
		refresh()
		return
	cash-=180
	warehouse_level+=1
	message="Склад расширен."
	refresh()
	save_game()

func refresh():
	hud.text = "Баланс %d мон.   Ур. %d   Продано %d" % [cash, level, sold]
	for i in range(3):
		shop_rows[i].text = "%s %d/%d | склад %d | +5 за %d" % [GOODS[i],stock[i],capacity(i),storage[i],COST[i]*5]
		shop_rows[i].disabled = cash < COST[i]*5 or storage[i]+delivery[i]+incoming[i]+5 > 40*warehouse_level
		shelf_buttons[i].text = "%s: прилавок %d · %d мон." % [GOODS[i],shelf_levels[i],150*shelf_levels[i]]
		shelf_buttons[i].disabled = shelf_levels[i]>=3 or cash<150*shelf_levels[i]
	var counts = [workers,loaders,cleaners]
	var names = ["Продавец","Грузчик","Уборщик"]
	for i in range(3):
		staff_buttons[i].text = "%s %d/3 · нанять %d" % [names[i],counts[i],role_cost(i)]
		staff_buttons[i].disabled = counts[i]>=3 or cash<role_cost(i)
	open_button.text = "Закрыть магазин" if running else "Открыть магазин"
	info.text = "В пути: %d сек. | На разгрузке: %d\nЧистота: %d%% | Склад: %d/товар" % [ceili(delivery_eta),delivery[0]+delivery[1]+delivery[2],roundi(100-dirt),40*warehouse_level]
	hint.text = message

func capacity(i: int = 0) -> int:
	return 12*shelf_levels[i]

func role_cost(i: int) -> int:
	return [220*workers,140*(loaders+1),100*(cleaners+1)][i]

func buy(i: int):
	if cash<COST[i]*5 or storage[i]+delivery[i]+incoming[i]+5>40*warehouse_level:
		return
	cash -= COST[i]*5
	incoming[i] += 5
	if delivery_eta<=0:
		delivery_eta=6.0
	message = "Заказ поставщику: " + GOODS[i]
	refresh()
	save_game()

func expand_shelf(i: int):
	if shelf_levels[i]>=3 or cash<150*shelf_levels[i]:
		return
	build_kind=i
	message="Выберите свободную площадку справа от магазина."
	refresh()

func hire_role(i: int):
	var count: int = [workers,loaders,cleaners][i]
	if count>=3 or cash<role_cost(i):
		return
	cash -= role_cost(i)
	match i:
		0:
			workers += 1
			add_seller()
		1: loaders += 1
		2: cleaners += 1
	message = ["Продавец нанят","Грузчик нанят","Уборщик нанят"][i]
	refresh()
	save_game()

func manual_load():
	if loader_phase != 0:
		return
	for i in range(3):
		if delivery[i]>0:
			storage[i] += delivery[i]
			delivery[i] = 0
	for i in range(3):
		var amount = mini(storage[i],capacity(i)-stock[i])
		stock[i] += amount
		storage[i] -= amount
	message = "Товар разгружен, полки пополнены."
	refresh()
	save_game()

func manual_clean():
	dirt = 0
	message = "Магазин чистый."
	refresh()
	save_game()

func toggle_shop():
	running = not running
	elapsed = 0
	message = "Магазин открыт." if running else "Магазин закрыт. Завершаем обслуживание."
	refresh()

func counter(i: int) -> Vector3:
	return Vector3(3.1-i*2.7,0,2.3)

func shelf_pos(i: int) -> Vector3:
	# The original rack is used first; overflow is sold from installed racks.
	if stock[i]>12:
		var n=ceili(float(stock[i]-12)/12.0)
		for slot in range(placements.size()):
			if placements[slot]==i:
				n-=1
				if n<=0:
					return build_slot(slot)+Vector3(0,0,0.8)
	return Vector3(-3.25+i*3.1,0,-1.35)

func add_seller():
	var p = counter(sellers.size())+Vector3(0,0,-0.95)
	sellers.append({"pos":p,"phase":0,"customer":null,"item":-1,"timer":0.0,"carry":false})

func move_actor(actor: Dictionary, target: Vector3, delta: float, speed: float = 2.6) -> bool:
	var p: Vector3 = actor["pos"]
	actor["pos"] = p.move_toward(target,speed*delta)
	return actor["pos"].distance_to(target)<0.03

func _process(delta):
	if world == null:
		return
	if delivery_eta>0:
		delivery_eta=maxf(0,delivery_eta-delta)
		if delivery_eta<=0:
			for i in range(3):
				delivery[i]+=incoming[i]
				incoming[i]=0
			message="Грузовик прибыл. Разгрузите поставку."
			refresh()
			save_game()
	if running:
		elapsed += delta
		if elapsed>=maxf(3.0,6.0-workers*0.6+dirt*0.04) and customers.size()<6:
			elapsed = 0
			customers.append({"pos":Vector3(-4.1,0,3.65),"phase":0,"item":rng.randi_range(0,2),"timer":0.0,"carry":false,"counter":-1})
	for c in customers:
		if c["phase"]==0:
			var q = customers.find(c)
			move_actor(c,Vector3(-3.8+minf(q,4)*0.85,0,3.4),delta)
		elif c["phase"]==1:
			if move_actor(c,counter(c["counter"])+Vector3(0,0,0.95),delta):
				c["phase"]=2
		elif c["phase"]==4:
			if move_actor(c,Vector3(-4.1,0,3.7),delta):
				c["phase"]=5
	customers = customers.filter(func(c): return c["phase"]!=5)
	for i in range(sellers.size()):
		service(sellers[i],i,delta)
	update_loader(delta)
	if cleaners>0:
		cleaner_pos=cleaner_pos.move_toward(cleaner_target,delta*1.6)
		if cleaner_pos.distance_to(cleaner_target)<0.1:
			cleaner_target=Vector3(rng.randf_range(-4,2),0,rng.randf_range(-0.8,1.0))
		dirt=maxf(0,dirt-delta*cleaners*0.65)
	if running or not customers.is_empty():
		dirt=minf(100,dirt+delta*0.12)
	info.text = "В пути: %d сек. | На разгрузке: %d\nЧистота: %d%% | Склад: %d/товар" % [ceili(delivery_eta),delivery[0]+delivery[1]+delivery[2],roundi(100-dirt),40*warehouse_level]

func service(s: Dictionary, i: int, delta: float):
	var home = counter(i)+Vector3(0,0,-0.95)
	if s["phase"]==0:
		for c in customers:
			if c["phase"]==0:
				s["customer"]=c
				s["item"]=c["item"]
				c["counter"]=i
				c["phase"]=1
				s["phase"]=1
				break
		return
	var c: Dictionary = s["customer"]
	var item: int = s["item"]
	match s["phase"]:
		1:
			if c["phase"]==2:
				s["phase"]=2
				s["timer"]=0.6
				message="Заказ клиента: "+GOODS[item]
				refresh()
		2:
			s["timer"]-=delta
			if s["timer"]<=0:
				if stock[item]<=0:
					message="Нет товара: "+GOODS[item]
					c["phase"]=4
					s["phase"]=0
					refresh()
				else:
					s["phase"]=3
		3:
			if move_actor(s,shelf_pos(item),delta):
				if stock[item]<=0:
					c["phase"]=4
					s["phase"]=6
				else:
					# Reserve visually; stock is deducted only when paid.
					s["carry"]=true
					stock[item]-=1
					s["phase"]=4
					refresh()
		4:
			if move_actor(s,home,delta):
				s["carry"]=false
				c["carry"]=true
				s["phase"]=5
				s["timer"]=0.9
		5:
			s["timer"]-=delta
			if s["timer"]<=0:
				cash+=PRICE[item]
				revenue+=PRICE[item]
				sold+=1
				payment_events.append({"pos":counter(i),"amount":PRICE[item]})
				dirt=minf(100,dirt+2)
				c["phase"]=4
				s["phase"]=0
				message="Оплата: %s +%d мон." % [GOODS[item],PRICE[item]]
				refresh()
				save_game()
		6:
			if move_actor(s,home,delta):
				s["phase"]=0

func update_loader(delta: float):
	if loaders==0:
		return
	var dock = Vector3(-4.3,0,-0.2)
	var warehouse = Vector3(-4.3,0,1.35)
	var speed = 1.8+loaders*0.6
	match loader_phase:
		0:
			for i in range(3):
				if delivery[i]>0:
					loader_item=i
					loader_phase=1
					break
			if loader_phase==0:
				for i in range(3):
					if storage[i]>0 and stock[i]<capacity(i):
						loader_item=i
						loader_phase=3
						break
		1:
			loader_pos=loader_pos.move_toward(dock,speed*delta)
			if loader_pos.distance_to(dock)<0.03:
				loader_amount=mini(5,delivery[loader_item])
				delivery[loader_item]-=loader_amount
				loader_phase=2
		2:
			loader_pos=loader_pos.move_toward(warehouse,speed*delta)
			if loader_pos.distance_to(warehouse)<0.03:
				storage[loader_item]+=loader_amount
				loader_amount=0
				loader_phase=0
				refresh()
				save_game()
		3:
			loader_pos=loader_pos.move_toward(warehouse,speed*delta)
			if loader_pos.distance_to(warehouse)<0.03:
				loader_amount=mini(5,storage[loader_item])
				storage[loader_item]-=loader_amount
				loader_phase=4
		4:
			var target=shelf_pos(loader_item)+Vector3(0.4,0,0.2)
			loader_pos=loader_pos.move_toward(target,speed*delta)
			if loader_pos.distance_to(target)<0.03:
				var n=mini(loader_amount,capacity(loader_item)-stock[loader_item])
				stock[loader_item]+=n
				storage[loader_item]+=loader_amount-n
				loader_amount=0
				loader_phase=0
				refresh()
				save_game()

func save_game():
	# In-flight goods are restored to their source when a saved game is reopened.
	var saved_stock=stock.duplicate()
	var saved_storage=storage.duplicate()
	var saved_delivery=delivery.duplicate()
	for s in sellers:
		if s["phase"]==4 or s["phase"]==5:
			var i: int=s["item"]
			if saved_stock[i]<capacity(i):
				saved_stock[i]+=1
			else:
				saved_storage[i]+=1
	if loader_phase==2:
		saved_delivery[loader_item]+=loader_amount
	elif loader_phase==4:
		saved_storage[loader_item]+=loader_amount
	var f=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"version":3,"placements":placements,"warehouse_level":warehouse_level,"incoming":incoming,"delivery_eta":delivery_eta,"cash":cash,"stock":saved_stock,"storage":saved_storage,"delivery":saved_delivery,"shelf_levels":shelf_levels,"level":level,"sold":sold,"revenue":revenue,"workers":workers,"loaders":loaders,"cleaners":cleaners,"dirt":dirt}))

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data)!=TYPE_DICTIONARY:
		return
	cash=maxi(0,int(data.get("cash",500)))
	level=clampi(int(data.get("level",1)),1,10)
	sold=maxi(0,int(data.get("sold",0)))
	revenue=maxi(0,int(data.get("revenue",0)))
	workers=clampi(int(data.get("workers",1)),1,3)
	loaders=clampi(int(data.get("loaders",0)),0,3)
	cleaners=clampi(int(data.get("cleaners",0)),0,3)
	dirt=clampf(float(data.get("dirt",0)),0,100)
	warehouse_level=clampi(int(data.get("warehouse_level",1)),1,3)
	placements=data.get("placements",[-1,-1,-1,-1,-1,-1])
	incoming=data.get("incoming",[0,0,0])
	delivery_eta=maxf(0,float(data.get("delivery_eta",0)))
	for i in range(3):
		shelf_levels[i]=clampi(int(data.get("shelf_levels",[1,1,1])[i]),1,3)
		var old=maxi(0,int(data.get("stock",[8,8,8])[i]))
		stock[i]=mini(old,capacity(i))
		storage[i]=maxi(0,int(data.get("storage",[5,5,5])[i]))+old-stock[i]
		delivery[i]=maxi(0,int(data.get("delivery",[0,0,0])[i]))
	if int(data.get("version",1))<3:
		var slot=0
		for i in range(3):
			for j in range(shelf_levels[i]-1):
				placements[slot]=i
				slot+=1
