module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
output reg flag_handshake_to_clk1;
input flag_clk1_to_handshake;

output flag_handshake_to_clk2;
input flag_clk2_to_handshake;

// Remember:
//   Don't modify the signal name
reg sreq;
wire dreq;
reg dack;
wire sack;

//==================================================================
// parameter & integer
//==================================================================
parameter IDLE = 3'd0;
parameter SEND = 3'd1;
parameter OUT = 3'd1;
parameter WAIT = 3'd2;

//==================================================================
// reg & wire
//==================================================================
reg [1:0] src_state;
reg [1:0] next_src_state;
reg [1:0] dest_state;
reg [1:0] next_dest_state;
reg [WIDTH-1:0] src_reg;
reg [WIDTH-1:0] dest_reg;

//==================================================================
// NDFF_syn
//==================================================================
NDFF_syn NDFF_syn_req(.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn NDFF_syn_ack(.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));

//==================================================================
// src_state
//==================================================================
always @ (posedge sclk or negedge rst_n)
begin
    if(!rst_n) src_state <= 2'd0;
    else src_state <= next_src_state;
end

always @ (*)
begin
    case(src_state)
    IDLE:
    begin
        if((sready == 1'b1) && (sreq == 1'b0)) next_src_state = SEND;
        else next_src_state = IDLE;
    end
    SEND:
    begin
        if((sreq == 1'b1) && (sack == 1'b1)) next_src_state = WAIT;
        else next_src_state = SEND;
    end
    WAIT:
    begin
        if((sreq == 1'b0) && (sack == 1'b0)) next_src_state = IDLE;
        else next_src_state = WAIT;
    end
    default:
    begin
        next_src_state = IDLE;
    end
    endcase
end

//==================================================================
// sreq
//==================================================================
always @ (posedge sclk or negedge rst_n)
begin
    if(!rst_n) sreq <= 1'b0;
    else if(src_state == IDLE)
    begin
        if((sready == 1'b1) && (sreq == 1'b0)) sreq <= 1'b1;
        else sreq <= 1'b0;
    end
    else if(src_state == SEND)
    begin
        if((sreq == 1'b1) && (sack == 1'b1)) sreq <= 1'b0;
        else sreq <= 1'b1;
    end
    else sreq <= sreq;
end

//==================================================================
// src_reg
//==================================================================
always @ (posedge sclk or negedge rst_n)
begin
    if(!rst_n) src_reg <= 0;
    else if(src_state == IDLE)
    begin
        src_reg <= din;
    end
    else src_reg <= src_reg;
end

//==================================================================
// sidle
//==================================================================
assign sidle = (src_state == IDLE)?1'b1:1'b0;

//==================================================================
// dest_state
//==================================================================
always @ (posedge dclk or negedge rst_n)
begin
    if(!rst_n) dest_state <= 2'd0;
    else dest_state <= next_dest_state;
end

always @ (*)
begin
    case(dest_state)
    IDLE:
    begin
        if((dbusy == 1'b0) && (dreq == 1'b1)) next_dest_state = OUT;
        else next_dest_state = IDLE;
    end
    OUT:
    begin
        next_dest_state = WAIT;
    end
    WAIT:
    begin
        if((dreq == 1'b0) && (dack == 1'b1)) next_dest_state = IDLE;
        else next_dest_state = WAIT;
    end
    default:
    begin
        next_dest_state = IDLE;
    end
    endcase
end

//==================================================================
// dack
//==================================================================
always @ (posedge dclk or negedge rst_n)
begin
    if(!rst_n) dack <= 1'b0;
    else if(dest_state == IDLE)
    begin
        if((dbusy == 1'b0) && (dreq == 1'b1)) dack <= 1'b1;
        else dack <= 1'b0;
    end
    else if(dest_state == WAIT)
    begin
        if((dreq == 1'b0) && (dack == 1'b1)) dack <= 1'b0;
        else dack <= 1'b1;
    end
    else dack <= dack;
end

//==================================================================
// dest_reg
//==================================================================
always @ (posedge dclk or negedge rst_n)
begin
    if(!rst_n) dest_reg <= 0;
    else if(dest_state == IDLE)
    begin
        if((dbusy == 1'b0) && (dreq == 1'b1)) dest_reg <= src_reg;
        else dest_reg <= dest_reg;
    end
    else dest_reg <= dest_reg;
end

//==================================================================
// dvalid
//==================================================================
always @ (posedge dclk or negedge rst_n)
begin
    if(!rst_n) dvalid <= 1'b0;
    else if(dest_state == OUT) dvalid <= 1'b1;
    else dvalid <= 1'b0;
end

//==================================================================
// dout
//==================================================================
always @ (posedge dclk or negedge rst_n)
begin
    if(!rst_n) dout <= 0;
    else if(dest_state == OUT) dout <= dest_reg;
    else dout <= 0;
end

endmodule