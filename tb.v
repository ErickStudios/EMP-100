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
    reg  [7:0]  rom [0:4095];
    reg  [7:0]  ram [0:4095];
    wire [7:0]  pag = adr[15:8];
    wire [15:0] ins = (
            (pc[15:12] == 4'hF) ? { rom[pc[11:0]], rom[pc[11:0]+1] } :
            { ram[pc[11:0]], ram[pc[11:0]+1] } );

    cpu uut (
        .rex(rex),
        .wex(wex),
        .adr(adr),
        .wvx(wvx),
        .rvx(rvx),
        .ins(ins),
        .exi(exi),
        .clk(clk),
        .rst(rst),
        .jf(jf)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst) begin
            pc = 16'hFFF0;
        end
        else begin
            if (!exi) begin
                exi = 1;
                $display("PC: %h | INS: %h", pc, ins);
            end
            else if (exi) begin
                if (jf) begin
                    pc = adr;
                end
                else pc = pc + 2;
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

        #150 $finish;
    end

endmodule