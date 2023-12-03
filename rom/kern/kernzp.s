.include "banks.inc"

.globalzp krn_ptr1, ram_bank, rom_bank, imparm

.segment "KERNZP" : zeropage

ram_bank:       .res 1
rom_bank:       .res 1
krn_ptr1:       .res 2

.assert * = imparm, error, "imparm must be at specific address"
__imparm
	.res 2           ;    PRIMM utility string pointer
