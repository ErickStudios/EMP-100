
    local 0F000h ; en ROM
    
    BANK_CFG equ 2000h

DR: db 0
ER: db 0
HR: db 0

reset:
    PAG $DR.h
    CTA $DR.l

    reserve (0FF0h-$)
    STC
    PAG $reset.h
    BCC $reset.l
    reserve (1000h-$)
