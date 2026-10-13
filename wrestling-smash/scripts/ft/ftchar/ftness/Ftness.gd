## 1:1 port of src/ft/ftchar/ftness/ftness.c (ssb-decomp-re): Ness' loaded-file globals.
## The file pointers are filled by the fighter data loader (ftdata.c / ftmanager.c port);
## they stay null until the loaded fighter data is attached.
class_name Ftness
extends Port

## 0x80131130
static var gFTNessFileMain = null

## 0x80131134
static var gFTNessFileMainMotion = null

## 0x80131138
static var gFTNessFileModel = null

## 0x8013113C
static var gFTNessFileSpecial1 = null

## 0x80131140
static var gFTNessFileSpecial2 = null

## 0x80131144
static var gFTNessFileSpecial3 = null

## 0x80131148
static var gFTNessParticleBankID: int = 0
