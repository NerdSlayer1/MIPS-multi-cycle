# ModelSim waveform simulation script
# Usage (from project folder in ModelSim Transcript):
#   do sim_wave.do

# ASCII path recommended if vlib fails (e.g. copy project to C:/temp/mips-sim)

if {![file exists work]} {
    vlib work
}

vlog mips.v control.v datapath.v alucontrol.v tb_mips.v

vsim -voptargs=+acc work.tb_mips

# Clock and reset
add wave -divider "Clock / Reset"
add wave -radix binary   /tb_mips/clk
add wave -radix binary   /tb_mips/reset

# Control FSM
add wave -divider "Control FSM"
add wave -radix unsigned /tb_mips/mips_DUT/control_D/state
add wave -radix binary   /tb_mips/mips_DUT/control_D/RegWrite
add wave -radix binary   /tb_mips/mips_DUT/control_D/MemRead
add wave -radix binary   /tb_mips/mips_DUT/control_D/MemWrite
add wave -radix binary   /tb_mips/mips_DUT/control_D/IRWrite
add wave -radix binary   /tb_mips/mips_DUT/control_D/PCSel

# Program counter and instruction
add wave -divider "Fetch"
add wave -radix unsigned /tb_mips/mips_DUT/datapath_D/PC
add wave -radix hex      /tb_mips/mips_DUT/datapath_D/Instruction
add wave -radix hex      /tb_mips/mips_DUT/datapath_D/Op
add wave -radix hex      /tb_mips/mips_DUT/datapath_D/Function

# Registers (test program uses these)
add wave -divider "Registers"
add wave -radix decimal  /tb_mips/mips_DUT/datapath_D/registers[29]
add wave -radix decimal  /tb_mips/mips_DUT/datapath_D/registers[8]
add wave -radix decimal  /tb_mips/mips_DUT/datapath_D/registers[9]
add wave -radix decimal  /tb_mips/mips_DUT/datapath_D/registers[10]
add wave -radix decimal  /tb_mips/mips_DUT/datapath_D/registers[11]
add wave -radix decimal  /tb_mips/mips_DUT/datapath_D/registers[12]
add wave -radix decimal  /tb_mips/mips_DUT/datapath_D/registers[14]

# ALU
add wave -divider "ALU"
add wave -radix decimal  /tb_mips/mips_DUT/datapath_D/A
add wave -radix decimal  /tb_mips/mips_DUT/datapath_D/B
add wave -radix decimal  /tb_mips/mips_DUT/datapath_D/ALUResult
add wave -radix decimal  /tb_mips/mips_DUT/datapath_D/ALUOut
add wave -radix hex      /tb_mips/mips_DUT/datapath_D/ALUCtrl

# Memory
add wave -divider "Memory"
add wave -radix unsigned /tb_mips/mips_DUT/datapath_D/address
add wave -radix hex      /tb_mips/mips_DUT/datapath_D/MemData
add wave -radix decimal  /tb_mips/mips_DUT/datapath_D/mem[200]

# Branch flags
add wave -divider "Branch"
add wave -radix binary   /tb_mips/mips_DUT/datapath_D/Zero
add wave -radix binary   /tb_mips/mips_DUT/datapath_D/GT

configure wave -namecolwidth 260
configure wave -valuecolwidth 100
configure wave -timelineunits ns

run 500 ns
wave zoom full
