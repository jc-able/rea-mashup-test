## 1:1 port of src/ft/ftchar/ftpurin/ftpurin.c (ssb-decomp-re): Jigglypuff's loaded-file globals.
## The file pointers are filled by the fighter data loader (ftdata.c / ftmanager.c port);
## they stay null until the loaded fighter data is attached.
class_name Ftpurin
extends Port

## 0x801310F0
static var gFTDataPurinMain = null

## 0x801310F4
static var gFTDataPurinMainMotion = null

## 0x801310F8
static var gFTDataPurinModel = null

## 0x801310FC
static var gFTDataPurinSpecial2 = null

## 0x80131100
static var gFTDataPurinParticleBankID: int = 0
