extends SceneTree
const Catalog=preload("res://resources/sol_species/catalog.tres")
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

 var output="res://artifacts/plant-closeup-review/sols/"
 DirAccess.make_dir_recursive_absolute(output)
 var rows=[]
 for index in Catalog.entries.size():
  var entry=Catalog.entries[index]
  var model=entry.presentation_scene.instantiate()
  model.configure("neutral",SolVisualSettings.new())
  stage.add_child(model)
  model.animate(1.25,0,0)
  var box: AABB=model.preview_bounds()
  var center=box.get_center()
  var span=maxf(.1,box.size.length())
  soil.mesh.size=Vector2.ONE*span*100
  soil.position.y=-.02
  var code="SOL%02d"%(index+1)
  for view in range(2):
   camera.position=center+Vector3(.8,.45,1 if view==0 else -1).normalized()*span*3
   camera.look_at(center)
   camera.size=span*1.1
   for frame in range(6): await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(output+code+"-%d.png"%view)
  rows.append({"code":code,"name":entry.display_name,"species_id":entry.species_id,"class_id":entry.class_id,"views":[code+"-0.png",code+"-1.png"]})
  model.free()
 var file=FileAccess.open(output+"manifest.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(rows,"  "))
 print("SOL REVIEW: ",rows.size()," models captured")
 quit()
