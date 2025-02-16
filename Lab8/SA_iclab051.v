/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: SA
// FILE NAME: SA.v
// VERSRION: 1.0
// DATE: Nov 06, 2024
// AUTHOR: Yen-Ning Tung, NYCU AIG
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2024 Fall IC Lab / Exersise Lab08 / SA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on


module SA(
    //Input signals
    clk,
    rst_n,
    cg_en,
    in_valid,
    T,
    in_data,
    w_Q,
    w_K,
    w_V,

    //Output signals
    out_valid,
    out_data
    );

input clk;
input rst_n;
input in_valid;
input cg_en;
input [3:0] T;
input signed [7:0] in_data;
input signed [7:0] w_Q;
input signed [7:0] w_K;
input signed [7:0] w_V;

output reg out_valid;
output reg signed [63:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter IDLE = 3'd0;
parameter XWQ = 3'd1;
parameter XWK = 3'd2;
parameter XWV = 3'd3;
parameter WAIT = 3'd4;
parameter OUT = 3'd5;

integer i;

//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [2:0] state;
reg [2:0] next_state;
reg [5:0] input_counter;
reg [5:0] next_input_counter;
reg [5:0] output_counter;
reg [5:0] next_output_counter;

reg [3:0] t_reg;
reg signed [7:0] in_data_reg [63:0];
reg signed [7:0] w_reg [63:0];
reg signed [18:0] xw_reg [63:0];
reg signed [40:0] qkt_reg [63:0];

reg [3:0] next_t_reg;
reg signed [7:0] next_in_data_reg [63:0];
reg signed [7:0] next_w_reg [63:0];
reg signed [18:0] next_xw_reg [63:0];
reg signed [40:0] next_qkt_reg [63:0];

reg [6:0] t_reg_shift;

reg signed [18:0] mult_0_a [7:0];
reg signed [18:0] mult_0_b [7:0];
reg signed [40:0] mult_0_z;
reg signed [18:0] mult_1_a [7:0];
reg signed [18:0] mult_1_b [7:0];
reg signed [40:0] mult_1_z;
reg signed [18:0] mult_2_a [7:0];
reg signed [18:0] mult_2_b [7:0];
reg signed [40:0] mult_2_z;
reg signed [18:0] mult_3_a [7:0];
reg signed [18:0] mult_3_b [7:0];
reg signed [40:0] mult_3_z;
reg signed [18:0] mult_4_a [7:0];
reg signed [18:0] mult_4_b [7:0];
reg signed [40:0] mult_4_z;
reg signed [18:0] mult_5_a [7:0];
reg signed [18:0] mult_5_b [7:0];
reg signed [40:0] mult_5_z;
reg signed [18:0] mult_6_a [7:0];
reg signed [18:0] mult_6_b [7:0];
reg signed [40:0] mult_6_z;
reg signed [40:0] mult_7_a [7:0];
reg signed [18:0] mult_7_b [7:0];
reg signed [62:0] mult_7_z;

reg signed [40:0] scale_relu_a;
reg signed [40:0] scale_relu_z;

reg signed [63:0] out_data_reg;
reg signed [63:0] next_out_data_reg;

//wire clk_state;
wire clk_input_counter;
wire clk_in_data;
wire clk_w;
wire clk_xw_0;
wire clk_xw_1;
wire clk_xw_2;
wire clk_qkt [0:63];

reg sleep_ctrl_w;
reg sleep_ctrl_xw;
reg sleep_ctrl_qkt [0:63];

//==============================================//
//                 GATED_OR                     //
//==============================================//
GATED_OR GATED_OR_0(.CLOCK(clk), .SLEEP_CTRL(1'b0), .RST_N(rst_n), .CLOCK_GATED(clk_input_counter));
GATED_OR GATED_OR_1(.CLOCK(clk), .SLEEP_CTRL(cg_en && !((state == IDLE) || (state == XWQ))), .RST_N(rst_n), .CLOCK_GATED(clk_in_data));
GATED_OR GATED_OR_2(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_w), .RST_N(rst_n), .CLOCK_GATED(clk_w));
GATED_OR GATED_OR_3(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_xw), .RST_N(rst_n), .CLOCK_GATED(clk_xw_0));
GATED_OR GATED_OR_4(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_xw), .RST_N(rst_n), .CLOCK_GATED(clk_xw_1));
GATED_OR GATED_OR_5(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_xw), .RST_N(rst_n), .CLOCK_GATED(clk_xw_2));

GATED_OR GATED_OR_QKT_0(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[0]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[0]));
GATED_OR GATED_OR_QKT_1(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[1]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[1]));
GATED_OR GATED_OR_QKT_2(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[2]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[2]));
GATED_OR GATED_OR_QKT_3(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[3]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[3]));
GATED_OR GATED_OR_QKT_4(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[4]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[4]));
GATED_OR GATED_OR_QKT_5(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[5]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[5]));
GATED_OR GATED_OR_QKT_6(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[6]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[6]));
GATED_OR GATED_OR_QKT_7(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[7]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[7]));
GATED_OR GATED_OR_QKT_8(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[8]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[8]));
GATED_OR GATED_OR_QKT_9(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[9]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[9]));
GATED_OR GATED_OR_QKT_10(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[10]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[10]));
GATED_OR GATED_OR_QKT_11(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[11]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[11]));
GATED_OR GATED_OR_QKT_12(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[12]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[12]));
GATED_OR GATED_OR_QKT_13(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[13]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[13]));
GATED_OR GATED_OR_QKT_14(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[14]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[14]));
GATED_OR GATED_OR_QKT_15(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[15]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[15]));
GATED_OR GATED_OR_QKT_16(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[16]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[16]));
GATED_OR GATED_OR_QKT_17(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[17]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[17]));
GATED_OR GATED_OR_QKT_18(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[18]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[18]));
GATED_OR GATED_OR_QKT_19(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[19]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[19]));
GATED_OR GATED_OR_QKT_20(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[20]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[20]));
GATED_OR GATED_OR_QKT_21(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[21]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[21]));
GATED_OR GATED_OR_QKT_22(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[22]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[22]));
GATED_OR GATED_OR_QKT_23(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[23]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[23]));
GATED_OR GATED_OR_QKT_24(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[24]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[24]));
GATED_OR GATED_OR_QKT_25(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[25]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[25]));
GATED_OR GATED_OR_QKT_26(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[26]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[26]));
GATED_OR GATED_OR_QKT_27(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[27]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[27]));
GATED_OR GATED_OR_QKT_28(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[28]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[28]));
GATED_OR GATED_OR_QKT_29(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[29]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[29]));
GATED_OR GATED_OR_QKT_30(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[30]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[30]));
GATED_OR GATED_OR_QKT_31(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[31]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[31]));
GATED_OR GATED_OR_QKT_32(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[32]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[32]));
GATED_OR GATED_OR_QKT_33(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[33]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[33]));
GATED_OR GATED_OR_QKT_34(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[34]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[34]));
GATED_OR GATED_OR_QKT_35(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[35]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[35]));
GATED_OR GATED_OR_QKT_36(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[36]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[36]));
GATED_OR GATED_OR_QKT_37(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[37]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[37]));
GATED_OR GATED_OR_QKT_38(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[38]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[38]));
GATED_OR GATED_OR_QKT_39(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[39]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[39]));
GATED_OR GATED_OR_QKT_40(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[40]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[40]));
GATED_OR GATED_OR_QKT_41(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[41]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[41]));
GATED_OR GATED_OR_QKT_42(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[42]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[42]));
GATED_OR GATED_OR_QKT_43(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[43]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[43]));
GATED_OR GATED_OR_QKT_44(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[44]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[44]));
GATED_OR GATED_OR_QKT_45(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[45]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[45]));
GATED_OR GATED_OR_QKT_46(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[46]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[46]));
GATED_OR GATED_OR_QKT_47(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[47]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[47]));
GATED_OR GATED_OR_QKT_48(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[48]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[48]));
GATED_OR GATED_OR_QKT_49(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[49]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[49]));
GATED_OR GATED_OR_QKT_50(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[50]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[50]));
GATED_OR GATED_OR_QKT_51(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[51]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[51]));
GATED_OR GATED_OR_QKT_52(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[52]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[52]));
GATED_OR GATED_OR_QKT_53(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[53]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[53]));
GATED_OR GATED_OR_QKT_54(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[54]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[54]));
GATED_OR GATED_OR_QKT_55(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[55]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[55]));
GATED_OR GATED_OR_QKT_56(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[56]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[56]));
GATED_OR GATED_OR_QKT_57(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[57]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[57]));
GATED_OR GATED_OR_QKT_58(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[58]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[58]));
GATED_OR GATED_OR_QKT_59(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[59]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[59]));
GATED_OR GATED_OR_QKT_60(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[60]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[60]));
GATED_OR GATED_OR_QKT_61(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[61]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[61]));
GATED_OR GATED_OR_QKT_62(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[62]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[62]));
GATED_OR GATED_OR_QKT_63(.CLOCK(clk), .SLEEP_CTRL(cg_en && sleep_ctrl_qkt[63]), .RST_N(rst_n), .CLOCK_GATED(clk_qkt[63]));

//==============================================//
//                  design                      //
//==============================================//
//==================================================================
// sleep_ctrl
//==================================================================
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_w <= 1'b0;
    else sleep_ctrl_w <= (next_state == OUT);
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_xw <= 1'b0;
    else sleep_ctrl_xw <= !(((next_state == XWQ) && (next_input_counter == 6'd63)) || 
                            ((next_state == XWK) && (next_input_counter <= 6'd8)) || 
                            ((next_state == XWV) && (next_input_counter >= 6'd56)) || 
                            ((next_state == OUT) && (next_output_counter <= 6'd2)));
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[0] <= 1'b0;
    else sleep_ctrl_qkt[0] <= !(((next_state == XWK) && (next_input_counter == 6'd57)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd1)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd2)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[1] <= 1'b0;
    else sleep_ctrl_qkt[1] <= !(((next_state == XWK) && (next_input_counter == 6'd57)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd2)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd3)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[2] <= 1'b0;
    else sleep_ctrl_qkt[2] <= !(((next_state == XWK) && (next_input_counter == 6'd57)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd3)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd4)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[3] <= 1'b0;
    else sleep_ctrl_qkt[3] <= !(((next_state == XWK) && (next_input_counter == 6'd57)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd4)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd5)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[4] <= 1'b0;
    else sleep_ctrl_qkt[4] <= !(((next_state == XWK) && (next_input_counter == 6'd57)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd5)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd6)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[5] <= 1'b0;
    else sleep_ctrl_qkt[5] <= !(((next_state == XWK) && (next_input_counter == 6'd57)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd6)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd7)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[6] <= 1'b0;
    else sleep_ctrl_qkt[6] <= !(((next_state == XWK) && (next_input_counter == 6'd57)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd7)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd8)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[7] <= 1'b0;
    else sleep_ctrl_qkt[7] <= !(((next_state == XWK) && (next_input_counter == 6'd57)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd8)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd9)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[8] <= 1'b0;
    else sleep_ctrl_qkt[8] <= !(((next_state == XWK) && (next_input_counter == 6'd58)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd1)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd10)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[9] <= 1'b0;
    else sleep_ctrl_qkt[9] <= !(((next_state == XWK) && (next_input_counter == 6'd58)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd2)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd11)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[10] <= 1'b0;
    else sleep_ctrl_qkt[10] <= !(((next_state == XWK) && (next_input_counter == 6'd58)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd3)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd12)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[11] <= 1'b0;
    else sleep_ctrl_qkt[11] <= !(((next_state == XWK) && (next_input_counter == 6'd58)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd4)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd13)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[12] <= 1'b0;
    else sleep_ctrl_qkt[12] <= !(((next_state == XWK) && (next_input_counter == 6'd58)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd5)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd14)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[13] <= 1'b0;
    else sleep_ctrl_qkt[13] <= !(((next_state == XWK) && (next_input_counter == 6'd58)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd6)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd15)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[14] <= 1'b0;
    else sleep_ctrl_qkt[14] <= !(((next_state == XWK) && (next_input_counter == 6'd58)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd7)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd16)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[15] <= 1'b0;
    else sleep_ctrl_qkt[15] <= !(((next_state == XWK) && (next_input_counter == 6'd58)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd8)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd17)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[16] <= 1'b0;
    else sleep_ctrl_qkt[16] <= !(((next_state == XWK) && (next_input_counter == 6'd59)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd1)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd18)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[17] <= 1'b0;
    else sleep_ctrl_qkt[17] <= !(((next_state == XWK) && (next_input_counter == 6'd59)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd2)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd19)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[18] <= 1'b0;
    else sleep_ctrl_qkt[18] <= !(((next_state == XWK) && (next_input_counter == 6'd59)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd3)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd20)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[19] <= 1'b0;
    else sleep_ctrl_qkt[19] <= !(((next_state == XWK) && (next_input_counter == 6'd59)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd4)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd21)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[20] <= 1'b0;
    else sleep_ctrl_qkt[20] <= !(((next_state == XWK) && (next_input_counter == 6'd59)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd5)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd22)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[21] <= 1'b0;
    else sleep_ctrl_qkt[21] <= !(((next_state == XWK) && (next_input_counter == 6'd59)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd6)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd23)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[22] <= 1'b0;
    else sleep_ctrl_qkt[22] <= !(((next_state == XWK) && (next_input_counter == 6'd59)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd7)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd24)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[23] <= 1'b0;
    else sleep_ctrl_qkt[23] <= !(((next_state == XWK) && (next_input_counter == 6'd59)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd8)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd25)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[24] <= 1'b0;
    else sleep_ctrl_qkt[24] <= !(((next_state == XWK) && (next_input_counter == 6'd60)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd1)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd26)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[25] <= 1'b0;
    else sleep_ctrl_qkt[25] <= !(((next_state == XWK) && (next_input_counter == 6'd60)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd2)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd27)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[26] <= 1'b0;
    else sleep_ctrl_qkt[26] <= !(((next_state == XWK) && (next_input_counter == 6'd60)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd3)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd28)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[27] <= 1'b0;
    else sleep_ctrl_qkt[27] <= !(((next_state == XWK) && (next_input_counter == 6'd60)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd4)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd29)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[28] <= 1'b0;
    else sleep_ctrl_qkt[28] <= !(((next_state == XWK) && (next_input_counter == 6'd60)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd5)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd30)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[29] <= 1'b0;
    else sleep_ctrl_qkt[29] <= !(((next_state == XWK) && (next_input_counter == 6'd60)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd6)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd31)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[30] <= 1'b0;
    else sleep_ctrl_qkt[30] <= !(((next_state == XWK) && (next_input_counter == 6'd60)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd7)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd32)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[31] <= 1'b0;
    else sleep_ctrl_qkt[31] <= !(((next_state == XWK) && (next_input_counter == 6'd60)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd8)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd33)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[32] <= 1'b0;
    else sleep_ctrl_qkt[32] <= !(((next_state == XWK) && (next_input_counter == 6'd61)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd1)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd34)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[33] <= 1'b0;
    else sleep_ctrl_qkt[33] <= !(((next_state == XWK) && (next_input_counter == 6'd61)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd2)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd35)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[34] <= 1'b0;
    else sleep_ctrl_qkt[34] <= !(((next_state == XWK) && (next_input_counter == 6'd61)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd3)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd36)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[35] <= 1'b0;
    else sleep_ctrl_qkt[35] <= !(((next_state == XWK) && (next_input_counter == 6'd61)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd4)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd37)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[36] <= 1'b0;
    else sleep_ctrl_qkt[36] <= !(((next_state == XWK) && (next_input_counter == 6'd61)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd5)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd38)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[37] <= 1'b0;
    else sleep_ctrl_qkt[37] <= !(((next_state == XWK) && (next_input_counter == 6'd61)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd6)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd39)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[38] <= 1'b0;
    else sleep_ctrl_qkt[38] <= !(((next_state == XWK) && (next_input_counter == 6'd61)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd7)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd40)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[39] <= 1'b0;
    else sleep_ctrl_qkt[39] <= !(((next_state == XWK) && (next_input_counter == 6'd61)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd8)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd41)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[40] <= 1'b0;
    else sleep_ctrl_qkt[40] <= !(((next_state == XWK) && (next_input_counter == 6'd62)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd1)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd42)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[41] <= 1'b0;
    else sleep_ctrl_qkt[41] <= !(((next_state == XWK) && (next_input_counter == 6'd62)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd2)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd43)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[42] <= 1'b0;
    else sleep_ctrl_qkt[42] <= !(((next_state == XWK) && (next_input_counter == 6'd62)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd3)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd44)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[43] <= 1'b0;
    else sleep_ctrl_qkt[43] <= !(((next_state == XWK) && (next_input_counter == 6'd62)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd4)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd45)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[44] <= 1'b0;
    else sleep_ctrl_qkt[44] <= !(((next_state == XWK) && (next_input_counter == 6'd62)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd5)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd46)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[45] <= 1'b0;
    else sleep_ctrl_qkt[45] <= !(((next_state == XWK) && (next_input_counter == 6'd62)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd6)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd47)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[46] <= 1'b0;
    else sleep_ctrl_qkt[46] <= !(((next_state == XWK) && (next_input_counter == 6'd62)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd7)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd48)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[47] <= 1'b0;
    else sleep_ctrl_qkt[47] <= !(((next_state == XWK) && (next_input_counter == 6'd62)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd8)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd49)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[48] <= 1'b0;
    else sleep_ctrl_qkt[48] <= !(((next_state == XWK) && (next_input_counter == 6'd63)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd1)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd50)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[49] <= 1'b0;
    else sleep_ctrl_qkt[49] <= !(((next_state == XWK) && (next_input_counter == 6'd63)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd2)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd51)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[50] <= 1'b0;
    else sleep_ctrl_qkt[50] <= !(((next_state == XWK) && (next_input_counter == 6'd63)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd3)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd52)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[51] <= 1'b0;
    else sleep_ctrl_qkt[51] <= !(((next_state == XWK) && (next_input_counter == 6'd63)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd4)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd53)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[52] <= 1'b0;
    else sleep_ctrl_qkt[52] <= !(((next_state == XWK) && (next_input_counter == 6'd63)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd5)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd54)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[53] <= 1'b0;
    else sleep_ctrl_qkt[53] <= !(((next_state == XWK) && (next_input_counter == 6'd63)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd6)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd55)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[54] <= 1'b0;
    else sleep_ctrl_qkt[54] <= !(((next_state == XWK) && (next_input_counter == 6'd63)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd7)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd56)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[55] <= 1'b0;
    else sleep_ctrl_qkt[55] <= !(((next_state == XWK) && (next_input_counter == 6'd63)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd8)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd57)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[56] <= 1'b0;
    else sleep_ctrl_qkt[56] <= !(((next_state == XWV) && (next_input_counter == 6'd0)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd1)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd58)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[57] <= 1'b0;
    else sleep_ctrl_qkt[57] <= !(((next_state == XWV) && (next_input_counter == 6'd0)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd2)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd59)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[58] <= 1'b0;
    else sleep_ctrl_qkt[58] <= !(((next_state == XWV) && (next_input_counter == 6'd0)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd3)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd60)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[59] <= 1'b0;
    else sleep_ctrl_qkt[59] <= !(((next_state == XWV) && (next_input_counter == 6'd0)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd4)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd61)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[60] <= 1'b0;
    else sleep_ctrl_qkt[60] <= !(((next_state == XWV) && (next_input_counter == 6'd0)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd5)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd62)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[61] <= 1'b0;
    else sleep_ctrl_qkt[61] <= !(((next_state == XWV) && (next_input_counter == 6'd0)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd6)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd63)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[62] <= 1'b0;
    else sleep_ctrl_qkt[62] <= !(((next_state == XWV) && (next_input_counter == 6'd0)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd7)) || 
                                ((next_state == OUT) && (next_output_counter == 6'd0)));
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) sleep_ctrl_qkt[63] <= 1'b0;
    else sleep_ctrl_qkt[63] <= !(((next_state == XWV) && (next_input_counter == 6'd0)) || 
                                ((next_state == XWV) && (next_input_counter == 6'd8)) || 
                                ((next_state == OUT) && (next_output_counter == 6'd1)));
end

//==================================================================
// sequential
//==================================================================
always @ (posedge clk_input_counter or negedge rst_n)
begin
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always @ (posedge clk_input_counter or negedge rst_n)
begin
    if(!rst_n) input_counter <= 6'd0;
    else input_counter <= next_input_counter;
end

always @ (posedge clk_input_counter or negedge rst_n)
begin
    if(!rst_n) output_counter <= 6'd0;
    else output_counter <= next_output_counter;
end

always @ (posedge clk_input_counter or negedge rst_n)
begin
    if(!rst_n) t_reg <= 4'd0;
    else t_reg <= next_t_reg;
end

always @ (posedge clk_in_data or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i = 0; i < 64; i = i+1)
        begin
            in_data_reg[i] <= 8'd0;
        end
    end
    else
    begin
        for(i = 0; i < 64; i = i+1)
        begin
            in_data_reg[i] <= next_in_data_reg[i];
        end
    end
end


always @ (posedge clk_w or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i = 0; i < 64; i = i+1)
        begin
            w_reg[i] <= 8'd0;
        end
    end
    else
    begin
        for(i = 0; i < 64; i = i+1)
        begin
            w_reg[i] <= next_w_reg[i];
        end
    end
end

always @ (posedge clk_xw_0 or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i = 0; i < 64; i = i+1)
        begin
            xw_reg[i][6:0] <= 7'd0;
        end
    end
    else
    begin
        for(i = 0; i < 64; i = i+1)
        begin
            xw_reg[i][6:0] <= next_xw_reg[i][6:0];
        end
    end
end

always @ (posedge clk_xw_1 or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i = 0; i < 64; i = i+1)
        begin
            xw_reg[i][12:7] <= 6'd0;
        end
    end
    else
    begin
        for(i = 0; i < 64; i = i+1)
        begin
            xw_reg[i][12:7] <= next_xw_reg[i][12:7];
        end
    end
end

always @ (posedge clk_xw_2 or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i = 0; i < 64; i = i+1)
        begin
            xw_reg[i][18:13] <= 6'd0;
        end
    end
    else
    begin
        for(i = 0; i < 64; i = i+1)
        begin
            xw_reg[i][18:13] <= next_xw_reg[i][18:13];
        end
    end
end

/*always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i = 0; i < 64; i = i+1)
        begin
            qkt_reg[i] <= 41'd0;
        end
    end
    else
    begin
        for(i = 0; i < 64; i = i+1)
        begin
            qkt_reg[i] <= next_qkt_reg[i];
        end
    end
end*/

always @ (posedge clk_qkt[0] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[0] <= 41'd0;
    else qkt_reg[0] <= next_qkt_reg[0];
end
always @ (posedge clk_qkt[1] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[1] <= 41'd0;
    else qkt_reg[1] <= next_qkt_reg[1];
end
always @ (posedge clk_qkt[2] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[2] <= 41'd0;
    else qkt_reg[2] <= next_qkt_reg[2];
end
always @ (posedge clk_qkt[3] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[3] <= 41'd0;
    else qkt_reg[3] <= next_qkt_reg[3];
end
always @ (posedge clk_qkt[4] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[4] <= 41'd0;
    else qkt_reg[4] <= next_qkt_reg[4];
end
always @ (posedge clk_qkt[5] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[5] <= 41'd0;
    else qkt_reg[5] <= next_qkt_reg[5];
end
always @ (posedge clk_qkt[6] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[6] <= 41'd0;
    else qkt_reg[6] <= next_qkt_reg[6];
end
always @ (posedge clk_qkt[7] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[7] <= 41'd0;
    else qkt_reg[7] <= next_qkt_reg[7];
end
always @ (posedge clk_qkt[8] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[8] <= 41'd0;
    else qkt_reg[8] <= next_qkt_reg[8];
end
always @ (posedge clk_qkt[9] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[9] <= 41'd0;
    else qkt_reg[9] <= next_qkt_reg[9];
end
always @ (posedge clk_qkt[10] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[10] <= 41'd0;
    else qkt_reg[10] <= next_qkt_reg[10];
end
always @ (posedge clk_qkt[11] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[11] <= 41'd0;
    else qkt_reg[11] <= next_qkt_reg[11];
end
always @ (posedge clk_qkt[12] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[12] <= 41'd0;
    else qkt_reg[12] <= next_qkt_reg[12];
end
always @ (posedge clk_qkt[13] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[13] <= 41'd0;
    else qkt_reg[13] <= next_qkt_reg[13];
end
always @ (posedge clk_qkt[14] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[14] <= 41'd0;
    else qkt_reg[14] <= next_qkt_reg[14];
end
always @ (posedge clk_qkt[15] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[15] <= 41'd0;
    else qkt_reg[15] <= next_qkt_reg[15];
end
always @ (posedge clk_qkt[16] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[16] <= 41'd0;
    else qkt_reg[16] <= next_qkt_reg[16];
end
always @ (posedge clk_qkt[17] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[17] <= 41'd0;
    else qkt_reg[17] <= next_qkt_reg[17];
end
always @ (posedge clk_qkt[18] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[18] <= 41'd0;
    else qkt_reg[18] <= next_qkt_reg[18];
end
always @ (posedge clk_qkt[19] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[19] <= 41'd0;
    else qkt_reg[19] <= next_qkt_reg[19];
end
always @ (posedge clk_qkt[20] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[20] <= 41'd0;
    else qkt_reg[20] <= next_qkt_reg[20];
end
always @ (posedge clk_qkt[21] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[21] <= 41'd0;
    else qkt_reg[21] <= next_qkt_reg[21];
end
always @ (posedge clk_qkt[22] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[22] <= 41'd0;
    else qkt_reg[22] <= next_qkt_reg[22];
end
always @ (posedge clk_qkt[23] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[23] <= 41'd0;
    else qkt_reg[23] <= next_qkt_reg[23];
end
always @ (posedge clk_qkt[24] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[24] <= 41'd0;
    else qkt_reg[24] <= next_qkt_reg[24];
end
always @ (posedge clk_qkt[25] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[25] <= 41'd0;
    else qkt_reg[25] <= next_qkt_reg[25];
end
always @ (posedge clk_qkt[26] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[26] <= 41'd0;
    else qkt_reg[26] <= next_qkt_reg[26];
end
always @ (posedge clk_qkt[27] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[27] <= 41'd0;
    else qkt_reg[27] <= next_qkt_reg[27];
end
always @ (posedge clk_qkt[28] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[28] <= 41'd0;
    else qkt_reg[28] <= next_qkt_reg[28];
end
always @ (posedge clk_qkt[29] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[29] <= 41'd0;
    else qkt_reg[29] <= next_qkt_reg[29];
end
always @ (posedge clk_qkt[30] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[30] <= 41'd0;
    else qkt_reg[30] <= next_qkt_reg[30];
end
always @ (posedge clk_qkt[31] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[31] <= 41'd0;
    else qkt_reg[31] <= next_qkt_reg[31];
end
always @ (posedge clk_qkt[32] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[32] <= 41'd0;
    else qkt_reg[32] <= next_qkt_reg[32];
end
always @ (posedge clk_qkt[33] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[33] <= 41'd0;
    else qkt_reg[33] <= next_qkt_reg[33];
end
always @ (posedge clk_qkt[34] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[34] <= 41'd0;
    else qkt_reg[34] <= next_qkt_reg[34];
end
always @ (posedge clk_qkt[35] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[35] <= 41'd0;
    else qkt_reg[35] <= next_qkt_reg[35];
end
always @ (posedge clk_qkt[36] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[36] <= 41'd0;
    else qkt_reg[36] <= next_qkt_reg[36];
end
always @ (posedge clk_qkt[37] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[37] <= 41'd0;
    else qkt_reg[37] <= next_qkt_reg[37];
end
always @ (posedge clk_qkt[38] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[38] <= 41'd0;
    else qkt_reg[38] <= next_qkt_reg[38];
end
always @ (posedge clk_qkt[39] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[39] <= 41'd0;
    else qkt_reg[39] <= next_qkt_reg[39];
end
always @ (posedge clk_qkt[40] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[40] <= 41'd0;
    else qkt_reg[40] <= next_qkt_reg[40];
end
always @ (posedge clk_qkt[41] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[41] <= 41'd0;
    else qkt_reg[41] <= next_qkt_reg[41];
end
always @ (posedge clk_qkt[42] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[42] <= 41'd0;
    else qkt_reg[42] <= next_qkt_reg[42];
end
always @ (posedge clk_qkt[43] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[43] <= 41'd0;
    else qkt_reg[43] <= next_qkt_reg[43];
end
always @ (posedge clk_qkt[44] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[44] <= 41'd0;
    else qkt_reg[44] <= next_qkt_reg[44];
end
always @ (posedge clk_qkt[45] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[45] <= 41'd0;
    else qkt_reg[45] <= next_qkt_reg[45];
end
always @ (posedge clk_qkt[46] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[46] <= 41'd0;
    else qkt_reg[46] <= next_qkt_reg[46];
end
always @ (posedge clk_qkt[47] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[47] <= 41'd0;
    else qkt_reg[47] <= next_qkt_reg[47];
end
always @ (posedge clk_qkt[48] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[48] <= 41'd0;
    else qkt_reg[48] <= next_qkt_reg[48];
end
always @ (posedge clk_qkt[49] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[49] <= 41'd0;
    else qkt_reg[49] <= next_qkt_reg[49];
end
always @ (posedge clk_qkt[50] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[50] <= 41'd0;
    else qkt_reg[50] <= next_qkt_reg[50];
end
always @ (posedge clk_qkt[51] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[51] <= 41'd0;
    else qkt_reg[51] <= next_qkt_reg[51];
end
always @ (posedge clk_qkt[52] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[52] <= 41'd0;
    else qkt_reg[52] <= next_qkt_reg[52];
end
always @ (posedge clk_qkt[53] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[53] <= 41'd0;
    else qkt_reg[53] <= next_qkt_reg[53];
end
always @ (posedge clk_qkt[54] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[54] <= 41'd0;
    else qkt_reg[54] <= next_qkt_reg[54];
end
always @ (posedge clk_qkt[55] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[55] <= 41'd0;
    else qkt_reg[55] <= next_qkt_reg[55];
end
always @ (posedge clk_qkt[56] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[56] <= 41'd0;
    else qkt_reg[56] <= next_qkt_reg[56];
end
always @ (posedge clk_qkt[57] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[57] <= 41'd0;
    else qkt_reg[57] <= next_qkt_reg[57];
end
always @ (posedge clk_qkt[58] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[58] <= 41'd0;
    else qkt_reg[58] <= next_qkt_reg[58];
end
always @ (posedge clk_qkt[59] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[59] <= 41'd0;
    else qkt_reg[59] <= next_qkt_reg[59];
end
always @ (posedge clk_qkt[60] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[60] <= 41'd0;
    else qkt_reg[60] <= next_qkt_reg[60];
end
always @ (posedge clk_qkt[61] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[61] <= 41'd0;
    else qkt_reg[61] <= next_qkt_reg[61];
end
always @ (posedge clk_qkt[62] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[62] <= 41'd0;
    else qkt_reg[62] <= next_qkt_reg[62];
end
always @ (posedge clk_qkt[63] or negedge rst_n)
begin
    if(!rst_n) qkt_reg[63] <= 41'd0;
    else qkt_reg[63] <= next_qkt_reg[63];
end

always @ (posedge clk_input_counter or negedge rst_n)
begin
    if(!rst_n) out_data_reg <= 64'd0;
    else out_data_reg <= next_out_data_reg;
end

//==================================================================
// next_state
//==================================================================
always @ (*)
begin
    case(state)
    IDLE:
    begin
        if(in_valid) next_state = XWQ;
        else next_state = IDLE;
    end
    XWQ:
    begin
        if(input_counter == 6'd63) next_state = XWK;
        else next_state = XWQ;
    end
    XWK:
    begin
        if(input_counter == 6'd63) next_state = XWV;
        else next_state = XWK;
    end
    XWV:
    begin
        if(input_counter == 6'd63) next_state = WAIT;
        else next_state = XWV;
    end
    WAIT:
    begin
        next_state = OUT;
    end
    OUT:
    begin
        if(output_counter == (t_reg_shift - 1)) next_state = IDLE;
        else next_state = OUT;
    end
    default:
    begin
        next_state = IDLE;
    end
    endcase
end

//==================================================================
// counter
//==================================================================
always @ (*)
begin
    if(in_valid)
    begin
        if(input_counter == 6'd63) next_input_counter = 6'd0;
        else next_input_counter = input_counter + 6'd1;
    end
    else next_input_counter = 6'd0;
end

always @ (*)
begin
    if(out_valid)
    begin
        if(output_counter == 6'd63) next_output_counter = 6'd0;
        else next_output_counter = output_counter + 6'd1;
    end
    else next_output_counter = 6'd0;
end

//==================================================================
// next_t_reg
//==================================================================
always @ (*)
begin
    if((state == IDLE) && in_valid) next_t_reg = T;
    else next_t_reg = t_reg;
end

//==================================================================
// next_in_data_reg
//==================================================================
always @ (*)
begin
    //t_reg_shift = t_reg << 3;
    case(t_reg)
    4'd1: t_reg_shift = 7'd8;
    4'd4: t_reg_shift = 7'd32;
    default: t_reg_shift = 7'd64;
    endcase
    //if(t_reg == 4'd1) t_reg_shift = 7'd8;
    //else if(t_reg == 4'd4) t_reg_shift = 7'd32;
    //else t_reg_shift = 7'd64;
end

always @ (*)
begin
    for(i = 0; i < 64; i = i+1)
    begin
        next_in_data_reg[i] = in_data_reg[i];
    end
    //if(in_valid && ((state == IDLE) || (state == XWQ)))
    //begin
    //    if(input_counter < t_reg_shift) next_in_data_reg[input_counter] = in_data;
    //    else next_in_data_reg[input_counter] = 8'd0;
    //end
    if(((state == IDLE) || (state == XWQ)))
    begin
        if(in_valid && (input_counter < t_reg_shift)) next_in_data_reg[input_counter] = in_data;
        else next_in_data_reg[input_counter] = 8'd0;
    end
end

//==================================================================
// next_w_reg
//==================================================================
always @ (*)
begin
    for(i = 0; i < 64; i = i+1)
    begin
        next_w_reg[i] = w_reg[i];
    end
    if(in_valid)
    begin
        case(state)
        IDLE: next_w_reg[0] = w_Q;
        XWQ: next_w_reg[input_counter] = w_Q;
        XWK: next_w_reg[input_counter] = w_K;
        XWV: next_w_reg[input_counter] = w_V;
        endcase
    end
end

//==================================================================
// next_xw_reg
//==================================================================
always @ (*)
begin
    for(i = 0; i < 64; i = i+1)
    begin
        next_xw_reg[i] = xw_reg[i];
    end
    case(state)
    XWK:
    begin
        case(input_counter)
        6'd0:
        begin
            next_xw_reg[0] = mult_0_z[18:0];
            next_xw_reg[8] = mult_1_z[18:0];
            next_xw_reg[16] = mult_2_z[18:0];
            next_xw_reg[24] = mult_3_z[18:0];
            next_xw_reg[32] = mult_4_z[18:0];
            next_xw_reg[40] = mult_5_z[18:0];
            next_xw_reg[48] = mult_6_z[18:0];
            next_xw_reg[56] = mult_7_z[18:0];
        end
        6'd1:
        begin
            next_xw_reg[1] = mult_0_z[18:0];
            next_xw_reg[9] = mult_1_z[18:0];
            next_xw_reg[17] = mult_2_z[18:0];
            next_xw_reg[25] = mult_3_z[18:0];
            next_xw_reg[33] = mult_4_z[18:0];
            next_xw_reg[41] = mult_5_z[18:0];
            next_xw_reg[49] = mult_6_z[18:0];
            next_xw_reg[57] = mult_7_z[18:0];
        end
        6'd2:
        begin
            next_xw_reg[2] = mult_0_z[18:0];
            next_xw_reg[10] = mult_1_z[18:0];
            next_xw_reg[18] = mult_2_z[18:0];
            next_xw_reg[26] = mult_3_z[18:0];
            next_xw_reg[34] = mult_4_z[18:0];
            next_xw_reg[42] = mult_5_z[18:0];
            next_xw_reg[50] = mult_6_z[18:0];
            next_xw_reg[58] = mult_7_z[18:0];
        end
        6'd3:
        begin
            next_xw_reg[3] = mult_0_z[18:0];
            next_xw_reg[11] = mult_1_z[18:0];
            next_xw_reg[19] = mult_2_z[18:0];
            next_xw_reg[27] = mult_3_z[18:0];
            next_xw_reg[35] = mult_4_z[18:0];
            next_xw_reg[43] = mult_5_z[18:0];
            next_xw_reg[51] = mult_6_z[18:0];
            next_xw_reg[59] = mult_7_z[18:0];
        end
        6'd4:
        begin
            next_xw_reg[4] = mult_0_z[18:0];
            next_xw_reg[12] = mult_1_z[18:0];
            next_xw_reg[20] = mult_2_z[18:0];
            next_xw_reg[28] = mult_3_z[18:0];
            next_xw_reg[36] = mult_4_z[18:0];
            next_xw_reg[44] = mult_5_z[18:0];
            next_xw_reg[52] = mult_6_z[18:0];
            next_xw_reg[60] = mult_7_z[18:0];
        end
        6'd5:
        begin
            next_xw_reg[5] = mult_0_z[18:0];
            next_xw_reg[13] = mult_1_z[18:0];
            next_xw_reg[21] = mult_2_z[18:0];
            next_xw_reg[29] = mult_3_z[18:0];
            next_xw_reg[37] = mult_4_z[18:0];
            next_xw_reg[45] = mult_5_z[18:0];
            next_xw_reg[53] = mult_6_z[18:0];
            next_xw_reg[61] = mult_7_z[18:0];
        end
        6'd6:
        begin
            next_xw_reg[6] = mult_0_z[18:0];
            next_xw_reg[14] = mult_1_z[18:0];
            next_xw_reg[22] = mult_2_z[18:0];
            next_xw_reg[30] = mult_3_z[18:0];
            next_xw_reg[38] = mult_4_z[18:0];
            next_xw_reg[46] = mult_5_z[18:0];
            next_xw_reg[54] = mult_6_z[18:0];
            next_xw_reg[62] = mult_7_z[18:0];
        end
        6'd7:
        begin
            next_xw_reg[7] = mult_0_z[18:0];
            next_xw_reg[15] = mult_1_z[18:0];
            next_xw_reg[23] = mult_2_z[18:0];
            next_xw_reg[31] = mult_3_z[18:0];
            next_xw_reg[39] = mult_4_z[18:0];
            next_xw_reg[47] = mult_5_z[18:0];
            next_xw_reg[55] = mult_6_z[18:0];
            next_xw_reg[63] = mult_7_z[18:0];
        end
        endcase
    end
    XWV:
    begin
        case(input_counter)
        6'd57:
        begin
            next_xw_reg[0] = mult_0_z[18:0];
            next_xw_reg[8] = mult_1_z[18:0];
            next_xw_reg[16] = mult_2_z[18:0];
            next_xw_reg[24] = mult_3_z[18:0];
            next_xw_reg[32] = mult_4_z[18:0];
            next_xw_reg[40] = mult_5_z[18:0];
            next_xw_reg[48] = mult_6_z[18:0];
            next_xw_reg[56] = mult_7_z[18:0];
        end
        6'd58:
        begin
            next_xw_reg[1] = mult_0_z[18:0];
            next_xw_reg[9] = mult_1_z[18:0];
            next_xw_reg[17] = mult_2_z[18:0];
            next_xw_reg[25] = mult_3_z[18:0];
            next_xw_reg[33] = mult_4_z[18:0];
            next_xw_reg[41] = mult_5_z[18:0];
            next_xw_reg[49] = mult_6_z[18:0];
            next_xw_reg[57] = mult_7_z[18:0];
        end
        6'd59:
        begin
            next_xw_reg[2] = mult_0_z[18:0];
            next_xw_reg[10] = mult_1_z[18:0];
            next_xw_reg[18] = mult_2_z[18:0];
            next_xw_reg[26] = mult_3_z[18:0];
            next_xw_reg[34] = mult_4_z[18:0];
            next_xw_reg[42] = mult_5_z[18:0];
            next_xw_reg[50] = mult_6_z[18:0];
            next_xw_reg[58] = mult_7_z[18:0];
        end
        6'd60:
        begin
            next_xw_reg[3] = mult_0_z[18:0];
            next_xw_reg[11] = mult_1_z[18:0];
            next_xw_reg[19] = mult_2_z[18:0];
            next_xw_reg[27] = mult_3_z[18:0];
            next_xw_reg[35] = mult_4_z[18:0];
            next_xw_reg[43] = mult_5_z[18:0];
            next_xw_reg[51] = mult_6_z[18:0];
            next_xw_reg[59] = mult_7_z[18:0];
        end
        6'd61:
        begin
            next_xw_reg[4] = mult_0_z[18:0];
            next_xw_reg[12] = mult_1_z[18:0];
            next_xw_reg[20] = mult_2_z[18:0];
            next_xw_reg[28] = mult_3_z[18:0];
            next_xw_reg[36] = mult_4_z[18:0];
            next_xw_reg[44] = mult_5_z[18:0];
            next_xw_reg[52] = mult_6_z[18:0];
            next_xw_reg[60] = mult_7_z[18:0];
        end
        6'd62:
        begin
            next_xw_reg[5] = mult_0_z[18:0];
            next_xw_reg[13] = mult_1_z[18:0];
            next_xw_reg[21] = mult_2_z[18:0];
            next_xw_reg[29] = mult_3_z[18:0];
            next_xw_reg[37] = mult_4_z[18:0];
            next_xw_reg[45] = mult_5_z[18:0];
            next_xw_reg[53] = mult_6_z[18:0];
            next_xw_reg[61] = mult_7_z[18:0];
        end
        6'd63:
        begin
            next_xw_reg[6] = mult_0_z[18:0];
            next_xw_reg[14] = mult_1_z[18:0];
            next_xw_reg[22] = mult_2_z[18:0];
            next_xw_reg[30] = mult_3_z[18:0];
            next_xw_reg[38] = mult_4_z[18:0];
            next_xw_reg[46] = mult_5_z[18:0];
            next_xw_reg[54] = mult_6_z[18:0];
        end
        endcase
    end
    OUT:
    begin
        if(output_counter == 6'd0)
        begin
            next_xw_reg[7] = mult_0_z[18:0];
            next_xw_reg[15] = mult_1_z[18:0];
            next_xw_reg[23] = mult_2_z[18:0];
            next_xw_reg[31] = mult_3_z[18:0];
            next_xw_reg[39] = mult_4_z[18:0];
            next_xw_reg[47] = mult_5_z[18:0];
            next_xw_reg[55] = mult_6_z[18:0];
        end
        else if(output_counter == 6'd1)
        begin
            next_xw_reg[62] = mult_0_z[18:0];
            next_xw_reg[63] = mult_1_z[18:0];
        end
    end
    endcase
end

//==================================================================
// next_qkt_reg
//==================================================================
always @ (*)
begin
    for(i = 0; i < 64; i = i+1)
    begin
        next_qkt_reg[i] = qkt_reg[i];
    end
    case(state)
    XWK:
    begin
        case(input_counter)
        6'd57:
        begin
            next_qkt_reg[0][18:0] = mult_0_z[18:0];
            next_qkt_reg[1][18:0] = mult_1_z[18:0];
            next_qkt_reg[2][18:0] = mult_2_z[18:0];
            next_qkt_reg[3][18:0] = mult_3_z[18:0];
            next_qkt_reg[4][18:0] = mult_4_z[18:0];
            next_qkt_reg[5][18:0] = mult_5_z[18:0];
            next_qkt_reg[6][18:0] = mult_6_z[18:0];
            next_qkt_reg[7][18:0] = mult_7_z[18:0];
        end
        6'd58:
        begin
            next_qkt_reg[8][18:0] = mult_0_z[18:0];
            next_qkt_reg[9][18:0] = mult_1_z[18:0];
            next_qkt_reg[10][18:0] = mult_2_z[18:0];
            next_qkt_reg[11][18:0] = mult_3_z[18:0];
            next_qkt_reg[12][18:0] = mult_4_z[18:0];
            next_qkt_reg[13][18:0] = mult_5_z[18:0];
            next_qkt_reg[14][18:0] = mult_6_z[18:0];
            next_qkt_reg[15][18:0] = mult_7_z[18:0];
        end
        6'd59:
        begin
            next_qkt_reg[16][18:0] = mult_0_z[18:0];
            next_qkt_reg[17][18:0] = mult_1_z[18:0];
            next_qkt_reg[18][18:0] = mult_2_z[18:0];
            next_qkt_reg[19][18:0] = mult_3_z[18:0];
            next_qkt_reg[20][18:0] = mult_4_z[18:0];
            next_qkt_reg[21][18:0] = mult_5_z[18:0];
            next_qkt_reg[22][18:0] = mult_6_z[18:0];
            next_qkt_reg[23][18:0] = mult_7_z[18:0];
        end
        6'd60:
        begin
            next_qkt_reg[24][18:0] = mult_0_z[18:0];
            next_qkt_reg[25][18:0] = mult_1_z[18:0];
            next_qkt_reg[26][18:0] = mult_2_z[18:0];
            next_qkt_reg[27][18:0] = mult_3_z[18:0];
            next_qkt_reg[28][18:0] = mult_4_z[18:0];
            next_qkt_reg[29][18:0] = mult_5_z[18:0];
            next_qkt_reg[30][18:0] = mult_6_z[18:0];
            next_qkt_reg[31][18:0] = mult_7_z[18:0];
        end
        6'd61:
        begin
            next_qkt_reg[32][18:0] = mult_0_z[18:0];
            next_qkt_reg[33][18:0] = mult_1_z[18:0];
            next_qkt_reg[34][18:0] = mult_2_z[18:0];
            next_qkt_reg[35][18:0] = mult_3_z[18:0];
            next_qkt_reg[36][18:0] = mult_4_z[18:0];
            next_qkt_reg[37][18:0] = mult_5_z[18:0];
            next_qkt_reg[38][18:0] = mult_6_z[18:0];
            next_qkt_reg[39][18:0] = mult_7_z[18:0];
        end
        6'd62:
        begin
            next_qkt_reg[40][18:0] = mult_0_z[18:0];
            next_qkt_reg[41][18:0] = mult_1_z[18:0];
            next_qkt_reg[42][18:0] = mult_2_z[18:0];
            next_qkt_reg[43][18:0] = mult_3_z[18:0];
            next_qkt_reg[44][18:0] = mult_4_z[18:0];
            next_qkt_reg[45][18:0] = mult_5_z[18:0];
            next_qkt_reg[46][18:0] = mult_6_z[18:0];
            next_qkt_reg[47][18:0] = mult_7_z[18:0];
        end
        6'd63:
        begin
            next_qkt_reg[48][18:0] = mult_0_z[18:0];
            next_qkt_reg[49][18:0] = mult_1_z[18:0];
            next_qkt_reg[50][18:0] = mult_2_z[18:0];
            next_qkt_reg[51][18:0] = mult_3_z[18:0];
            next_qkt_reg[52][18:0] = mult_4_z[18:0];
            next_qkt_reg[53][18:0] = mult_5_z[18:0];
            next_qkt_reg[54][18:0] = mult_6_z[18:0];
            next_qkt_reg[55][18:0] = mult_7_z[18:0];
        end
        endcase
    end
    XWV:
    begin
        case(input_counter)
        6'd0:
        begin
            next_qkt_reg[56][18:0] = mult_0_z[18:0];
            next_qkt_reg[57][18:0] = mult_1_z[18:0];
            next_qkt_reg[58][18:0] = mult_2_z[18:0];
            next_qkt_reg[59][18:0] = mult_3_z[18:0];
            next_qkt_reg[60][18:0] = mult_4_z[18:0];
            next_qkt_reg[61][18:0] = mult_5_z[18:0];
            next_qkt_reg[62][18:0] = mult_6_z[18:0];
            next_qkt_reg[63][18:0] = mult_7_z[18:0];
        end
        6'd1:
        begin
            next_qkt_reg[0] = mult_0_z;
            next_qkt_reg[8] = mult_1_z;
            next_qkt_reg[16] = mult_2_z;
            next_qkt_reg[24] = mult_3_z;
            next_qkt_reg[32] = mult_4_z;
            next_qkt_reg[40] = mult_5_z;
            next_qkt_reg[48] = mult_6_z;
            next_qkt_reg[56] = mult_7_z[40:0];
        end
        6'd2:
        begin
            next_qkt_reg[1] = mult_0_z;
            next_qkt_reg[9] = mult_1_z;
            next_qkt_reg[17] = mult_2_z;
            next_qkt_reg[25] = mult_3_z;
            next_qkt_reg[33] = mult_4_z;
            next_qkt_reg[41] = mult_5_z;
            next_qkt_reg[49] = mult_6_z;
            next_qkt_reg[57] = mult_7_z[40:0];
        end
        6'd3:
        begin
            next_qkt_reg[2] = mult_0_z;
            next_qkt_reg[10] = mult_1_z;
            next_qkt_reg[18] = mult_2_z;
            next_qkt_reg[26] = mult_3_z;
            next_qkt_reg[34] = mult_4_z;
            next_qkt_reg[42] = mult_5_z;
            next_qkt_reg[50] = mult_6_z;
            next_qkt_reg[58] = mult_7_z[40:0];
        end
        6'd4:
        begin
            next_qkt_reg[3] = mult_0_z;
            next_qkt_reg[11] = mult_1_z;
            next_qkt_reg[19] = mult_2_z;
            next_qkt_reg[27] = mult_3_z;
            next_qkt_reg[35] = mult_4_z;
            next_qkt_reg[43] = mult_5_z;
            next_qkt_reg[51] = mult_6_z;
            next_qkt_reg[59] = mult_7_z[40:0];
        end
        6'd5:
        begin
            next_qkt_reg[4] = mult_0_z;
            next_qkt_reg[12] = mult_1_z;
            next_qkt_reg[20] = mult_2_z;
            next_qkt_reg[28] = mult_3_z;
            next_qkt_reg[36] = mult_4_z;
            next_qkt_reg[44] = mult_5_z;
            next_qkt_reg[52] = mult_6_z;
            next_qkt_reg[60] = mult_7_z[40:0];
        end
        6'd6:
        begin
            next_qkt_reg[5] = mult_0_z;
            next_qkt_reg[13] = mult_1_z;
            next_qkt_reg[21] = mult_2_z;
            next_qkt_reg[29] = mult_3_z;
            next_qkt_reg[37] = mult_4_z;
            next_qkt_reg[45] = mult_5_z;
            next_qkt_reg[53] = mult_6_z;
            next_qkt_reg[61] = mult_7_z[40:0];
        end
        6'd7:
        begin
            next_qkt_reg[6] = mult_0_z;
            next_qkt_reg[14] = mult_1_z;
            next_qkt_reg[22] = mult_2_z;
            next_qkt_reg[30] = mult_3_z;
            next_qkt_reg[38] = mult_4_z;
            next_qkt_reg[46] = mult_5_z;
            next_qkt_reg[54] = mult_6_z;
            next_qkt_reg[62] = mult_7_z[40:0];
        end
        6'd8:
        begin
            next_qkt_reg[7] = mult_0_z;
            next_qkt_reg[15] = mult_1_z;
            next_qkt_reg[23] = mult_2_z;
            next_qkt_reg[31] = mult_3_z;
            next_qkt_reg[39] = mult_4_z;
            next_qkt_reg[47] = mult_5_z;
            next_qkt_reg[55] = mult_6_z;
            next_qkt_reg[63] = mult_7_z[40:0];
        end
        endcase
        case(input_counter)
        6'd2: next_qkt_reg[0] = scale_relu_z;
        6'd3: next_qkt_reg[1] = scale_relu_z;
        6'd4: next_qkt_reg[2] = scale_relu_z;
        6'd5: next_qkt_reg[3] = scale_relu_z;
        6'd6: next_qkt_reg[4] = scale_relu_z;
        6'd7: next_qkt_reg[5] = scale_relu_z;
        6'd8: next_qkt_reg[6] = scale_relu_z;
        6'd9: next_qkt_reg[7] = scale_relu_z;
        6'd10: next_qkt_reg[8] = scale_relu_z;
        6'd11: next_qkt_reg[9] = scale_relu_z;
        6'd12: next_qkt_reg[10] = scale_relu_z;
        6'd13: next_qkt_reg[11] = scale_relu_z;
        6'd14: next_qkt_reg[12] = scale_relu_z;
        6'd15: next_qkt_reg[13] = scale_relu_z;
        6'd16: next_qkt_reg[14] = scale_relu_z;
        6'd17: next_qkt_reg[15] = scale_relu_z;
        6'd18: next_qkt_reg[16] = scale_relu_z;
        6'd19: next_qkt_reg[17] = scale_relu_z;
        6'd20: next_qkt_reg[18] = scale_relu_z;
        6'd21: next_qkt_reg[19] = scale_relu_z;
        6'd22: next_qkt_reg[20] = scale_relu_z;
        6'd23: next_qkt_reg[21] = scale_relu_z;
        6'd24: next_qkt_reg[22] = scale_relu_z;
        6'd25: next_qkt_reg[23] = scale_relu_z;
        6'd26: next_qkt_reg[24] = scale_relu_z;
        6'd27: next_qkt_reg[25] = scale_relu_z;
        6'd28: next_qkt_reg[26] = scale_relu_z;
        6'd29: next_qkt_reg[27] = scale_relu_z;
        6'd30: next_qkt_reg[28] = scale_relu_z;
        6'd31: next_qkt_reg[29] = scale_relu_z;
        6'd32: next_qkt_reg[30] = scale_relu_z;
        6'd33: next_qkt_reg[31] = scale_relu_z;
        6'd34: next_qkt_reg[32] = scale_relu_z;
        6'd35: next_qkt_reg[33] = scale_relu_z;
        6'd36: next_qkt_reg[34] = scale_relu_z;
        6'd37: next_qkt_reg[35] = scale_relu_z;
        6'd38: next_qkt_reg[36] = scale_relu_z;
        6'd39: next_qkt_reg[37] = scale_relu_z;
        6'd40: next_qkt_reg[38] = scale_relu_z;
        6'd41: next_qkt_reg[39] = scale_relu_z;
        6'd42: next_qkt_reg[40] = scale_relu_z;
        6'd43: next_qkt_reg[41] = scale_relu_z;
        6'd44: next_qkt_reg[42] = scale_relu_z;
        6'd45: next_qkt_reg[43] = scale_relu_z;
        6'd46: next_qkt_reg[44] = scale_relu_z;
        6'd47: next_qkt_reg[45] = scale_relu_z;
        6'd48: next_qkt_reg[46] = scale_relu_z;
        6'd49: next_qkt_reg[47] = scale_relu_z;
        6'd50: next_qkt_reg[48] = scale_relu_z;
        6'd51: next_qkt_reg[49] = scale_relu_z;
        6'd52: next_qkt_reg[50] = scale_relu_z;
        6'd53: next_qkt_reg[51] = scale_relu_z;
        6'd54: next_qkt_reg[52] = scale_relu_z;
        6'd55: next_qkt_reg[53] = scale_relu_z;
        6'd56: next_qkt_reg[54] = scale_relu_z;
        6'd57: next_qkt_reg[55] = scale_relu_z;
        6'd58: next_qkt_reg[56] = scale_relu_z;
        6'd59: next_qkt_reg[57] = scale_relu_z;
        6'd60: next_qkt_reg[58] = scale_relu_z;
        6'd61: next_qkt_reg[59] = scale_relu_z;
        6'd62: next_qkt_reg[60] = scale_relu_z;
        6'd63: next_qkt_reg[61] = scale_relu_z;
        endcase
    end
    OUT:
    begin
        case(output_counter)
        6'd0: next_qkt_reg[62] = scale_relu_z;
        6'd1: next_qkt_reg[63] = scale_relu_z;
        endcase
    end
    endcase
end

//==================================================================
// multiplier
//==================================================================
multiplier_19 multiplier_0
(
    .m0_a(mult_0_a[0]), .m1_a(mult_0_a[1]), .m2_a(mult_0_a[2]), .m3_a(mult_0_a[3]), 
    .m4_a(mult_0_a[4]), .m5_a(mult_0_a[5]), .m6_a(mult_0_a[6]), .m7_a(mult_0_a[7]), 
    .m0_b(mult_0_b[0]), .m1_b(mult_0_b[1]), .m2_b(mult_0_b[2]), .m3_b(mult_0_b[3]), 
    .m4_b(mult_0_b[4]), .m5_b(mult_0_b[5]), .m6_b(mult_0_b[6]), .m7_b(mult_0_b[7]), 
    .z(mult_0_z)
);
multiplier_19 multiplier_1
(
    .m0_a(mult_1_a[0]), .m1_a(mult_1_a[1]), .m2_a(mult_1_a[2]), .m3_a(mult_1_a[3]), 
    .m4_a(mult_1_a[4]), .m5_a(mult_1_a[5]), .m6_a(mult_1_a[6]), .m7_a(mult_1_a[7]), 
    .m0_b(mult_1_b[0]), .m1_b(mult_1_b[1]), .m2_b(mult_1_b[2]), .m3_b(mult_1_b[3]), 
    .m4_b(mult_1_b[4]), .m5_b(mult_1_b[5]), .m6_b(mult_1_b[6]), .m7_b(mult_1_b[7]), 
    .z(mult_1_z)
);
multiplier_19 multiplier_2
(
    .m0_a(mult_2_a[0]), .m1_a(mult_2_a[1]), .m2_a(mult_2_a[2]), .m3_a(mult_2_a[3]), 
    .m4_a(mult_2_a[4]), .m5_a(mult_2_a[5]), .m6_a(mult_2_a[6]), .m7_a(mult_2_a[7]), 
    .m0_b(mult_2_b[0]), .m1_b(mult_2_b[1]), .m2_b(mult_2_b[2]), .m3_b(mult_2_b[3]), 
    .m4_b(mult_2_b[4]), .m5_b(mult_2_b[5]), .m6_b(mult_2_b[6]), .m7_b(mult_2_b[7]), 
    .z(mult_2_z)
);
multiplier_19 multiplier_3
(
    .m0_a(mult_3_a[0]), .m1_a(mult_3_a[1]), .m2_a(mult_3_a[2]), .m3_a(mult_3_a[3]), 
    .m4_a(mult_3_a[4]), .m5_a(mult_3_a[5]), .m6_a(mult_3_a[6]), .m7_a(mult_3_a[7]), 
    .m0_b(mult_3_b[0]), .m1_b(mult_3_b[1]), .m2_b(mult_3_b[2]), .m3_b(mult_3_b[3]), 
    .m4_b(mult_3_b[4]), .m5_b(mult_3_b[5]), .m6_b(mult_3_b[6]), .m7_b(mult_3_b[7]), 
    .z(mult_3_z)
);
multiplier_19 multiplier_4
(
    .m0_a(mult_4_a[0]), .m1_a(mult_4_a[1]), .m2_a(mult_4_a[2]), .m3_a(mult_4_a[3]), 
    .m4_a(mult_4_a[4]), .m5_a(mult_4_a[5]), .m6_a(mult_4_a[6]), .m7_a(mult_4_a[7]), 
    .m0_b(mult_4_b[0]), .m1_b(mult_4_b[1]), .m2_b(mult_4_b[2]), .m3_b(mult_4_b[3]), 
    .m4_b(mult_4_b[4]), .m5_b(mult_4_b[5]), .m6_b(mult_4_b[6]), .m7_b(mult_4_b[7]), 
    .z(mult_4_z)
);
multiplier_19 multiplier_5
(
    .m0_a(mult_5_a[0]), .m1_a(mult_5_a[1]), .m2_a(mult_5_a[2]), .m3_a(mult_5_a[3]), 
    .m4_a(mult_5_a[4]), .m5_a(mult_5_a[5]), .m6_a(mult_5_a[6]), .m7_a(mult_5_a[7]), 
    .m0_b(mult_5_b[0]), .m1_b(mult_5_b[1]), .m2_b(mult_5_b[2]), .m3_b(mult_5_b[3]), 
    .m4_b(mult_5_b[4]), .m5_b(mult_5_b[5]), .m6_b(mult_5_b[6]), .m7_b(mult_5_b[7]), 
    .z(mult_5_z)
);
multiplier_19 multiplier_6
(
    .m0_a(mult_6_a[0]), .m1_a(mult_6_a[1]), .m2_a(mult_6_a[2]), .m3_a(mult_6_a[3]), 
    .m4_a(mult_6_a[4]), .m5_a(mult_6_a[5]), .m6_a(mult_6_a[6]), .m7_a(mult_6_a[7]), 
    .m0_b(mult_6_b[0]), .m1_b(mult_6_b[1]), .m2_b(mult_6_b[2]), .m3_b(mult_6_b[3]), 
    .m4_b(mult_6_b[4]), .m5_b(mult_6_b[5]), .m6_b(mult_6_b[6]), .m7_b(mult_6_b[7]), 
    .z(mult_6_z)
);
multiplier_41 multiplier_7
(
    .m0_a(mult_7_a[0]), .m1_a(mult_7_a[1]), .m2_a(mult_7_a[2]), .m3_a(mult_7_a[3]), 
    .m4_a(mult_7_a[4]), .m5_a(mult_7_a[5]), .m6_a(mult_7_a[6]), .m7_a(mult_7_a[7]), 
    .m0_b(mult_7_b[0]), .m1_b(mult_7_b[1]), .m2_b(mult_7_b[2]), .m3_b(mult_7_b[3]), 
    .m4_b(mult_7_b[4]), .m5_b(mult_7_b[5]), .m6_b(mult_7_b[6]), .m7_b(mult_7_b[7]), 
    .z(mult_7_z)
);

//==================================================================
// mult_0_a mult_0_b
//==================================================================
always @ (*)
begin
    case(state)
    XWK:
    begin
        case(input_counter)
        6'd0, 6'd57:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_0_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_0_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_0_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_0_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_0_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_0_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_0_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd1, 6'd58:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_0_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_0_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_0_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_0_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_0_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_0_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_0_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd2, 6'd59:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_0_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_0_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_0_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_0_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_0_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_0_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_0_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd3, 6'd60:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_0_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_0_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_0_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_0_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_0_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_0_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_0_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd4, 6'd61:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_0_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_0_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_0_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_0_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_0_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_0_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_0_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd5, 6'd62:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_0_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_0_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_0_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_0_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_0_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_0_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_0_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd6, 6'd63:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_0_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_0_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_0_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_0_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_0_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_0_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_0_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        6'd7:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_0_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_0_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_0_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_0_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_0_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_0_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_0_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        default:
        begin
            mult_0_a[0] = 19'd0;
            mult_0_a[1] = 19'd0;
            mult_0_a[2] = 19'd0;
            mult_0_a[3] = 19'd0;
            mult_0_a[4] = 19'd0;
            mult_0_a[5] = 19'd0;
            mult_0_a[6] = 19'd0;
            mult_0_a[7] = 19'd0;
            mult_0_b[0] = 19'd0;
            mult_0_b[1] = 19'd0;
            mult_0_b[2] = 19'd0;
            mult_0_b[3] = 19'd0;
            mult_0_b[4] = 19'd0;
            mult_0_b[5] = 19'd0;
            mult_0_b[6] = 19'd0;
            mult_0_b[7] = 19'd0;
        end
        endcase
    end
    XWV:
    begin
        case(input_counter)
        6'd0:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_0_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_0_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_0_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_0_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_0_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_0_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_0_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        6'd1:
        begin
            mult_0_a[0] = xw_reg[0];
            mult_0_a[1] = xw_reg[1];
            mult_0_a[2] = xw_reg[2];
            mult_0_a[3] = xw_reg[3];
            mult_0_a[4] = xw_reg[4];
            mult_0_a[5] = xw_reg[5];
            mult_0_a[6] = xw_reg[6];
            mult_0_a[7] = xw_reg[7];
            mult_0_b[0] = qkt_reg[0][18:0];
            mult_0_b[1] = qkt_reg[8][18:0];
            mult_0_b[2] = qkt_reg[16][18:0];
            mult_0_b[3] = qkt_reg[24][18:0];
            mult_0_b[4] = qkt_reg[32][18:0];
            mult_0_b[5] = qkt_reg[40][18:0];
            mult_0_b[6] = qkt_reg[48][18:0];
            mult_0_b[7] = qkt_reg[56][18:0];
        end
        6'd2:
        begin
            mult_0_a[0] = xw_reg[0];
            mult_0_a[1] = xw_reg[1];
            mult_0_a[2] = xw_reg[2];
            mult_0_a[3] = xw_reg[3];
            mult_0_a[4] = xw_reg[4];
            mult_0_a[5] = xw_reg[5];
            mult_0_a[6] = xw_reg[6];
            mult_0_a[7] = xw_reg[7];
            mult_0_b[0] = qkt_reg[1][18:0];
            mult_0_b[1] = qkt_reg[9][18:0];
            mult_0_b[2] = qkt_reg[17][18:0];
            mult_0_b[3] = qkt_reg[25][18:0];
            mult_0_b[4] = qkt_reg[33][18:0];
            mult_0_b[5] = qkt_reg[41][18:0];
            mult_0_b[6] = qkt_reg[49][18:0];
            mult_0_b[7] = qkt_reg[57][18:0];
        end
        6'd3:
        begin
            mult_0_a[0] = xw_reg[0];
            mult_0_a[1] = xw_reg[1];
            mult_0_a[2] = xw_reg[2];
            mult_0_a[3] = xw_reg[3];
            mult_0_a[4] = xw_reg[4];
            mult_0_a[5] = xw_reg[5];
            mult_0_a[6] = xw_reg[6];
            mult_0_a[7] = xw_reg[7];
            mult_0_b[0] = qkt_reg[2][18:0];
            mult_0_b[1] = qkt_reg[10][18:0];
            mult_0_b[2] = qkt_reg[18][18:0];
            mult_0_b[3] = qkt_reg[26][18:0];
            mult_0_b[4] = qkt_reg[34][18:0];
            mult_0_b[5] = qkt_reg[42][18:0];
            mult_0_b[6] = qkt_reg[50][18:0];
            mult_0_b[7] = qkt_reg[58][18:0];
        end
        6'd4:
        begin
            mult_0_a[0] = xw_reg[0];
            mult_0_a[1] = xw_reg[1];
            mult_0_a[2] = xw_reg[2];
            mult_0_a[3] = xw_reg[3];
            mult_0_a[4] = xw_reg[4];
            mult_0_a[5] = xw_reg[5];
            mult_0_a[6] = xw_reg[6];
            mult_0_a[7] = xw_reg[7];
            mult_0_b[0] = qkt_reg[3][18:0];
            mult_0_b[1] = qkt_reg[11][18:0];
            mult_0_b[2] = qkt_reg[19][18:0];
            mult_0_b[3] = qkt_reg[27][18:0];
            mult_0_b[4] = qkt_reg[35][18:0];
            mult_0_b[5] = qkt_reg[43][18:0];
            mult_0_b[6] = qkt_reg[51][18:0];
            mult_0_b[7] = qkt_reg[59][18:0];
        end
        6'd5:
        begin
            mult_0_a[0] = xw_reg[0];
            mult_0_a[1] = xw_reg[1];
            mult_0_a[2] = xw_reg[2];
            mult_0_a[3] = xw_reg[3];
            mult_0_a[4] = xw_reg[4];
            mult_0_a[5] = xw_reg[5];
            mult_0_a[6] = xw_reg[6];
            mult_0_a[7] = xw_reg[7];
            mult_0_b[0] = qkt_reg[4][18:0];
            mult_0_b[1] = qkt_reg[12][18:0];
            mult_0_b[2] = qkt_reg[20][18:0];
            mult_0_b[3] = qkt_reg[28][18:0];
            mult_0_b[4] = qkt_reg[36][18:0];
            mult_0_b[5] = qkt_reg[44][18:0];
            mult_0_b[6] = qkt_reg[52][18:0];
            mult_0_b[7] = qkt_reg[60][18:0];
        end
        6'd6:
        begin
            mult_0_a[0] = xw_reg[0];
            mult_0_a[1] = xw_reg[1];
            mult_0_a[2] = xw_reg[2];
            mult_0_a[3] = xw_reg[3];
            mult_0_a[4] = xw_reg[4];
            mult_0_a[5] = xw_reg[5];
            mult_0_a[6] = xw_reg[6];
            mult_0_a[7] = xw_reg[7];
            mult_0_b[0] = qkt_reg[5][18:0];
            mult_0_b[1] = qkt_reg[13][18:0];
            mult_0_b[2] = qkt_reg[21][18:0];
            mult_0_b[3] = qkt_reg[29][18:0];
            mult_0_b[4] = qkt_reg[37][18:0];
            mult_0_b[5] = qkt_reg[45][18:0];
            mult_0_b[6] = qkt_reg[53][18:0];
            mult_0_b[7] = qkt_reg[61][18:0];
        end
        6'd7:
        begin
            mult_0_a[0] = xw_reg[0];
            mult_0_a[1] = xw_reg[1];
            mult_0_a[2] = xw_reg[2];
            mult_0_a[3] = xw_reg[3];
            mult_0_a[4] = xw_reg[4];
            mult_0_a[5] = xw_reg[5];
            mult_0_a[6] = xw_reg[6];
            mult_0_a[7] = xw_reg[7];
            mult_0_b[0] = qkt_reg[6][18:0];
            mult_0_b[1] = qkt_reg[14][18:0];
            mult_0_b[2] = qkt_reg[22][18:0];
            mult_0_b[3] = qkt_reg[30][18:0];
            mult_0_b[4] = qkt_reg[38][18:0];
            mult_0_b[5] = qkt_reg[46][18:0];
            mult_0_b[6] = qkt_reg[54][18:0];
            mult_0_b[7] = qkt_reg[62][18:0];
        end
        6'd8:
        begin
            mult_0_a[0] = xw_reg[0];
            mult_0_a[1] = xw_reg[1];
            mult_0_a[2] = xw_reg[2];
            mult_0_a[3] = xw_reg[3];
            mult_0_a[4] = xw_reg[4];
            mult_0_a[5] = xw_reg[5];
            mult_0_a[6] = xw_reg[6];
            mult_0_a[7] = xw_reg[7];
            mult_0_b[0] = qkt_reg[7][18:0];
            mult_0_b[1] = qkt_reg[15][18:0];
            mult_0_b[2] = qkt_reg[23][18:0];
            mult_0_b[3] = qkt_reg[31][18:0];
            mult_0_b[4] = qkt_reg[39][18:0];
            mult_0_b[5] = qkt_reg[47][18:0];
            mult_0_b[6] = qkt_reg[55][18:0];
            mult_0_b[7] = qkt_reg[63][18:0];
        end
        6'd57:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_0_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_0_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_0_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_0_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_0_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_0_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_0_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd58:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_0_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_0_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_0_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_0_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_0_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_0_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_0_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd59:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_0_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_0_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_0_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_0_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_0_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_0_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_0_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd60:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_0_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_0_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_0_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_0_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_0_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_0_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_0_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd61:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_0_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_0_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_0_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_0_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_0_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_0_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_0_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd62:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_0_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_0_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_0_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_0_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_0_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_0_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_0_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd63:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_0_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_0_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_0_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_0_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_0_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_0_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_0_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        default:
        begin
            mult_0_a[0] = 19'd0;
            mult_0_a[1] = 19'd0;
            mult_0_a[2] = 19'd0;
            mult_0_a[3] = 19'd0;
            mult_0_a[4] = 19'd0;
            mult_0_a[5] = 19'd0;
            mult_0_a[6] = 19'd0;
            mult_0_a[7] = 19'd0;
            mult_0_b[0] = 19'd0;
            mult_0_b[1] = 19'd0;
            mult_0_b[2] = 19'd0;
            mult_0_b[3] = 19'd0;
            mult_0_b[4] = 19'd0;
            mult_0_b[5] = 19'd0;
            mult_0_b[6] = 19'd0;
            mult_0_b[7] = 19'd0;
        end
        endcase
    end
    OUT:
    begin
        case(output_counter)
        6'd0:
        begin
            mult_0_a[0] = {{11{in_data_reg[0][7]}}, in_data_reg[0]};
            mult_0_a[1] = {{11{in_data_reg[1][7]}}, in_data_reg[1]};
            mult_0_a[2] = {{11{in_data_reg[2][7]}}, in_data_reg[2]};
            mult_0_a[3] = {{11{in_data_reg[3][7]}}, in_data_reg[3]};
            mult_0_a[4] = {{11{in_data_reg[4][7]}}, in_data_reg[4]};
            mult_0_a[5] = {{11{in_data_reg[5][7]}}, in_data_reg[5]};
            mult_0_a[6] = {{11{in_data_reg[6][7]}}, in_data_reg[6]};
            mult_0_a[7] = {{11{in_data_reg[7][7]}}, in_data_reg[7]};
            mult_0_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_0_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_0_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_0_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_0_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_0_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_0_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_0_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        6'd1:
        begin
            mult_0_a[0] = {{11{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_0_a[1] = {{11{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_0_a[2] = {{11{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_0_a[3] = {{11{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_0_a[4] = {{11{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_0_a[5] = {{11{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_0_a[6] = {{11{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_0_a[7] = {{11{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_0_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_0_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_0_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_0_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_0_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_0_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_0_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_0_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        default:
        begin
            mult_0_a[0] = 19'd0;
            mult_0_a[1] = 19'd0;
            mult_0_a[2] = 19'd0;
            mult_0_a[3] = 19'd0;
            mult_0_a[4] = 19'd0;
            mult_0_a[5] = 19'd0;
            mult_0_a[6] = 19'd0;
            mult_0_a[7] = 19'd0;
            mult_0_b[0] = 19'd0;
            mult_0_b[1] = 19'd0;
            mult_0_b[2] = 19'd0;
            mult_0_b[3] = 19'd0;
            mult_0_b[4] = 19'd0;
            mult_0_b[5] = 19'd0;
            mult_0_b[6] = 19'd0;
            mult_0_b[7] = 19'd0;
        end
        endcase
    end
    default:
    begin
        mult_0_a[0] = 19'd0;
        mult_0_a[1] = 19'd0;
        mult_0_a[2] = 19'd0;
        mult_0_a[3] = 19'd0;
        mult_0_a[4] = 19'd0;
        mult_0_a[5] = 19'd0;
        mult_0_a[6] = 19'd0;
        mult_0_a[7] = 19'd0;
        mult_0_b[0] = 19'd0;
        mult_0_b[1] = 19'd0;
        mult_0_b[2] = 19'd0;
        mult_0_b[3] = 19'd0;
        mult_0_b[4] = 19'd0;
        mult_0_b[5] = 19'd0;
        mult_0_b[6] = 19'd0;
        mult_0_b[7] = 19'd0;
    end
    endcase
end

//==================================================================
// mult_1_a mult_1_b
//==================================================================
always @ (*)
begin
    case(state)
    XWK:
    begin
        case(input_counter)
        6'd0, 6'd57:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_1_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_1_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_1_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_1_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_1_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_1_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_1_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd1, 6'd58:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_1_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_1_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_1_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_1_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_1_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_1_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_1_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd2, 6'd59:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_1_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_1_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_1_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_1_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_1_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_1_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_1_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd3, 6'd60:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_1_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_1_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_1_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_1_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_1_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_1_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_1_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd4, 6'd61:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_1_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_1_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_1_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_1_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_1_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_1_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_1_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd5, 6'd62:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_1_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_1_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_1_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_1_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_1_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_1_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_1_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd6, 6'd63:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_1_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_1_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_1_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_1_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_1_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_1_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_1_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        6'd7:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_1_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_1_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_1_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_1_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_1_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_1_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_1_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        default:
        begin
            mult_1_a[0] = 19'd0;
            mult_1_a[1] = 19'd0;
            mult_1_a[2] = 19'd0;
            mult_1_a[3] = 19'd0;
            mult_1_a[4] = 19'd0;
            mult_1_a[5] = 19'd0;
            mult_1_a[6] = 19'd0;
            mult_1_a[7] = 19'd0;
            mult_1_b[0] = 19'd0;
            mult_1_b[1] = 19'd0;
            mult_1_b[2] = 19'd0;
            mult_1_b[3] = 19'd0;
            mult_1_b[4] = 19'd0;
            mult_1_b[5] = 19'd0;
            mult_1_b[6] = 19'd0;
            mult_1_b[7] = 19'd0;
        end
        endcase
    end
    XWV:
    begin
        case(input_counter)
        6'd0:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_1_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_1_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_1_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_1_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_1_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_1_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_1_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        6'd1:
        begin
            mult_1_a[0] = xw_reg[8];
            mult_1_a[1] = xw_reg[9];
            mult_1_a[2] = xw_reg[10];
            mult_1_a[3] = xw_reg[11];
            mult_1_a[4] = xw_reg[12];
            mult_1_a[5] = xw_reg[13];
            mult_1_a[6] = xw_reg[14];
            mult_1_a[7] = xw_reg[15];
            mult_1_b[0] = qkt_reg[0][18:0];
            mult_1_b[1] = qkt_reg[8][18:0];
            mult_1_b[2] = qkt_reg[16][18:0];
            mult_1_b[3] = qkt_reg[24][18:0];
            mult_1_b[4] = qkt_reg[32][18:0];
            mult_1_b[5] = qkt_reg[40][18:0];
            mult_1_b[6] = qkt_reg[48][18:0];
            mult_1_b[7] = qkt_reg[56][18:0];
        end
        6'd2:
        begin
            mult_1_a[0] = xw_reg[8];
            mult_1_a[1] = xw_reg[9];
            mult_1_a[2] = xw_reg[10];
            mult_1_a[3] = xw_reg[11];
            mult_1_a[4] = xw_reg[12];
            mult_1_a[5] = xw_reg[13];
            mult_1_a[6] = xw_reg[14];
            mult_1_a[7] = xw_reg[15];
            mult_1_b[0] = qkt_reg[1][18:0];
            mult_1_b[1] = qkt_reg[9][18:0];
            mult_1_b[2] = qkt_reg[17][18:0];
            mult_1_b[3] = qkt_reg[25][18:0];
            mult_1_b[4] = qkt_reg[33][18:0];
            mult_1_b[5] = qkt_reg[41][18:0];
            mult_1_b[6] = qkt_reg[49][18:0];
            mult_1_b[7] = qkt_reg[57][18:0];
        end
        6'd3:
        begin
            mult_1_a[0] = xw_reg[8];
            mult_1_a[1] = xw_reg[9];
            mult_1_a[2] = xw_reg[10];
            mult_1_a[3] = xw_reg[11];
            mult_1_a[4] = xw_reg[12];
            mult_1_a[5] = xw_reg[13];
            mult_1_a[6] = xw_reg[14];
            mult_1_a[7] = xw_reg[15];
            mult_1_b[0] = qkt_reg[2][18:0];
            mult_1_b[1] = qkt_reg[10][18:0];
            mult_1_b[2] = qkt_reg[18][18:0];
            mult_1_b[3] = qkt_reg[26][18:0];
            mult_1_b[4] = qkt_reg[34][18:0];
            mult_1_b[5] = qkt_reg[42][18:0];
            mult_1_b[6] = qkt_reg[50][18:0];
            mult_1_b[7] = qkt_reg[58][18:0];
        end
        6'd4:
        begin
            mult_1_a[0] = xw_reg[8];
            mult_1_a[1] = xw_reg[9];
            mult_1_a[2] = xw_reg[10];
            mult_1_a[3] = xw_reg[11];
            mult_1_a[4] = xw_reg[12];
            mult_1_a[5] = xw_reg[13];
            mult_1_a[6] = xw_reg[14];
            mult_1_a[7] = xw_reg[15];
            mult_1_b[0] = qkt_reg[3][18:0];
            mult_1_b[1] = qkt_reg[11][18:0];
            mult_1_b[2] = qkt_reg[19][18:0];
            mult_1_b[3] = qkt_reg[27][18:0];
            mult_1_b[4] = qkt_reg[35][18:0];
            mult_1_b[5] = qkt_reg[43][18:0];
            mult_1_b[6] = qkt_reg[51][18:0];
            mult_1_b[7] = qkt_reg[59][18:0];
        end
        6'd5:
        begin
            mult_1_a[0] = xw_reg[8];
            mult_1_a[1] = xw_reg[9];
            mult_1_a[2] = xw_reg[10];
            mult_1_a[3] = xw_reg[11];
            mult_1_a[4] = xw_reg[12];
            mult_1_a[5] = xw_reg[13];
            mult_1_a[6] = xw_reg[14];
            mult_1_a[7] = xw_reg[15];
            mult_1_b[0] = qkt_reg[4][18:0];
            mult_1_b[1] = qkt_reg[12][18:0];
            mult_1_b[2] = qkt_reg[20][18:0];
            mult_1_b[3] = qkt_reg[28][18:0];
            mult_1_b[4] = qkt_reg[36][18:0];
            mult_1_b[5] = qkt_reg[44][18:0];
            mult_1_b[6] = qkt_reg[52][18:0];
            mult_1_b[7] = qkt_reg[60][18:0];
        end
        6'd6:
        begin
            mult_1_a[0] = xw_reg[8];
            mult_1_a[1] = xw_reg[9];
            mult_1_a[2] = xw_reg[10];
            mult_1_a[3] = xw_reg[11];
            mult_1_a[4] = xw_reg[12];
            mult_1_a[5] = xw_reg[13];
            mult_1_a[6] = xw_reg[14];
            mult_1_a[7] = xw_reg[15];
            mult_1_b[0] = qkt_reg[5][18:0];
            mult_1_b[1] = qkt_reg[13][18:0];
            mult_1_b[2] = qkt_reg[21][18:0];
            mult_1_b[3] = qkt_reg[29][18:0];
            mult_1_b[4] = qkt_reg[37][18:0];
            mult_1_b[5] = qkt_reg[45][18:0];
            mult_1_b[6] = qkt_reg[53][18:0];
            mult_1_b[7] = qkt_reg[61][18:0];
        end
        6'd7:
        begin
            mult_1_a[0] = xw_reg[8];
            mult_1_a[1] = xw_reg[9];
            mult_1_a[2] = xw_reg[10];
            mult_1_a[3] = xw_reg[11];
            mult_1_a[4] = xw_reg[12];
            mult_1_a[5] = xw_reg[13];
            mult_1_a[6] = xw_reg[14];
            mult_1_a[7] = xw_reg[15];
            mult_1_b[0] = qkt_reg[6][18:0];
            mult_1_b[1] = qkt_reg[14][18:0];
            mult_1_b[2] = qkt_reg[22][18:0];
            mult_1_b[3] = qkt_reg[30][18:0];
            mult_1_b[4] = qkt_reg[38][18:0];
            mult_1_b[5] = qkt_reg[46][18:0];
            mult_1_b[6] = qkt_reg[54][18:0];
            mult_1_b[7] = qkt_reg[62][18:0];
        end
        6'd8:
        begin
            mult_1_a[0] = xw_reg[8];
            mult_1_a[1] = xw_reg[9];
            mult_1_a[2] = xw_reg[10];
            mult_1_a[3] = xw_reg[11];
            mult_1_a[4] = xw_reg[12];
            mult_1_a[5] = xw_reg[13];
            mult_1_a[6] = xw_reg[14];
            mult_1_a[7] = xw_reg[15];
            mult_1_b[0] = qkt_reg[7][18:0];
            mult_1_b[1] = qkt_reg[15][18:0];
            mult_1_b[2] = qkt_reg[23][18:0];
            mult_1_b[3] = qkt_reg[31][18:0];
            mult_1_b[4] = qkt_reg[39][18:0];
            mult_1_b[5] = qkt_reg[47][18:0];
            mult_1_b[6] = qkt_reg[55][18:0];
            mult_1_b[7] = qkt_reg[63][18:0];
        end
        6'd57:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_1_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_1_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_1_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_1_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_1_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_1_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_1_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd58:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_1_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_1_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_1_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_1_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_1_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_1_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_1_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd59:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_1_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_1_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_1_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_1_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_1_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_1_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_1_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd60:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_1_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_1_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_1_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_1_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_1_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_1_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_1_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd61:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_1_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_1_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_1_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_1_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_1_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_1_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_1_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd62:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_1_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_1_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_1_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_1_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_1_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_1_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_1_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd63:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_1_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_1_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_1_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_1_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_1_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_1_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_1_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        default:
        begin
            mult_1_a[0] = 19'd0;
            mult_1_a[1] = 19'd0;
            mult_1_a[2] = 19'd0;
            mult_1_a[3] = 19'd0;
            mult_1_a[4] = 19'd0;
            mult_1_a[5] = 19'd0;
            mult_1_a[6] = 19'd0;
            mult_1_a[7] = 19'd0;
            mult_1_b[0] = 19'd0;
            mult_1_b[1] = 19'd0;
            mult_1_b[2] = 19'd0;
            mult_1_b[3] = 19'd0;
            mult_1_b[4] = 19'd0;
            mult_1_b[5] = 19'd0;
            mult_1_b[6] = 19'd0;
            mult_1_b[7] = 19'd0;
        end
        endcase
    end
    OUT:
    begin
        case(output_counter)
        6'd0:
        begin
            mult_1_a[0] = {{11{in_data_reg[8][7]}}, in_data_reg[8]};
            mult_1_a[1] = {{11{in_data_reg[9][7]}}, in_data_reg[9]};
            mult_1_a[2] = {{11{in_data_reg[10][7]}}, in_data_reg[10]};
            mult_1_a[3] = {{11{in_data_reg[11][7]}}, in_data_reg[11]};
            mult_1_a[4] = {{11{in_data_reg[12][7]}}, in_data_reg[12]};
            mult_1_a[5] = {{11{in_data_reg[13][7]}}, in_data_reg[13]};
            mult_1_a[6] = {{11{in_data_reg[14][7]}}, in_data_reg[14]};
            mult_1_a[7] = {{11{in_data_reg[15][7]}}, in_data_reg[15]};
            mult_1_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_1_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_1_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_1_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_1_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_1_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_1_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_1_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        6'd1:
        begin
            mult_1_a[0] = {{11{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_1_a[1] = {{11{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_1_a[2] = {{11{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_1_a[3] = {{11{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_1_a[4] = {{11{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_1_a[5] = {{11{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_1_a[6] = {{11{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_1_a[7] = {{11{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_1_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_1_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_1_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_1_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_1_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_1_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_1_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_1_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        default:
        begin
            mult_1_a[0] = 19'd0;
            mult_1_a[1] = 19'd0;
            mult_1_a[2] = 19'd0;
            mult_1_a[3] = 19'd0;
            mult_1_a[4] = 19'd0;
            mult_1_a[5] = 19'd0;
            mult_1_a[6] = 19'd0;
            mult_1_a[7] = 19'd0;
            mult_1_b[0] = 19'd0;
            mult_1_b[1] = 19'd0;
            mult_1_b[2] = 19'd0;
            mult_1_b[3] = 19'd0;
            mult_1_b[4] = 19'd0;
            mult_1_b[5] = 19'd0;
            mult_1_b[6] = 19'd0;
            mult_1_b[7] = 19'd0;
        end
        endcase
    end
    default:
    begin
        mult_1_a[0] = 19'd0;
        mult_1_a[1] = 19'd0;
        mult_1_a[2] = 19'd0;
        mult_1_a[3] = 19'd0;
        mult_1_a[4] = 19'd0;
        mult_1_a[5] = 19'd0;
        mult_1_a[6] = 19'd0;
        mult_1_a[7] = 19'd0;
        mult_1_b[0] = 19'd0;
        mult_1_b[1] = 19'd0;
        mult_1_b[2] = 19'd0;
        mult_1_b[3] = 19'd0;
        mult_1_b[4] = 19'd0;
        mult_1_b[5] = 19'd0;
        mult_1_b[6] = 19'd0;
        mult_1_b[7] = 19'd0;
    end
    endcase
end

//==================================================================
// mult_2_a mult_2_b
//==================================================================
always @ (*)
begin
    case(state)
    XWK:
    begin
        case(input_counter)
        6'd0, 6'd57:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_2_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_2_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_2_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_2_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_2_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_2_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_2_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd1, 6'd58:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_2_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_2_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_2_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_2_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_2_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_2_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_2_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd2, 6'd59:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_2_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_2_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_2_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_2_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_2_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_2_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_2_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd3, 6'd60:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_2_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_2_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_2_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_2_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_2_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_2_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_2_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd4, 6'd61:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_2_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_2_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_2_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_2_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_2_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_2_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_2_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd5, 6'd62:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_2_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_2_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_2_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_2_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_2_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_2_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_2_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd6, 6'd63:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_2_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_2_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_2_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_2_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_2_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_2_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_2_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        6'd7:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_2_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_2_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_2_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_2_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_2_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_2_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_2_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        default:
        begin
            mult_2_a[0] = 19'd0;
            mult_2_a[1] = 19'd0;
            mult_2_a[2] = 19'd0;
            mult_2_a[3] = 19'd0;
            mult_2_a[4] = 19'd0;
            mult_2_a[5] = 19'd0;
            mult_2_a[6] = 19'd0;
            mult_2_a[7] = 19'd0;
            mult_2_b[0] = 19'd0;
            mult_2_b[1] = 19'd0;
            mult_2_b[2] = 19'd0;
            mult_2_b[3] = 19'd0;
            mult_2_b[4] = 19'd0;
            mult_2_b[5] = 19'd0;
            mult_2_b[6] = 19'd0;
            mult_2_b[7] = 19'd0;
        end
        endcase
    end
    XWV:
    begin
        case(input_counter)
        6'd0:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_2_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_2_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_2_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_2_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_2_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_2_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_2_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        6'd1:
        begin
            mult_2_a[0] = xw_reg[16];
            mult_2_a[1] = xw_reg[17];
            mult_2_a[2] = xw_reg[18];
            mult_2_a[3] = xw_reg[19];
            mult_2_a[4] = xw_reg[20];
            mult_2_a[5] = xw_reg[21];
            mult_2_a[6] = xw_reg[22];
            mult_2_a[7] = xw_reg[23];
            mult_2_b[0] = qkt_reg[0][18:0];
            mult_2_b[1] = qkt_reg[8][18:0];
            mult_2_b[2] = qkt_reg[16][18:0];
            mult_2_b[3] = qkt_reg[24][18:0];
            mult_2_b[4] = qkt_reg[32][18:0];
            mult_2_b[5] = qkt_reg[40][18:0];
            mult_2_b[6] = qkt_reg[48][18:0];
            mult_2_b[7] = qkt_reg[56][18:0];
        end
        6'd2:
        begin
            mult_2_a[0] = xw_reg[16];
            mult_2_a[1] = xw_reg[17];
            mult_2_a[2] = xw_reg[18];
            mult_2_a[3] = xw_reg[19];
            mult_2_a[4] = xw_reg[20];
            mult_2_a[5] = xw_reg[21];
            mult_2_a[6] = xw_reg[22];
            mult_2_a[7] = xw_reg[23];
            mult_2_b[0] = qkt_reg[1][18:0];
            mult_2_b[1] = qkt_reg[9][18:0];
            mult_2_b[2] = qkt_reg[17][18:0];
            mult_2_b[3] = qkt_reg[25][18:0];
            mult_2_b[4] = qkt_reg[33][18:0];
            mult_2_b[5] = qkt_reg[41][18:0];
            mult_2_b[6] = qkt_reg[49][18:0];
            mult_2_b[7] = qkt_reg[57][18:0];
        end
        6'd3:
        begin
            mult_2_a[0] = xw_reg[16];
            mult_2_a[1] = xw_reg[17];
            mult_2_a[2] = xw_reg[18];
            mult_2_a[3] = xw_reg[19];
            mult_2_a[4] = xw_reg[20];
            mult_2_a[5] = xw_reg[21];
            mult_2_a[6] = xw_reg[22];
            mult_2_a[7] = xw_reg[23];
            mult_2_b[0] = qkt_reg[2][18:0];
            mult_2_b[1] = qkt_reg[10][18:0];
            mult_2_b[2] = qkt_reg[18][18:0];
            mult_2_b[3] = qkt_reg[26][18:0];
            mult_2_b[4] = qkt_reg[34][18:0];
            mult_2_b[5] = qkt_reg[42][18:0];
            mult_2_b[6] = qkt_reg[50][18:0];
            mult_2_b[7] = qkt_reg[58][18:0];
        end
        6'd4:
        begin
            mult_2_a[0] = xw_reg[16];
            mult_2_a[1] = xw_reg[17];
            mult_2_a[2] = xw_reg[18];
            mult_2_a[3] = xw_reg[19];
            mult_2_a[4] = xw_reg[20];
            mult_2_a[5] = xw_reg[21];
            mult_2_a[6] = xw_reg[22];
            mult_2_a[7] = xw_reg[23];
            mult_2_b[0] = qkt_reg[3][18:0];
            mult_2_b[1] = qkt_reg[11][18:0];
            mult_2_b[2] = qkt_reg[19][18:0];
            mult_2_b[3] = qkt_reg[27][18:0];
            mult_2_b[4] = qkt_reg[35][18:0];
            mult_2_b[5] = qkt_reg[43][18:0];
            mult_2_b[6] = qkt_reg[51][18:0];
            mult_2_b[7] = qkt_reg[59][18:0];
        end
        6'd5:
        begin
            mult_2_a[0] = xw_reg[16];
            mult_2_a[1] = xw_reg[17];
            mult_2_a[2] = xw_reg[18];
            mult_2_a[3] = xw_reg[19];
            mult_2_a[4] = xw_reg[20];
            mult_2_a[5] = xw_reg[21];
            mult_2_a[6] = xw_reg[22];
            mult_2_a[7] = xw_reg[23];
            mult_2_b[0] = qkt_reg[4][18:0];
            mult_2_b[1] = qkt_reg[12][18:0];
            mult_2_b[2] = qkt_reg[20][18:0];
            mult_2_b[3] = qkt_reg[28][18:0];
            mult_2_b[4] = qkt_reg[36][18:0];
            mult_2_b[5] = qkt_reg[44][18:0];
            mult_2_b[6] = qkt_reg[52][18:0];
            mult_2_b[7] = qkt_reg[60][18:0];
        end
        6'd6:
        begin
            mult_2_a[0] = xw_reg[16];
            mult_2_a[1] = xw_reg[17];
            mult_2_a[2] = xw_reg[18];
            mult_2_a[3] = xw_reg[19];
            mult_2_a[4] = xw_reg[20];
            mult_2_a[5] = xw_reg[21];
            mult_2_a[6] = xw_reg[22];
            mult_2_a[7] = xw_reg[23];
            mult_2_b[0] = qkt_reg[5][18:0];
            mult_2_b[1] = qkt_reg[13][18:0];
            mult_2_b[2] = qkt_reg[21][18:0];
            mult_2_b[3] = qkt_reg[29][18:0];
            mult_2_b[4] = qkt_reg[37][18:0];
            mult_2_b[5] = qkt_reg[45][18:0];
            mult_2_b[6] = qkt_reg[53][18:0];
            mult_2_b[7] = qkt_reg[61][18:0];
        end
        6'd7:
        begin
            mult_2_a[0] = xw_reg[16];
            mult_2_a[1] = xw_reg[17];
            mult_2_a[2] = xw_reg[18];
            mult_2_a[3] = xw_reg[19];
            mult_2_a[4] = xw_reg[20];
            mult_2_a[5] = xw_reg[21];
            mult_2_a[6] = xw_reg[22];
            mult_2_a[7] = xw_reg[23];
            mult_2_b[0] = qkt_reg[6][18:0];
            mult_2_b[1] = qkt_reg[14][18:0];
            mult_2_b[2] = qkt_reg[22][18:0];
            mult_2_b[3] = qkt_reg[30][18:0];
            mult_2_b[4] = qkt_reg[38][18:0];
            mult_2_b[5] = qkt_reg[46][18:0];
            mult_2_b[6] = qkt_reg[54][18:0];
            mult_2_b[7] = qkt_reg[62][18:0];
        end
        6'd8:
        begin
            mult_2_a[0] = xw_reg[16];
            mult_2_a[1] = xw_reg[17];
            mult_2_a[2] = xw_reg[18];
            mult_2_a[3] = xw_reg[19];
            mult_2_a[4] = xw_reg[20];
            mult_2_a[5] = xw_reg[21];
            mult_2_a[6] = xw_reg[22];
            mult_2_a[7] = xw_reg[23];
            mult_2_b[0] = qkt_reg[7][18:0];
            mult_2_b[1] = qkt_reg[15][18:0];
            mult_2_b[2] = qkt_reg[23][18:0];
            mult_2_b[3] = qkt_reg[31][18:0];
            mult_2_b[4] = qkt_reg[39][18:0];
            mult_2_b[5] = qkt_reg[47][18:0];
            mult_2_b[6] = qkt_reg[55][18:0];
            mult_2_b[7] = qkt_reg[63][18:0];
        end
        6'd57:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_2_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_2_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_2_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_2_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_2_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_2_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_2_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd58:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_2_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_2_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_2_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_2_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_2_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_2_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_2_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd59:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_2_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_2_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_2_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_2_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_2_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_2_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_2_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd60:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_2_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_2_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_2_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_2_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_2_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_2_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_2_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd61:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_2_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_2_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_2_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_2_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_2_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_2_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_2_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd62:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_2_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_2_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_2_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_2_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_2_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_2_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_2_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd63:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_2_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_2_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_2_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_2_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_2_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_2_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_2_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        default:
        begin
            mult_2_a[0] = 19'd0;
            mult_2_a[1] = 19'd0;
            mult_2_a[2] = 19'd0;
            mult_2_a[3] = 19'd0;
            mult_2_a[4] = 19'd0;
            mult_2_a[5] = 19'd0;
            mult_2_a[6] = 19'd0;
            mult_2_a[7] = 19'd0;
            mult_2_b[0] = 19'd0;
            mult_2_b[1] = 19'd0;
            mult_2_b[2] = 19'd0;
            mult_2_b[3] = 19'd0;
            mult_2_b[4] = 19'd0;
            mult_2_b[5] = 19'd0;
            mult_2_b[6] = 19'd0;
            mult_2_b[7] = 19'd0;
        end
        endcase
    end
    OUT:
    begin
        case(output_counter)
        6'd0:
        begin
            mult_2_a[0] = {{11{in_data_reg[16][7]}}, in_data_reg[16]};
            mult_2_a[1] = {{11{in_data_reg[17][7]}}, in_data_reg[17]};
            mult_2_a[2] = {{11{in_data_reg[18][7]}}, in_data_reg[18]};
            mult_2_a[3] = {{11{in_data_reg[19][7]}}, in_data_reg[19]};
            mult_2_a[4] = {{11{in_data_reg[20][7]}}, in_data_reg[20]};
            mult_2_a[5] = {{11{in_data_reg[21][7]}}, in_data_reg[21]};
            mult_2_a[6] = {{11{in_data_reg[22][7]}}, in_data_reg[22]};
            mult_2_a[7] = {{11{in_data_reg[23][7]}}, in_data_reg[23]};
            mult_2_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_2_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_2_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_2_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_2_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_2_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_2_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_2_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        default:
        begin
            mult_2_a[0] = 19'd0;
            mult_2_a[1] = 19'd0;
            mult_2_a[2] = 19'd0;
            mult_2_a[3] = 19'd0;
            mult_2_a[4] = 19'd0;
            mult_2_a[5] = 19'd0;
            mult_2_a[6] = 19'd0;
            mult_2_a[7] = 19'd0;
            mult_2_b[0] = 19'd0;
            mult_2_b[1] = 19'd0;
            mult_2_b[2] = 19'd0;
            mult_2_b[3] = 19'd0;
            mult_2_b[4] = 19'd0;
            mult_2_b[5] = 19'd0;
            mult_2_b[6] = 19'd0;
            mult_2_b[7] = 19'd0;
        end
        endcase
    end
    default:
    begin
        mult_2_a[0] = 19'd0;
        mult_2_a[1] = 19'd0;
        mult_2_a[2] = 19'd0;
        mult_2_a[3] = 19'd0;
        mult_2_a[4] = 19'd0;
        mult_2_a[5] = 19'd0;
        mult_2_a[6] = 19'd0;
        mult_2_a[7] = 19'd0;
        mult_2_b[0] = 19'd0;
        mult_2_b[1] = 19'd0;
        mult_2_b[2] = 19'd0;
        mult_2_b[3] = 19'd0;
        mult_2_b[4] = 19'd0;
        mult_2_b[5] = 19'd0;
        mult_2_b[6] = 19'd0;
        mult_2_b[7] = 19'd0;
    end
    endcase
end

//==================================================================
// mult_3_a mult_3_b
//==================================================================
always @ (*)
begin
    case(state)
    XWK:
    begin
        case(input_counter)
        6'd0, 6'd57:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_3_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_3_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_3_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_3_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_3_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_3_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_3_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd1, 6'd58:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_3_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_3_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_3_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_3_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_3_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_3_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_3_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd2, 6'd59:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_3_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_3_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_3_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_3_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_3_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_3_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_3_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd3, 6'd60:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_3_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_3_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_3_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_3_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_3_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_3_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_3_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd4, 6'd61:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_3_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_3_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_3_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_3_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_3_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_3_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_3_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd5, 6'd62:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_3_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_3_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_3_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_3_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_3_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_3_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_3_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd6, 6'd63:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_3_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_3_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_3_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_3_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_3_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_3_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_3_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        6'd7:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_3_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_3_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_3_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_3_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_3_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_3_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_3_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        default:
        begin
            mult_3_a[0] = 19'd0;
            mult_3_a[1] = 19'd0;
            mult_3_a[2] = 19'd0;
            mult_3_a[3] = 19'd0;
            mult_3_a[4] = 19'd0;
            mult_3_a[5] = 19'd0;
            mult_3_a[6] = 19'd0;
            mult_3_a[7] = 19'd0;
            mult_3_b[0] = 19'd0;
            mult_3_b[1] = 19'd0;
            mult_3_b[2] = 19'd0;
            mult_3_b[3] = 19'd0;
            mult_3_b[4] = 19'd0;
            mult_3_b[5] = 19'd0;
            mult_3_b[6] = 19'd0;
            mult_3_b[7] = 19'd0;
        end
        endcase
    end
    XWV:
    begin
        case(input_counter)
        6'd0:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_3_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_3_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_3_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_3_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_3_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_3_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_3_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        6'd1:
        begin
            mult_3_a[0] = xw_reg[24];
            mult_3_a[1] = xw_reg[25];
            mult_3_a[2] = xw_reg[26];
            mult_3_a[3] = xw_reg[27];
            mult_3_a[4] = xw_reg[28];
            mult_3_a[5] = xw_reg[29];
            mult_3_a[6] = xw_reg[30];
            mult_3_a[7] = xw_reg[31];
            mult_3_b[0] = qkt_reg[0][18:0];
            mult_3_b[1] = qkt_reg[8][18:0];
            mult_3_b[2] = qkt_reg[16][18:0];
            mult_3_b[3] = qkt_reg[24][18:0];
            mult_3_b[4] = qkt_reg[32][18:0];
            mult_3_b[5] = qkt_reg[40][18:0];
            mult_3_b[6] = qkt_reg[48][18:0];
            mult_3_b[7] = qkt_reg[56][18:0];
        end
        6'd2:
        begin
            mult_3_a[0] = xw_reg[24];
            mult_3_a[1] = xw_reg[25];
            mult_3_a[2] = xw_reg[26];
            mult_3_a[3] = xw_reg[27];
            mult_3_a[4] = xw_reg[28];
            mult_3_a[5] = xw_reg[29];
            mult_3_a[6] = xw_reg[30];
            mult_3_a[7] = xw_reg[31];
            mult_3_b[0] = qkt_reg[1][18:0];
            mult_3_b[1] = qkt_reg[9][18:0];
            mult_3_b[2] = qkt_reg[17][18:0];
            mult_3_b[3] = qkt_reg[25][18:0];
            mult_3_b[4] = qkt_reg[33][18:0];
            mult_3_b[5] = qkt_reg[41][18:0];
            mult_3_b[6] = qkt_reg[49][18:0];
            mult_3_b[7] = qkt_reg[57][18:0];
        end
        6'd3:
        begin
            mult_3_a[0] = xw_reg[24];
            mult_3_a[1] = xw_reg[25];
            mult_3_a[2] = xw_reg[26];
            mult_3_a[3] = xw_reg[27];
            mult_3_a[4] = xw_reg[28];
            mult_3_a[5] = xw_reg[29];
            mult_3_a[6] = xw_reg[30];
            mult_3_a[7] = xw_reg[31];
            mult_3_b[0] = qkt_reg[2][18:0];
            mult_3_b[1] = qkt_reg[10][18:0];
            mult_3_b[2] = qkt_reg[18][18:0];
            mult_3_b[3] = qkt_reg[26][18:0];
            mult_3_b[4] = qkt_reg[34][18:0];
            mult_3_b[5] = qkt_reg[42][18:0];
            mult_3_b[6] = qkt_reg[50][18:0];
            mult_3_b[7] = qkt_reg[58][18:0];
        end
        6'd4:
        begin
            mult_3_a[0] = xw_reg[24];
            mult_3_a[1] = xw_reg[25];
            mult_3_a[2] = xw_reg[26];
            mult_3_a[3] = xw_reg[27];
            mult_3_a[4] = xw_reg[28];
            mult_3_a[5] = xw_reg[29];
            mult_3_a[6] = xw_reg[30];
            mult_3_a[7] = xw_reg[31];
            mult_3_b[0] = qkt_reg[3][18:0];
            mult_3_b[1] = qkt_reg[11][18:0];
            mult_3_b[2] = qkt_reg[19][18:0];
            mult_3_b[3] = qkt_reg[27][18:0];
            mult_3_b[4] = qkt_reg[35][18:0];
            mult_3_b[5] = qkt_reg[43][18:0];
            mult_3_b[6] = qkt_reg[51][18:0];
            mult_3_b[7] = qkt_reg[59][18:0];
        end
        6'd5:
        begin
            mult_3_a[0] = xw_reg[24];
            mult_3_a[1] = xw_reg[25];
            mult_3_a[2] = xw_reg[26];
            mult_3_a[3] = xw_reg[27];
            mult_3_a[4] = xw_reg[28];
            mult_3_a[5] = xw_reg[29];
            mult_3_a[6] = xw_reg[30];
            mult_3_a[7] = xw_reg[31];
            mult_3_b[0] = qkt_reg[4][18:0];
            mult_3_b[1] = qkt_reg[12][18:0];
            mult_3_b[2] = qkt_reg[20][18:0];
            mult_3_b[3] = qkt_reg[28][18:0];
            mult_3_b[4] = qkt_reg[36][18:0];
            mult_3_b[5] = qkt_reg[44][18:0];
            mult_3_b[6] = qkt_reg[52][18:0];
            mult_3_b[7] = qkt_reg[60][18:0];
        end
        6'd6:
        begin
            mult_3_a[0] = xw_reg[24];
            mult_3_a[1] = xw_reg[25];
            mult_3_a[2] = xw_reg[26];
            mult_3_a[3] = xw_reg[27];
            mult_3_a[4] = xw_reg[28];
            mult_3_a[5] = xw_reg[29];
            mult_3_a[6] = xw_reg[30];
            mult_3_a[7] = xw_reg[31];
            mult_3_b[0] = qkt_reg[5][18:0];
            mult_3_b[1] = qkt_reg[13][18:0];
            mult_3_b[2] = qkt_reg[21][18:0];
            mult_3_b[3] = qkt_reg[29][18:0];
            mult_3_b[4] = qkt_reg[37][18:0];
            mult_3_b[5] = qkt_reg[45][18:0];
            mult_3_b[6] = qkt_reg[53][18:0];
            mult_3_b[7] = qkt_reg[61][18:0];
        end
        6'd7:
        begin
            mult_3_a[0] = xw_reg[24];
            mult_3_a[1] = xw_reg[25];
            mult_3_a[2] = xw_reg[26];
            mult_3_a[3] = xw_reg[27];
            mult_3_a[4] = xw_reg[28];
            mult_3_a[5] = xw_reg[29];
            mult_3_a[6] = xw_reg[30];
            mult_3_a[7] = xw_reg[31];
            mult_3_b[0] = qkt_reg[6][18:0];
            mult_3_b[1] = qkt_reg[14][18:0];
            mult_3_b[2] = qkt_reg[22][18:0];
            mult_3_b[3] = qkt_reg[30][18:0];
            mult_3_b[4] = qkt_reg[38][18:0];
            mult_3_b[5] = qkt_reg[46][18:0];
            mult_3_b[6] = qkt_reg[54][18:0];
            mult_3_b[7] = qkt_reg[62][18:0];
        end
        6'd8:
        begin
            mult_3_a[0] = xw_reg[24];
            mult_3_a[1] = xw_reg[25];
            mult_3_a[2] = xw_reg[26];
            mult_3_a[3] = xw_reg[27];
            mult_3_a[4] = xw_reg[28];
            mult_3_a[5] = xw_reg[29];
            mult_3_a[6] = xw_reg[30];
            mult_3_a[7] = xw_reg[31];
            mult_3_b[0] = qkt_reg[7][18:0];
            mult_3_b[1] = qkt_reg[15][18:0];
            mult_3_b[2] = qkt_reg[23][18:0];
            mult_3_b[3] = qkt_reg[31][18:0];
            mult_3_b[4] = qkt_reg[39][18:0];
            mult_3_b[5] = qkt_reg[47][18:0];
            mult_3_b[6] = qkt_reg[55][18:0];
            mult_3_b[7] = qkt_reg[63][18:0];
        end
        6'd57:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_3_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_3_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_3_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_3_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_3_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_3_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_3_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd58:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_3_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_3_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_3_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_3_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_3_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_3_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_3_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd59:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_3_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_3_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_3_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_3_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_3_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_3_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_3_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd60:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_3_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_3_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_3_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_3_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_3_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_3_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_3_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd61:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_3_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_3_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_3_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_3_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_3_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_3_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_3_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd62:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_3_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_3_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_3_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_3_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_3_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_3_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_3_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd63:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_3_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_3_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_3_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_3_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_3_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_3_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_3_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        default:
        begin
            mult_3_a[0] = 19'd0;
            mult_3_a[1] = 19'd0;
            mult_3_a[2] = 19'd0;
            mult_3_a[3] = 19'd0;
            mult_3_a[4] = 19'd0;
            mult_3_a[5] = 19'd0;
            mult_3_a[6] = 19'd0;
            mult_3_a[7] = 19'd0;
            mult_3_b[0] = 19'd0;
            mult_3_b[1] = 19'd0;
            mult_3_b[2] = 19'd0;
            mult_3_b[3] = 19'd0;
            mult_3_b[4] = 19'd0;
            mult_3_b[5] = 19'd0;
            mult_3_b[6] = 19'd0;
            mult_3_b[7] = 19'd0;
        end
        endcase
    end
    OUT:
    begin
        case(output_counter)
        6'd0:
        begin
            mult_3_a[0] = {{11{in_data_reg[24][7]}}, in_data_reg[24]};
            mult_3_a[1] = {{11{in_data_reg[25][7]}}, in_data_reg[25]};
            mult_3_a[2] = {{11{in_data_reg[26][7]}}, in_data_reg[26]};
            mult_3_a[3] = {{11{in_data_reg[27][7]}}, in_data_reg[27]};
            mult_3_a[4] = {{11{in_data_reg[28][7]}}, in_data_reg[28]};
            mult_3_a[5] = {{11{in_data_reg[29][7]}}, in_data_reg[29]};
            mult_3_a[6] = {{11{in_data_reg[30][7]}}, in_data_reg[30]};
            mult_3_a[7] = {{11{in_data_reg[31][7]}}, in_data_reg[31]};
            mult_3_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_3_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_3_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_3_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_3_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_3_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_3_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_3_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        default:
        begin
            mult_3_a[0] = 19'd0;
            mult_3_a[1] = 19'd0;
            mult_3_a[2] = 19'd0;
            mult_3_a[3] = 19'd0;
            mult_3_a[4] = 19'd0;
            mult_3_a[5] = 19'd0;
            mult_3_a[6] = 19'd0;
            mult_3_a[7] = 19'd0;
            mult_3_b[0] = 19'd0;
            mult_3_b[1] = 19'd0;
            mult_3_b[2] = 19'd0;
            mult_3_b[3] = 19'd0;
            mult_3_b[4] = 19'd0;
            mult_3_b[5] = 19'd0;
            mult_3_b[6] = 19'd0;
            mult_3_b[7] = 19'd0;
        end
        endcase
    end
    default:
    begin
        mult_3_a[0] = 19'd0;
        mult_3_a[1] = 19'd0;
        mult_3_a[2] = 19'd0;
        mult_3_a[3] = 19'd0;
        mult_3_a[4] = 19'd0;
        mult_3_a[5] = 19'd0;
        mult_3_a[6] = 19'd0;
        mult_3_a[7] = 19'd0;
        mult_3_b[0] = 19'd0;
        mult_3_b[1] = 19'd0;
        mult_3_b[2] = 19'd0;
        mult_3_b[3] = 19'd0;
        mult_3_b[4] = 19'd0;
        mult_3_b[5] = 19'd0;
        mult_3_b[6] = 19'd0;
        mult_3_b[7] = 19'd0;
    end
    endcase
end

//==================================================================
// mult_4_a mult_4_b
//==================================================================
always @ (*)
begin
    case(state)
    XWK:
    begin
        case(input_counter)
        6'd0, 6'd57:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_4_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_4_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_4_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_4_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_4_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_4_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_4_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd1, 6'd58:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_4_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_4_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_4_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_4_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_4_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_4_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_4_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd2, 6'd59:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_4_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_4_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_4_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_4_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_4_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_4_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_4_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd3, 6'd60:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_4_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_4_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_4_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_4_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_4_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_4_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_4_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd4, 6'd61:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_4_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_4_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_4_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_4_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_4_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_4_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_4_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd5, 6'd62:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_4_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_4_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_4_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_4_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_4_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_4_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_4_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd6, 6'd63:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_4_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_4_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_4_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_4_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_4_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_4_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_4_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        6'd7:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_4_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_4_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_4_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_4_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_4_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_4_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_4_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        default:
        begin
            mult_4_a[0] = 19'd0;
            mult_4_a[1] = 19'd0;
            mult_4_a[2] = 19'd0;
            mult_4_a[3] = 19'd0;
            mult_4_a[4] = 19'd0;
            mult_4_a[5] = 19'd0;
            mult_4_a[6] = 19'd0;
            mult_4_a[7] = 19'd0;
            mult_4_b[0] = 19'd0;
            mult_4_b[1] = 19'd0;
            mult_4_b[2] = 19'd0;
            mult_4_b[3] = 19'd0;
            mult_4_b[4] = 19'd0;
            mult_4_b[5] = 19'd0;
            mult_4_b[6] = 19'd0;
            mult_4_b[7] = 19'd0;
        end
        endcase
    end
    XWV:
    begin
        case(input_counter)
        6'd0:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_4_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_4_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_4_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_4_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_4_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_4_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_4_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        6'd1:
        begin
            mult_4_a[0] = xw_reg[32];
            mult_4_a[1] = xw_reg[33];
            mult_4_a[2] = xw_reg[34];
            mult_4_a[3] = xw_reg[35];
            mult_4_a[4] = xw_reg[36];
            mult_4_a[5] = xw_reg[37];
            mult_4_a[6] = xw_reg[38];
            mult_4_a[7] = xw_reg[39];
            mult_4_b[0] = qkt_reg[0][18:0];
            mult_4_b[1] = qkt_reg[8][18:0];
            mult_4_b[2] = qkt_reg[16][18:0];
            mult_4_b[3] = qkt_reg[24][18:0];
            mult_4_b[4] = qkt_reg[32][18:0];
            mult_4_b[5] = qkt_reg[40][18:0];
            mult_4_b[6] = qkt_reg[48][18:0];
            mult_4_b[7] = qkt_reg[56][18:0];
        end
        6'd2:
        begin
            mult_4_a[0] = xw_reg[32];
            mult_4_a[1] = xw_reg[33];
            mult_4_a[2] = xw_reg[34];
            mult_4_a[3] = xw_reg[35];
            mult_4_a[4] = xw_reg[36];
            mult_4_a[5] = xw_reg[37];
            mult_4_a[6] = xw_reg[38];
            mult_4_a[7] = xw_reg[39];
            mult_4_b[0] = qkt_reg[1][18:0];
            mult_4_b[1] = qkt_reg[9][18:0];
            mult_4_b[2] = qkt_reg[17][18:0];
            mult_4_b[3] = qkt_reg[25][18:0];
            mult_4_b[4] = qkt_reg[33][18:0];
            mult_4_b[5] = qkt_reg[41][18:0];
            mult_4_b[6] = qkt_reg[49][18:0];
            mult_4_b[7] = qkt_reg[57][18:0];
        end
        6'd3:
        begin
            mult_4_a[0] = xw_reg[32];
            mult_4_a[1] = xw_reg[33];
            mult_4_a[2] = xw_reg[34];
            mult_4_a[3] = xw_reg[35];
            mult_4_a[4] = xw_reg[36];
            mult_4_a[5] = xw_reg[37];
            mult_4_a[6] = xw_reg[38];
            mult_4_a[7] = xw_reg[39];
            mult_4_b[0] = qkt_reg[2][18:0];
            mult_4_b[1] = qkt_reg[10][18:0];
            mult_4_b[2] = qkt_reg[18][18:0];
            mult_4_b[3] = qkt_reg[26][18:0];
            mult_4_b[4] = qkt_reg[34][18:0];
            mult_4_b[5] = qkt_reg[42][18:0];
            mult_4_b[6] = qkt_reg[50][18:0];
            mult_4_b[7] = qkt_reg[58][18:0];
        end
        6'd4:
        begin
            mult_4_a[0] = xw_reg[32];
            mult_4_a[1] = xw_reg[33];
            mult_4_a[2] = xw_reg[34];
            mult_4_a[3] = xw_reg[35];
            mult_4_a[4] = xw_reg[36];
            mult_4_a[5] = xw_reg[37];
            mult_4_a[6] = xw_reg[38];
            mult_4_a[7] = xw_reg[39];
            mult_4_b[0] = qkt_reg[3][18:0];
            mult_4_b[1] = qkt_reg[11][18:0];
            mult_4_b[2] = qkt_reg[19][18:0];
            mult_4_b[3] = qkt_reg[27][18:0];
            mult_4_b[4] = qkt_reg[35][18:0];
            mult_4_b[5] = qkt_reg[43][18:0];
            mult_4_b[6] = qkt_reg[51][18:0];
            mult_4_b[7] = qkt_reg[59][18:0];
        end
        6'd5:
        begin
            mult_4_a[0] = xw_reg[32];
            mult_4_a[1] = xw_reg[33];
            mult_4_a[2] = xw_reg[34];
            mult_4_a[3] = xw_reg[35];
            mult_4_a[4] = xw_reg[36];
            mult_4_a[5] = xw_reg[37];
            mult_4_a[6] = xw_reg[38];
            mult_4_a[7] = xw_reg[39];
            mult_4_b[0] = qkt_reg[4][18:0];
            mult_4_b[1] = qkt_reg[12][18:0];
            mult_4_b[2] = qkt_reg[20][18:0];
            mult_4_b[3] = qkt_reg[28][18:0];
            mult_4_b[4] = qkt_reg[36][18:0];
            mult_4_b[5] = qkt_reg[44][18:0];
            mult_4_b[6] = qkt_reg[52][18:0];
            mult_4_b[7] = qkt_reg[60][18:0];
        end
        6'd6:
        begin
            mult_4_a[0] = xw_reg[32];
            mult_4_a[1] = xw_reg[33];
            mult_4_a[2] = xw_reg[34];
            mult_4_a[3] = xw_reg[35];
            mult_4_a[4] = xw_reg[36];
            mult_4_a[5] = xw_reg[37];
            mult_4_a[6] = xw_reg[38];
            mult_4_a[7] = xw_reg[39];
            mult_4_b[0] = qkt_reg[5][18:0];
            mult_4_b[1] = qkt_reg[13][18:0];
            mult_4_b[2] = qkt_reg[21][18:0];
            mult_4_b[3] = qkt_reg[29][18:0];
            mult_4_b[4] = qkt_reg[37][18:0];
            mult_4_b[5] = qkt_reg[45][18:0];
            mult_4_b[6] = qkt_reg[53][18:0];
            mult_4_b[7] = qkt_reg[61][18:0];
        end
        6'd7:
        begin
            mult_4_a[0] = xw_reg[32];
            mult_4_a[1] = xw_reg[33];
            mult_4_a[2] = xw_reg[34];
            mult_4_a[3] = xw_reg[35];
            mult_4_a[4] = xw_reg[36];
            mult_4_a[5] = xw_reg[37];
            mult_4_a[6] = xw_reg[38];
            mult_4_a[7] = xw_reg[39];
            mult_4_b[0] = qkt_reg[6][18:0];
            mult_4_b[1] = qkt_reg[14][18:0];
            mult_4_b[2] = qkt_reg[22][18:0];
            mult_4_b[3] = qkt_reg[30][18:0];
            mult_4_b[4] = qkt_reg[38][18:0];
            mult_4_b[5] = qkt_reg[46][18:0];
            mult_4_b[6] = qkt_reg[54][18:0];
            mult_4_b[7] = qkt_reg[62][18:0];
        end
        6'd8:
        begin
            mult_4_a[0] = xw_reg[32];
            mult_4_a[1] = xw_reg[33];
            mult_4_a[2] = xw_reg[34];
            mult_4_a[3] = xw_reg[35];
            mult_4_a[4] = xw_reg[36];
            mult_4_a[5] = xw_reg[37];
            mult_4_a[6] = xw_reg[38];
            mult_4_a[7] = xw_reg[39];
            mult_4_b[0] = qkt_reg[7][18:0];
            mult_4_b[1] = qkt_reg[15][18:0];
            mult_4_b[2] = qkt_reg[23][18:0];
            mult_4_b[3] = qkt_reg[31][18:0];
            mult_4_b[4] = qkt_reg[39][18:0];
            mult_4_b[5] = qkt_reg[47][18:0];
            mult_4_b[6] = qkt_reg[55][18:0];
            mult_4_b[7] = qkt_reg[63][18:0];
        end
        6'd57:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_4_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_4_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_4_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_4_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_4_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_4_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_4_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd58:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_4_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_4_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_4_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_4_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_4_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_4_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_4_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd59:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_4_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_4_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_4_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_4_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_4_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_4_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_4_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd60:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_4_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_4_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_4_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_4_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_4_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_4_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_4_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd61:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_4_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_4_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_4_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_4_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_4_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_4_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_4_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd62:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_4_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_4_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_4_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_4_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_4_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_4_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_4_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd63:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_4_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_4_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_4_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_4_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_4_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_4_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_4_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        default:
        begin
            mult_4_a[0] = 19'd0;
            mult_4_a[1] = 19'd0;
            mult_4_a[2] = 19'd0;
            mult_4_a[3] = 19'd0;
            mult_4_a[4] = 19'd0;
            mult_4_a[5] = 19'd0;
            mult_4_a[6] = 19'd0;
            mult_4_a[7] = 19'd0;
            mult_4_b[0] = 19'd0;
            mult_4_b[1] = 19'd0;
            mult_4_b[2] = 19'd0;
            mult_4_b[3] = 19'd0;
            mult_4_b[4] = 19'd0;
            mult_4_b[5] = 19'd0;
            mult_4_b[6] = 19'd0;
            mult_4_b[7] = 19'd0;
        end
        endcase
    end
    OUT:
    begin
        case(output_counter)
        6'd0:
        begin
            mult_4_a[0] = {{11{in_data_reg[32][7]}}, in_data_reg[32]};
            mult_4_a[1] = {{11{in_data_reg[33][7]}}, in_data_reg[33]};
            mult_4_a[2] = {{11{in_data_reg[34][7]}}, in_data_reg[34]};
            mult_4_a[3] = {{11{in_data_reg[35][7]}}, in_data_reg[35]};
            mult_4_a[4] = {{11{in_data_reg[36][7]}}, in_data_reg[36]};
            mult_4_a[5] = {{11{in_data_reg[37][7]}}, in_data_reg[37]};
            mult_4_a[6] = {{11{in_data_reg[38][7]}}, in_data_reg[38]};
            mult_4_a[7] = {{11{in_data_reg[39][7]}}, in_data_reg[39]};
            mult_4_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_4_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_4_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_4_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_4_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_4_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_4_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_4_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        default:
        begin
            mult_4_a[0] = 19'd0;
            mult_4_a[1] = 19'd0;
            mult_4_a[2] = 19'd0;
            mult_4_a[3] = 19'd0;
            mult_4_a[4] = 19'd0;
            mult_4_a[5] = 19'd0;
            mult_4_a[6] = 19'd0;
            mult_4_a[7] = 19'd0;
            mult_4_b[0] = 19'd0;
            mult_4_b[1] = 19'd0;
            mult_4_b[2] = 19'd0;
            mult_4_b[3] = 19'd0;
            mult_4_b[4] = 19'd0;
            mult_4_b[5] = 19'd0;
            mult_4_b[6] = 19'd0;
            mult_4_b[7] = 19'd0;
        end
        endcase
    end
    default:
    begin
        mult_4_a[0] = 19'd0;
        mult_4_a[1] = 19'd0;
        mult_4_a[2] = 19'd0;
        mult_4_a[3] = 19'd0;
        mult_4_a[4] = 19'd0;
        mult_4_a[5] = 19'd0;
        mult_4_a[6] = 19'd0;
        mult_4_a[7] = 19'd0;
        mult_4_b[0] = 19'd0;
        mult_4_b[1] = 19'd0;
        mult_4_b[2] = 19'd0;
        mult_4_b[3] = 19'd0;
        mult_4_b[4] = 19'd0;
        mult_4_b[5] = 19'd0;
        mult_4_b[6] = 19'd0;
        mult_4_b[7] = 19'd0;
    end
    endcase
end

//==================================================================
// mult_5_a mult_5_b
//==================================================================
always @ (*)
begin
    case(state)
    XWK:
    begin
        case(input_counter)
        6'd0, 6'd57:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_5_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_5_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_5_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_5_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_5_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_5_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_5_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd1, 6'd58:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_5_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_5_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_5_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_5_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_5_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_5_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_5_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd2, 6'd59:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_5_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_5_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_5_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_5_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_5_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_5_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_5_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd3, 6'd60:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_5_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_5_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_5_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_5_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_5_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_5_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_5_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd4, 6'd61:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_5_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_5_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_5_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_5_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_5_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_5_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_5_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd5, 6'd62:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_5_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_5_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_5_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_5_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_5_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_5_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_5_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd6, 6'd63:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_5_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_5_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_5_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_5_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_5_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_5_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_5_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        6'd7:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_5_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_5_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_5_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_5_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_5_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_5_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_5_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        default:
        begin
            mult_5_a[0] = 19'd0;
            mult_5_a[1] = 19'd0;
            mult_5_a[2] = 19'd0;
            mult_5_a[3] = 19'd0;
            mult_5_a[4] = 19'd0;
            mult_5_a[5] = 19'd0;
            mult_5_a[6] = 19'd0;
            mult_5_a[7] = 19'd0;
            mult_5_b[0] = 19'd0;
            mult_5_b[1] = 19'd0;
            mult_5_b[2] = 19'd0;
            mult_5_b[3] = 19'd0;
            mult_5_b[4] = 19'd0;
            mult_5_b[5] = 19'd0;
            mult_5_b[6] = 19'd0;
            mult_5_b[7] = 19'd0;
        end
        endcase
    end
    XWV:
    begin
        case(input_counter)
        6'd0:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_5_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_5_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_5_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_5_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_5_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_5_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_5_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        6'd1:
        begin
            mult_5_a[0] = xw_reg[40];
            mult_5_a[1] = xw_reg[41];
            mult_5_a[2] = xw_reg[42];
            mult_5_a[3] = xw_reg[43];
            mult_5_a[4] = xw_reg[44];
            mult_5_a[5] = xw_reg[45];
            mult_5_a[6] = xw_reg[46];
            mult_5_a[7] = xw_reg[47];
            mult_5_b[0] = qkt_reg[0][18:0];
            mult_5_b[1] = qkt_reg[8][18:0];
            mult_5_b[2] = qkt_reg[16][18:0];
            mult_5_b[3] = qkt_reg[24][18:0];
            mult_5_b[4] = qkt_reg[32][18:0];
            mult_5_b[5] = qkt_reg[40][18:0];
            mult_5_b[6] = qkt_reg[48][18:0];
            mult_5_b[7] = qkt_reg[56][18:0];
        end
        6'd2:
        begin
            mult_5_a[0] = xw_reg[40];
            mult_5_a[1] = xw_reg[41];
            mult_5_a[2] = xw_reg[42];
            mult_5_a[3] = xw_reg[43];
            mult_5_a[4] = xw_reg[44];
            mult_5_a[5] = xw_reg[45];
            mult_5_a[6] = xw_reg[46];
            mult_5_a[7] = xw_reg[47];
            mult_5_b[0] = qkt_reg[1][18:0];
            mult_5_b[1] = qkt_reg[9][18:0];
            mult_5_b[2] = qkt_reg[17][18:0];
            mult_5_b[3] = qkt_reg[25][18:0];
            mult_5_b[4] = qkt_reg[33][18:0];
            mult_5_b[5] = qkt_reg[41][18:0];
            mult_5_b[6] = qkt_reg[49][18:0];
            mult_5_b[7] = qkt_reg[57][18:0];
        end
        6'd3:
        begin
            mult_5_a[0] = xw_reg[40];
            mult_5_a[1] = xw_reg[41];
            mult_5_a[2] = xw_reg[42];
            mult_5_a[3] = xw_reg[43];
            mult_5_a[4] = xw_reg[44];
            mult_5_a[5] = xw_reg[45];
            mult_5_a[6] = xw_reg[46];
            mult_5_a[7] = xw_reg[47];
            mult_5_b[0] = qkt_reg[2][18:0];
            mult_5_b[1] = qkt_reg[10][18:0];
            mult_5_b[2] = qkt_reg[18][18:0];
            mult_5_b[3] = qkt_reg[26][18:0];
            mult_5_b[4] = qkt_reg[34][18:0];
            mult_5_b[5] = qkt_reg[42][18:0];
            mult_5_b[6] = qkt_reg[50][18:0];
            mult_5_b[7] = qkt_reg[58][18:0];
        end
        6'd4:
        begin
            mult_5_a[0] = xw_reg[40];
            mult_5_a[1] = xw_reg[41];
            mult_5_a[2] = xw_reg[42];
            mult_5_a[3] = xw_reg[43];
            mult_5_a[4] = xw_reg[44];
            mult_5_a[5] = xw_reg[45];
            mult_5_a[6] = xw_reg[46];
            mult_5_a[7] = xw_reg[47];
            mult_5_b[0] = qkt_reg[3][18:0];
            mult_5_b[1] = qkt_reg[11][18:0];
            mult_5_b[2] = qkt_reg[19][18:0];
            mult_5_b[3] = qkt_reg[27][18:0];
            mult_5_b[4] = qkt_reg[35][18:0];
            mult_5_b[5] = qkt_reg[43][18:0];
            mult_5_b[6] = qkt_reg[51][18:0];
            mult_5_b[7] = qkt_reg[59][18:0];
        end
        6'd5:
        begin
            mult_5_a[0] = xw_reg[40];
            mult_5_a[1] = xw_reg[41];
            mult_5_a[2] = xw_reg[42];
            mult_5_a[3] = xw_reg[43];
            mult_5_a[4] = xw_reg[44];
            mult_5_a[5] = xw_reg[45];
            mult_5_a[6] = xw_reg[46];
            mult_5_a[7] = xw_reg[47];
            mult_5_b[0] = qkt_reg[4][18:0];
            mult_5_b[1] = qkt_reg[12][18:0];
            mult_5_b[2] = qkt_reg[20][18:0];
            mult_5_b[3] = qkt_reg[28][18:0];
            mult_5_b[4] = qkt_reg[36][18:0];
            mult_5_b[5] = qkt_reg[44][18:0];
            mult_5_b[6] = qkt_reg[52][18:0];
            mult_5_b[7] = qkt_reg[60][18:0];
        end
        6'd6:
        begin
            mult_5_a[0] = xw_reg[40];
            mult_5_a[1] = xw_reg[41];
            mult_5_a[2] = xw_reg[42];
            mult_5_a[3] = xw_reg[43];
            mult_5_a[4] = xw_reg[44];
            mult_5_a[5] = xw_reg[45];
            mult_5_a[6] = xw_reg[46];
            mult_5_a[7] = xw_reg[47];
            mult_5_b[0] = qkt_reg[5][18:0];
            mult_5_b[1] = qkt_reg[13][18:0];
            mult_5_b[2] = qkt_reg[21][18:0];
            mult_5_b[3] = qkt_reg[29][18:0];
            mult_5_b[4] = qkt_reg[37][18:0];
            mult_5_b[5] = qkt_reg[45][18:0];
            mult_5_b[6] = qkt_reg[53][18:0];
            mult_5_b[7] = qkt_reg[61][18:0];
        end
        6'd7:
        begin
            mult_5_a[0] = xw_reg[40];
            mult_5_a[1] = xw_reg[41];
            mult_5_a[2] = xw_reg[42];
            mult_5_a[3] = xw_reg[43];
            mult_5_a[4] = xw_reg[44];
            mult_5_a[5] = xw_reg[45];
            mult_5_a[6] = xw_reg[46];
            mult_5_a[7] = xw_reg[47];
            mult_5_b[0] = qkt_reg[6][18:0];
            mult_5_b[1] = qkt_reg[14][18:0];
            mult_5_b[2] = qkt_reg[22][18:0];
            mult_5_b[3] = qkt_reg[30][18:0];
            mult_5_b[4] = qkt_reg[38][18:0];
            mult_5_b[5] = qkt_reg[46][18:0];
            mult_5_b[6] = qkt_reg[54][18:0];
            mult_5_b[7] = qkt_reg[62][18:0];
        end
        6'd8:
        begin
            mult_5_a[0] = xw_reg[40];
            mult_5_a[1] = xw_reg[41];
            mult_5_a[2] = xw_reg[42];
            mult_5_a[3] = xw_reg[43];
            mult_5_a[4] = xw_reg[44];
            mult_5_a[5] = xw_reg[45];
            mult_5_a[6] = xw_reg[46];
            mult_5_a[7] = xw_reg[47];
            mult_5_b[0] = qkt_reg[7][18:0];
            mult_5_b[1] = qkt_reg[15][18:0];
            mult_5_b[2] = qkt_reg[23][18:0];
            mult_5_b[3] = qkt_reg[31][18:0];
            mult_5_b[4] = qkt_reg[39][18:0];
            mult_5_b[5] = qkt_reg[47][18:0];
            mult_5_b[6] = qkt_reg[55][18:0];
            mult_5_b[7] = qkt_reg[63][18:0];
        end
        6'd57:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_5_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_5_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_5_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_5_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_5_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_5_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_5_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd58:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_5_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_5_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_5_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_5_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_5_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_5_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_5_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd59:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_5_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_5_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_5_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_5_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_5_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_5_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_5_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd60:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_5_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_5_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_5_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_5_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_5_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_5_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_5_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd61:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_5_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_5_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_5_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_5_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_5_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_5_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_5_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd62:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_5_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_5_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_5_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_5_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_5_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_5_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_5_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd63:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_5_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_5_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_5_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_5_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_5_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_5_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_5_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        default:
        begin
            mult_5_a[0] = 19'd0;
            mult_5_a[1] = 19'd0;
            mult_5_a[2] = 19'd0;
            mult_5_a[3] = 19'd0;
            mult_5_a[4] = 19'd0;
            mult_5_a[5] = 19'd0;
            mult_5_a[6] = 19'd0;
            mult_5_a[7] = 19'd0;
            mult_5_b[0] = 19'd0;
            mult_5_b[1] = 19'd0;
            mult_5_b[2] = 19'd0;
            mult_5_b[3] = 19'd0;
            mult_5_b[4] = 19'd0;
            mult_5_b[5] = 19'd0;
            mult_5_b[6] = 19'd0;
            mult_5_b[7] = 19'd0;
        end
        endcase
    end
    OUT:
    begin
        case(output_counter)
        6'd0:
        begin
            mult_5_a[0] = {{11{in_data_reg[40][7]}}, in_data_reg[40]};
            mult_5_a[1] = {{11{in_data_reg[41][7]}}, in_data_reg[41]};
            mult_5_a[2] = {{11{in_data_reg[42][7]}}, in_data_reg[42]};
            mult_5_a[3] = {{11{in_data_reg[43][7]}}, in_data_reg[43]};
            mult_5_a[4] = {{11{in_data_reg[44][7]}}, in_data_reg[44]};
            mult_5_a[5] = {{11{in_data_reg[45][7]}}, in_data_reg[45]};
            mult_5_a[6] = {{11{in_data_reg[46][7]}}, in_data_reg[46]};
            mult_5_a[7] = {{11{in_data_reg[47][7]}}, in_data_reg[47]};
            mult_5_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_5_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_5_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_5_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_5_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_5_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_5_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_5_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        default:
        begin
            mult_5_a[0] = 19'd0;
            mult_5_a[1] = 19'd0;
            mult_5_a[2] = 19'd0;
            mult_5_a[3] = 19'd0;
            mult_5_a[4] = 19'd0;
            mult_5_a[5] = 19'd0;
            mult_5_a[6] = 19'd0;
            mult_5_a[7] = 19'd0;
            mult_5_b[0] = 19'd0;
            mult_5_b[1] = 19'd0;
            mult_5_b[2] = 19'd0;
            mult_5_b[3] = 19'd0;
            mult_5_b[4] = 19'd0;
            mult_5_b[5] = 19'd0;
            mult_5_b[6] = 19'd0;
            mult_5_b[7] = 19'd0;
        end
        endcase
    end
    default:
    begin
        mult_5_a[0] = 19'd0;
        mult_5_a[1] = 19'd0;
        mult_5_a[2] = 19'd0;
        mult_5_a[3] = 19'd0;
        mult_5_a[4] = 19'd0;
        mult_5_a[5] = 19'd0;
        mult_5_a[6] = 19'd0;
        mult_5_a[7] = 19'd0;
        mult_5_b[0] = 19'd0;
        mult_5_b[1] = 19'd0;
        mult_5_b[2] = 19'd0;
        mult_5_b[3] = 19'd0;
        mult_5_b[4] = 19'd0;
        mult_5_b[5] = 19'd0;
        mult_5_b[6] = 19'd0;
        mult_5_b[7] = 19'd0;
    end
    endcase
end

//==================================================================
// mult_6_a mult_6_b
//==================================================================
always @ (*)
begin
    case(state)
    XWK:
    begin
        case(input_counter)
        6'd0, 6'd57:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_6_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_6_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_6_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_6_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_6_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_6_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_6_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd1, 6'd58:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_6_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_6_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_6_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_6_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_6_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_6_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_6_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd2, 6'd59:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_6_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_6_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_6_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_6_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_6_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_6_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_6_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd3, 6'd60:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_6_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_6_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_6_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_6_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_6_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_6_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_6_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd4, 6'd61:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_6_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_6_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_6_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_6_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_6_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_6_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_6_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd5, 6'd62:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_6_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_6_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_6_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_6_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_6_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_6_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_6_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd6, 6'd63:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_6_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_6_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_6_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_6_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_6_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_6_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_6_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        6'd7:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_6_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_6_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_6_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_6_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_6_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_6_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_6_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        default:
        begin
            mult_6_a[0] = 19'd0;
            mult_6_a[1] = 19'd0;
            mult_6_a[2] = 19'd0;
            mult_6_a[3] = 19'd0;
            mult_6_a[4] = 19'd0;
            mult_6_a[5] = 19'd0;
            mult_6_a[6] = 19'd0;
            mult_6_a[7] = 19'd0;
            mult_6_b[0] = 19'd0;
            mult_6_b[1] = 19'd0;
            mult_6_b[2] = 19'd0;
            mult_6_b[3] = 19'd0;
            mult_6_b[4] = 19'd0;
            mult_6_b[5] = 19'd0;
            mult_6_b[6] = 19'd0;
            mult_6_b[7] = 19'd0;
        end
        endcase
    end
    XWV:
    begin
        case(input_counter)
        6'd0:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_6_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_6_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_6_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_6_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_6_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_6_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_6_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        6'd1:
        begin
            mult_6_a[0] = xw_reg[48];
            mult_6_a[1] = xw_reg[49];
            mult_6_a[2] = xw_reg[50];
            mult_6_a[3] = xw_reg[51];
            mult_6_a[4] = xw_reg[52];
            mult_6_a[5] = xw_reg[53];
            mult_6_a[6] = xw_reg[54];
            mult_6_a[7] = xw_reg[55];
            mult_6_b[0] = qkt_reg[0][18:0];
            mult_6_b[1] = qkt_reg[8][18:0];
            mult_6_b[2] = qkt_reg[16][18:0];
            mult_6_b[3] = qkt_reg[24][18:0];
            mult_6_b[4] = qkt_reg[32][18:0];
            mult_6_b[5] = qkt_reg[40][18:0];
            mult_6_b[6] = qkt_reg[48][18:0];
            mult_6_b[7] = qkt_reg[56][18:0];
        end
        6'd2:
        begin
            mult_6_a[0] = xw_reg[48];
            mult_6_a[1] = xw_reg[49];
            mult_6_a[2] = xw_reg[50];
            mult_6_a[3] = xw_reg[51];
            mult_6_a[4] = xw_reg[52];
            mult_6_a[5] = xw_reg[53];
            mult_6_a[6] = xw_reg[54];
            mult_6_a[7] = xw_reg[55];
            mult_6_b[0] = qkt_reg[1][18:0];
            mult_6_b[1] = qkt_reg[9][18:0];
            mult_6_b[2] = qkt_reg[17][18:0];
            mult_6_b[3] = qkt_reg[25][18:0];
            mult_6_b[4] = qkt_reg[33][18:0];
            mult_6_b[5] = qkt_reg[41][18:0];
            mult_6_b[6] = qkt_reg[49][18:0];
            mult_6_b[7] = qkt_reg[57][18:0];
        end
        6'd3:
        begin
            mult_6_a[0] = xw_reg[48];
            mult_6_a[1] = xw_reg[49];
            mult_6_a[2] = xw_reg[50];
            mult_6_a[3] = xw_reg[51];
            mult_6_a[4] = xw_reg[52];
            mult_6_a[5] = xw_reg[53];
            mult_6_a[6] = xw_reg[54];
            mult_6_a[7] = xw_reg[55];
            mult_6_b[0] = qkt_reg[2][18:0];
            mult_6_b[1] = qkt_reg[10][18:0];
            mult_6_b[2] = qkt_reg[18][18:0];
            mult_6_b[3] = qkt_reg[26][18:0];
            mult_6_b[4] = qkt_reg[34][18:0];
            mult_6_b[5] = qkt_reg[42][18:0];
            mult_6_b[6] = qkt_reg[50][18:0];
            mult_6_b[7] = qkt_reg[58][18:0];
        end
        6'd4:
        begin
            mult_6_a[0] = xw_reg[48];
            mult_6_a[1] = xw_reg[49];
            mult_6_a[2] = xw_reg[50];
            mult_6_a[3] = xw_reg[51];
            mult_6_a[4] = xw_reg[52];
            mult_6_a[5] = xw_reg[53];
            mult_6_a[6] = xw_reg[54];
            mult_6_a[7] = xw_reg[55];
            mult_6_b[0] = qkt_reg[3][18:0];
            mult_6_b[1] = qkt_reg[11][18:0];
            mult_6_b[2] = qkt_reg[19][18:0];
            mult_6_b[3] = qkt_reg[27][18:0];
            mult_6_b[4] = qkt_reg[35][18:0];
            mult_6_b[5] = qkt_reg[43][18:0];
            mult_6_b[6] = qkt_reg[51][18:0];
            mult_6_b[7] = qkt_reg[59][18:0];
        end
        6'd5:
        begin
            mult_6_a[0] = xw_reg[48];
            mult_6_a[1] = xw_reg[49];
            mult_6_a[2] = xw_reg[50];
            mult_6_a[3] = xw_reg[51];
            mult_6_a[4] = xw_reg[52];
            mult_6_a[5] = xw_reg[53];
            mult_6_a[6] = xw_reg[54];
            mult_6_a[7] = xw_reg[55];
            mult_6_b[0] = qkt_reg[4][18:0];
            mult_6_b[1] = qkt_reg[12][18:0];
            mult_6_b[2] = qkt_reg[20][18:0];
            mult_6_b[3] = qkt_reg[28][18:0];
            mult_6_b[4] = qkt_reg[36][18:0];
            mult_6_b[5] = qkt_reg[44][18:0];
            mult_6_b[6] = qkt_reg[52][18:0];
            mult_6_b[7] = qkt_reg[60][18:0];
        end
        6'd6:
        begin
            mult_6_a[0] = xw_reg[48];
            mult_6_a[1] = xw_reg[49];
            mult_6_a[2] = xw_reg[50];
            mult_6_a[3] = xw_reg[51];
            mult_6_a[4] = xw_reg[52];
            mult_6_a[5] = xw_reg[53];
            mult_6_a[6] = xw_reg[54];
            mult_6_a[7] = xw_reg[55];
            mult_6_b[0] = qkt_reg[5][18:0];
            mult_6_b[1] = qkt_reg[13][18:0];
            mult_6_b[2] = qkt_reg[21][18:0];
            mult_6_b[3] = qkt_reg[29][18:0];
            mult_6_b[4] = qkt_reg[37][18:0];
            mult_6_b[5] = qkt_reg[45][18:0];
            mult_6_b[6] = qkt_reg[53][18:0];
            mult_6_b[7] = qkt_reg[61][18:0];
        end
        6'd7:
        begin
            mult_6_a[0] = xw_reg[48];
            mult_6_a[1] = xw_reg[49];
            mult_6_a[2] = xw_reg[50];
            mult_6_a[3] = xw_reg[51];
            mult_6_a[4] = xw_reg[52];
            mult_6_a[5] = xw_reg[53];
            mult_6_a[6] = xw_reg[54];
            mult_6_a[7] = xw_reg[55];
            mult_6_b[0] = qkt_reg[6][18:0];
            mult_6_b[1] = qkt_reg[14][18:0];
            mult_6_b[2] = qkt_reg[22][18:0];
            mult_6_b[3] = qkt_reg[30][18:0];
            mult_6_b[4] = qkt_reg[38][18:0];
            mult_6_b[5] = qkt_reg[46][18:0];
            mult_6_b[6] = qkt_reg[54][18:0];
            mult_6_b[7] = qkt_reg[62][18:0];
        end
        6'd8:
        begin
            mult_6_a[0] = xw_reg[48];
            mult_6_a[1] = xw_reg[49];
            mult_6_a[2] = xw_reg[50];
            mult_6_a[3] = xw_reg[51];
            mult_6_a[4] = xw_reg[52];
            mult_6_a[5] = xw_reg[53];
            mult_6_a[6] = xw_reg[54];
            mult_6_a[7] = xw_reg[55];
            mult_6_b[0] = qkt_reg[7][18:0];
            mult_6_b[1] = qkt_reg[15][18:0];
            mult_6_b[2] = qkt_reg[23][18:0];
            mult_6_b[3] = qkt_reg[31][18:0];
            mult_6_b[4] = qkt_reg[39][18:0];
            mult_6_b[5] = qkt_reg[47][18:0];
            mult_6_b[6] = qkt_reg[55][18:0];
            mult_6_b[7] = qkt_reg[63][18:0];
        end
        6'd57:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_6_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_6_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_6_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_6_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_6_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_6_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_6_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd58:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_6_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_6_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_6_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_6_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_6_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_6_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_6_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd59:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_6_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_6_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_6_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_6_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_6_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_6_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_6_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd60:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_6_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_6_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_6_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_6_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_6_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_6_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_6_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd61:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_6_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_6_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_6_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_6_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_6_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_6_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_6_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd62:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_6_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_6_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_6_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_6_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_6_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_6_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_6_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd63:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_6_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_6_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_6_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_6_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_6_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_6_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_6_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        default:
        begin
            mult_6_a[0] = 19'd0;
            mult_6_a[1] = 19'd0;
            mult_6_a[2] = 19'd0;
            mult_6_a[3] = 19'd0;
            mult_6_a[4] = 19'd0;
            mult_6_a[5] = 19'd0;
            mult_6_a[6] = 19'd0;
            mult_6_a[7] = 19'd0;
            mult_6_b[0] = 19'd0;
            mult_6_b[1] = 19'd0;
            mult_6_b[2] = 19'd0;
            mult_6_b[3] = 19'd0;
            mult_6_b[4] = 19'd0;
            mult_6_b[5] = 19'd0;
            mult_6_b[6] = 19'd0;
            mult_6_b[7] = 19'd0;
        end
        endcase
    end
    OUT:
    begin
        case(output_counter)
        6'd0:
        begin
            mult_6_a[0] = {{11{in_data_reg[48][7]}}, in_data_reg[48]};
            mult_6_a[1] = {{11{in_data_reg[49][7]}}, in_data_reg[49]};
            mult_6_a[2] = {{11{in_data_reg[50][7]}}, in_data_reg[50]};
            mult_6_a[3] = {{11{in_data_reg[51][7]}}, in_data_reg[51]};
            mult_6_a[4] = {{11{in_data_reg[52][7]}}, in_data_reg[52]};
            mult_6_a[5] = {{11{in_data_reg[53][7]}}, in_data_reg[53]};
            mult_6_a[6] = {{11{in_data_reg[54][7]}}, in_data_reg[54]};
            mult_6_a[7] = {{11{in_data_reg[55][7]}}, in_data_reg[55]};
            mult_6_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_6_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_6_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_6_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_6_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_6_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_6_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_6_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        default:
        begin
            mult_6_a[0] = 19'd0;
            mult_6_a[1] = 19'd0;
            mult_6_a[2] = 19'd0;
            mult_6_a[3] = 19'd0;
            mult_6_a[4] = 19'd0;
            mult_6_a[5] = 19'd0;
            mult_6_a[6] = 19'd0;
            mult_6_a[7] = 19'd0;
            mult_6_b[0] = 19'd0;
            mult_6_b[1] = 19'd0;
            mult_6_b[2] = 19'd0;
            mult_6_b[3] = 19'd0;
            mult_6_b[4] = 19'd0;
            mult_6_b[5] = 19'd0;
            mult_6_b[6] = 19'd0;
            mult_6_b[7] = 19'd0;
        end
        endcase
    end
    default:
    begin
        mult_6_a[0] = 19'd0;
        mult_6_a[1] = 19'd0;
        mult_6_a[2] = 19'd0;
        mult_6_a[3] = 19'd0;
        mult_6_a[4] = 19'd0;
        mult_6_a[5] = 19'd0;
        mult_6_a[6] = 19'd0;
        mult_6_a[7] = 19'd0;
        mult_6_b[0] = 19'd0;
        mult_6_b[1] = 19'd0;
        mult_6_b[2] = 19'd0;
        mult_6_b[3] = 19'd0;
        mult_6_b[4] = 19'd0;
        mult_6_b[5] = 19'd0;
        mult_6_b[6] = 19'd0;
        mult_6_b[7] = 19'd0;
    end
    endcase
end

//==================================================================
// mult_7_a mult_7_b
//==================================================================
always @ (*)
begin
    case(state)
    XWK:
    begin
        case(input_counter)
        6'd0, 6'd57:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_7_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_7_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_7_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_7_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_7_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_7_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_7_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd1, 6'd58:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_7_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_7_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_7_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_7_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_7_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_7_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_7_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd2, 6'd59:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_7_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_7_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_7_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_7_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_7_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_7_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_7_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd3, 6'd60:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_7_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_7_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_7_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_7_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_7_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_7_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_7_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd4, 6'd61:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_7_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_7_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_7_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_7_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_7_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_7_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_7_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd5, 6'd62:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_7_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_7_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_7_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_7_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_7_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_7_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_7_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd6, 6'd63:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[6][7]}}, w_reg[6]};
            mult_7_b[1] = {{11{w_reg[14][7]}}, w_reg[14]};
            mult_7_b[2] = {{11{w_reg[22][7]}}, w_reg[22]};
            mult_7_b[3] = {{11{w_reg[30][7]}}, w_reg[30]};
            mult_7_b[4] = {{11{w_reg[38][7]}}, w_reg[38]};
            mult_7_b[5] = {{11{w_reg[46][7]}}, w_reg[46]};
            mult_7_b[6] = {{11{w_reg[54][7]}}, w_reg[54]};
            mult_7_b[7] = {{11{w_reg[62][7]}}, w_reg[62]};
        end
        6'd7:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_7_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_7_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_7_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_7_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_7_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_7_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_7_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        default:
        begin
            mult_7_a[0] = 41'd0;
            mult_7_a[1] = 41'd0;
            mult_7_a[2] = 41'd0;
            mult_7_a[3] = 41'd0;
            mult_7_a[4] = 41'd0;
            mult_7_a[5] = 41'd0;
            mult_7_a[6] = 41'd0;
            mult_7_a[7] = 41'd0;
            mult_7_b[0] = 19'd0;
            mult_7_b[1] = 19'd0;
            mult_7_b[2] = 19'd0;
            mult_7_b[3] = 19'd0;
            mult_7_b[4] = 19'd0;
            mult_7_b[5] = 19'd0;
            mult_7_b[6] = 19'd0;
            mult_7_b[7] = 19'd0;
        end
        endcase
    end
    XWV:
    begin
        case(input_counter)
        6'd0:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[7][7]}}, w_reg[7]};
            mult_7_b[1] = {{11{w_reg[15][7]}}, w_reg[15]};
            mult_7_b[2] = {{11{w_reg[23][7]}}, w_reg[23]};
            mult_7_b[3] = {{11{w_reg[31][7]}}, w_reg[31]};
            mult_7_b[4] = {{11{w_reg[39][7]}}, w_reg[39]};
            mult_7_b[5] = {{11{w_reg[47][7]}}, w_reg[47]};
            mult_7_b[6] = {{11{w_reg[55][7]}}, w_reg[55]};
            mult_7_b[7] = {{11{w_reg[63][7]}}, w_reg[63]};
        end
        6'd1:
        begin
            mult_7_a[0] = {{22{qkt_reg[0][18]}}, qkt_reg[0][18:0]};
            mult_7_a[1] = {{22{qkt_reg[8][18]}}, qkt_reg[8][18:0]};
            mult_7_a[2] = {{22{qkt_reg[16][18]}}, qkt_reg[16][18:0]};
            mult_7_a[3] = {{22{qkt_reg[24][18]}}, qkt_reg[24][18:0]};
            mult_7_a[4] = {{22{qkt_reg[32][18]}}, qkt_reg[32][18:0]};
            mult_7_a[5] = {{22{qkt_reg[40][18]}}, qkt_reg[40][18:0]};
            mult_7_a[6] = {{22{qkt_reg[48][18]}}, qkt_reg[48][18:0]};
            mult_7_a[7] = {{22{qkt_reg[56][18]}}, qkt_reg[56][18:0]};
            mult_7_b[0] = xw_reg[56];
            mult_7_b[1] = xw_reg[57];
            mult_7_b[2] = xw_reg[58];
            mult_7_b[3] = xw_reg[59];
            mult_7_b[4] = xw_reg[60];
            mult_7_b[5] = xw_reg[61];
            mult_7_b[6] = xw_reg[62];
            mult_7_b[7] = xw_reg[63];
        end
        6'd2:
        begin
            mult_7_a[0] = {{22{qkt_reg[1][18]}}, qkt_reg[1][18:0]};
            mult_7_a[1] = {{22{qkt_reg[9][18]}}, qkt_reg[9][18:0]};
            mult_7_a[2] = {{22{qkt_reg[17][18]}}, qkt_reg[17][18:0]};
            mult_7_a[3] = {{22{qkt_reg[25][18]}}, qkt_reg[25][18:0]};
            mult_7_a[4] = {{22{qkt_reg[33][18]}}, qkt_reg[33][18:0]};
            mult_7_a[5] = {{22{qkt_reg[41][18]}}, qkt_reg[41][18:0]};
            mult_7_a[6] = {{22{qkt_reg[49][18]}}, qkt_reg[49][18:0]};
            mult_7_a[7] = {{22{qkt_reg[57][18]}}, qkt_reg[57][18:0]};
            mult_7_b[0] = xw_reg[56];
            mult_7_b[1] = xw_reg[57];
            mult_7_b[2] = xw_reg[58];
            mult_7_b[3] = xw_reg[59];
            mult_7_b[4] = xw_reg[60];
            mult_7_b[5] = xw_reg[61];
            mult_7_b[6] = xw_reg[62];
            mult_7_b[7] = xw_reg[63];
        end
        6'd3:
        begin
            mult_7_a[0] = {{22{qkt_reg[2][18]}}, qkt_reg[2][18:0]};
            mult_7_a[1] = {{22{qkt_reg[10][18]}}, qkt_reg[10][18:0]};
            mult_7_a[2] = {{22{qkt_reg[18][18]}}, qkt_reg[18][18:0]};
            mult_7_a[3] = {{22{qkt_reg[26][18]}}, qkt_reg[26][18:0]};
            mult_7_a[4] = {{22{qkt_reg[34][18]}}, qkt_reg[34][18:0]};
            mult_7_a[5] = {{22{qkt_reg[42][18]}}, qkt_reg[42][18:0]};
            mult_7_a[6] = {{22{qkt_reg[50][18]}}, qkt_reg[50][18:0]};
            mult_7_a[7] = {{22{qkt_reg[58][18]}}, qkt_reg[58][18:0]};
            mult_7_b[0] = xw_reg[56];
            mult_7_b[1] = xw_reg[57];
            mult_7_b[2] = xw_reg[58];
            mult_7_b[3] = xw_reg[59];
            mult_7_b[4] = xw_reg[60];
            mult_7_b[5] = xw_reg[61];
            mult_7_b[6] = xw_reg[62];
            mult_7_b[7] = xw_reg[63];
        end
        6'd4:
        begin
            mult_7_a[0] = {{22{qkt_reg[3][18]}}, qkt_reg[3][18:0]};
            mult_7_a[1] = {{22{qkt_reg[11][18]}}, qkt_reg[11][18:0]};
            mult_7_a[2] = {{22{qkt_reg[19][18]}}, qkt_reg[19][18:0]};
            mult_7_a[3] = {{22{qkt_reg[27][18]}}, qkt_reg[27][18:0]};
            mult_7_a[4] = {{22{qkt_reg[35][18]}}, qkt_reg[35][18:0]};
            mult_7_a[5] = {{22{qkt_reg[43][18]}}, qkt_reg[43][18:0]};
            mult_7_a[6] = {{22{qkt_reg[51][18]}}, qkt_reg[51][18:0]};
            mult_7_a[7] = {{22{qkt_reg[59][18]}}, qkt_reg[59][18:0]};
            mult_7_b[0] = xw_reg[56];
            mult_7_b[1] = xw_reg[57];
            mult_7_b[2] = xw_reg[58];
            mult_7_b[3] = xw_reg[59];
            mult_7_b[4] = xw_reg[60];
            mult_7_b[5] = xw_reg[61];
            mult_7_b[6] = xw_reg[62];
            mult_7_b[7] = xw_reg[63];
        end
        6'd5:
        begin
            mult_7_a[0] = {{22{qkt_reg[4][18]}}, qkt_reg[4][18:0]};
            mult_7_a[1] = {{22{qkt_reg[12][18]}}, qkt_reg[12][18:0]};
            mult_7_a[2] = {{22{qkt_reg[20][18]}}, qkt_reg[20][18:0]};
            mult_7_a[3] = {{22{qkt_reg[28][18]}}, qkt_reg[28][18:0]};
            mult_7_a[4] = {{22{qkt_reg[36][18]}}, qkt_reg[36][18:0]};
            mult_7_a[5] = {{22{qkt_reg[44][18]}}, qkt_reg[44][18:0]};
            mult_7_a[6] = {{22{qkt_reg[52][18]}}, qkt_reg[52][18:0]};
            mult_7_a[7] = {{22{qkt_reg[60][18]}}, qkt_reg[60][18:0]};
            mult_7_b[0] = xw_reg[56];
            mult_7_b[1] = xw_reg[57];
            mult_7_b[2] = xw_reg[58];
            mult_7_b[3] = xw_reg[59];
            mult_7_b[4] = xw_reg[60];
            mult_7_b[5] = xw_reg[61];
            mult_7_b[6] = xw_reg[62];
            mult_7_b[7] = xw_reg[63];
        end
        6'd6:
        begin
            mult_7_a[0] = {{22{qkt_reg[5][18]}}, qkt_reg[5][18:0]};
            mult_7_a[1] = {{22{qkt_reg[13][18]}}, qkt_reg[13][18:0]};
            mult_7_a[2] = {{22{qkt_reg[21][18]}}, qkt_reg[21][18:0]};
            mult_7_a[3] = {{22{qkt_reg[29][18]}}, qkt_reg[29][18:0]};
            mult_7_a[4] = {{22{qkt_reg[37][18]}}, qkt_reg[37][18:0]};
            mult_7_a[5] = {{22{qkt_reg[45][18]}}, qkt_reg[45][18:0]};
            mult_7_a[6] = {{22{qkt_reg[53][18]}}, qkt_reg[53][18:0]};
            mult_7_a[7] = {{22{qkt_reg[61][18]}}, qkt_reg[61][18:0]};
            mult_7_b[0] = xw_reg[56];
            mult_7_b[1] = xw_reg[57];
            mult_7_b[2] = xw_reg[58];
            mult_7_b[3] = xw_reg[59];
            mult_7_b[4] = xw_reg[60];
            mult_7_b[5] = xw_reg[61];
            mult_7_b[6] = xw_reg[62];
            mult_7_b[7] = xw_reg[63];
        end
        6'd7:
        begin
            mult_7_a[0] = {{22{qkt_reg[6][18]}}, qkt_reg[6][18:0]};
            mult_7_a[1] = {{22{qkt_reg[14][18]}}, qkt_reg[14][18:0]};
            mult_7_a[2] = {{22{qkt_reg[22][18]}}, qkt_reg[22][18:0]};
            mult_7_a[3] = {{22{qkt_reg[30][18]}}, qkt_reg[30][18:0]};
            mult_7_a[4] = {{22{qkt_reg[38][18]}}, qkt_reg[38][18:0]};
            mult_7_a[5] = {{22{qkt_reg[46][18]}}, qkt_reg[46][18:0]};
            mult_7_a[6] = {{22{qkt_reg[54][18]}}, qkt_reg[54][18:0]};
            mult_7_a[7] = {{22{qkt_reg[62][18]}}, qkt_reg[62][18:0]};
            mult_7_b[0] = xw_reg[56];
            mult_7_b[1] = xw_reg[57];
            mult_7_b[2] = xw_reg[58];
            mult_7_b[3] = xw_reg[59];
            mult_7_b[4] = xw_reg[60];
            mult_7_b[5] = xw_reg[61];
            mult_7_b[6] = xw_reg[62];
            mult_7_b[7] = xw_reg[63];
        end
        6'd8:
        begin
            mult_7_a[0] = {{22{qkt_reg[7][18]}}, qkt_reg[7][18:0]};
            mult_7_a[1] = {{22{qkt_reg[15][18]}}, qkt_reg[15][18:0]};
            mult_7_a[2] = {{22{qkt_reg[23][18]}}, qkt_reg[23][18:0]};
            mult_7_a[3] = {{22{qkt_reg[31][18]}}, qkt_reg[31][18:0]};
            mult_7_a[4] = {{22{qkt_reg[39][18]}}, qkt_reg[39][18:0]};
            mult_7_a[5] = {{22{qkt_reg[47][18]}}, qkt_reg[47][18:0]};
            mult_7_a[6] = {{22{qkt_reg[55][18]}}, qkt_reg[55][18:0]};
            mult_7_a[7] = {{22{qkt_reg[63][18]}}, qkt_reg[63][18:0]};
            mult_7_b[0] = xw_reg[56];
            mult_7_b[1] = xw_reg[57];
            mult_7_b[2] = xw_reg[58];
            mult_7_b[3] = xw_reg[59];
            mult_7_b[4] = xw_reg[60];
            mult_7_b[5] = xw_reg[61];
            mult_7_b[6] = xw_reg[62];
            mult_7_b[7] = xw_reg[63];
        end
        6'd57:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[0][7]}}, w_reg[0]};
            mult_7_b[1] = {{11{w_reg[8][7]}}, w_reg[8]};
            mult_7_b[2] = {{11{w_reg[16][7]}}, w_reg[16]};
            mult_7_b[3] = {{11{w_reg[24][7]}}, w_reg[24]};
            mult_7_b[4] = {{11{w_reg[32][7]}}, w_reg[32]};
            mult_7_b[5] = {{11{w_reg[40][7]}}, w_reg[40]};
            mult_7_b[6] = {{11{w_reg[48][7]}}, w_reg[48]};
            mult_7_b[7] = {{11{w_reg[56][7]}}, w_reg[56]};
        end
        6'd58:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[1][7]}}, w_reg[1]};
            mult_7_b[1] = {{11{w_reg[9][7]}}, w_reg[9]};
            mult_7_b[2] = {{11{w_reg[17][7]}}, w_reg[17]};
            mult_7_b[3] = {{11{w_reg[25][7]}}, w_reg[25]};
            mult_7_b[4] = {{11{w_reg[33][7]}}, w_reg[33]};
            mult_7_b[5] = {{11{w_reg[41][7]}}, w_reg[41]};
            mult_7_b[6] = {{11{w_reg[49][7]}}, w_reg[49]};
            mult_7_b[7] = {{11{w_reg[57][7]}}, w_reg[57]};
        end
        6'd59:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[2][7]}}, w_reg[2]};
            mult_7_b[1] = {{11{w_reg[10][7]}}, w_reg[10]};
            mult_7_b[2] = {{11{w_reg[18][7]}}, w_reg[18]};
            mult_7_b[3] = {{11{w_reg[26][7]}}, w_reg[26]};
            mult_7_b[4] = {{11{w_reg[34][7]}}, w_reg[34]};
            mult_7_b[5] = {{11{w_reg[42][7]}}, w_reg[42]};
            mult_7_b[6] = {{11{w_reg[50][7]}}, w_reg[50]};
            mult_7_b[7] = {{11{w_reg[58][7]}}, w_reg[58]};
        end
        6'd60:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[3][7]}}, w_reg[3]};
            mult_7_b[1] = {{11{w_reg[11][7]}}, w_reg[11]};
            mult_7_b[2] = {{11{w_reg[19][7]}}, w_reg[19]};
            mult_7_b[3] = {{11{w_reg[27][7]}}, w_reg[27]};
            mult_7_b[4] = {{11{w_reg[35][7]}}, w_reg[35]};
            mult_7_b[5] = {{11{w_reg[43][7]}}, w_reg[43]};
            mult_7_b[6] = {{11{w_reg[51][7]}}, w_reg[51]};
            mult_7_b[7] = {{11{w_reg[59][7]}}, w_reg[59]};
        end
        6'd61:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[4][7]}}, w_reg[4]};
            mult_7_b[1] = {{11{w_reg[12][7]}}, w_reg[12]};
            mult_7_b[2] = {{11{w_reg[20][7]}}, w_reg[20]};
            mult_7_b[3] = {{11{w_reg[28][7]}}, w_reg[28]};
            mult_7_b[4] = {{11{w_reg[36][7]}}, w_reg[36]};
            mult_7_b[5] = {{11{w_reg[44][7]}}, w_reg[44]};
            mult_7_b[6] = {{11{w_reg[52][7]}}, w_reg[52]};
            mult_7_b[7] = {{11{w_reg[60][7]}}, w_reg[60]};
        end
        6'd62:
        begin
            mult_7_a[0] = {{33{in_data_reg[56][7]}}, in_data_reg[56]};
            mult_7_a[1] = {{33{in_data_reg[57][7]}}, in_data_reg[57]};
            mult_7_a[2] = {{33{in_data_reg[58][7]}}, in_data_reg[58]};
            mult_7_a[3] = {{33{in_data_reg[59][7]}}, in_data_reg[59]};
            mult_7_a[4] = {{33{in_data_reg[60][7]}}, in_data_reg[60]};
            mult_7_a[5] = {{33{in_data_reg[61][7]}}, in_data_reg[61]};
            mult_7_a[6] = {{33{in_data_reg[62][7]}}, in_data_reg[62]};
            mult_7_a[7] = {{33{in_data_reg[63][7]}}, in_data_reg[63]};
            mult_7_b[0] = {{11{w_reg[5][7]}}, w_reg[5]};
            mult_7_b[1] = {{11{w_reg[13][7]}}, w_reg[13]};
            mult_7_b[2] = {{11{w_reg[21][7]}}, w_reg[21]};
            mult_7_b[3] = {{11{w_reg[29][7]}}, w_reg[29]};
            mult_7_b[4] = {{11{w_reg[37][7]}}, w_reg[37]};
            mult_7_b[5] = {{11{w_reg[45][7]}}, w_reg[45]};
            mult_7_b[6] = {{11{w_reg[53][7]}}, w_reg[53]};
            mult_7_b[7] = {{11{w_reg[61][7]}}, w_reg[61]};
        end
        6'd63:
        begin
            mult_7_a[0] = qkt_reg[0];
            mult_7_a[1] = qkt_reg[1];
            mult_7_a[2] = qkt_reg[2];
            mult_7_a[3] = qkt_reg[3];
            mult_7_a[4] = qkt_reg[4];
            mult_7_a[5] = qkt_reg[5];
            mult_7_a[6] = qkt_reg[6];
            mult_7_a[7] = qkt_reg[7];
            mult_7_b[0] = xw_reg[0];
            mult_7_b[1] = xw_reg[8];
            mult_7_b[2] = xw_reg[16];
            mult_7_b[3] = xw_reg[24];
            mult_7_b[4] = xw_reg[32];
            mult_7_b[5] = xw_reg[40];
            mult_7_b[6] = xw_reg[48];
            mult_7_b[7] = xw_reg[56];
        end
        default:
        begin
            mult_7_a[0] = 41'd0;
            mult_7_a[1] = 41'd0;
            mult_7_a[2] = 41'd0;
            mult_7_a[3] = 41'd0;
            mult_7_a[4] = 41'd0;
            mult_7_a[5] = 41'd0;
            mult_7_a[6] = 41'd0;
            mult_7_a[7] = 41'd0;
            mult_7_b[0] = 19'd0;
            mult_7_b[1] = 19'd0;
            mult_7_b[2] = 19'd0;
            mult_7_b[3] = 19'd0;
            mult_7_b[4] = 19'd0;
            mult_7_b[5] = 19'd0;
            mult_7_b[6] = 19'd0;
            mult_7_b[7] = 19'd0;
        end
        endcase
    end
    OUT:
    begin
        case(output_counter)
        6'd0:
        begin
            mult_7_a[0] = qkt_reg[0];
            mult_7_a[1] = qkt_reg[1];
            mult_7_a[2] = qkt_reg[2];
            mult_7_a[3] = qkt_reg[3];
            mult_7_a[4] = qkt_reg[4];
            mult_7_a[5] = qkt_reg[5];
            mult_7_a[6] = qkt_reg[6];
            mult_7_a[7] = qkt_reg[7];
            mult_7_b[0] = xw_reg[1];
            mult_7_b[1] = xw_reg[9];
            mult_7_b[2] = xw_reg[17];
            mult_7_b[3] = xw_reg[25];
            mult_7_b[4] = xw_reg[33];
            mult_7_b[5] = xw_reg[41];
            mult_7_b[6] = xw_reg[49];
            mult_7_b[7] = xw_reg[57];
        end
        6'd1:
        begin
            mult_7_a[0] = qkt_reg[0];
            mult_7_a[1] = qkt_reg[1];
            mult_7_a[2] = qkt_reg[2];
            mult_7_a[3] = qkt_reg[3];
            mult_7_a[4] = qkt_reg[4];
            mult_7_a[5] = qkt_reg[5];
            mult_7_a[6] = qkt_reg[6];
            mult_7_a[7] = qkt_reg[7];
            mult_7_b[0] = xw_reg[2];
            mult_7_b[1] = xw_reg[10];
            mult_7_b[2] = xw_reg[18];
            mult_7_b[3] = xw_reg[26];
            mult_7_b[4] = xw_reg[34];
            mult_7_b[5] = xw_reg[42];
            mult_7_b[6] = xw_reg[50];
            mult_7_b[7] = xw_reg[58];
        end
        6'd2:
        begin
            mult_7_a[0] = qkt_reg[0];
            mult_7_a[1] = qkt_reg[1];
            mult_7_a[2] = qkt_reg[2];
            mult_7_a[3] = qkt_reg[3];
            mult_7_a[4] = qkt_reg[4];
            mult_7_a[5] = qkt_reg[5];
            mult_7_a[6] = qkt_reg[6];
            mult_7_a[7] = qkt_reg[7];
            mult_7_b[0] = xw_reg[3];
            mult_7_b[1] = xw_reg[11];
            mult_7_b[2] = xw_reg[19];
            mult_7_b[3] = xw_reg[27];
            mult_7_b[4] = xw_reg[35];
            mult_7_b[5] = xw_reg[43];
            mult_7_b[6] = xw_reg[51];
            mult_7_b[7] = xw_reg[59];
        end
        6'd3:
        begin
            mult_7_a[0] = qkt_reg[0];
            mult_7_a[1] = qkt_reg[1];
            mult_7_a[2] = qkt_reg[2];
            mult_7_a[3] = qkt_reg[3];
            mult_7_a[4] = qkt_reg[4];
            mult_7_a[5] = qkt_reg[5];
            mult_7_a[6] = qkt_reg[6];
            mult_7_a[7] = qkt_reg[7];
            mult_7_b[0] = xw_reg[4];
            mult_7_b[1] = xw_reg[12];
            mult_7_b[2] = xw_reg[20];
            mult_7_b[3] = xw_reg[28];
            mult_7_b[4] = xw_reg[36];
            mult_7_b[5] = xw_reg[44];
            mult_7_b[6] = xw_reg[52];
            mult_7_b[7] = xw_reg[60];
        end
        6'd4:
        begin
            mult_7_a[0] = qkt_reg[0];
            mult_7_a[1] = qkt_reg[1];
            mult_7_a[2] = qkt_reg[2];
            mult_7_a[3] = qkt_reg[3];
            mult_7_a[4] = qkt_reg[4];
            mult_7_a[5] = qkt_reg[5];
            mult_7_a[6] = qkt_reg[6];
            mult_7_a[7] = qkt_reg[7];
            mult_7_b[0] = xw_reg[5];
            mult_7_b[1] = xw_reg[13];
            mult_7_b[2] = xw_reg[21];
            mult_7_b[3] = xw_reg[29];
            mult_7_b[4] = xw_reg[37];
            mult_7_b[5] = xw_reg[45];
            mult_7_b[6] = xw_reg[53];
            mult_7_b[7] = xw_reg[61];
        end
        6'd5:
        begin
            mult_7_a[0] = qkt_reg[0];
            mult_7_a[1] = qkt_reg[1];
            mult_7_a[2] = qkt_reg[2];
            mult_7_a[3] = qkt_reg[3];
            mult_7_a[4] = qkt_reg[4];
            mult_7_a[5] = qkt_reg[5];
            mult_7_a[6] = qkt_reg[6];
            mult_7_a[7] = qkt_reg[7];
            mult_7_b[0] = xw_reg[6];
            mult_7_b[1] = xw_reg[14];
            mult_7_b[2] = xw_reg[22];
            mult_7_b[3] = xw_reg[30];
            mult_7_b[4] = xw_reg[38];
            mult_7_b[5] = xw_reg[46];
            mult_7_b[6] = xw_reg[54];
            mult_7_b[7] = xw_reg[62];
        end
        6'd6:
        begin
            mult_7_a[0] = qkt_reg[0];
            mult_7_a[1] = qkt_reg[1];
            mult_7_a[2] = qkt_reg[2];
            mult_7_a[3] = qkt_reg[3];
            mult_7_a[4] = qkt_reg[4];
            mult_7_a[5] = qkt_reg[5];
            mult_7_a[6] = qkt_reg[6];
            mult_7_a[7] = qkt_reg[7];
            mult_7_b[0] = xw_reg[7];
            mult_7_b[1] = xw_reg[15];
            mult_7_b[2] = xw_reg[23];
            mult_7_b[3] = xw_reg[31];
            mult_7_b[4] = xw_reg[39];
            mult_7_b[5] = xw_reg[47];
            mult_7_b[6] = xw_reg[55];
            mult_7_b[7] = xw_reg[63];
        end
        6'd7:
        begin
            mult_7_a[0] = qkt_reg[8];
            mult_7_a[1] = qkt_reg[9];
            mult_7_a[2] = qkt_reg[10];
            mult_7_a[3] = qkt_reg[11];
            mult_7_a[4] = qkt_reg[12];
            mult_7_a[5] = qkt_reg[13];
            mult_7_a[6] = qkt_reg[14];
            mult_7_a[7] = qkt_reg[15];
            mult_7_b[0] = xw_reg[0];
            mult_7_b[1] = xw_reg[8];
            mult_7_b[2] = xw_reg[16];
            mult_7_b[3] = xw_reg[24];
            mult_7_b[4] = xw_reg[32];
            mult_7_b[5] = xw_reg[40];
            mult_7_b[6] = xw_reg[48];
            mult_7_b[7] = xw_reg[56];
        end
        6'd8:
        begin
            mult_7_a[0] = qkt_reg[8];
            mult_7_a[1] = qkt_reg[9];
            mult_7_a[2] = qkt_reg[10];
            mult_7_a[3] = qkt_reg[11];
            mult_7_a[4] = qkt_reg[12];
            mult_7_a[5] = qkt_reg[13];
            mult_7_a[6] = qkt_reg[14];
            mult_7_a[7] = qkt_reg[15];
            mult_7_b[0] = xw_reg[1];
            mult_7_b[1] = xw_reg[9];
            mult_7_b[2] = xw_reg[17];
            mult_7_b[3] = xw_reg[25];
            mult_7_b[4] = xw_reg[33];
            mult_7_b[5] = xw_reg[41];
            mult_7_b[6] = xw_reg[49];
            mult_7_b[7] = xw_reg[57];
        end
        6'd9:
        begin
            mult_7_a[0] = qkt_reg[8];
            mult_7_a[1] = qkt_reg[9];
            mult_7_a[2] = qkt_reg[10];
            mult_7_a[3] = qkt_reg[11];
            mult_7_a[4] = qkt_reg[12];
            mult_7_a[5] = qkt_reg[13];
            mult_7_a[6] = qkt_reg[14];
            mult_7_a[7] = qkt_reg[15];
            mult_7_b[0] = xw_reg[2];
            mult_7_b[1] = xw_reg[10];
            mult_7_b[2] = xw_reg[18];
            mult_7_b[3] = xw_reg[26];
            mult_7_b[4] = xw_reg[34];
            mult_7_b[5] = xw_reg[42];
            mult_7_b[6] = xw_reg[50];
            mult_7_b[7] = xw_reg[58];
        end
        6'd10:
        begin
            mult_7_a[0] = qkt_reg[8];
            mult_7_a[1] = qkt_reg[9];
            mult_7_a[2] = qkt_reg[10];
            mult_7_a[3] = qkt_reg[11];
            mult_7_a[4] = qkt_reg[12];
            mult_7_a[5] = qkt_reg[13];
            mult_7_a[6] = qkt_reg[14];
            mult_7_a[7] = qkt_reg[15];
            mult_7_b[0] = xw_reg[3];
            mult_7_b[1] = xw_reg[11];
            mult_7_b[2] = xw_reg[19];
            mult_7_b[3] = xw_reg[27];
            mult_7_b[4] = xw_reg[35];
            mult_7_b[5] = xw_reg[43];
            mult_7_b[6] = xw_reg[51];
            mult_7_b[7] = xw_reg[59];
        end
        6'd11:
        begin
            mult_7_a[0] = qkt_reg[8];
            mult_7_a[1] = qkt_reg[9];
            mult_7_a[2] = qkt_reg[10];
            mult_7_a[3] = qkt_reg[11];
            mult_7_a[4] = qkt_reg[12];
            mult_7_a[5] = qkt_reg[13];
            mult_7_a[6] = qkt_reg[14];
            mult_7_a[7] = qkt_reg[15];
            mult_7_b[0] = xw_reg[4];
            mult_7_b[1] = xw_reg[12];
            mult_7_b[2] = xw_reg[20];
            mult_7_b[3] = xw_reg[28];
            mult_7_b[4] = xw_reg[36];
            mult_7_b[5] = xw_reg[44];
            mult_7_b[6] = xw_reg[52];
            mult_7_b[7] = xw_reg[60];
        end
        6'd12:
        begin
            mult_7_a[0] = qkt_reg[8];
            mult_7_a[1] = qkt_reg[9];
            mult_7_a[2] = qkt_reg[10];
            mult_7_a[3] = qkt_reg[11];
            mult_7_a[4] = qkt_reg[12];
            mult_7_a[5] = qkt_reg[13];
            mult_7_a[6] = qkt_reg[14];
            mult_7_a[7] = qkt_reg[15];
            mult_7_b[0] = xw_reg[5];
            mult_7_b[1] = xw_reg[13];
            mult_7_b[2] = xw_reg[21];
            mult_7_b[3] = xw_reg[29];
            mult_7_b[4] = xw_reg[37];
            mult_7_b[5] = xw_reg[45];
            mult_7_b[6] = xw_reg[53];
            mult_7_b[7] = xw_reg[61];
        end
        6'd13:
        begin
            mult_7_a[0] = qkt_reg[8];
            mult_7_a[1] = qkt_reg[9];
            mult_7_a[2] = qkt_reg[10];
            mult_7_a[3] = qkt_reg[11];
            mult_7_a[4] = qkt_reg[12];
            mult_7_a[5] = qkt_reg[13];
            mult_7_a[6] = qkt_reg[14];
            mult_7_a[7] = qkt_reg[15];
            mult_7_b[0] = xw_reg[6];
            mult_7_b[1] = xw_reg[14];
            mult_7_b[2] = xw_reg[22];
            mult_7_b[3] = xw_reg[30];
            mult_7_b[4] = xw_reg[38];
            mult_7_b[5] = xw_reg[46];
            mult_7_b[6] = xw_reg[54];
            mult_7_b[7] = xw_reg[62];
        end
        6'd14:
        begin
            mult_7_a[0] = qkt_reg[8];
            mult_7_a[1] = qkt_reg[9];
            mult_7_a[2] = qkt_reg[10];
            mult_7_a[3] = qkt_reg[11];
            mult_7_a[4] = qkt_reg[12];
            mult_7_a[5] = qkt_reg[13];
            mult_7_a[6] = qkt_reg[14];
            mult_7_a[7] = qkt_reg[15];
            mult_7_b[0] = xw_reg[7];
            mult_7_b[1] = xw_reg[15];
            mult_7_b[2] = xw_reg[23];
            mult_7_b[3] = xw_reg[31];
            mult_7_b[4] = xw_reg[39];
            mult_7_b[5] = xw_reg[47];
            mult_7_b[6] = xw_reg[55];
            mult_7_b[7] = xw_reg[63];
        end
        6'd15:
        begin
            mult_7_a[0] = qkt_reg[16];
            mult_7_a[1] = qkt_reg[17];
            mult_7_a[2] = qkt_reg[18];
            mult_7_a[3] = qkt_reg[19];
            mult_7_a[4] = qkt_reg[20];
            mult_7_a[5] = qkt_reg[21];
            mult_7_a[6] = qkt_reg[22];
            mult_7_a[7] = qkt_reg[23];
            mult_7_b[0] = xw_reg[0];
            mult_7_b[1] = xw_reg[8];
            mult_7_b[2] = xw_reg[16];
            mult_7_b[3] = xw_reg[24];
            mult_7_b[4] = xw_reg[32];
            mult_7_b[5] = xw_reg[40];
            mult_7_b[6] = xw_reg[48];
            mult_7_b[7] = xw_reg[56];
        end
        6'd16:
        begin
            mult_7_a[0] = qkt_reg[16];
            mult_7_a[1] = qkt_reg[17];
            mult_7_a[2] = qkt_reg[18];
            mult_7_a[3] = qkt_reg[19];
            mult_7_a[4] = qkt_reg[20];
            mult_7_a[5] = qkt_reg[21];
            mult_7_a[6] = qkt_reg[22];
            mult_7_a[7] = qkt_reg[23];
            mult_7_b[0] = xw_reg[1];
            mult_7_b[1] = xw_reg[9];
            mult_7_b[2] = xw_reg[17];
            mult_7_b[3] = xw_reg[25];
            mult_7_b[4] = xw_reg[33];
            mult_7_b[5] = xw_reg[41];
            mult_7_b[6] = xw_reg[49];
            mult_7_b[7] = xw_reg[57];
        end
        6'd17:
        begin
            mult_7_a[0] = qkt_reg[16];
            mult_7_a[1] = qkt_reg[17];
            mult_7_a[2] = qkt_reg[18];
            mult_7_a[3] = qkt_reg[19];
            mult_7_a[4] = qkt_reg[20];
            mult_7_a[5] = qkt_reg[21];
            mult_7_a[6] = qkt_reg[22];
            mult_7_a[7] = qkt_reg[23];
            mult_7_b[0] = xw_reg[2];
            mult_7_b[1] = xw_reg[10];
            mult_7_b[2] = xw_reg[18];
            mult_7_b[3] = xw_reg[26];
            mult_7_b[4] = xw_reg[34];
            mult_7_b[5] = xw_reg[42];
            mult_7_b[6] = xw_reg[50];
            mult_7_b[7] = xw_reg[58];
        end
        6'd18:
        begin
            mult_7_a[0] = qkt_reg[16];
            mult_7_a[1] = qkt_reg[17];
            mult_7_a[2] = qkt_reg[18];
            mult_7_a[3] = qkt_reg[19];
            mult_7_a[4] = qkt_reg[20];
            mult_7_a[5] = qkt_reg[21];
            mult_7_a[6] = qkt_reg[22];
            mult_7_a[7] = qkt_reg[23];
            mult_7_b[0] = xw_reg[3];
            mult_7_b[1] = xw_reg[11];
            mult_7_b[2] = xw_reg[19];
            mult_7_b[3] = xw_reg[27];
            mult_7_b[4] = xw_reg[35];
            mult_7_b[5] = xw_reg[43];
            mult_7_b[6] = xw_reg[51];
            mult_7_b[7] = xw_reg[59];
        end
        6'd19:
        begin
            mult_7_a[0] = qkt_reg[16];
            mult_7_a[1] = qkt_reg[17];
            mult_7_a[2] = qkt_reg[18];
            mult_7_a[3] = qkt_reg[19];
            mult_7_a[4] = qkt_reg[20];
            mult_7_a[5] = qkt_reg[21];
            mult_7_a[6] = qkt_reg[22];
            mult_7_a[7] = qkt_reg[23];
            mult_7_b[0] = xw_reg[4];
            mult_7_b[1] = xw_reg[12];
            mult_7_b[2] = xw_reg[20];
            mult_7_b[3] = xw_reg[28];
            mult_7_b[4] = xw_reg[36];
            mult_7_b[5] = xw_reg[44];
            mult_7_b[6] = xw_reg[52];
            mult_7_b[7] = xw_reg[60];
        end
        6'd20:
        begin
            mult_7_a[0] = qkt_reg[16];
            mult_7_a[1] = qkt_reg[17];
            mult_7_a[2] = qkt_reg[18];
            mult_7_a[3] = qkt_reg[19];
            mult_7_a[4] = qkt_reg[20];
            mult_7_a[5] = qkt_reg[21];
            mult_7_a[6] = qkt_reg[22];
            mult_7_a[7] = qkt_reg[23];
            mult_7_b[0] = xw_reg[5];
            mult_7_b[1] = xw_reg[13];
            mult_7_b[2] = xw_reg[21];
            mult_7_b[3] = xw_reg[29];
            mult_7_b[4] = xw_reg[37];
            mult_7_b[5] = xw_reg[45];
            mult_7_b[6] = xw_reg[53];
            mult_7_b[7] = xw_reg[61];
        end
        6'd21:
        begin
            mult_7_a[0] = qkt_reg[16];
            mult_7_a[1] = qkt_reg[17];
            mult_7_a[2] = qkt_reg[18];
            mult_7_a[3] = qkt_reg[19];
            mult_7_a[4] = qkt_reg[20];
            mult_7_a[5] = qkt_reg[21];
            mult_7_a[6] = qkt_reg[22];
            mult_7_a[7] = qkt_reg[23];
            mult_7_b[0] = xw_reg[6];
            mult_7_b[1] = xw_reg[14];
            mult_7_b[2] = xw_reg[22];
            mult_7_b[3] = xw_reg[30];
            mult_7_b[4] = xw_reg[38];
            mult_7_b[5] = xw_reg[46];
            mult_7_b[6] = xw_reg[54];
            mult_7_b[7] = xw_reg[62];
        end
        6'd22:
        begin
            mult_7_a[0] = qkt_reg[16];
            mult_7_a[1] = qkt_reg[17];
            mult_7_a[2] = qkt_reg[18];
            mult_7_a[3] = qkt_reg[19];
            mult_7_a[4] = qkt_reg[20];
            mult_7_a[5] = qkt_reg[21];
            mult_7_a[6] = qkt_reg[22];
            mult_7_a[7] = qkt_reg[23];
            mult_7_b[0] = xw_reg[7];
            mult_7_b[1] = xw_reg[15];
            mult_7_b[2] = xw_reg[23];
            mult_7_b[3] = xw_reg[31];
            mult_7_b[4] = xw_reg[39];
            mult_7_b[5] = xw_reg[47];
            mult_7_b[6] = xw_reg[55];
            mult_7_b[7] = xw_reg[63];
        end
        6'd23:
        begin
            mult_7_a[0] = qkt_reg[24];
            mult_7_a[1] = qkt_reg[25];
            mult_7_a[2] = qkt_reg[26];
            mult_7_a[3] = qkt_reg[27];
            mult_7_a[4] = qkt_reg[28];
            mult_7_a[5] = qkt_reg[29];
            mult_7_a[6] = qkt_reg[30];
            mult_7_a[7] = qkt_reg[31];
            mult_7_b[0] = xw_reg[0];
            mult_7_b[1] = xw_reg[8];
            mult_7_b[2] = xw_reg[16];
            mult_7_b[3] = xw_reg[24];
            mult_7_b[4] = xw_reg[32];
            mult_7_b[5] = xw_reg[40];
            mult_7_b[6] = xw_reg[48];
            mult_7_b[7] = xw_reg[56];
        end
        6'd24:
        begin
            mult_7_a[0] = qkt_reg[24];
            mult_7_a[1] = qkt_reg[25];
            mult_7_a[2] = qkt_reg[26];
            mult_7_a[3] = qkt_reg[27];
            mult_7_a[4] = qkt_reg[28];
            mult_7_a[5] = qkt_reg[29];
            mult_7_a[6] = qkt_reg[30];
            mult_7_a[7] = qkt_reg[31];
            mult_7_b[0] = xw_reg[1];
            mult_7_b[1] = xw_reg[9];
            mult_7_b[2] = xw_reg[17];
            mult_7_b[3] = xw_reg[25];
            mult_7_b[4] = xw_reg[33];
            mult_7_b[5] = xw_reg[41];
            mult_7_b[6] = xw_reg[49];
            mult_7_b[7] = xw_reg[57];
        end
        6'd25:
        begin
            mult_7_a[0] = qkt_reg[24];
            mult_7_a[1] = qkt_reg[25];
            mult_7_a[2] = qkt_reg[26];
            mult_7_a[3] = qkt_reg[27];
            mult_7_a[4] = qkt_reg[28];
            mult_7_a[5] = qkt_reg[29];
            mult_7_a[6] = qkt_reg[30];
            mult_7_a[7] = qkt_reg[31];
            mult_7_b[0] = xw_reg[2];
            mult_7_b[1] = xw_reg[10];
            mult_7_b[2] = xw_reg[18];
            mult_7_b[3] = xw_reg[26];
            mult_7_b[4] = xw_reg[34];
            mult_7_b[5] = xw_reg[42];
            mult_7_b[6] = xw_reg[50];
            mult_7_b[7] = xw_reg[58];
        end
        6'd26:
        begin
            mult_7_a[0] = qkt_reg[24];
            mult_7_a[1] = qkt_reg[25];
            mult_7_a[2] = qkt_reg[26];
            mult_7_a[3] = qkt_reg[27];
            mult_7_a[4] = qkt_reg[28];
            mult_7_a[5] = qkt_reg[29];
            mult_7_a[6] = qkt_reg[30];
            mult_7_a[7] = qkt_reg[31];
            mult_7_b[0] = xw_reg[3];
            mult_7_b[1] = xw_reg[11];
            mult_7_b[2] = xw_reg[19];
            mult_7_b[3] = xw_reg[27];
            mult_7_b[4] = xw_reg[35];
            mult_7_b[5] = xw_reg[43];
            mult_7_b[6] = xw_reg[51];
            mult_7_b[7] = xw_reg[59];
        end
        6'd27:
        begin
            mult_7_a[0] = qkt_reg[24];
            mult_7_a[1] = qkt_reg[25];
            mult_7_a[2] = qkt_reg[26];
            mult_7_a[3] = qkt_reg[27];
            mult_7_a[4] = qkt_reg[28];
            mult_7_a[5] = qkt_reg[29];
            mult_7_a[6] = qkt_reg[30];
            mult_7_a[7] = qkt_reg[31];
            mult_7_b[0] = xw_reg[4];
            mult_7_b[1] = xw_reg[12];
            mult_7_b[2] = xw_reg[20];
            mult_7_b[3] = xw_reg[28];
            mult_7_b[4] = xw_reg[36];
            mult_7_b[5] = xw_reg[44];
            mult_7_b[6] = xw_reg[52];
            mult_7_b[7] = xw_reg[60];
        end
        6'd28:
        begin
            mult_7_a[0] = qkt_reg[24];
            mult_7_a[1] = qkt_reg[25];
            mult_7_a[2] = qkt_reg[26];
            mult_7_a[3] = qkt_reg[27];
            mult_7_a[4] = qkt_reg[28];
            mult_7_a[5] = qkt_reg[29];
            mult_7_a[6] = qkt_reg[30];
            mult_7_a[7] = qkt_reg[31];
            mult_7_b[0] = xw_reg[5];
            mult_7_b[1] = xw_reg[13];
            mult_7_b[2] = xw_reg[21];
            mult_7_b[3] = xw_reg[29];
            mult_7_b[4] = xw_reg[37];
            mult_7_b[5] = xw_reg[45];
            mult_7_b[6] = xw_reg[53];
            mult_7_b[7] = xw_reg[61];
        end
        6'd29:
        begin
            mult_7_a[0] = qkt_reg[24];
            mult_7_a[1] = qkt_reg[25];
            mult_7_a[2] = qkt_reg[26];
            mult_7_a[3] = qkt_reg[27];
            mult_7_a[4] = qkt_reg[28];
            mult_7_a[5] = qkt_reg[29];
            mult_7_a[6] = qkt_reg[30];
            mult_7_a[7] = qkt_reg[31];
            mult_7_b[0] = xw_reg[6];
            mult_7_b[1] = xw_reg[14];
            mult_7_b[2] = xw_reg[22];
            mult_7_b[3] = xw_reg[30];
            mult_7_b[4] = xw_reg[38];
            mult_7_b[5] = xw_reg[46];
            mult_7_b[6] = xw_reg[54];
            mult_7_b[7] = xw_reg[62];
        end
        6'd30:
        begin
            mult_7_a[0] = qkt_reg[24];
            mult_7_a[1] = qkt_reg[25];
            mult_7_a[2] = qkt_reg[26];
            mult_7_a[3] = qkt_reg[27];
            mult_7_a[4] = qkt_reg[28];
            mult_7_a[5] = qkt_reg[29];
            mult_7_a[6] = qkt_reg[30];
            mult_7_a[7] = qkt_reg[31];
            mult_7_b[0] = xw_reg[7];
            mult_7_b[1] = xw_reg[15];
            mult_7_b[2] = xw_reg[23];
            mult_7_b[3] = xw_reg[31];
            mult_7_b[4] = xw_reg[39];
            mult_7_b[5] = xw_reg[47];
            mult_7_b[6] = xw_reg[55];
            mult_7_b[7] = xw_reg[63];
        end
        6'd31:
        begin
            mult_7_a[0] = qkt_reg[32];
            mult_7_a[1] = qkt_reg[33];
            mult_7_a[2] = qkt_reg[34];
            mult_7_a[3] = qkt_reg[35];
            mult_7_a[4] = qkt_reg[36];
            mult_7_a[5] = qkt_reg[37];
            mult_7_a[6] = qkt_reg[38];
            mult_7_a[7] = qkt_reg[39];
            mult_7_b[0] = xw_reg[0];
            mult_7_b[1] = xw_reg[8];
            mult_7_b[2] = xw_reg[16];
            mult_7_b[3] = xw_reg[24];
            mult_7_b[4] = xw_reg[32];
            mult_7_b[5] = xw_reg[40];
            mult_7_b[6] = xw_reg[48];
            mult_7_b[7] = xw_reg[56];
        end
        6'd32:
        begin
            mult_7_a[0] = qkt_reg[32];
            mult_7_a[1] = qkt_reg[33];
            mult_7_a[2] = qkt_reg[34];
            mult_7_a[3] = qkt_reg[35];
            mult_7_a[4] = qkt_reg[36];
            mult_7_a[5] = qkt_reg[37];
            mult_7_a[6] = qkt_reg[38];
            mult_7_a[7] = qkt_reg[39];
            mult_7_b[0] = xw_reg[1];
            mult_7_b[1] = xw_reg[9];
            mult_7_b[2] = xw_reg[17];
            mult_7_b[3] = xw_reg[25];
            mult_7_b[4] = xw_reg[33];
            mult_7_b[5] = xw_reg[41];
            mult_7_b[6] = xw_reg[49];
            mult_7_b[7] = xw_reg[57];
        end
        6'd33:
        begin
            mult_7_a[0] = qkt_reg[32];
            mult_7_a[1] = qkt_reg[33];
            mult_7_a[2] = qkt_reg[34];
            mult_7_a[3] = qkt_reg[35];
            mult_7_a[4] = qkt_reg[36];
            mult_7_a[5] = qkt_reg[37];
            mult_7_a[6] = qkt_reg[38];
            mult_7_a[7] = qkt_reg[39];
            mult_7_b[0] = xw_reg[2];
            mult_7_b[1] = xw_reg[10];
            mult_7_b[2] = xw_reg[18];
            mult_7_b[3] = xw_reg[26];
            mult_7_b[4] = xw_reg[34];
            mult_7_b[5] = xw_reg[42];
            mult_7_b[6] = xw_reg[50];
            mult_7_b[7] = xw_reg[58];
        end
        6'd34:
        begin
            mult_7_a[0] = qkt_reg[32];
            mult_7_a[1] = qkt_reg[33];
            mult_7_a[2] = qkt_reg[34];
            mult_7_a[3] = qkt_reg[35];
            mult_7_a[4] = qkt_reg[36];
            mult_7_a[5] = qkt_reg[37];
            mult_7_a[6] = qkt_reg[38];
            mult_7_a[7] = qkt_reg[39];
            mult_7_b[0] = xw_reg[3];
            mult_7_b[1] = xw_reg[11];
            mult_7_b[2] = xw_reg[19];
            mult_7_b[3] = xw_reg[27];
            mult_7_b[4] = xw_reg[35];
            mult_7_b[5] = xw_reg[43];
            mult_7_b[6] = xw_reg[51];
            mult_7_b[7] = xw_reg[59];
        end
        6'd35:
        begin
            mult_7_a[0] = qkt_reg[32];
            mult_7_a[1] = qkt_reg[33];
            mult_7_a[2] = qkt_reg[34];
            mult_7_a[3] = qkt_reg[35];
            mult_7_a[4] = qkt_reg[36];
            mult_7_a[5] = qkt_reg[37];
            mult_7_a[6] = qkt_reg[38];
            mult_7_a[7] = qkt_reg[39];
            mult_7_b[0] = xw_reg[4];
            mult_7_b[1] = xw_reg[12];
            mult_7_b[2] = xw_reg[20];
            mult_7_b[3] = xw_reg[28];
            mult_7_b[4] = xw_reg[36];
            mult_7_b[5] = xw_reg[44];
            mult_7_b[6] = xw_reg[52];
            mult_7_b[7] = xw_reg[60];
        end
        6'd36:
        begin
            mult_7_a[0] = qkt_reg[32];
            mult_7_a[1] = qkt_reg[33];
            mult_7_a[2] = qkt_reg[34];
            mult_7_a[3] = qkt_reg[35];
            mult_7_a[4] = qkt_reg[36];
            mult_7_a[5] = qkt_reg[37];
            mult_7_a[6] = qkt_reg[38];
            mult_7_a[7] = qkt_reg[39];
            mult_7_b[0] = xw_reg[5];
            mult_7_b[1] = xw_reg[13];
            mult_7_b[2] = xw_reg[21];
            mult_7_b[3] = xw_reg[29];
            mult_7_b[4] = xw_reg[37];
            mult_7_b[5] = xw_reg[45];
            mult_7_b[6] = xw_reg[53];
            mult_7_b[7] = xw_reg[61];
        end
        6'd37:
        begin
            mult_7_a[0] = qkt_reg[32];
            mult_7_a[1] = qkt_reg[33];
            mult_7_a[2] = qkt_reg[34];
            mult_7_a[3] = qkt_reg[35];
            mult_7_a[4] = qkt_reg[36];
            mult_7_a[5] = qkt_reg[37];
            mult_7_a[6] = qkt_reg[38];
            mult_7_a[7] = qkt_reg[39];
            mult_7_b[0] = xw_reg[6];
            mult_7_b[1] = xw_reg[14];
            mult_7_b[2] = xw_reg[22];
            mult_7_b[3] = xw_reg[30];
            mult_7_b[4] = xw_reg[38];
            mult_7_b[5] = xw_reg[46];
            mult_7_b[6] = xw_reg[54];
            mult_7_b[7] = xw_reg[62];
        end
        6'd38:
        begin
            mult_7_a[0] = qkt_reg[32];
            mult_7_a[1] = qkt_reg[33];
            mult_7_a[2] = qkt_reg[34];
            mult_7_a[3] = qkt_reg[35];
            mult_7_a[4] = qkt_reg[36];
            mult_7_a[5] = qkt_reg[37];
            mult_7_a[6] = qkt_reg[38];
            mult_7_a[7] = qkt_reg[39];
            mult_7_b[0] = xw_reg[7];
            mult_7_b[1] = xw_reg[15];
            mult_7_b[2] = xw_reg[23];
            mult_7_b[3] = xw_reg[31];
            mult_7_b[4] = xw_reg[39];
            mult_7_b[5] = xw_reg[47];
            mult_7_b[6] = xw_reg[55];
            mult_7_b[7] = xw_reg[63];
        end
        6'd39:
        begin
            mult_7_a[0] = qkt_reg[40];
            mult_7_a[1] = qkt_reg[41];
            mult_7_a[2] = qkt_reg[42];
            mult_7_a[3] = qkt_reg[43];
            mult_7_a[4] = qkt_reg[44];
            mult_7_a[5] = qkt_reg[45];
            mult_7_a[6] = qkt_reg[46];
            mult_7_a[7] = qkt_reg[47];
            mult_7_b[0] = xw_reg[0];
            mult_7_b[1] = xw_reg[8];
            mult_7_b[2] = xw_reg[16];
            mult_7_b[3] = xw_reg[24];
            mult_7_b[4] = xw_reg[32];
            mult_7_b[5] = xw_reg[40];
            mult_7_b[6] = xw_reg[48];
            mult_7_b[7] = xw_reg[56];
        end
        6'd40:
        begin
            mult_7_a[0] = qkt_reg[40];
            mult_7_a[1] = qkt_reg[41];
            mult_7_a[2] = qkt_reg[42];
            mult_7_a[3] = qkt_reg[43];
            mult_7_a[4] = qkt_reg[44];
            mult_7_a[5] = qkt_reg[45];
            mult_7_a[6] = qkt_reg[46];
            mult_7_a[7] = qkt_reg[47];
            mult_7_b[0] = xw_reg[1];
            mult_7_b[1] = xw_reg[9];
            mult_7_b[2] = xw_reg[17];
            mult_7_b[3] = xw_reg[25];
            mult_7_b[4] = xw_reg[33];
            mult_7_b[5] = xw_reg[41];
            mult_7_b[6] = xw_reg[49];
            mult_7_b[7] = xw_reg[57];
        end
        6'd41:
        begin
            mult_7_a[0] = qkt_reg[40];
            mult_7_a[1] = qkt_reg[41];
            mult_7_a[2] = qkt_reg[42];
            mult_7_a[3] = qkt_reg[43];
            mult_7_a[4] = qkt_reg[44];
            mult_7_a[5] = qkt_reg[45];
            mult_7_a[6] = qkt_reg[46];
            mult_7_a[7] = qkt_reg[47];
            mult_7_b[0] = xw_reg[2];
            mult_7_b[1] = xw_reg[10];
            mult_7_b[2] = xw_reg[18];
            mult_7_b[3] = xw_reg[26];
            mult_7_b[4] = xw_reg[34];
            mult_7_b[5] = xw_reg[42];
            mult_7_b[6] = xw_reg[50];
            mult_7_b[7] = xw_reg[58];
        end
        6'd42:
        begin
            mult_7_a[0] = qkt_reg[40];
            mult_7_a[1] = qkt_reg[41];
            mult_7_a[2] = qkt_reg[42];
            mult_7_a[3] = qkt_reg[43];
            mult_7_a[4] = qkt_reg[44];
            mult_7_a[5] = qkt_reg[45];
            mult_7_a[6] = qkt_reg[46];
            mult_7_a[7] = qkt_reg[47];
            mult_7_b[0] = xw_reg[3];
            mult_7_b[1] = xw_reg[11];
            mult_7_b[2] = xw_reg[19];
            mult_7_b[3] = xw_reg[27];
            mult_7_b[4] = xw_reg[35];
            mult_7_b[5] = xw_reg[43];
            mult_7_b[6] = xw_reg[51];
            mult_7_b[7] = xw_reg[59];
        end
        6'd43:
        begin
            mult_7_a[0] = qkt_reg[40];
            mult_7_a[1] = qkt_reg[41];
            mult_7_a[2] = qkt_reg[42];
            mult_7_a[3] = qkt_reg[43];
            mult_7_a[4] = qkt_reg[44];
            mult_7_a[5] = qkt_reg[45];
            mult_7_a[6] = qkt_reg[46];
            mult_7_a[7] = qkt_reg[47];
            mult_7_b[0] = xw_reg[4];
            mult_7_b[1] = xw_reg[12];
            mult_7_b[2] = xw_reg[20];
            mult_7_b[3] = xw_reg[28];
            mult_7_b[4] = xw_reg[36];
            mult_7_b[5] = xw_reg[44];
            mult_7_b[6] = xw_reg[52];
            mult_7_b[7] = xw_reg[60];
        end
        6'd44:
        begin
            mult_7_a[0] = qkt_reg[40];
            mult_7_a[1] = qkt_reg[41];
            mult_7_a[2] = qkt_reg[42];
            mult_7_a[3] = qkt_reg[43];
            mult_7_a[4] = qkt_reg[44];
            mult_7_a[5] = qkt_reg[45];
            mult_7_a[6] = qkt_reg[46];
            mult_7_a[7] = qkt_reg[47];
            mult_7_b[0] = xw_reg[5];
            mult_7_b[1] = xw_reg[13];
            mult_7_b[2] = xw_reg[21];
            mult_7_b[3] = xw_reg[29];
            mult_7_b[4] = xw_reg[37];
            mult_7_b[5] = xw_reg[45];
            mult_7_b[6] = xw_reg[53];
            mult_7_b[7] = xw_reg[61];
        end
        6'd45:
        begin
            mult_7_a[0] = qkt_reg[40];
            mult_7_a[1] = qkt_reg[41];
            mult_7_a[2] = qkt_reg[42];
            mult_7_a[3] = qkt_reg[43];
            mult_7_a[4] = qkt_reg[44];
            mult_7_a[5] = qkt_reg[45];
            mult_7_a[6] = qkt_reg[46];
            mult_7_a[7] = qkt_reg[47];
            mult_7_b[0] = xw_reg[6];
            mult_7_b[1] = xw_reg[14];
            mult_7_b[2] = xw_reg[22];
            mult_7_b[3] = xw_reg[30];
            mult_7_b[4] = xw_reg[38];
            mult_7_b[5] = xw_reg[46];
            mult_7_b[6] = xw_reg[54];
            mult_7_b[7] = xw_reg[62];
        end
        6'd46:
        begin
            mult_7_a[0] = qkt_reg[40];
            mult_7_a[1] = qkt_reg[41];
            mult_7_a[2] = qkt_reg[42];
            mult_7_a[3] = qkt_reg[43];
            mult_7_a[4] = qkt_reg[44];
            mult_7_a[5] = qkt_reg[45];
            mult_7_a[6] = qkt_reg[46];
            mult_7_a[7] = qkt_reg[47];
            mult_7_b[0] = xw_reg[7];
            mult_7_b[1] = xw_reg[15];
            mult_7_b[2] = xw_reg[23];
            mult_7_b[3] = xw_reg[31];
            mult_7_b[4] = xw_reg[39];
            mult_7_b[5] = xw_reg[47];
            mult_7_b[6] = xw_reg[55];
            mult_7_b[7] = xw_reg[63];
        end
        6'd47:
        begin
            mult_7_a[0] = qkt_reg[48];
            mult_7_a[1] = qkt_reg[49];
            mult_7_a[2] = qkt_reg[50];
            mult_7_a[3] = qkt_reg[51];
            mult_7_a[4] = qkt_reg[52];
            mult_7_a[5] = qkt_reg[53];
            mult_7_a[6] = qkt_reg[54];
            mult_7_a[7] = qkt_reg[55];
            mult_7_b[0] = xw_reg[0];
            mult_7_b[1] = xw_reg[8];
            mult_7_b[2] = xw_reg[16];
            mult_7_b[3] = xw_reg[24];
            mult_7_b[4] = xw_reg[32];
            mult_7_b[5] = xw_reg[40];
            mult_7_b[6] = xw_reg[48];
            mult_7_b[7] = xw_reg[56];
        end
        6'd48:
        begin
            mult_7_a[0] = qkt_reg[48];
            mult_7_a[1] = qkt_reg[49];
            mult_7_a[2] = qkt_reg[50];
            mult_7_a[3] = qkt_reg[51];
            mult_7_a[4] = qkt_reg[52];
            mult_7_a[5] = qkt_reg[53];
            mult_7_a[6] = qkt_reg[54];
            mult_7_a[7] = qkt_reg[55];
            mult_7_b[0] = xw_reg[1];
            mult_7_b[1] = xw_reg[9];
            mult_7_b[2] = xw_reg[17];
            mult_7_b[3] = xw_reg[25];
            mult_7_b[4] = xw_reg[33];
            mult_7_b[5] = xw_reg[41];
            mult_7_b[6] = xw_reg[49];
            mult_7_b[7] = xw_reg[57];
        end
        6'd49:
        begin
            mult_7_a[0] = qkt_reg[48];
            mult_7_a[1] = qkt_reg[49];
            mult_7_a[2] = qkt_reg[50];
            mult_7_a[3] = qkt_reg[51];
            mult_7_a[4] = qkt_reg[52];
            mult_7_a[5] = qkt_reg[53];
            mult_7_a[6] = qkt_reg[54];
            mult_7_a[7] = qkt_reg[55];
            mult_7_b[0] = xw_reg[2];
            mult_7_b[1] = xw_reg[10];
            mult_7_b[2] = xw_reg[18];
            mult_7_b[3] = xw_reg[26];
            mult_7_b[4] = xw_reg[34];
            mult_7_b[5] = xw_reg[42];
            mult_7_b[6] = xw_reg[50];
            mult_7_b[7] = xw_reg[58];
        end
        6'd50:
        begin
            mult_7_a[0] = qkt_reg[48];
            mult_7_a[1] = qkt_reg[49];
            mult_7_a[2] = qkt_reg[50];
            mult_7_a[3] = qkt_reg[51];
            mult_7_a[4] = qkt_reg[52];
            mult_7_a[5] = qkt_reg[53];
            mult_7_a[6] = qkt_reg[54];
            mult_7_a[7] = qkt_reg[55];
            mult_7_b[0] = xw_reg[3];
            mult_7_b[1] = xw_reg[11];
            mult_7_b[2] = xw_reg[19];
            mult_7_b[3] = xw_reg[27];
            mult_7_b[4] = xw_reg[35];
            mult_7_b[5] = xw_reg[43];
            mult_7_b[6] = xw_reg[51];
            mult_7_b[7] = xw_reg[59];
        end
        6'd51:
        begin
            mult_7_a[0] = qkt_reg[48];
            mult_7_a[1] = qkt_reg[49];
            mult_7_a[2] = qkt_reg[50];
            mult_7_a[3] = qkt_reg[51];
            mult_7_a[4] = qkt_reg[52];
            mult_7_a[5] = qkt_reg[53];
            mult_7_a[6] = qkt_reg[54];
            mult_7_a[7] = qkt_reg[55];
            mult_7_b[0] = xw_reg[4];
            mult_7_b[1] = xw_reg[12];
            mult_7_b[2] = xw_reg[20];
            mult_7_b[3] = xw_reg[28];
            mult_7_b[4] = xw_reg[36];
            mult_7_b[5] = xw_reg[44];
            mult_7_b[6] = xw_reg[52];
            mult_7_b[7] = xw_reg[60];
        end
        6'd52:
        begin
            mult_7_a[0] = qkt_reg[48];
            mult_7_a[1] = qkt_reg[49];
            mult_7_a[2] = qkt_reg[50];
            mult_7_a[3] = qkt_reg[51];
            mult_7_a[4] = qkt_reg[52];
            mult_7_a[5] = qkt_reg[53];
            mult_7_a[6] = qkt_reg[54];
            mult_7_a[7] = qkt_reg[55];
            mult_7_b[0] = xw_reg[5];
            mult_7_b[1] = xw_reg[13];
            mult_7_b[2] = xw_reg[21];
            mult_7_b[3] = xw_reg[29];
            mult_7_b[4] = xw_reg[37];
            mult_7_b[5] = xw_reg[45];
            mult_7_b[6] = xw_reg[53];
            mult_7_b[7] = xw_reg[61];
        end
        6'd53:
        begin
            mult_7_a[0] = qkt_reg[48];
            mult_7_a[1] = qkt_reg[49];
            mult_7_a[2] = qkt_reg[50];
            mult_7_a[3] = qkt_reg[51];
            mult_7_a[4] = qkt_reg[52];
            mult_7_a[5] = qkt_reg[53];
            mult_7_a[6] = qkt_reg[54];
            mult_7_a[7] = qkt_reg[55];
            mult_7_b[0] = xw_reg[6];
            mult_7_b[1] = xw_reg[14];
            mult_7_b[2] = xw_reg[22];
            mult_7_b[3] = xw_reg[30];
            mult_7_b[4] = xw_reg[38];
            mult_7_b[5] = xw_reg[46];
            mult_7_b[6] = xw_reg[54];
            mult_7_b[7] = xw_reg[62];
        end
        6'd54:
        begin
            mult_7_a[0] = qkt_reg[48];
            mult_7_a[1] = qkt_reg[49];
            mult_7_a[2] = qkt_reg[50];
            mult_7_a[3] = qkt_reg[51];
            mult_7_a[4] = qkt_reg[52];
            mult_7_a[5] = qkt_reg[53];
            mult_7_a[6] = qkt_reg[54];
            mult_7_a[7] = qkt_reg[55];
            mult_7_b[0] = xw_reg[7];
            mult_7_b[1] = xw_reg[15];
            mult_7_b[2] = xw_reg[23];
            mult_7_b[3] = xw_reg[31];
            mult_7_b[4] = xw_reg[39];
            mult_7_b[5] = xw_reg[47];
            mult_7_b[6] = xw_reg[55];
            mult_7_b[7] = xw_reg[63];
        end
        6'd55:
        begin
            mult_7_a[0] = qkt_reg[56];
            mult_7_a[1] = qkt_reg[57];
            mult_7_a[2] = qkt_reg[58];
            mult_7_a[3] = qkt_reg[59];
            mult_7_a[4] = qkt_reg[60];
            mult_7_a[5] = qkt_reg[61];
            mult_7_a[6] = qkt_reg[62];
            mult_7_a[7] = qkt_reg[63];
            mult_7_b[0] = xw_reg[0];
            mult_7_b[1] = xw_reg[8];
            mult_7_b[2] = xw_reg[16];
            mult_7_b[3] = xw_reg[24];
            mult_7_b[4] = xw_reg[32];
            mult_7_b[5] = xw_reg[40];
            mult_7_b[6] = xw_reg[48];
            mult_7_b[7] = xw_reg[56];
        end
        6'd56:
        begin
            mult_7_a[0] = qkt_reg[56];
            mult_7_a[1] = qkt_reg[57];
            mult_7_a[2] = qkt_reg[58];
            mult_7_a[3] = qkt_reg[59];
            mult_7_a[4] = qkt_reg[60];
            mult_7_a[5] = qkt_reg[61];
            mult_7_a[6] = qkt_reg[62];
            mult_7_a[7] = qkt_reg[63];
            mult_7_b[0] = xw_reg[1];
            mult_7_b[1] = xw_reg[9];
            mult_7_b[2] = xw_reg[17];
            mult_7_b[3] = xw_reg[25];
            mult_7_b[4] = xw_reg[33];
            mult_7_b[5] = xw_reg[41];
            mult_7_b[6] = xw_reg[49];
            mult_7_b[7] = xw_reg[57];
        end
        6'd57:
        begin
            mult_7_a[0] = qkt_reg[56];
            mult_7_a[1] = qkt_reg[57];
            mult_7_a[2] = qkt_reg[58];
            mult_7_a[3] = qkt_reg[59];
            mult_7_a[4] = qkt_reg[60];
            mult_7_a[5] = qkt_reg[61];
            mult_7_a[6] = qkt_reg[62];
            mult_7_a[7] = qkt_reg[63];
            mult_7_b[0] = xw_reg[2];
            mult_7_b[1] = xw_reg[10];
            mult_7_b[2] = xw_reg[18];
            mult_7_b[3] = xw_reg[26];
            mult_7_b[4] = xw_reg[34];
            mult_7_b[5] = xw_reg[42];
            mult_7_b[6] = xw_reg[50];
            mult_7_b[7] = xw_reg[58];
        end
        6'd58:
        begin
            mult_7_a[0] = qkt_reg[56];
            mult_7_a[1] = qkt_reg[57];
            mult_7_a[2] = qkt_reg[58];
            mult_7_a[3] = qkt_reg[59];
            mult_7_a[4] = qkt_reg[60];
            mult_7_a[5] = qkt_reg[61];
            mult_7_a[6] = qkt_reg[62];
            mult_7_a[7] = qkt_reg[63];
            mult_7_b[0] = xw_reg[3];
            mult_7_b[1] = xw_reg[11];
            mult_7_b[2] = xw_reg[19];
            mult_7_b[3] = xw_reg[27];
            mult_7_b[4] = xw_reg[35];
            mult_7_b[5] = xw_reg[43];
            mult_7_b[6] = xw_reg[51];
            mult_7_b[7] = xw_reg[59];
        end
        6'd59:
        begin
            mult_7_a[0] = qkt_reg[56];
            mult_7_a[1] = qkt_reg[57];
            mult_7_a[2] = qkt_reg[58];
            mult_7_a[3] = qkt_reg[59];
            mult_7_a[4] = qkt_reg[60];
            mult_7_a[5] = qkt_reg[61];
            mult_7_a[6] = qkt_reg[62];
            mult_7_a[7] = qkt_reg[63];
            mult_7_b[0] = xw_reg[4];
            mult_7_b[1] = xw_reg[12];
            mult_7_b[2] = xw_reg[20];
            mult_7_b[3] = xw_reg[28];
            mult_7_b[4] = xw_reg[36];
            mult_7_b[5] = xw_reg[44];
            mult_7_b[6] = xw_reg[52];
            mult_7_b[7] = xw_reg[60];
        end
        6'd60:
        begin
            mult_7_a[0] = qkt_reg[56];
            mult_7_a[1] = qkt_reg[57];
            mult_7_a[2] = qkt_reg[58];
            mult_7_a[3] = qkt_reg[59];
            mult_7_a[4] = qkt_reg[60];
            mult_7_a[5] = qkt_reg[61];
            mult_7_a[6] = qkt_reg[62];
            mult_7_a[7] = qkt_reg[63];
            mult_7_b[0] = xw_reg[5];
            mult_7_b[1] = xw_reg[13];
            mult_7_b[2] = xw_reg[21];
            mult_7_b[3] = xw_reg[29];
            mult_7_b[4] = xw_reg[37];
            mult_7_b[5] = xw_reg[45];
            mult_7_b[6] = xw_reg[53];
            mult_7_b[7] = xw_reg[61];
        end
        6'd61:
        begin
            mult_7_a[0] = qkt_reg[56];
            mult_7_a[1] = qkt_reg[57];
            mult_7_a[2] = qkt_reg[58];
            mult_7_a[3] = qkt_reg[59];
            mult_7_a[4] = qkt_reg[60];
            mult_7_a[5] = qkt_reg[61];
            mult_7_a[6] = qkt_reg[62];
            mult_7_a[7] = qkt_reg[63];
            mult_7_b[0] = xw_reg[6];
            mult_7_b[1] = xw_reg[14];
            mult_7_b[2] = xw_reg[22];
            mult_7_b[3] = xw_reg[30];
            mult_7_b[4] = xw_reg[38];
            mult_7_b[5] = xw_reg[46];
            mult_7_b[6] = xw_reg[54];
            mult_7_b[7] = xw_reg[62];
        end
        6'd62:
        begin
            mult_7_a[0] = qkt_reg[56];
            mult_7_a[1] = qkt_reg[57];
            mult_7_a[2] = qkt_reg[58];
            mult_7_a[3] = qkt_reg[59];
            mult_7_a[4] = qkt_reg[60];
            mult_7_a[5] = qkt_reg[61];
            mult_7_a[6] = qkt_reg[62];
            mult_7_a[7] = qkt_reg[63];
            mult_7_b[0] = xw_reg[7];
            mult_7_b[1] = xw_reg[15];
            mult_7_b[2] = xw_reg[23];
            mult_7_b[3] = xw_reg[31];
            mult_7_b[4] = xw_reg[39];
            mult_7_b[5] = xw_reg[47];
            mult_7_b[6] = xw_reg[55];
            mult_7_b[7] = xw_reg[63];
        end
        default:
        begin
            mult_7_a[0] = 41'd0;
            mult_7_a[1] = 41'd0;
            mult_7_a[2] = 41'd0;
            mult_7_a[3] = 41'd0;
            mult_7_a[4] = 41'd0;
            mult_7_a[5] = 41'd0;
            mult_7_a[6] = 41'd0;
            mult_7_a[7] = 41'd0;
            mult_7_b[0] = 19'd0;
            mult_7_b[1] = 19'd0;
            mult_7_b[2] = 19'd0;
            mult_7_b[3] = 19'd0;
            mult_7_b[4] = 19'd0;
            mult_7_b[5] = 19'd0;
            mult_7_b[6] = 19'd0;
            mult_7_b[7] = 19'd0;
        end
        endcase
    end
    default:
    begin
        mult_7_a[0] = 41'd0;
        mult_7_a[1] = 41'd0;
        mult_7_a[2] = 41'd0;
        mult_7_a[3] = 41'd0;
        mult_7_a[4] = 41'd0;
        mult_7_a[5] = 41'd0;
        mult_7_a[6] = 41'd0;
        mult_7_a[7] = 41'd0;
        mult_7_b[0] = 19'd0;
        mult_7_b[1] = 19'd0;
        mult_7_b[2] = 19'd0;
        mult_7_b[3] = 19'd0;
        mult_7_b[4] = 19'd0;
        mult_7_b[5] = 19'd0;
        mult_7_b[6] = 19'd0;
        mult_7_b[7] = 19'd0;
    end
    endcase
end

//==================================================================
// scale_relu
//==================================================================
scale_relu scale_relu(.a(scale_relu_a), .z(scale_relu_z));

//==================================================================
// scale_relu_a
//==================================================================
always @ (*)
begin
    if((state == XWV) && (input_counter > 6'd1))
    begin
        scale_relu_a = qkt_reg[input_counter - 2];
    end
    else if((state == OUT) && (output_counter == 6'd0))
    begin
        scale_relu_a = qkt_reg[62];
    end
    else if((state == OUT) && (output_counter == 6'd1))
    begin
        scale_relu_a = qkt_reg[63];
    end
    else
    begin
        scale_relu_a = 41'd0;
    end
end

//==================================================================
// next_out_data_reg
//==================================================================
always @ (*)
begin
    if(((state == XWV) && (input_counter == 6'd63)) || ((state == OUT) && (output_counter < 63)))
    begin
        next_out_data_reg = {mult_7_z[62], mult_7_z};
    end
    else if(state == WAIT) next_out_data_reg = out_data_reg;
    else next_out_data_reg = 64'b0;
end

//==================================================================
// out_valid
//==================================================================
always @ (posedge clk_input_counter or negedge rst_n)
begin
    if(!rst_n) out_valid <= 1'b0;
    else if(state == WAIT) out_valid <= 1'b1;
    else if(output_counter == (t_reg_shift - 1)) out_valid <= 1'b0;
    else out_valid <= out_valid;
end

//==================================================================
// out_data
//==================================================================
always @ (*)
begin
    if(out_valid == 1'b1) out_data = out_data_reg;
    else out_data = 64'd0;
end

endmodule

module multiplier_19(
    m0_a, m1_a, m2_a, m3_a, m4_a, m5_a, m6_a, m7_a, 
    m0_b, m1_b, m2_b, m3_b, m4_b, m5_b, m6_b, m7_b, 
    z
);
input signed [18:0] m0_a, m1_a, m2_a, m3_a, m4_a, m5_a, m6_a, m7_a;
input signed [18:0] m0_b, m1_b, m2_b, m3_b, m4_b, m5_b, m6_b, m7_b;
output reg signed [40:0] z;
reg signed [37:0] net_0 [7:0];
reg signed [38:0] net_1 [3:0];
reg signed [39:0] net_2 [1:0];

always @ (*)
begin
    net_0[0] = m0_a * m0_b;
    net_0[1] = m1_a * m1_b;
    net_0[2] = m2_a * m2_b;
    net_0[3] = m3_a * m3_b;
    net_0[4] = m4_a * m4_b;
    net_0[5] = m5_a * m5_b;
    net_0[6] = m6_a * m6_b;
    net_0[7] = m7_a * m7_b;
end

always @ (*)
begin
    net_1[0] = net_0[0] + net_0[1];
    net_1[1] = net_0[2] + net_0[3];
    net_1[2] = net_0[4] + net_0[5];
    net_1[3] = net_0[6] + net_0[7];
end

always @(*)
begin
    net_2[0] = net_1[0] + net_1[1];
    net_2[1] = net_1[2] + net_1[3];
end

always @ (*)
begin
    z = net_2[0] + net_2[1];
end
endmodule

module multiplier_41(
    m0_a, m1_a, m2_a, m3_a, m4_a, m5_a, m6_a, m7_a, 
    m0_b, m1_b, m2_b, m3_b, m4_b, m5_b, m6_b, m7_b, 
    z
);
input signed [40:0] m0_a, m1_a, m2_a, m3_a, m4_a, m5_a, m6_a, m7_a;
input signed [18:0] m0_b, m1_b, m2_b, m3_b, m4_b, m5_b, m6_b, m7_b;
output reg signed [62:0] z;
reg signed [59:0] net_0 [7:0];
reg signed [60:0] net_1 [3:0];
reg signed [61:0] net_2 [1:0];

always @ (*)
begin
    net_0[0] = m0_a * m0_b;
    net_0[1] = m1_a * m1_b;
    net_0[2] = m2_a * m2_b;
    net_0[3] = m3_a * m3_b;
    net_0[4] = m4_a * m4_b;
    net_0[5] = m5_a * m5_b;
    net_0[6] = m6_a * m6_b;
    net_0[7] = m7_a * m7_b;
end

always @ (*)
begin
    net_1[0] = net_0[0] + net_0[1];
    net_1[1] = net_0[2] + net_0[3];
    net_1[2] = net_0[4] + net_0[5];
    net_1[3] = net_0[6] + net_0[7];
end

always @(*)
begin
    net_2[0] = net_1[0] + net_1[1];
    net_2[1] = net_1[2] + net_1[3];
end

always @ (*)
begin
    z = net_2[0] + net_2[1];
end
endmodule

module scale_relu(a, z);
input signed [40:0] a;
output reg signed [40:0] z;
reg signed [40:0] net;

always @ (*)
begin
    net = a / 3;
end

always @ (*)
begin
    if(a[40] == 1'b1) z = 41'd0;
    else z = net;
end
endmodule