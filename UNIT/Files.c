proc Files.SafeOpen
     mov        ax, $3D02
     mov        dx, FileName + 1
     int        21h
     cmp        ax, 2
     jne         .done
     mov        ah, $3C
     mov        dx, FileName + 1
     xor        cx, cx
     int        21h
.done:
     mov        [File.handler], al
     ret
endp

proc Files.push uses si bx di,\
     ofsString
     mov        si, [ofsString]
     mov        ax, $4202
     xor        cx, cx
     xor        dx, dx
     movzx      bx, [File.handler]
     int        21h

     mov        di, ax

     mov        ah, $40
     movzx      bx, [File.handler]
     mov        cx, recLen
     mov        dx, si
     inc        dx
     int        21h
     cmp        ax, 0

.loop:
     sub        di, recLen
     cmp        di, 0
     jl         .done

     mov        ax, $4200
     mov        dx, di
     xor        cx, cx
     movzx      bx, [File.handler]
     int        21h

     mov        ah, $3F
     movzx      bx, [File.handler]
     mov        dx, strBuf + 1
     mov        cx, recLen
     int        21h

     push       di
     mov        di, scorePos
     mov        bx, si

.compLoop:
     mov        al, [strBuf + di]
     cmp        [bx + di], al
     je         .endCompLoop
     jb         .below

     pop        di

     mov        ax, $4200
     mov        dx, di
     xor        cx, cx
     movzx      bx, [File.handler]
     int        21h

     mov        ah, $40
     movzx      bx, [File.handler]
     mov        cx, recLen
     mov        dx, si
     inc        dx
     int        21h

     mov        ah, $40
     movzx      bx, [File.handler]
     mov        cx, recLen
     mov        dx, strBuf
     inc        dx
     int        21h
     jmp        .loop



.endCompLoop:
    inc         di
    cmp         di, recLen - 2
    jbe         .compLoop


.below:
    pop         di

.done:

     ret
endp

proc Files.Fill uses si,\
     N, ofsTab
     mov        ax, $4200
     xor        cx, cx
     xor        dx, dx
     movzx      bx, [File.handler]
     int        21h

     mov        si, [ofsTab]
     add        si, 4
     mov        cx, [N]
.loop:
     push       cx
     mov        ah, $3f
     movzx      bx, [File.handler]
     mov        cx, recLen
     mov        dx, si
     int        21h
     pop        cx
     cmp        ax, recLen
     jne        .done

     add        si, recLen + 4
     loop       .loop

.done:
     ret

endp