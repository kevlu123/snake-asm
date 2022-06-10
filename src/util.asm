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
