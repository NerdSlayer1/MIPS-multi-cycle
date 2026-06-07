import sys
import re

R_FUNCTS = {
    "add": 0x20,
    "sub": 0x22,
    "and": 0x24,
    "or": 0x25,
    "xor": 0x26,
    "slt": 0x2A,
    "mul": 0x1C,
}

I_OPCODES = {
    "addi": 0x08,
    "slti": 0x0A,
    "andi": 0x0C,
    "ori": 0x0D,
    "lw": 0x23,
    "sw": 0x2B,
    "beq": 0x04,
    "bne": 0x05,
    "loadi": 0x1F,
    "addi3": 0x1E,
    "swap": 0x1D,
    "bgt": 0x1B,
    "push": 0x1A,
    "pop": 0x19,
}

J_OPCODES = {
    "j": 0x02,
}

REGISTERS = {
    "$zero": 0, "$0": 0,
    "$at": 1,
    "$v0": 2, "$v1": 3,
    "$a0": 4, "$a1": 5, "$a2": 6, "$a3": 7,
    "$t0": 8, "$t1": 9, "$t2": 10, "$t3": 11,
    "$t4": 12, "$t5": 13, "$t6": 14, "$t7": 15,
    "$s0": 16, "$s1": 17, "$s2": 18, "$s3": 19,
    "$s4": 20, "$s5": 21, "$s6": 22, "$s7": 23,
    "$t8": 24, "$t9": 25,
    "$k0": 26, "$k1": 27,
    "$gp": 28, "$sp": 29, "$fp": 30, "$ra": 31,
}

def clean_line(line):
    line = line.split("#")[0]
    line = line.split("//")[0]
    return line.strip()

def parse_reg(reg):
    reg = reg.strip().lower()
    if reg not in REGISTERS:
        raise ValueError(f"Geçersiz register: {reg}")
    return REGISTERS[reg]

def parse_imm(value):
    value = value.strip()
    return int(value, 0)

def split_args(text):
    return [x.strip() for x in text.split(",") if x.strip()]

def encode_r(rs, rt, rd, shamt, funct):
    return (0 << 26) | (rs << 21) | (rt << 16) | (rd << 11) | (shamt << 6) | funct

def encode_i(opcode, rs, rt, imm):
    return (opcode << 26) | (rs << 21) | (rt << 16) | (imm & 0xFFFF)

def encode_j(opcode, address):
    return (opcode << 26) | (address & 0x03FFFFFF)

def parse_mem(arg):
    match = re.match(r"(-?(?:0x[0-9a-fA-F]+|\d+))\((\$[a-zA-Z0-9]+)\)", arg.replace(" ", ""))
    if not match:
        raise ValueError(f"Geçersiz memory formatı: {arg}")
    offset = parse_imm(match.group(1))
    base = parse_reg(match.group(2))
    return offset, base

def first_pass(lines):
    labels = {}
    instructions = []
    pc = 0

    for raw in lines:
        line = clean_line(raw)
        if not line:
            continue

        while ":" in line:
            label, rest = line.split(":", 1)
            label = label.strip()
            if not label:
                raise ValueError("Boş label bulundu")
            labels[label] = pc
            line = rest.strip()

        if line:
            instructions.append(line)
            pc += 1

    return labels, instructions

def assemble_instruction(line, labels, pc):
    parts = line.replace("\t", " ").split(None, 1)
    op = parts[0].lower()
    args = split_args(parts[1]) if len(parts) > 1 else []

    if op in ["add", "sub", "and", "or", "xor", "slt"]:
        if len(args) != 3:
            raise ValueError(f"{op} için format: {op} rd, rs, rt")
        rd = parse_reg(args[0])
        rs = parse_reg(args[1])
        rt = parse_reg(args[2])
        return encode_r(rs, rt, rd, 0, R_FUNCTS[op])

    if op == "mul":
        if len(args) != 3:
            raise ValueError("mul için format: mul rd, rs, rt")
        rd = parse_reg(args[0])
        rs = parse_reg(args[1])
        rt = parse_reg(args[2])
        return encode_r(rs, rt, rd, 0, R_FUNCTS[op])

    if op == "swap":
        if len(args) != 2:
            raise ValueError("swap için format: swap rs, rt")
        rs = parse_reg(args[0])
        rt = parse_reg(args[1])
        return encode_i(I_OPCODES[op], rs, rt, 0)

    if op in ["addi", "slti", "andi", "ori"]:
        if len(args) != 3:
            raise ValueError(f"{op} için format: {op} rt, rs, imm")
        rt = parse_reg(args[0])
        rs = parse_reg(args[1])
        imm = parse_imm(args[2])
        return encode_i(I_OPCODES[op], rs, rt, imm)

    if op == "loadi":
        if len(args) != 2:
            raise ValueError("loadi için format: loadi rt, imm")
        rt = parse_reg(args[0])
        imm = parse_imm(args[1])
        return encode_i(I_OPCODES[op], 0, rt, imm)

    if op == "addi3":
        if len(args) != 4:
            raise ValueError("addi3 için format: addi3 rt, rs, rd, imm")
        rt = parse_reg(args[0])
        rs = parse_reg(args[1])
        rd = parse_reg(args[2])
        imm = parse_imm(args[3]) & 0x7FF
        return (I_OPCODES[op] << 26) | (rs << 21) | (rt << 16) | (rd << 11) | imm

    if op in ["lw", "sw"]:
        if len(args) != 2:
            raise ValueError(f"{op} için format: {op} rt, offset(rs)")
        rt = parse_reg(args[0])
        offset, rs = parse_mem(args[1])
        return encode_i(I_OPCODES[op], rs, rt, offset)

    if op in ["beq", "bne", "bgt"]:
        if len(args) != 3:
            raise ValueError(f"{op} için format: {op} rs, rt, label")
        rs = parse_reg(args[0])
        rt = parse_reg(args[1])
        label = args[2]
        if label not in labels:
            raise ValueError(f"Label bulunamadı: {label}")
        offset = labels[label] - (pc + 1)
        return encode_i(I_OPCODES[op], rs, rt, offset)

    if op == "j":
        if len(args) != 1:
            raise ValueError("j için format: j label")
        label = args[0]
        if label not in labels:
            raise ValueError(f"Label bulunamadı: {label}")
        return encode_j(J_OPCODES[op], labels[label])

    if op == "push":
        if len(args) != 1:
            raise ValueError("push için format: push rt")
        rt = parse_reg(args[0])
        return encode_i(I_OPCODES[op], 29, rt, 0)

    if op == "pop":
        if len(args) != 1:
            raise ValueError("pop için format: pop rt")
        rt = parse_reg(args[0])
        return encode_i(I_OPCODES[op], 29, rt, 0)

    raise ValueError(f"Bilinmeyen komut: {op}")

def assemble(input_file, output_file):
    with open(input_file, "r", encoding="utf-8") as f:
        lines = f.readlines()

    labels, instructions = first_pass(lines)

    machine_codes = []
    for pc, line in enumerate(instructions):
        code = assemble_instruction(line, labels, pc)
        machine_codes.append(f"{code & 0xFFFFFFFF:08X}")

    with open(output_file, "w", encoding="utf-8") as f:
        f.write("\n".join(machine_codes))

def main():
    if len(sys.argv) < 2:
        print("Kullanım: python assembler.py input.asm output.mem")
        return

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) >= 3 else "mem.dat"

    assemble(input_file, output_file)

if __name__ == "__main__":
    main()