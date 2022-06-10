    global InitIO
    global Print
    global Exit
    global GetUpKey
    global GetDownKey
    global GetLeftKey
    global GetRightKey
    global GetSpaceKey
    global Sleep

; HANDLE WINAPI GetStdHandle(
;  _In_ DWORD nStdHandle
; );
    extern _GetStdHandle@4
; BOOL WriteFile(
;   [in]                HANDLE       hFile,
;   [in]                LPCVOID      lpBuffer,
;   [in]                DWORD        nNumberOfBytesToWrite,
;   [out, optional]     LPDWORD      lpNumberOfBytesWritten,
;   [in, out, optional] LPOVERLAPPED lpOverlapped
; );
    extern _WriteFile@20
; void ExitProcess(
;   [in] UINT uExitCode
; );
    extern _ExitProcess@4
;SHORT GetAsyncKeyState(
;   [in] int vKey
;);
    extern _GetAsyncKeyState@4
;void Sleep(
;   [in] DWORD dwMilliseconds
;);
    extern _Sleep@4


    section .data
stdout:
    dw 0


    section .text
; void InitIO();
InitIO:
    enter   0, 0

    ; GetStdHandle(STD_OUTPUT_HANDLE);
    push    -11
    call    _GetStdHandle@4
    add     esp, 4

    mov     [stdout], eax
    
    leave
    ret

; [noreturn] void Exit();
Exit:
    enter   0, 0
    
    ; Does not return
    push    0
    call    _ExitProcess@4

; void Print(const char* buf, uint32_t len);
Print:
    enter   4, 0
    push    ebx
    
    mov     eax, esp        ; dummy buffer address
    lea     ebx, [ebp+12]   ; len
    lea     ecx, [ebp+8]    ; buf

    push    0               ; overlapped
    push    eax             ; byteswritten
    push    dword [ebx]     ; len
    push    dword [ecx]     ; buf
    push    dword [stdout]  ; file
    call    _WriteFile@20
    add     esp, 20

    pop     ebx
    leave
    ret

; int GetKey(uint32_t keycode);
GetKey:
    enter   0, 0

    mov     eax, [ebp+8]
    push    eax
    call    _GetAsyncKeyState@4
    pop     ecx

    and     eax, 8000h

    leave
    ret

; int GetUpKey();
GetUpKey:
    enter   0, 0

    push    26h
    call    GetKey
    pop     ecx

    leave
    ret

; int GetDownKey();
GetDownKey:
    enter   0, 0

    push    28h
    call    GetKey
    pop     ecx

    leave
    ret

; int GetLeftKey();
GetLeftKey:
    enter   0, 0

    push    25h
    call    GetKey
    pop     ecx

    leave
    ret

; int GetRightKey();
GetRightKey:
    enter   0, 0

    push    27h
    call    GetKey
    pop     ecx

    leave
    ret

; int GetSpaceKey();
GetSpaceKey:
    enter   0, 0

    push    20h
    call    GetKey
    pop     ecx

    leave
    ret

Sleep:
    enter   0, 0

    mov     eax, [ebp+8]
    push    eax
    call    _Sleep@4
    pop     eax

    leave
    ret
