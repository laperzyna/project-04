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
	TrapHandlerAddr uint32
	// timer to keep track of instructions and manage time slices
	Timer uint32
	// how many times the timers has fired
	TimerFired uint32
	// instructions per time slice
	// dont know if need to implement this?
	InstructsTimeSlice uint32
}

// The initial kernel state when the CPU boots.
var initKernelCpuState = kernelCpuState{
	// start in user mode
	Mode: false,
	// TODO: address to be filled in with current address
	TrapHandlerAddr: 0x1000,
	Timer:           0,
	TimerFired:      0,
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
	// check timer
	k.Timer++
	if k.Timer >= k.InstructsTimeSlice {
		k.Timer = 0
		k.TimerFired++
		fmt.Println("\nTimer fired!")
		// init trap handler here?
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
				// TODO: Fill this in.
				return fmt.Errorf("unimplemented")
			},
			validate: nil,
		}

		// TODO: Add other instructions that can be used to implement a kernel.
	)

	// Add kernel instructions to the instruction set.
	instructionSet.add(instrSyscall)
}
