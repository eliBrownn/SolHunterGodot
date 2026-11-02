"""Prepare the owner-supplied Human LowPoly1 FBX with Blender 2.82.

Preserve mesh topology and UVs; normalize transforms, add smooth shading and a
deformation rig for the existing Godot player bridge. No remesh or subdivision.
"""
import bpy
import json
import os
import hashlib
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'characters', 'human_low_poly')
REVIEW = os.path.join(ROOT, 'artifacts', 'human_low_poly')
os.makedirs(REVIEW, exist_ok=True)
source = os.path.join(OUT, 'human_low_poly.fbx')
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.import_scene.fbx(filepath=source)
body = next(obj for obj in bpy.context.scene.objects if obj.type == 'MESH')
body.name = 'BaseBody'
bpy.context.view_layer.objects.active = body
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bottom = min(v.co.z for v in body.data.vertices)
height = max(v.co.z for v in body.data.vertices) - bottom
for vertex in body.data.vertices:
    vertex.co = Vector((vertex.co.x, vertex.co.y, vertex.co.z-bottom)) * (1.8/height)
# The supplied FBX contains explicit split normals. Clear those before smoothing
# so the existing low-poly silhouette stays intact without faceted lighting.
if body.data.has_custom_normals:
    bpy.ops.mesh.customdata_custom_splitnormals_clear()
body.data.use_auto_smooth = False
for polygon in body.data.polygons:
    polygon.use_smooth = True
material = bpy.data.materials.new('Skin')
material.diffuse_color = (.48,.285,.17,1)
material.use_nodes = True
shader = material.node_tree.nodes.get('Principled BSDF')
shader.inputs['Base Color'].default_value = (.48,.285,.17,1)
shader.inputs['Roughness'].default_value = .85
body.data.materials.clear()
body.data.materials.append(material)

bpy.ops.object.select_all(action='DESELECT')
bpy.ops.object.armature_add(enter_editmode=True)
rig = bpy.context.object
rig.name = 'HumanBaseRig'
rig.data.edit_bones.remove(rig.data.edit_bones[0])

def bone(name, head, tail, parent=None):
    item = rig.data.edit_bones.new(name)
    item.head, item.tail = head, tail
    if parent:
        item.parent = rig.data.edit_bones[parent]
    return item

bone('root',(0,0,0),(0,0,.15)).use_deform = False
bone('pelvis',(0,.035,.86),(0,.035,1.0),'root')
bone('spine',(0,.035,1.0),(0,.035,1.22),'pelvis')
bone('chest',(0,.035,1.22),(0,.03,1.43),'spine')
bone('neck',(0,.03,1.43),(0,-.025,1.56),'chest')
bone('head',(0,-.025,1.56),(0,-.055,1.79),'neck')
for side,suffix in [(1,'.L'),(-1,'.R')]:
    bone('clavicle'+suffix,(0,.03,1.42),(side*.205,.04,1.43),'chest')
    bone('upper_arm'+suffix,(side*.205,.04,1.43),(side*.275,.035,1.16),'clavicle'+suffix)
    bone('forearm'+suffix,(side*.275,.035,1.16),(side*.297,-.04,.89),'upper_arm'+suffix)
    bone('hand'+suffix,(side*.297,-.04,.89),(side*.285,-.055,.745),'forearm'+suffix)
    bone('thigh'+suffix,(side*.105,.035,.88),(side*.13,.065,.47),'pelvis')
    bone('shin'+suffix,(side*.13,.065,.47),(side*.17,.09,.08),'thigh'+suffix)
    bone('foot'+suffix,(side*.17,.09,.08),(side*.17,-.07,.035),'shin'+suffix)
bpy.ops.object.mode_set(mode='OBJECT')
rig.show_in_front = True
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
bpy.context.view_layer.objects.active = body
bpy.ops.object.vertex_group_limit_total(limit=4)
bpy.ops.object.vertex_group_normalize_all(lock_active=False)
# Fail rather than exporting a mesh that cannot follow the player rig.
assert all(vertex.groups for vertex in body.data.vertices), 'Automatic weighting left unbound vertices'
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT,'human_low_poly.glb'),
    export_format='GLB', export_selected=True, export_animations=False,
    export_morph=False, export_skins=True, export_yup=True)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'human_low_poly.blend'))
with open(source,'rb') as handle:
    digest = hashlib.sha256(handle.read()).hexdigest()
with open(os.path.join(REVIEW,'mesh_report.json'),'w') as handle:
    json.dump({'source_sha256':digest,'vertices':len(body.data.vertices),
        'triangles':sum(len(p.vertices)-2 for p in body.data.polygons),
        'height_m':1.8,'bones':len(rig.data.bones),'smooth_shading':True,
        'uv_layers':len(body.data.uv_layers)},handle,indent=2)
print('HUMAN_LOW_POLY_EXPORTED')
