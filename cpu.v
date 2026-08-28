module cpu(
    output reg         rex,
    output reg         wex,
    output reg  [15:0] adr,
    output reg  [7:0]  wvx,
    input       [7:0]  rvx,
    input       [15:0] ins,
    input              exi,
    input              clk,
    input              rst,
    output reg         ix,
    output reg         jf
);

// registers
reg [7:0]   ar; // acumulador
reg [7:0]   br; // helper acum
reg [7:0]   cr; // unnamed
reg [7:0]   pr; // page
reg [7:0]   fr; // flags
reg         ir; // in reading
reg [7:0]   tr; // tmp

// flags
wire        rcf; // carry flag
assign      rcf = fr[0];

wire [7:0]  opcode = ins[15:8];
wire [3:0]  reg_r  = ins[3:0];
wire [7:0]  imm_vv = ins[7:0];

function [7:0] getReg(input [3:0] id);
    case (id)
    4'h0: getReg = ar;
    4'h1: getReg = br;
    4'h2: getReg = cr;
    4'h3: getReg = pr;
    default: getReg = 8'h00;
    endcase
endfunction

task setRegister(input [3:0] id, input [7:0] val);
begin
    case (id)
    4'h0: ar = val;
    4'h1: br = val;
    4'h2: cr = val;
    4'h3: pr = val;
    endcase
end
endtask

always @(posedge clk or posedge rst) begin
    if (rst) begin
        ar  <= 8'h00;
        br  <= 8'h00;
        cr  <= 8'h00;
        pr  <= 8'h00;
        fr  <= 8'h00;
        rex <= 1'b0;
        wex <= 1'b0;
        adr <= 16'h0000;
        wvx <= 8'h00;
    end else if (exi) begin
        if (rex == 1) rex <= 1'b0;
        if (wex == 1) wex <= 1'b0;
        ix <= 1'b0;

        if (jf == 1) begin
            jf <= 1'b0;
        end
    
        if (ir == 1) begin
            ir <= 0;
            ar  <= rvx;
            ix <= 1'b0;
        end
        else begin
            casez (opcode)
                // 00 0r: TSA r (a test r)
                8'h00: begin
                    ix <= 1'b1;
                    if (ins[7:4] == 4'h0) begin
                        tr = ar - getReg(reg_r);
                        fr[1] = 0;
                        if (tr == 0) fr[1] = 1;
                        if (tr[7] == 1) begin 
                            fr[2] = 1;
                            fr[3] = 0;
                        end
                        else begin
                            fr[2] = 0;
                            fr[3] = 1;
                        end
                    end
                    else if (ins[7:4] == 4'h1) begin
                        ar <= getReg(reg_r);
                    end
                end

                // 01 0r: CPr (r = a)
                8'b0001_000?: begin
                    setRegister(reg_r, ar);
                    ix <= 1'b1;
                end

                // 02 00: ZRC (CF = 0)
                8'h02: begin
                    if (imm_vv == 8'h00) 
                        fr[0] <= 1'b0; // ZRC
                    else if (imm_vv == 8'h10) 
                        fr[0] <= 1'b1; // STC
                    ix <= 1'b1;
                end

                // 03 0r: ADC r (a = a + r + CF)
                8'b0011_000?: begin
                    {fr[0], ar} <= ar + getReg(reg_r) + {7'b0, rcf};
                    ix <= 1'b1;
                end

                // 03 1r: SBB r (a = a - r + CF)
                8'b0011_100?: begin
                    ar <= ar - getReg(reg_r) + {7'b0, rcf};
                    ix <= 1'b1;
                end

                // 04 VV: PAG $VV (page = 0xVV)
                8'h04: begin
                    pr <= imm_vv;
                    ix <= 1'b1;
                end

                // 05 0r: STA r ([page:r] = a)
                8'b0101_000?: begin
                    adr <= {pr, getReg(reg_r)};
                    wvx <= ar;
                    wex <= 1'b1;
                    ix <= 1'b1;
                end

                // 05 1r: LDA r (a = [page:r])
                8'b0101_100?: begin
                    adr <= {pr, getReg(reg_r)};
                    rex <= 1'b1;
                    ir  <= 1;
                end

                // 06 1r: CHA v (a = v)
                8'h06: begin
                    ix <= 1'b1;
                    ar <= imm_vv;
                end

                // 07 VV: LDC $VV
                8'h07: begin
                    ix <= 1'b1;
                    fr[0] = fr[imm_vv];
                end

                // 08 0r: BRC r
                8'h08: begin
                    if (rcf) begin
                        jf <= 1'b1;
                        adr <= {pr, getReg(reg_r)};
                    end
                    ix <= 1'b1;
                end

                // 09 1r: CHB v (b = v)
                8'h09: begin
                    ix <= 1'b1;
                    br <= imm_vv;
                end

                // 0a 0r: CTA $$V ([page:$VV] = a)
                8'h0a: begin
                    adr <= {pr, imm_vv};
                    wvx <= ar;
                    wex <= 1'b1;
                    ix <= 1'b1;
                end

                // 0b VV: BCC $VV
                8'h0b: begin
                    if (rcf) begin
                        jf <= 1'b1;
                        adr <= {pr, imm_vv};
                    end
                    ix <= 1'b1;
                end

                // 0c VV: CDA $VV (a = [page:$VV])
                8'h0c: begin
                    adr <= {pr, imm_vv};
                    rex <= 1'b1;
                    ir  <= 1;
                end

                default: begin
                    ix <= 1'b1;
                    // Operación no definida o NOP
                end
            endcase
        end
    end
end

endmodule