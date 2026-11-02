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
 var uv_builder=Builder.new()
 uv_builder.tube_metric_uv=true
 for length in [1.0,4.0]:
  uv_builder.prepare(73,{},uv_builder.make_anatomy_materials())
  uv_builder.tube([Vector3.ZERO,Vector3.UP*length],0.1,0,Color.WHITE,1.0)
  var tube_mesh: ArrayMesh=uv_builder.finish()
  var uv_end:=Vector2.ZERO
  for uv: Vector2 in tube_mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]: uv_end=uv_end.max(uv)
  check(is_equal_approx(uv_end.y,length*2.0),"Bark repeats follow actual branch length rather than segment count")
  check(is_equal_approx(uv_end.x,TAU*0.1*2.0),"Bark repeats follow branch circumference rather than normalized rings")
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
 var routing=Builder.new()
 routing.spaced_branch_tip(Vector3(1,-1,0),Vector3(1,1,0),0.08)
 var rerouted: Vector3=routing.spaced_branch_tip(Vector3.ZERO,Vector3(2,0,0),0.08)
 check(not rerouted.is_equal_approx(Vector3(2,0,0)),"Crossing branches choose a different growth direction")
 var first: Dictionary=routing.branch_corridors[0]
 var close: PackedVector3Array=Geometry3D.get_closest_points_between_segments(Vector3.ZERO,rerouted,first.start,first.end)
 check(close[0].distance_to(close[1])>=0.16,"Rerouted branches leave room for both radii")
 var joined=Builder.new()
 joined.prepare(73,{},joined.make_anatomy_materials())
 joined.add_organ("ground","Ground contact",Vector3.ZERO,"",0.03)
 joined.add_organ("stem","Leaf conductor",Vector3.UP,"ground",0.03)
 check(joined.junction_radii.has(Vector3.ZERO),"Plant stems blend into shared bark collars at their attachment")
 var joined_vertices: int=joined.counts[0]
 joined.stem_joint(Vector3.ZERO,0.03)
 check(joined.counts[0]==joined_vertices,"Shared junction collars are emitted once")
 var builder=Builder.new()
 var settings={"branches":5,"foliage":0.65,"tree_fork_depth":2,"tree_leaf_cards":true,"branching_depth":1}
 for biome in range(4):
  for role in range(6):
   var sample=builder.create_sample(biome,role,73,settings,builder.make_anatomy_materials())
   var replay=Builder.new()
   for branch: Dictionary in builder.branch_corridors:
    check(replay.branch_has_room(branch.start,branch.end,branch.radius),"Accepted plant branches reserve noncrossing growth corridors")
    replay.spaced_branch_tip(branch.start,branch.end,branch.radius)
   var positions={}
   for organ in sample.organs:
    positions[organ.id]=organ.position
    if organ.id.begins_with("root"):
     check(organ.position.y < -0.1,"Every root tip penetrates soil")
     check(organ.parent=="ground","Root remains attached to canonical ground organ")
   for link in sample.links:
    if link.to.begins_with("root"):
     check(link.path[0].y>link.path[1].y and link.path[1].y>link.path[2].y,"Whole root conductor descends")
   if role==1:
    for link in sample.links:
     check(link.path[0].is_equal_approx(positions[link.from]) and link.path[-1].is_equal_approx(positions[link.to]),"Tree tubes meet their exact named junctions")
     if link.to.begins_with("canopy") and "_fork" not in link.to:
      check(link.from.begins_with("trunk_joint") or link.from.begins_with("branch_socket"),"Canopy scaffolds follow shared trunk and branch sockets")
      var ascent: Vector3=link.path[-1]-link.path[0]
      check(ascent.y>Vector2(ascent.x,ascent.z).length()*0.4,"Primary tree scaffolds rise even in broad-crowned biome habits")
    check(positions.has("trunk_joint0") and positions.has("trunk_joint2"),"Tree trunk has a continuous socket hierarchy")
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
