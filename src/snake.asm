    global _main
    extern InitIO
    extern Print
    extern Exit
    extern GetUpKey
    extern GetDownKey
    extern GetLeftKey
    extern GetRightKey
    extern Sleep

FRAME_DURATION:     EQU 33
SCREEN_WIDTH:       EQU 120
SCREEN_HEIGHT:      EQU 29
SCREEN_SIZE:        EQU (SCREEN_WIDTH * SCREEN_HEIGHT)

    section .data
player_x:   dd      0
player_y:   dd      0
screen_buf: times SCREEN_SIZE db 20h

    section .text
; void main();
_main:
    enter   0, 0
    
    call    InitIO

main_loop:
    ; Add delay
    push    FRAME_DURATION
    call    Sleep
    pop     eax

    ; Move down
    call    GetDownKey
    cmp     eax, 0
    je      not_pressing_down
    inc     dword [player_y]
not_pressing_down:

    ; Move up
    call    GetUpKey
    cmp     eax, 0
    je      not_pressing_up
    dec     dword [player_y]
not_pressing_up:

    ; Move right
    call    GetRightKey
    cmp     eax, 0
    je      not_pressing_right
    inc     dword [player_x]
not_pressing_right:

    ; Move left
    call    GetLeftKey
    cmp     eax, 0
    je      not_pressing_left
    dec     dword [player_x]
not_pressing_left:
    
    ; Draw frame to console
    call    DrawScreen

    jmp     main_loop

    ; Does not return
    call    Exit

; void DrawScreen();
DrawScreen:
    enter   0, 0

    ; Clear screen buffer
    mov     ecx, SCREEN_SIZE - SCREEN_WIDTH
clr_scr_loop:
    dec     ecx
    mov     byte [screen_buf+ecx], 2Eh
    cmp     ecx, 0
    jne     clr_scr_loop

    ; Draw player head
    push    SCREEN_WIDTH
    push    dword [player_y]
    call    Multiply
    add     esp, 8
    add     eax, [player_x]
    mov     byte [screen_buf+eax], 23h

    ; Draw screen
    push    SCREEN_SIZE
    push    screen_buf
    call    Print
    add     esp, 8

    leave
    ret

; int Multiply(int a, int b);
Multiply:
    enter   0, 0

    lea     ecx, [ebp+8]
    mov     eax, [ecx]
    lea     ecx, [ebp+12]
    mov     ebx, [ecx]
    mul     bx

    and     eax, 0FFFFh

    leave
    ret
