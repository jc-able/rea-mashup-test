## 1:1 port of src/ft/ftchar/ftcaptain/ftcaptain.c (ssb-decomp-re): Captain Falcon's loaded-file globals.
## The file pointers are filled by the fighter data loader (ftdata.c / ftmanager.c port);
## they stay null until the loaded fighter data is attached.
class_name Ftcaptain
extends Port

## 0x80131030
static var gFTDataCaptainMain = null

## 0x80131034
static var gFTDataCaptainMainMotion = null

## 0x80131038
static var gFTDataCaptainModel = null

## 0x8013103C
static var gFTDataCaptainSpecial2 = null

## 0x80131040
static var gFTDataCaptainSpecial3 = null

## 0x80131044
static var gFTDataCaptainParticleBankID: int = 0
