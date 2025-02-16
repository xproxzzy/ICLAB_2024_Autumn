//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/9
//		Version		: v1.0
//   	File Name   : MDC.v
//   	Module Name : MDC
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "HAMMING_IP.v"
//synopsys translate_on

module MDC(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_data, 
	in_mode,
    // Output signals
    out_valid, 
	out_data
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [8:0] in_mode;
input [14:0] in_data;

output reg out_valid;
output reg [206:0] out_data;

//==================================================================
// parameter & integer
//==================================================================
parameter IDLE = 2'd0;
parameter CAL = 2'd1;
parameter WAIT = 2'd2;
parameter OUT = 2'd3;

integer i;

//==================================================================
// reg & wire
//==================================================================
reg [1:0] state;
reg [1:0] next_state;
reg [3:0] counter;
reg [3:0] next_counter;

reg [8:0] in_mode_reg;
reg [8:0] next_in_mode_reg;
reg [14:0] in_data_reg;
reg [14:0] next_in_data_reg;

reg [8:0] in_mode_ip_in;
reg [4:0] in_mode_ip_out;
reg [14:0] in_data_ip_in;
reg [10:0] in_data_ip_out;

reg [4:0] true_in_mode_reg;
reg [4:0] next_true_in_mode_reg;
reg [10:0] true_in_data_reg [15:0];
reg [10:0] next_true_in_data_reg [15:0];

reg [10:0] in_0_0, in_0_1, in_0_2, in_1_0, in_1_1, in_1_2, in_2_0, in_2_1, in_2_2;
reg signed [22:0] z_2;
reg signed [35:0] z_3;

reg [35:0] a_mac;
reg [10:0] b_mac;
reg [48:0] c_mac;
reg [48:0] z_mac;

reg [206:0] out_reg;
reg [206:0] next_out_reg;
//==================================================================
// IP module
//==================================================================
HAMMING_IP #(.IP_BIT(5)) HAMMING_IP_1 (.IN_code(in_mode_ip_in), .OUT_code(in_mode_ip_out));

HAMMING_IP #(.IP_BIT(11)) HAMMING_IP_0 (.IN_code(in_data_ip_in), .OUT_code(in_data_ip_out));

DET_3 DET_3(.in_0_0(in_0_0), .in_0_1(in_0_1), .in_0_2(in_0_2), 
            .in_1_0(in_1_0), .in_1_1(in_1_1), .in_1_2(in_1_2), 
            .in_2_0(in_2_0), .in_2_1(in_2_1), .in_2_2(in_2_2), 
            .z_2(z_2), .z_3(z_3));

MAC_4 MAC_4(.a_mac(a_mac), .b_mac(b_mac), .c_mac(c_mac), .z_mac(z_mac));
//==================================================================
// sequential
//==================================================================
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state <= IDLE;
        counter <= 4'd0;
        true_in_mode_reg <= 5'd0;
        for(i = 0; i < 16; i = i + 1)
        begin
            true_in_data_reg[i] <= 11'd0;
        end
        out_reg <= 207'd0;
    end
    else
    begin
        state <= next_state;
        counter <= next_counter;
        true_in_mode_reg <= next_true_in_mode_reg;
        for(i = 0; i < 16; i = i + 1)
        begin
            true_in_data_reg[i] <= next_true_in_data_reg[i];
        end
        out_reg <= next_out_reg;
    end
end

//==================================================================
// next state
//==================================================================
always @ (*)
begin
    case(state)
    IDLE:
    begin
        if(in_valid) next_state = CAL;
        else next_state = IDLE;
    end
    CAL:
    begin
        if(counter == 4'd15) next_state = WAIT;
        else next_state = CAL;
    end
    WAIT:
    begin
        next_state = OUT;
    end
    OUT:
    begin
        next_state = IDLE;
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
    if(in_valid) next_counter = counter + 4'd1;
    else next_counter = 4'd0;
end

//==================================================================
// in_mode_ip_in in_data_ip_in
//==================================================================
/*always @ (*)
begin
    if(in_valid && (counter == 4'd0)) in_mode_ip_in = in_mode;
    else in_mode_ip_in = 9'd0;
end

always @ (*)
begin
    if(in_valid) in_data_ip_in = in_data;
    else in_data_ip_in = 15'd0;
end*/
always @ (*)
begin
    in_mode_ip_in = in_mode;
end

always @ (*)
begin
    in_data_ip_in = in_data;
end
//==================================================================
// true_in_mode_reg true_in_data_reg
//==================================================================
always @ (*)
begin
    if(in_valid && (counter == 4'd0)) next_true_in_mode_reg = in_mode_ip_out;
    else next_true_in_mode_reg = true_in_mode_reg;
end

always @ (*)
begin
    for(i = 0; i < 16; ++i)
    begin
        next_true_in_data_reg[i] = true_in_data_reg[i];
    end
    if(in_valid)
    begin
        next_true_in_data_reg[counter] = in_data_ip_out;
    end
end

//==================================================================
// DET_in
//==================================================================
always @ (*)
begin
    if(state == WAIT)
    begin
        if(true_in_mode_reg == 5'b00100) //2
        begin
            in_0_0 = true_in_data_reg[10];
            in_0_1 = true_in_data_reg[11];
            in_0_2 = 11'd0;
            in_1_0 = true_in_data_reg[14];
            in_1_1 = true_in_data_reg[15];
            in_1_2 = 11'd0;
            in_2_0 = 11'd0;
            in_2_1 = 11'd0;
            in_2_2 = 11'd0;
        end
        else //3
        begin
            in_0_0 = true_in_data_reg[5];
            in_0_1 = true_in_data_reg[6];
            in_0_2 = true_in_data_reg[7];
            in_1_0 = true_in_data_reg[9];
            in_1_1 = true_in_data_reg[10];
            in_1_2 = true_in_data_reg[11];
            in_2_0 = true_in_data_reg[13];
            in_2_1 = true_in_data_reg[14];
            in_2_2 = true_in_data_reg[15];
        end
    end
    else
    begin
        case(counter)
        4'd6: //2
        begin
            in_0_0 = true_in_data_reg[0];
            in_0_1 = true_in_data_reg[1];
            in_0_2 = 11'd0;
            in_1_0 = true_in_data_reg[4];
            in_1_1 = true_in_data_reg[5];
            in_1_2 = 11'd0;
            in_2_0 = 11'd0;
            in_2_1 = 11'd0;
            in_2_2 = 11'd0;
        end
        4'd7: //2
        begin
            in_0_0 = true_in_data_reg[1];
            in_0_1 = true_in_data_reg[2];
            in_0_2 = 11'd0;
            in_1_0 = true_in_data_reg[5];
            in_1_1 = true_in_data_reg[6];
            in_1_2 = 11'd0;
            in_2_0 = 11'd0;
            in_2_1 = 11'd0;
            in_2_2 = 11'd0;
        end
        4'd8: //2
        begin
            in_0_0 = true_in_data_reg[2];
            in_0_1 = true_in_data_reg[3];
            in_0_2 = 11'd0;
            in_1_0 = true_in_data_reg[6];
            in_1_1 = true_in_data_reg[7];
            in_1_2 = 11'd0;
            in_2_0 = 11'd0;
            in_2_1 = 11'd0;
            in_2_2 = 11'd0;
        end
        4'd10: //2
        begin
            in_0_0 = true_in_data_reg[4];
            in_0_1 = true_in_data_reg[5];
            in_0_2 = 11'd0;
            in_1_0 = true_in_data_reg[8];
            in_1_1 = true_in_data_reg[9];
            in_1_2 = 11'd0;
            in_2_0 = 11'd0;
            in_2_1 = 11'd0;
            in_2_2 = 11'd0;
        end
        4'd11:
        begin
            if(true_in_mode_reg == 5'b00100) //2
            begin
                in_0_0 = true_in_data_reg[5];
                in_0_1 = true_in_data_reg[6];
                in_0_2 = 11'd0;
                in_1_0 = true_in_data_reg[9];
                in_1_1 = true_in_data_reg[10];
                in_1_2 = 11'd0;
                in_2_0 = 11'd0;
                in_2_1 = 11'd0;
                in_2_2 = 11'd0;
            end
            else //3
            begin
                in_0_0 = true_in_data_reg[0];
                in_0_1 = true_in_data_reg[1];
                in_0_2 = true_in_data_reg[2];
                in_1_0 = true_in_data_reg[4];
                in_1_1 = true_in_data_reg[5];
                in_1_2 = true_in_data_reg[6];
                in_2_0 = true_in_data_reg[8];
                in_2_1 = true_in_data_reg[9];
                in_2_2 = true_in_data_reg[10];
            end
        end
        4'd12:
        begin
            if(true_in_mode_reg == 5'b00100) //2
            begin
                in_0_0 = true_in_data_reg[6];
                in_0_1 = true_in_data_reg[7];
                in_0_2 = 11'd0;
                in_1_0 = true_in_data_reg[10];
                in_1_1 = true_in_data_reg[11];
                in_1_2 = 11'd0;
                in_2_0 = 11'd0;
                in_2_1 = 11'd0;
                in_2_2 = 11'd0;
            end
            else if(true_in_mode_reg == 5'b00110) //3
            begin
                in_0_0 = true_in_data_reg[1];
                in_0_1 = true_in_data_reg[2];
                in_0_2 = true_in_data_reg[3];
                in_1_0 = true_in_data_reg[5];
                in_1_1 = true_in_data_reg[6];
                in_1_2 = true_in_data_reg[7];
                in_2_0 = true_in_data_reg[9];
                in_2_1 = true_in_data_reg[10];
                in_2_2 = true_in_data_reg[11];
            end
            else //4
            begin
                in_0_0 = true_in_data_reg[1];
                in_0_1 = true_in_data_reg[2];
                in_0_2 = true_in_data_reg[3];
                in_1_0 = true_in_data_reg[5];
                in_1_1 = true_in_data_reg[6];
                in_1_2 = true_in_data_reg[7];
                in_2_0 = true_in_data_reg[9];
                in_2_1 = true_in_data_reg[10];
                in_2_2 = true_in_data_reg[11];
            end
        end
        4'd13: //4
        begin
            in_0_0 = true_in_data_reg[0];
            in_0_1 = true_in_data_reg[2];
            in_0_2 = true_in_data_reg[3];
            in_1_0 = true_in_data_reg[4];
            in_1_1 = true_in_data_reg[6];
            in_1_2 = true_in_data_reg[7];
            in_2_0 = true_in_data_reg[8];
            in_2_1 = true_in_data_reg[10];
            in_2_2 = true_in_data_reg[11];
        end
        4'd14:
        begin
            if(true_in_mode_reg == 5'b00100) //2
            begin
                in_0_0 = true_in_data_reg[8];
                in_0_1 = true_in_data_reg[9];
                in_0_2 = 11'd0;
                in_1_0 = true_in_data_reg[12];
                in_1_1 = true_in_data_reg[13];
                in_1_2 = 11'd0;
                in_2_0 = 11'd0;
                in_2_1 = 11'd0;
                in_2_2 = 11'd0;
            end
            else //4
            begin
                in_0_0 = true_in_data_reg[0];
                in_0_1 = true_in_data_reg[1];
                in_0_2 = true_in_data_reg[3];
                in_1_0 = true_in_data_reg[4];
                in_1_1 = true_in_data_reg[5];
                in_1_2 = true_in_data_reg[7];
                in_2_0 = true_in_data_reg[8];
                in_2_1 = true_in_data_reg[9];
                in_2_2 = true_in_data_reg[11];
            end
        end
        4'd15:
        begin
            if(true_in_mode_reg == 5'b00100) //2
            begin
                in_0_0 = true_in_data_reg[9];
                in_0_1 = true_in_data_reg[10];
                in_0_2 = 11'd0;
                in_1_0 = true_in_data_reg[13];
                in_1_1 = true_in_data_reg[14];
                in_1_2 = 11'd0;
                in_2_0 = 11'd0;
                in_2_1 = 11'd0;
                in_2_2 = 11'd0;
            end
            else if(true_in_mode_reg == 5'b00110) //3
            begin
                in_0_0 = true_in_data_reg[4];
                in_0_1 = true_in_data_reg[5];
                in_0_2 = true_in_data_reg[6];
                in_1_0 = true_in_data_reg[8];
                in_1_1 = true_in_data_reg[9];
                in_1_2 = true_in_data_reg[10];
                in_2_0 = true_in_data_reg[12];
                in_2_1 = true_in_data_reg[13];
                in_2_2 = true_in_data_reg[14];
            end
            else //4
            begin
                in_0_0 = true_in_data_reg[0];
                in_0_1 = true_in_data_reg[1];
                in_0_2 = true_in_data_reg[2];
                in_1_0 = true_in_data_reg[4];
                in_1_1 = true_in_data_reg[5];
                in_1_2 = true_in_data_reg[6];
                in_2_0 = true_in_data_reg[8];
                in_2_1 = true_in_data_reg[9];
                in_2_2 = true_in_data_reg[10];
            end
        end
        default:
        begin
            in_0_0 = 11'd0;
            in_0_1 = 11'd0;
            in_0_2 = 11'd0;
            in_1_0 = 11'd0;
            in_1_1 = 11'd0;
            in_1_2 = 11'd0;
            in_2_0 = 11'd0;
            in_2_1 = 11'd0;
            in_2_2 = 11'd0;
        end
        endcase
    end
end
//==================================================================
// MAC
//==================================================================
always @ (*)
begin
    if(state == WAIT)
    begin
        a_mac = out_reg[84:49];
    end
    else if(counter == 4'd13)
    begin
        a_mac = ~out_reg[84:49] + 36'd1;
    end
    else if(counter == 4'd14)
    begin
        a_mac = out_reg[84:49];
    end
    else //4'd15
    begin
        a_mac = ~out_reg[84:49] + 36'd1;
    end

    /*if((state == WAIT)||(counter == 4'd14))
    begin
        a_mac = out_reg[84:49];
    end
    else
    begin
        a_mac = ~out_reg[84:49] + 36'd1;
    end*/
    
    /*if((counter == 4'd13) || (counter == 4'd15))
    begin
        a_mac = ~out_reg[84:49] + 36'd1;
    end
    else
    begin
        a_mac = out_reg[84:49];
    end*/
end

always @ (*)
begin
    if(state == WAIT)
    begin
        b_mac = true_in_data_reg[15];
    end
    else if(counter == 4'd13)
    begin
        b_mac = true_in_data_reg[12];
    end
    else if(counter == 4'd14)
    begin
        b_mac = true_in_data_reg[13];
    end
    else //4'd15
    begin
        b_mac = true_in_data_reg[14];
    end
end

always @ (*)
begin
    c_mac = out_reg[48:0];
end

//==================================================================
// out_reg
//==================================================================
always @ (*)
begin
    if(next_state == IDLE)
    begin
        next_out_reg = 207'd0;
    end
    else
    begin
        next_out_reg = out_reg;
        if(state == WAIT)
        begin
            if(true_in_mode_reg == 5'b00100) //2
            begin
                next_out_reg[22:0] = z_2;
            end
            else if(true_in_mode_reg == 5'b00110) //3
            begin
                next_out_reg[50:0] = z_3;
            end
            else //4
            begin
                next_out_reg[48:0] = z_mac;
            end
        end
        else
        begin
            case(counter)
            4'd6: //2
            begin
                if(true_in_mode_reg == 5'b00100) //2
                begin
                    next_out_reg[206:184] = z_2;
                end
            end
            4'd7: //2
            begin
                if(true_in_mode_reg == 5'b00100) //2
                begin
                    next_out_reg[183:161] = z_2;
                end
            end
            4'd8: //2
            begin
                if(true_in_mode_reg == 5'b00100) //2
                begin
                    next_out_reg[160:138] = z_2;
                end
            end
            4'd10: //2
            begin
                if(true_in_mode_reg == 5'b00100) //2
                begin
                    next_out_reg[137:115] = z_2;
                end
            end
            4'd11:
            begin
                if(true_in_mode_reg == 5'b00100) //2
                begin
                    next_out_reg[114:92] = z_2;
                end
                else if(true_in_mode_reg == 5'b00110) //3
                begin
                    next_out_reg[203:153] = z_3;
                end
            end
            4'd12:
            begin
                if(true_in_mode_reg == 5'b00100) //2
                begin
                    next_out_reg[91:69] = z_2;
                end
                else if(true_in_mode_reg == 5'b00110) //3
                begin
                    next_out_reg[152:102] = z_3;
                end
                else //4
                begin
                    next_out_reg[84:49] = z_3;
                end
            end
            4'd13: //4
            begin
                if(true_in_mode_reg == 5'b10110)
                begin
                    next_out_reg[84:49] = z_3;
                    next_out_reg[48:0] = z_mac;
                end
            end
            4'd14:
            begin
                if(true_in_mode_reg == 5'b00100) //2
                begin
                    next_out_reg[68:46] = z_2;
                end
                else if(true_in_mode_reg == 5'b10110)//4
                begin
                    next_out_reg[84:49] = z_3;
                    next_out_reg[48:0] = z_mac;
                end
            end
            4'd15:
            begin
                if(true_in_mode_reg == 5'b00100) //2
                begin
                    next_out_reg[45:23] = z_2;
                end
                else if(true_in_mode_reg == 5'b00110) //3
                begin
                    next_out_reg[101:51] = z_3;
                end
                else //4
                begin
                    next_out_reg[84:49] = z_3;
                    next_out_reg[48:0] = z_mac;
                end
            end
            endcase
        end
    end
end
//==================================================================
// out
//==================================================================
always @ (*)
begin
    if(state == OUT) out_valid = 1'b1;
    else out_valid = 1'b0;
end

always @ (*)
begin
    if((state == OUT) && (true_in_mode_reg == 5'b10110)) out_data = {{158{out_reg[48]}}, out_reg[48:0]};
    else if(state == OUT) out_data = out_reg;
    else out_data = 207'd0;
end
endmodule

//==================================================================
// DET_module
//==================================================================
module DET_2(in_0_0, in_0_1, in_1_0, in_1_1, z_2);
    input signed [10:0] in_0_0, in_0_1, in_1_0, in_1_1;
    output reg signed [22:0] z_2;
    reg signed [21:0] net_2 [1:0];
    always @ (*)
    begin
        net_2[0] = in_0_0 * in_1_1;
        net_2[1] = in_0_1 * in_1_0;
        z_2 = net_2[0] - net_2[1];
    end
endmodule

module DET_3(in_0_0, in_0_1, in_0_2, in_1_0, in_1_1, in_1_2, in_2_0, in_2_1, in_2_2, z_2, z_3);
    input signed [10:0] in_0_0, in_0_1, in_0_2, in_1_0, in_1_1, in_1_2, in_2_0, in_2_1, in_2_2;
    output reg signed [22:0] z_2;
    output reg signed [35:0] z_3;
    reg signed [22:0] z_2_0, z_2_1, z_2_2;
    reg signed [33:0] net_3 [2:0];
    reg signed [35:0] net_3_1;
    DET_2 DET_2_0(.in_0_0(in_0_1), .in_0_1(in_0_2), .in_1_0(in_1_1), .in_1_1(in_1_2), .z_2(z_2_0));
    DET_2 DET_2_1(.in_0_0(in_0_0), .in_0_1(in_0_2), .in_1_0(in_1_0), .in_1_1(in_1_2), .z_2(z_2_1));
    DET_2 DET_2_2(.in_0_0(in_0_0), .in_0_1(in_0_1), .in_1_0(in_1_0), .in_1_1(in_1_1), .z_2(z_2_2));
    always @ (*)
    begin
        z_2 = z_2_2;
        net_3[0] = z_2_0 * in_2_0;
        net_3[1] = z_2_1 * in_2_1;
        net_3[2] = z_2_2 * in_2_2;
        net_3_1 = net_3[0] - net_3[1];
        z_3 = net_3_1 + net_3[2];
    end
endmodule

module MAC_4(a_mac, b_mac, c_mac, z_mac);
    input signed [35:0] a_mac;
    input signed [10:0] b_mac;
    input signed [48:0] c_mac;
    output reg signed [48:0] z_mac;
    reg signed [46:0] net;
    always @ (*)
    begin
        net = a_mac * b_mac;
        z_mac = net + c_mac;
    end
endmodule