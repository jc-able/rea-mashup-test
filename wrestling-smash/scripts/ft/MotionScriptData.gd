## One decoded ftMotionCommand script (see tools/ssb64 extraction): a list of commands
## plus a word-offset -> command-index table so Goto/Subroutine targets resolve exactly.
class_name MotionScriptData
extends RefCounted

var name: String = ""
var cmds: Array = []                # Array[Dictionary]
var word_to_index: Dictionary = {}  # word offset -> command index
