module datapath(clk, reset, IorD, MemRead, MemWrite, MemtoReg, IRWrite,
PCSource, ALUSrcB, ALUSrcA, RegWrite, RegDst, PCSel, ALUCtrl, Op, Zero, GT, Function);

    parameter PCSTART = 128;

    input clk, reset;
    input IorD;
    input MemWrite, MemRead, MemtoReg;
    input IRWrite;
    input PCSource;
    input RegDst, RegWrite;
    input ALUSrcA;
    input [1:0] ALUSrcB;
    input PCSel;
    input [3:0] ALUCtrl;

    output [5:0] Op;
    output Zero;
    output GT;
    output [5:0] Function;

    reg [7:0] PC;
    reg [31:0] ALUOut;
    reg [31:0] ALUResult;
    wire [31:0] OpA;
    reg [31:0] OpB;
    reg [31:0] A, B;
    wire [7:0] address;
    wire [31:0] MemData;
    reg [31:0] mem[255:0];
    reg [31:0] Instruction;
    reg [31:0] mdr;
    wire [31:0] da, db;
    reg [31:0] registers[31:0];

    assign Function = Instruction[5:0];
    assign Op       = Instruction[31:26];
    assign address  = (IorD) ? ALUOut : PC;

    initial
        $readmemh("mem.dat", mem);

    always @(posedge clk) begin
        if (MemWrite)
            mem[address] <= B;
    end

    assign MemData = (MemRead) ? mem[address] : 32'bx;

    always @(posedge clk) begin
        if (reset)
            PC <= PCSTART;
        else if (PCSel) begin
            case (PCSource)
                1'b0: PC <= ALUResult;
                1'b1: PC <= ALUOut;
            endcase
        end
    end

    always @(posedge clk) begin
        if (IRWrite)
            Instruction <= MemData;
    end

    always @(posedge clk) begin
        mdr <= MemData;
    end

    assign da = (Instruction[25:21] != 0) ? registers[Instruction[25:21]] : 0;
    assign db = (Op == 6'h1E)
        ? ((Instruction[15:11] != 0) ? registers[Instruction[15:11]] : 0)
        : ((Instruction[20:16] != 0) ? registers[Instruction[20:16]] : 0);

    always @(posedge clk) begin
        if (RegWrite) begin
            if (Op == 6'h1F)
                registers[Instruction[20:16]] <= {{16{Instruction[15]}}, Instruction[15:0]};
            else if (Op == 6'h1D) begin
                registers[Instruction[25:21]] <= B;
                registers[Instruction[20:16]] <= A;
            end
            else if (Op == 6'h1A)
                registers[29] <= registers[29] - 4;
            else if (Op == 6'h19) begin
                registers[Instruction[20:16]] <= mdr;
                registers[29] <= registers[29] + 4;
            end
            else if (Op == 6'h1E)
                registers[Instruction[20:16]] <= ALUResult;
            else if (RegDst)
                registers[Instruction[15:11]] <= (MemtoReg) ? mdr : ALUOut;
            else
                registers[Instruction[20:16]] <= (MemtoReg) ? mdr : ALUOut;
        end
    end

    always @(posedge clk) A <= da;
    always @(posedge clk) B <= db;

    assign OpA = (ALUSrcA) ? A : PC;

    always @(ALUSrcB or B or Instruction[15:0]) begin
        casex (ALUSrcB)
            2'b00: OpB = B;
            2'b01: OpB = 1;
            2'b10: OpB = {{16{Instruction[15]}}, Instruction[15:0]};
            2'b11: OpB = {{16{Instruction[15]}}, Instruction[15:0]};
        endcase
    end

    assign Zero = (ALUResult == 0);
    assign GT   = (!ALUResult[31] && (ALUResult != 0));

    always @(ALUCtrl or OpA or OpB or A or B or Instruction) begin
        case (ALUCtrl)
            4'b0000: ALUResult = OpA & OpB;
            4'b0001: ALUResult = OpA | OpB;
            4'b0010: ALUResult = OpA + OpB;
            4'b0110: ALUResult = OpA - OpB;
            4'b0111: ALUResult = (OpA < OpB) ? 1 : 0;
            4'b1100: ALUResult = ~(OpA | OpB);
            4'b1101: ALUResult = A + B + {{21{Instruction[10]}}, Instruction[10:0]};
            4'b1110: ALUResult = A * B;
            default: ALUResult = 0;
        endcase
    end

    always @(posedge clk) begin
        ALUOut <= ALUResult;
    end

endmodule
