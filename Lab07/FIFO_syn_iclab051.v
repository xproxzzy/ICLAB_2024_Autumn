module FIFO_syn #(parameter WIDTH=8, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk1,
	flag_clk1_to_fifo
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
output  flag_fifo_to_clk2;
input flag_clk2_to_fifo;

output flag_fifo_to_clk1;
input flag_clk1_to_fifo;

wire [WIDTH-1:0] rdata_q;

// Remember: 
//   wptr and rptr should be gray coded
//   Don't modify the signal name
reg [$clog2(WORDS):0] wptr;
reg [$clog2(WORDS):0] rptr;

//==================================================================
// reg & wire
//==================================================================
reg [6:0] waddr;
reg [6:0] next_waddr;
reg [6:0] raddr;
reg [6:0] next_raddr;

reg [6:0] next_wptr;
reg [6:0] next_rptr;

reg [6:0] wptr_out;
reg [6:0] rptr_out;

reg [7:0] rdata_reg;
reg [7:0] next_rdata_reg;
reg wean;

//==================================================================
// SRAM NDFF_BUS
//==================================================================

DUAL_64X8X1BM1 u_dual_sram  (.A0(waddr[0]), .A1(waddr[1]), .A2(waddr[2]), .A3(waddr[3]), .A4(waddr[4]), .A5(waddr[5]), 
                                .B0(raddr[0]), .B1(raddr[1]), .B2(raddr[2]), .B3(raddr[3]), .B4(raddr[4]), .B5(raddr[5]), 
                                //.DOA0(), .DOA1(), .DOA2(), .DOA3(), .DOA4(), .DOA5(), .DOA6(), .DOA7(), 
                                .DOB0(next_rdata_reg[0]), .DOB1(next_rdata_reg[1]), .DOB2(next_rdata_reg[2]), .DOB3(next_rdata_reg[3]), 
                                .DOB4(next_rdata_reg[4]), .DOB5(next_rdata_reg[5]), .DOB6(next_rdata_reg[6]), .DOB7(next_rdata_reg[7]), 
                                .DIA0(wdata[0]), .DIA1(wdata[1]), .DIA2(wdata[2]), .DIA3(wdata[3]), .DIA4(wdata[4]), .DIA5(wdata[5]), .DIA6(wdata[6]), .DIA7(wdata[7]), 
                                .DIB0(1'b0), .DIB1(1'b0), .DIB2(1'b0), .DIB3(1'b0), .DIB4(1'b0), .DIB5(1'b0), .DIB6(1'b0), .DIB7(1'b0), 
                                .WEAN(wean), .WEBN(1'b1), .CKA(wclk), .CKB(rclk), .CSA(1'b1), .CSB(1'b1), .OEA(1'b1), .OEB(1'b1));

NDFF_BUS_syn #(7) NDFF_BUS_syn_w (.D(wptr), .Q(wptr_out), .clk(rclk), .rst_n(rst_n));
NDFF_BUS_syn #(7) NDFF_BUS_syn_r (.D(rptr), .Q(rptr_out), .clk(wclk), .rst_n(rst_n));

//==================================================================
// wean
//==================================================================
always @ (*)
begin
    if((winc == 1'b1) && (wfull == 1'b0)) wean = 1'b0;
    else wean = 1'b1;
end

//==================================================================
// waddr
//==================================================================
always @ (posedge wclk or negedge rst_n)
begin
    if(!rst_n) waddr <= 7'd0;
    else waddr <= next_waddr;
end

always @ (*)
begin
    if((winc == 1'b1) && (wfull == 1'b0)) next_waddr = waddr + 7'd1;
    else next_waddr = waddr;
end

//==================================================================
// raddr
//==================================================================
always @ (posedge rclk or negedge rst_n)
begin
    if(!rst_n) raddr <= 7'd0;
    else raddr <= next_raddr;
end

always @ (*)
begin
    if((rinc == 1'b1) && (rempty == 1'b0)) next_raddr = raddr + 7'd1;
    else next_raddr = raddr;
end

//==================================================================
// wptr
//==================================================================
always @ (posedge wclk or negedge rst_n)
begin
    if(!rst_n) wptr <= 7'd0;
    else wptr <= next_wptr;
end

always @ (*)
begin
    next_wptr = next_waddr ^ (next_waddr >> 1);
end

//==================================================================
// rptr
//==================================================================
always @ (posedge rclk or negedge rst_n)
begin
    if(!rst_n) rptr <= 7'd0;
    else rptr <= next_rptr;
end

always @ (*)
begin
    next_rptr = next_raddr ^ (next_raddr >> 1);
end

//==================================================================
// wfull
//==================================================================
always @ (posedge wclk or negedge rst_n)
begin
    if(!rst_n) wfull <= 1'b0;
    else
    begin
        if(next_wptr == {~rptr_out[6:5], rptr_out[4:0]}) wfull <= 1'b1;
        else wfull <= 1'b0;
    end
end

//==================================================================
// rempty
//==================================================================
always @ (posedge rclk or negedge rst_n)
begin
    if(!rst_n) rempty <= 1'b1;
    else
    begin
        if(next_rptr == wptr_out) rempty <= 1'b1;
        else rempty <= 1'b0;
    end
end

//==================================================================
// rdata_reg
//==================================================================
always @ (posedge rclk or negedge rst_n)
begin
    if(!rst_n) rdata_reg <= 8'd0;
    else rdata_reg <= next_rdata_reg;
end

//==================================================================
// rdata
//==================================================================
always @ (*)
begin
    rdata = rdata_reg;
end

endmodule
