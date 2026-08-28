
    local 0C000h ; en ROM
    
    BANK_CFG equ 0A000h
    SP_OFF   equ 0A100h
    SP_PAG   equ 0A101h
    BL_REG   equ 0A102h
    RT_REG   equ 0A103h

DR: db 0
ER: db 0
HR: db 0

reset:
    CHA $0FFh
    PAG $SP_PAG.h
    CTA $SP_PAG.l
    CHA $02Fh
    CTA $SP_OFF.l

    CTA $BL_REG.l

    PAG $proce.h
    BCC $proce.l

aloop:
    PAG $aloop.h
    BCC $aloop.l

proce:
    PAG $RT_REG.h
    CTA $RT_REG.l

    reserve (3FF0h-$)
    STC
    PAG $reset.h
    BCC $reset.l
    reserve (4000h-$)
