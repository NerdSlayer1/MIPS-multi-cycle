module control (clk, reset, Op, Zero, GT, IorD, MemRead, MemWrite, MemtoReg, IRWrite,
PCSource, ALUSrcB, ALUSrcA, RegWrite, RegDst, PCSel, ALUOp);

    input clk;
    input reset;
    input [5:0] Op;
    input Zero;
    input GT;

    output reg IorD;
    output reg MemWrite;
    output reg MemRead;
    output reg MemtoReg;
    output reg IRWrite;
    output reg PCSource;
    output reg RegDst;
    output reg RegWrite;
    output reg ALUSrcA;
    output reg [1:0] ALUSrcB;
    output PCSel;
    output reg [1:0] ALUOp;

    reg PCWrite;
    reg PCWriteCond;
    reg GTCond;

    assign PCSel = (PCWrite | (PCWriteCond & Zero) | (GTCond & GT));

    parameter FETCH      = 5'b00000;
    parameter DECODE     = 5'b00001;
    parameter MEMADRCOMP = 5'b00010;
    parameter MEMACCESSL = 5'b00011;
    parameter MEMREADEND = 5'b00100;
    parameter MEMACCESSS = 5'b00101;
    parameter EXECUTION  = 5'b00110;
    parameter RTYPEEND   = 5'b00111;
    parameter BEQ        = 5'b01000;
    parameter LOADI      = 5'b01001;
    parameter ADDI3      = 5'b01010;
    parameter SWAP       = 5'b01011;
    parameter MUL        = 5'b01100;
    parameter BGT        = 5'b01101;
    parameter PUSHADR    = 5'b01110;
    parameter PUSHMEM    = 5'b01111;
    parameter POPADR     = 5'b10000;
    parameter POPMEM     = 5'b10001;
    parameter POPWB      = 5'b10010;

    reg [4:0] state;
    reg [4:0] nextstate;

    always @(posedge clk)
        if (reset)
            state <= FETCH;
        else
            state <= nextstate;

    always @(state or Op) begin
        case (state)
            FETCH: nextstate = DECODE;

            DECODE: case (Op)
                6'b100011: nextstate = MEMADRCOMP;
                6'b101011: nextstate = MEMADRCOMP;
                6'b000000: nextstate = EXECUTION;
                6'b000100: nextstate = BEQ;
                6'b011111: nextstate = LOADI;
                6'b011110: nextstate = ADDI3;
                6'b011101: nextstate = SWAP;
                6'b011100: nextstate = MUL;
                6'b011011: nextstate = BGT;
                6'b011010: nextstate = PUSHADR;
                6'b011001: nextstate = POPADR;
                default:   nextstate = FETCH;
            endcase

            MEMADRCOMP: case (Op)
                6'b100011: nextstate = MEMACCESSL;
                6'b101011: nextstate = MEMACCESSS;
                default:   nextstate = FETCH;
            endcase

            MEMACCESSL: nextstate = MEMREADEND;
            MEMREADEND: nextstate = FETCH;
            MEMACCESSS: nextstate = FETCH;
            EXECUTION:  nextstate = RTYPEEND;
            RTYPEEND:   nextstate = FETCH;
            BEQ:        nextstate = FETCH;
            LOADI:      nextstate = FETCH;
            ADDI3:      nextstate = FETCH;
            SWAP:       nextstate = FETCH;
            MUL:        nextstate = FETCH;
            BGT:        nextstate = FETCH;
            PUSHADR:    nextstate = PUSHMEM;
            PUSHMEM:    nextstate = FETCH;
            POPADR:     nextstate = POPMEM;
            POPMEM:     nextstate = POPWB;
            POPWB:      nextstate = FETCH;
            default:    nextstate = FETCH;
        endcase
    end

    always @(state) begin
        IorD=0; MemRead=0; MemWrite=0; MemtoReg=0; IRWrite=0;
        PCSource=0; ALUSrcB=2'b00; ALUSrcA=0; RegWrite=0; RegDst=0;
        PCWrite=0; PCWriteCond=0; GTCond=0; ALUOp=2'b00;

        case (state)
            FETCH:
                begin
                    MemRead = 1;
                    IRWrite = 1;
                    ALUSrcB = 2'b01;
                    PCWrite = 1;
                end
            DECODE:
                ALUSrcB = 2'b11;
            MEMADRCOMP:
                begin
                    ALUSrcA = 1;
                    ALUSrcB = 2'b10;
                end
            MEMACCESSL:
                begin
                    MemRead = 1;
                    IorD    = 1;
                end
            MEMREADEND:
                begin
                    RegWrite = 1;
                    MemtoReg = 1;
                    RegDst   = 0;
                end
            MEMACCESSS:
                begin
                    MemWrite = 1;
                    IorD     = 1;
                end
            EXECUTION:
                begin
                    ALUSrcA = 1;
                    ALUOp   = 2'b10;
                end
            RTYPEEND:
                begin
                    RegDst   = 1;
                    RegWrite = 1;
                end
            BEQ:
                begin
                    ALUSrcA     = 1;
                    ALUOp       = 2'b01;
                    PCWriteCond = 1;
                    PCSource    = 1;
                end
            LOADI:
                begin
                    RegWrite = 1;
                    RegDst   = 0;
                end
            ADDI3:
                begin
                    RegWrite = 1;
                    RegDst   = 0;
                    ALUSrcA  = 1;
                    ALUOp    = 2'b11;
                end
            SWAP:
                begin
                    RegWrite = 1;
                    ALUSrcA  = 1;
                end
            MUL:
                begin
                    ALUSrcA  = 1;
                    ALUSrcB  = 2'b00;
                    ALUOp    = 2'b10;
                    RegDst   = 1;
                    RegWrite = 1;
                end
            BGT:
                begin
                    ALUSrcA  = 1;
                    ALUSrcB  = 2'b00;
                    ALUOp    = 2'b01;
                    GTCond   = 1;
                    PCSource = 1;
                end
            PUSHADR:
                begin
                    ALUSrcA = 1;
                    ALUSrcB = 2'b10;
                    ALUOp   = 2'b00;
                end
            PUSHMEM:
                begin
                    MemWrite = 1;
                    IorD     = 1;
                end
            POPADR:
                begin
                    ALUSrcA = 1;
                    ALUSrcB = 2'b10;
                    ALUOp   = 2'b00;
                end
            POPMEM:
                begin
                    MemRead = 1;
                    IorD    = 1;
                end
            POPWB:
                begin
                    RegWrite = 1;
                    MemtoReg = 1;
                    RegDst   = 0;
                end
        endcase
    end

endmodule
