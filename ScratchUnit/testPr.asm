    local 0
start:
    CHA $3  ;   %a = 3
    CHZ $2  ;   %z = 2
    SHL %z  ;   %a shl %z
    STC     ;   /cf = 1
    PAG $0  ;   %p = $0
.hlt:
    BCC $.hlt ; %pc = /cf ? %p:$.hlt : %pc