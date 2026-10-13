## 1:1 port of src/ft/ftchar/ftmario/ftmario.c (ssb-decomp-re): Mario's loaded-file globals.
## (dFTMarioMotionDescs is commented out in the C source and is therefore not ported.)
## The file pointers are filled by the fighter data loader (ftdata.c / ftmanager.c port);
## they stay null until the loaded fighter data is attached.
class_name Ftmario
extends Port

## 0x80130E30
static var gFTMarioFileMain = null

## 0x80130E34
static var gFTMarioFileMainMotion = null

## 0x80130E38
static var gFTMarioFileModel = null

## 0x80130E3C
static var gFTMarioFileSpecial1 = null

## 0x80130E40
static var gFTMarioFileSpecial2 = null

## 0x80130E44
static var gFTMarioFileSpecial3 = null

## 0x80130E48
static var gFTMarioParticleBankID: int = 0
