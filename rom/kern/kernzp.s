.include "banks.inc"

.globalzp kernptr1, kernptr2, ram_bank, rom_bank, imparm

.segment "KERNZP" : zeropage

ram_bank:       .res 1
rom_bank:       .res 1
kernptr1:       .res 2
kernptr2:       .res 2

.assert * = imparm, error, "imparm must be at specific address"
__imparm
	.res 2           ;    PRIMM utility string pointer