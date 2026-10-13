## Port of union GMStatFlags (src/gm/gmtypes.h): bitfields over one u16 halfword.
## Bit layout (IDO big-endian bitfields): unused:3 | is_smash_attack:1 | ga:1 | is_projectile:1 | attack_id:10
class_name GMStatFlags
extends RefCounted

var halfword: int = 0

var attack_id: int:
	get:
		return halfword & 0x3FF
	set(v):
		halfword = (halfword & ~0x3FF) | (v & 0x3FF)

var is_projectile: int:
	get:
		return (halfword >> 10) & 1
	set(v):
		halfword = (halfword & ~(1 << 10)) | ((v & 1) << 10)

var ga: int:
	get:
		return (halfword >> 11) & 1
	set(v):
		halfword = (halfword & ~(1 << 11)) | ((v & 1) << 11)

var is_smash_attack: int:
	get:
		return (halfword >> 12) & 1
	set(v):
		halfword = (halfword & ~(1 << 12)) | ((v & 1) << 12)

static func from_halfword(h: int) -> GMStatFlags:
	var f := GMStatFlags.new()
	f.halfword = h & 0xFFFF
	return f

func dup() -> GMStatFlags:
	return GMStatFlags.from_halfword(halfword)
