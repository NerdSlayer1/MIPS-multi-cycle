`timescale 1ns / 1ps

module tb_mips;

    reg clk;
    reg reset;

    mips mips_DUT(
        .clk(clk), 
        .reset(reset)
    );

    initial forever #5 clk = ~clk;

    task check_register;
        input [4:0] reg_num;
        input [31:0] expected_value;
        input [200:0] test_name;
        begin
            if (mips_DUT.datapath_D.registers[reg_num] !== expected_value) begin
                $display("[HATA] %s | Register R%0d. Beklenen: %0d, Alinan: %0d", 
                         test_name, reg_num, expected_value, mips_DUT.datapath_D.registers[reg_num]);
                $stop; 
            end else begin
                $display("[BASARILI] %s | Register R%0d degeri %0d olarak dogrulandi.", 
                         test_name, reg_num, expected_value);
            end
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        #15 reset = 0; 

        $display("--- MIPS Multi-Cycle CPU Testleri Basliyor ---");

        #90; 
        check_register(29, 32'd200, "SP Ilklendirme");
        check_register(8,  32'd10,  "LOADI t0");
        check_register(9,  32'd20,  "LOADI t1");

        #30; 
        check_register(10, 32'd35,  "ADDI3 Komutu");

        #30;
        check_register(8,  32'd20,  "SWAP Komutu (t0)");
        check_register(9,  32'd10,  "SWAP Komutu (t1)");

        #40;
        check_register(11, 32'd200, "MUL Komutu");

        #50;
        if (mips_DUT.datapath_D.mem[200] !== 32'd200) begin
            $display("[HATA] PUSH Komutu | RAM[200] beklenen: 200, alinan: %0d",
                     mips_DUT.datapath_D.mem[200]);
            $stop;
        end else begin
            $display("[BASARILI] PUSH Komutu | RAM[200] = 200 dogrulandi.");
        end

        #60;
        check_register(12, 32'd200, "POP Komutu");

        #70;
        if (mips_DUT.datapath_D.registers[13] === 32'd99) begin
            $display("[HATA] BGT Komutu | Branch atlanmadi, R13 (t5) = 99 yazildi.");
            $stop;
        end else begin
            $display("[BASARILI] BGT Komutu | Ara komut atlandi (R13 != 99).");
        end
        check_register(14, 32'd100, "BGT Komutu (t6)");

        #50;
        $display("--- TOPLAM: 10 / 10 BASARILI ---");
        $stop;
    end

endmodule