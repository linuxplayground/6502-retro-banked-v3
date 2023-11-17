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

VIA_BASE = $9F20

VIA_PORTB = VIA_BASE + $0
VIA_PORTA = VIA_BASE + $1
VIA_DDRB  = VIA_BASE + $2
VIA_DDRA  = VIA_BASE + $3
VIA_T1CL  = VIA_BASE + $4
VIA_T1CH  = VIA_BASE + $5
VIA_T1LL  = VIA_BASE + $6
VIA_T1LH  = VIA_BASE + $7
VIA_T2CL  = VIA_BASE + $8
VIA_T2CH  = VIA_BASE + $9
VIA_SR    = VIA_BASE + $a
VIA_ACR   = VIA_BASE + $b
VIA_PCR   = VIA_BASE + $c
VIA_IFR   = VIA_BASE + $d
VIA_IER   = VIA_BASE + $e
VIA_PANH  = VIA_BASE + $f
