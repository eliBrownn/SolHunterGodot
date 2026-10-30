extends SceneTree
const Builder=preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd")
const Library=preload("res://scripts/scenery/plant_library.gd")
const Definition=preload("res://scripts/scenery/plant_definition.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String):
 checks+=1
 if not value: failures+=1; push_error(message)
func _initialize(): run.call_deferred()
func run():
 var horizontal=PackedVector3Array([Vector3(-1,0,-1),Vector3(1,0,-1),Vector3(0,0,1)])
 var crossing=PackedVector3Array([Vector3(0,-1,0),Vector3(0,1,0),Vector3(0,0,2)])
 var separated=PackedVector3Array([Vector3(3,0,0),Vector3(4,0,0),Vector3(3,0,1)])
 var coplanar=PackedVector3Array([Vector3(-0.1,0,0),Vector3(0.1,0,0),Vector3(0,0,0.1)])
 check(Builder.triangles_cross(horizontal,crossing),"Crossing surfaces collide")
 check(Builder.triangles_cross(horizontal,coplanar),"Coplanar contained surfaces collide")
 check(not Builder.triangles_cross(horizontal,separated),"Disjoint surfaces remain available")
 check(not Builder.triangles_cross(horizontal,coplanar,Vector3.ZERO,0.2),"Small connected attachments can meet")
 var crowded=Builder.new()
 crowded.prepare(73,{},crowded.make_anatomy_materials())
 crowded.quad(0,[Vector3(0.45,-1,-1),Vector3(0.45,1,-1),Vector3(0.45,1,1),Vector3(0.45,-1,1)],[Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN],Color.WHITE)
 var wall_triangles=crowded.spacing_triangles.size()
 crowded.blade(Vector3.ZERO,Vector3.RIGHT,1.0,0.2)
 crowded.flush_leaves()
 check(crowded.omitted_leaves==1,"Fully obstructed optional leaf is omitted rather than deformed through a wall")
 check(crowded.spacing_triangles.size()==wall_triangles,"Rejected leaf contributes no visible intersecting surface")
 var free=Builder.new()
 free.prepare(73,{},free.make_anatomy_materials())
 free.blade(Vector3.ZERO,Vector3.RIGHT,1.0,0.2)
 free.flush_leaves()
 check(free.omitted_leaves==0 and not free.spacing_triangles.is_empty(),"A leaf in free space retains its body")
 var builder=Builder.new()
 var settings={"branches":5,"foliage":0.65,"tree_fork_depth":2,"tree_leaf_cards":true,"branching_depth":1}
 for biome in range(4):
  for role in range(6):
   var sample=builder.create_sample(biome,role,73,settings,builder.make_anatomy_materials())
   var positions={}
   for organ in sample.organs:
    positions[organ.id]=organ.position
    if organ.id.begins_with("root"):
     check(organ.position.y < -0.1,"Every root tip penetrates soil")
     check(organ.parent=="ground","Root remains attached to canonical ground organ")
   for link in sample.links:
    if link.to.begins_with("root"):
     check(link.path[0].y>link.path[1].y and link.path[1].y>link.path[2].y,"Whole root conductor descends")
   check(positions.collar.y>0.0,"Above-ground collar remains above the soil plane")
   check(sample.body.get_surface_count()>0,"Official form retains visible growth")
 for biome in range(4):
  for variation in range(5):
   var item=Library.foliage_definition(biome,variation,"emanator")
   var bounds: AABB=Library.model(item).bounds
   var scale: Vector3=item.scale_for(bounds)
   var offset: Vector3=item.ground_offset(bounds)
   check(is_zero_approx(offset.y),"New foliage is grounded at soil plane, not root bottom")
   check((bounds.position.y-offset.y)*scale.y<0.0,"Fitted foliage roots remain underground")
   check(bounds.end.y*scale.y<=item.world_height+0.0001,"Height limit measures visible above-ground growth")
 var old=Definition.new()
 var box=AABB(Vector3(-1,-0.4,-1),Vector3(2,2,2))
 check(is_equal_approx(old.ground_offset(box).y,-0.4),"Old baked plant retains mesh-bottom compatibility")
 old.recipe={"roots_below_ground":true}
 check(is_zero_approx(old.ground_offset(box).y),"New revision retains authored soil plane")
 print("PLANT INTERNAL FIT: ",checks," checks, ",failures," failures")
 quit(0 if failures==0 else 1)
