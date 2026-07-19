; I wrote the code, and had AI document it.
; Has you enter a password, and will keep asking until you enter
; a strong password (8+ characters and contains '!').
; decided to do '!' to give myself a lil challenge

extern printf
extern exit
extern gets_s
extern strcat
extern strlen        

section .data
    prompt:         db "Enter a password: ", 0
    strong_msg:     db "Status: Strong Password!", 10, 0
    weak_msg:       db "Status: Too Weak or missing '!'! Must be 8+ characters.", 10, 0
    
    message_buffer: db "Password is: ", 0
                    times 100 db 0 
    letter_search:  db '!'
    format:         db "%s",0

section .bss
    password: resb 100

section .text
    global main

; =====================================================================
; check_char_in
; Expects: RCX = character to find (e.g., '!')
;          RDX = address of the string to search
; Returns: RAX = 1 if found, 0 if not found
; =====================================================================
check_char_in:
    push rbp
    mov rbp, rsp
    
    push rbx
    push rsi

    mov rbx, rcx       ; RBX = The character byte to find
    mov rsi, rdx       ; RSI = The address of the string
    xor r8, r8         ; R8  = Our loop index counter (Start at 0)

.loop_start:
    movzx rax, byte [rsi + r8]  ; Load current character into RAX
    
    cmp rax, 0
    je .not_found               ; If character is \0, we hit the end.

    cmp rax, rbx
    je .found                   ; If it matches our target, success!

    inc r8                      ; Move to next character slot
    jmp .loop_start             

.found:
    mov rax, 1                  ; Return True (1)
    jmp .done

.not_found:
    mov rax, 0                  ; Return False (0)

.done:
    pop rsi
    pop rbx
    pop rbp
    ret


; =====================================================================
; check_strong
; Expects: RCX = address of the password string
; Returns: RAX = 1 if strong (length >= 8 AND contains '!'), 0 if weak
; =====================================================================
check_strong:
    push rbp
    mov rbp, rsp
    push rbx                      ; Honor Code: Save RBX because we borrow it

    mov rbx, rcx                  ; Save the password pointer securely in RBX
                                  ; so strlen won't destroy it!

    ; --- CHECK 1: Length Check ---
    call strlen                   ; RAX now holds the password length number
    mov r9, 1
    xor r8, r8                    ; Assume length check fails (R8 = 0)
    cmp rax, 8                    ; Compare length against 8
    cmovge r8, r9                 ; If length >= 8, R8 becomes 1

    ; --- CHECK 2: Character Check ---
    ; Read the byte character out of memory from our data section
    movzx rcx, byte [rel letter_search]  ; RCX = '!'
    mov rdx, rbx                  ; RDX = The password string pointer
    


    ; --- COMBINE BOTH RESULTS ---
    and rax, r8                   ; Logical AND: RAX = (Char Found) AND (Length Pass)
                                  ; If BOTH are 1, RAX stays 1. Otherwise becomes 0.

    pop rbx                       ; Honor Code Restore
    pop rbp
    ret

; =====================================================================
; main ROUTINE
; =====================================================================
main:
    push rbp
    mov rbp, rsp
    sub rsp, 32                   ; Set up standard shadow space

.ask_again:                       ; Target label for re-asking the user
    ; 1. Print the prompt
    lea rcx, [rel prompt]
    call printf

    ; 2. Get user input
    lea rcx, [rel password]
    mov rdx, 100
    call gets_s

    ; 3. Validate strength
    lea rcx, [rel password]       ; Pass the string location to check_strong
    call check_strong
    
    cmp rax, 1                    ; Is our combined status flag 1 (Strong)?
    jne .is_weak                  ; If it is NOT equal to 1, go to the weak handler!
    jmp .is_strong                ; Otherwise, it's strong!

.is_strong:
    lea rcx, [rel strong_msg]     ; Load the strong success message
    call printf
    jmp .print_final_string       ; Skip the weak code entirely

.is_weak:
    lea rcx, [rel weak_msg]       ; Load the failure warning message
    call printf
    jmp .ask_again                ; Pure jump back to the prompt loop!

.print_final_string:
    lea rcx, [rel message_buffer] 
    lea rdx, [rel password]       
    call strcat                   

    lea rcx, [rel message_buffer]
    call printf
    
    ; 5. Exit
    add rsp, 32
    xor rcx, rcx
    call exit