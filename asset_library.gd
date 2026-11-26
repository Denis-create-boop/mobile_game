extends RefCounted
var catalog: Dictionary = {}
var cache: Dictionary = {}
var loaded_count: int = 0
var fallback_count: int = 0
func _init():
	if FileAccess.file_exists("res://assets/kenney/catalog.json"):
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/kenney/catalog.json"))
		if data is Dictionary:
			catalog=data

func pick(pack: String, names: Array) -> String:
	var entries: Dictionary=catalog.get(pack,{})
	for name in names:
		if entries.has(name):
			return entries[name]
	for name in names:
		for key in entries:
			if String(key).begins_with(name):
				return entries[key]
	return ""

func spawn(pack: String, names: Array, parent: Node3D, pos: Vector3, target: Vector3) -> Node3D:
	var path=pick(pack,names)
	if path.is_empty() or not ResourceLoader.exists(path):
		fallback_count+=1
		return null
	if not cache.has(path):
		cache[path]=load(path)
	var scene=cache[path]
	if not scene is PackedScene:
		fallback_count+=1
		return null
	var holder=Node3D.new()
	parent.add_child(holder)
	holder.position=pos
	var model=scene.instantiate() as Node3D
	if model==null:
		holder.queue_free()
		fallback_count+=1
		return null
	holder.add_child(model)
	var bounds=AABB()
	var found=false
	var meshes=model.find_children("*","MeshInstance3D",true,false)
	if model is MeshInstance3D:
		meshes.push_front(model)
	for child in meshes:
		var m=child as MeshInstance3D
		var local=Transform3D.IDENTITY
		var cursor: Node3D=m
		while cursor!=holder and cursor!=null:
			local=cursor.transform*local
			cursor=cursor.get_parent() as Node3D
		var a=local*m.get_aabb()
		bounds=bounds.merge(a) if found else a
		found=true
	if not found or bounds.size.length()<0.001:
		holder.queue_free()
		return null
	var ratio=minf(target.x/maxf(bounds.size.x,0.001),minf(target.y/maxf(bounds.size.y,0.001),target.z/maxf(bounds.size.z,0.001)))
	model.scale*=ratio
	model.position-=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*ratio
	loaded_count+=1
	return holder

func food(kind: int,parent: Node3D,pos: Vector3) -> Node3D:
	var names=[["bread","baguette","loaf"],["milk","carton"],["apple"],["cheese"],["juice","bottle"],["coffee","coffeecup"],["chocolate"],["carrot","broccoli","lettuce"],["yogurt","milk"],["tea","teacup"],["pasta","spaghetti"],["icecream"]]
	return spawn("food",names[kind],parent,pos,Vector3(0.47,0.48,0.46))
