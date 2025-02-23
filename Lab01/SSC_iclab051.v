//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Fall
//   Lab01 Exercise		: Snack Shopping Calculator
//   Author     		  : Yu-Hsiang Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SSC.v
//   Module Name : SSC
//   Release version : V1.0 (Release Date: 2024-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module SSC(
    // Input signals
    card_num,
    input_money,
    snack_num,
    price, 
    // Output signals
    out_valid,
    out_change
);

//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input [63:0] card_num;
input [8:0] input_money;
input [31:0] snack_num;
input [31:0] price;
output out_valid;
output [8:0] out_change;    

//================================================================
//    Wire & Registers 
//================================================================
// Declare the wire/reg you would use in your circuit
// remember 
// wire for port connection and cont. assignment
// reg for proc. assignment

reg out_valid_reg;
reg [8:0] out_change_reg;
assign out_valid = out_valid_reg;
assign out_change = out_change_reg;

reg [3:0] card_odd [7:0];
reg [7:0] card_sum;

wire [7:0] total_price [7:0];

reg [7:0] nest_0 [7:0];

reg [7:0] sort_3 [7:0];
reg [7:0] sort_4 [3:0];
reg [7:0] sort_5 [5:0];

reg [8:0] change [7:0];

//================================================================
//    DESIGN
//================================================================

card_odd_mux card_odd_mux_0(.a(card_num[7:4]), .out(card_odd[0]));
card_odd_mux card_odd_mux_1(.a(card_num[15:12]), .out(card_odd[1]));
card_odd_mux card_odd_mux_2(.a(card_num[23:20]), .out(card_odd[2]));
card_odd_mux card_odd_mux_3(.a(card_num[31:28]), .out(card_odd[3]));
card_odd_mux card_odd_mux_4(.a(card_num[39:36]), .out(card_odd[4]));
card_odd_mux card_odd_mux_5(.a(card_num[47:44]), .out(card_odd[5]));
card_odd_mux card_odd_mux_6(.a(card_num[55:52]), .out(card_odd[6]));
card_odd_mux card_odd_mux_7(.a(card_num[63:60]), .out(card_odd[7]));

always @ (*)
begin
    card_sum = card_odd[0] + card_odd[1] + card_odd[2] + card_odd[3] + card_odd[4] + card_odd[5] + card_odd[6] + card_odd[7]
             + card_num[3:0] + card_num[11:8] + card_num[19:16] + card_num[27:24] + card_num[35:32] + card_num[43:40] + card_num[51:48] + card_num[59:56];
end

mul mul_0(.a(snack_num[3:0]), .b(price[3:0]), .out(total_price[0][7:0]));
mul mul_1(.a(snack_num[7:4]), .b(price[7:4]), .out(total_price[1][7:0]));
mul mul_2(.a(snack_num[11:8]), .b(price[11:8]), .out(total_price[2][7:0]));
mul mul_3(.a(snack_num[15:12]), .b(price[15:12]), .out(total_price[3][7:0]));
mul mul_4(.a(snack_num[19:16]), .b(price[19:16]), .out(total_price[4][7:0]));
mul mul_5(.a(snack_num[23:20]), .b(price[23:20]), .out(total_price[5][7:0]));
mul mul_6(.a(snack_num[27:24]), .b(price[27:24]), .out(total_price[6][7:0]));
mul mul_7(.a(snack_num[31:28]), .b(price[31:28]), .out(total_price[7][7:0]));

always @ (*)
begin
    if( (card_sum == 8'd0) || (card_sum == 8'd10) || (card_sum == 8'd20) || (card_sum == 8'd30) || (card_sum == 8'd40) || 
        (card_sum == 8'd50) || (card_sum == 8'd60) || (card_sum == 8'd70) || (card_sum == 8'd80) || (card_sum == 8'd90) || 
        (card_sum == 8'd100) || (card_sum == 8'd110) || (card_sum == 8'd120) || (card_sum == 8'd130) || (card_sum == 8'd140) || 
        (card_sum == 8'd150))
    begin
        out_valid_reg = 1'b1;
    end
    else
    begin
        out_valid_reg = 1'b0;
    end
end

always @ (*)
begin
    if(out_valid_reg)
    begin
        
        //nest_0
        if((total_price[0] <= total_price[1]) && (total_price[0] <= total_price[2]) && (total_price[0] <= total_price[3]))
        begin
            nest_0[0] = total_price[0];
            if((total_price[1] <= total_price[2]) && (total_price[1] <= total_price[3]))
            begin
                //nest_0[1] = total_price[1];
                if(total_price[2] <= total_price[3])
                begin
                    nest_0[0] = total_price[0];
                    nest_0[1] = total_price[1];
                    nest_0[2] = total_price[2];
                    nest_0[3] = total_price[3];
                end
                else
                begin
                    nest_0[0] = total_price[0];
                    nest_0[1] = total_price[1];
                    nest_0[2] = total_price[3];
                    nest_0[3] = total_price[2];
                end
            end
            else if((total_price[2] <= total_price[1]) && (total_price[2] <= total_price[3]))
            begin
                //nest_0[1] = total_price[2];
                if(total_price[1] <= total_price[3])
                begin
                    nest_0[0] = total_price[0];
                    nest_0[1] = total_price[2];
                    nest_0[2] = total_price[1];
                    nest_0[3] = total_price[3];
                end
                else
                begin
                    nest_0[0] = total_price[0];
                    nest_0[1] = total_price[2];
                    nest_0[2] = total_price[3];
                    nest_0[3] = total_price[1];
                end
            end
            else
            begin
                //nest_0[1] = total_price[3];
                if(total_price[1] <= total_price[2])
                begin
                    nest_0[0] = total_price[0];
                    nest_0[1] = total_price[3];
                    nest_0[2] = total_price[1];
                    nest_0[3] = total_price[2];
                end
                else
                begin
                    nest_0[0] = total_price[0];
                    nest_0[1] = total_price[3];
                    nest_0[2] = total_price[2];
                    nest_0[3] = total_price[1];
                end
            end
        end
        else if((total_price[1] <= total_price[0]) && (total_price[1] <= total_price[2]) && (total_price[1] <= total_price[3]))
        begin
            if((total_price[0] <= total_price[2]) && (total_price[0] <= total_price[3]))
            begin
                if(total_price[2] <= total_price[3])
                begin
                    nest_0[0] = total_price[1];
                    nest_0[1] = total_price[0];
                    nest_0[2] = total_price[2];
                    nest_0[3] = total_price[3];
                end
                else
                begin
                    nest_0[0] = total_price[1];
                    nest_0[1] = total_price[0];
                    nest_0[2] = total_price[3];
                    nest_0[3] = total_price[2];
                end
            end
            else if((total_price[2] <= total_price[0]) && (total_price[2] <= total_price[3]))
            begin
                if(total_price[0] <= total_price[3])
                begin
                    nest_0[0] = total_price[1];
                    nest_0[1] = total_price[2];
                    nest_0[2] = total_price[0];
                    nest_0[3] = total_price[3];
                end
                else
                begin
                    nest_0[0] = total_price[1];
                    nest_0[1] = total_price[2];
                    nest_0[2] = total_price[3];
                    nest_0[3] = total_price[0];
                end
            end
            else
            begin
                if(total_price[0] <= total_price[2])
                begin
                    nest_0[0] = total_price[1];
                    nest_0[1] = total_price[3];
                    nest_0[2] = total_price[0];
                    nest_0[3] = total_price[2];
                end
                else
                begin
                    nest_0[0] = total_price[1];
                    nest_0[1] = total_price[3];
                    nest_0[2] = total_price[2];
                    nest_0[3] = total_price[0];
                end
            end
        end
        else if((total_price[2] <= total_price[0]) && (total_price[2] <= total_price[1]) && (total_price[2] <= total_price[3]))
        begin
            if((total_price[0] <= total_price[1]) && (total_price[0] <= total_price[3]))
            begin
                if(total_price[1] <= total_price[3])
                begin
                    nest_0[0] = total_price[2];
                    nest_0[1] = total_price[0];
                    nest_0[2] = total_price[1];
                    nest_0[3] = total_price[3];
                end
                else
                begin
                    nest_0[0] = total_price[2];
                    nest_0[1] = total_price[0];
                    nest_0[2] = total_price[3];
                    nest_0[3] = total_price[1];
                end
            end
            else if((total_price[1] <= total_price[0]) && (total_price[1] <= total_price[3]))
            begin
                if(total_price[0] <= total_price[3])
                begin
                    nest_0[0] = total_price[2];
                    nest_0[1] = total_price[1];
                    nest_0[2] = total_price[0];
                    nest_0[3] = total_price[3];
                end
                else
                begin
                    nest_0[0] = total_price[2];
                    nest_0[1] = total_price[1];
                    nest_0[2] = total_price[3];
                    nest_0[3] = total_price[0];
                end
            end
            else
            begin
                if(total_price[0] <= total_price[1])
                begin
                    nest_0[0] = total_price[2];
                    nest_0[1] = total_price[3];
                    nest_0[2] = total_price[0];
                    nest_0[3] = total_price[1];
                end
                else
                begin
                    nest_0[0] = total_price[2];
                    nest_0[1] = total_price[3];
                    nest_0[2] = total_price[1];
                    nest_0[3] = total_price[0];
                end
            end
        end
        else
        begin
            if((total_price[0] <= total_price[1]) && (total_price[0] <= total_price[2]))
            begin
                if(total_price[1] <= total_price[2])
                begin
                    nest_0[0] = total_price[3];
                    nest_0[1] = total_price[0];
                    nest_0[2] = total_price[1];
                    nest_0[3] = total_price[2];
                end
                else
                begin
                    nest_0[0] = total_price[3];
                    nest_0[1] = total_price[0];
                    nest_0[2] = total_price[2];
                    nest_0[3] = total_price[1];
                end
            end
            else if((total_price[1] <= total_price[0]) && (total_price[1] <= total_price[2]))
            begin
                if(total_price[0] <= total_price[2])
                begin
                    nest_0[0] = total_price[3];
                    nest_0[1] = total_price[1];
                    nest_0[2] = total_price[0];
                    nest_0[3] = total_price[2];
                end
                else
                begin
                    nest_0[0] = total_price[3];
                    nest_0[1] = total_price[1];
                    nest_0[2] = total_price[2];
                    nest_0[3] = total_price[0];
                end
            end
            else
            begin
                if(total_price[0] <= total_price[1])
                begin
                    nest_0[0] = total_price[3];
                    nest_0[1] = total_price[2];
                    nest_0[2] = total_price[0];
                    nest_0[3] = total_price[1];
                end
                else
                begin
                    nest_0[0] = total_price[3];
                    nest_0[1] = total_price[2];
                    nest_0[2] = total_price[1];
                    nest_0[3] = total_price[0];
                end
            end
        end


        if((total_price[4] <= total_price[5]) && (total_price[4] <= total_price[6]) && (total_price[4] <= total_price[7]))
        begin
            if((total_price[5] <= total_price[6]) && (total_price[5] <= total_price[7]))
            begin
                if(total_price[6] <= total_price[7])
                begin
                    nest_0[4] = total_price[4];
                    nest_0[5] = total_price[5];
                    nest_0[6] = total_price[6];
                    nest_0[7] = total_price[7];
                end
                else
                begin
                    nest_0[4] = total_price[4];
                    nest_0[5] = total_price[5];
                    nest_0[6] = total_price[7];
                    nest_0[7] = total_price[6];
                end
            end
            else if((total_price[6] <= total_price[5]) && (total_price[6] <= total_price[7]))
            begin
                if(total_price[5] <= total_price[7])
                begin
                    nest_0[4] = total_price[4];
                    nest_0[5] = total_price[6];
                    nest_0[6] = total_price[5];
                    nest_0[7] = total_price[7];
                end
                else
                begin
                    nest_0[4] = total_price[4];
                    nest_0[5] = total_price[6];
                    nest_0[6] = total_price[7];
                    nest_0[7] = total_price[5];
                end
            end
            else
            begin
                if(total_price[5] <= total_price[6])
                begin
                    nest_0[4] = total_price[4];
                    nest_0[5] = total_price[7];
                    nest_0[6] = total_price[5];
                    nest_0[7] = total_price[6];
                end
                else
                begin
                    nest_0[4] = total_price[4];
                    nest_0[5] = total_price[7];
                    nest_0[6] = total_price[6];
                    nest_0[7] = total_price[5];
                end
            end
        end
        else if((total_price[5] <= total_price[4]) && (total_price[5] <= total_price[6]) && (total_price[5] <= total_price[7]))
        begin
            if((total_price[4] <= total_price[6]) && (total_price[4] <= total_price[7]))
            begin
                if(total_price[6] <= total_price[7])
                begin
                    nest_0[4] = total_price[5];
                    nest_0[5] = total_price[4];
                    nest_0[6] = total_price[6];
                    nest_0[7] = total_price[7];
                end
                else
                begin
                    nest_0[4] = total_price[5];
                    nest_0[5] = total_price[4];
                    nest_0[6] = total_price[7];
                    nest_0[7] = total_price[6];
                end
            end
            else if((total_price[6] <= total_price[4]) && (total_price[6] <= total_price[7]))
            begin
                if(total_price[4] <= total_price[7])
                begin
                    nest_0[4] = total_price[5];
                    nest_0[5] = total_price[6];
                    nest_0[6] = total_price[4];
                    nest_0[7] = total_price[7];
                end
                else
                begin
                    nest_0[4] = total_price[5];
                    nest_0[5] = total_price[6];
                    nest_0[6] = total_price[7];
                    nest_0[7] = total_price[4];
                end
            end
            else
            begin
                if(total_price[4] <= total_price[6])
                begin
                    nest_0[4] = total_price[5];
                    nest_0[5] = total_price[7];
                    nest_0[6] = total_price[4];
                    nest_0[7] = total_price[6];
                end
                else
                begin
                    nest_0[4] = total_price[5];
                    nest_0[5] = total_price[7];
                    nest_0[6] = total_price[6];
                    nest_0[7] = total_price[4];
                end
            end
        end
        else if((total_price[6] <= total_price[4]) && (total_price[6] <= total_price[5]) && (total_price[6] <= total_price[7]))
        begin
            if((total_price[4] <= total_price[5]) && (total_price[4] <= total_price[7]))
            begin
                if(total_price[5] <= total_price[7])
                begin
                    nest_0[4] = total_price[6];
                    nest_0[5] = total_price[4];
                    nest_0[6] = total_price[5];
                    nest_0[7] = total_price[7];
                end
                else
                begin
                    nest_0[4] = total_price[6];
                    nest_0[5] = total_price[4];
                    nest_0[6] = total_price[7];
                    nest_0[7] = total_price[5];
                end
            end
            else if((total_price[5] <= total_price[4]) && (total_price[5] <= total_price[7]))
            begin
                if(total_price[4] <= total_price[7])
                begin
                    nest_0[4] = total_price[6];
                    nest_0[5] = total_price[5];
                    nest_0[6] = total_price[4];
                    nest_0[7] = total_price[7];
                end
                else
                begin
                    nest_0[4] = total_price[6];
                    nest_0[5] = total_price[5];
                    nest_0[6] = total_price[7];
                    nest_0[7] = total_price[4];
                end
            end
            else
            begin
                if(total_price[4] <= total_price[5])
                begin
                    nest_0[4] = total_price[6];
                    nest_0[5] = total_price[7];
                    nest_0[6] = total_price[4];
                    nest_0[7] = total_price[5];
                end
                else
                begin
                    nest_0[4] = total_price[6];
                    nest_0[5] = total_price[7];
                    nest_0[6] = total_price[5];
                    nest_0[7] = total_price[4];
                end
            end
        end
        else
        begin
            if((total_price[4] <= total_price[5]) && (total_price[4] <= total_price[6]))
            begin
                if(total_price[5] <= total_price[6])
                begin
                    nest_0[4] = total_price[7];
                    nest_0[5] = total_price[4];
                    nest_0[6] = total_price[5];
                    nest_0[7] = total_price[6];
                end
                else
                begin
                    nest_0[4] = total_price[7];
                    nest_0[5] = total_price[4];
                    nest_0[6] = total_price[6];
                    nest_0[7] = total_price[5];
                end
            end
            else if((total_price[5] <= total_price[4]) && (total_price[5] <= total_price[6]))
            begin
                if(total_price[4] <= total_price[6])
                begin
                    nest_0[4] = total_price[7];
                    nest_0[5] = total_price[5];
                    nest_0[6] = total_price[4];
                    nest_0[7] = total_price[6];
                end
                else
                begin
                    nest_0[4] = total_price[7];
                    nest_0[5] = total_price[5];
                    nest_0[6] = total_price[6];
                    nest_0[7] = total_price[4];
                end
            end
            else
            begin
                if(total_price[4] <= total_price[5])
                begin
                    nest_0[4] = total_price[7];
                    nest_0[5] = total_price[6];
                    nest_0[6] = total_price[4];
                    nest_0[7] = total_price[5];
                end
                else
                begin
                    nest_0[4] = total_price[7];
                    nest_0[5] = total_price[6];
                    nest_0[6] = total_price[5];
                    nest_0[7] = total_price[4];
                end
            end
        end
        //sort_3
        if(nest_0[0] < nest_0[4])
        begin
            sort_3[0] = nest_0[0];
            sort_3[4] = nest_0[4];
        end
        else
        begin
            sort_3[0] = nest_0[4];
            sort_3[4] = nest_0[0];
        end
        if(nest_0[1] < nest_0[5])
        begin
            sort_3[1] = nest_0[1];
            sort_3[5] = nest_0[5];
        end
        else
        begin
            sort_3[1] = nest_0[5];
            sort_3[5] = nest_0[1];
        end
        if(nest_0[2] < nest_0[6])
        begin
            sort_3[2] = nest_0[2];
            sort_3[6] = nest_0[6];
        end
        else
        begin
            sort_3[2] = nest_0[6];
            sort_3[6] = nest_0[2];
        end
        if(nest_0[3] < nest_0[7])
        begin
            sort_3[3] = nest_0[3];
            sort_3[7] = nest_0[7];
        end
        else
        begin
            sort_3[3] = nest_0[7];
            sort_3[7] = nest_0[3];
        end

        //sort_4
        if(sort_3[2]<sort_3[4])
        begin
            sort_4[0] = sort_3[2];
            sort_4[1] = sort_3[4];
        end
        else
        begin
            sort_4[0] = sort_3[4];
            sort_4[1] = sort_3[2];
        end
        if(sort_3[3]<sort_3[5])
        begin
            sort_4[2] = sort_3[3];
            sort_4[3] = sort_3[5];
        end
        else
        begin
            sort_4[2] = sort_3[5];
            sort_4[3] = sort_3[3];
        end
        //sort_5
        if(sort_3[1]<sort_4[0])
        begin
            sort_5[0] = sort_3[1];
            sort_5[1] = sort_4[0];
        end
        else
        begin
            sort_5[0] = sort_4[0];
            sort_5[1] = sort_3[1];
        end
        if(sort_4[1]<sort_4[2])
        begin
            sort_5[2] = sort_4[1];
            sort_5[3] = sort_4[2];
        end
        else
        begin
            sort_5[2] = sort_4[2];
            sort_5[3] = sort_4[1];
        end
        if(sort_4[3]<sort_3[6])
        begin
            sort_5[4] = sort_4[3];
            sort_5[5] = sort_3[6];
        end
        else
        begin
            sort_5[4] = sort_3[6];
            sort_5[5] = sort_4[3];
        end
        //sort_3[0] < sort_5[0] ~ sort_5[5] < sort_3[7]

        change[0] = input_money - sort_3[7];
        change[1] = input_money - sort_3[7] - sort_5[5];
        change[2] = input_money - sort_3[7] - sort_5[5] - sort_5[4];
        change[3] = input_money - sort_3[7] - sort_5[5] - sort_5[4] - sort_5[3];
        change[4] = input_money - sort_3[7] - sort_5[5] - sort_5[4] - sort_5[3] - sort_5[2];
        change[5] = input_money - sort_3[7] - sort_5[5] - sort_5[4] - sort_5[3] - sort_5[2] - sort_5[1];
        change[6] = input_money - sort_3[7] - sort_5[5] - sort_5[4] - sort_5[3] - sort_5[2] - sort_5[1] - sort_5[0];
        change[7] = input_money - sort_3[7] - sort_5[5] - sort_5[4] - sort_5[3] - sort_5[2] - sort_5[1] - sort_5[0] - sort_3[0];

        if(sort_3[7] <= input_money)
        begin
            if(sort_5[5] <= change[0])
            begin
                if(sort_5[4] <= change[1])
                begin
                    if(sort_5[3] <= change[2])
                    begin
                        if(sort_5[2] <= change[3])
                        begin
                            if(sort_5[1] <= change[4])
                            begin
                                if(sort_5[0] <= change[5])
                                begin
                                    if(sort_3[0] <= change[6])
                                    begin
                                        out_change_reg = change[7];
                                    end
                                    else
                                    begin
                                        out_change_reg = change[6];
                                    end
                                end
                                else
                                begin
                                    out_change_reg = change[5];
                                end
                            end
                            else
                            begin
                                out_change_reg = change[4];
                            end
                        end
                        else
                        begin
                            out_change_reg = change[3];
                        end
                    end
                    else
                    begin
                        out_change_reg = change[2];
                    end
                end
                else
                begin
                    out_change_reg = change[1];
                end
            end
            else
            begin
                out_change_reg = change[0];
            end
        end
        else
        begin
            out_change_reg = input_money;
        end
    end
    else
    begin
        out_change_reg = input_money;

        nest_0[0] = 8'd0;
        nest_0[1] = 8'd0;
        nest_0[2] = 8'd0;
        nest_0[3] = 8'd0;
        nest_0[4] = 8'd0;
        nest_0[5] = 8'd0;
        nest_0[6] = 8'd0;
        nest_0[7] = 8'd0;

        sort_3[0] = 8'd0;
        sort_3[1] = 8'd0;
        sort_3[2] = 8'd0;
        sort_3[3] = 8'd0;
        sort_3[4] = 8'd0;
        sort_3[5] = 8'd0;
        sort_3[6] = 8'd0;
        sort_3[7] = 8'd0;

        sort_4[0] = 8'd0;
        sort_4[1] = 8'd0;
        sort_4[2] = 8'd0;
        sort_4[3] = 8'd0;

        sort_5[0] = 8'd0;
        sort_5[1] = 8'd0;
        sort_5[2] = 8'd0;
        sort_5[3] = 8'd0;
        sort_5[4] = 8'd0;
        sort_5[5] = 8'd0;

        change[0] = 9'd0;
        change[1] = 9'd0;
        change[2] = 9'd0;
        change[3] = 9'd0;
        change[4] = 9'd0;
        change[5] = 9'd0;
        change[6] = 9'd0;
        change[7] = 9'd0;
    end
end
endmodule

module mul(a, b, out);
    input [3:0] a, b;
    output reg [7:0] out;
    always @ (*)
    begin
        out = ((a[0])?{4'd0,b[3:0]}:8'd0) + ((a[1])?{3'd0,b[3:0],1'd0}:8'd0) + ((a[2])?{2'd0,b[3:0],2'd0}:8'd0) + ((a[3])?{1'd0,b[3:0],3'd0}:8'd0);
    end
endmodule

module card_odd_mux(a, out);
    input [3:0] a;
    output reg [3:0] out;
    always @ (*)
    begin
        case(a)
        4'd0:   out = 4'd0;
        4'd1:   out = 4'd2;
        4'd2:   out = 4'd4;
        4'd3:   out = 4'd6;
        4'd4:   out = 4'd8;
        4'd5:   out = 4'd1;
        4'd6:   out = 4'd3;
        4'd7:   out = 4'd5;
        4'd8:   out = 4'd7;
        4'd9:   out = 4'd9;
        4'd10:  out = 4'd2;
        4'd11:  out = 4'd4;
        4'd12:  out = 4'd6;
        4'd13:  out = 4'd8;
        4'd14:  out = 4'd10;
        4'd15:  out = 4'd3;
        default:out = 4'd0;
        endcase
    end
endmodule