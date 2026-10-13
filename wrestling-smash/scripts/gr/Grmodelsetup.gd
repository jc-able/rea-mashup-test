## 1:1 port of src/gr/grmodelsetup.c
class_name Grmodelsetup
extends Port

## 0x80105760
## dobjdesc: GRPtr to a DObjDesc array (see Grdisplay); dobjs: output Array (C DObj**) or null;
## transform_types: Array of DObjTransformTypes {"tk1", "tk2", "tk3"} (one per DObjDesc).
static func grModelSetupGroundDObjs(gobj = null, dobjdesc = null, dobjs = null, transform_types = null) -> void:
	var i: int
	var id: int
	var dobj: DObj
	var array_dobjs: Array = []

	array_dobjs.resize(DOBJ_ARRAY_MAX)   # all NULL

	i = 0
	for desc in Grdisplay.grDisplayGetDObjDescs(dobjdesc):   # dobjdesc->id != ARRAY_COUNT(array_dobjs)
		id = desc.id & 0xFFF

		if id != 0:
			dobj = Objman.gcAddChildForDObj(array_dobjs[id - 1], desc.dl)
			array_dobjs[id] = dobj
		else:
			dobj = Objman.gcAddDObjForGObj(gobj, desc.dl)
			array_dobjs[0] = dobj

		if transform_types[i].tk1 != nGCMatrixKindNull:
			Grdisplay.grDisplayAddXObj(dobj, transform_types[i].tk1, transform_types[i].tk3)
		if transform_types[i].tk2 != nGCMatrixKindNull:
			Grdisplay.grDisplayAddXObj(dobj, transform_types[i].tk2, 0)

		dobj.translate = desc.translate
		dobj.rotate = desc.rotate
		dobj.scale = desc.scale

		if dobjs != null:
			dobjs[i] = dobj
		i += 1
