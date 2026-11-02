extends SceneTree
const Wire = preload("res://tools/lab_bridge_wire.gd")
const Catalogue = preload("res://tools/lab_station_catalogue.gd")
const Workstation = preload("res://tools/development_workstation.gd")
const Storage = preload("res://tools/lab_bridge_storage.gd")
var failures := 0

class SettingsFixture extends Node:
	@export_range(0.0, 2.0, 0.1) var strength := 1.0
	@export var enabled := true

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(30).timeout.connect(func(): quit(1))
	run.call_deferred()

func run() -> void:
	var server := TCPServer.new()
	check(server.listen(0, "127.0.0.1") == OK, "Open loopback test connection")
	var outgoing = Wire.new()
	outgoing.peer = StreamPeerTCP.new()
	outgoing.peer.connect_to_host("127.0.0.1", server.get_local_port())
	for i in range(500):
		outgoing.peer.poll()
		if server.is_connection_available(): break
		await create_timer(0.01).timeout
	var incoming = Wire.new()
	incoming.peer = server.take_connection()
	if incoming.peer == null:
		check(false, "Accept the local test peer")
		quit(1)
		return
	var payload := "0123456789abcdef".repeat(262144)
	check(outgoing.send({"payload":payload}), "Queue a packet larger than TCP receive buffers")
	outgoing.send({"tail":1})
	var received: Array[Dictionary] = []
	for i in range(1000):
		outgoing.flush()
		received.append_array(incoming.receive())
		if received.size() == 2: break
		await process_frame
	check(received.size() == 2, "Large and following small packets both arrive")
	if received.size() == 2:
		check(received[0].payload == payload and received[1].tail == 1, "Packet boundaries and payloads survive fragmentation")
	outgoing.peer.put_u32(Wire.MAX_PACKET + 1)
	for i in range(20):
		incoming.receive()
		if incoming.failed: break
		await process_frame
	check(incoming.failed, "Reject oversized framing before allocation")
	outgoing.peer.disconnect_from_host()
	incoming.peer.disconnect_from_host()
	server.stop()
	var target := SettingsFixture.new()
	var admitted := Workstation.admit_settings(target, {"strength":9.0, "enabled":"wrong", "removed":42})
	check(admitted.values.is_empty() and admitted.unresolved.size() == 3, "Incompatible tuning remains recoverable")
	check(Workstation.admit_settings(target, {"strength":0.5}).values.strength == 0.5, "Current valid binding is admitted")
	target.free()
	var folder := "res://artifacts/lab-dependency-fixture"
	DirAccess.make_dir_recursive_absolute(folder)
	var ignore := FileAccess.open(folder.path_join(".gdignore"), FileAccess.WRITE)
	ignore.close()
	var scene := folder.path_join("entry.tscn")
	var base := folder.path_join("base.gd")
	var child := folder.path_join("child.gd")
	for pair in [[scene, '[ext_resource path="'+child+'"]'], [child, 'extends "'+base+'"'], [base, "first"]]:
		var file := FileAccess.open(pair[0], FileAccess.WRITE)
		file.store_string(pair[1])
		file.close()
	var entry := {"scene":scene, "id":"dependency-test"}
	var before := Catalogue.fingerprint(entry)
	var changed := FileAccess.open(base, FileAccess.WRITE)
	changed.store_string("changed inherited owner")
	changed.close()
	check(before != Catalogue.fingerprint(entry), "Inherited script changes invalidate dependency evidence")
	var original := folder.path_join("standalone.cfg")
	var destination := folder.path_join("editor.cfg")
	var original_file := FileAccess.open(original, FileAccess.WRITE)
	original_file.store_string("[workspace]\nnotes=\"keep this note\"\n")
	original_file.close()
	# Unique targets make this reproducible without deleting any prior evidence.
	destination += str(Time.get_ticks_usec())
	var original_hash := FileAccess.get_sha256(original)
	check(bool(Storage.seed_workspace(original, destination).get("copied")), "First editor workspace imports a copy")
	check(FileAccess.get_sha256(destination) == original_hash and FileAccess.get_sha256(original) == original_hash, "Migration preserves original and copied content")
	check(FileAccess.file_exists(destination + ".migration.json"), "Migration retains a source provenance marker")
	var edited := FileAccess.open(destination, FileAccess.WRITE)
	edited.store_string("editor changes")
	edited.close()
	check(not bool(Storage.seed_workspace(original, destination).get("copied")) and FileAccess.get_file_as_string(destination) == "editor changes", "Migration never overwrites existing editor work")
	print("LAB PROTOCOL: ", failures, " failures")
	quit(1 if failures else 0)
