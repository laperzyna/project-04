; bootloader fetches instruction words based on how many instructions are in the program
; similar to how we read in a literal in the prime example, will be doing the same for instruction words
; main tasks
; - fetch instructions
; - save instructions
; - when out of instructions, move iptr back to start (1024)
; - start executing?

; QUESTIONS?
; - if we have direct contact with the emulator and it has the 16-bit int that is the total num of instructions in the program, could we just loop the total number that we have recieved?
;       - yes.
; - is there a done instruction? how do we know when the program is finished? null pointer?
;       - 'move r3 r7' --> done. jumping to execute


;Read in program length, two bytes and can only read one at a time


;r0 is the program length
;r1 for the instruction word (whole thing)
;r2 for the instruction word (the next byte we gather)
;r3 is the memory address
;r4 loop counter
;r5 
;r7 is the instruction pointer

start: 
    ; Read the program length
    read r0        ; Read the first byte into r0
    shl r0 8 r0    ; Shift r0 left by 8 bits
    read r1        ; Read the second byte into r1
    or r0 r1 r0    ; Combine r0 and r1 using OR operation, store in r2

; debug r0

; Initialize loop counter and memory address
loadLiteral 1024 r3     ; r3 is the memory address where the program starts
loadLiteral 0 r4        ; r4 is our loop counter
; debug r0

loop_start:
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
    cmove r5 .loop_start r7

loop_end:
    ; Move the pointer back to 1024
    loadLiteral 1024 r7

