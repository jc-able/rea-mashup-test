## 1:1 port of src/ft/ftchar/ftpikachu/ftpikachu.c (ssb-decomp-re): Pikachu's loaded-file globals.
## The file pointers are filled by the fighter data loader (ftdata.c / ftmanager.c port);
## they stay null until the loaded fighter data is attached.
class_name Ftpikachu
extends Port

## 0x801310B0
static var gFTDataPikachuMain = null

## 0x801310B4
static var gFTDataPikachuMainMotion = null

## 0x801310B8
static var gFTDataPikachuModel = null

## 0x801310BC
static var gFTDataPikachuSpecial1 = null

## 0x801310C0
static var gFTDataPikachuSpecial2 = null

## 0x801310C4
static var gFTDataPikachuSpecial3 = null

## 0x801310C8
static var gFTDataPikachuParticleBankID: int = 0
