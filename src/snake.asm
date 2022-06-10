    global _main
    extern InitIO
    extern Print
    extern Exit
    extern GetUpKey
    extern GetDownKey
    extern GetLeftKey
    extern GetRightKey
    extern GetSpaceKey
    extern Sleep
    extern IncrWithMod
    extern Multiply
    extern Modulo
    extern TickRand
    extern Rand

FRAME_DURATION:     EQU 200
SCREEN_WIDTH:       EQU 120
SCREEN_HEIGHT:      EQU 29
SCREEN_SIZE:        EQU (SCREEN_WIDTH * SCREEN_HEIGHT)
MAX_BODY_SIZE:      EQU SCREEN_SIZE
STARTING_FOOD_X:    EQU 20
STARTING_FOOD_Y:    EQU 10

    section .data

screen_buf: times SCREEN_SIZE db 20h
init_body:  dd 1, 13, 2, 13, 3, 13, 4, 13
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

    ; Calculate new position
    mov     ecx, [player_x]
    add     ecx, [vel_x]
    mov     [player_x], ecx
    mov     edx, [player_y]
    add     edx, [vel_y]
    mov     [player_y], edx

    ; Check if snake has collided with wall or itself
    push    ecx
    push    edx
    push    edx
    push    ecx
    call    CheckCollision
    add     esp, 8
    pop     edx
    pop     ecx
    cmp     eax, 0
    je      hasnt_lost
    call    RunLoseLoop
    jmp     main_loop
hasnt_lost:

    ; Move snake
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
    mov     dword [head], (init_body_end - init_body) / 8
    mov     dword [tail], 0

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
    cmp     ecx, SCREEN_SIZE
    jne     clr_scr_loop

    ; Draw player
    push    0
    push    23h
    push    DrawChar
    call    IterateBody
    add     esp, 12

    ; Draw food
    push    40h
    push    dword [food_y]
    push    dword [food_x]
    call    DrawChar
    add     esp, 12

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
    add     esp, 8
    mov     [food_x], eax

    push    SCREEN_HEIGHT
    push    0
    call    Rand
    add     esp, 8
    mov     [food_y], eax
    
    ; Increment score
    inc     dword [score]

    leave
    ret

; uint32_t CheckCollision(uint32_t x, uint32_t y);
CheckCollision:
    enter   8, 0

    mov     ecx, [ebp+8]  ; x
    mov     edx, [ebp+12] ; y

    ; Check wall collision
    mov     eax, 1
    cmp     ecx, -1
    je      check_collision_end
    cmp     edx, -1
    je      check_collision_end
    cmp     ecx, SCREEN_WIDTH
    je      check_collision_end
    cmp     edx, SCREEN_HEIGHT
    je      check_collision_end

    ; Check body collision
    mov     [esp+4], ecx
    mov     [esp+8], edx
    lea     eax, [esp+4]
    push    1
    push    eax
    push    CheckBodyCollision
    call    IterateBody
    add     esp, 12
    cmp     eax, 0
    mov     eax, 1
    je      check_collision_end

    mov     eax, 0
check_collision_end:
    leave
    ret

; uint32_t CheckBodyCollision(uint32_t x, uint32_t y, void* userdata);
; Returns 0 if there was a collision, otherwise 1.
CheckBodyCollision:
    enter   0, 0
    push    ebx

    mov     eax, [ebp+16]
    mov     ecx, [eax]
    mov     edx, [eax+4]

    mov     eax, [ebp+8]
    mov     ebx, [ebp+12]

    cmp     eax, ecx
    mov     eax, 1
    jne     check_body_collision_end

    cmp     ebx, edx
    mov     eax, 1
    jne     check_body_collision_end

    mov     eax, 0
check_body_collision_end:
    pop     ebx
    leave
    ret

; void RunLoseLoop();
RunLoseLoop:
    enter   0, 0

    ; Wait until space bar pressed
waiting_for_reset:
    call    GetSpaceKey
    cmp     eax, 0
    je      waiting_for_reset

    ; Reinitialize game
    call InitGame

    leave
    ret

; bool IterateBody(bool(*fn)(uint32_t x, uint32_t y, void* userdata), void* userdata, bool skipFirst);
IterateBody:
    enter   0, 0
    push    ebx

    mov     ecx, [tail] ; Start index
    mov     ebx, [head] ; End index

    mov     eax, [ebp+16]
    cmp     eax, 0
    jne     skip_first

iterate_body_loop:
    push    ecx    
    mov     eax, ecx
    shl     eax, 3
    add     eax, body
    push    dword [ebp+12]
    push    dword [eax+4]
    push    dword [eax]
    call    dword [ebp+8]
    add     esp, 12
    pop     ecx

    ; Check if should terminate
    cmp     eax, 0
    je      body_iter_end

    ; Increment loop counter with wrapping
skip_first:
    push    MAX_BODY_SIZE
    push    ecx
    call    IncrWithMod
    add     esp, 8
    mov     ecx, eax

    ; End of loop
    cmp     ecx, ebx
    jne     iterate_body_loop

    mov     eax, 1
body_iter_end:
    pop     ebx
    leave
    ret
