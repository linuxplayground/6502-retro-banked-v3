.import __VIA_START__

.export VIA_PORTB ; fe20
.export VIA_PORTA ; fe21
.export VIA_DDRB  ; fe22
.export VIA_DDRA  ; fe23
.export VIA_T1CL  ; fe24
.export VIA_T1CH  ; fe25
.export VIA_T1LL  ; fe26
.export VIA_T1LH  ; fe27
.export VIA_T2CL  ; fe28
.export VIA_T2CH  ; fe29
.export VIA_SR    ; fe2a
.export VIA_ACR   ; fe2b
.export VIA_PCR   ; fe2c
.export VIA_IFR   ; fe2d
.export VIA_IER   ; fe2e
.export VIA_PANH  ; fe2f

VIA_PORTB = __VIA_START__ + $0
VIA_PORTA = __VIA_START__ + $1
VIA_DDRB  = __VIA_START__ + $2
VIA_DDRA  = __VIA_START__ + $3
VIA_T1CL  = __VIA_START__ + $4
VIA_T1CH  = __VIA_START__ + $5
VIA_T1LL  = __VIA_START__ + $6
VIA_T1LH  = __VIA_START__ + $7
VIA_T2CL  = __VIA_START__ + $8
VIA_T2CH  = __VIA_START__ + $9
VIA_SR    = __VIA_START__ + $a
VIA_ACR   = __VIA_START__ + $b
VIA_PCR   = __VIA_START__ + $c
VIA_IFR   = __VIA_START__ + $d
VIA_IER   = __VIA_START__ + $e
VIA_PANH  = __VIA_START__ + $f
