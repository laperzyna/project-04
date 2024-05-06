
; The kernel.asm file mainly focuses on handling system calls
; and traps. It interactes directly with the CPU emulator, kernel.go. 
; The core functionalities include loading in the program or instructions,trap handling, and responses to various system events.

; 1. Overview

; Our kernel implementation is designed to handle system traps by interacting with our CPU emulator and being told when to execute. However, based on our CPU emulator implementation, our kernel is fired regularly after every illegal request, syscall, or timer fired. Our kernel is responsible for managing the CPU state, memory, and other system-level functions.


; 2. Syscall Handling

; System calls are extremely important for user programs to interact with the operating system. Our kernel utilizes a comprehensive set of handlers that interpret syscall and respond with appropriate actions. Each syscall has a unique identifier, and the kernel uses this identifier to execute the appropriate response.

 
; 3. Trap Handling

; Our kernel also utilizes a trap handling routine that captures and categorizes traps based on their origin and type. The kernel then decides the appropriate response for each type of trap, whether it is a syscall, timer fired event, or a memory fault. The handler also ensures that all system state changes are safely stored and restored, allowing for consistent system behavior.

; 4. Program Loading and Execution

; A simple loader is implemented that utilizes previous code from our bootloader.asm file to read executable instructions into memory. Our loader establishes the length of the program, reads in the program instructions, and sets the instruction pointer to the start of the program. 

; Lidia Perzyna & Isaac Meltsner (Intro to Security USFCA-2024)

start: 
    ; sent trap handler address
    setTrapAddr .trap_handler_store
    ; Read the program length
    read r0     ; Read the first byte into r0
    shl r0 8 r0    ; Shift r0 left by 8 bits
    read r1        ; Read the second byte into r1
    or r0 r1 r0    ; Combine r0 and r1 using OR operation

    ; Initialize loop counter and memory address
    loadLiteral 1024 r2     ; r2 is the memory address where the program starts
    loadLiteral 0 r3        ; r3 is our loop counter

instruc_loadin:
    ; Read and assemble ans instruction word

    ; clear r4 for new word
    loadLiteral 0 r4
    ; read in the 1st byte
    read r1
    ; shift 3 places because we read in 1 byte
    shl r1 24 r1
    ; combine
    or r4 r1 r4

    read r1
    ; shift 2 places because we read in 1 byte
    shl r1 16 r1
    ; combine
    or r4 r1 r4

    read r1
    ; shift 1 place because we read in 1 byte
    shl r1 8 r1
    ; combine
    or r4 r1 r4

    ; read the 4th byte
    read r1
    or r4 r1 r4

    ; we have the word (a line of code), so store it in memory
    ; store the instruction word in memory
    store r4 r2

    ; Increment counter and memory address
    ; Increment loop counter
    add r2 1 r2
    ; Increment memory address
    add r3 1 r3

    ; Compare loop counter with program length
    ; Compare counter (r3) with length (r0), result in r4
    lt r3 r0 r4
    ; If the loop counter is less than program length, then we have more instructions to write, jump to .instruc_loadin
    cmove r4 .instruc_loadin r7
    ; move the pointer back to 1024
    loadLiteral 1024 r7


trap_handler_store:
    ; store all registers at a location in memory
    store r0 0
    store r1 1
    store r2 2
    store r3 3
    store r4 4
    store r5 5

    ; sending memory address to CPU '6' stands for the c.memory[num] on the CPU side
    load 6 r5
    ; prep the address to jump to after handling the trap
    loadLiteral .trap_reset r4

    ; Check the trap reason and handle (all the checks/ hooks)
    ; if 0, run read 
    eq r5 0 r0
    loadLiteral .read_instruct r3
    ; jump to read handler if trap reason is 0
    cmove r0 r3 r7

    ; if 1, run write
    eq r5 1 r0
    loadLiteral .write_instruct r3
    ; jump to write handler if trap reason is 1
    cmove r0 r3 r7

    ; if 2, then halt
    eq r5 2 r0
    loadLiteral .halt r3
    ; jump to halt routine if trap reason is 2
    cmove r0 r3 r7

    ; if 3, timer
    eq r5 3 r0
    loadLiteral .timer_fired r3
    ; jump to timer fired routine if trap reason is 3
    cmove r0 r3 r7

    ; if 4, throw memory out of bounds
    eq r5 4 r0 
    ; jump to memory bounds error routine if trap reason is 4
    cmove r0 .mem_bounds r7

    ; if 5, throw illegal instruction
    eq r5 5 r0
    ; jump to illegal instruction routine if trap reason is 5
    cmove r0 .illegal_instruc r7

    eq r5 8 r0
    loadLiteral .timer_fired_num r3
    ; special handling for a specific case trap reason 8
    cmove r0 r3 r7

    ; unreachable syscall
    move r4 r7
    
; handle a read request from the trap
read_instruct:
    ; allow read 
    read r6
    ; jump to exit
    move r4 r7

; handle a write request from the trap
write_instruct:
    ; allow read 
    write r6
    ; jump to exit
    move r4 r7

; handle illegal instruction trap
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

; handle memory out of bounds access
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

; handle a halt trap
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

; handle timer fired trap
timer_fired:
    ; \nTimer fired!\n
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
    write '!'
    write 10

    ; jump to reset
    move r4 r7

; begin printing the number of times the timer fired
timer_fired_num:
   ; \nTimer fired XXXXXX times\n
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
	write 32

    ; load the number of timer fires from a memory location (index 8) into r0
	load 8 r0
    ; load the initial bit shift value (28) into r1
	loadLiteral 28 r1


; enter the timer_loop to convert a timer value to hexadecimal. 
; utilizes bitwise operations (shr, and) to extract and manipulate 4-bit hexadecimal digits
timer_loop:
	shr r0 r1 r2
	and r2 15 r2
	lt r2 10 r3	

	loadLiteral .hex r5
	cmove r3 r5 r7
	add r2 87 r2

; manage loop 
; if there are more digits to check then loop through again if not move to continue
loop_again:
    ; write the current hex digit stored in r2
    write r2
    ; subtract 4 from the shift amount in r1 for the next hex digit
    sub r1 4 r1

    ; check if all hex digits have been processed (when shift amount reaches 0)
    eq r1 0 r3
    ; load address of 'timer_two' section into r5 for handling the last digit
    loadLiteral .timer_two r5
    ; conditional move: if all digits processed, move to process the last digit
    cmove r3 r5 r7
    ; otherwise, repeat the loop
    loadLiteral .timer_loop r5
    move r5 r7

; adjust the ASCII value to show the actual hexadecimal digit
hex:
    ; ddd 48 to r2 to adjust ASCII value for numeric digits (0-9)
    add r2 48 r2
    ; jump back to 'loop_again' to continue processing
    loadLiteral .loop_again r5
    move r5 r7

; conversion to hex
timer_two:
	; isolate the last hex digit from r0
    and r0 15 r2
    ; check if it is a numeric digit
    lt r2 10 r3

    ; prepare to handle numeric or alphabetic hex digit
    loadLiteral .next_hex r5
    cmove r3 r5 r7
    ; adjust for alphabetic digit (a-f)
    add r2 87 r2
    ; prepare to finish displaying timer value
    loadLiteral .timer_finish r5
    move r5 r7

; finish conversion
next_hex:
    ; adjust ASCII for numeric digit
	add r2 48 r2

; finish up timer - print number "times" and halt
timer_finish:
    ; write the final digit
	write r2				
	write 32
	write 't'
	write 'i'
	write 'm'
	write 'e'
	write 's'
	write 10
    ; halt the program
	halt

; reset registers and reset the instruction pointer and set the mode back to user
trap_reset:
    ; Reset registers
    load 0 r0
    load 1 r1
    load 2 r2
    load 3 r3
    load 4 r4
    load 5 r5

    setIptr 7
    ; set back to user mode
    setUserMode


