## 1:1 port of src/ft/ftchar/ftfox/ftfox.c (ssb-decomp-re): Fox's loaded-file globals.
## The file pointers are filled by the fighter data loader (ftdata.c / ftmanager.c port);
## they stay null until the loaded fighter data is attached.
class_name Ftfox
extends Port

## 0x80130E90
static var gFTDataFoxMain = null

## 0x80130E94
static var gFTDataFoxMainMotion = null

## 0x80130E98
static var gFTDataFoxModel = null

## 0x80130E9C
static var gFTDataFoxSpecial1 = null

## 0x80130EA0
static var gFTDataFoxSpecial2 = null

## 0x80130EA4
static var gFTDataFoxSpecial3 = null

## 0x80130EA8
static var gFTDataFoxSpecial4 = null

## 0x80130EAC
static var gFTDataFoxParticleBankID: int = 0
