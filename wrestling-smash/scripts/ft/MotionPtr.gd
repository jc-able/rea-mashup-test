## A pointer into a decoded motion script: (script command list, command index).
## Commands are dictionaries {op, args, words, word_offset} decoded from the ROM.
class_name MotionPtr
extends RefCounted

var scr: MotionScriptData = null      # the script ("script" is reserved by Object)
var index: int = 0

static func make(s: MotionScriptData, i: int) -> MotionPtr:
	var p := MotionPtr.new()
	p.scr = s
	p.index = i
	return p

func dup() -> MotionPtr:
	return MotionPtr.make(scr, index)

func cmd() -> Dictionary:
	return scr.cmds[index]
