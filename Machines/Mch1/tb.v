module tb;

    reg         clk;
    reg         rst;
    reg         exi;
    wire        rex;
    wire        wex;
    wire        jf;
    wire [15:0] adr;
    wire [7:0]  wvx;
    reg  [7:0]  rvx;
    reg  [15:0] pc;
    reg  [7:0]  rom [0:16383];
    reg  [7:0]  ram [0:70964];
    wire [7:0]  pag = adr[15:8];
    wire [15:0] ins = (
            ((pc[15:12] & 4'hC) == 4'hC) ? { rom[pc[13:0]], rom[pc[13:0]+1] } :
            { ram[pc[14:0]], ram[pc[14:0]+1] } );
    reg  [15:0] sp;
    reg         bl_f; // br link flag
    wire        ir;

    cpu #(
        .MODEL_TYPE(1000)
    ) uut (
        .rex(rex),
        .wex(wex),
        .adr(adr),
        .wvx(wvx),
        .rvx(rvx),
        .ins(ins),
        .exi(exi),
        .clk(clk),
        .rst(rst),
        .jf(jf),
        .ir(ir)
    );

    always #5 clk = ~clk;

    task WriteMemory;
    input [15:0]    addrs;
    input [7:0]     val;
    begin
        if (pc[15:12] == 4'hC) begin
        end
        else ram[addrs] = val;
    end
    endtask

    always @(posedge clk) begin
        if (rst) begin
            pc = 16'hFFF0;
        end
        else begin
            if (!exi) begin
                exi = 1;
                //$display("PC: %h | INS: %h", pc, ins);
            end
            else if (exi) begin
                if (wex) begin
                    $display("PC: %h | WRT: %h = %h", pc, adr, wvx);
                    if (adr == 16'hA101) sp[7:0] = wvx;
                    if (adr == 16'hA100) sp[15:8] = wvx;
                    if (adr == 16'hA102) bl_f = 1;
                    if (adr == 16'hA103) begin
                        sp = sp + 2;
                        $display("PC: %h | RET: pc = %h sp = %h", pc, {ram[sp], ram[sp+1]}, sp);

                        pc = {ram[sp], ram[sp+1]};
                    end
                end
                else if (rex) begin
                    $display("PC: %h | RAD: %h", pc, adr);
                end
                if (jf) begin
                    if (bl_f) begin
                        bl_f = 0;
                        ram[sp] = pc[15:8];
                        ram[sp+1] = pc[7:0];
                        $display("PC: %h | BLR: pc = %h sp = %h", pc, adr, sp);
                        sp = sp - 2;
                    end
                    pc = adr;
                end
                else begin 
                    if (!ir) 
                        pc = pc + 2;
                end
                exi = 0;
            end
        end
    end

    initial begin
        clk = 0;
        rst = 1;
        exi = 0;
        rvx = 8'h00;

        $readmemh("test.hex", rom);

        #20 rst = 0;

        #6400 $finish;
    end

endmodule