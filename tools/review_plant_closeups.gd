extends SceneTree
## Repeatable current plant close-ups. Review IDs come from the frozen registry.
const Library=preload("res://scripts/scenery/plant_library.gd")
const Draft=preload("res://tools/plant_review_definition.gd")
const BIOMES=["Meadow","Woodland","Heath","Marsh"]
var OUT="res://artifacts/plant-closeup-review/"
var records: Array=[]
var stage: Node3D
var camera: Camera3D
var soil: MeshInstance3D
func _initialize(): run.call_deferred()
func run():
 root.size=Vector2i(1000,900)
 stage=Node3D.new()
 root.add_child(stage)
 var env=WorldEnvironment.new()
 env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color("dbe2df")
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color.WHITE
 env.environment.ambient_light_energy=0.7
 env.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 stage.add_child(env)
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-45,-30,0)
 light.light_energy=1.15
 stage.add_child(light)
 camera=Camera3D.new()
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 stage.add_child(camera)
 soil=MeshInstance3D.new()
 soil.mesh=PlaneMesh.new()
 var mat=StandardMaterial3D.new()
 mat.albedo_color=Color("dbe2df")
 mat.roughness=1.0
 soil.material_override=mat
 stage.add_child(soil)
 var config=Draft.registry()
 OUT+=config.revision+"/"
 DirAccess.make_dir_recursive_absolute(OUT)
 Library.refresh(["res://resources/plants/library.json"])
 var input_hash=FileAccess.get_sha256(Draft.REGISTRY)
 var library_hash=FileAccess.get_sha256("res://resources/plants/library.json")
 var catalog_hash=FileAccess.get_sha256(Library.Species.PATH)
 var palette_hash=FileAccess.get_sha256(Library.PALETTE_DIRECTORY+"/manifest.json")
 for row: Dictionary in config.roster:
  if not Draft.revised(row,config): continue
  var rebuilt=Draft.draft(row,config)
  if rebuilt.is_empty(): push_error("Cannot reconstruct "+row.code); quit(1); return
  await capture(rebuilt.definition,row)
  records.back()["settings"]=rebuilt.settings
  records.back()["seed"]=rebuilt.seed
  records.back()["source_plant_id"]=row.plant_id
  records.back()["pending_review"]=true
 var file=FileAccess.open(OUT+"manifest.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"revision":config.revision,"registry_sha256":input_hash,"plants":records},"  "))
 file.close()
 if library_hash!=FileAccess.get_sha256("res://resources/plants/library.json") or catalog_hash!=FileAccess.get_sha256(Library.Species.PATH) or palette_hash!=FileAccess.get_sha256(Library.PALETTE_DIRECTORY+"/manifest.json"):
  push_error("Review changed a production authority")
  quit(1)
  return
 print("PLANT CLOSEUP REVIEW: ",records.size()," revisions, production catalog/library/palette unchanged")
 quit()
func capture(item,row):
 var biome=BIOMES.find(row.biome)
 var group=row.group
 var title=row.name
 var status=row.status
 var code=row.code
 var model=Library.model(item)
 var node=item.scene.instantiate()
 stage.add_child(node)
 node.scale=item.scale_for(model.bounds)
 node.position=-(node.basis*item.ground_offset(model.bounds))
 var bounds: AABB=node.transform*model.bounds
 if item.recipe.get("roots_below_ground",false):
  var top=bounds.end.y
  bounds.position.y=0
  bounds.size.y=top
 var center=bounds.get_center()
 var span=maxf(0.01,maxf(bounds.size.y,maxf(bounds.size.x,bounds.size.z)))
 soil.mesh.size=Vector2.ONE*span*200
 soil.position=Vector3(center.x,-span*0.002,center.z)
 camera.near=span*0.001
 camera.far=span*50
 Library.set_weather(Vector2.RIGHT,0,0)
 for view in range(2):
  var direction=Vector3(0.65,0.38,1.0).normalized() if view==0 else Vector3(-0.75,1.15,1.0).normalized()
  camera.position=center+direction*span*4
  camera.look_at(center)
  var right=camera.global_basis.x
  var up=camera.global_basis.y
  var width=absf(right.x)*bounds.size.x+absf(right.y)*bounds.size.y+absf(right.z)*bounds.size.z
  var height=absf(up.x)*bounds.size.x+absf(up.y)*bounds.size.y+absf(up.z)*bounds.size.z
  camera.size=maxf(height,width/(1000.0/900))*1.12
  for frame in range(3): await process_frame
  await RenderingServer.frame_post_draw
  var err=root.get_texture().get_image().save_png(OUT+code+"-%d.png"%view)
  if err!=OK: push_error("Capture failed "+code)
 records.append({"code":code,"plant_id":item.plant_id,"biome":BIOMES[biome],"group":group,"name":title,"status":status,"height":bounds.size.y,"width":maxf(bounds.size.x,bounds.size.z),"views":[code+"-0.png",code+"-1.png"]})
 print("CAPTURED ",code," ",item.plant_id)
 node.free()

