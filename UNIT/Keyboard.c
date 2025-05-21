proc Keyboard.ReadKey
     mov        ax, 0C08h
     int        21h
     movzx      dx, al
     test       al, al
     jnz        @F
     mov        ah, 08h
     int        21h
     mov        dh, al
@@:
     xchg       dx, ax
     ret
endp
