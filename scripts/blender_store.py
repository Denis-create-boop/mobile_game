import bpy, math, random, os, sys
from mathutils import Vector
from pathlib import Path
random.seed(18)
out=Path(sys.argv[sys.argv.index("--")+1]).resolve()
out.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
def mat(name,c,rough=.48,metal=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*c,1); m.use_nodes=True
    p=m.node_tree.nodes.get("Principled BSDF"); p.inputs["Base Color"].default_value=(*c,1); p.inputs["Roughness"].default_value=rough; p.inputs["Metallic"].default_value=metal
    return m
def textured(name,c,scale,rough):
    m=mat(name,c,rough); n=m.node_tree.nodes; l=m.node_tree.links; p=n.get("Principled BSDF")
    noise=n.new("ShaderNodeTexNoise"); noise.inputs["Scale"].default_value=scale; noise.inputs["Detail"].default_value=3
    ramp=n.new("ShaderNodeValToRGB"); ramp.color_ramp.elements[0].color=(*(v*.72 for v in c),1); ramp.color_ramp.elements[1].color=(*(min(1,v*1.18) for v in c),1)
    l.new(noise.outputs["Fac"],ramp.inputs[0]); l.new(ramp.outputs[0],p.inputs["Base Color"])
    bump=n.new("ShaderNodeBump"); bump.inputs["Strength"].default_value=.13; bump.inputs["Distance"].default_value=.025; l.new(noise.outputs["Fac"],bump.inputs["Height"]); l.new(bump.outputs[0],p.inputs["Normal"])
    return m
wood=textured("Warm oak",(.43,.25,.12),6,.43)
tile=textured("Porcelain stone",(.51,.46,.39),36,.32)
dark=mat("Anthracite",(.055,.065,.075),.32)
steel=mat("Brushed stainless steel",(.34,.38,.42),.25,.72)
rubber=mat("Belt",(.025,.027,.03),.65)
wall=textured("Warm plaster",(.26,.23,.20),22,.72)
grout=mat("Grout",(.23,.21,.18),.8)
carton=mat("Kraft",(.49,.31,.15),.73)
white=mat("Cream labels",(.86,.82,.69))
green=mat("Leaf",(.12,.30,.05))
colors=[mat("Package "+str(i),c,.36) for i,c in enumerate([(.65,.055,.025),(.92,.43,.025),(.025,.24,.57),(.12,.39,.06),(.64,.49,.12),(.31,.065,.12),(.78,.76,.64)])]
glow=mat("Warm LED",(.95,.74,.38)); p=glow.node_tree.nodes.get("Principled BSDF"); p.inputs["Emission Color" if "Emission Color" in p.inputs else "Emission"].default_value=(1,.65,.27,1); p.inputs["Emission Strength"].default_value=3
def assign(o,m): o.data.materials.append(m); return o
def box(n,p,d,m,bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1,location=p); o=bpy.context.object; o.name=n; o.dimensions=d; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); assign(o,m)
    if bevel:
        b=o.modifiers.new("Rounded manufactured edges","BEVEL"); b.width=bevel; b.segments=2
        o.modifiers.new("Weighted normals","WEIGHTED_NORMAL")
    return o
def sphere(n,p,d,m):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,location=p); o=bpy.context.object; o.name=n; o.scale=d; assign(o,m)
    for f in o.data.polygons: f.use_smooth=True
    return o
def cylinder(n,p,r,h,m):
    bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=h,location=p); o=bpy.context.object; o.name=n; assign(o,m)
    for f in o.data.polygons: f.use_smooth=True
    return o
def product(x,y,z,i):
    m=colors[i%len(colors)]
    if i%3==0:
        cylinder("Can", (x,y,z+.10),.075,.20,m); cylinder("Lid",(x,y,z+.204),.073,.012,steel)
    else:
        box("Carton",(x,y,z+.11),(.14,.16,.22),m,.008); box("Label",(x,y-.083,z+.115),(.105,.007,.065),white,.002)
def rack(x,y,length=3.2,depth=.88,back=False):
    box("Oak plinth",(x,y,.12),(depth,length,.24),wood)
    box("Steel spine",(x,y,.95),(.08,length,1.65),dark)
    for s in [-1,1]:
        for h in [.37,.91,1.45]:
            box("Shelf",(x+s*.24,y,h),(.44,length,.065),steel,.009)
            box("Price rail",(x+s*.47,y,h+.015),(.025,length,.06),white,.005)
            for j in range(int(length/.20)-1):
                product(x+s*.25,y-length/2+.20+j*.20,h+.045,random.randrange(7))
        box("LED strip",(x+s*.25,y,1.80),(.045,length,.026),glow,.004)
    box("Cap",(x,y,1.84),(depth,length,.07),dark)
def cold(x,y):
    box("Cold cabinet",(x,y,1.03),(2.15,.86,2.06),dark)
    for h in [.30,.83,1.36]:
        box("Cold shelf",(x,y-.49,h),(2.02,.34,.065),steel)
        for j in range(11): product(x-.91+j*.18,y-.50,h+.04,random.randrange(7))
    box("Light",(x,y-.58,1.85),(2.01,.03,.035),glow)
    for dx in [-1.05,0,1.05]: box("Door frame",(x+dx,y-.70,1.03),(.055,.06,1.66),steel)
    for dx in [-.08,.08]: box("Handle",(x+dx,y-.75,1.02),(.035,.08,.30),steel)
def produce(x,y,fruit):
    box("Display base",(x,y,.37),(2.75,1.0,.74),wood)
    for j in range(5):
        xx=x-1.08+j*.54
        box("Crate",(xx,y,.78),(.50,.90,.13),dark)
        for k in range(9):
            p=(xx+(k%3-1)*.14,y+(k//3-1)*.23,.92)
            sphere("Fresh produce",p,(.08,.10,.08),colors[(j+2)%7] if fruit else colors[(j+1)%7])
def checkout(x,y):
    box("Checkout cabinet",(x,y,.48),(.83,2.2,.96),dark)
    box("Steel worktop",(x,y,1.0),(.90,2.28,.09),steel)
    box("Conveyor",(x,y+.15,1.055),(.63,1.65,.025),rubber)
    box("Screen stand",(x+.52,y-.62,1.12),(.12,.12,.28),dark)
    box("Monitor",(x+.52,y-.62,1.38),(.40,.12,.29),dark)
    box("Screen",(x+.52,y-.69,1.38),(.34,.018,.22),colors[2])
    box("Scanner",(x,y-.87,1.06),(.30,.24,.035),rubber)
def plant(x,y):
    cylinder("Planter",(x,y,.20),.22,.40,wall)
    for j in range(13):
        a=j*2.4; o=sphere("Leaf",(x+math.cos(a)*.17,y+math.sin(a)*.17,.48+random.random()*.30),(.09,.16,.045),green); o.rotation_euler=(.5,a,.4)
def light(name,p,power,size,color=(1,.83,.64)):
    data=bpy.data.lights.new(name,"AREA"); data.energy=power; data.shape="DISK"; data.size=size; data.color=color
    o=bpy.data.objects.new(name,data); bpy.context.collection.objects.link(o); o.location=p; return o
# Layout based on the supplied reference: entrance south, warehouse NW, checkout east.
box("Foundation",(0,0,-.21),(13.4,9.4,.40),dark)
box("Grouted subfloor",(0,0,.015),(13,9,.05),grout)
for i in range(26):
    for j in range(18): box("Porcelain tile",(-6.25+i*.5,-4.25+j*.5,.055),(.493,.493,.045),tile,.004)
for x in [-6.55,6.55]: box("Side wall",(x,0,1.15),(.19,9.2,2.3),wall)
box("Back wall",(0,4.55,1.15),(13.2,.18,2.3),wall)
for x in [-6.55,6.55]: box("Wall cap",(x,0,2.34),(.29,9.3,.12),dark)
box("Wall cap",(0,4.55,2.34),(13.4,.28,.12),dark)
for x in [-4.7,4.7]:
    box("Facade base",(x,-4.55,.23),(3.65,.22,.46),dark)
    box("Facade header",(x,-4.55,2.20),(3.65,.25,.18),dark)
    for dx in [-1.75,0,1.75]: box("Window mullion",(x+dx,-4.55,1.25),(.085,.18,1.88),steel)
for x in [-1.37,1.37]: box("Entrance pier",(x,-4.55,1.15),(.30,.32,2.3),dark)
box("Entrance lintel",(0,-4.55,2.28),(2.95,.35,.24),dark)
box("Entrance mat",(0,-3.85,.10),(2.2,1.1,.035),rubber)
for x in [-.92,.92]: box("Sliding door frame",(x,-4.54,1.1),(.07,.10,2.05),steel)
for x in [-.1,2.15,4.4]: cold(x,3.95)
for x in [-1.9,.0,1.9]: rack(x,.35)
produce(-4.65,1.0,True); produce(-4.65,-.35,False)
produce(-2.2,-2.65,False)
for x in [4.0,5.55]: checkout(x,-1.5)
box("Warehouse partition",(-3.2,3.35,1.05),(.12,2.3,2.1),dark)
box("Warehouse partition",(-4.8,2.2,1.05),(3.1,.12,2.1),wall)
for z in [.35,1.0,1.65]:
    box("Stock shelf",(-5.92,3.45,z),(.72,1.8,.07),steel)
    for j in range(4):
        box("Shipping carton",(-5.92,2.80+j*.43,z+.20),(.58,.39,.34),carton)
        box("Tape",(-5.92,2.80+j*.43,z+.375),(.065,.39,.008),white,.001)
for x,y in [(-3.4,3.9),(3.6,3.3),(5.8,-3.5),(-5.8,-3.5),(-1.7,-4.85),(1.7,-4.85)]: plant(x,y)
for x in [-4.4,4.4]:
    for j in range(5): box("Bench slat",(x,-5.28+j*.09,.37),(1.65,.075,.06),wood)
    for s in [-1,1]: box("Bench leg",(x+s*.65,-5.10,.18),(.08,.45,.36),dark)
box("Pavement",(0,-5.1,-.13),(13.4,1.1,.20),grout)
for x in [-4,0,4]:
    for y in [-2,2]: light("Ceiling softbox",(x,y,5.6),430,3.0)
light("Entrance warm light",(0,-4.3,3.5),160,2.1)
world=bpy.context.scene.world; world.use_nodes=True; world.node_tree.nodes["Background"].inputs[0].default_value=(.21,.24,.29,1); world.node_tree.nodes["Background"].inputs[1].default_value=.35
bpy.ops.object.camera_add(location=(0,-9,18)); cam=bpy.context.object; cam.rotation_euler=(Vector((0,0,.5))-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.type='ORTHO'; cam.data.ortho_scale=15.8; bpy.context.scene.camera=cam
scene=bpy.context.scene; scene.render.engine="CYCLES"; scene.cycles.samples=24; scene.cycles.use_denoising=True; scene.render.resolution_x=1440; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
# Source scene and real 3D export; procedural textures are preserved in .blend, base PBR parameters in GLB.
bpy.ops.wm.save_as_mainfile(filepath=str(out/"store_small_shop.blend"))
scene.render.filepath=str(out/"preview.png"); bpy.ops.render.render(write_still=True)
bpy.ops.export_scene.gltf(filepath=str(out/"store_small_shop.glb"),export_format="GLB",export_lights=True)
