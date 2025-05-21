proc IntToStr uses bx di,\
     ofsString, num
     mov        ax, [num]
     mov        bx, 0
.loop1:
     mov        cx, 10
     xor        dx, dx
     div        cx
     push       dx
     inc        bx
     test       ax, ax
     jnz        .loop1

     mov        di, [ofsString]
     mov        [di], bx
     mov        dx, bx
     inc        dx
     mov        bx, 1
.loop2:
     pop        ax
     add        ax, '0'
     mov        [di + bx], al
     inc        bx
     cmp        bx, dx
     jnz        .loop2

     ret
endp