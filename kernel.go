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

	// checks for mem out of bounds
	// timer fired --> instruction hook instead?
	// mode
	// prevent priviledges
	// validation --> both?
	// BASE OF SECURITY - LOTS OF CHECKS

	// check timer
	if !k.Mode {
		k.Timer++
		if k.Timer >= k.InstructsTimeSlice {
			k.Timer = 0
			fmt.Println("\nTimer fired!")
			k.TimerFired++
			c.registers[7] = k.TrapHandlerAddr
			k.Mode = true
			return true, nil
		}
	}

	// example mode check and rejecting execution
	// if !k.Mode && c.CurrentInstruction.IsPriviledge() {
	// 	return false, fmt.Errorf("illegal instruction in user mode")
	// }
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
			if addr < 1024 || addr > 2048 {
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
			if addr < 1024 || addr > 2048 {
				return true, nil
			}
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
			cb: func(c *cpu, args [3]byte) error {
				fmt.Println("\nentered syscall: ", int(args[0]&0x7F))

				// switch case for syscall number provided in args[0]
				switch int(args[0] & 0x7F) {
				case 0: // Read
					var buf [1]byte
					_, err := c.read.Read(buf[:])
					if err != nil {
						return fmt.Errorf("failed to read from input device: %v", err)
					}
					c.registers[6] = word(buf[0])
					return nil

				case 1: // Write
					b := byte(c.registers[6] & 0xFF)
					_, err := c.write.Write([]byte{b})
					if err != nil {
						return fmt.Errorf("failed to write to output device: %v", err)
					}
					return nil

				case 2: // Exit
					fmt.Printf("\nProgram has exited\nTimer fired %d times\n", c.kernel.TimerFired)
					c.halted = true
					return nil

				default:
					return fmt.Errorf("unknown syscall number: %d", args[0])
				}

			},
			validate: nil,
		}

		// Sets the kernel to user mode
		instrSetUserMode = &instr{
			name: "setUserMode",
			cb: func(c *cpu, args [3]uint8) error {
				c.kernel.Mode = false
				return nil
			},
			validate: nil,
		}

		// TODO: Make an instruction to get and set the trap handler state
		// instrTrapState = &instr{
		// 	name: "trap_state",
		// 	cb: func(c *cpu, args [3]byte) error {
		// 		syscall := int(args[0] & 0x7F)
		// 		switch syscall {
		// 		case 3: // Get trap
		// 			c.registers[7] = word(c.trapHandler.getState())
		// 			return nil

		// 		case 4: // Set trap
		// 			c.trapHandler.setState(c.registers[7])
		// 			return nil

		// 		default:
		// 			return fmt.Errorf("unknown trap handler syscall number: %d", syscall)
		// 		}
		// 	},
		// 	validate: nil, // Assuming no special validation needed for trap state instructions
		// }
	)

	// Add kernel instructions to the instruction set.
	// TODO: add any other instructions
	instructionSet.add(instrSyscall)
	instructionSet.add((instrSetUserMode))
	//instructionSet.add(instrTrapState)
}
