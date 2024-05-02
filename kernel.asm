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
    read r0     ; Read the first byte into r0
    shl r0 8 r0    ; Shift r0 left by 8 bits
    read r1        ; Read the second byte into r1
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
    read r2
    ; shift 3 places because we read in 1 byte
    shl r2 24 r2
    ; combine
    or r2 r1 r1

    read r2
    ; shift 2 places because we read in 1 byte
    shl r2 16 r2
    ; combine
    or r2 r1 r1

    read r2
    ; shift 1 place because we read in 1 byte
    shl r2 8 r2
    ; combine
    or r2 r1 r1

    ; read the 4th byte
    read r2
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
    store r1 1
    store r2 2
    store r3 3
    store r4 4
    store r5 5

    ; sending memory address to CPU '6' stands for the c.memory[num] on the CPU side
    load 6 r6 
    loadLiteral .trap_reset r5
    ; Check the trap reason and handle (all the checks/ hooks)

    ; if 0, run read 
    eq r5 0 r0
    loadLiteral .read_instruct r3
    cmove r0 r3 r7

    ; if 1, run write
    eq r5 1 r0
    loadLiteral .write_instruct r3
    cmove r0 r3 r7

    ; if 2, then halt
    eq r5 2 r0
    loadLiteral .halt r3
    cmove r0 r3 r7

    ; if 3, timer
    eq r5 3 r0
    loadLiteral .timer_fired r3
    cmove r0 r3 r7
    ; cmove r0 .timer_fired r7

    ; if 4, throw memory out of bounds
    eq r5 4 r0 
    cmove r0 .mem_bounds r7

    ; if 5, throw illegal instruction
    eq r5 5 r0
    cmove r0 .illegal_instruc r7

    eq r5 8 r0
    loadLiteral .timer_fired_num r3
    cmove r0 r3 r7

    ; unreachable syscall
    move r4 r7
    

read_instruct:
    ; allow read 
    read r6
    ; jump to exit
    move r4 r7

write_instruct:
    ; allow read 
    write r6
    ; jump to exit
    move r4 r7

illegal_instruc:
    ; \nIllegal instruction!
    ; \nTimer fired XXXXXXXX times\n
    write 10    ; new line
    write 'I'
    write 'l'
    write 'l'
    write 'e'
    write 'g'
    write 'a'
    write 'l'
    write 32    ; space
    write 'i'
    write 'n'
    write 's'
    write 't'
    write 'r'
    write 'u'
    write 'c'
    write 't'
    write 'i'
    write 'o'
    write 'n'
    write '!'

    ;print number of times a time was fired
    loadLiteral .timer_fired_num r0
    move r0 r7

mem_bounds:
; \nOut of bounds memory access!
; \nTimer fired XXXXXXXX times\n
    write 10    ; new line
    write 'O'
    write 'u'
    write 't'
    write 32    ; space
    write 'o'
    write 'f'
    write 32    ; space
    write 'b'
    write 'o'
    write 'u'
    write 'n'
    write 'd'
    write 's'
    write 32    ; space
    write 'm'
    write 'e'
    write 'm'
    write 'o'
    write 'r'
    write 'y'
    write 32    ; space
    write 'a'
    write 'c'
    write 'c'
    write 'e'
    write 's'
    write 's'
    write '!'

    ; print number of times a time was fired
    loadLiteral .timer_fired_num r0
    move r0 r7

halt:
    ; \nProgram has exited
    ; \nTimer fired XXXXXXXX times\n
    write 10    ; new line
    write 'P'
    write 'r'
    write 'o'
    write 'g'
    write 'r'
    write 'a'
    write 'm'
    write 32
    write 'h'
    write 'a'
    write 's'
    write 32
    write 'e'
    write 'x'
    write 'i'
    write 't'
    write 'e'
    write 'd'

    ;print number of times a time was fired
    loadLiteral .timer_fired_num r0
    move r0 r7

timer_fired:
    ; \nTimer fired\n
    write 10    ; new line
    write 'T'
    write 'i'
    write 'm'
    write 'e'
    write 'r'
    write 32
    write 'f'
    write 'i'
    write 'r'
    write 'e'
    write 'd'
    write 10

    ; jump to reset
    move r5 r7

timer_fired_num:
    ;Timer fired XXXXXXXX times\n
    write 'T'          
    write 'i'
    write 'm'
    write 'e'
    write 'r'
    write 32               ; space
    write 'f'
    write 'i'
    write 'r'
    write 'e'
    write 'd'
    write 32               ; space

    ; load timer from memory
    load 8 r0
    ; Initial shift amount
    loadLiteral 28 r1

timer:
    ; shift right to isolate the next four bits
    shr r0 r1 r2
    and r2 15 r2
    lt r2 10 r3

    ; prep ASCII for digits 0-9
    add r2 48 r4
    ; prep ASCII for 'A'-'F'
    add r2 87 r5

    ; choose correct ASCII value
    cmove r3 r4 r2
    ; If r2 >= 10, move r5 to r2
    cmove r4 r5 r2
    ; write ASCII character
    write r2

    ; Decrement the shift amount by 4
    sub r1 4 r1
    ; Check if r1 > 0 (continue loop if true)
    gt r1 0 r6

    ; move non-zero r1 into r7 as a new shift amount
    cmove r6 r1 r7
    ; restore r1 from r7 if r6 is true (continue loop)
    cmove r6 r7 r1
    ; repeat timerLoop if r6 is true
    ; WHAT DO I USE HERE?!?!? RIP
    ; cmove r6 .timer r7

finishTimerCount:
    write 32               ; space
    write 't'
    write 'i'
    write 'm'
    write 'e'
    write 's'
    write 10               ; new line
    halt                   ; exit

trap_reset:
    ; sent trap handler address
    setTrapAddr .trap_handler_store

    ; Reset registers
    load 0 r0
    load 4 r1
    load 8 r2
    load 16 r3
    load 20 r4
    load 24 r5

    ; set back to user mode
    setUserMode
