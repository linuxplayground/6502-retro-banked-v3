.export _acia_init
.export _acia_getc
.export _acia_putc
.export _acia_getc_nw
.export _acia_puts
.export _write
.export _cgetc
.export _cputc
.export _cputs
.export _cgetc_nw
.export _delay_ms
.export _wozmon
.export _prbyte
.export _primm

.export _rambankreg
.export _rombankreg
.export _via_portb
.export _via_porta
.export _via_ddrb
.export _via_ddra
.export _via_pcr
.export _via_ier

VIA_BASE = $9F20
_via_portb = VIA_BASE + $0
_via_porta = VIA_BASE + $1
_via_ddrb  = VIA_BASE + $2
_via_ddra  = VIA_BASE + $3
_via_pcr   = VIA_BASE + $c
_via_ier   = VIA_BASE + $e

BANK_BASE = $9F00
_rambankreg     = BANK_BASE + 0
_rombankreg     = BANK_BASE + 1

.code
_acia_init:               jmp ($FF00)
_acia_getc:               jmp ($FF02)
_acia_putc:               jmp ($FF04)
_acia_getc_nw:            jmp ($FF06)
_acia_puts:               jmp ($FF08)
_cgetc:                   jmp ($FF0A)
_cputc:                   jmp ($FF0C)
_cputs:                   jmp ($FF0E)
_cgetc_nw:                jmp ($FF10)
_delay_ms:                jmp ($FF12)
_wozmon:                  jmp ($FF14)
_prbyte:                  jmp ($FF16)
_write:                   jmp ($FF18)
_primm:                   jmp ($FF1A)
_rstfar:                  jmp ($FF1C)      
_jsfar:                   jmp ($FF1E)
