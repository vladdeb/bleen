proc Screen.SetMode uses bx,\
     wMode

     mov        ah, $0F
     int        10h
     mov        bl, al

     movzx      ax, byte [wMode]
     int        10h
     mov        ah, $05
     mov        al, byte [wMode + 1]
     int        10h

     xchg       ax, bx
     ret
endp

proc Screen.Clear uses es di
     cld
     push         $B800
     pop          es
     xor          di, di
     xor          ax, ax
     mov          cx, 80 * 25
     rep          stosw
     ret
endp

proc Screen.ClearVGA uses es di,\
     wSegm
     cld
     push         [wSegm]
     pop          es
     xor          di, di
     xor          ax, ax
     mov          cx, 320 * 200/2
     rep          stosw
     ret
endp

proc Screen.writeString uses es si di,\
     ofsString, nLine, alAlign, bAttr: Byte
     mov        si, [ofsString]
     lodsb
     movzx      cx, al
     imul       di, [nLine], 80
     mov        dx, 0
     cmp        [alAlign], alLeft
     je         .Write
     mov        dx, 80
     sub        dx, cx
     cmp        [alAlign], alRight
     je         .Write
     shr        dx, 1
.Write:
     add        di, dx
     shl        di, 1
     push       $B800
     pop        es
     mov        ah, [bAttr]
.Writeloop:
     lodsb
     stosw
     loop .Writeloop


     ret
endp

proc Screen.Rect uses si di es,\
     X, Y, W, H, Color: Byte, wSegm      ;x, y, w, h, color

     mov     dx, [H]
     mov     al, [Color]
     imul    di, [Y], 320
     add     di, [X]
     push    [wSegm]
     pop     es
.rowLoop:
     mov     cx, [W]
     rep     stosb
     add     di, 320
     sub     di, [W]
     dec     dx
     jnz     .rowLoop
     ret
endp

proc Screen.WriteStringVGA uses si di es,\
     X, Y, ofsString, Color, bufSegm     ;Color = bgColor:fntColor

     push       bp
     ;es:bx char table
     mov        ax, 1130h
     mov        bh, 03h
     int        10h
     mov        bx, bp
     pop        bp
     ;di for video memory ofs
     imul       di, [Y], 320
     add        di, [X]
     mov        cl, 1
.strLoop:
     ;si - char table ofs: 16*c
     movzx      si, cl
     push       bx
     mov        bx, [ofsString]
     movzx      si, byte[bx + si]
     pop        bx
     shl        si, 3
     mov        ch, 0
.charLoop:
     ;ax - line mask
     mov        ax, 0000'0000_1000'0000b

.lineLoop:
     ;dh - color
     mov        dh, byte [Color]
     test       [es:bx + si], ax
     jnz        @F
     mov        dh, byte [Color + 1]
@@:
     push       es
     push       [bufSegm]
     pop        es
     mov        byte [es:di], dh
     pop        es
.lineLoopEnd:
     inc        di
     ror        ax, 1
     cmp        ax, 1000'0000_0000'0000b
     jne        .lineLoop
.charLoopEnd:
     inc        si
     add        di, 320
     sub        di, 8
     inc        ch
     cmp        ch, 8
     jb         .charLoop
.strLoopEnd:
     sub        di, 320*8
     add        di, 8
     inc        cl
     push       bx
     mov        bx, [ofsString]
     cmp        cl, byte [bx]
     pop        bx
     jbe        .strLoop


                     ;0000 -> 0000'0000_0000'0000
                     ;C600 -> 1100'0110_0000'0000

     ret
endp

proc Screen.ReadPalette uses di,\
     ofsPalette

     mov        di, [ofsPalette]
     mov        cx, 256
     xor        ax, ax
.ReadLoop:
     mov        dx, $3C7
     mov        al, ah
     out        dx, al
     mov        dx, $3C9
     insb
     insb
     insb
     inc        ah
     loop       .ReadLoop
     ret
endp

proc Screen.WritePalette uses si,\
     ofsNew, nChange, Start
     mov     si, [ofsNew]
     mov     cx, [nChange]
     mov     ax, [Start]
     xchg     ah, al
.WriteLoop:
     mov     dx, $3C8
     mov     al, ah
     out     dx, al
     mov     dx, $3C9
     outsb
     outsb
     outsb
     inc     ah
     loop    .WriteLoop

     ret
endp