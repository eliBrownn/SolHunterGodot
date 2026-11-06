class_name RecordShape
extends RefCounted
## Shared exact-record admission; independent of saved state and game domains.

static func keys_match(data: Dictionary, expected: Array) -> bool:
	if data.size() != expected.size():
		return false
	for key in expected:
		if not data.has(key):
			return false
	return true
