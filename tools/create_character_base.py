"""Author the original base mesh. Run with Blender --background --python this_file.

Blender 2.82 compatible. No external assets or packages. Model units are metres;
Godot's adapter normalizes the 1.8 m source to the existing player's height.
"""
import bpy
import math
import os
import json
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'characters', 'customizable_base')
REVIEW = os.path.join(ROOT, 'artifacts', 'character_base')
os.makedirs(OUT, exist_ok=True)
os.makedirs(REVIEW, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version = 0
parts = []


def ellipsoid(name, position, scale):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, location=position)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    parts.append(obj)
    return obj


def rings(name, sections, count=16):
    vertices, faces = [], []
    for x, y, z, width, depth in sections:
        for index in range(count):
            angle = index * 2 * math.pi / count
            vertices.append((x + width * math.cos(angle), y + depth * math.sin(angle), z))
    for row in range(len(sections) - 1):
        for index in range(count):
            a = row * count + index
            b = row * count + (index + 1) % count
            faces.append((a, b, b + count, a + count))
    faces.extend([tuple(reversed(range(count))), tuple((len(sections)-1)*count+i for i in range(count))])
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    parts.append(obj)
    return obj


# Neutral adult proportions; smooth blank pelvis/chest, no intimate anatomy.
rings('Torso', [(0,0,.80,.125,.095), (0,.005,.90,.155,.105),
    (0,.008,1.00,.145,.100), (0,0,1.10,.127,.089),
    (0,0,1.22,.166,.107), (0,0,1.34,.201,.104),
    (0,0,1.405,.180,.087), (0,0,1.43,.118,.070)])
ellipsoid('Neck', (0,0,1.47), (.062,.062,.107))
ellipsoid('Pelvis', (0,.006,.90), (.163,.107,.145))
rings('Head', [(0,0,1.53,.042,.044), (0,-.012,1.565,.069,.070),
    (0,-.008,1.61,.091,.083), (0,0,1.67,.102,.088),
    (0,.005,1.73,.094,.085), (0,.006,1.775,.067,.063),
    (0,.006,1.80,.015,.018)])
ellipsoid('Nose', (0,-.084,1.635), (.020,.026,.032))
for side in (-1, 1):
    ellipsoid('Shoulder', (side*.185,0,1.337), (.090,.080,.096))
    ellipsoid('Ear', (side*.101,0,1.65), (.019,.027,.042))
    x = side * .091
    rings('Leg', [(x,.005,.94,.074,.078), (side*.103,.008,.79,.086,.090),
        (side*.107,.006,.65,.072,.075), (side*.110,-.014,.505,.052,.055),
        (side*.111,-.020,.455,.051,.054), (side*.113,.004,.345,.063,.066),
        (side*.114,.008,.235,.052,.055), (side*.115,0,.105,.034,.038),
        (side*.115,0,.065,.034,.037)])
    ellipsoid('Foot', (side*.115,-.053,.057), (.051,.112,.052))
    # Relaxed A-pose: clothes can be fitted without arms touching the torso.
    rings('Arm', [(side*.176,0,1.365,.077,.075),
        (side*.228,0,1.315,.074,.071), (side*.278,0,1.225,.060,.058),
        (side*.317,-.006,1.14,.047,.049), (side*.328,-.010,1.11,.046,.046),
        (side*.368,-.012,1.035,.051,.047), (side*.407,-.014,.947,.033,.032),
        (side*.414,-.016,.925,.030,.029)], 12)
    ellipsoid('Palm', (side*.435,-.016,.879), (.042,.027,.064))
    # Simple readable fingers; deliberately no fingernail detail.
    for finger in range(4):
        fx = side * (.414 + finger*.017)
        length = [.047,.063,.059,.045][finger]
        ellipsoid('Finger', (fx,-.017,.834-length*.30), (.012,.015,length))
    ellipsoid('Thumb', (side*.395,-.027,.868), (.021,.021,.044))

bpy.ops.object.select_all(action='DESELECT')
for obj in parts:
    obj.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.join()
body = bpy.context.object
body.name = 'BaseBody'
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
# Weld the construction volumes into a single continuous skin, then simplify.
body.data.remesh_voxel_size = .006
bpy.ops.object.voxel_remesh()
smooth = body.modifiers.new('Rounded silhouette', 'SMOOTH')
smooth.factor = .9
smooth.iterations = 60
bpy.ops.object.modifier_apply(modifier=smooth.name)
decimate = body.modifiers.new('Low polygon budget', 'DECIMATE')
source_triangles = sum(len(p.vertices)-2 for p in body.data.polygons)
decimate.ratio = min(1.0, 3000.0 / source_triangles)
decimate.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier=decimate.name)
# Exact source height and sole anchor, independent of remeshing shrinkage.
bottom = min(v.co.z for v in body.data.vertices)
top = max(v.co.z for v in body.data.vertices)
for vertex in body.data.vertices:
    vertex.co.z = (vertex.co.z - bottom) * 1.8 / (top-bottom)
for polygon in body.data.polygons:
    polygon.use_smooth = True
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.uv.smart_project(angle_limit=66, island_margin=.025)
bpy.ops.object.mode_set(mode='OBJECT')


def material(name, color, roughness=.8):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color,1)
    mat.use_nodes = True
    principled = mat.node_tree.nodes.get('Principled BSDF')
    principled.inputs['Base Color'].default_value = (*color,1)
    principled.inputs['Roughness'].default_value = roughness
    return mat


skin = material('Skin', (.48,.285,.17))
body.data.materials.append(skin)
# Minimal facial landmarks are separately replaceable customization pieces.
eyes = []
for side in (-1,1):
    eye = ellipsoid('Eye.L' if side == 1 else 'Eye.R',
        (side*.040,-.081,1.666), (.015,.010,.010))
    low_eye = eye.modifiers.new('Low polygon eyes', 'DECIMATE')
    low_eye.ratio = .15
    bpy.context.view_layer.objects.active = eye
    bpy.ops.object.modifier_apply(modifier=low_eye.name)
    eye.data.materials.append(material(eye.name+'Material', (.055,.036,.027)))
    for polygon in eye.data.polygons:
        polygon.use_smooth = True
    eyes.append(eye)

# Shape keys are a starting point for future authoring, not a gameplay system.
body.shape_key_add(name='Basis')
for name in ('ShoulderWidth', 'HipWidth', 'BodyBuild', 'FaceWidth'):
    key = body.shape_key_add(name=name)
    for vertex in key.data:
        x,y,z = vertex.co
        if name == 'ShoulderWidth':
            weight = max(0, 1-abs(z-1.35)/.30)
            vertex.co.x *= 1 + .20*weight
        elif name == 'HipWidth':
            weight = max(0, 1-abs(z-.89)/.28)
            vertex.co.x *= 1 + .22*weight
        elif name == 'BodyBuild':
            weight = max(0, 1-abs(z-1.12)/.45)
            vertex.co.x *= 1 + .12*weight
            vertex.co.y *= 1 + .25*weight
        elif name == 'FaceWidth':
            weight = max(0, 1-abs(z-1.67)/.14)
            vertex.co.x *= 1 + .16*weight

# Standard named chains recognized by the existing procedural player locomotion.
bpy.ops.object.select_all(action='DESELECT')
bpy.ops.object.armature_add(enter_editmode=True, location=(0,0,0))
rig = bpy.context.object
rig.name = 'BaseRig'
rig.data.edit_bones.remove(rig.data.edit_bones[0])
bones = []


def bone(name, head, tail, parent=None):
    item = rig.data.edit_bones.new(name)
    item.head, item.tail = head, tail
    if parent:
        item.parent = rig.data.edit_bones[parent]
    bones.append((name, Vector(head), Vector(tail)))


bone('root',(0,0,0),(0,0,.15))
bone('pelvis',(0,0,.86),(0,0,1.0),'root')
bone('spine',(0,0,1.0),(0,0,1.20),'pelvis')
bone('chest',(0,0,1.20),(0,0,1.40),'spine')
bone('neck',(0,0,1.40),(0,0,1.54),'chest')
bone('head',(0,0,1.54),(0,0,1.79),'neck')
for side, suffix in [(1,'.L'),(-1,'.R')]:
    bone('clavicle'+suffix,(0,0,1.37),(side*.19,0,1.36),'chest')
    bone('upper_arm'+suffix,(side*.19,0,1.36),(side*.323,-.01,1.12),'clavicle'+suffix)
    bone('forearm'+suffix,(side*.323,-.01,1.12),(side*.413,-.016,.93),'upper_arm'+suffix)
    bone('hand'+suffix,(side*.413,-.016,.93),(side*.44,-.016,.80),'forearm'+suffix)
    bone('thigh'+suffix,(side*.093,0,.88),(side*.11,-.02,.48),'pelvis')
    bone('shin'+suffix,(side*.11,-.02,.48),(side*.115,0,.10),'thigh'+suffix)
    bone('foot'+suffix,(side*.115,0,.10),(side*.115,-.13,.045),'shin'+suffix)
bpy.ops.object.mode_set(mode='OBJECT')
rig.show_in_front = True


def distance_to_segment(point, a, b):
    t = max(0,min(1,(point-a).dot(b-a)/(b-a).length_squared))
    return (point - (a+(b-a)*t)).length


for obj in [body] + eyes:
    groups = {name:obj.vertex_groups.new(name=name) for name,a,b in bones}
    for vertex in obj.data.vertices:
        point = obj.matrix_world @ vertex.co
        # Prevent cross weighting between adjacent legs and torso/forearms.
        candidates = []
        for name,a,b in bones:
            if name == 'root':
                continue
            if name.endswith('.L') and point.x < -.025:
                continue
            if name.endswith('.R') and point.x > .025:
                continue
            if ('arm' in name or 'hand' in name) and abs(point.x) < .16:
                continue
            candidates.append((distance_to_segment(point,a,b), name))
        nearest = sorted(candidates)[:3]
        weights = [(1.0/(d+.018)**4,name) for d,name in nearest]
        total = sum(w for w,name in weights)
        for weight,name in weights:
            groups[name].add([vertex.index],weight/total,'REPLACE')
    mod = obj.modifiers.new('Character skin', 'ARMATURE')
    mod.object = rig
    obj.parent = rig

bpy.ops.object.select_all(action='DESELECT')
for obj in [rig, body] + eyes:
    obj.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'customizable_base.glb'),
    export_format='GLB', export_selected=True, export_animations=False,
    export_morph=True, export_skins=True, export_yup=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'customizable_base.blend'))
triangles = sum(len(p.vertices)-2 for obj in [body]+eyes for p in obj.data.polygons)
with open(os.path.join(REVIEW,'mesh_report.json'),'w') as handle:
    json.dump({'triangles':triangles,'body_vertices':len(body.data.vertices),
        'height_m':1.8,'bones':len(bones),'smooth_shading':True,
        'shape_keys':[k.name for k in body.data.shape_keys.key_blocks]},handle,indent=2)

# Studio review render; lights/camera are excluded from the exported asset.
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.eevee.use_gtao = True
scene.eevee.gtao_distance = 3
scene.eevee.gtao_factor = 1.1
scene.render.resolution_x = 900
scene.render.resolution_y = 1000
scene.render.resolution_percentage = 100
scene.world.color = (.16,.16,.16)
scene.view_settings.view_transform = 'Standard'
scene.view_settings.look = 'Standard - Medium High Contrast'
scene.view_settings.exposure = 0
scene.view_settings.gamma = 1
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.008))
bpy.context.object.data.materials.append(material('StudioFloor',(.075,.09,.11)))
for pos, energy, size in [((3,-4,5),450,4),((-3,-2,3),250,3),((1,3,4),550,3)]:
    bpy.ops.object.light_add(type='AREA',location=pos)
    light=bpy.context.object
    light.data.energy=energy
    light.data.size=size
    light.rotation_euler=(Vector((0,0,1))-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(2.8,-5,2.3))
camera=bpy.context.object
camera.rotation_euler=(Vector((0,0,.93))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO'
camera.data.ortho_scale=2.15
scene.camera=camera
scene.render.filepath=os.path.join(REVIEW,'base_preview.png')
bpy.ops.render.render(write_still=True)
print('CHARACTER_BASE_REPORT', triangles, 'triangles; 1.8m; smooth shaded')
