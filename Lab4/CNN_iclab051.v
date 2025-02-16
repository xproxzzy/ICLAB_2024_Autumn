//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network 
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel_ch1,
    Kernel_ch2,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

parameter IDLE = 3'd0;
parameter IN = 3'd1;
parameter CAL = 3'd2;
parameter MAXPOOL = 3'd3;
parameter FC = 3'd4;
parameter SOFTMAX = 3'd5;
parameter OUT = 3'd6;

input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel_ch1, Kernel_ch2, Weight;
input Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;


//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
reg [2:0] state;
reg [2:0] next_state;
reg [6:0] input_counter;
reg [6:0] next_input_counter;
reg [6:0] cal_counter;
reg [6:0] next_cal_counter;
reg [1:0] output_counter;
reg [1:0] next_output_counter;
integer i;

reg opt_ff;
reg next_opt_ff;

reg [31:0] img_ff [3:0];
reg [31:0] next_img_ff [3:0];

reg [31:0] kernel_ch1_ff [11:0];
reg [31:0] next_kernel_ch1_ff [11:0];
reg [31:0] kernel_ch2_ff [11:0];
reg [31:0] next_kernel_ch2_ff [11:0];

reg [31:0] weight_ff [23:0];
reg [31:0] next_weight_ff [23:0];

reg [31:0] conv_out_ch1_ff [35:0];
reg [31:0] next_conv_out_ch1_ff [35:0];
reg [31:0] conv_out_ch2_ff [35:0];
reg [31:0] next_conv_out_ch2_ff [35:0];

reg [31:0] before_act_div_ch1_ff [1:0];
reg [31:0] next_before_act_div_ch1_ff [1:0];

reg [31:0] before_act_div_ch2_ff [1:0];
reg [31:0] next_before_act_div_ch2_ff [1:0];

reg [31:0] fc_out_ff [2:0];
reg [31:0] next_fc_out_ff [2:0];

reg [31:0] softmax_out_ff [2:0];
reg [31:0] next_softmax_out_ff [2:0];

reg [7:0] conv_out_pos [3:0];

reg [31:0] M0_a, M0_b, M0_z;
reg [31:0] M1_a, M1_b, M1_z;
reg [31:0] M2_a, M2_b, M2_z;
reg [31:0] M3_a, M3_b, M3_z;
reg [31:0] M4_a, M4_b, M4_z;
reg [31:0] M5_a, M5_b, M5_z;
reg [31:0] M6_a, M6_b, M6_z;
reg [31:0] M7_a, M7_b, M7_z;

reg [31:0] A1_0_a, A1_0_b, A1_0_z;
reg [31:0] A1_1_a, A1_1_b, A1_1_z;
reg [31:0] A1_2_a, A1_2_b, A1_2_z;
reg [31:0] A1_3_a, A1_3_b, A1_3_z;

reg [31:0] S1_0_a, S1_0_b, S1_0_c, S1_0_z;
reg [31:0] S1_1_a, S1_1_b, S1_1_c, S1_1_z;

reg [31:0] A2_0_a, A2_0_b, A2_0_z;
reg [31:0] A2_1_a, A2_1_b, A2_1_z;
reg [31:0] A2_2_a, A2_2_b, A2_2_z;
reg [31:0] A2_3_a, A2_3_b, A2_3_z;

reg [31:0] S2_0_a, S2_0_b, S2_0_c, S2_0_z;
reg [31:0] S2_1_a, S2_1_b, S2_1_c, S2_1_z;

reg [31:0] C1_in [8:0];
reg [31:0] C1_net [6:0];
reg [31:0] C1_out;

reg [31:0] C2_in [8:0];
reg [31:0] C2_net [6:0];
reg [31:0] C2_out;

reg [31:0] E1_0_a, E1_0_z;
reg [31:0] E1_1_a, E1_1_z;

reg [31:0] E2_0_a, E2_0_z;
reg [31:0] E2_1_a, E2_1_z;

reg [31:0] Sub1_act_a, Sub1_act_b, Sub1_act_z;
reg [31:0] A1_act_a, A1_act_b, A1_act_z;

reg [31:0] Sub2_act_a, Sub2_act_b, Sub2_act_z;
reg [31:0] A2_act_a, A2_act_b, A2_act_z;

reg [31:0] D1_a, D1_b, D1_z;

reg [31:0] D2_a, D2_b, D2_z;

reg [31:0] M1_0_fc_a, M1_0_fc_b, M1_0_fc_z;
reg [31:0] M1_1_fc_a, M1_1_fc_b, M1_1_fc_z;
reg [31:0] M1_2_fc_a, M1_2_fc_b, M1_2_fc_z;

reg [31:0] M2_0_fc_a, M2_0_fc_b, M2_0_fc_z;
reg [31:0] M2_1_fc_a, M2_1_fc_b, M2_1_fc_z;
reg [31:0] M2_2_fc_a, M2_2_fc_b, M2_2_fc_z;

reg [31:0] S0_fc_a, S0_fc_b, S0_fc_c, S0_fc_z;
reg [31:0] S1_fc_a, S1_fc_b, S1_fc_c, S1_fc_z;
reg [31:0] S2_fc_a, S2_fc_b, S2_fc_c, S2_fc_z;

reg [31:0] E0_softmax_a, E0_softmax_z;
reg [31:0] E1_softmax_a, E1_softmax_z;
reg [31:0] E2_softmax_a, E2_softmax_z;

reg [31:0] S_softmax_a, S_softmax_b, S_softmax_c, S_softmax_z;

reg [31:0] D0_softmax_a, D0_softmax_b, D0_softmax_z;
//---------------------------------------------------------------------
//   IPs
//---------------------------------------------------------------------
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M0(.a(M0_a), .b(M0_b), .rnd(3'd0), .z(M0_z));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1(.a(M1_a), .b(M1_b), .rnd(3'd0), .z(M1_z));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M2(.a(M2_a), .b(M2_b), .rnd(3'd0), .z(M2_z));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M3(.a(M3_a), .b(M3_b), .rnd(3'd0), .z(M3_z));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M4(.a(M4_a), .b(M4_b), .rnd(3'd0), .z(M4_z));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M5(.a(M5_a), .b(M5_b), .rnd(3'd0), .z(M5_z));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M6(.a(M6_a), .b(M6_b), .rnd(3'd0), .z(M6_z));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M7(.a(M7_a), .b(M7_b), .rnd(3'd0), .z(M7_z));

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A1_0(.a(A1_0_a), .b(A1_0_b), .rnd(3'd0), .z(A1_0_z));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A1_1(.a(A1_1_a), .b(A1_1_b), .rnd(3'd0), .z(A1_1_z));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A1_2(.a(A1_2_a), .b(A1_2_b), .rnd(3'd0), .z(A1_2_z));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A1_3(.a(A1_3_a), .b(A1_3_b), .rnd(3'd0), .z(A1_3_z));

DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) S1_0(.a(S1_0_a), .b(S1_0_b), .c(S1_0_c), .rnd(3'd0), .z(S1_0_z));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) S1_1(.a(S1_1_a), .b(S1_1_b), .c(S1_1_c), .rnd(3'd0), .z(S1_1_z));

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A2_0(.a(A2_0_a), .b(A2_0_b), .rnd(3'd0), .z(A2_0_z));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A2_1(.a(A2_1_a), .b(A2_1_b), .rnd(3'd0), .z(A2_1_z));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A2_2(.a(A2_2_a), .b(A2_2_b), .rnd(3'd0), .z(A2_2_z));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A2_3(.a(A2_3_a), .b(A2_3_b), .rnd(3'd0), .z(A2_3_z));

DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) S2_0(.a(S2_0_a), .b(S2_0_b), .c(S2_0_c), .rnd(3'd0), .z(S2_0_z));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) S2_1(.a(S2_1_a), .b(S2_1_b), .c(S2_1_c), .rnd(3'd0), .z(S2_1_z));

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C1_0(.a(C1_in[0]), .b(C1_in[1]), .zctr(1'b0), .z1(C1_net[0]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C1_1(.a(C1_in[2]), .b(C1_in[3]), .zctr(1'b0), .z1(C1_net[1]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C1_2(.a(C1_in[4]), .b(C1_in[5]), .zctr(1'b0), .z1(C1_net[2]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C1_3(.a(C1_in[6]), .b(C1_in[7]), .zctr(1'b0), .z1(C1_net[3]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C1_4(.a(C1_net[0]), .b(C1_net[1]), .zctr(1'b0), .z1(C1_net[4]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C1_5(.a(C1_net[2]), .b(C1_net[3]), .zctr(1'b0), .z1(C1_net[5]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C1_6(.a(C1_net[4]), .b(C1_net[5]), .zctr(1'b0), .z1(C1_net[6]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C1_7(.a(C1_net[6]), .b(C1_in[8]), .zctr(1'b0), .z1(C1_out));

DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C2_0(.a(C2_in[0]), .b(C2_in[1]), .zctr(1'b0), .z1(C2_net[0]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C2_1(.a(C2_in[2]), .b(C2_in[3]), .zctr(1'b0), .z1(C2_net[1]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C2_2(.a(C2_in[4]), .b(C2_in[5]), .zctr(1'b0), .z1(C2_net[2]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C2_3(.a(C2_in[6]), .b(C2_in[7]), .zctr(1'b0), .z1(C2_net[3]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C2_4(.a(C2_net[0]), .b(C2_net[1]), .zctr(1'b0), .z1(C2_net[4]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C2_5(.a(C2_net[2]), .b(C2_net[3]), .zctr(1'b0), .z1(C2_net[5]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C2_6(.a(C2_net[4]), .b(C2_net[5]), .zctr(1'b0), .z1(C2_net[6]));
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) C2_7(.a(C2_net[6]), .b(C2_in[8]), .zctr(1'b0), .z1(C2_out));

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) E1_0(.a(E1_0_a), .z(E1_0_z));
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) E1_1(.a(E1_1_a), .z(E1_1_z));

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) E2_0(.a(E2_0_a), .z(E2_0_z));
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) E2_1(.a(E2_1_a), .z(E2_1_z));

DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) SUB1_Act(.a(Sub1_act_a), .b(Sub1_act_b), .rnd(3'd0), .z(Sub1_act_z));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A1_Act(.a(A1_act_a), .b(A1_act_b), .rnd(3'd0), .z(A1_act_z));

DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance) SUB2_Act(.a(Sub2_act_a), .b(Sub2_act_b), .rnd(3'd0), .z(Sub2_act_z));
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A2_Act(.a(A2_act_a), .b(A2_act_b), .rnd(3'd0), .z(A2_act_z));

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) D1(.a(D1_a), .b(D1_b), .rnd(3'd0), .z(D1_z));

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) D2(.a(D2_a), .b(D2_b), .rnd(3'd0), .z(D2_z));

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1_Fc_0(.a(M1_0_fc_a), .b(M1_0_fc_b), .rnd(3'd0), .z(M1_0_fc_z));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1_Fc_1(.a(M1_1_fc_a), .b(M1_1_fc_b), .rnd(3'd0), .z(M1_1_fc_z));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1_Fc_2(.a(M1_2_fc_a), .b(M1_2_fc_b), .rnd(3'd0), .z(M1_2_fc_z));

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M2_Fc_0(.a(M2_0_fc_a), .b(M2_0_fc_b), .rnd(3'd0), .z(M2_0_fc_z));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M2_Fc_1(.a(M2_1_fc_a), .b(M2_1_fc_b), .rnd(3'd0), .z(M2_1_fc_z));
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M2_Fc_2(.a(M2_2_fc_a), .b(M2_2_fc_b), .rnd(3'd0), .z(M2_2_fc_z));

DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) S0_Fc(.a(S0_fc_a), .b(S0_fc_b), .c(S0_fc_c), .rnd(3'd0), .z(S0_fc_z));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) S1_Fc(.a(S1_fc_a), .b(S1_fc_b), .c(S1_fc_c), .rnd(3'd0), .z(S1_fc_z));
DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) S2_Fc(.a(S2_fc_a), .b(S2_fc_b), .c(S2_fc_c), .rnd(3'd0), .z(S2_fc_z));

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) E0_Softmax(.a(E0_softmax_a), .z(E0_softmax_z));
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) E1_Softmax(.a(E1_softmax_a), .z(E1_softmax_z));
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) E2_Softmax(.a(E2_softmax_a), .z(E2_softmax_z));

DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type) S_Softmax(.a(S_softmax_a), .b(S_softmax_b), .c(S_softmax_c), .rnd(3'd0), .z(S_softmax_z));

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) D0_Softmax(.a(D0_softmax_a), .b(D0_softmax_b), .rnd(3'd0), .z(D0_softmax_z));
//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------
//---------------------------------------------------------------------
//   CURRENT STATE
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state <= IDLE;
        input_counter <= 7'd0;
        cal_counter <= 7'd0;
        output_counter <= 2'd0;
        opt_ff <= 1'b0;
        for(i = 0; i < 4; ++i)
        begin
            img_ff[i] <= 32'd0;
        end
        for(i = 0; i < 12; ++i)
        begin
            kernel_ch1_ff[i] <= 32'd0;
        end
        for(i = 0; i < 12; ++i)
        begin
            kernel_ch2_ff[i] <= 32'd0;
        end
        for(i = 0; i < 24; ++i)
        begin
            weight_ff[i] <= 32'd0;
        end
        for(i = 0; i < 36; ++i)
        begin
            conv_out_ch1_ff[i] <= 32'd0;
        end
        for(i = 0; i < 36; ++i)
        begin
            conv_out_ch2_ff[i] <= 32'd0;
        end
        before_act_div_ch1_ff[0] <= 32'd0;
        before_act_div_ch1_ff[1] <= 32'd0;
        before_act_div_ch2_ff[0] <= 32'd0;
        before_act_div_ch2_ff[1] <= 32'd0;
        fc_out_ff[0] <= 32'd0;
        fc_out_ff[1] <= 32'd0;
        fc_out_ff[2] <= 32'd0;
        softmax_out_ff[0] <= 32'd0;
        softmax_out_ff[1] <= 32'd0;
        softmax_out_ff[2] <= 32'd0;
        //softmax_out_ff[3] <= 32'd0;
    end
    else
    begin
        state <= next_state;
        input_counter <= next_input_counter;
        cal_counter <= next_cal_counter;
        output_counter <= next_output_counter;
        opt_ff <= next_opt_ff;
        for(i = 0; i < 4; ++i)
        begin
            img_ff[i] <= next_img_ff[i];
        end
        for(i = 0; i < 12; ++i)
        begin
            kernel_ch1_ff[i] <= next_kernel_ch1_ff[i];
        end
        for(i = 0; i < 12; ++i)
        begin
            kernel_ch2_ff[i] <= next_kernel_ch2_ff[i];
        end
        for(i = 0; i < 24; ++i)
        begin
            weight_ff[i] <= next_weight_ff[i];
        end
        for(i = 0; i < 36; ++i)
        begin
            conv_out_ch1_ff[i] <= next_conv_out_ch1_ff[i];
        end
        for(i = 0; i < 36; ++i)
        begin
            conv_out_ch2_ff[i] <= next_conv_out_ch2_ff[i];
        end
        before_act_div_ch1_ff[0] <= next_before_act_div_ch1_ff[0];
        before_act_div_ch1_ff[1] <= next_before_act_div_ch1_ff[1];
        before_act_div_ch2_ff[0] <= next_before_act_div_ch2_ff[0];
        before_act_div_ch2_ff[1] <= next_before_act_div_ch2_ff[1];
        fc_out_ff[0] <= next_fc_out_ff[0];
        fc_out_ff[1] <= next_fc_out_ff[1];
        fc_out_ff[2] <= next_fc_out_ff[2];
        softmax_out_ff[0] <= next_softmax_out_ff[0];
        softmax_out_ff[1] <= next_softmax_out_ff[1];
        softmax_out_ff[2] <= next_softmax_out_ff[2];
        //softmax_out_ff[3] <= next_softmax_out_ff[3];
    end
end

//---------------------------------------------------------------------
//   NEXT STATE
//---------------------------------------------------------------------
always @ (*)
begin
    case(state)
    IDLE:
    begin
        if(in_valid) next_state = IN;
        else next_state = IDLE;
    end
    IN:
    begin
        if(input_counter == 7'd3) next_state = CAL;
        else next_state = IN;
    end
    CAL:
    begin
        if(cal_counter == 7'd74) next_state = MAXPOOL;
        else next_state = CAL;
    end
    MAXPOOL:
    begin
        next_state = FC;
    end
    FC:
    begin
        next_state = SOFTMAX;
    end
    SOFTMAX:
    begin
        next_state = OUT;
    end
    OUT:
    begin
        if(output_counter == 2'd2) next_state = IDLE;
        else next_state = OUT;
    end
    default:
    begin
        next_state = IDLE;
    end
    endcase
end

//---------------------------------------------------------------------
//   OTHER
//---------------------------------------------------------------------
//---------------------------------------------------------------------
//   COUNTER
//---------------------------------------------------------------------
always @ (*)
begin
    if(in_valid) next_input_counter = input_counter + 7'd1;
    else next_input_counter = 7'd0;
end

always @ (*)
begin
    if(state == CAL) next_cal_counter = cal_counter + 7'd1;
    else next_cal_counter = 7'd0;
end

always @ (*)
begin
    if(out_valid) next_output_counter = output_counter + 2'd1;
    else next_output_counter = 2'd0;
end
//---------------------------------------------------------------------
//   NEXT IMG
//---------------------------------------------------------------------
always @ (*)
begin
    if(in_valid)
    begin
        case(input_counter)
        7'd0:
        begin
            next_img_ff[0] = Img;
            next_img_ff[1] = 32'd0;
            next_img_ff[2] = 32'd0;
            next_img_ff[3] = 32'd0;
        end
        7'd1:
        begin
            next_img_ff[0] = img_ff[0];
            next_img_ff[1] = Img;
            next_img_ff[2] = 32'd0;
            next_img_ff[3] = 32'd0;
        end
        7'd2:
        begin
            next_img_ff[0] = img_ff[0];
            next_img_ff[1] = img_ff[1];
            next_img_ff[2] = Img;
            next_img_ff[3] = 32'd0;
        end
        7'd3:
        begin
            next_img_ff[0] = img_ff[0];
            next_img_ff[1] = img_ff[1];
            next_img_ff[2] = img_ff[2];
            next_img_ff[3] = Img;
        end
        default:
        begin
            next_img_ff[0] = img_ff[1];
            next_img_ff[1] = img_ff[2];
            next_img_ff[2] = img_ff[3];
            next_img_ff[3] = Img;
        end
        endcase
    end
    else
    begin
        next_img_ff[0] = img_ff[1];
        next_img_ff[1] = img_ff[2];
        next_img_ff[2] = img_ff[3];
        next_img_ff[3] = 32'd0;
    end
end

//---------------------------------------------------------------------
//   NEXT KERNEL
//---------------------------------------------------------------------
//ch1
always @ (*)
begin
    if(out_valid)
    begin
        for(i = 0; i < 12; ++i)
        begin
            next_kernel_ch1_ff[i] = 32'd0;
        end
    end
    else
    begin
        for(i = 0; i < 12; ++i)
        begin
            next_kernel_ch1_ff[i] = kernel_ch1_ff[i];
        end
        if(in_valid && (input_counter < 7'd12)) next_kernel_ch1_ff[input_counter] = Kernel_ch1;
    end
end
//ch2
always @ (*)
begin
    if(out_valid)
    begin
        for(i = 0; i < 12; ++i)
        begin
            next_kernel_ch2_ff[i] = 32'd0;
        end
    end
    else
    begin
        for(i = 0; i < 12; ++i)
        begin
            next_kernel_ch2_ff[i] = kernel_ch2_ff[i];
        end
        if(in_valid && (input_counter < 7'd12)) next_kernel_ch2_ff[input_counter] = Kernel_ch2;
    end
end

//---------------------------------------------------------------------
//   NEXT WEIGHT
//---------------------------------------------------------------------
always @ (*)
begin
    if(out_valid)
    begin
        for(i = 0; i < 24; ++i)
        begin
            next_weight_ff[i] = 32'd0;
        end
    end
    else
    begin
        for(i = 0; i < 24; ++i)
        begin
            next_weight_ff[i] = weight_ff[i];
        end
        if(in_valid && (input_counter < 7'd24)) next_weight_ff[input_counter] = Weight;
    end
end
//---------------------------------------------------------------------
//   NEXT OPT
//---------------------------------------------------------------------
always @ (*)
begin
    if(out_valid)
    begin
        next_opt_ff = 1'b0;
    end
    else
    begin
        if(in_valid && (input_counter == 7'd0)) next_opt_ff = Opt;
        else next_opt_ff = opt_ff;
    end
end

//---------------------------------------------------------------------
//   M0~7 a b
//---------------------------------------------------------------------
//M0
always @ (*)
begin
    if(state == CAL) M0_a = img_ff[0];
    else M0_a = 32'd0;
end
always @ (*)
begin
    if(state == CAL)
    begin
        if(cal_counter < 7'd25) M0_b = kernel_ch1_ff[0];
        else if((cal_counter >= 7'd25) && (cal_counter < 7'd50)) M0_b = kernel_ch1_ff[4];
        else if((cal_counter >= 7'd50) && (cal_counter < 7'd75)) M0_b = kernel_ch1_ff[8];
        else M0_b = 32'd0;
    end
    else M0_b = 32'd0;
end
//M1
always @ (*)
begin
    if(state == CAL) M1_a = img_ff[0];
    else M1_a = 32'd0;
end
always @ (*)
begin
    if(state == CAL)
    begin
        if(cal_counter < 7'd25) M1_b = kernel_ch1_ff[1];
        else if((cal_counter >= 7'd25) && (cal_counter < 7'd50)) M1_b = kernel_ch1_ff[5];
        else if((cal_counter >= 7'd50) && (cal_counter < 7'd75)) M1_b = kernel_ch1_ff[9];
        else M1_b = 32'd0;
    end
    else M1_b = 32'd0;
end
//M2
always @ (*)
begin
    if(state == CAL) M2_a = img_ff[0];
    else M2_a = 32'd0;
end
always @ (*)
begin
    if(state == CAL)
    begin
        if(cal_counter < 7'd25) M2_b = kernel_ch1_ff[2];
        else if((cal_counter >= 7'd25) && (cal_counter < 7'd50)) M2_b = kernel_ch1_ff[6];
        else if((cal_counter >= 7'd50) && (cal_counter < 7'd75)) M2_b = kernel_ch1_ff[10];
        else M2_b = 32'd0;
    end
    else M2_b = 32'd0;
end
//M3
always @ (*)
begin
    if(state == CAL) M3_a = img_ff[0];
    else M3_a = 32'd0;
end
always @ (*)
begin
    if(state == CAL)
    begin
        if(cal_counter < 7'd25) M3_b = kernel_ch1_ff[3];
        else if((cal_counter >= 7'd25) && (cal_counter < 7'd50)) M3_b = kernel_ch1_ff[7];
        else if((cal_counter >= 7'd50) && (cal_counter < 7'd75)) M3_b = kernel_ch1_ff[11];
        else M3_b = 32'd0;
    end
    else M3_b = 32'd0;
end
//M4
always @ (*)
begin
    if(state == CAL) M4_a = img_ff[0];
    else M4_a = 32'd0;
end
always @ (*)
begin
    if(state == CAL)
    begin
        if(cal_counter < 7'd25) M4_b = kernel_ch2_ff[0];
        else if((cal_counter >= 7'd25) && (cal_counter < 7'd50)) M4_b = kernel_ch2_ff[4];
        else if((cal_counter >= 7'd50) && (cal_counter < 7'd75)) M4_b = kernel_ch2_ff[8];
        else M4_b = 32'd0;
    end
    else M4_b = 32'd0;
end
//M5
always @ (*)
begin
    if(state == CAL) M5_a = img_ff[0];
    else M5_a = 32'd0;
end
always @ (*)
begin
    if(state == CAL)
    begin
        if(cal_counter < 7'd25) M5_b = kernel_ch2_ff[1];
        else if((cal_counter >= 7'd25) && (cal_counter < 7'd50)) M5_b = kernel_ch2_ff[5];
        else if((cal_counter >= 7'd50) && (cal_counter < 7'd75)) M5_b = kernel_ch2_ff[9];
        else M5_b = 32'd0;
    end
    else M5_b = 32'd0;
end
//M6
always @ (*)
begin
    if(state == CAL) M6_a = img_ff[0];
    else M6_a = 32'd0;
end
always @ (*)
begin
    if(state == CAL)
    begin
        if(cal_counter < 7'd25) M6_b = kernel_ch2_ff[2];
        else if((cal_counter >= 7'd25) && (cal_counter < 7'd50)) M6_b = kernel_ch2_ff[6];
        else if((cal_counter >= 7'd50) && (cal_counter < 7'd75)) M6_b = kernel_ch2_ff[10];
        else M6_b = 32'd0;
    end
    else M6_b = 32'd0;
end
//M7
always @ (*)
begin
    if(state == CAL) M7_a = img_ff[0];
    else M7_a = 32'd0;
end
always @ (*)
begin
    if(state == CAL)
    begin
        if(cal_counter < 7'd25) M7_b = kernel_ch2_ff[3];
        else if((cal_counter >= 7'd25) && (cal_counter < 7'd50)) M7_b = kernel_ch2_ff[7];
        else if((cal_counter >= 7'd50) && (cal_counter < 7'd75)) M7_b = kernel_ch2_ff[11];
        else M7_b = 32'd0;
    end
    else M7_b = 32'd0;
end

//---------------------------------------------------------------------
//   CONV OUT POS
//---------------------------------------------------------------------
always @ (*)
begin
    if(state == CAL)
    begin
        if(cal_counter < 7'd5)
        begin
            conv_out_pos[0] = cal_counter + 7'd7;
            conv_out_pos[1] = cal_counter + 7'd6;
            conv_out_pos[2] = cal_counter + 7'd1;
            conv_out_pos[3] = cal_counter;
        end
        else if((cal_counter >= 7'd5) && (cal_counter < 7'd10))
        begin
            conv_out_pos[0] = cal_counter + 7'd8;
            conv_out_pos[1] = cal_counter + 7'd7;
            conv_out_pos[2] = cal_counter + 7'd2;
            conv_out_pos[3] = cal_counter + 7'd1;
        end
        else if((cal_counter >= 7'd10) && (cal_counter < 7'd15))
        begin
            conv_out_pos[0] = cal_counter + 7'd9;
            conv_out_pos[1] = cal_counter + 7'd8;
            conv_out_pos[2] = cal_counter + 7'd3;
            conv_out_pos[3] = cal_counter + 7'd2;
        end
        else if((cal_counter >= 7'd15) && (cal_counter < 7'd20))
        begin
            conv_out_pos[0] = cal_counter + 7'd10;
            conv_out_pos[1] = cal_counter + 7'd9;
            conv_out_pos[2] = cal_counter + 7'd4;
            conv_out_pos[3] = cal_counter + 7'd3;
        end
        else if((cal_counter >= 7'd20) && (cal_counter < 7'd25))
        begin
            conv_out_pos[0] = cal_counter + 7'd11;
            conv_out_pos[1] = cal_counter + 7'd10;
            conv_out_pos[2] = cal_counter + 7'd5;
            conv_out_pos[3] = cal_counter + 7'd4;
        end
        else if((cal_counter >= 7'd25) && (cal_counter < 7'd30))
        begin
            conv_out_pos[0] = cal_counter - 7'd18;
            conv_out_pos[1] = cal_counter - 7'd19;
            conv_out_pos[2] = cal_counter - 7'd24;
            conv_out_pos[3] = cal_counter - 7'd25;
        end
        else if((cal_counter >= 7'd30) && (cal_counter < 7'd35))
        begin
            conv_out_pos[0] = cal_counter - 7'd17;
            conv_out_pos[1] = cal_counter - 7'd18;
            conv_out_pos[2] = cal_counter - 7'd23;
            conv_out_pos[3] = cal_counter - 7'd24;
        end
        else if((cal_counter >= 7'd35) && (cal_counter < 7'd40))
        begin
            conv_out_pos[0] = cal_counter - 7'd16;
            conv_out_pos[1] = cal_counter - 7'd17;
            conv_out_pos[2] = cal_counter - 7'd22;
            conv_out_pos[3] = cal_counter - 7'd23;
        end
        else if((cal_counter >= 7'd40) && (cal_counter < 7'd45))
        begin
            conv_out_pos[0] = cal_counter - 7'd15;
            conv_out_pos[1] = cal_counter - 7'd16;
            conv_out_pos[2] = cal_counter - 7'd21;
            conv_out_pos[3] = cal_counter - 7'd22;
        end
        else if((cal_counter >= 7'd45) && (cal_counter < 7'd50))
        begin
            conv_out_pos[0] = cal_counter - 7'd14;
            conv_out_pos[1] = cal_counter - 7'd15;
            conv_out_pos[2] = cal_counter - 7'd20;
            conv_out_pos[3] = cal_counter - 7'd21;
        end
        else if((cal_counter >= 7'd50) && (cal_counter < 7'd55))
        begin
            conv_out_pos[0] = cal_counter - 7'd43;
            conv_out_pos[1] = cal_counter - 7'd44;
            conv_out_pos[2] = cal_counter - 7'd49;
            conv_out_pos[3] = cal_counter - 7'd50;
        end
        else if((cal_counter >= 7'd55) && (cal_counter < 7'd60))
        begin
            conv_out_pos[0] = cal_counter - 7'd42;
            conv_out_pos[1] = cal_counter - 7'd43;
            conv_out_pos[2] = cal_counter - 7'd48;
            conv_out_pos[3] = cal_counter - 7'd49;
        end
        else if((cal_counter >= 7'd60) && (cal_counter < 7'd65))
        begin
            conv_out_pos[0] = cal_counter - 7'd41;
            conv_out_pos[1] = cal_counter - 7'd42;
            conv_out_pos[2] = cal_counter - 7'd47;
            conv_out_pos[3] = cal_counter - 7'd48;
        end
        else if((cal_counter >= 7'd65) && (cal_counter < 7'd70))
        begin
            conv_out_pos[0] = cal_counter - 7'd40;
            conv_out_pos[1] = cal_counter - 7'd41;
            conv_out_pos[2] = cal_counter - 7'd46;
            conv_out_pos[3] = cal_counter - 7'd47;
        end
        else if((cal_counter >= 7'd70) && (cal_counter < 7'd75))
        begin
            conv_out_pos[0] = cal_counter - 7'd39;
            conv_out_pos[1] = cal_counter - 7'd40;
            conv_out_pos[2] = cal_counter - 7'd45;
            conv_out_pos[3] = cal_counter - 7'd46;
        end
        else
        begin
            conv_out_pos[0] = 7'd0;
            conv_out_pos[1] = 7'd0;
            conv_out_pos[2] = 7'd0;
            conv_out_pos[3] = 7'd0;
        end
    end
    else
    begin
        conv_out_pos[0] = 7'd0;
        conv_out_pos[1] = 7'd0;
        conv_out_pos[2] = 7'd0;
        conv_out_pos[3] = 7'd0;
    end
end

//---------------------------------------------------------------------
//   A1_0_a S1_0_a
//---------------------------------------------------------------------
always @ (*)
begin
    if(state == CAL)
    begin
        case(cal_counter)
        7'd0, 7'd25, 7'd50: //1(opt_ff)?:32'd0;
        begin
            A1_0_a = conv_out_ch1_ff[conv_out_pos[0]];
            A1_0_b = M0_z;
            A1_1_a = (opt_ff)?M0_z:32'd0;
            A1_1_b = M1_z;
            A1_2_a = conv_out_ch1_ff[conv_out_pos[1]];
            A1_2_b = A1_1_z;
            A1_3_a = (opt_ff)?M2_z:32'd0;
            A1_3_b = M3_z;
            S1_0_a = conv_out_ch1_ff[conv_out_pos[2]];
            S1_0_b = (opt_ff)?M0_z:32'd0;
            S1_0_c = M2_z;
            S1_1_a = conv_out_ch1_ff[conv_out_pos[3]];
            S1_1_b = (opt_ff)?A1_1_z:32'd0;
            S1_1_c = A1_3_z;
        end
        7'd4, 7'd29, 7'd54: //5
        begin
            A1_0_a = conv_out_ch1_ff[conv_out_pos[1]];
            A1_0_b = M1_z;
            A1_1_a = M0_z;
            A1_1_b = (opt_ff)?M1_z:32'd0;
            A1_2_a = conv_out_ch1_ff[conv_out_pos[0]];
            A1_2_b = A1_1_z;
            A1_3_a = M2_z;
            A1_3_b = (opt_ff)?M3_z:32'd0;
            S1_0_a = conv_out_ch1_ff[conv_out_pos[3]];
            S1_0_b = (opt_ff)?M1_z:32'd0;
            S1_0_c = M3_z;
            S1_1_a = conv_out_ch1_ff[conv_out_pos[2]];
            S1_1_b = (opt_ff)?A1_1_z:32'd0;
            S1_1_c = A1_3_z;
        end
        7'd20, 7'd45, 7'd70: //21
        begin
            A1_0_a = conv_out_ch1_ff[conv_out_pos[2]];
            A1_0_b = M2_z;
            A1_1_a = (opt_ff)?M2_z:32'd0;
            A1_1_b = M3_z;
            A1_2_a = conv_out_ch1_ff[conv_out_pos[3]];
            A1_2_b = A1_1_z;
            A1_3_a = (opt_ff)?M0_z:32'd0;
            A1_3_b = M1_z;
            S1_0_a = conv_out_ch1_ff[conv_out_pos[0]];
            S1_0_b = M0_z;
            S1_0_c = (opt_ff)?M2_z:32'd0;
            S1_1_a = conv_out_ch1_ff[conv_out_pos[1]];
            S1_1_b = (opt_ff)?A1_1_z:32'd0;
            S1_1_c = A1_3_z;
        end
        7'd24, 7'd49, 7'd74: //25
        begin
            A1_0_a = conv_out_ch1_ff[conv_out_pos[3]];
            A1_0_b = M3_z;
            A1_1_a = M2_z;
            A1_1_b = (opt_ff)?M3_z:32'd0;
            A1_2_a = conv_out_ch1_ff[conv_out_pos[2]];
            A1_2_b = A1_1_z;
            A1_3_a = M0_z;
            A1_3_b = (opt_ff)?M1_z:32'd0;
            S1_0_a = conv_out_ch1_ff[conv_out_pos[1]];
            S1_0_b = M1_z;
            S1_0_c = (opt_ff)?M3_z:32'd0;
            S1_1_a = conv_out_ch1_ff[conv_out_pos[0]];
            S1_1_b = (opt_ff)?A1_1_z:32'd0;
            S1_1_c = A1_3_z;
        end
        7'd1, 7'd2, 7'd3, 7'd26, 7'd27, 7'd28, 7'd51, 7'd52, 7'd53: //2 3 4
        begin
            A1_0_a = conv_out_ch1_ff[conv_out_pos[0]];
            A1_0_b = M0_z;
            A1_1_a = conv_out_ch1_ff[conv_out_pos[1]];
            A1_1_b = M1_z;
            A1_2_a = 32'd0;
            A1_2_b = 32'd0;
            A1_3_a = 32'd0;
            A1_3_b = 32'd0;
            S1_0_a = conv_out_ch1_ff[conv_out_pos[2]];
            S1_0_b = (opt_ff)?M0_z:32'd0;
            S1_0_c = M2_z;
            S1_1_a = conv_out_ch1_ff[conv_out_pos[3]];
            S1_1_b = (opt_ff)?M1_z:32'd0;
            S1_1_c = M3_z;
        end
        7'd5, 7'd10, 7'd15, 7'd30, 7'd35, 7'd40, 7'd55, 7'd60, 7'd65: //6 11 16
        begin
            A1_0_a = conv_out_ch1_ff[conv_out_pos[0]];
            A1_0_b = M0_z;
            A1_1_a = conv_out_ch1_ff[conv_out_pos[2]];
            A1_1_b = M2_z;
            A1_2_a = 32'd0;
            A1_2_b = 32'd0;
            A1_3_a = 32'd0;
            A1_3_b = 32'd0;
            S1_0_a = conv_out_ch1_ff[conv_out_pos[1]];
            S1_0_b = (opt_ff)?M0_z:32'd0;
            S1_0_c = M1_z;
            S1_1_a = conv_out_ch1_ff[conv_out_pos[3]];
            S1_1_b = (opt_ff)?M2_z:32'd0;
            S1_1_c = M3_z;
        end
        7'd9, 7'd14, 7'd19, 7'd34, 7'd39, 7'd44, 7'd59, 7'd64, 7'd69: //10 15 20
        begin
            A1_0_a = conv_out_ch1_ff[conv_out_pos[1]];
            A1_0_b = M1_z;
            A1_1_a = conv_out_ch1_ff[conv_out_pos[3]];
            A1_1_b = M3_z;
            A1_2_a = 32'd0;
            A1_2_b = 32'd0;
            A1_3_a = 32'd0;
            A1_3_b = 32'd0;
            S1_0_a = conv_out_ch1_ff[conv_out_pos[0]];
            S1_0_b = M0_z;
            S1_0_c = (opt_ff)?M1_z:32'd0;
            S1_1_a = conv_out_ch1_ff[conv_out_pos[2]];
            S1_1_b = M2_z;
            S1_1_c = (opt_ff)?M3_z:32'd0;
        end
        7'd21, 7'd22, 7'd23, 7'd46, 7'd47, 7'd48, 7'd71, 7'd72, 7'd73: //22 23 24
        begin
            A1_0_a = conv_out_ch1_ff[conv_out_pos[2]];
            A1_0_b = M2_z;
            A1_1_a = conv_out_ch1_ff[conv_out_pos[3]];
            A1_1_b = M3_z;
            A1_2_a = 32'd0;
            A1_2_b = 32'd0;
            A1_3_a = 32'd0;
            A1_3_b = 32'd0;
            S1_0_a = conv_out_ch1_ff[conv_out_pos[0]];
            S1_0_b = M0_z;
            S1_0_c = (opt_ff)?M2_z:32'd0;
            S1_1_a = conv_out_ch1_ff[conv_out_pos[1]];
            S1_1_b = M1_z;
            S1_1_c = (opt_ff)?M3_z:32'd0;
        end
        7'd6, 7'd7, 7'd8, 7'd11, 7'd12, 7'd13, 7'd16, 7'd17, 7'd18,  
        7'd31, 7'd32, 7'd33, 7'd36, 7'd37, 7'd38, 7'd41, 7'd42, 7'd43, 
        7'd56, 7'd57, 7'd58, 7'd61, 7'd62, 7'd63, 7'd66, 7'd67, 7'd68: //7 8 9 12 13 14 17 18 19
        begin
            A1_0_a = conv_out_ch1_ff[conv_out_pos[0]];
            A1_0_b = M0_z;
            A1_1_a = conv_out_ch1_ff[conv_out_pos[1]];
            A1_1_b = M1_z;
            A1_2_a = conv_out_ch1_ff[conv_out_pos[2]];
            A1_2_b = M2_z;
            A1_3_a = conv_out_ch1_ff[conv_out_pos[3]];
            A1_3_b = M3_z;
            S1_0_a = 32'd0;
            S1_0_b = 32'd0;
            S1_0_c = 32'd0;
            S1_1_a = 32'd0;
            S1_1_b = 32'd0;
            S1_1_c = 32'd0;
        end
        default:
        begin
            A1_0_a = 32'd0;
            A1_0_b = 32'd0;
            A1_1_a = 32'd0;
            A1_1_b = 32'd0;
            A1_2_a = 32'd0;
            A1_2_b = 32'd0;
            A1_3_a = 32'd0;
            A1_3_b = 32'd0;
            S1_0_a = 32'd0;
            S1_0_b = 32'd0;
            S1_0_c = 32'd0;
            S1_1_a = 32'd0;
            S1_1_b = 32'd0;
            S1_1_c = 32'd0;
        end
        endcase
    end
    else 
    begin
        A1_0_a = 32'd0;
        A1_0_b = 32'd0;
        A1_1_a = 32'd0;
        A1_1_b = 32'd0;
        A1_2_a = 32'd0;
        A1_2_b = 32'd0;
        A1_3_a = 32'd0;
        A1_3_b = 32'd0;
        S1_0_a = 32'd0;
        S1_0_b = 32'd0;
        S1_0_c = 32'd0;
        S1_1_a = 32'd0;
        S1_1_b = 32'd0;
        S1_1_c = 32'd0;
    end
end

//---------------------------------------------------------------------
//   A2_0_a S2_0_a
//---------------------------------------------------------------------
always @ (*)
begin
    if(state == CAL)
    begin
        case(cal_counter)
        7'd0, 7'd25, 7'd50: //1(opt_ff)?:32'd0;
        begin
            A2_0_a = conv_out_ch2_ff[conv_out_pos[0]];
            A2_0_b = M4_z;
            A2_1_a = (opt_ff)?M4_z:32'd0;
            A2_1_b = M5_z;
            A2_2_a = conv_out_ch2_ff[conv_out_pos[1]];
            A2_2_b = A2_1_z;
            A2_3_a = (opt_ff)?M6_z:32'd0;
            A2_3_b = M7_z;
            S2_0_a = conv_out_ch2_ff[conv_out_pos[2]];
            S2_0_b = (opt_ff)?M4_z:32'd0;
            S2_0_c = M6_z;
            S2_1_a = conv_out_ch2_ff[conv_out_pos[3]];
            S2_1_b = (opt_ff)?A2_1_z:32'd0;
            S2_1_c = A2_3_z;
        end
        7'd4, 7'd29, 7'd54: //5
        begin
            A2_0_a = conv_out_ch2_ff[conv_out_pos[1]];
            A2_0_b = M5_z;
            A2_1_a = M4_z;
            A2_1_b = (opt_ff)?M5_z:32'd0;
            A2_2_a = conv_out_ch2_ff[conv_out_pos[0]];
            A2_2_b = A2_1_z;
            A2_3_a = M6_z;
            A2_3_b = (opt_ff)?M7_z:32'd0;
            S2_0_a = conv_out_ch2_ff[conv_out_pos[3]];
            S2_0_b = (opt_ff)?M5_z:32'd0;
            S2_0_c = M7_z;
            S2_1_a = conv_out_ch2_ff[conv_out_pos[2]];
            S2_1_b = (opt_ff)?A2_1_z:32'd0;
            S2_1_c = A2_3_z;
        end
        7'd20, 7'd45, 7'd70: //21
        begin
            A2_0_a = conv_out_ch2_ff[conv_out_pos[2]];
            A2_0_b = M6_z;
            A2_1_a = (opt_ff)?M6_z:32'd0;
            A2_1_b = M7_z;
            A2_2_a = conv_out_ch2_ff[conv_out_pos[3]];
            A2_2_b = A2_1_z;
            A2_3_a = (opt_ff)?M4_z:32'd0;
            A2_3_b = M5_z;
            S2_0_a = conv_out_ch2_ff[conv_out_pos[0]];
            S2_0_b = M4_z;
            S2_0_c = (opt_ff)?M6_z:32'd0;
            S2_1_a = conv_out_ch2_ff[conv_out_pos[1]];
            S2_1_b = (opt_ff)?A2_1_z:32'd0;
            S2_1_c = A2_3_z;
        end
        7'd24, 7'd49, 7'd74: //25
        begin
            A2_0_a = conv_out_ch2_ff[conv_out_pos[3]];
            A2_0_b = M7_z;
            A2_1_a = M6_z;
            A2_1_b = (opt_ff)?M7_z:32'd0;
            A2_2_a = conv_out_ch2_ff[conv_out_pos[2]];
            A2_2_b = A2_1_z;
            A2_3_a = M4_z;
            A2_3_b = (opt_ff)?M5_z:32'd0;
            S2_0_a = conv_out_ch2_ff[conv_out_pos[1]];
            S2_0_b = M5_z;
            S2_0_c = (opt_ff)?M7_z:32'd0;
            S2_1_a = conv_out_ch2_ff[conv_out_pos[0]];
            S2_1_b = (opt_ff)?A2_1_z:32'd0;
            S2_1_c = A2_3_z;
        end
        7'd1, 7'd2, 7'd3, 7'd26, 7'd27, 7'd28, 7'd51, 7'd52, 7'd53: //2 3 4
        begin
            A2_0_a = conv_out_ch2_ff[conv_out_pos[0]];
            A2_0_b = M4_z;
            A2_1_a = conv_out_ch2_ff[conv_out_pos[1]];
            A2_1_b = M5_z;
            A2_2_a = 32'd0;
            A2_2_b = 32'd0;
            A2_3_a = 32'd0;
            A2_3_b = 32'd0;
            S2_0_a = conv_out_ch2_ff[conv_out_pos[2]];
            S2_0_b = (opt_ff)?M4_z:32'd0;
            S2_0_c = M6_z;
            S2_1_a = conv_out_ch2_ff[conv_out_pos[3]];
            S2_1_b = (opt_ff)?M5_z:32'd0;
            S2_1_c = M7_z;
        end
        7'd5, 7'd10, 7'd15, 7'd30, 7'd35, 7'd40, 7'd55, 7'd60, 7'd65: //6 11 16
        begin
            A2_0_a = conv_out_ch2_ff[conv_out_pos[0]];
            A2_0_b = M4_z;
            A2_1_a = conv_out_ch2_ff[conv_out_pos[2]];
            A2_1_b = M6_z;
            A2_2_a = 32'd0;
            A2_2_b = 32'd0;
            A2_3_a = 32'd0;
            A2_3_b = 32'd0;
            S2_0_a = conv_out_ch2_ff[conv_out_pos[1]];
            S2_0_b = (opt_ff)?M4_z:32'd0;
            S2_0_c = M5_z;
            S2_1_a = conv_out_ch2_ff[conv_out_pos[3]];
            S2_1_b = (opt_ff)?M6_z:32'd0;
            S2_1_c = M7_z;
        end
        7'd9, 7'd14, 7'd19, 7'd34, 7'd39, 7'd44, 7'd59, 7'd64, 7'd69: //10 15 20
        begin
            A2_0_a = conv_out_ch2_ff[conv_out_pos[1]];
            A2_0_b = M5_z;
            A2_1_a = conv_out_ch2_ff[conv_out_pos[3]];
            A2_1_b = M7_z;
            A2_2_a = 32'd0;
            A2_2_b = 32'd0;
            A2_3_a = 32'd0;
            A2_3_b = 32'd0;
            S2_0_a = conv_out_ch2_ff[conv_out_pos[0]];
            S2_0_b = M4_z;
            S2_0_c = (opt_ff)?M5_z:32'd0;
            S2_1_a = conv_out_ch2_ff[conv_out_pos[2]];
            S2_1_b = M6_z;
            S2_1_c = (opt_ff)?M7_z:32'd0;
        end
        7'd21, 7'd22, 7'd23, 7'd46, 7'd47, 7'd48, 7'd71, 7'd72, 7'd73: //22 23 24
        begin
            A2_0_a = conv_out_ch2_ff[conv_out_pos[2]];
            A2_0_b = M6_z;
            A2_1_a = conv_out_ch2_ff[conv_out_pos[3]];
            A2_1_b = M7_z;
            A2_2_a = 32'd0;
            A2_2_b = 32'd0;
            A2_3_a = 32'd0;
            A2_3_b = 32'd0;
            S2_0_a = conv_out_ch2_ff[conv_out_pos[0]];
            S2_0_b = M4_z;
            S2_0_c = (opt_ff)?M6_z:32'd0;
            S2_1_a = conv_out_ch2_ff[conv_out_pos[1]];
            S2_1_b = M5_z;
            S2_1_c = (opt_ff)?M7_z:32'd0;
        end
        7'd6, 7'd7, 7'd8, 7'd11, 7'd12, 7'd13, 7'd16, 7'd17, 7'd18,  
        7'd31, 7'd32, 7'd33, 7'd36, 7'd37, 7'd38, 7'd41, 7'd42, 7'd43, 
        7'd56, 7'd57, 7'd58, 7'd61, 7'd62, 7'd63, 7'd66, 7'd67, 7'd68: //7 8 9 12 13 14 17 18 19
        begin
            A2_0_a = conv_out_ch2_ff[conv_out_pos[0]];
            A2_0_b = M4_z;
            A2_1_a = conv_out_ch2_ff[conv_out_pos[1]];
            A2_1_b = M5_z;
            A2_2_a = conv_out_ch2_ff[conv_out_pos[2]];
            A2_2_b = M6_z;
            A2_3_a = conv_out_ch2_ff[conv_out_pos[3]];
            A2_3_b = M7_z;
            S2_0_a = 32'd0;
            S2_0_b = 32'd0;
            S2_0_c = 32'd0;
            S2_1_a = 32'd0;
            S2_1_b = 32'd0;
            S2_1_c = 32'd0;
        end
        default:
        begin
            A2_0_a = 32'd0;
            A2_0_b = 32'd0;
            A2_1_a = 32'd0;
            A2_1_b = 32'd0;
            A2_2_a = 32'd0;
            A2_2_b = 32'd0;
            A2_3_a = 32'd0;
            A2_3_b = 32'd0;
            S2_0_a = 32'd0;
            S2_0_b = 32'd0;
            S2_0_c = 32'd0;
            S2_1_a = 32'd0;
            S2_1_b = 32'd0;
            S2_1_c = 32'd0;
        end
        endcase
    end
    else 
    begin
        A2_0_a = 32'd0;
        A2_0_b = 32'd0;
        A2_1_a = 32'd0;
        A2_1_b = 32'd0;
        A2_2_a = 32'd0;
        A2_2_b = 32'd0;
        A2_3_a = 32'd0;
        A2_3_b = 32'd0;
        S2_0_a = 32'd0;
        S2_0_b = 32'd0;
        S2_0_c = 32'd0;
        S2_1_a = 32'd0;
        S2_1_b = 32'd0;
        S2_1_c = 32'd0;
    end
end

//---------------------------------------------------------------------
//   NEXT CONV OUT CH1
//---------------------------------------------------------------------
always @ (*)
begin
    if(out_valid)
    begin
        for(i = 0; i < 36; ++i)
        begin
            next_conv_out_ch1_ff[i] = 32'd0;
        end
    end
    else
    begin
        for(i = 0; i < 36; ++i)
        begin
            next_conv_out_ch1_ff[i] = conv_out_ch1_ff[i];
        end
        if(state == CAL)
        begin
            case(cal_counter)
            7'd0, 7'd25, 7'd50: //1
            begin
                next_conv_out_ch1_ff[conv_out_pos[0]] = A1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[1]] = A1_2_z;
                next_conv_out_ch1_ff[conv_out_pos[2]] = S1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[3]] = S1_1_z;
            end
            7'd4, 7'd29, 7'd54: //5
            begin
                next_conv_out_ch1_ff[conv_out_pos[0]] = A1_2_z;
                next_conv_out_ch1_ff[conv_out_pos[1]] = A1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[2]] = S1_1_z;
                next_conv_out_ch1_ff[conv_out_pos[3]] = S1_0_z;
            end
            7'd20, 7'd45, 7'd70: //21
            begin
                next_conv_out_ch1_ff[conv_out_pos[0]] = S1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[1]] = S1_1_z;
                next_conv_out_ch1_ff[conv_out_pos[2]] = A1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[3]] = A1_2_z;
            end
            7'd24, 7'd49, 7'd74: //25
            begin
                next_conv_out_ch1_ff[conv_out_pos[0]] = S1_1_z;
                next_conv_out_ch1_ff[conv_out_pos[1]] = S1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[2]] = A1_2_z;
                next_conv_out_ch1_ff[conv_out_pos[3]] = A1_0_z;
            end
            7'd1, 7'd2, 7'd3, 7'd26, 7'd27, 7'd28, 7'd51, 7'd52, 7'd53: //2 3 4
            begin
                next_conv_out_ch1_ff[conv_out_pos[0]] = A1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[1]] = A1_1_z;
                next_conv_out_ch1_ff[conv_out_pos[2]] = S1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[3]] = S1_1_z;
            end
            7'd5, 7'd10, 7'd15, 7'd30, 7'd35, 7'd40, 7'd55, 7'd60, 7'd65: //6 11 16
            begin
                next_conv_out_ch1_ff[conv_out_pos[0]] = A1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[1]] = S1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[2]] = A1_1_z;
                next_conv_out_ch1_ff[conv_out_pos[3]] = S1_1_z;
            end
            7'd9, 7'd14, 7'd19, 7'd34, 7'd39, 7'd44, 7'd59, 7'd64, 7'd69: //10 15 20
            begin
                next_conv_out_ch1_ff[conv_out_pos[0]] = S1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[1]] = A1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[2]] = S1_1_z;
                next_conv_out_ch1_ff[conv_out_pos[3]] = A1_1_z;
            end
            7'd21, 7'd22, 7'd23, 7'd46, 7'd47, 7'd48, 7'd71, 7'd72, 7'd73: //22 23 24
            begin
                next_conv_out_ch1_ff[conv_out_pos[0]] = S1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[1]] = S1_1_z;
                next_conv_out_ch1_ff[conv_out_pos[2]] = A1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[3]] = A1_1_z;
            end
            7'd6, 7'd7, 7'd8, 7'd11, 7'd12, 7'd13, 7'd16, 7'd17, 7'd18,  
            7'd31, 7'd32, 7'd33, 7'd36, 7'd37, 7'd38, 7'd41, 7'd42, 7'd43, 
            7'd56, 7'd57, 7'd58, 7'd61, 7'd62, 7'd63, 7'd66, 7'd67, 7'd68: //7 8 9 12 13 14 17 18 19
            begin
                next_conv_out_ch1_ff[conv_out_pos[0]] = A1_0_z;
                next_conv_out_ch1_ff[conv_out_pos[1]] = A1_1_z;
                next_conv_out_ch1_ff[conv_out_pos[2]] = A1_2_z;
                next_conv_out_ch1_ff[conv_out_pos[3]] = A1_3_z;
            end
            endcase
        end
    end
end

//---------------------------------------------------------------------
//   NEXT CONV OUT CH2
//---------------------------------------------------------------------
always @ (*)
begin
    if(out_valid)
    begin
        for(i = 0; i < 36; ++i)
        begin
            next_conv_out_ch2_ff[i] = 32'd0;
        end
    end
    else
    begin
        for(i = 0; i < 36; ++i)
        begin
            next_conv_out_ch2_ff[i] = conv_out_ch2_ff[i];
        end
        if(state == CAL)
        begin
            case(cal_counter)
            7'd0, 7'd25, 7'd50: //1
            begin
                next_conv_out_ch2_ff[conv_out_pos[0]] = A2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[1]] = A2_2_z;
                next_conv_out_ch2_ff[conv_out_pos[2]] = S2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[3]] = S2_1_z;
            end
            7'd4, 7'd29, 7'd54: //5
            begin
                next_conv_out_ch2_ff[conv_out_pos[0]] = A2_2_z;
                next_conv_out_ch2_ff[conv_out_pos[1]] = A2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[2]] = S2_1_z;
                next_conv_out_ch2_ff[conv_out_pos[3]] = S2_0_z;
            end
            7'd20, 7'd45, 7'd70: //21
            begin
                next_conv_out_ch2_ff[conv_out_pos[0]] = S2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[1]] = S2_1_z;
                next_conv_out_ch2_ff[conv_out_pos[2]] = A2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[3]] = A2_2_z;
            end
            7'd24, 7'd49, 7'd74: //25
            begin
                next_conv_out_ch2_ff[conv_out_pos[0]] = S2_1_z;
                next_conv_out_ch2_ff[conv_out_pos[1]] = S2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[2]] = A2_2_z;
                next_conv_out_ch2_ff[conv_out_pos[3]] = A2_0_z;
            end
            7'd1, 7'd2, 7'd3, 7'd26, 7'd27, 7'd28, 7'd51, 7'd52, 7'd53: //2 3 4
            begin
                next_conv_out_ch2_ff[conv_out_pos[0]] = A2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[1]] = A2_1_z;
                next_conv_out_ch2_ff[conv_out_pos[2]] = S2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[3]] = S2_1_z;
            end
            7'd5, 7'd10, 7'd15, 7'd30, 7'd35, 7'd40, 7'd55, 7'd60, 7'd65: //6 11 16
            begin
                next_conv_out_ch2_ff[conv_out_pos[0]] = A2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[1]] = S2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[2]] = A2_1_z;
                next_conv_out_ch2_ff[conv_out_pos[3]] = S2_1_z;
            end
            7'd9, 7'd14, 7'd19, 7'd34, 7'd39, 7'd44, 7'd59, 7'd64, 7'd69: //10 15 20
            begin
                next_conv_out_ch2_ff[conv_out_pos[0]] = S2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[1]] = A2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[2]] = S2_1_z;
                next_conv_out_ch2_ff[conv_out_pos[3]] = A2_1_z;
            end
            7'd21, 7'd22, 7'd23, 7'd46, 7'd47, 7'd48, 7'd71, 7'd72, 7'd73: //22 23 24
            begin
                next_conv_out_ch2_ff[conv_out_pos[0]] = S2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[1]] = S2_1_z;
                next_conv_out_ch2_ff[conv_out_pos[2]] = A2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[3]] = A2_1_z;
            end
            7'd6, 7'd7, 7'd8, 7'd11, 7'd12, 7'd13, 7'd16, 7'd17, 7'd18,  
            7'd31, 7'd32, 7'd33, 7'd36, 7'd37, 7'd38, 7'd41, 7'd42, 7'd43, 
            7'd56, 7'd57, 7'd58, 7'd61, 7'd62, 7'd63, 7'd66, 7'd67, 7'd68: //7 8 9 12 13 14 17 18 19
            begin
                next_conv_out_ch2_ff[conv_out_pos[0]] = A2_0_z;
                next_conv_out_ch2_ff[conv_out_pos[1]] = A2_1_z;
                next_conv_out_ch2_ff[conv_out_pos[2]] = A2_2_z;
                next_conv_out_ch2_ff[conv_out_pos[3]] = A2_3_z;
            end
            endcase
        end
    end
end

//---------------------------------------------------------------------
//   C1_in[8:0]
//---------------------------------------------------------------------
always @ (*)
begin
    if(cal_counter == 7'd63)
    begin
        C1_in[0] = conv_out_ch1_ff[0];
        C1_in[1] = conv_out_ch1_ff[1];
        C1_in[2] = conv_out_ch1_ff[2];
        C1_in[3] = conv_out_ch1_ff[6];
        C1_in[4] = conv_out_ch1_ff[7];
        C1_in[5] = conv_out_ch1_ff[8];
        C1_in[6] = conv_out_ch1_ff[12];
        C1_in[7] = conv_out_ch1_ff[13];
        C1_in[8] = conv_out_ch1_ff[14];
    end
    else if(cal_counter == 7'd65)
    begin
        C1_in[0] = conv_out_ch1_ff[3];
        C1_in[1] = conv_out_ch1_ff[4];
        C1_in[2] = conv_out_ch1_ff[5];
        C1_in[3] = conv_out_ch1_ff[9];
        C1_in[4] = conv_out_ch1_ff[10];
        C1_in[5] = conv_out_ch1_ff[11];
        C1_in[6] = conv_out_ch1_ff[15];
        C1_in[7] = conv_out_ch1_ff[16];
        C1_in[8] = conv_out_ch1_ff[17];
    end
    else if(cal_counter == 7'd73)
    begin
        C1_in[0] = conv_out_ch1_ff[18];
        C1_in[1] = conv_out_ch1_ff[19];
        C1_in[2] = conv_out_ch1_ff[20];
        C1_in[3] = conv_out_ch1_ff[24];
        C1_in[4] = conv_out_ch1_ff[25];
        C1_in[5] = conv_out_ch1_ff[26];
        C1_in[6] = conv_out_ch1_ff[30];
        C1_in[7] = conv_out_ch1_ff[31];
        C1_in[8] = conv_out_ch1_ff[32];
    end
    else if(state == MAXPOOL)
    begin
        C1_in[0] = conv_out_ch1_ff[21];
        C1_in[1] = conv_out_ch1_ff[22];
        C1_in[2] = conv_out_ch1_ff[23];
        C1_in[3] = conv_out_ch1_ff[27];
        C1_in[4] = conv_out_ch1_ff[28];
        C1_in[5] = conv_out_ch1_ff[29];
        C1_in[6] = conv_out_ch1_ff[33];
        C1_in[7] = conv_out_ch1_ff[34];
        C1_in[8] = conv_out_ch1_ff[35];
    end
    else
    begin
        C1_in[0] = 32'd0;
        C1_in[1] = 32'd0;
        C1_in[2] = 32'd0;
        C1_in[3] = 32'd0;
        C1_in[4] = 32'd0;
        C1_in[5] = 32'd0;
        C1_in[6] = 32'd0;
        C1_in[7] = 32'd0;
        C1_in[8] = 32'd0;
    end
end

//---------------------------------------------------------------------
//   C2_in[8:0]
//---------------------------------------------------------------------
always @ (*)
begin
    if(cal_counter == 7'd63)
    begin
        C2_in[0] = conv_out_ch2_ff[0];
        C2_in[1] = conv_out_ch2_ff[1];
        C2_in[2] = conv_out_ch2_ff[2];
        C2_in[3] = conv_out_ch2_ff[6];
        C2_in[4] = conv_out_ch2_ff[7];
        C2_in[5] = conv_out_ch2_ff[8];
        C2_in[6] = conv_out_ch2_ff[12];
        C2_in[7] = conv_out_ch2_ff[13];
        C2_in[8] = conv_out_ch2_ff[14];
    end
    else if(cal_counter == 7'd65)
    begin
        C2_in[0] = conv_out_ch2_ff[3];
        C2_in[1] = conv_out_ch2_ff[4];
        C2_in[2] = conv_out_ch2_ff[5];
        C2_in[3] = conv_out_ch2_ff[9];
        C2_in[4] = conv_out_ch2_ff[10];
        C2_in[5] = conv_out_ch2_ff[11];
        C2_in[6] = conv_out_ch2_ff[15];
        C2_in[7] = conv_out_ch2_ff[16];
        C2_in[8] = conv_out_ch2_ff[17];
    end
    else if(cal_counter == 7'd73)
    begin
        C2_in[0] = conv_out_ch2_ff[18];
        C2_in[1] = conv_out_ch2_ff[19];
        C2_in[2] = conv_out_ch2_ff[20];
        C2_in[3] = conv_out_ch2_ff[24];
        C2_in[4] = conv_out_ch2_ff[25];
        C2_in[5] = conv_out_ch2_ff[26];
        C2_in[6] = conv_out_ch2_ff[30];
        C2_in[7] = conv_out_ch2_ff[31];
        C2_in[8] = conv_out_ch2_ff[32];
    end
    else if(state == MAXPOOL)
    begin
        C2_in[0] = conv_out_ch2_ff[21];
        C2_in[1] = conv_out_ch2_ff[22];
        C2_in[2] = conv_out_ch2_ff[23];
        C2_in[3] = conv_out_ch2_ff[27];
        C2_in[4] = conv_out_ch2_ff[28];
        C2_in[5] = conv_out_ch2_ff[29];
        C2_in[6] = conv_out_ch2_ff[33];
        C2_in[7] = conv_out_ch2_ff[34];
        C2_in[8] = conv_out_ch2_ff[35];
    end
    else
    begin
        C2_in[0] = 32'd0;
        C2_in[1] = 32'd0;
        C2_in[2] = 32'd0;
        C2_in[3] = 32'd0;
        C2_in[4] = 32'd0;
        C2_in[5] = 32'd0;
        C2_in[6] = 32'd0;
        C2_in[7] = 32'd0;
        C2_in[8] = 32'd0;
    end
end

//---------------------------------------------------------------------
//   E1_0_a E1_1_a
//---------------------------------------------------------------------
always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL))
    begin
        E1_0_a = C1_out; //e^z
    end
    else
    begin
        E1_0_a = 32'd0;
    end
end

always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL))
    begin
        E1_1_a = {(C1_out[31] ^ (1'b1)) , C1_out[30:0]}; //e^-z
    end
    else
    begin
        E1_1_a = 32'd0;
    end
end

//---------------------------------------------------------------------
//   E2_0_a E2_1_a
//---------------------------------------------------------------------
always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL))
    begin
        E2_0_a = C2_out; //e^z
    end
    else
    begin
        E2_0_a = 32'd0;
    end
end

always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL))
    begin
        E2_1_a = {(C2_out[31] ^ (1'b1)) , C2_out[30:0]}; //e^-z
    end
    else
    begin
        E2_1_a = 32'd0;
    end
end

//---------------------------------------------------------------------
//   Sub1_act_a
//---------------------------------------------------------------------
always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL))
    begin
        Sub1_act_a = E1_0_z;
    end
    else
    begin
        Sub1_act_a = 32'd0;
    end
end
always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL))
    begin
        Sub1_act_b = E1_1_z;
    end
    else
    begin
        Sub1_act_b = 32'd0;
    end
end

//---------------------------------------------------------------------
//   A1_act_a
//---------------------------------------------------------------------
always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL))
    begin
        A1_act_a = (opt_ff)?E1_0_z:32'b0011_1111_1000_0000_0000_0000_0000_0000;
    end
    else
    begin
        A1_act_a = 32'd0;
    end
end
always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL))
    begin
        A1_act_b = E1_1_z;
    end
    else
    begin
        A1_act_b = 32'd0;
    end
end

//---------------------------------------------------------------------
//   Sub2_act_a
//---------------------------------------------------------------------
always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL))
    begin
        Sub2_act_a = E2_0_z;
    end
    else
    begin
        Sub2_act_a = 32'd0;
    end
end
always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL))
    begin
        Sub2_act_b = E2_1_z;
    end
    else
    begin
        Sub2_act_b = 32'd0;
    end
end

//---------------------------------------------------------------------
//   A2_act_a
//---------------------------------------------------------------------
always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL))
    begin
        A2_act_a = (opt_ff)?E2_0_z:32'b0011_1111_1000_0000_0000_0000_0000_0000;
    end
    else
    begin
        A2_act_a = 32'd0;
    end
end
always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL))
    begin
        A2_act_b = E2_1_z;
    end
    else
    begin
        A2_act_b = 32'd0;
    end
end

//---------------------------------------------------------------------
//   next_before_act_div_ch1_ff
//---------------------------------------------------------------------
always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL)) next_before_act_div_ch1_ff[0] = Sub1_act_z;
    else next_before_act_div_ch1_ff[0] = 32'd0;
end
always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL)) next_before_act_div_ch1_ff[1] = A1_act_z;
    else next_before_act_div_ch1_ff[1] = 32'd0;
end

//---------------------------------------------------------------------
//   next_before_act_div_ch2_ff
//---------------------------------------------------------------------
always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL)) next_before_act_div_ch2_ff[0] = Sub2_act_z;
    else next_before_act_div_ch2_ff[0] = 32'd0;
end
always @ (*)
begin
    if((cal_counter == 7'd63) || (cal_counter == 7'd65) || (cal_counter == 7'd73) || (state == MAXPOOL)) next_before_act_div_ch2_ff[1] = A2_act_z;
    else next_before_act_div_ch2_ff[1] = 32'd0;
end

//---------------------------------------------------------------------
//   D1 a b
//---------------------------------------------------------------------
always @ (*)
begin
    if((cal_counter == 7'd64) || (cal_counter == 7'd66) || (cal_counter == 7'd74) || (state == FC))
    begin
        D1_a = (opt_ff)?before_act_div_ch1_ff[0]:32'b0011_1111_1000_0000_0000_0000_0000_0000;
    end
    else
    begin
        D1_a = 32'd0;
    end
end
always @ (*)
begin
    if((cal_counter == 7'd64) || (cal_counter == 7'd66) || (cal_counter == 7'd74) || (state == FC))
    begin
        D1_b = before_act_div_ch1_ff[1];
    end
    else
    begin
        D1_b = 32'd0;
    end
end

//---------------------------------------------------------------------
//   D2 a b
//---------------------------------------------------------------------
always @ (*)
begin
    if((cal_counter == 7'd64) || (cal_counter == 7'd66) || (cal_counter == 7'd74) || (state == FC))
    begin
        D2_a = (opt_ff)?before_act_div_ch2_ff[0]:32'b0011_1111_1000_0000_0000_0000_0000_0000;
    end
    else
    begin
        D2_a = 32'd0;
    end
end
always @ (*)
begin
    if((cal_counter == 7'd64) || (cal_counter == 7'd66) || (cal_counter == 7'd74) || (state == FC))
    begin
        D2_b = before_act_div_ch2_ff[1];
    end
    else
    begin
        D2_b = 32'd0;
    end
end

//---------------------------------------------------------------------
//   M1_0_Fc_a
//---------------------------------------------------------------------
always @ (*)
begin
    if(cal_counter == 7'd64)
    begin
        M1_0_fc_a = D1_z;
        M1_0_fc_b = weight_ff[0];
        M1_1_fc_a = D1_z;
        M1_1_fc_b = weight_ff[8];
        M1_2_fc_a = D1_z;
        M1_2_fc_b = weight_ff[16];
    end
    else if(cal_counter == 7'd66)
    begin
        M1_0_fc_a = D1_z;
        M1_0_fc_b = weight_ff[1];
        M1_1_fc_a = D1_z;
        M1_1_fc_b = weight_ff[9];
        M1_2_fc_a = D1_z;
        M1_2_fc_b = weight_ff[17];
    end
    else if(cal_counter == 7'd74)
    begin
        M1_0_fc_a = D1_z;
        M1_0_fc_b = weight_ff[2];
        M1_1_fc_a = D1_z;
        M1_1_fc_b = weight_ff[10];
        M1_2_fc_a = D1_z;
        M1_2_fc_b = weight_ff[18];
    end
    else if(state == FC)
    begin
        M1_0_fc_a = D1_z;
        M1_0_fc_b = weight_ff[3];
        M1_1_fc_a = D1_z;
        M1_1_fc_b = weight_ff[11];
        M1_2_fc_a = D1_z;
        M1_2_fc_b = weight_ff[19];
    end
    else
    begin
        M1_0_fc_a = 32'd0;
        M1_0_fc_b = 32'd0;
        M1_1_fc_a = 32'd0;
        M1_1_fc_b = 32'd0;
        M1_2_fc_a = 32'd0;
        M1_2_fc_b = 32'd0;
    end
end
//---------------------------------------------------------------------
//   M2_0_Fc_a
//---------------------------------------------------------------------
always @ (*)
begin
    if(cal_counter == 7'd64)
    begin
        M2_0_fc_a = D2_z;
        M2_0_fc_b = weight_ff[4];
        M2_1_fc_a = D2_z;
        M2_1_fc_b = weight_ff[12];
        M2_2_fc_a = D2_z;
        M2_2_fc_b = weight_ff[20];
    end
    else if(cal_counter == 7'd66)
    begin
        M2_0_fc_a = D2_z;
        M2_0_fc_b = weight_ff[5];
        M2_1_fc_a = D2_z;
        M2_1_fc_b = weight_ff[13];
        M2_2_fc_a = D2_z;
        M2_2_fc_b = weight_ff[21];
    end
    else if(cal_counter == 7'd74)
    begin
        M2_0_fc_a = D2_z;
        M2_0_fc_b = weight_ff[6];
        M2_1_fc_a = D2_z;
        M2_1_fc_b = weight_ff[14];
        M2_2_fc_a = D2_z;
        M2_2_fc_b = weight_ff[22];
    end
    else if(state == FC)
    begin
        M2_0_fc_a = D2_z;
        M2_0_fc_b = weight_ff[7];
        M2_1_fc_a = D2_z;
        M2_1_fc_b = weight_ff[15];
        M2_2_fc_a = D2_z;
        M2_2_fc_b = weight_ff[23];
    end
    else
    begin
        M2_0_fc_a = 32'd0;
        M2_0_fc_b = 32'd0;
        M2_1_fc_a = 32'd0;
        M2_1_fc_b = 32'd0;
        M2_2_fc_a = 32'd0;
        M2_2_fc_b = 32'd0;
    end
end
//---------------------------------------------------------------------
//   S0_fc_a b c
//---------------------------------------------------------------------
always @ (*)
begin
    if((cal_counter == 7'd64) || (cal_counter == 7'd66) || (cal_counter == 7'd74) || (state == FC))
    begin
        S0_fc_a = fc_out_ff[0];
        S0_fc_b = M1_0_fc_z;
        S0_fc_c = M2_0_fc_z;
    end
    else
    begin
        S0_fc_a = 32'd0;
        S0_fc_b = 32'd0;
        S0_fc_c = 32'd0;
    end
end
//---------------------------------------------------------------------
//   S1_fc_a b c
//---------------------------------------------------------------------
always @ (*)
begin
    if((cal_counter == 7'd64) || (cal_counter == 7'd66) || (cal_counter == 7'd74) || (state == FC))
    begin
        S1_fc_a = fc_out_ff[1];
        S1_fc_b = M1_1_fc_z;
        S1_fc_c = M2_1_fc_z;
    end
    else
    begin
        S1_fc_a = 32'd0;
        S1_fc_b = 32'd0;
        S1_fc_c = 32'd0;
    end
end
//---------------------------------------------------------------------
//   S2_fc_a b c
//---------------------------------------------------------------------
always @ (*)
begin
    if((cal_counter == 7'd64) || (cal_counter == 7'd66) || (cal_counter == 7'd74) || (state == FC))
    begin
        S2_fc_a = fc_out_ff[2];
        S2_fc_b = M1_2_fc_z;
        S2_fc_c = M2_2_fc_z;
    end
    else
    begin
        S2_fc_a = 32'd0;
        S2_fc_b = 32'd0;
        S2_fc_c = 32'd0;
    end
end
//---------------------------------------------------------------------
//   next_fc_out_ff
//---------------------------------------------------------------------
always @ (*)
begin
    if(output_counter == 2'd2)
    begin
        next_fc_out_ff[0] = 32'd0;
        next_fc_out_ff[1] = 32'd0;
        next_fc_out_ff[2] = 32'd0;
    end
    else
    begin
        if((cal_counter == 7'd64) || (cal_counter == 7'd66) || (cal_counter == 7'd74) || (state == FC))
        begin
            next_fc_out_ff[0] = S0_fc_z;
            next_fc_out_ff[1] = S1_fc_z;
            next_fc_out_ff[2] = S2_fc_z;
        end
        else
        begin
            next_fc_out_ff[0] = fc_out_ff[0];
            next_fc_out_ff[1] = fc_out_ff[1];
            next_fc_out_ff[2] = fc_out_ff[2];
        end
    end
end

//---------------------------------------------------------------------
//   E0_softmax_a
//---------------------------------------------------------------------
always @ (*)
begin
    if((state == SOFTMAX) || ((state == OUT) && ((output_counter == 2'd0) || (output_counter == 2'd1)))) E0_softmax_a = fc_out_ff[0];
    else E0_softmax_a = 32'd0;
end
always @ (*)
begin
    if((state == SOFTMAX) || ((state == OUT) && ((output_counter == 2'd0) || (output_counter == 2'd1)))) E1_softmax_a = fc_out_ff[1];
    else E1_softmax_a = 32'd0;
end
always @ (*)
begin
    if((state == SOFTMAX) || ((state == OUT) && ((output_counter == 2'd0) || (output_counter == 2'd1)))) E2_softmax_a = fc_out_ff[2];
    else E2_softmax_a = 32'd0;
end

//---------------------------------------------------------------------
//   S_softmax_a
//---------------------------------------------------------------------
always @ (*)
begin
    if((state == SOFTMAX) || ((state == OUT) && ((output_counter == 2'd0) || (output_counter == 2'd1)))) S_softmax_a = E0_softmax_z;
    else S_softmax_a = 32'd0;
end
always @ (*)
begin
    if((state == SOFTMAX) || ((state == OUT) && ((output_counter == 2'd0) || (output_counter == 2'd1)))) S_softmax_b = E1_softmax_z;
    else S_softmax_b = 32'd0;
end
always @ (*)
begin
    if((state == SOFTMAX) || ((state == OUT) && ((output_counter == 2'd0) || (output_counter == 2'd1)))) S_softmax_c = E2_softmax_z;
    else S_softmax_c = 32'd0;
end

//---------------------------------------------------------------------
//   D0_softmax_a
//---------------------------------------------------------------------
always @ (*)
begin
    if(state == SOFTMAX) D0_softmax_a = E0_softmax_z;
    else if((state == OUT) && (output_counter == 2'd0)) D0_softmax_a = E1_softmax_z;
    else if((state == OUT) && (output_counter == 2'd1)) D0_softmax_a = E2_softmax_z;
    else D0_softmax_a = 32'd0;
end
always @ (*)
begin
    if((state == SOFTMAX) || ((state == OUT) && ((output_counter == 2'd0) || (output_counter == 2'd1)))) D0_softmax_b = S_softmax_z;
    else D0_softmax_b = 32'd0;
end


//---------------------------------------------------------------------
//   next_softmax_out_ff
//---------------------------------------------------------------------
always @ (*)
begin
    if(output_counter == 2'd2)
    begin
        next_softmax_out_ff[0] = 32'd0;
        next_softmax_out_ff[1] = 32'd0;
        next_softmax_out_ff[2] = 32'd0;
    end
    else
    begin
        if(state == SOFTMAX)
        begin
            next_softmax_out_ff[0] = D0_softmax_z;
            next_softmax_out_ff[1] = softmax_out_ff[1];
            next_softmax_out_ff[2] = softmax_out_ff[2];
        end
        else if((state == OUT) && (output_counter == 2'd0))
        begin
            next_softmax_out_ff[0] = softmax_out_ff[0];
            next_softmax_out_ff[1] = D0_softmax_z;
            next_softmax_out_ff[2] = softmax_out_ff[2];
        end
        else if((state == OUT) && (output_counter == 2'd1))
        begin
            next_softmax_out_ff[0] = softmax_out_ff[0];
            next_softmax_out_ff[1] = softmax_out_ff[1];
            next_softmax_out_ff[2] = D0_softmax_z;
        end
        else
        begin
            next_softmax_out_ff[0] = softmax_out_ff[0];
            next_softmax_out_ff[1] = softmax_out_ff[1];
            next_softmax_out_ff[2] = softmax_out_ff[2];
        end
    end
end
//---------------------------------------------------------------------
//   OUT
//---------------------------------------------------------------------
always @ (*)
begin
    if(state == OUT) out_valid = 1'b1;
    else out_valid = 1'b0;
end

always @ (*)
begin
    if(state == OUT)
    begin
        if(output_counter == 2'd0) out = softmax_out_ff[0];
        else if(output_counter == 2'd1) out = softmax_out_ff[1];
        else if(output_counter == 2'd2) out = softmax_out_ff[2];
        else out = 32'd0;
    end
    else out = 32'd0;
end

endmodule