@tool
extends RefCounted
## Bounded, nonblocking JSON packets. TCP chunks need not match packet boundaries.
const VERSION := 1
const MAX_PACKET := 16 * 1024 * 1024
const MAX_QUEUED := 2 * MAX_PACKET
var peer: StreamPeerTCP
var expected := 0
var incoming := PackedByteArray()
var outgoing: Array[PackedByteArray] = []
var outgoing_offset := 0
var queued_bytes := 0
var failed := false

func send(packet: Dictionary) -> bool:
	if peer == null or failed: return false
	var bytes := JSON.stringify(packet).to_utf8_buffer()
	if bytes.size() > MAX_PACKET or queued_bytes + bytes.size() + 4 > MAX_QUEUED:
		failed = true
		return false
	var framed := PackedByteArray()
	framed.resize(4)
	framed.encode_u32(0, bytes.size())
	framed.append_array(bytes)
	outgoing.append(framed)
	queued_bytes += framed.size()
	flush()
	return not failed

func flush() -> void:
	if peer == null or failed: return
	peer.poll()
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED: return
	# A fixed work budget keeps the editor responsive even if its peer is busy.
	for _index in range(16):
		if outgoing.is_empty(): break
		var data: PackedByteArray = outgoing[0]
		var result := peer.put_partial_data(data.slice(outgoing_offset, mini(data.size(), outgoing_offset + 65536)))
		if result[0] != OK:
			failed = true
			break
		if int(result[1]) == 0: break
		outgoing_offset += int(result[1])
		queued_bytes -= int(result[1])
		if outgoing_offset == data.size():
			outgoing.pop_front()
			outgoing_offset = 0

func receive() -> Array[Dictionary]:
	var packets: Array[Dictionary] = []
	if peer == null or failed: return packets
	flush()
	peer.poll()
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED: return packets
	for _index in range(32):
		if expected == 0:
			if peer.get_available_bytes() < 4: break
			expected = peer.get_u32()
			if expected <= 0 or expected > MAX_PACKET:
				failed = true
				break
		var available := peer.get_available_bytes()
		if available <= 0: break
		var data := peer.get_data(mini(expected - incoming.size(), available))
		if data[0] != OK:
			failed = true
			break
		incoming.append_array(data[1])
		if incoming.size() < expected: continue
		var parser := JSON.new()
		if parser.parse(incoming.get_string_from_utf8()) != OK or not parser.data is Dictionary:
			push_warning("Lab bridge rejected invalid JSON: " + parser.get_error_message())
			failed = true
			break
		packets.append(parser.data)
		expected = 0
		incoming.clear()
	return packets
