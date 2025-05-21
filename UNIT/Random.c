proc Random.Initialize
     mov        ah, 2Ch
     int        21h
     mov        [Random.wPrevValue], dx
     ret
endp

proc Random.Get \
     wMin, wMax
     push       ax
     mov        ax, [Random.wPrevValue]
     mov        cx, 8405h
     imul       cx
     add        ax, 1
     mov        [Random.wPrevValue], ax

     mov        cx, [wMax]
     sub        cx, [wMin]
     inc        cx
     mov        dx, cx
     mul        dx
     add        dx, [wMin]
;     xor        dx, dx
;     div        cx

  ;   add        dx, [wMin]
     xchg       ax, dx
     ret
endp