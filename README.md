# MIPS-multi-cycle

MIPS multi-cycle Verilog implementation based on *Computer Organization and Design* by David A. Patterson and John L. Hennessy (Chapter 5.5 — multicycle implementation).

## Overview

The processor uses a single unified memory for both instructions and data. Memory is organized as 256 words of 32 bits. The program counter starts at **PC_START = 128** (`0x80`).

### Standard MIPS instructions

| Instruction | Cycles |
|-------------|--------|
| `beq` | 3 |
| R-type (`add`, `sub`, `and`, `or`, `slt`, `mul`) | 4 |
| `sw` | 4 |
| `lw` | 5 |

### Custom extensions

| Instruction | Opcode | Description | Cycles |
|-------------|--------|-------------|--------|
| `loadi rt, imm` | `0x1F` | Load immediate into register | 3 |
| `addi3 rt, rs, rd, imm` | `0x1E` | `rt = rs + rd + imm` | 3 |
| `swap rs, rt` | `0x1D` | Swap two registers | 3 |
| `bgt rs, rt, label` | `0x1B` | Branch if `rs > rt` (signed) | 3 |
| `push rt` | `0x1A` | Push register onto stack | 4 |
| `pop rt` | `0x19` | Pop from stack into register | 5 |

`mul` is encoded as a standard R-type instruction with funct `0x1C`.

## Project structure

| File | Description |
|------|-------------|
| `mips.v` | Top-level module |
| `control.v` | FSM control unit |
| `datapath.v` | Datapath (PC, registers, memory, ALU) |
| `alucontrol.v` | ALU control decoder |
| `tb_mips.v` | Simulation testbench |
| `assembler.py` | Assembly → `mem.dat` converter |
| `test.asm` | Test program for the testbench |
| `mem.dat` | Memory image loaded at simulation |

## Building and simulating

### 1. Assemble a program

```bash
python assembler.py test.asm mem.dat
```

Instruction memory must start at address 128. The provided `mem.dat` uses `@80` (hex) as the load offset.

### 2. Run in ModelSim

```bash
vlib work
vlog mips.v control.v datapath.v alucontrol.v tb_mips.v
vsim -c tb_mips -do "run -all; quit"
```

> **Note:** Avoid project paths with non-ASCII characters (e.g. Turkish locale folder names); ModelSim may fail to create the work library otherwise.

## Test program

`test.asm` exercises all custom instructions:

```
loadi $sp, 200
loadi $t0, 10
loadi $t1, 20
addi3 $t2, $t0, $t1, 5    # t2 = 35
swap  $t0, $t1            # t0 = 20, t1 = 10
mul   $t3, $t0, $t1       # t3 = 200
push  $t3
pop   $t4
bgt   $t0, $t1, target    # branch taken
loadi $t5, 99             # skipped
target:
loadi $t6, 100
```

Expected results: R29=200, R10=35, R8=20, R9=10, R11=200, mem[200]=200, R12=200, R14=100.

## Example program (sum of data memory values)

The original demo program sums the first 16 values from data memory. The result (5) is stored at memory address 76:

```
add $t0, $zero, $zero
add $t6, $zero, $zero
lw $t1, 64($t0)
...
beq $t1, $t1, loop
done:
```

## Tools

- **ModelSim** — simulation (Intel FPGA Edition / student edition)
- **QtSpim** — reference for instruction encoding
