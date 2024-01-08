.struct sIndex
        filename       .res 21  ; 21  0
        attrib         .byte    ; 1  21
        start          .dword   ; 4  22
        index_lba      .dword   ; 4  26
        size           .word    ; 2  30
.endstruct

.struct sVolId
        id             .res 8   ; 8  0
        version        .res 4   ; 4  7
        index_start    .dword   ; 4 11
        index_last     .dword   ; 4 15
        data_start     .dword   ; 4 19
.endstruct
