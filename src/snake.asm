    global _main
    extern InitIO
    extern Print
    extern Exit
    extern GetUpKey
    extern GetDownKey
    extern GetLeftKey
    extern GetRightKey
    extern Sleep

FRAME_DURATION:     EQU 100
SCREEN_WIDTH:       EQU 120
SCREEN_HEIGHT:      EQU 29
SCREEN_SIZE:        EQU (SCREEN_WIDTH * SCREEN_HEIGHT)
MAX_BODY_SIZE:      EQU SCREEN_SIZE

    section .data

screen_buf: times SCREEN_SIZE db 20h
init_body:  dd 1, 13, 2, 13, 3, 13
init_body_end:
; struct { uint32_t x, y; } body[SCREEN_SIZE] = {0};
body:       times SCREEN_SIZE * 2 dd 0
head:       dd 0
tail:       dd 0
player_x:   dd 0
player_y:   dd 0
vel_x:      dd 0
vel_y:      dd 0

    section .text
; void main();
_main:
    enter   0, 0
    
    call    InitIO

    call    InitGame

main_loop:
    ; Add delay
    push    FRAME_DURATION
    call    Sleep
    pop     eax

    ; Move down
    call    GetDownKey
    cmp     eax, 0
    je      not_pressing_down
    mov     dword [vel_x], 0
    mov     dword [vel_y], 1
not_pressing_down:

    ; Move up
    call    GetUpKey
    cmp     eax, 0
    je      not_pressing_up
    mov     dword [vel_x], 0
    mov     dword [vel_y], -1
not_pressing_up:

    ; Move right
    call    GetRightKey
    cmp     eax, 0
    je      not_pressing_right
    mov     dword [vel_x], 1
    mov     dword [vel_y], 0
not_pressing_right:

    ; Move left
    call    GetLeftKey
    cmp     eax, 0
    je      not_pressing_left
    mov     dword [vel_x], -1
    mov     dword [vel_y], 0
not_pressing_left:

    ; Move snake
    mov     ecx, [player_x]
    add     ecx, [vel_x]
    mov     [player_x], ecx
    mov     edx, [player_y]
    add     edx, [vel_y]
    mov     [player_y], edx

    mov     eax, [head]
    shl     eax, 3
    add     eax, body
    mov     [eax], ecx
    mov     [eax+4], edx

    ; Increment head and tail index with wrapping
    push    MAX_BODY_SIZE
    push    dword [head]
    call    IncrWithMod
    add     esp, 8
    mov     [head], eax
    push    MAX_BODY_SIZE
    push    dword [tail]
    call    IncrWithMod
    add     esp, 8
    mov     [tail], eax
    
    ; Draw frame to console
    call    DrawScreen

    jmp     main_loop

    ; Does not return
    call    Exit

; void InitGame();
InitGame:
    enter   0, 0
    push    ebx
    
    ; Set snake starting position
    mov     ecx, 0
init_snake_loop:
    mov     al, [init_body+ecx]
    mov     [body+ecx], al
    inc     ecx
    cmp     ecx, init_body_end - init_body
    jne     init_snake_loop

    ; Set head position
    mov     eax, [init_body_end-8]
    mov     [player_x], eax
    mov     eax, [init_body_end-4]
    mov     [player_y], eax

    ; Set head and tail index
    mov     dword [head], 3 ; Exclusive
    mov     dword [tail], 0 ; Inclusive

    ; Set direction
    mov     dword [vel_x], 1
    mov     dword [vel_y], 0

    pop     ebx
    leave
    ret

; void DrawScreen();
DrawScreen:
    enter   0, 0
    push    ebx

    ; Clear screen buffer
    mov     ecx, 0
clr_scr_loop:
    mov     byte [screen_buf+ecx], 2Eh
    inc     ecx
    cmp     ecx, SCREEN_SIZE - SCREEN_WIDTH
    jne     clr_scr_loop

    ; Draw player
    mov     ecx, [tail] ; Start index
    mov     ebx, [head] ; End index
draw_player_loop:
    push    ecx    
    mov     eax, ecx
    shl     eax, 3
    add     eax, body
    push    23h
    push    dword [eax+4]
    push    dword [eax]
    call    DrawChar
    add     esp, 12
    pop     ecx
    
    ; Increment loop counter with wrapping
    push    MAX_BODY_SIZE
    push    ecx
    call    IncrWithMod
    add     esp, 8
    mov     ecx, eax
    ; End of loop
    cmp     ecx, ebx
    jne     draw_player_loop

    ; Draw screen
    push    SCREEN_SIZE
    push    screen_buf
    call    Print
    add     esp, 8

    pop     ebx
    leave
    ret

; void DrawChar(uint32_t x, uint32_t y, uint32_t c);
DrawChar:
    enter   0, 0

    ; Calculate index into screen buffer
    push    ecx
    push    SCREEN_WIDTH
    push    dword [ebp+12]
    call    Multiply
    add     esp, 8
    pop     ecx
    add     eax, [ebp+8]

    ; Write to screen buffer
    mov     ecx, [ebp+16]
    mov     [screen_buf+eax], cl

    leave
    ret

; uint32_t IncrWithMod(uint32_t x, uint32_t m);
IncrWithMod:
    enter   0, 0

    mov     eax, [ebp+8]
    inc     eax
    push    dword [ebp+12]
    push    eax
    call    Modulo
    add     esp, 8

    leave
    ret

; uint32_t Multiply(uint32_t a, uint32_t b);
Multiply:
    enter   0, 0
    push    ebx

    mov     eax, [ebp+8]
    mov     ebx, [ebp+12]
    mul     bx

    and     eax, 0FFFFh

    pop     ebx
    leave
    ret

; uint32_t Modulo(uint32_t a, uint32_t b);
Modulo:
    enter   0, 0
    push    ebx

    mov     eax, [ebp+8]
    mov     edx, 0
    mov     ebx, [ebp+12]
    div     ebx
    mov     eax, edx

    pop     ebx
    leave
    ret
