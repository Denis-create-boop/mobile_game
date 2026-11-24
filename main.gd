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
var workers: int = 0
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
	build_ui()
	refresh()

func style(bg: Color, radius: int = 12) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 7
	s.content_margin_bottom = 7
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
	b.custom_minimum_size.y = 42
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_stylebox_override("normal", style(Color("#286653")))
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
	world.draw.connect(draw_world)
	row.add_child(world)
	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = 290
	panel.add_theme_stylebox_override("panel", style(Color("#192e35")))
	row.add_child(panel)
	var side = VBoxContainer.new()
	side.add_theme_constant_override("separation", 6)
	panel.add_child(side)
	label(side, "УПРАВЛЕНИЕ МАГАЗИНОМ", 17)
	for i in range(GOODS.size()):
		shop_rows.append(button(side, "", buy.bind(i)))
	upgrade = button(side, "", expand_store)
	hire = button(side, "", hire_worker)
	open_button = button(side, "", toggle_shop)
	button(side, "Сохранить", save_game)
	hint = label(root, "", 16)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.y = 42

func refresh():
	hud.text = "₽ %d    Уровень %d    Продано %d" % [cash, level, sold]
	for i in range(GOODS.size()):
		shop_rows[i].text = "%s: %d шт.  |  +5 за ₽%d" % [GOODS[i], stock[i], COST[i]*5]
		shop_rows[i].disabled = cash < COST[i]*5 or stock[i]+5 > capacity()
	upgrade.text = "Расширить магазин · ₽%d" % upgrade_cost()
	upgrade.disabled = cash < upgrade_cost() or level >= 10
	hire.text = "Нанять кассира (%d/3) · ₽%d" % [workers, hire_cost()]
	hire.disabled = cash < hire_cost() or workers >= 3
	open_button.text = "Закрыть магазин" if running else "Открыть магазин"
	hint.text = message
	world.queue_redraw()

func capacity() -> int:
	return 20 + (level-1)*10

func upgrade_cost() -> int:
	return 250*level

func hire_cost() -> int:
	return 300*(workers+1)

func buy(i: int):
	if cash < COST[i]*5 or stock[i]+5 > capacity():
		return
	cash -= COST[i]*5
	stock[i] += 5
	message = "Поставка получена: " + GOODS[i]
	refresh()
	save_game()

func expand_store():
	if cash < upgrade_cost() or level >= 10:
		return
	cash -= upgrade_cost()
	level += 1
	message = "Магазин расширен! Вместимость и поток покупателей увеличены."
	refresh()
	save_game()

func hire_worker():
	if cash < hire_cost() or workers >= 3:
		return
	cash -= hire_cost()
	workers += 1
	message = "Кассир нанят. Обслуживание покупателей ускорено."
	refresh()
	save_game()

func toggle_shop():
	running = not running
	elapsed = 0
	message = "Магазин открыт. Следите за запасами." if running else "Магазин закрыт."
	refresh()

func _process(delta):
	if world == null:
		return
	if running:
		elapsed += delta
		var interval = maxf(0.8, 3.2 - 0.18*(level-1) - 0.4*workers)
		if elapsed >= interval:
			elapsed = 0.0
			sell()
	for customer in customers:
		customer["progress"] += delta * 0.45
	customers = customers.filter(func(c): return c["progress"] < 1.0)
	world.queue_redraw()

func sell():
	var i = rng.randi_range(0, GOODS.size()-1)
	customers.append({"progress": 0.0, "color": COLORS[i]})
	if stock[i] > 0:
		stock[i] -= 1
		cash += PRICE[i]
		revenue += PRICE[i]
		sold += 1
		message = "Покупатель купил %s · +₽%d" % [GOODS[i].to_lower(), PRICE[i]]
	else:
		message = "Покупатель ушёл: нет товара «%s»." % GOODS[i]
	refresh()
	save_game()

func iso(x: float, y: float, z: float = 0.0) -> Vector2:
	var scale_factor = minf(world.size.x/600.0, world.size.y/380.0)
	return Vector2(world.size.x*0.5, world.size.y*0.19) + Vector2((x-y)*35.0,(x+y)*17.0-z*35.0)*scale_factor

func poly(points: Array, color: Color):
	world.draw_colored_polygon(PackedVector2Array(points), color)

func block(x: float,y: float,w: float,d: float,h: float,color: Color,z: float=0.0):
	var a=iso(x,y,z+h)
	var b=iso(x+w,y,z+h)
	var c=iso(x+w,y+d,z+h)
	var e=iso(x,y+d,z+h)
	poly([e,c,iso(x+w,y+d,z),iso(x,y+d,z)],color.darkened(0.24))
	poly([b,c,iso(x+w,y+d,z),iso(x+w,y,z)],color.darkened(0.38))
	poly([a,b,c,e],color)

func draw_world():
	var sz = world.size
	world.draw_rect(Rect2(Vector2.ZERO,sz),Color("#142830"))
	for x in range(8):
		for y in range(7):
			var shade = Color("#c5d5c5") if (x+y)%2==0 else Color("#afc5b8")
			poly([iso(x-3,y),iso(x-2,y),iso(x-2,y+1),iso(x-3,y+1)],shade)
	for x in range(8):
		block(x-3,0,0.96,0.23,1.4,Color("#d6e6d9"))
	for y in range(7):
		block(-3,y,0.23,0.96,1.4,Color("#d6e6d9"))
	for i in range(3):
		var x = -2.3 + i*2.1
		block(x,1.1,1.6,0.65,0.75,Color("#805f43"))
		for j in range(mini(stock[i],8)):
			block(x+0.1+(j%4)*0.36,1.18+floori(j/4.0)*0.26,0.25,0.22,0.32,COLORS[i],0.75)
	block(2.7,5.1,1.4,0.8,0.9,Color("#4c9277"))
	block(3.0,5.2,0.48,0.35,0.32,Color("#243841"),0.9)
	for customer in customers:
		var p: float = customer["progress"]
		var x = lerpf(0.5,3.2,p)
		var y = 6.1 - sin(p*PI)*2.5
		block(x,y,0.38,0.38,0.7,customer["color"])
		block(x+0.03,y+0.03,0.32,0.32,0.32,Color("#e3b794"),0.7)
	var font = ThemeDB.fallback_font
	world.draw_string(font,Vector2(12,25),"МАГАЗИН • %s" % ("ОТКРЫТ" if running else "ЗАКРЫТ"),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#a9e8b0"))
	world.draw_string(font,Vector2(12,sz.y-12),"Выручка ₽%d   |   Вместимость %d на товар" % [revenue,capacity()],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#d0e1df"))

func save_game():
	var f = FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"cash":cash,"stock":stock,"level":level,"sold":sold,"revenue":revenue,"workers":workers}))

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return
	cash = maxi(0,int(data.get("cash",500)))
	level = clampi(int(data.get("level",1)),1,10)
	sold = maxi(0,int(data.get("sold",0)))
	revenue = maxi(0,int(data.get("revenue",0)))
	workers = clampi(int(data.get("workers",0)),0,3)
	var saved_stock = data.get("stock",[])
	if typeof(saved_stock)==TYPE_ARRAY and saved_stock.size()==3:
		for i in range(3):
			stock[i] = clampi(int(saved_stock[i]),0,capacity())
