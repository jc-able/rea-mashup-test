## Records calls into not-yet-ported (stub) functions, once per function.
class_name StubLog
extends RefCounted

static var seen: Dictionary = {}

static func hit(name: String) -> void:
	if not seen.has(name):
		seen[name] = 1
		push_warning("unported stub called: " + name)
	else:
		seen[name] += 1
