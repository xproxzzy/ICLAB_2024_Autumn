/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: SA
// FILE NAME: SA_wocg.v
// VERSRION: 1.0
// DATE: Nov 06, 2024
// AUTHOR: Yen-Ning Tung, NYCU AIG
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2024 Spring IC Lab / Exersise Lab08 / SA_wocg
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

module SA(
    // Input signals
    clk,
    rst_n,
    in_valid,
    T,
    in_data,
    w_Q,
    w_K,
    w_V,
    // Output signals
    out_valid,
    out_data
);

input clk;
input rst_n;
input in_valid;
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

//==============================================//
//                  design                      //
//==============================================//
//==================================================================
// sequential
//==================================================================
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) state <= IDLE;
    else state <= next_state;
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) input_counter <= 6'd0;
    else input_counter <= next_input_counter;
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) output_counter <= 6'd0;
    else output_counter <= next_output_counter;
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) t_reg <= 4'd0;
    else t_reg <= next_t_reg;
end

always @ (posedge clk or negedge rst_n)
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


always @ (posedge clk or negedge rst_n)
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

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        for(i = 0; i < 64; i = i+1)
        begin
            xw_reg[i] <= 19'd0;
        end
    end
    else
    begin
        for(i = 0; i < 64; i = i+1)
        begin
            xw_reg[i] <= next_xw_reg[i];
        end
    end
end

always @ (posedge clk or negedge rst_n)
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
end

always @ (posedge clk or negedge rst_n)
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
always @ (posedge clk or negedge rst_n)
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