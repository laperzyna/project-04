; bootloader fetches instruction words based on how many instructions are in the program
; similar to how we read in a literal in the prime example, will be doing the same for instruction words
; main tasks
; - fetch instructions
; - save instructions
; - when out of instructions, move iptr back to start (1024)
; - start executing?

; QUESTIONS?
; - if we have direct contact with the emulator and it has the 16-bit int that is the total num of instructions in the program, could we just loop the total number that we have recieved?
; - is there a done instruction? how do we know when the program is finished? null pointer?
;       - 'move r3 r7' --> done. jumping to execute


; r0
; r1
; r2
; r3
; r4
; r7

; BEGINNING IMPLEMENTATION

loadLiteral 1024 r0
read r3

read r1               ; Read the high-order byte
loadLiteral 256 r3    ; Value to multiply by to shift left 8 bits
mul r1 r3 r1          ; Effectively shift left 8 bits
read r3               ; Read the low-order byte
add r1 r3 r1 

; PSUEDOCODE

; ; Initialize registers for addresses and counters
; loadLiteral 0 r1     ; Counter for bytes read
; loadLiteral 0 r2     ; Program length in words

; ; ; Read program length (assuming it's 2 bytes)
; read r1               ; Read the high-order byte
; loadLiteral 256 r3    ; Value to multiply by to shift left 8 bits
; mul r1 r3 r1          ; Effectively shift left 8 bits
; read r3               ; Read the low-order byte
; add r1 r3 r1 
; Combine the two bytes into the length (assuming r3<<8 + r4)
; Since we don't have shift instructions, we need to assume or manually handle this

; Read and store the program into memory
; loadLiteral 1024 r0  ; Memory address to start storing program
; read_loop:
;     lt r2 r1 r4      ; Compare read counter with length
;     cmove r4 .end_read_program r7  ; If counter equals length, prepare to jump to end

;     read r3          ; Read a byte from the input device
;     load r3 r0      ; Store the byte in memory at address in r0
;     add r0 1 r0      ; Increment memory address
;     add r2 1 r2      ; Increment byte counter
;     loadLiteral .read_loop r5  ; Prepare next loop iteration
;     cmove r2 r5 r7   ; Continue loop

; end_read_program:
; loadLiteral 1024 r7  ; Set instruction pointer to start of program
