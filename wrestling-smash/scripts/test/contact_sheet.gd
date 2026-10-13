## Headless tool: tiles PNGs into one contact sheet.
##   -- out=<png> dir=<dir> match=<substring> cols=4 w=480 crop=x,y,w,h
extends SceneTree
func _initialize() -> void:
	var o := {"cols": "4", "w": "480", "match": ""}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		o[kv[0]] = kv[1]
	var files: Array = []
	for f in DirAccess.get_files_at(o.dir):
		if f.ends_with(".png") and (o.match == "" or o.match in f):
			files.append(f)
	files.sort()
	var cols := int(o.cols)
	var tw := int(o.w)
	var crop := Rect2i()
	if o.has("crop"):
		var c: PackedStringArray = o.crop.split(",")
		crop = Rect2i(int(c[0]), int(c[1]), int(c[2]), int(c[3]))
	var tiles: Array = []
	var th := 0
	for f in files:
		var img := Image.load_from_file(o.dir + "/" + f)
		if crop.size.x > 0:
			img = img.get_region(crop)
		var h := int(float(img.get_height()) * tw / img.get_width())
		img.resize(tw, h, Image.INTERPOLATE_BILINEAR)
		img.convert(Image.FORMAT_RGBA8)
		th = maxi(th, h)
		tiles.append(img)
	var rows := int(ceil(float(tiles.size()) / cols))
	var sheet := Image.create(cols * tw, rows * th, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.1, 0.12))
	for i in tiles.size():
		sheet.blit_rect(tiles[i], Rect2i(0, 0, tw, tiles[i].get_height()), Vector2i((i % cols) * tw, (i / cols) * th))
	if str(o.out).ends_with(".jpg"):
		sheet.convert(Image.FORMAT_RGB8)
		sheet.save_jpg(o.out, 0.82)
	else:
		sheet.save_png(o.out)
	print("sheet ", o.out, " ", tiles.size(), " tiles")
	quit(0)
