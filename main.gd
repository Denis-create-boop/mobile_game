extends Control

const SAVE_PATH = "user://market.json"
const GOODS = ["Хлеб", "Молоко", "Яблоки", "Сыр", "Сок", "Кофе", "Шоколад", "Овощи", "Йогурт", "Чай", "Макароны", "Мороженое"]
const COST = [12,18,10,24,15,32,18,12,16,22,14,25]
const PRICE = [22,32,19,43,28,59,34,23,29,40,26,46]
const COLORS = [Color("#d6a660"), Color("#91c9ed"), Color("#e17c68")]
var menu: PanelContainer
var sound: AudioStreamPlayer
var muted: bool = false
var supplier: int = 0
var supplier_button: Button
var rewards: Array = []
var inventory_cost: Array = [156,234,130]
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
var placements: Array = [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]
var area_level: int = 1
var area_button: Button
var reputation: float = 60.0
var promo_left: float = 0.0
var promo_button: Button
var autosave_clock: float = 0.0
var delivery_duration: float = 6.0
var build_kind: int = -1
var visual: Control
var tabs: TabContainer
var delivery_eta: float = 0.0
var incoming: Array = [0,0,0]
var payment_events: Array = []
var prices: Array = [22,32,19]
var expenses: int = 0
var cost_of_sales: int = 0
var lost_sales: int = 0
var day_number: int = 1
var day_clock: float = 0.0
var finance_label: Label
var price_labels: Array[Label] = []
var goals_label: Label
var loader_tasks: Array = []
var cleaner_tasks: Array = []
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
var show_locked: bool = false
var filter_button: Button
var stock_status: Label
var music: AudioStreamPlayer
var music_enabled: bool = true
var upgrade: Button
var hire: Button
var open_button: Button
var world: Control
var rng = RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	normalize_catalog()
	load_game()
	normalize_catalog()
	for i in range(workers):
		add_seller()
	for i in range(loaders):
		add_loader()
	for i in range(cleaners):
		add_cleaner()
	build_ui()
	setup_sound()
	setup_music()
	refresh()
	show_menu()

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
	b.custom_minimum_size.y = 35
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_stylebox_override("normal", style(Color("#356c60")))
	b.add_theme_stylebox_override("hover", style(Color("#438c77")))
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
	panel.custom_minimum_size.x = 318
	panel.add_theme_stylebox_override("panel", style(Color("#203038")))
	row.add_child(panel)
	tabs = TabContainer.new()
	tabs.add_theme_font_size_override("font_size", 13)
	tabs.add_theme_stylebox_override("panel", style(Color("#17262e")))
	tabs.add_theme_stylebox_override("tab_selected", style(Color("#356c60"),6))
	tabs.add_theme_stylebox_override("tab_unselected", style(Color("#263a42"),6))
	panel.add_child(tabs)
	var side = tab_page("Товары")
	label(side, "ПОСТАВКИ · ПОЛКА / СКЛАД", 15)
	supplier_button=button(side,"",switch_supplier)
	info = label(side, "", 13)
	button(side, "Разгрузить / пополнить вручную", manual_load)
	filter_button=button(side,"",toggle_catalog)
	for i in range(GOODS.size()):
		shop_rows.append(button(side, "", buy.bind(i)))
	side = tab_page("Стройка")
	label(side, "РАЗМЕЩЕНИЕ ОБОРУДОВАНИЯ", 14)
	label(side, "Выберите товар, затем место в зале.", 12)
	for i in range(GOODS.size()):
		shelf_buttons.append(button(side, "", expand_shelf.bind(i)))
	button(side, "Отменить строительство", cancel_build)
	button(side, "Расширить склад · 180 мон.", expand_warehouse)
	area_button=button(side,"",expand_area)
	side = tab_page("Штат")
	label(side, "ПЕРСОНАЛ", 15)
	for i in range(3):
		staff_buttons.append(button(side, "", hire_role.bind(i)))
	button(side, "Убрать магазин вручную", manual_clean)
	side = tab_page("Отчёт")
	label(side, "ЭКОНОМИКА", 16)
	finance_label=label(side, "", 13)
	promo_button=button(side,"",start_promo)
	label(side, "ЦЕНЫ ПРОДАЖИ", 15)
	for i in range(GOODS.size()):
		var price_row=HBoxContainer.new()
		side.add_child(price_row)
		button(price_row,"−",change_price.bind(i,-1))
		var price_label=label(price_row,"",13)
		price_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		price_labels.append(price_label)
		button(price_row,"+",change_price.bind(i,1))
	goals_label=label(side,"",13)
	goals_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var toolbar = HBoxContainer.new()
	root.add_child(toolbar)
	open_button = button(toolbar, "", toggle_shop)
	button(toolbar, "Меню", show_menu)
	button(toolbar, "Сохранить", save_game)
	button(toolbar, "−", func(): visual.zoom(1.15))
	button(toolbar, "+", func(): visual.zoom(0.87))
	button(toolbar, "↶", func(): visual.rotate_view(-1))
	button(toolbar, "↷", func(): visual.rotate_view(1))
	button(toolbar, "Обзор", func(): visual.overview())
	button(toolbar, "Сброс", func(): visual.reset_view())
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
	return Vector3(5.9+(i%3)*2.7,0,-2.1+floori(i/3.0)*2.25)

func cancel_build():
	build_kind=-1
	message="Строительство отменено."
	refresh()

func place_equipment(slot: int):
	if build_kind<0 or slot<0 or slot>=active_slots() or placements[slot]!=-1:
		return
	var i=build_kind
	var cost=equipment_cost(i)
	if shelf_levels[i]>=3 or cash<cost or not unlocked(i):
		cancel_build()
		return
	cash-=cost
	expenses+=cost
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
	expenses+=180
	warehouse_level+=1
	message="Склад расширен."
	refresh()
	save_game()

func change_price(i: int, direction: int):
	prices[i]=clampi(int(prices[i])+direction*2,COST[i],PRICE[i]*2)
	refresh()
	save_game()

func refresh_finance():
	if finance_label==null:
		return
	finance_label.text="Репутация: %d%%\nАссортимент: %d/%d\nДень %d · %d%% смены\nВыручка: %d\nСебестоимость продаж: %d\nОперационные расходы: %d\nПрибыль от продаж: %d\nУшли без покупки: %d" % [roundi(reputation),active_products().size(),GOODS.size(),day_number,roundi(day_clock/1.2),revenue,cost_of_sales,expenses,revenue-cost_of_sales-expenses,lost_sales]
	for i in range(GOODS.size()):
		price_labels[i].text="%s · %d мон." % [GOODS[i],prices[i]]
	goals_label.text="Достижения: %d/5\n" % rewards.size()+"ЦЕЛИ\n%s  Продать 50 товаров (%d/50)\n%s  Нанять грузчика\n%s  Построить 3 новых полки" % ["✓" if sold>=50 else "○",mini(sold,50),"✓" if loaders>0 else "○","✓" if level>=4 else "○"]

func refresh():
	hud.text = "Баланс %d мон.   Ур. %d   Продано %d" % [cash, level, sold]
	filter_button.text="Показать все товары" if not show_locked else "Только открытые товары"
	for i in range(GOODS.size()):
		shop_rows[i].visible=show_locked or shelf_levels[i]>0
		shop_rows[i].text = "%s %d/%d | склад %d | +5 за %d" % [GOODS[i],stock[i],capacity(i),storage[i],supplier_cost(i)*5]
		shop_rows[i].disabled = shelf_levels[i]==0 or cash < supplier_cost(i)*5 or storage[i]+delivery[i]+incoming[i]+5 > 40*warehouse_level
		shelf_buttons[i].text = "%s: %d полок · %d мон." % [GOODS[i],shelf_levels[i],equipment_cost(i)]
		if not unlocked(i):
			shelf_buttons[i].text=GOODS[i]+" · откроется на ур. "+str(unlock_level(i))
		if shelf_levels[i]==0:
			shop_rows[i].text=GOODS[i]+" · нужен прилавок"
		shelf_buttons[i].disabled = shelf_levels[i]>=3 or cash<equipment_cost(i) or not unlocked(i)
	var counts = [workers,loaders,cleaners]
	var names = ["Продавец","Грузчик","Уборщик"]
	for i in range(3):
		staff_buttons[i].text = "%s %d/3 · нанять %d" % [names[i],counts[i],role_cost(i)]
		staff_buttons[i].disabled = counts[i]>=3 or cash<role_cost(i)
	area_button.text="Расширить зал (%d/2) · 450 мон." % area_level
	area_button.disabled=area_level>=2 or cash<450
	promo_button.text="Реклама: %d сек." % ceili(promo_left) if promo_left>0 else "Реклама · 60 мон. / 45 сек."
	promo_button.disabled=promo_left>0 or cash<60
	open_button.text = "Закрыть магазин" if running else "Открыть магазин"
	info.text = "В пути: %d сек. | На разгрузке: %d\nЧистота: %d%% | Склад: %d/товар" % [ceili(delivery_eta),sum_items(delivery),roundi(100-dirt),40*warehouse_level]
	hint.text = message
	supplier_button.text=["Местный · 6 сек.","Оптовик · 12 сек. / скидка","Экспресс · 3 сек. / доплата"][supplier]
	refresh_finance()

func capacity(i: int = 0) -> int:
	return 12*shelf_levels[i]

func role_cost(i: int) -> int:
	return [220*workers,140*(loaders+1),100*(cleaners+1)][i]

func buy(i: int):
	if shelf_levels[i]==0 or cash<supplier_cost(i)*5 or storage[i]+delivery[i]+incoming[i]+5>40*warehouse_level:
		return
	cash -= supplier_cost(i)*5
	inventory_cost[i] += supplier_cost(i)*5
	incoming[i] += 5
	if delivery_eta<=0:
		delivery_eta=[6.0,12.0,3.0][supplier]
		delivery_duration=delivery_eta
	message = "Заказ поставщику: " + GOODS[i]
	refresh()
	save_game()

func expand_shelf(i: int):
	if shelf_levels[i]>=3 or cash<equipment_cost(i) or not unlocked(i):
		return
	if not placements.slice(0,active_slots()).has(-1):
		message="Нет свободных площадок. Расширьте зал."
		refresh()
		return
	build_kind=i
	message="Выберите свободную площадку справа от магазина."
	refresh()

func hire_role(i: int):
	var count: int = [workers,loaders,cleaners][i]
	if count>=3 or cash<role_cost(i):
		return
	cash -= role_cost(i)
	expenses += role_cost(i)
	match i:
		0:
			workers += 1
			add_seller()
		1:
			loaders += 1
			add_loader()
		2:
			cleaners += 1
			add_cleaner()
	message = ["Продавец нанят","Грузчик нанят","Уборщик нанят"][i]
	refresh()
	save_game()

func manual_load():
	for task in loader_tasks:
		if task["phase"]!=0:
			message="Грузчики работают. Дождитесь окончания разгрузки."
			refresh()
			return
	for i in range(GOODS.size()):
		if delivery[i]>0:
			storage[i] += delivery[i]
			delivery[i] = 0
	for i in range(GOODS.size()):
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
	var base=12 if i<3 else 0
	if stock[i]>base or i>=3:
		var n=maxi(1,ceili(float(stock[i]-base)/12.0))
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
	if world == null or (menu!=null and menu.visible):
		return
	autosave_clock+=delta
	if autosave_clock>=15:
		autosave_clock=0
		save_game()
	if delivery_eta>0:
		delivery_eta=maxf(0,delivery_eta-delta)
		if delivery_eta<=0:
			for i in range(GOODS.size()):
				delivery[i]+=incoming[i]
				incoming[i]=0
			message="Грузовик прибыл. Разгрузите поставку."
			refresh()
			save_game()
	if promo_left>0:
		promo_left=maxf(0,promo_left-delta)
		if promo_left==0:
			refresh()
	if running:
		day_clock+=delta
		if day_clock>=120.0:
			day_clock-=120.0
			day_number+=1
			var wages=12*workers+8*loaders+6*cleaners
			var rent=15+warehouse_level*5
			var bill=wages+rent
			cash-=bill
			expenses+=bill
			message="Новая смена. Зарплата и аренда: −%d мон." % bill
			if cash<0:
				message+=" Баланс отрицательный: продолжайте продажи."
			refresh()
			save_game()
		elapsed += delta
		if running and elapsed>=maxf(1.8,6.0-workers*0.6+dirt*0.04-reputation*0.018-(1.4 if promo_left>0 else 0.0)) and customers.size()<6:
			elapsed = 0
			customers.append({"pos":Vector3(-4.1,0,3.65),"phase":0,"item":choose_product(),"timer":0.0,"carry":false,"counter":-1})
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
	for task in loader_tasks:
		update_loader_task(task,delta)
	for task in cleaner_tasks:
		update_cleaner_task(task,delta)
	if cleaners>0:
		dirt=maxf(0,dirt-delta*cleaners*0.65)
	if running or not customers.is_empty():
		dirt=minf(100,dirt+delta*0.12)
	check_rewards()
	if tabs.current_tab==3:
		refresh_finance()
	info.text = "В пути: %d сек. | На разгрузке: %d\nЧистота: %d%% | Склад: %d/товар" % [ceili(delivery_eta),sum_items(delivery),roundi(100-dirt),40*warehouse_level]

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
				if stock[item]<=0 or (prices[item]>PRICE[item]*1.25 and rng.randf()<float(prices[item]-PRICE[item])/float(PRICE[item])):
					lost_sales+=1
					reputation=maxf(0,reputation-1.5)
					message="Клиент ушёл: нет товара или высокая цена."
					c["phase"]=4
					s["phase"]=0
					refresh()
				else:
					s["phase"]=3
					s["target"]=shelf_pos(item)
		3:
			if move_staff(s,s["target"],delta):
				if stock[item]<=0:
					lost_sales+=1
					reputation=maxf(0,reputation-1.5)
					c["phase"]=4
					s["phase"]=6
				else:
					# Reserve visually; stock is deducted only when paid.
					s["carry"]=true
					stock[item]-=1
					s["phase"]=4
					refresh()
		4:
			if move_staff(s,home,delta):
				s["carry"]=false
				c["carry"]=true
				s["phase"]=5
				s["timer"]=0.9
		5:
			s["timer"]-=delta
			if s["timer"]<=0:
				cash+=prices[item]
				revenue+=prices[item]
				var remaining: int=stock[item]+storage[item]+delivery[item]+incoming[item]+1
				for task in loader_tasks:
					if task["item"]==item:
						remaining+=task["amount"]
				for other in sellers:
					if other!=s and other["item"]==item and other["phase"] in [4,5]:
						remaining+=1
				var unit_cost=clampi(roundi(float(inventory_cost[item])/maxi(1,remaining)),0,int(inventory_cost[item]))
				inventory_cost[item]-=unit_cost
				cost_of_sales+=unit_cost
				play_sound()
				sold+=1
				reputation=minf(100,reputation+0.7)
				payment_events.append({"pos":counter(i),"amount":prices[item]})
				dirt=minf(100,dirt+2)
				c["phase"]=4
				s["phase"]=0
				message="Оплата: %s +%d мон." % [GOODS[item],prices[item]]
				refresh()
				save_game()
		6:
			if move_actor(s,home,delta):
				s["phase"]=0

func add_loader():
	loader_tasks.append({"pos":Vector3(-4.0,0,0.6+loader_tasks.size()*0.4),"phase":0,"item":-1,"amount":0,"target":Vector3.ZERO})

func add_cleaner():
	var p=Vector3(-3.0+cleaner_tasks.size(),0,1.0)
	cleaner_tasks.append({"pos":p,"target":p})

func update_cleaner_task(task: Dictionary, delta: float):
	if move_actor(task,task["target"],delta,1.5):
		task["target"]=Vector3(rng.randf_range(-3.4,3.5),0,rng.randf_range(-0.8,1.0))

func update_loader_task(task: Dictionary, delta: float):
	var dock=Vector3(-3.9,0,-0.25)
	var warehouse=Vector3(-3.9,0,1.35)
	var item: int=task["item"]
	match int(task["phase"]):
		0:
			for i in range(GOODS.size()):
				if delivery[i]>0:
					task["item"]=i
					task["phase"]=1
					return
			for i in range(GOODS.size()):
				if storage[i]>0 and stock[i]<capacity(i):
					task["item"]=i
					task["phase"]=3
					return
		1:
			if move_actor(task,dock,delta,2.4):
				var amount=mini(5,delivery[item])
				delivery[item]-=amount
				task["amount"]=amount
				task["phase"]=2 if amount>0 else 0
		2:
			if move_actor(task,warehouse,delta,2.4):
				storage[item]+=task["amount"]
				task["amount"]=0
				task["phase"]=0
				refresh()
				save_game()
		3:
			if move_actor(task,warehouse,delta,2.4):
				var amount=mini(5,mini(storage[item],capacity(item)-stock[item]))
				storage[item]-=amount
				task["amount"]=amount
				task["target"]=shelf_pos(item)+Vector3(0.35,0,0.25)
				task["phase"]=4 if amount>0 else 0
		4:
			if move_staff(task,task["target"],delta,2.4):
				var n=mini(task["amount"],capacity(item)-stock[item])
				stock[item]+=n
				storage[item]+=task["amount"]-n
				task["amount"]=0
				task["phase"]=0
				refresh()
				save_game()

func unloading() -> bool:
	for task in loader_tasks:
		if task["phase"]==2:
			return true
	return false

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
	for task in loader_tasks:
		var i: int=task["item"]
		if task["phase"]==2:
			saved_delivery[i]+=task["amount"]
		elif task["phase"]==4:
			saved_storage[i]+=task["amount"]
	var f=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"version":7,"music_enabled":music_enabled,"area_level":area_level,"reputation":reputation,"promo_left":promo_left,"delivery_duration":delivery_duration,"supplier":supplier,"muted":muted,"rewards":rewards,"inventory_cost":inventory_cost,"prices":prices,"expenses":expenses,"cost_of_sales":cost_of_sales,"lost_sales":lost_sales,"day_number":day_number,"day_clock":day_clock,"placements":placements,"warehouse_level":warehouse_level,"incoming":incoming,"delivery_eta":delivery_eta,"cash":cash,"stock":saved_stock,"storage":saved_storage,"delivery":saved_delivery,"shelf_levels":shelf_levels,"level":level,"sold":sold,"revenue":revenue,"workers":workers,"loaders":loaders,"cleaners":cleaners,"dirt":dirt}))

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data=JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data)!=TYPE_DICTIONARY:
		return
	cash=int(data.get("cash",500))
	supplier=clampi(int(data.get("supplier",0)),0,2)
	muted=bool(data.get("muted",false))
	music_enabled=bool(data.get("music_enabled",true))
	rewards=data.get("rewards",[])
	level=maxi(1,int(data.get("level",1)))
	area_level=clampi(int(data.get("area_level",1)),1,2)
	reputation=clampf(float(data.get("reputation",60)),0,100)
	promo_left=clampf(float(data.get("promo_left",0)),0,45)
	delivery_duration=maxf(1,float(data.get("delivery_duration",6)))
	sold=maxi(0,int(data.get("sold",0)))
	revenue=maxi(0,int(data.get("revenue",0)))
	workers=clampi(int(data.get("workers",1)),1,3)
	loaders=clampi(int(data.get("loaders",0)),0,3)
	cleaners=clampi(int(data.get("cleaners",0)),0,3)
	dirt=clampf(float(data.get("dirt",0)),0,100)
	warehouse_level=clampi(int(data.get("warehouse_level",1)),1,3)
	placements=data.get("placements",[-1,-1,-1,-1,-1,-1])
	incoming=data.get("incoming",[0,0,0])
	normalize_catalog()
	delivery_eta=maxf(0,float(data.get("delivery_eta",0)))
	prices=data.get("prices",[22,32,19])
	expenses=maxi(0,int(data.get("expenses",0)))
	cost_of_sales=maxi(0,int(data.get("cost_of_sales",0)))
	lost_sales=maxi(0,int(data.get("lost_sales",0)))
	day_number=maxi(1,int(data.get("day_number",1)))
	day_clock=clampf(float(data.get("day_clock",0)),0,119.99)
	for i in range(GOODS.size()):
		shelf_levels[i]=clampi(int(array_value(data.get("shelf_levels",[]),i,1 if i<3 else 0)),0,3)
		var old=maxi(0,int(array_value(data.get("stock",[]),i,8 if i<3 else 0)))
		stock[i]=mini(old,capacity(i))
		storage[i]=maxi(0,int(array_value(data.get("storage",[]),i,5 if i<3 else 0)))+old-stock[i]
		delivery[i]=maxi(0,int(array_value(data.get("delivery",[]),i,0)))
	for i in range(GOODS.size()):
		if i>=prices.size():
			prices.append(PRICE[i])
		prices[i]=clampi(int(array_value(prices,i,PRICE[i])),COST[i],PRICE[i]*2)
	inventory_cost=data.get("inventory_cost",[])
	if inventory_cost.is_empty():
		for i in range(GOODS.size()):
			inventory_cost.append((stock[i]+storage[i]+delivery[i]+incoming[i])*COST[i])
	if int(data.get("version",1))<3:
		var slot=0
		for i in range(3):
			for j in range(shelf_levels[i]-1):
				placements[slot]=i
				slot+=1

func supplier_cost(i: int) -> int:
	return maxi(1,COST[i]+[0,-2,3][supplier])

func switch_supplier():
	supplier=(supplier+1)%3
	refresh()
	save_game()

func setup_sound():
	sound=AudioStreamPlayer.new()
	add_child(sound)
	var wav=AudioStreamWAV.new()
	wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate=22050
	var bytes=PackedByteArray()
	bytes.resize(8820)
	for i in range(4410):
		var t=float(i)/22050.0
		var f=660.0 if t<0.09 else 880.0
		var envelope=minf(1,t*150)*maxf(0,1-t/0.2)
		bytes.encode_s16(i*2,roundi(sin(t*TAU*f)*envelope*5500))
	wav.data=bytes
	sound.stream=wav

func play_sound():
	if not muted and sound!=null:
		sound.play()

func check_rewards():
	var conditions=[sold>=10,sold>=50,loaders>0,cleaners>0,placements.count(-1)<=3]
	var bonuses=[50,150,60,40,200]
	var names=["Первые продажи","Пятьдесят продаж","Первая доставка","Чистый магазин","Расширение бизнеса"]
	for i in range(conditions.size()):
		if conditions[i] and not rewards.has(i):
			rewards.append(i)
			cash+=bonuses[i]
			message="Достижение: %s! +%d мон." % [names[i],bonuses[i]]
			refresh()
			save_game()

func show_menu():
	if menu!=null:
		menu.visible=true
		return
	menu=PanelContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_theme_stylebox_override("panel",style(Color("#10242d"),0))
	add_child(menu)
	var center=CenterContainer.new()
	menu.add_child(center)
	var column=VBoxContainer.new()
	column.custom_minimum_size.x=400
	column.add_theme_constant_override("separation",12)
	center.add_child(column)
	var heading=label(column,"MARKET EMPIRE",40)
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color",Color("#a9e8b0"))
	var subtitle=label(column,"Построй свою торговую империю",19)
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	button(column,"Продолжить игру",func(): menu.hide())
	button(column,"Как играть",show_help)
	button(column,"Графика: сменить качество",func(): visual.toggle_quality())
	var mb=button(column,"Музыка: "+("вкл." if music_enabled else "выкл."),toggle_music)
	mb.name="MusicToggle"
	var toggle=button(column,"Звук: "+("выкл." if muted else "вкл."),toggle_sound)
	toggle.name="SoundToggle"
	button(column,"Новая игра",confirm_reset)

func toggle_sound():
	muted=not muted
	var b=menu.find_child("SoundToggle",true,false)
	if b!=null:
		b.text="Звук: "+("выкл." if muted else "вкл.")
	save_game()

func show_help():
	var d=AcceptDialog.new()
	d.title="Как играть"
	d.dialog_text="1. Открой магазин: продавец обслуживает клиентов.\n2. Заказывай товары, дождись поставки и пополни полки.\n3. Найми грузчика для автоматической разгрузки.\n4. Уборщик поддерживает чистоту.\n5. В стройке выбери оборудование и свободное место.\n6. В отчёте меняй цены и следи за расходами."
	add_child(d)
	d.confirmed.connect(d.queue_free)
	d.close_requested.connect(d.queue_free)
	d.popup_centered(Vector2i(570,300))

func confirm_reset():
	var d=ConfirmationDialog.new()
	d.title="Начать заново?"
	d.dialog_text="Текущий игровой прогресс будет удалён."
	add_child(d)
	d.confirmed.connect(func():
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		get_tree().reload_current_scene()
	)
	d.canceled.connect(d.queue_free)
	d.popup_centered()

func array_value(values: Array, i: int, fallback: int) -> int:
	return int(values[i]) if i<values.size() else fallback

func normalize_catalog():
	for values in [stock,storage,delivery,incoming,shelf_levels,inventory_cost]:
		while values.size()<GOODS.size():
			values.append(0)
	while prices.size()<GOODS.size():
		prices.append(PRICE[prices.size()])
	while placements.size()<12:
		placements.append(-1)
	for i in range(placements.size()):
		placements[i]=int(placements[i])

func sum_items(values: Array) -> int:
	var total=0
	for n in values:
		total+=int(n)
	return total

func active_slots() -> int:
	return 6 if area_level==1 else 12

func active_products() -> Array:
	var result=[]
	for i in range(GOODS.size()):
		if shelf_levels[i]>0:
			result.append(i)
	return result

func choose_product() -> int:
	var options=active_products()
	return int(options[rng.randi_range(0,options.size()-1)]) if not options.is_empty() else 0

func unlock_level(i: int) -> int:
	return [1,1,1,2,2,3,3,4,4,5,5,6][i]

func unlocked(i: int) -> bool:
	return level>=unlock_level(i)

func equipment_cost(i: int) -> int:
	return 150*maxi(1,shelf_levels[i]) if i<3 else 180+50*shelf_levels[i]

func expand_area():
	if area_level>=2 or cash<450:
		return
	area_level=2
	cash-=450
	expenses+=450
	message="Открыт новый торговый зал: ещё 6 площадок!"
	refresh()
	save_game()

func start_promo():
	if promo_left>0 or cash<60:
		return
	cash-=60
	expenses+=60
	promo_left=45
	message="Реклама запущена. Покупателей станет больше."
	refresh()
	save_game()

# Use the cross aisle and side aisles instead of crossing the display racks.
func move_staff(actor: Dictionary, target: Vector3, delta: float, speed: float=2.6) -> bool:
	var p: Vector3=actor["pos"]
	if not actor.has("route_target") or actor["route_target"]!=target or (actor["route"].is_empty() and p.distance_to(target)>0.04):
		var route: Array=[]
		if p.x>4.5 or target.x>4.5:
			# Cross the expansion via the corridor beside the original shop.
			var from_side=4.55
			if p.x>4.5:
				route.append(Vector3(from_side,0,p.z))
			route.append(Vector3(from_side,0,target.z))
		route.append(target)
		actor["route"]=route
		actor["route_target"]=target
	var path: Array=actor["route"]
	if path.is_empty():
		return true
	if move_actor(actor,path[0],delta,speed):
		path.pop_front()
	return path.is_empty()

func toggle_catalog():
	show_locked=not show_locked
	refresh()

func toggle_music():
	music_enabled=not music_enabled
	if music_enabled:
		music.play()
	else:
		music.stop()
	var b=menu.find_child("MusicToggle",true,false)
	if b!=null:
		b.text="Музыка: "+("вкл." if music_enabled else "выкл.")
	save_game()

# Original synthesized ambient accompaniment. No third-party recordings.
func setup_music():
	music=AudioStreamPlayer.new()
	music.volume_db=-19
	add_child(music)
	var wav=AudioStreamWAV.new()
	wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate=22050
	var seconds=16
	var samples=seconds*22050
	var bytes=PackedByteArray()
	bytes.resize(samples*2)
	var chords=[[48,55,60,64],[45,52,57,60],[41,48,53,57],[43,50,55,59]]
	for i in range(samples):
		var t=float(i)/22050.0
		var chord=chords[mini(3,floori(t/4.0))]
		var local=fmod(t,4.0)
		var env=minf(1.0,local*3.0)*minf(1.0,(4.0-local)*3.0)
		var tone=0.0
		for note in chord:
			var hz=440.0*pow(2.0,(float(note)-69.0)/12.0)
			tone+=sin(TAU*hz*t)*0.17+sin(TAU*hz*2.0*t)*0.025
		var beat=fmod(t,0.5)
		var pitch=float(chord[floori(local*2.0)%4])+12.0
		var melody=sin(TAU*440.0*pow(2.0,(pitch-69.0)/12.0)*t)*exp(-beat*7.0)*minf(1.0,beat*100.0)*0.13
		bytes.encode_s16(i*2,roundi((tone*env+melody)*10000))
	wav.data=bytes
	wav.loop_mode=AudioStreamWAV.LOOP_FORWARD
	wav.loop_end=samples
	music.stream=wav
	if music_enabled:
		music.play()
