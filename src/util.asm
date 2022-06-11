    global IncrWithMod
    global Multiply
    global Modulo

    section .text
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

; uint32_t Modulo(uint32_t x, uint32_t m);
Modulo:
    enter   0, 0

    mov     eax, [ebp+8]  ; x
    mov     edx, [ebp+12] ; m

mod_loop:
    cmp     eax, 0
    jl      is_negative
    cmp     eax, edx
    jge     is_greater
    leave
    ret
is_negative:
    add     eax, edx
    jmp     mod_loop
is_greater:
    sub     eax, edx
    jmp     mod_loop
