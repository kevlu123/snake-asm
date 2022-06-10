    global _main
    extern InitIO
    extern Print
    extern Exit
    extern GetUpKey
    extern GetDownKey
    extern GetLeftKey
    extern GetRightKey
    extern Sleep
    extern IncrWithMod
    extern Multiply
    extern Modulo
    extern TickRand
    extern Rand

FRAME_DURATION:     EQU 16
SCREEN_WIDTH:       EQU 120
SCREEN_HEIGHT:      EQU 29
SCREEN_SIZE:        EQU (SCREEN_WIDTH * SCREEN_HEIGHT)
MAX_BODY_SIZE:      EQU SCREEN_SIZE
STARTING_FOOD_X:    EQU 20
STARTING_FOOD_Y:    EQU 10

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
food_x:     dd 0
food_y:     dd 0
score:      dd 0

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

    ; Update rng
    call    TickRand

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

    ; Check if food is eaten
    mov     eax, [food_x]
    mov     ebx, [food_y]
    cmp     eax, ecx
    jne     food_not_eaten
    cmp     ebx, edx
    jne     food_not_eaten
    call    FoodEaten
    jmp     food_eaten
food_not_eaten:

    ; Increment tail
    push    MAX_BODY_SIZE
    push    dword [tail]
    call    IncrWithMod
    add     esp, 8
    mov     [tail], eax
food_eaten:

    ; Increment head
    push    MAX_BODY_SIZE
    push    dword [head]
    call    IncrWithMod
    add     esp, 8
    mov     [head], eax
    
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

    ; Set food position
    mov     dword [food_x], STARTING_FOOD_X
    mov     dword [food_y], STARTING_FOOD_Y

    ; Reset score
    mov     dword [score], 0

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

    ; Draw food
    push    40h
    push    dword [food_y]
    push    dword [food_x]
    call    DrawChar
    add     esp, 8

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

; void FoodEaten();
FoodEaten:
    enter   0, 0

    ; Pick new location for food
    push    SCREEN_WIDTH
    push    0
    call    Rand
    mov     [food_x], eax
    add     esp, 8

    push    SCREEN_HEIGHT
    push    0
    call    Rand
    mov     [food_y], eax
    add     esp, 8
    
    ; Increment score
    inc     dword [score]

    leave
    ret
