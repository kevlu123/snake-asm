    global TickRand
    global Rand
    extern GetUpKey
    extern GetDownKey
    extern GetLeftKey
    extern GetRightKey
    extern Multiply
    extern Modulo

    section .data
seed:   dd 123h

    section .text
; void TickRand();
TickRand:
    enter   0, 0
    push    ebx

    mov     ebx, 1
    
    call    GetDownKey
    cmp     eax, 0
    je      not_pressing_down
    add     ebx, 2
not_pressing_down:
    call    GetUpKey
    cmp     eax, 0
    je      not_pressing_up
    add     ebx, 3
not_pressing_up:
    call    GetRightKey
    cmp     eax, 0
    je      not_pressing_right
    add     ebx, 5
not_pressing_right:
    call    GetLeftKey
    cmp     eax, 0
    je      not_pressing_left
    add     ebx, 7
not_pressing_left:

    ; Advance random number generator ebx amount of times
    mov     ecx, 0
tick_rand_loop:
    push    ecx
    call    AdvanceRand
    pop     ecx
    inc     ecx
    cmp     ecx, ebx
    jne     tick_rand_loop

    pop     ebx
    leave
    ret

; uint32_t Rand(uint32_t lower, uint32_t upperExcl);
Rand:
    enter   0, 0
    push    ebx

    call    AdvanceRand

    mov     ebx, [ebp+8]  ; Lower bound
    mov     ecx, [ebp+12] ; Upper bound

    ; Calculate range
    mov     edx, ecx
    sub     edx, ebx

    ; Fit random number into range
    push    edx
    push    eax
    call    Modulo
    add     eax, ebx

    pop     ebx
    leave
    ret

; uint32_t AdvanceRand();
AdvanceRand:
    enter   0, 0

    ; seed = (seed * x + y) % 0xFFFF
    push    dword [seed]
    push    1406714865
    call    Multiply
    add     esp, 8
    add     eax, 128201163
    and     eax, 0FFFFh
    mov     [seed], eax

    leave
    ret
