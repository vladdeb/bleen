        include 'macro\proc16.inc'
        org     100h
        include 'UNIT\Keyboard.h'
        include 'UNIT\Screen.h'
        include 'UNIT\Random.h'
        include 'UNIT\Files.h'

struc  String Data&
{
  local ..Length
  . db ..Length, Data
  ..Length = $ - . - 1
}


Model.CellSize  =       40
Model.SkipLen   =       2
Model.GridSize  =       4

False           =       0
True            =       1
Predef          =       False

dirUp           =       0
dirRight        =       1
dirDown         =       2
dirLeft         =       3

EntryPoint:
        stdcall Random.Initialize
        stdcall Files.SafeOpen
        mov     bx, cs
        add     bx, 1000h
        mov     [bufSegm], bx
        ;mov      [bufSegm], $A000

        mov     dx, $331
        mov     si, MIDI.init
        outsb
        outsb
        dec     dx
        outsb
        outsb
        outsb
        outsb
        outsb
        outsb

        stdcall Screen.SetMode, 0003h
        push    ax

        mov     ah, 09h
        mov     dx, strInp
        int     21h

        mov     ah, $0A
        mov     dx, bufName
        int     21h

        mov     di, strBoardLine + 9
        movzx   cx, [Name.Len]
        sub     di, cx
        mov     si, Name

        rep     movsb

        stdcall  Files.Fill, 5, Top5

        stdcall Screen.SetMode, 0013h

        stdcall Screen.ReadPalette, OldPalette
        stdcall Screen.WritePalette, Model.Colors, 12, 40h-12
        stdcall Model.StartGame
@@:
        stdcall Control.Move
        test    ax, ax
        jz      .endProg
        stdcall Model.IsOver
        test    ax, ax
        jnz     @B

        stdcall Screen.WriteStringVGA, (320 - 8*11)/2, 96 , strLose, $2800, $A000
@@:
        mov     dx, $330
        mov     si, MIDI.Applause

        outsb
        outsb
        outsb
        outsb

        stdcall Control.Move
        test    ax,ax
        jnz     @B


        cmp     [Name.Len], 0
        jz      .endProg

.writeResult:
        mov     di, strBoardLine + scorePos
        mov     si, strScore + 8
        mov     cx, 6

        rep     movsb
        stdcall Files.push, strBoardLine

.endProg:
        stdcall Screen.WritePalette, OldPalette, 256, 0
        stdcall Screen.SetMode
        mov     ah, 3eh
        movzx   bx, [File.handler]
        int     21h
        ret

        include 'UNIT\Keyboard.c'
        include 'UNIT\Screen.c'
        include 'UNIT\Random.c'
        include 'UNIT\myfunc.c'
        include 'UNIT\Files.c'

proc Model.SpawnCell uses bx
     stdcall    Random.Get, 1, [Model.FreeCells]
     mov        cx, ax
     push       cx
     stdcall    Random.Get, 0, 9
     pop        cx
     mov        dx, 1
     test       ax, ax
     jnz        @F
     mov        dx, 2
@@:
     mov        bx, 0
.loop:
     cmp        word [Model.Field + bx], 0
     jnz        .endloop
     dec        cx
     jnz        .endloop
     mov        [Model.Field + bx], dx
     jmp        .done
.endloop:
     add        bx, 2
     jmp        .loop
.done:
     dec        word [Model.FreeCells]
     ret
endp

proc Model.StartGame
     mov        bx, 0
if 1 - Predef
.fill:
     mov        word [bx + Model.Field], 0
     add        bx, 2
     cmp        bx, 2*Model.GridSize*Model.GridSize
     jb         .fill
end if
     mov        word[Model.Score], 0
if 1 - Predef
     mov        word[Model.FreeCells], Model.GridSize*Model.GridSize
     stdcall    Model.SpawnCell
     stdcall    Model.SpawnCell
else
     mov        word[Model.FreeCells], 0
end if
     stdcall    View.Update
     ret
endp

proc Model.Move uses bx di si,\
     wDir
     locals
        dBx     dw      ?
        dDi     dw      ?
        stBx    dw      ?
        stDi    dw      ?
        maxBx   dw      ?
        maxDi   dw      ?
        data    dw      2*Model.GridSize,  2,                2*Model.GridSize,                      0, 2*(Model.GridSize)*Model.GridSize, 2*(Model.GridSize),\
                        -2,                2*Model.GridSize, 2*(Model.GridSize - 2),                0, -2,                                2*(Model.GridSize)*Model.GridSize,\
                        -2*Model.GridSize, 2,                2*(Model.GridSize - 2)*Model.GridSize, 0, -2*Model.GridSize,                 2*(Model.GridSize),\
                        2,                 2*Model.GridSize, 2,                                     0, 2*Model.GridSize,                  2*(Model.GridSize)*Model.GridSize
     endl
     imul       di, [wDir], 12
     push       [data + di]
     pop        [dBx]
     push       [data + di + 2]
     pop        [dDi]
     push       [data + di + 4]
     pop        [stBx]
     push       [data + di + 6]
     pop        [stDi]
     push       [data + di + 8]
     pop        [maxBx]
     push       [data + di + 10]
     pop        [maxDi]
     mov        [Model.Moved], False
     mov        di, [stDi]
.cols:
     mov        bx, [stBx]
.find:
     cmp        [bx + di + Model.Field], 0
     jz         .next
     mov        dx, [bx + di + Model.Field]
     push       bx
.move:
     mov        cx, [stBx]
     sub        cx, [dBx]
     cmp        bx, cx
     je        .endMove
     sub        bx, [dBx]
;if empty cell move to it
     cmp        [bx + di + Model.Field], 0
     jnz        .notEmpty
     mov        [Model.Moved], True
     mov        [bx + di + Model.Field], dx
     add        bx, [dBx]
     mov        word[bx + di + Model.Field], 0
     sub        bx, [dBx]
     jmp        .move
;if not Empty check if equal
.notEmpty:
     cmp        [bx + di + Model.Field], dx
     jnz        .endMove
     inc        [Model.FreeCells]
     mov        [Model.Moved], True
     inc        dx
     mov        ax, 1
     mov        cl, dl
     shl        ax, cl
     add        [Model.Score], ax
     mov        [bx + di + Model.Field], dx
     add        bx, [dBx]
     mov        word[bx + di + Model.Field], 0
     sub        bx, [dBx]
     jmp        .endMove
.endMove:
     pop        bx

.next:
     add        bx, [dBx]
     cmp        bx, [maxBx]
     jne        .find

     add        di, [dDi]
     cmp        di, [maxDi]
     jne        .cols

     mov        dx, $330
     cmp        [Model.Moved], True
     jne        @F
     mov        si, MIDI.Ping

     outsb
     outsb
     outsb
     outsb
     stdcall    Model.SpawnCell
     stdcall    View.Update
     jmp        .done
@@:
     mov        dx, $330
     mov        si, MIDI.invalid
     outsb
     outsb
     outsb
     outsb

.done:
     ret
endp



proc Model.IsOver uses bx di
     mov        ax, True
     cmp        [Model.FreeCells], 0
     jnz        .done

     mov        bx, 0
.rows:
     mov        di, 2
.cols:
     mov        cx, [Model.Field + bx + di - 2]
     cmp        [Model.Field + bx + di], cx
     je         .done
     add        di, 2
     cmp        di, 2*Model.GridSize
     jb         .cols

     add        bx, 2*Model.GridSize
     cmp        bx, 2*Model.GridSize*Model.GridSize
     jb         .rows

     mov        di, 0
.cols1:
     mov        bx, 2*Model.GridSize
.rows1:
     mov        cx, [Model.Field + bx + di - 2*Model.GridSize]
     cmp        [Model.Field + bx + di], cx
     je         .done
     add        bx, 2*Model.GridSize
     cmp        bx, 2*Model.GridSize*Model.GridSize
     jb         .rows1

     add        di, 2
     cmp        di, 2*Model.GridSize
     jb         .cols1

     mov        ax, False
.done:
     ret
endp

proc Control.Move
     stdcall    Keyboard.ReadKey
     cmp        ax, $4800
     je         .Up
     cmp        ax, $5000
     je         .Down
     cmp        ax, $4b00
     je         .Left
     cmp        ax, $4d00
     je         .Right
     cmp        ax, $001B
     je         .esc
     jmp        .done

.Up:
     ;stdcall    Model.MoveUp
     mov        cx, dirUp
     jmp        .Move
     ;jmp        .done

.Down:
     ;stdcall    Model.MoveDown
     ;jmp        .done
     mov        cx, dirDown
     jmp        .Move


.Left:
     ;stdcall    Model.MoveLeft
     ;jmp        .done
     mov        cx, dirLeft
     jmp        .Move

.Right:
     ;stdcall    Model.MoveRight
     ;jmp        .done
     mov        cx, dirRight
     jmp        .Move

.esc:
     mov        ax, False
     jmp        .endProc

.Move:
     stdcall    Model.Move, cx
     jmp        .done

.done:
     mov        ax, True
.endProc:
     ret
endp


proc View.Update uses bx di si

     stdcall    Screen.ClearVGA, [bufSegm]
     mov        bx, 0
     mov        cx, 20
.lines:
     mov        di, 0
     ;imul       cx, bx, Model.CellSize+Model.SkipLen

     mov        dx, 0
.cols:
     push       cx
     push       dx
     stdcall    View.DrawCell, dx, cx, [Model.Field + bx + di]
     pop        dx
     pop        cx

     add        di, 2
     add        dx, Model.CellSize+Model.SkipLen
     cmp        di, 2*Model.GridSize
     jb         .cols

     add        cx, Model.CellSize+Model.SkipLen
     add        bx, 2*Model.GridSize
     cmp        bx, 2*Model.GridSize*Model.GridSize
     jb         .lines



     stdcall    IntToStr, strNum, [Model.Score]
     movzx      cx, [strNum]
     movzx      di, [strScore]
     add        di, strScore
     movzx      si, [strNum]
     add        si, strNum
     std
     rep        movsb
     cld

     mov        ax, 320
     movzx      cx, [strScore]
     shl        cx, 3
     sub        ax, cx

     stdcall Screen.WriteStringVGA, ax, 5, strScore, $000f, [bufSegm]

     stdcall Screen.WriteStringVGA, 320 - 8*11, 45, strLabel, $000E, [bufSegm]

     mov        cx, 5
     mov        dx, 65
     mov        si, Top5
.loop:
     push       cx
     push       dx
     stdcall Screen.WriteStringVGA, 320 - 8*(recLen+1), dx, si, $000f, [bufSegm]
     pop        dx
     pop        cx
     add        dx, 16
     add        si, recLen + 4
     loop       .loop

     stdcall View.DrawBuf
     ret
endp

proc View.DrawCell uses bx,\
     X, Y, num
     stdcall View.GetColor, [num]
     stdcall Screen.Rect, [X], [Y], Model.CellSize, Model.CellSize, ax, word[bufSegm]
     cmp     [num], 0
     jz      .done
     mov     ax, 1
     mov     cl, byte[num]
     shl     ax, cl
     stdcall IntToStr, strNum, ax
     mov     dx, [X]
     mov     ax, [Y]
     add     ax, (Model.CellSize-8)/2
     mov     cx, Model.CellSize
     movzx   bx, [strNum]
     shl     bx, 3
     sub     cx, bx
     shr     cx, 1
     add     dx, cx
     push    ax
     push    dx
     stdcall View.GetColor, [num]
     xchg    ax, cx
     xchg    ch, cl
     pop     dx
     pop     ax
     stdcall Screen.WriteStringVGA, dx, ax, strNum, cx, [bufSegm]

.done:

     ret
endp

proc View.DrawBuf uses si di es ds
     push         [bufSegm]
     pop          ds
     push         $A000
     pop          es
     xor          di, di
     xor          si, si
     mov          cx, 32000
     rep movsw
     ret
endp

proc View.GetColor ,\
     num
     mov        ax, $0015
     cmp        [num], 0
     je         .endP

     mov        ax, [num]
     add        ax, 40h-12
     jmp        .endP

.endP:
     ret
endp

        include 'UNIT\Keyboard.di'
        include 'UNIT\Screen.di'
        include 'UNIT\Random.di'
        include 'UNIT\Files.di'


;Model.Colors    db      $15, $1E, $5B, $42, $41, $40, $29, $44, $44, $2C, $2C, $0E
Model.Colors    db      24, 22, 20,\         ; 0
                        59, 56, 54,\         ; 2
                        59, 55, 49,\         ; 4
                        60, 44, 30,\         ; 8
                        61, 37, 24,\         ; 16
                        61, 31, 23,\         ; 32
                        61, 23, 15,\         ; 64
                        59, 51, 28,\         ; 128
                        59, 50, 24,\         ; 256
                        59, 49, 20,\         ; 512
                        59, 49, 16,\         ; 1024
                        59, 48, 11           ; 2048
Model.Colors.Length     db   ($ - Model.Colors)/3
if Predef
Model.Field     dw      13, 14, 15, 16,\
                        12, 11, 10, 9,\
                        5, 6, 7, 8,\
                        3, 3, 3, 3
;Model.Field     dw      $ - Model.Field + 1, Model.GridSize*Model.GridSize - 1 dup (($ - Model.Field + 1)/2)
end if

MIDI.init       db      $FF, $3F
MIDI.SetInstr   db      $C0, 98, $C1,  $7E, $C2, 96
MIDI.Ping       db      $90, $48, $6F, $F7
MIDI.Applause   db      $91, $48, $7F, $F7
MIDI.invalid    db      $92, $48, $7F, $F7
strBoardLine    String  "        : 000000", 13, 10
strInp          db      "Enter your name: ", '$'
strLabel        String      "Leaderboard"
bufName         db      9
Name.Len        db      0
Name            db      10 dup 0
strScore        String  "Score: 000000"
strLose         String  "YOU LOSE!"
Top5            db      recLen + 1, "1) ",  recLen dup (0), recLen + 1, "2) ", recLen dup (0), recLen + 1, "3) ", recLen dup (0), recLen + 1, "4) ", recLen dup (0), recLen + 1, "5) ", recLen dup (0)
;to2048          db      2048-1998 dup ('A')


        include 'UNIT\Keyboard.du'
        include 'UNIT\Screen.du'
        include 'UNIT\Random.du'
        include 'UNIT\Files.du'

bufSegm          dw      ?
strNum  db      7 dup (?)
Model.Moved     dw      ?
Model.FreeCells dw      ?
if 1 - Predef
Model.Field     dw      Model.GridSize*Model.GridSize dup (?)
end if
Model.Score     dw      ?
OldPalette      db      3 * 256 dup (?)


