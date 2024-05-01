; syscall is a big chunk
; kernels responsibility to restore everything before you go back
; kernel needs to have a way to recieve the trap reason
; loading in a register or memory?
; yank all registers and put them in memory before anything else happens
; Need a new instruction to tell CPU where that memory address is 

; kernel.asm
; needs to read in the instructions
; needs to be able to respond to CPU emu
; It needs to know the reason in order to know how to respond
; it does that by doing a syscall check on the number 
; It needs to keep track of the timer
; can use read and write instructions
; syscall is used in prime because it doesn't have access


;r0 is the program length
;r1 for the instruction word (whole thing)
;r2 for the instruction word (the next byte we gather)
;r3 is the memory address
;r4 loop counter
;r5 
;r6 reading 
;r7 is the instruction pointer


start: 
    ; Read the program length
    syscall 0 
    move r6 r0     ; Read the first byte into r0
    shl r0 8 r0    ; Shift r0 left by 8 bits
    ;read r1        ; Read the second byte into r1
    syscall 0 
    move r6 r1 
    or r0 r1 r0    ; Combine r0 and r1 using OR operation, store in r2

    ; Initialize loop counter and memory address
    loadLiteral 1024 r3     ; r3 is the memory address where the program starts
    loadLiteral 0 r4        ; r4 is our loop counter

instruc_loadin:
    ; Read and assemble ans instruction word
    ; Remember to use r1 to store the full word
    ; r2 will be used to read in the next byte

    ; clear r1 for new word
    loadLiteral 0 r1
    ; read in the 1st byte
    syscall 0
    move r6 r2
    ; shift 3 places because we read in 1 byte
    shl r2 24 r2
    ; combine
    or r2 r1 r1

    syscall 0
    move r6 r2
    ; shift 2 places because we read in 1 byte
    shl r2 16 r2
    ; combine
    or r2 r1 r1

    syscall 0
    move r6 r2
    ; shift 1 place because we read in 1 byte
    shl r2 8 r2
    ; combine
    or r2 r1 r1

    ; read the 4th byte
    syscall 0
    move r6 r2
    or r2 r1 r1

    ; we have the word (a line of code), so store it in memory
    ; store the instruction word in memory
    store r1 r3

    ; Increment counter and memory address
    ; Increment loop counter
    add r4 1 r4
    ; Increment memory address
    add r3 1 r3

    ; Compare loop counter with program length
    ; Compare counter (r4) with length (r0), result in r5
    lt r4 r0 r5
    ; If the loop counter is less than program length, then we have more instructions to write, jump to loop_end
    cmove r5 .instruc_loadin r7
    ; After storing all instructions, the instruction pointer (r7) is reset to 1024 to begin execution of the loaded program.

    ; set back to user mode
    setUserMode
    ; move the pointer back to 1024
    loadLiteral 1024 r7


trap_handler_store:
    store r0 0
    store r1 4
    store r2 8
    store r3 16
    store r4 20
    store r5 24

    ; Determine the reason for the trap (stored in a specific memory location, here assumed r6)
    load 6 r6  ; Assumed to contain the trap reason
    ; Check the trap reason and handle (all the checks/ hooks)

illegal_instruc:
    ; \nIllegal instruction!
    ; \nTimer fired XXXXXXXX times\n
    loadLiteral 10  r6 ; Newline character
    syscall 1
    loadLiteral 'I' r6
    syscall 1
    loadLiteral 'l' r6
    syscall 1
    loadLiteral 'l' r6
    syscall 1
    loadLiteral 'e' r6
    syscall 1
    loadLiteral 'g' r6
    syscall 1
    loadLiteral 'a' r6
    syscall 1
    loadLiteral 'l' r6
    syscall 1
    loadLiteral 32  r6 ; Space character
    syscall 1
    loadLiteral 'i' r6
    syscall 1
    loadLiteral 'n' r6
    syscall 1
    loadLiteral 's' r6
    syscall 1
    loadLiteral 't' r6
    syscall 1
    loadLiteral 'r' r6
    syscall 1
    loadLiteral 'u' r6
    syscall 1
    loadLiteral 'c' r6
    syscall 1
    loadLiteral 't' r6
    syscall 1
    loadLiteral 'i' r6
    syscall 1
    loadLiteral 'o' r6
    syscall 1
    loadLiteral 'n' r6
    syscall 1
    loadLiteral '!' r6
    syscall 1

    ;print number of times a time was fired
    loadLiteral .timesFired r0
    move r0 r7

    syscall 2 ; Exit process

mem_bounds:
; \nOut of bounds memory access!
; \nTimer fired XXXXXXXX times\n
    loadLiteral 10  r6 ; Newline character
    syscall 1
    loadLiteral 'O' r6
    syscall 1
    loadLiteral 'u' r6
    syscall 1
    loadLiteral 't' r6
    syscall 1
    loadLiteral 32  r6 ; Space character
    syscall 1
    loadLiteral 'o' r6
    syscall 1
    loadLiteral 'f' r6
    syscall 1
    loadLiteral 32  r6 ; Space character
    syscall 1
    loadLiteral 'b' r6
    syscall 1
    loadLiteral 'o' r6
    syscall 1
    loadLiteral 'u' r6
    syscall 1
    loadLiteral 'n' r6
    syscall 1
    loadLiteral 'd' r6
    syscall 1
    loadLiteral 's' r6
    syscall 1
    loadLiteral 32  r6 ; Space character
    syscall 1
    loadLiteral 'm' r6
    syscall 1
    loadLiteral 'e' r6
    syscall 1
    loadLiteral 'm' r6
    syscall 1
    loadLiteral 'o' r6
    syscall 1
    loadLiteral 'r' r6
    syscall 1
    loadLiteral 'y' r6
    syscall 1
    loadLiteral 32  r6 ; Space character
    syscall 1
    loadLiteral 'a' r6
    syscall 1
    loadLiteral 'c' r6
    syscall 1
    loadLiteral 'c' r6
    syscall 1
    loadLiteral 'e' r6
    syscall 1
    loadLiteral 's' r6
    syscall 1
    loadLiteral 's' r6
    syscall 1
    loadLiteral '!' r6
    syscall 1

    ;print number of times a time was fired
    loadLiteral .timesFired r0
    move r0 r7

    syscall 2 ; Exit process

halt:
    ; \nProgram has exited
    ; \nTimer fired XXXXXXXX times\n
    loadLiteral 10  r6 ; Newline character
    syscall 1
    loadLiteral 'P' r6
    syscall 1
    loadLiteral 'r' r6
    syscall 1
    loadLiteral 'o' r6
    syscall 1
    loadLiteral 'g' r6
    syscall 1
    loadLiteral 'r' r6
    syscall 1
    loadLiteral 'a' r6
    syscall 1
    loadLiteral 'm' r6
    syscall 1
    loadLiteral 32  r6 ; Space character
    syscall 1
    loadLiteral 'h' r6
    syscall 1
    loadLiteral 'a' r6
    syscall 1
    loadLiteral 's' r6
    syscall 1
    loadLiteral 32  r6 ; Space character
    syscall 1
    loadLiteral 'e' r6
    syscall 1
    loadLiteral 'x' r6
    syscall 1
    loadLiteral 'i' r6
    syscall 1
    loadLiteral 't' r6
    syscall 1
    loadLiteral 'e' r6
    syscall 1
    loadLiteral 'd' r6
    syscall 1

    ;print number of times a time was fired
    loadLiteral .timesFired r0
    move r0 r7

    syscall 2 ; Exit process

timer_fired:
    ; \nTimer fired\n
    loadLiteral 10  r6 ; Newline character
    syscall 1
    loadLiteral 'T' r6
    syscall 1
    loadLiteral 'i' r6
    syscall 1
    loadLiteral 'm' r6
    syscall 1
    loadLiteral 'e' r6
    syscall 1
    loadLiteral 'r' r6
    syscall 1
    loadLiteral 32  r6 ; Space character
    syscall 1
    loadLiteral 'f' r6
    syscall 1
    loadLiteral 'i' r6
    syscall 1
    loadLiteral 'r' r6
    syscall 1
    loadLiteral 'e' r6
    syscall 1
    loadLiteral 'd' r6
    syscall 1
    loadLiteral 10  r6 ; Newline character
    syscall 1

    ; jump to reset
    move r5 r7


timesFired:
    ; \nTimer fired XXXXXXXX times\n
    loadLiteral 10  r6 ; Newline character
    syscall 1
    loadLiteral 'T' r6
    syscall 1
    loadLiteral 'i' r6
    syscall 1
    loadLiteral 'm' r6
    syscall 1
    loadLiteral 'e' r6
    syscall 1
    loadLiteral 'r' r6
    syscall 1
    loadLiteral 32  r6 ; Space character
    syscall 1
    loadLiteral 'f' r6
    syscall 1
    loadLiteral 'i' r6
    syscall 1
    loadLiteral 'r' r6
    syscall 1
    loadLiteral 'e' r6
    syscall 1
    loadLiteral 'd' r6
    syscall 1
    loadLiteral 10  r6 ; Newline character
    syscall 1

    ; ; grab amount timer has been fired
    ; load 8 r0
    ; ; shift amount by 4
    ; loadLiteral 28 r1


trap_reset:
    ; Reset registers
    load 0 r0
    load 4 r1
    load 8 r2
    load 16 r3
    load 20 r4
    load 24 r5

    ; set back to user mode
    setUserMode


