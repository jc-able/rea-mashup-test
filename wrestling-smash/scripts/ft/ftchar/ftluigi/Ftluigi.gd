## 1:1 port of src/ft/ftchar/ftluigi/ftluigi.c (ssb-decomp-re): Luigi's loaded-file globals.
## Luigi has no special-move C files of his own: his status table (dFTLuigiSpecialStatusDescs)
## reuses Mario's functions (Ftmariospecialn / Ftmariospecialhi / Ftmariospeciallw).
class_name Ftluigi
extends Port

## 0x80130F70
static var gFTDataLuigiMain = null

## 0x80130F74
static var gFTDataLuigiMainMotion = null

## 0x80130F78
static var gFTDataLuigiModel = null

## 0x80130F7C
static var gFTDataLuigiSpecial1 = null

## 0x80130F80
static var gFTDataLuigiSpecial2 = null

## 0x80130F84
static var gFTDataLuigiSpecial3 = null

## 0x80130F88
static var gFTDataLuigiParticleBankID: int = 0
