
;r0 is the program length
;r1 for the instruction word (whole thing)
;r2 for the instruction word (the next byte we gather)
;r3 is the memory address
;r4 loop counter
;r5 
;r7 is the instruction pointer


; syscall is a big chunk
; kernels responsibility to restore everything before you go back
; kernel needs to have a way to recieve the trap reason
; loading in a register or memory?
; yank all registers and put them in memory before anything else happens
; Need a new instruction to tell CPU where that memory address is 
; 0 - 1023: kernel
; 1024 - above: user

store:
    store r0 4
    store r1 8
    store r2 16
    store r3 20
    store r4 24
    store r5 28
    store r6 32
    ; store r7 36

start: 
    ; Read the program length
    syscall 0 
    move r6 r0     ; Read the first byte into r0
    shl r0 8 r0    ; Shift r0 left by 8 bits
    read r1        ; Read the second byte into r1
    or r0 r1 r0    ; Combine r0 and r1 using OR operation, store in r2


; Initialize loop counter and memory address
loadLiteral 1024 r3     ; r3 is the memory address where the program starts
loadLiteral 0 r4        ; r4 is our loop counter

loop_start:
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
    cmove r5 .loop_start r7
    ; After storing all instructions, the instruction pointer (r7) is reset to 1024 to begin execution of the loaded program.

loop_end:
    ; Set user mode and move the pointer back to 1024
    load 4 r0
    load 8 r1
    load 16 r2
    load 20 r3
    load 24 r4
    load 28 r5
    load 32 r6
    load 36 r7
    loadLiteral 1024 r7
    setUserMode

