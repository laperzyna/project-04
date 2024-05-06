/*
Purpose: The goal of this project is to implement CPU support for a kernel.
The CPU initializes the state of the kernel.
- Mode: The Mode is true if programs are executing in kernel mode and false if they are executing in user mode
- TrapHandlerAddr: Sets the memory address where the kernel will go after a timer fires or an illegal instruction loaded
- Timer: Keeps track of how many instructions have executed in a cycle
- TimerFired: Keeps track of how many times the timer has fired
- InstructsTimeSlice: Determines how many instructions can execute per cycle

Trap Handler: The CPU has a function to handle kernel traps. This function
takes a number that specifies which type of trap occured. It stores this number in cpu memory. The function also
stores the value of the current iptr and the number of times the timer has fired.
- 0-2: This corresponds to a syscall. 0 is for reads, 1 is for writes, and 2 is for halts.
- 3: Trap number 3 indicates that a timer has fired.
- 4: Trap number 4 indicates a memory out of bounds error
- 5: Trap number 5 indicates an illegal instruction was executed

New Instructions: We added 3 new instructions to support kernel operations
- setUserMode: This instruction changes the mode of the CPU from kernel mode to user mode
- setIptr: This instruction puts the last saved iptr address stored in cpu memory into the iptr register.
It then sets the cpu back to user mode.
- setTrapAddress: This instruction sets the address where the kernel will start executing after a trap

Pre execute hook: The pre execute hook executes before each instruction. If the kernel is in user mode, it increments the timer,
and checks to see whether or not the timer has exceeded the allowed number of instructions. If it has, it calls the trap handler
function with code 3.

Instruction hooks: Certain instructions require special rules regarding their execution
- Load/Store: In user mdoe, these instructions can only load and store from within the memory allocated to user space.
If a user land program attempts to access memory outside of this range, the trap handler is called with error code 4.
- Read/Write/Halt/Unreachable: These instructions are only allowed to be executed in kernel mode. If a user land program
attempts to use them, the kernal trap is invoked with error code 5.
- setIptr/setTrapAddress/setUserMode: These instructions are only allowed to be executed in kernel mode. If a user land program
attempts to use them, the kernal trap is invoked with error code 5.
*/

package main

import "fmt"

// ************* Kernel support *************
//
// All of your CPU emulator changes for Assignment 2 will go in this file.

// The state kept by the CPU in order to implement kernel support.
type kernelCpuState struct {
	// mode flag: for current mode
	// false for user, true for kernel
	Mode bool
	// memory address where CPU jumps for trap
	TrapHandlerAddr word
	// // timer to keep track of instructions and manage time slices
	Timer uint32
	// how many times the timers has fired
	TimerFired uint32
	// instructions per time slice
	InstructsTimeSlice uint32
}

// The initial kernel state when the CPU boots.
var initKernelCpuState = kernelCpuState{
	// start in kernel mode
	Mode: true,
	// address to be filled in with current address
	TrapHandlerAddr: word(0),
	Timer:           0,
	// print once finished with hex encoding the number
	// the last line of output to the output device must be Timer fired XXXXXXXX times\n, where XXXXXXXX is the hex encoding of the number of times that the timer has fired during the program execution. (from spec)
	TimerFired: 0,
	// standard slice length
	InstructsTimeSlice: 128,
}

// Saves iptr
// Determines sets which kind of trap occured
// 0 - syscall 0
// 1 - syscall 1
// 2 - syscall 2
// 3 - timer exceeded
// 4 - memory out of bounds
// 5 - illegal instruction
func trapHandler(c *cpu, trapVal word) {
	c.memory[6] = trapVal
	c.memory[7] = c.registers[7]
	c.memory[8] = word(c.kernel.TimerFired)
	c.kernel.Mode = true
	c.registers[7] = c.kernel.TrapHandlerAddr
}

// A hook which is executed at the beginning of each instruction step.
//
// This permits the kernel support subsystem to perform extra validation that is
// not part of the core CPU emulator functionality.
//
// If `preExecuteHook` returns an error, the CPU is considered to have entered
// an illegal state, and it halts.
//
// If `preExecuteHook` returns `true`, the instruction is "skipped": `cpu.step`
// will immediately return without any further execution.
func (k *kernelCpuState) preExecuteHook(c *cpu) (bool, error) {

	// check if no trap then increment timer
	if !c.kernel.Mode {
		k.Timer++
	}

	// if the timer has gone over the allowed time fire the trap
	if k.Timer > k.InstructsTimeSlice {
		trapHandler(c, 3)
		k.TimerFired++
		k.Timer = 0
		return true, nil
	}

	return false, nil
}

// Initialize kernel support.
//
// (In Go, any function named `init` automatically runs before `main`.)
func init() {
	if false {
		// This is an example of adding a hook to an instruction. You probably
		// don't actually want to add a hook to the `add` instruction.
		instrAdd.addHook(func(c *cpu, args [3]uint8) (bool, error) {
			if args[2] == 7 {
				return false, fmt.Errorf("You're not allowed to ever change the instruction pointer. No loops for you!")
			}

			return false, nil
		})
	}

	// Instruction hook for load to prevent loading from kernel memory
	instrLoad.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			a0 := resolveArg(c, args[0])
			addr := int(a0)
			if addr < 1024 || addr >= 2048 {
				trapHandler(c, 4)
				return true, nil
			}
		}

		return false, nil
	})

	// Instruction hook for store to prevent storing into kernel memory
	instrStore.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			a1 := resolveArg(c, args[1])
			addr := int(a1)
			if addr < 1024 || addr >= 2048 {
				trapHandler(c, 4)
				return true, nil
			}
		}

		return false, nil
	})

	// Prevent user mode from executing privledged instruction
	instrRead.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			trapHandler(c, 5)
			return true, nil
		}

		return false, nil
	})

	// Prevent user mode from executing privledged instruction
	instrWrite.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			trapHandler(c, 5)
			return true, nil
		}

		return false, nil
	})

	// Prevent user mode from executing privledged instruction
	instrHalt.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			trapHandler(c, 5)
			return true, nil
		}

		return false, nil
	})

	// Prevent user mode from executing privledged instruction
	instrUnreachable.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			trapHandler(c, 5)
			return true, nil
		}

		return false, nil
	})

	var (
		// syscall <code>
		//
		// Executes a syscall. The first argument is a literal which identifies
		// what kernel functionality is requested:
		// - 0/read:  Read a byte from the input device and store it in the
		//            lowest byte of r6 (and set the other bytes of r6 to 0)
		// - 1/write: Write the lowest byte of r6 to the output device
		// - 2/exit:  The program exits; print "Program has exited" and halt the
		// 	 		  machine.
		//
		// You may add new syscall codes if you want, but you may not modify
		// these existing codes, as `prime.asm` assumes that they are supported.
		instrSyscall = &instr{
			name: "syscall",
			cb: func(c *cpu, args [3]uint8) error {
				syscall := int(args[0] & 0x7F)

				if syscall > 2 || syscall < 0 {
					return fmt.Errorf("Invalid syscall: %d\n", syscall)
				}

				trapHandler(c, word(syscall))
				return nil

			},
			validate: genValidate(regOrLit, ignore, ignore),
		}

		// Sets the kernel to user mode
		instrSetUserMode = &instr{
			name: "setUserMode",
			cb: func(c *cpu, args [3]uint8) error {
				c.kernel.Mode = false
				return nil
			},
			validate: genValidate(ignore, ignore, ignore),
		}

		// gets trap handler address for trap
		instrSetTrapAddress = &instr{
			name: "setTrapAddr",
			cb: func(c *cpu, args [3]uint8) error {
				a0 := resolveArg(c, args[0])
				c.kernel.TrapHandlerAddr = a0
				return nil
			},
			validate: genValidate(regOrLit, ignore, ignore),
		}

		// resets the instruction pointer
		instrSetIptr = &instr{
			name: "setIptr",
			cb: func(c *cpu, args [3]uint8) error {
				addr := int(args[0] & 0x7F)
				c.registers[7] = c.memory[addr]
				c.kernel.Mode = false
				return nil
			},
			validate: genValidate(regOrLit, ignore, ignore),
		}
	)

	// Prevent user mode from executing privledged instruction
	instrSetUserMode.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			trapHandler(c, 5)
			return true, nil
		}

		return false, nil
	})

	// Prevent user mode from executing privledged instruction
	instrSetTrapAddress.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			trapHandler(c, 5)
			return true, nil
		}

		return false, nil
	})

	// Prevent user mode from executing privledged instruction
	instrSetIptr.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			trapHandler(c, 5)
			return true, nil
		}

		return false, nil
	})

	// Add kernel instructions to the instruction set.
	instructionSet.add(instrSyscall)
	instructionSet.add((instrSetUserMode))
	instructionSet.add((instrSetTrapAddress))
	instructionSet.add((instrSetIptr))
}
