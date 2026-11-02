"""Exercise the real EditorPlugin in a disposable project, with harmless fixtures."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--export-check", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    artifacts = root / "artifacts"
    artifacts.mkdir(exist_ok=True)
    project = Path(tempfile.mkdtemp(prefix="lab-editor-", dir=artifacts))
    shutil.copytree(root / "addons/solhunter_lab", project / "addons/solhunter_lab")
    (project / "tools").mkdir()
    for name in ("lab_station_catalogue.gd", "lab_bridge_wire.gd", "lab_bridge_runner.gd", "lab_bridge_storage.gd"):
        shutil.copy2(root / "tools" / name, project / "tools" / name)
    runner = project / "addons/probe"
    runner.mkdir()
    shutil.copy2(root / "tests/lab_plugin_editor.gd", runner / "probe.gd")
    (runner / "plugin.cfg").write_text(
        '[plugin]\nname="Lab lifecycle probe"\ndescription="Disposable test"\n'
        'author="SolHunter"\nversion="1"\nscript="probe.gd"\n', encoding="utf-8"
    )
    (project / "project.godot").write_text(
        'config_version=5\n[application]\nconfig/name="Lab plugin validation"\n'
        '[editor_plugins]\nenabled=PackedStringArray('
        '"res://addons/solhunter_lab/plugin.cfg", "res://addons/probe/plugin.cfg")\n'
        '[rendering]\nrenderer/rendering_method="gl_compatibility"\n',
        encoding="utf-8",
    )
    # Exercise real launch/lifecycle without loading production builders or saves.
    (project / "child.gd").write_text(
        'extends Control\nvar presses := 0\nfunc preserve_dirty() -> bool:\n\treturn true\n'
        'func _ready() -> void:\n'
        '\tvar file := FileAccess.open("user://lab_child_started.txt", FileAccess.WRITE)\n'
        '\tfile.store_string("started")\n\tfile.close()\n'
        '\tvar button := Button.new()\n\tbutton.text="Fixture action"\n'
        '\tbutton.size=Vector2(200,60)\n\tadd_child(button)\n'
        '\tbutton.pressed.connect(func():\n'
        '\t\tpresses += 1\n'
        '\t\tvar note := FileAccess.open("user://lab_child_clicked.txt",FileAccess.WRITE)\n'
        '\t\tnote.store_string(str(presses))\n\t\tnote.close())\n', encoding="utf-8"
    )
    for definition in (project / "addons/solhunter_lab/stations").glob("*.json"):
        entry = json.loads(definition.read_text(encoding="utf-8"))
        entry["host"] = "sol"
        definition.write_text(json.dumps(entry), encoding="utf-8")
        scene = project / entry["scene"][len("res://"):]
        scene.parent.mkdir(parents=True, exist_ok=True)
        scene.write_text(
            '[gd_scene load_steps=2 format=3]\n'
            '[ext_resource type="Script" path="res://child.gd" id="1"]\n'
            '[node name="HarmlessFixture" type="Control"]\nscript=ExtResource("1")\n',
            encoding="utf-8",
        )
    env = os.environ.copy()
    env["APPDATA"] = str(project / "profile")
    (project / "profile").mkdir()
    (project / "profile/.gdignore").write_text("", encoding="utf-8")
    result = subprocess.run(
        [args.godot, "--editor", "--path", str(project),
         "--rendering-method", "gl_compatibility", "--max-fps", "60", "--quit-after", "1500"],
        env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60,
    )
    output = result.stdout.decode("utf-8", errors="replace")
    (project / "editor.log").write_text(output, encoding="utf-8")
    print(output)
    print("Editor process exit:", result.returncode)
    print("Evidence:", project)
    failed = result.returncode != 0 or "LAB EDITOR: 0 failures" not in output or "SCRIPT ERROR:" in output or "ERROR:" in output
    if args.export_check and not failed:
        project_file = project / "project.godot"
        configuration = project_file.read_text(encoding="utf-8")
        configuration = configuration.replace('"res://addons/probe/plugin.cfg", ', '').replace(', "res://addons/probe/plugin.cfg"', '')
        project_file.write_text(configuration, encoding="utf-8")
        (project / "runtime.tres").write_text('[gd_resource type="Resource" format=3]\n[resource]\nresource_name="Runtime sentinel"\n', encoding="utf-8")
        (project / "export_presets.cfg").write_text(
            '[preset.0]\nname="Lab export check"\nplatform="Windows Desktop"\n'
            'runnable=true\nexport_filter="all_resources"\ninclude_filter="*.json"\n'
            'exclude_filter=""\nexport_path="check.pck"\nscript_export_mode=1\n'
            '[preset.0.options]\nbinary_format/architecture="x86_64"\n', encoding="utf-8"
        )
        pack = project / "check.pck"
        export = subprocess.run([args.godot, "--headless", "--path", str(project), "--export-pack", "Lab export check", str(pack)], env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        export_log = export.stdout.decode("utf-8", errors="replace")
        (project / "export.log").write_text(export_log, encoding="utf-8")
        print(export_log)
        failed = export.returncode != 0 or "ERROR:" in export_log or not pack.exists()
        if not failed:
            checker = project / "pack_checker"
            checker.mkdir()
            (checker / "project.godot").write_text('config_version=5\n', encoding="utf-8")
            checker_code = '''extends SceneTree
func _initialize() -> void:
\tvar failures := 0
\tif not ProjectSettings.load_resource_pack(PACK_PATH): failures += 1
\tfor path in ["res://addons/solhunter_lab/plugin.gd", "res://addons/solhunter_lab/plugin.gd.remap", "res://tools/lab_bridge_runner.gd", "res://tools/lab_bridge_runner.gd.remap", "res://scenes/plant_maker.tscn"]:
\t\tif FileAccess.file_exists(path): failures += 1; push_error("Editor-only file in pack: " + path)
\tif not ResourceLoader.exists("res://runtime.tres"): failures += 1
\tprint("LAB EXPORT: ", failures, " failures")
\tquit(1 if failures else 0)
'''.replace("PACK_PATH", json.dumps(pack.as_posix()))
            (checker / "verify.gd").write_text(checker_code, encoding="utf-8")
            verify = subprocess.run([args.godot, "--headless", "--path", str(checker), "--script", "res://verify.gd"], env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
            verify_log = verify.stdout.decode("utf-8", errors="replace")
            (project / "pack-check.log").write_text(verify_log, encoding="utf-8")
            print(verify_log)
            failed = verify.returncode != 0 or "LAB EXPORT: 0 failures" not in verify_log or "ERROR:" in verify_log
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
