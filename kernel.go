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
	// dont know if need to implement this?
	TimerFired uint32
	// instructions per time slice
	// dont know if need to implement this?
	InstructsTimeSlice uint32
}

// The initial kernel state when the CPU boots.
var initKernelCpuState = kernelCpuState{
	// start in kernel mode
	Mode: true,
	// TODO: address to be filled in with current address
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
func kernelTrap(c *cpu, trapVal word) {
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
	if !c.kernel.Mode {
		k.Timer++
	}

	if k.Timer >= k.InstructsTimeSlice {
		k.Timer = 0
		k.TimerFired++
		kernelTrap(c, 3)
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
			a0 := resolveArg(c, args[0])
			a1 := resolveArg(c, args[1])
			if a0 == a1 {
				// Adding a number to itself? That seems like a weird thing to
				// do. Best just to skip it...
				return true, nil
			}

			if args[2] == 7 {
				// This instruction is trying to write to the instruction
				// pointer. That sounds dangerous!
				return false, fmt.Errorf("You're not allowed to ever change the instruction pointer. No loops for you!")
			}

			return false, nil
		})
	}

	// TODO: Add hooks to other existing instructions to implement kernel
	// support.
	// Instruction hook for load to prevent loading from kernel memory
	instrLoad.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			a0 := resolveArg(c, args[0])
			addr := int(a0)
			if addr < 1024 || addr >= 2048 {
				kernelTrap(c, 4)
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
				kernelTrap(c, 4)
				return true, nil
			}
		}

		return false, nil
	})

	// Prevent user mode from executing privledged instruction
	instrRead.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			kernelTrap(c, 5)
			return true, nil
		}

		return false, nil
	})

	// Prevent user mode from executing privledged instruction
	instrWrite.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			kernelTrap(c, 5)
			return true, nil
		}

		return false, nil
	})

	// Prevent user mode from executing privledged instruction
	instrHalt.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			kernelTrap(c, 5)
			return true, nil
		}

		return false, nil
	})

	// Prevent user mode from executing privledged instruction
	instrUnreachable.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			kernelTrap(c, 5)
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

				kernelTrap(c, word(syscall))
				return nil

				// switch case for syscall number provided in args[0]
				// switch int(args[0] & 0x7F) {
				// case 0: // Read
				// 	var buf [1]byte
				// 	_, err := c.read.Read(buf[:])
				// 	if err != nil {
				// 		return fmt.Errorf("failed to read from input device: %v", err)
				// 	}
				// 	c.registers[6] = word(buf[0])
				// 	return nil

				// case 1: // Write
				// 	b := byte(c.registers[6] & 0xFF)
				// 	_, err := c.write.Write([]byte{b})
				// 	if err != nil {
				// 		return fmt.Errorf("failed to write to output device: %v", err)
				// 	}
				// 	return nil

				// case 2: // Exit
				// 	fmt.Printf("\nProgram has exited\nTimer fired %d times\n", c.kernel.TimerFired)
				// 	c.halted = true
				// 	return nil

				// default:
				// 	return fmt.Errorf("unknown syscall number: %d", args[0])
				// }

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

		instrSetTrapAddress = &instr{
			name: "setTrapAddr",
			cb: func(c *cpu, args [3]uint8) error {
				a0 := resolveArg(c, args[0])
				c.kernel.TrapHandlerAddr = a0
				return nil
			},
			validate: genValidate(regOrLit, ignore, ignore),
		}

		instrSetIptr = &instr{
			name: "setIptr",
			cb: func(c *cpu, args [3]uint8) error {
				c.registers[7] = c.memory[7]
				c.kernel.Mode = false
				return nil
			},
			validate: genValidate(ignore, ignore, ignore),
		}
	)

	// Prevent user mode from executing privledged instruction
	instrSetUserMode.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			kernelTrap(c, 5)
			return true, nil
		}

		return false, nil
	})

	// Prevent user mode from executing privledged instruction
	instrSetTrapAddress.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			kernelTrap(c, 5)
			return true, nil
		}

		return false, nil
	})

	// Prevent user mode from executing privledged instruction
	instrSetIptr.addHook(func(c *cpu, args [3]uint8) (bool, error) {
		if !c.kernel.Mode {
			kernelTrap(c, 5)
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
