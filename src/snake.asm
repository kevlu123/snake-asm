    global _main
    extern InitIO
    extern Print
    extern Exit
    extern GetUpKey
    extern GetDownKey
    extern GetLeftKey
    extern GetRightKey
    extern GetSpaceKey
    extern GetEscKey
    extern Get1Key
    extern Get2Key
    extern Get3Key
    extern Sleep
    extern IncrWithMod
    extern Multiply
    extern Modulo
    extern TickRand
    extern Rand

; Configurable properties
EASY_FRAME_DUR:     EQU 100
MED_FRAME_DUR:      EQU 50
HARD_FRAME_DUR:     EQU 25
SCREEN_WIDTH:       EQU 40
SCREEN_HEIGHT:      EQU 28
STARTING_FOOD_X:    EQU 30
STARTING_FOOD_Y:    EQU SCREEN_HEIGHT / 2
BACKGROUND_CHAR:    EQU 2Eh ; '.'
PLAYER_CHAR:        EQU 23h ; '#'
FOOD_CHAR:          EQU 40h ; '@'

SCREEN_SIZE:        EQU (SCREEN_WIDTH * SCREEN_HEIGHT)
SCREEN_BUF_SIZE:    EQU (SCREEN_SIZE + 2 * SCREEN_HEIGHT) ; Includes \r\n
MAX_BODY_SIZE:      EQU SCREEN_SIZE
CR_CHAR:            EQU 0Dh ; '\r'
LF_CHAR:            EQU 0Ah ; '\n'

    section .data

frame_sep:  times 20 db CR_CHAR, LF_CHAR ; Some arbitrary number of timess
frame_sep_end:
screen_buf: times SCREEN_BUF_SIZE db 20h

init_body:  dd 1, SCREEN_HEIGHT / 2, 2, SCREEN_HEIGHT / 2, 3, SCREEN_HEIGHT / 2
init_body_end:
body:       times SCREEN_SIZE * 2 dd 0 ; struct { uint32_t x, y; } body[SCREEN_SIZE] = {0};
head:       dd 0
tail:       dd 0
player_x:   dd 0
player_y:   dd 0
vel_x:      dd 0
vel_y:      dd 0
food_x:     dd 0
food_y:     dd 0
score:      dd 0
frame_dur:  dd 50

    section .text

; void main();
_main:
    enter   0, 0
    
    call    InitIO
    call    RunMainMenu
    call    InitGame
    call    RunMainLoop

    ; Does not return
    call    Exit

; void RunMainMenu();
RunMainMenu:
    enter   0, 0


    mov     dword [frame_dur], MED_FRAME_DUR

    leave
    ret

; void RunMainLoop();
RunMainLoop:
    enter   0, 0
    push    ebx

main_loop:
    ; Add delay
    push    dword [frame_dur]
    call    Sleep
    pop     eax

    ; Update rng
    call    TickRand

    ; Move down
    call    GetDownKey
    cmp     eax, 0
    je      not_pressing_down
    push    1
    push    0
    call    TryChangeDirection
    add     esp, 8
    cmp     eax, 0
    jne     end_move
not_pressing_down:

    ; Move up
    call    GetUpKey
    cmp     eax, 0
    je      not_pressing_up
    push    -1
    push    0
    call    TryChangeDirection
    add     esp, 8
    cmp     eax, 0
    jne     end_move
not_pressing_up:

    ; Move right
    call    GetRightKey
    cmp     eax, 0
    je      not_pressing_right
    push    0
    push    1
    call    TryChangeDirection
    add     esp, 8
    cmp     eax, 0
    jne     end_move
not_pressing_right:

    ; Move left
    call    GetLeftKey
    cmp     eax, 0
    je      not_pressing_left
    push    0
    push    -1
    call    TryChangeDirection
    add     esp, 8
    cmp     eax, 0
    jne     end_move
not_pressing_left:
end_move:

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
    cmp     eax, 0
    jne     end_main_loop

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
    call    DrawGame
    call    PresentFrame

    jmp     main_loop

end_main_loop:
    pop     ebx
    leave
    ret

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

; void ClearScreen();
ClearScreen:
    enter   0, 0
    
    ; Fill with '.'
    mov     ecx, 0
clr_scr_loop:
    mov     byte [screen_buf+ecx], BACKGROUND_CHAR
    inc     ecx
    cmp     ecx, SCREEN_BUF_SIZE
    jne     clr_scr_loop

    ; Add newlines
    mov     ecx, 0
fill_newline_loop:
    inc     ecx
    push    ecx
    push    SCREEN_WIDTH + 2
    push    ecx
    call    Multiply
    add     esp, 8
    pop     ecx
    mov     byte [screen_buf+eax-2], CR_CHAR
    mov     byte [screen_buf+eax-1], LF_CHAR
    cmp     ecx, SCREEN_HEIGHT
    jne     fill_newline_loop

    leave
    ret


; void PresentFrame();
PresentFrame:
    enter   0, 0

    ; Draw both frame separator and visible frame
    push    SCREEN_BUF_SIZE + (frame_sep_end - frame_sep)
    push    frame_sep
    call    Print
    add     esp, 8

    leave
    ret

; void DrawGame();
DrawGame:
    enter   0, 0

    call    ClearScreen

    ; Draw player
    push    0
    push    PLAYER_CHAR
    push    DrawChar
    call    IterateBody
    add     esp, 12

    ; Draw food
    push    FOOD_CHAR
    push    dword [food_y]
    push    dword [food_x]
    call    DrawChar
    add     esp, 12

    leave
    ret

; void DrawChar(uint32_t x, uint32_t y, uint32_t c);
DrawChar:
    enter   0, 0

    ; Calculate index into screen buffer
    push    ecx
    push    SCREEN_WIDTH + 2
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
    enter   0, 0
    sub     esp, 8

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
    mov     [esp], ecx
    mov     [esp+4], edx
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
    add     esp, 8
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

; uint32_t RunLoseLoop();
; Returns 1 if game should exit, otherwise 0
RunLoseLoop:
    enter   0, 0
    push    ebx

    ; Wait until space bar pressed
waiting_for_reset:
    call    GetSpaceKey
    cmp     eax, 0
    mov     ebx, 0
    jne     stop_lose_loop

    call    GetEscKey
    cmp     eax, 0
    mov     ebx, 1
    jne     stop_lose_loop

    jmp     waiting_for_reset

stop_lose_loop:

    ; Reinitialize game
    call    InitGame

    mov     eax, ebx
    pop     ebx
    leave
    ret

; uint32_t IterateBody(uint32_t(*fn)(uint32_t x, uint32_t y, void* userdata), void* userdata, uint32_t skipFirst);
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

; uint32_t TryChangeDirection(uint32_t new_vel_x, uint32_t new_vel_y);
TryChangeDirection:
    enter   0, 0
    push    ebx

    mov     eax, [ebp+8]  ; new_vel_x
    mov     ebx, [ebp+12] ; new_vel_y
    mov     ecx, [vel_x]  ; vel_x
    mov     edx, [vel_y]  ; vel_y

    ; Fancy bit hacks to check if new direction is valid
    add     ecx, eax
    add     edx, ebx
    and     ecx, edx
    cmp     ecx, 0
    mov     ecx, eax
    mov     eax, 0
    je      change_dir_end

    ; Apply new direction
    mov     [vel_x], ecx
    mov     [vel_y], ebx

    mov     eax, 1
change_dir_end:
    pop ebx
    leave
    ret
