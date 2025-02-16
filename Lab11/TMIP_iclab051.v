module TMIP(
    // input signals
    clk,
    rst_n,
    in_valid, 
    in_valid2,
    
    image,
    template,
    image_size,
	action,
	
    // output signals
    out_valid,
    out_value
    );

input            clk, rst_n;
input            in_valid, in_valid2;

input      [7:0] image;
input      [7:0] template;
input      [1:0] image_size;
input      [2:0] action;

output reg       out_valid;
output reg       out_value;

//==================================================================
// parameter & integer
//==================================================================
parameter IDLE = 3'd0;
parameter IN1 = 3'd1;
parameter IN2 = 3'd2;
parameter WAIT = 3'd3;
parameter MAXPOOL = 3'd4;
parameter MEDIAN = 3'd5;
parameter CONV = 3'd6;
parameter OUT = 3'd7;

parameter FOUR = 2'd0;
parameter EIGHT = 2'd1;
parameter SIXTEEN = 2'd2;

parameter MAX_ACTION = 3'd0;
parameter AVERAGE_ACTION = 3'd1;
parameter WEIGHTED_ACTION = 3'd2;
parameter MAXPOOL_ACTION = 3'd3;
parameter NEGATIVE_ACTION = 3'd4;
parameter FLIP_ACTION = 3'd5;
parameter MEDIAN_ACTION = 3'd6;
parameter CONV_ACTION = 3'd7;

//==================================================================
// reg & wire
//==================================================================
reg [2:0] action_ff;
reg [2:0] next_action_ff;
reg [2:0] in_valid_reg;
reg [2:0] next_in_valid_reg;

reg [8:0] sram_addr_1;
reg [15:0] sram_di_1;
reg [15:0] sram_do_1;
reg sram_web_1;
reg [6:0] sram_addr_2;
reg [15:0] sram_di_2;
reg [15:0] sram_do_2;
reg sram_web_2;

reg [1:0] can_maxpool;
reg [1:0] next_can_maxpool;
reg [6:0] read_addr;
reg [6:0] out_addr;
reg [6:0] write_addr;
reg [15:0] write_data;

reg [7:0] image_reg [2:0];
reg [7:0] next_image_reg [2:0];
reg [15:0] gray_reg [2:0];
reg [15:0] next_gray_reg [2:0];

reg [2:0] state;
reg [2:0] next_state;
reg [8:0] input1_counter;
reg [8:0] next_input1_counter;
reg [1:0] input1_3_counter;
reg [1:0] next_input1_3_counter;
reg [1:0] input1_index_counter;
reg [1:0] next_input1_index_counter;
reg [3:0] template_counter;
reg [3:0] next_template_counter;
reg [2:0] input2_counter;
reg [2:0] next_input2_counter;

reg [7:0] addr_counter;
reg [7:0] next_addr_counter;
reg [3:0] maxpool_out_counter;
reg [3:0] next_maxpool_out_counter;
reg [3:0] line_counter;
reg [3:0] next_line_counter;

reg [7:0] maxpool_in [3:0];
reg [7:0] maxpool_out;
reg [7:0] maxpool_out_reg;
reg [7:0] next_maxpool_out_reg;

reg [3:0] median_out_counter;
reg [3:0] next_median_out_counter;
reg [3:0] median_out_line_counter;
reg [3:0] next_median_out_line_counter;

reg [7:0] true_median_in_0 [8:0];
reg [7:0] true_median_in_1 [8:0];

reg [7:0] median_in_0 [8:0];
reg [7:0] median_out_0;
reg [7:0] median_in_1 [8:0];
reg [7:0] median_out_1;

reg [3:0] conv_out_counter;
reg [3:0] next_conv_out_counter;
reg [3:0] conv_out_line_counter;
reg [3:0] next_conv_out_line_counter;

reg [7:0] conv_in_0 [8:0];
reg [7:0] conv_in_1 [8:0];
reg [7:0] neg_conv_in_0 [8:0];
reg [7:0] neg_conv_in_1 [8:0];

reg [4:0] conv_counter;
reg [4:0] next_conv_counter;

reg [7:0] output_counter;
reg [7:0] next_output_counter;
reg [4:0] output_bit_counter;
reg [4:0] next_output_bit_counter;
integer i;

reg [1:0] image_size_reg;
reg [1:0] next_image_size_reg;
reg [7:0] template_reg [8:0];
reg [7:0] next_template_reg [8:0];

reg [1:0] now_image_size_reg;
reg [1:0] next_now_image_size_reg;

reg [2:0] action_reg [7:0];
reg [2:0] next_action_reg [7:0];
reg [7:0] is_negative;
reg [7:0] next_is_negative;
reg [7:0] is_flip;
reg [7:0] next_is_flip;
reg [2:0] action_counter;
reg [2:0] next_action_counter;

reg [7:0] tmp_reg [37:0];
reg [7:0] next_tmp_reg [37:0];

reg [19:0] mac_reg;
reg [19:0] next_mac_reg;
reg [19:0] out_value_reg;
reg [19:0] next_out_value_reg;

reg is_read;
reg is_hold;
reg maxpool_done;
reg median_done;
//==================================================================
// SRAM
//==================================================================

SRAM512x16 SRAM512x16(  .A0(sram_addr_1[0]), .A1(sram_addr_1[1]), .A2(sram_addr_1[2]), .A3(sram_addr_1[3]), .A4(sram_addr_1[4]), .A5(sram_addr_1[5]), .A6(sram_addr_1[6]), .A7(sram_addr_1[7]), .A8(sram_addr_1[8]), 
                        .DO0(sram_do_1[0]), .DO1(sram_do_1[1]), .DO2(sram_do_1[2]), .DO3(sram_do_1[3]), .DO4(sram_do_1[4]), .DO5(sram_do_1[5]), .DO6(sram_do_1[6]), .DO7(sram_do_1[7]), 
                        .DO8(sram_do_1[8]), .DO9(sram_do_1[9]), .DO10(sram_do_1[10]), .DO11(sram_do_1[11]), .DO12(sram_do_1[12]), .DO13(sram_do_1[13]), .DO14(sram_do_1[14]), .DO15(sram_do_1[15]), 
                        .DI0(sram_di_1[0]), .DI1(sram_di_1[1]), .DI2(sram_di_1[2]), .DI3(sram_di_1[3]), .DI4(sram_di_1[4]), .DI5(sram_di_1[5]), .DI6(sram_di_1[6]), .DI7(sram_di_1[7]), 
                        .DI8(sram_di_1[8]), .DI9(sram_di_1[9]), .DI10(sram_di_1[10]), .DI11(sram_di_1[11]), .DI12(sram_di_1[12]), .DI13(sram_di_1[13]), .DI14(sram_di_1[14]), .DI15(sram_di_1[15]), 
                        .CK(clk), .WEB(sram_web_1), .OE(1'b1), .CS(1'b1));

SRAM128x16 SRAM128x16(  .A0(sram_addr_2[0]), .A1(sram_addr_2[1]), .A2(sram_addr_2[2]), .A3(sram_addr_2[3]), .A4(sram_addr_2[4]), .A5(sram_addr_2[5]), .A6(sram_addr_2[6]), 
                        .DO0(sram_do_2[0]), .DO1(sram_do_2[1]), .DO2(sram_do_2[2]), .DO3(sram_do_2[3]), .DO4(sram_do_2[4]), .DO5(sram_do_2[5]), .DO6(sram_do_2[6]), .DO7(sram_do_2[7]), 
                        .DO8(sram_do_2[8]), .DO9(sram_do_2[9]), .DO10(sram_do_2[10]), .DO11(sram_do_2[11]), .DO12(sram_do_2[12]), .DO13(sram_do_2[13]), .DO14(sram_do_2[14]), .DO15(sram_do_2[15]), 
                        .DI0(sram_di_2[0]), .DI1(sram_di_2[1]), .DI2(sram_di_2[2]), .DI3(sram_di_2[3]), .DI4(sram_di_2[4]), .DI5(sram_di_2[5]), .DI6(sram_di_2[6]), .DI7(sram_di_2[7]), 
                        .DI8(sram_di_2[8]), .DI9(sram_di_2[9]), .DI10(sram_di_2[10]), .DI11(sram_di_2[11]), .DI12(sram_di_2[12]), .DI13(sram_di_2[13]), .DI14(sram_di_2[14]), .DI15(sram_di_2[15]), 
                        .CK(clk), .WEB(sram_web_2), .OE(1'b1), .CS(1'b1));

//==================================================================
// current state
//==================================================================
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state <= IDLE;
        action_ff <= 3'd0;
        can_maxpool <= 2'd0;
        in_valid_reg <= 3'd0;
        for(i = 0; i < 3; ++i)
        begin
            image_reg[i] <= 8'd0;
        end
        for(i = 0; i < 3; ++i)
        begin
            gray_reg[i] <= 16'd0;
        end
        input1_counter <= 9'd0;
        input1_3_counter <= 2'd0;
        input1_index_counter <= 2'd0;
        template_counter <= 4'd0;
        input2_counter <= 3'd0;
        addr_counter <= 8'd0;
        maxpool_out_counter <= 4'd0;
        line_counter <= 4'd0;
        maxpool_out_reg <= 8'd0;
        median_out_counter <= 4'd0;
        median_out_line_counter <= 4'd0;
        conv_counter <= 4'd0;
        conv_out_counter <= 4'd0;
        conv_out_line_counter <= 4'd0;
        output_counter <= 8'd0;
        output_bit_counter <= 5'd0;
        image_size_reg <= 2'd0;
        for(i = 0; i < 9; ++i)
        begin
            template_reg[i] <= 8'd0;
        end
        now_image_size_reg <= 2'd0;
        for(i = 0; i < 8; ++i)
        begin
            action_reg[i] <= 3'd0;
        end
        is_negative <= 8'd0;
        is_flip <= 8'd0;
        action_counter <= 3'd0;
        for(i = 0; i < 38; ++i)
        begin
            tmp_reg[i] <= 8'd0;
        end
        mac_reg <= 20'd0;
        out_value_reg <= 20'd0;
    end
    else
    begin
        state <= next_state;
        action_ff <= next_action_ff;
        can_maxpool <= next_can_maxpool;
        in_valid_reg <= next_in_valid_reg;
        for(i = 0; i < 3; ++i)
        begin
            image_reg[i] <= next_image_reg[i];
        end
        for(i = 0; i < 3; ++i)
        begin
            gray_reg[i] <= next_gray_reg[i];
        end
        input1_counter <= next_input1_counter;
        input1_3_counter <= next_input1_3_counter;
        input1_index_counter <= next_input1_index_counter;
        template_counter <= next_template_counter;
        input2_counter <= next_input2_counter;
        addr_counter <= next_addr_counter;
        maxpool_out_counter <= next_maxpool_out_counter;
        line_counter <= next_line_counter;
        maxpool_out_reg <= next_maxpool_out_reg;
        median_out_counter <= next_median_out_counter;
        median_out_line_counter <= next_median_out_line_counter;
        conv_counter <= next_conv_counter;
        conv_out_counter <= next_conv_out_counter;
        conv_out_line_counter <= next_conv_out_line_counter;
        output_counter <= next_output_counter;
        output_bit_counter <= next_output_bit_counter;
        image_size_reg <= next_image_size_reg;
        for(i = 0; i < 9; ++i)
        begin
            template_reg[i] <= next_template_reg[i];
        end
        now_image_size_reg <= next_now_image_size_reg;
        for(i = 0; i < 8; ++i)
        begin
            action_reg[i] <= next_action_reg[i];
        end
        is_negative <= next_is_negative;
        is_flip <= next_is_flip;
        action_counter <= next_action_counter;
        for(i = 0; i < 38; ++i)
        begin
            if((state == MAXPOOL) || (state == MEDIAN) || (state == CONV) || (state == OUT)) tmp_reg[i] <= next_tmp_reg[i];
        end
        mac_reg <= next_mac_reg;
        out_value_reg <= next_out_value_reg;
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
        if(in_valid) next_state = IN1;
        else if(in_valid2) next_state = IN2;
        else next_state = IDLE;
    end
    IN1:
    begin
        if(!in_valid) next_state = IDLE;
        else next_state = IN1;
    end
    IN2:
    begin
        if(action_ff == CONV_ACTION) next_state = WAIT;
        else next_state = IN2;
    end
    WAIT:
    begin
        if(action_reg[action_counter] == MAXPOOL_ACTION) next_state = MAXPOOL;
        else if(action_reg[action_counter] == MEDIAN_ACTION) next_state = MEDIAN;
        else if(action_reg[action_counter] == CONV_ACTION) next_state = CONV;
        else next_state = IN2;
    end
    MAXPOOL:
    begin
        if(maxpool_done) next_state = WAIT;
        else next_state = MAXPOOL;
    end
    MEDIAN:
    begin
        if(median_done) next_state = WAIT;
        else next_state = MEDIAN;
    end
    CONV:
    begin
        if(conv_counter == 4'd10) next_state = OUT;
        else next_state = CONV;
    end
    OUT:
    begin
        if(((now_image_size_reg == 2'd0)&&(output_counter == 8'd15)&&(output_bit_counter == 5'd19)) ||
           ((now_image_size_reg == 2'd1)&&(output_counter == 8'd63)&&(output_bit_counter == 5'd19)) ||
           ((now_image_size_reg == 2'd2)&&(output_counter == 8'd255)&&(output_bit_counter == 5'd19))) next_state = IDLE;
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
    next_in_valid_reg = {in_valid_reg[1:0], in_valid};
end
always @ (*)
begin
    //if(input1_3_counter == 2'd2) next_input1_counter = input1_counter + 9'd1;
    //else if((input1_3_counter == 2'd2) && (in_valid_reg == 3'd0)) next_input1_counter = 9'd0;
    //else next_input1_counter = input1_counter;
    if((input1_3_counter == 2'd2) && (in_valid_reg == 3'd0)) next_input1_counter = 9'd0;
    else if(input1_3_counter == 2'd2) next_input1_counter = input1_counter + 9'd1;
    else next_input1_counter = input1_counter;
end
always @ (*)
begin
    if((state == IN1) || (in_valid_reg != 3'd0))
    begin
        if(input1_3_counter == 2'd2) next_input1_3_counter = 3'd0;
        else next_input1_3_counter = input1_3_counter + 3'd1;
    end
    else next_input1_3_counter = 3'd0;
end
always @ (*)
begin
    if(in_valid || (in_valid_reg != 3'd0))
    begin
        if(input1_index_counter == 2'd2) next_input1_index_counter = 3'd0;
        else next_input1_index_counter = input1_index_counter + 3'd1;
    end
    else next_input1_index_counter = 3'd0;
end

always @ (*)
begin
    if(in_valid)
    begin
        if(template_counter >= 4'd9) next_template_counter = template_counter;
        else next_template_counter = template_counter + 4'd1;
    end
    else next_template_counter = 4'd0;
end

always @ (*)
begin
    if(state == IN2) next_input2_counter = input2_counter + 3'd1;
    else next_input2_counter = 3'd0;
end

always @ (*)
begin
    if(state == IN2)
    begin
        if((action_ff == MAX_ACTION) || (action_ff == AVERAGE_ACTION) || (action_ff == WEIGHTED_ACTION) || ((action_ff == MAXPOOL_ACTION)&&(can_maxpool != 2'd0)) || (action_ff == MEDIAN_ACTION)) next_action_counter = action_counter + 3'd1;
        else if(action_ff == CONV_ACTION) next_action_counter = 3'd1;
        else next_action_counter = action_counter;
    end
    else
    begin
        if(((now_image_size_reg == 2'd0)&&(output_counter == 8'd15)&&(output_bit_counter == 5'd19)) ||
           ((now_image_size_reg == 2'd1)&&(output_counter == 8'd63)&&(output_bit_counter == 5'd19)) ||
           ((now_image_size_reg == 2'd2)&&(output_counter == 8'd255)&&(output_bit_counter == 5'd19))) next_action_counter = 3'd0;
        else if(maxpool_done || median_done) next_action_counter = action_counter + 3'd1;
        else next_action_counter = action_counter;
    end
end

always @ (*)
begin
    if((state == MAXPOOL) || (state == MEDIAN) || (state == CONV)) next_addr_counter = addr_counter + 7'd1;
    else next_addr_counter = 7'd0;
end

always @ (*)
begin
    if((addr_counter >= 2) && (now_image_size_reg == 2'd1))
    begin
        if(maxpool_out_counter == 4'd3) next_maxpool_out_counter = 4'd0;
        else next_maxpool_out_counter = maxpool_out_counter + 4'd1;
    end
    else if((addr_counter >= 2) && (now_image_size_reg == 2'd2))
    begin
        if(maxpool_out_counter == 4'd7) next_maxpool_out_counter = 4'd0;
        else next_maxpool_out_counter = maxpool_out_counter + 4'd1;
    end
    else next_maxpool_out_counter = 4'd0;
end

always @ (*)
begin
    if(state == MAXPOOL)
    begin
        if((((now_image_size_reg == 2'd0) && (maxpool_out_counter == 4'd1)) || ((now_image_size_reg == 2'd1) && (maxpool_out_counter == 4'd3)) || ((now_image_size_reg == 2'd2) && (maxpool_out_counter == 4'd7))))
        begin
            next_line_counter = line_counter + 4'd1;
        end
        else next_line_counter = line_counter;
    end
    else next_line_counter = 4'd0;
end

always @ (*)
begin
    if(state == MEDIAN)
    begin
        if((addr_counter >= 5) && (now_image_size_reg == 2'd0))
        begin
            if(median_out_counter == 4'd1) next_median_out_counter = 4'd0;
            else next_median_out_counter = median_out_counter + 4'd1;
        end
        else if((addr_counter >= 7) && (now_image_size_reg == 2'd1))
        begin
            if(median_out_counter == 4'd3) next_median_out_counter = 4'd0;
            else next_median_out_counter = median_out_counter + 4'd1;
        end
        else if((addr_counter >= 11) && (now_image_size_reg == 2'd2))
        begin
            if(median_out_counter == 4'd7) next_median_out_counter = 4'd0;
            else next_median_out_counter = median_out_counter + 4'd1;
        end
        else next_median_out_counter = 4'd0;
    end
    else next_median_out_counter = 4'd0;
end

always @ (*)
begin
    if(state == MEDIAN)
    begin
        if((((now_image_size_reg == 2'd0) && (median_out_counter == 4'd1)) || ((now_image_size_reg == 2'd1) && (median_out_counter == 4'd3)) || ((now_image_size_reg == 2'd2) && (median_out_counter == 4'd7))))
        begin
            next_median_out_line_counter = median_out_line_counter + 4'd1;
        end
        else next_median_out_line_counter = median_out_line_counter;
    end
    else next_median_out_line_counter = 4'd0;
end

always @ (*)
begin
    //if(state == CONV)
    //begin
    //    if(conv_counter == 4'd10) next_conv_out_counter <= 4'd1;
    //    else next_conv_out_counter = 4'd0;
    //end
    //else 
    if(state == OUT)
    begin
        if((output_bit_counter == 5'd19) && (output_counter[0] == 1'b0))
        begin
            if(now_image_size_reg == 2'd0)
            begin
                if(conv_out_counter == 4'd1) next_conv_out_counter = 4'd0;
                else next_conv_out_counter = conv_out_counter + 4'd1;
            end
            else if(now_image_size_reg == 2'd1)
            begin
                if(conv_out_counter == 4'd3) next_conv_out_counter = 4'd0;
                else next_conv_out_counter = conv_out_counter + 4'd1;
            end
            else if(now_image_size_reg == 2'd2)
            begin
                if(conv_out_counter == 4'd7) next_conv_out_counter = 4'd0;
                else next_conv_out_counter = conv_out_counter + 4'd1;
            end
            else next_conv_out_counter = 4'd0;
        end
        else next_conv_out_counter = conv_out_counter;
    end
    else next_conv_out_counter = 4'd0;
end

always @ (*)
begin
    if(state == OUT)
    begin
        if((output_bit_counter == 5'd19) && (output_counter[0] == 1'b0) && (((now_image_size_reg == 2'd0) && (conv_out_counter == 4'd1)) || ((now_image_size_reg == 2'd1) && (conv_out_counter == 4'd3)) || ((now_image_size_reg == 2'd2) && (conv_out_counter == 4'd7))))
        begin
            next_conv_out_line_counter = conv_out_line_counter + 4'd1;
        end
        else next_conv_out_line_counter = conv_out_line_counter;
    end
    else next_conv_out_line_counter = 4'd0;
end

always @ (*)
begin
    if((state == CONV) &&
        (((now_image_size_reg == 2'd0)&&(addr_counter >= 4)) ||
        ((now_image_size_reg == 2'd1)&&(addr_counter >= 6)) ||
        ((now_image_size_reg == 2'd2)&&(addr_counter >= 10)))) next_conv_counter = conv_counter + 4'd1;
    else next_conv_counter = 4'd0;
end

always @ (*)
begin
    if(state == OUT)
    begin
        if(output_bit_counter == 5'd19) next_output_counter = output_counter + 7'd1;
        else next_output_counter = output_counter;
    end
    else next_output_counter = 7'd0;
end
always @ (*)
begin
    if(output_bit_counter == 5'd19) next_output_bit_counter = 5'd0;
    else if(out_valid) next_output_bit_counter = output_bit_counter + 5'd1;
    else next_output_bit_counter = 5'd0;
end

//==================================================================
// next_action_ff
//==================================================================
always @ (*)
begin
    if(in_valid2)
    begin
        next_action_ff = action;
    end
    else
    begin
        next_action_ff = action_ff;
    end
end

//==================================================================
// next_image_size_reg
//==================================================================
always @ (*)
begin
    if(in_valid && (template_counter == 7'd0))
    begin
        next_image_size_reg = image_size;
    end
    else
    begin
        next_image_size_reg = image_size_reg;
    end
end

//==================================================================
// next_now_image_size_reg
//==================================================================
always @ (*)
begin
    if(in_valid && (template_counter == 7'd0))
    begin
        next_now_image_size_reg = image_size;
    end
    else if(((now_image_size_reg == 2'd0)&&(output_counter == 8'd15)&&(output_bit_counter == 5'd19)) ||
            ((now_image_size_reg == 2'd1)&&(output_counter == 8'd63)&&(output_bit_counter == 5'd19)) ||
            ((now_image_size_reg == 2'd2)&&(output_counter == 8'd255)&&(output_bit_counter == 5'd19)))
    begin
        next_now_image_size_reg = image_size_reg;
    end
    else if(maxpool_done && (now_image_size_reg > 2'd0))
    begin
        next_now_image_size_reg = now_image_size_reg - 2'd1;
    end
    else
    begin
        next_now_image_size_reg = now_image_size_reg;
    end
end

//==================================================================
// next_can_maxpool
//==================================================================
always @ (*)
begin
    if(in_valid && (template_counter == 7'd0))
    begin
        next_can_maxpool = image_size;
    end
    else if(((now_image_size_reg == 2'd0)&&(output_counter == 8'd15)&&(output_bit_counter == 5'd19)) ||
            ((now_image_size_reg == 2'd1)&&(output_counter == 8'd63)&&(output_bit_counter == 5'd19)) ||
            ((now_image_size_reg == 2'd2)&&(output_counter == 8'd255)&&(output_bit_counter == 5'd19)))
    begin
        next_can_maxpool = image_size_reg;
    end
    else if((action_ff == MAXPOOL_ACTION) && (can_maxpool != 2'd0))
    begin
        next_can_maxpool = can_maxpool - 2'd1;
    end
    else
    begin
        next_can_maxpool = can_maxpool;
    end
end

//==================================================================
// next_template_reg
//==================================================================
always @ (*)
begin
    for(i = 0; i < 9; ++i)
    begin
        next_template_reg[i] = template_reg[i];
    end
    if(in_valid && (template_counter < 7'd9))
    begin
        next_template_reg[template_counter] = template;
    end
end

//==================================================================
// next_action_reg
//==================================================================
always @ (*)
begin
    if(((now_image_size_reg == 2'd0)&&(output_counter == 8'd15)&&(output_bit_counter == 5'd19)) ||
       ((now_image_size_reg == 2'd1)&&(output_counter == 8'd63)&&(output_bit_counter == 5'd19)) ||
       ((now_image_size_reg == 2'd2)&&(output_counter == 8'd255)&&(output_bit_counter == 5'd19)))
    begin
        for(i = 0; i < 8; ++i)
        begin
            next_action_reg[i] = 3'd0;
        end
    end
    else
    begin
        for(i = 0; i < 8; ++i)
        begin
            next_action_reg[i] = action_reg[i];
        end
        if((action_ff == MAX_ACTION) || (action_ff == AVERAGE_ACTION) || (action_ff == WEIGHTED_ACTION) || ((action_ff == MAXPOOL_ACTION)&&(can_maxpool != 2'd0)) || (action_ff == MEDIAN_ACTION) || (action_ff == CONV_ACTION))
        begin
            next_action_reg[action_counter] = action_ff;
        end
    end
end

//==================================================================
// next_is_negative
//==================================================================
always @ (*)
begin
    if(((now_image_size_reg == 2'd0)&&(output_counter == 8'd15)&&(output_bit_counter == 5'd19)) ||
       ((now_image_size_reg == 2'd1)&&(output_counter == 8'd63)&&(output_bit_counter == 5'd19)) ||
       ((now_image_size_reg == 2'd2)&&(output_counter == 8'd255)&&(output_bit_counter == 5'd19)))
    begin
        next_is_negative = 8'd0;
    end
    else
    begin
        next_is_negative = is_negative;
        if(action_ff == NEGATIVE_ACTION)
        begin
            next_is_negative[action_counter] = !is_negative[action_counter];
        end
    end
end

//==================================================================
// next_is_flip
//==================================================================
always @ (*)
begin
    if(((now_image_size_reg == 2'd0)&&(output_counter == 8'd15)&&(output_bit_counter == 5'd19)) ||
       ((now_image_size_reg == 2'd1)&&(output_counter == 8'd63)&&(output_bit_counter == 5'd19)) ||
       ((now_image_size_reg == 2'd2)&&(output_counter == 8'd255)&&(output_bit_counter == 5'd19)))
    begin
        next_is_flip = 8'd0;
    end
    else
    begin
        next_is_flip = is_flip;
        if(action_ff == FLIP_ACTION)
        begin
            next_is_flip[action_counter] = !is_flip[action_counter];
        end
    end
end

//==================================================================
// next_image_reg
//==================================================================
always @ (*)
begin
    for(i = 0; i < 3; ++i)
    begin
        next_image_reg[i] = image_reg[i];
    end
    if(in_valid) next_image_reg[input1_index_counter] = image;
end

//==================================================================
// next_gray_reg
//==================================================================
always @ (*)
begin
    for(i = 0; i < 3; ++i)
    begin
        next_gray_reg[i] = gray_reg[i];
    end
    if(input1_3_counter == 2'd2)
    begin
        if(input1_counter[0] == 1'b0)
        begin
            next_gray_reg[0][7:0] = (image_reg[0]>image_reg[1])?((image_reg[0]>image_reg[2])?image_reg[0]:image_reg[2]):((image_reg[1]>image_reg[2])?image_reg[1]:image_reg[2]);
            next_gray_reg[1][7:0] = (image_reg[0] + image_reg[1] + image_reg[2]) / 3;
            next_gray_reg[2][7:0] = (image_reg[0] >> 2) + (image_reg[1] >> 1) + (image_reg[2] >> 2);
        end
        else
        begin
            next_gray_reg[0][15:8] = (image_reg[0]>image_reg[1])?((image_reg[0]>image_reg[2])?image_reg[0]:image_reg[2]):((image_reg[1]>image_reg[2])?image_reg[1]:image_reg[2]);
            next_gray_reg[1][15:8] = (image_reg[0] + image_reg[1] + image_reg[2]) / 3;
            next_gray_reg[2][15:8] = (image_reg[0] >> 2) + (image_reg[1] >> 1) + (image_reg[2] >> 2);
        end
    end
end
//==================================================================
// sram_addr_1
//==================================================================
always @ (*)
begin
    if((input1_counter > 0) && (input1_counter[0] == 1'b0)) sram_addr_1 = ((input1_counter >> 1) - 1) + ((input1_3_counter + 1) << 7);
    else if(action_counter == 3'd1) //read
    begin
        if(action_reg[0] == MAX_ACTION) sram_addr_1 = {2'd1, read_addr};
        else if(action_reg[0] == AVERAGE_ACTION) sram_addr_1 = {2'd2, read_addr};
        else sram_addr_1 = {2'd3, read_addr};
    end
    else if(action_counter[0] == 1'b1) //read
    begin
        sram_addr_1 = read_addr;
    end
    else //write
    begin
        sram_addr_1 = write_addr;
    end
end
//==================================================================
// sram_addr_2
//==================================================================
always @ (*)
begin
    if(action_counter[0] == 1'b1) //write
    begin
        sram_addr_2 = write_addr;
    end
    else //read
    begin
        sram_addr_2 = read_addr;
    end
end
//==================================================================
// read_addr
//==================================================================
always @ (*)
begin
    case(now_image_size_reg)
    2'd0: out_addr = (output_counter >> 1) + 4;
    2'd1: out_addr = (output_counter >> 1) + 6;
    2'd2: out_addr = (output_counter >> 1) + 10;
    default: out_addr = (output_counter >> 1) + 10;
    endcase
end

always @ (*)
begin
    if(state == OUT)
    begin
        if(is_flip[action_counter])
        begin
            case(now_image_size_reg)
            2'd0: read_addr = {out_addr[6:1], ~out_addr[0]};
            2'd1: read_addr = {out_addr[6:2], ~out_addr[1:0]};
            2'd2: read_addr = {out_addr[6:3], ~out_addr[2:0]};
            default: read_addr = out_addr;
            endcase
        end
        else read_addr = out_addr;
    end
    else
    begin
        if(is_flip[action_counter])
        begin
            case(now_image_size_reg)
            2'd0: read_addr = {addr_counter[6:1], ~addr_counter[0]};
            2'd1: read_addr = {addr_counter[6:2], ~addr_counter[1:0]};
            2'd2: read_addr = {addr_counter[6:3], ~addr_counter[2:0]};
            default: read_addr = addr_counter[6:0];
            endcase
        end
        else read_addr = addr_counter[6:0];
    end
end
//==================================================================
// write_addr
//==================================================================
always @ (*)
begin
    case(state)
    MAXPOOL:
    begin
        case(now_image_size_reg)
        2'd1: 
        begin
            write_addr = (maxpool_out_counter >> 1) + ((line_counter >> 1) << 1);
        end
        2'd2: 
        begin
            write_addr = (maxpool_out_counter >> 1) + ((line_counter >> 1) << 2);
        end
        default: write_addr = 6'd0;
        endcase
    end
    MEDIAN:
    begin
        case(now_image_size_reg)
        2'd0: write_addr = addr_counter - 8'd5;
        2'd1: write_addr = addr_counter - 8'd7;
        2'd2: write_addr = addr_counter - 8'd11;
        default: write_addr = 6'd0;
        endcase
    end
    default: write_addr = 6'd0;
    endcase
end
//==================================================================
// sram_di_1
//==================================================================
always @ (*)
begin
    case(state)
    MAXPOOL:
    begin
        if(action_counter[0] == 1'b0) //write
        begin
            sram_di_1 = write_data;
        end
        else  sram_di_1 = 16'd0;
    end
    MEDIAN:
    begin
        if(action_counter[0] == 1'b0) //write
        begin
            sram_di_1 = write_data;
        end
        else  sram_di_1 = 16'd0;
    end
    default:
    begin
        if((input1_counter > 0) && (input1_counter[0] == 1'b0)) sram_di_1 = gray_reg[input1_3_counter];
        else sram_di_1 = 16'd0;
    end
    endcase
end
//==================================================================
// sram_di_2
//==================================================================
always @ (*)
begin
    case(state)
    MAXPOOL:
    begin
        if(action_counter[0] == 1'b1) //write
        begin
            sram_di_2 = write_data;
        end
        else  sram_di_2 = 15'd0;
    end
    MEDIAN:
    begin
        if(action_counter[0] == 1'b1) //write
        begin
            sram_di_2 = write_data;
        end
        else  sram_di_2 = 15'd0;
    end
    default:
    begin
        sram_di_2 = 15'd0;
    end
    endcase
end

//==================================================================
// maxpool_out
//==================================================================
MAX_FOUR MAX_FOUR(.a(maxpool_in[0]) , .b(maxpool_in[1]), .c(maxpool_in[2]), .d(maxpool_in[3]), .z(maxpool_out));

always @ (*)
begin
    maxpool_in[0] = (is_negative[action_counter])?(~tmp_reg[37]):(tmp_reg[37]);
end
always @ (*)
begin
    maxpool_in[1] = (is_negative[action_counter])?(~tmp_reg[36]):(tmp_reg[36]);
end
always @ (*)
begin
    if(now_image_size_reg == 2'd1) maxpool_in[2] = (is_negative[action_counter])?(~tmp_reg[29]):(tmp_reg[29]);
    else maxpool_in[2] = (is_negative[action_counter])?(~tmp_reg[21]):(tmp_reg[21]);
end
always @ (*)
begin
    if(now_image_size_reg == 2'd1) maxpool_in[3] = (is_negative[action_counter])?(~tmp_reg[28]):(tmp_reg[28]);
    else maxpool_in[3] = (is_negative[action_counter])?(~tmp_reg[20]):(tmp_reg[20]);
end

always @ (*)
begin
    next_maxpool_out_reg = maxpool_out;
end

//==================================================================
// median_in
//==================================================================
MEDIAN_NINE MEDIAN_NINE_0(.a(true_median_in_0[0]), .b(true_median_in_0[1]), .c(true_median_in_0[2]), .d(true_median_in_0[3]), .e(true_median_in_0[4]), .f(true_median_in_0[5]), .g(true_median_in_0[6]), .h(true_median_in_0[7]), .i(true_median_in_0[8]), .z(median_out_0));
MEDIAN_NINE MEDIAN_NINE_1(.a(true_median_in_1[0]), .b(true_median_in_1[1]), .c(true_median_in_1[2]), .d(true_median_in_1[3]), .e(true_median_in_1[4]), .f(true_median_in_1[5]), .g(true_median_in_1[6]), .h(true_median_in_1[7]), .i(true_median_in_1[8]), .z(median_out_1));

always @ (*)
begin
    true_median_in_0[0] = (is_negative[action_counter])?(~median_in_0[0]):(median_in_0[0]);
    true_median_in_0[1] = (is_negative[action_counter])?(~median_in_0[1]):(median_in_0[1]);
    true_median_in_0[2] = (is_negative[action_counter])?(~median_in_0[2]):(median_in_0[2]);
    true_median_in_0[3] = (is_negative[action_counter])?(~median_in_0[3]):(median_in_0[3]);
    true_median_in_0[4] = (is_negative[action_counter])?(~median_in_0[4]):(median_in_0[4]);
    true_median_in_0[5] = (is_negative[action_counter])?(~median_in_0[5]):(median_in_0[5]);
    true_median_in_0[6] = (is_negative[action_counter])?(~median_in_0[6]):(median_in_0[6]);
    true_median_in_0[7] = (is_negative[action_counter])?(~median_in_0[7]):(median_in_0[7]);
    true_median_in_0[8] = (is_negative[action_counter])?(~median_in_0[8]):(median_in_0[8]);
    true_median_in_1[0] = (is_negative[action_counter])?(~median_in_1[0]):(median_in_1[0]);
    true_median_in_1[1] = (is_negative[action_counter])?(~median_in_1[1]):(median_in_1[1]);
    true_median_in_1[2] = (is_negative[action_counter])?(~median_in_1[2]):(median_in_1[2]);
    true_median_in_1[3] = (is_negative[action_counter])?(~median_in_1[3]):(median_in_1[3]);
    true_median_in_1[4] = (is_negative[action_counter])?(~median_in_1[4]):(median_in_1[4]);
    true_median_in_1[5] = (is_negative[action_counter])?(~median_in_1[5]):(median_in_1[5]);
    true_median_in_1[6] = (is_negative[action_counter])?(~median_in_1[6]):(median_in_1[6]);
    true_median_in_1[7] = (is_negative[action_counter])?(~median_in_1[7]):(median_in_1[7]);
    true_median_in_1[8] = (is_negative[action_counter])?(~median_in_1[8]):(median_in_1[8]);
end

always @ (*)
begin
    case(now_image_size_reg)
    2'd0:
    begin
        if(median_out_line_counter == 0)
        begin
            if(median_out_counter == 0)
            begin
                median_in_0[0] = tmp_reg[30];
                median_in_0[1] = tmp_reg[30];
                median_in_0[2] = tmp_reg[31];
                median_in_0[3] = tmp_reg[30];
                median_in_0[4] = tmp_reg[30];
                median_in_0[5] = tmp_reg[31];
                median_in_0[6] = tmp_reg[34];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[30];
                median_in_1[1] = tmp_reg[31];
                median_in_1[2] = tmp_reg[32];
                median_in_1[3] = tmp_reg[30];
                median_in_1[4] = tmp_reg[31];
                median_in_1[5] = tmp_reg[32];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[36];
            end
            else
            begin
                median_in_0[0] = tmp_reg[29];
                median_in_0[1] = tmp_reg[30];
                median_in_0[2] = tmp_reg[31];
                median_in_0[3] = tmp_reg[29];
                median_in_0[4] = tmp_reg[30];
                median_in_0[5] = tmp_reg[31];
                median_in_0[6] = tmp_reg[33];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[30];
                median_in_1[1] = tmp_reg[31];
                median_in_1[2] = tmp_reg[31];
                median_in_1[3] = tmp_reg[30];
                median_in_1[4] = tmp_reg[31];
                median_in_1[5] = tmp_reg[31];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[35];
            end
        end
        else if(median_out_line_counter == 3)
        begin
            if(median_out_counter == 0)
            begin
                median_in_0[0] = tmp_reg[26];
                median_in_0[1] = tmp_reg[26];
                median_in_0[2] = tmp_reg[27];
                median_in_0[3] = tmp_reg[30];
                median_in_0[4] = tmp_reg[30];
                median_in_0[5] = tmp_reg[31];
                median_in_0[6] = tmp_reg[30];
                median_in_0[7] = tmp_reg[30];
                median_in_0[8] = tmp_reg[31];
                median_in_1[0] = tmp_reg[26];
                median_in_1[1] = tmp_reg[27];
                median_in_1[2] = tmp_reg[28];
                median_in_1[3] = tmp_reg[30];
                median_in_1[4] = tmp_reg[31];
                median_in_1[5] = tmp_reg[32];
                median_in_1[6] = tmp_reg[30];
                median_in_1[7] = tmp_reg[31];
                median_in_1[8] = tmp_reg[32];
            end
            else
            begin
                median_in_0[0] = tmp_reg[25];
                median_in_0[1] = tmp_reg[26];
                median_in_0[2] = tmp_reg[27];
                median_in_0[3] = tmp_reg[29];
                median_in_0[4] = tmp_reg[30];
                median_in_0[5] = tmp_reg[31];
                median_in_0[6] = tmp_reg[29];
                median_in_0[7] = tmp_reg[30];
                median_in_0[8] = tmp_reg[31];
                median_in_1[0] = tmp_reg[26];
                median_in_1[1] = tmp_reg[27];
                median_in_1[2] = tmp_reg[27];
                median_in_1[3] = tmp_reg[30];
                median_in_1[4] = tmp_reg[31];
                median_in_1[5] = tmp_reg[31];
                median_in_1[6] = tmp_reg[30];
                median_in_1[7] = tmp_reg[31];
                median_in_1[8] = tmp_reg[31];
            end
        end
        else
        begin
            if(median_out_counter == 0)
            begin
                median_in_0[0] = tmp_reg[26];
                median_in_0[1] = tmp_reg[26];
                median_in_0[2] = tmp_reg[27];
                median_in_0[3] = tmp_reg[30];
                median_in_0[4] = tmp_reg[30];
                median_in_0[5] = tmp_reg[31];
                median_in_0[6] = tmp_reg[34];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[26];
                median_in_1[1] = tmp_reg[27];
                median_in_1[2] = tmp_reg[28];
                median_in_1[3] = tmp_reg[30];
                median_in_1[4] = tmp_reg[31];
                median_in_1[5] = tmp_reg[32];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[36];
            end
            else
            begin
                median_in_0[0] = tmp_reg[25];
                median_in_0[1] = tmp_reg[26];
                median_in_0[2] = tmp_reg[27];
                median_in_0[3] = tmp_reg[29];
                median_in_0[4] = tmp_reg[30];
                median_in_0[5] = tmp_reg[31];
                median_in_0[6] = tmp_reg[33];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[26];
                median_in_1[1] = tmp_reg[27];
                median_in_1[2] = tmp_reg[27];
                median_in_1[3] = tmp_reg[30];
                median_in_1[4] = tmp_reg[31];
                median_in_1[5] = tmp_reg[31];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[35];
            end
        end
    end
    2'd1:
    begin
        if(median_out_line_counter == 0)
        begin
            if(median_out_counter == 0)
            begin
                median_in_0[0] = tmp_reg[26];
                median_in_0[1] = tmp_reg[26];
                median_in_0[2] = tmp_reg[27];
                median_in_0[3] = tmp_reg[26];
                median_in_0[4] = tmp_reg[26];
                median_in_0[5] = tmp_reg[27];
                median_in_0[6] = tmp_reg[34];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[26];
                median_in_1[1] = tmp_reg[27];
                median_in_1[2] = tmp_reg[28];
                median_in_1[3] = tmp_reg[26];
                median_in_1[4] = tmp_reg[27];
                median_in_1[5] = tmp_reg[28];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[36];
            end
            else if(median_out_counter == 3)
            begin
                median_in_0[0] = tmp_reg[25];
                median_in_0[1] = tmp_reg[26];
                median_in_0[2] = tmp_reg[27];
                median_in_0[3] = tmp_reg[25];
                median_in_0[4] = tmp_reg[26];
                median_in_0[5] = tmp_reg[27];
                median_in_0[6] = tmp_reg[33];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[26];
                median_in_1[1] = tmp_reg[27];
                median_in_1[2] = tmp_reg[27];
                median_in_1[3] = tmp_reg[26];
                median_in_1[4] = tmp_reg[27];
                median_in_1[5] = tmp_reg[27];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[35];
            end
            else
            begin
                median_in_0[0] = tmp_reg[25];
                median_in_0[1] = tmp_reg[26];
                median_in_0[2] = tmp_reg[27];
                median_in_0[3] = tmp_reg[25];
                median_in_0[4] = tmp_reg[26];
                median_in_0[5] = tmp_reg[27];
                median_in_0[6] = tmp_reg[33];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[26];
                median_in_1[1] = tmp_reg[27];
                median_in_1[2] = tmp_reg[28];
                median_in_1[3] = tmp_reg[26];
                median_in_1[4] = tmp_reg[27];
                median_in_1[5] = tmp_reg[28];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[36];
            end
        end
        else if(median_out_line_counter == 7)
        begin
            if(median_out_counter == 0)
            begin
                median_in_0[0] = tmp_reg[18];
                median_in_0[1] = tmp_reg[18];
                median_in_0[2] = tmp_reg[19];
                median_in_0[3] = tmp_reg[26];
                median_in_0[4] = tmp_reg[26];
                median_in_0[5] = tmp_reg[27];
                median_in_0[6] = tmp_reg[26];
                median_in_0[7] = tmp_reg[26];
                median_in_0[8] = tmp_reg[27];
                median_in_1[0] = tmp_reg[18];
                median_in_1[1] = tmp_reg[19];
                median_in_1[2] = tmp_reg[20];
                median_in_1[3] = tmp_reg[26];
                median_in_1[4] = tmp_reg[27];
                median_in_1[5] = tmp_reg[28];
                median_in_1[6] = tmp_reg[26];
                median_in_1[7] = tmp_reg[27];
                median_in_1[8] = tmp_reg[28];
            end
            else if(median_out_counter == 3)
            begin
                median_in_0[0] = tmp_reg[17];
                median_in_0[1] = tmp_reg[18];
                median_in_0[2] = tmp_reg[19];
                median_in_0[3] = tmp_reg[25];
                median_in_0[4] = tmp_reg[26];
                median_in_0[5] = tmp_reg[27];
                median_in_0[6] = tmp_reg[25];
                median_in_0[7] = tmp_reg[26];
                median_in_0[8] = tmp_reg[27];
                median_in_1[0] = tmp_reg[18];
                median_in_1[1] = tmp_reg[19];
                median_in_1[2] = tmp_reg[19];
                median_in_1[3] = tmp_reg[26];
                median_in_1[4] = tmp_reg[27];
                median_in_1[5] = tmp_reg[27];
                median_in_1[6] = tmp_reg[26];
                median_in_1[7] = tmp_reg[27];
                median_in_1[8] = tmp_reg[27];
            end
            else
            begin
                median_in_0[0] = tmp_reg[17];
                median_in_0[1] = tmp_reg[18];
                median_in_0[2] = tmp_reg[19];
                median_in_0[3] = tmp_reg[25];
                median_in_0[4] = tmp_reg[26];
                median_in_0[5] = tmp_reg[27];
                median_in_0[6] = tmp_reg[25];
                median_in_0[7] = tmp_reg[26];
                median_in_0[8] = tmp_reg[27];
                median_in_1[0] = tmp_reg[18];
                median_in_1[1] = tmp_reg[19];
                median_in_1[2] = tmp_reg[20];
                median_in_1[3] = tmp_reg[26];
                median_in_1[4] = tmp_reg[27];
                median_in_1[5] = tmp_reg[28];
                median_in_1[6] = tmp_reg[26];
                median_in_1[7] = tmp_reg[27];
                median_in_1[8] = tmp_reg[28];
            end
        end
        else
        begin
            if(median_out_counter == 0)
            begin
                median_in_0[0] = tmp_reg[18];
                median_in_0[1] = tmp_reg[18];
                median_in_0[2] = tmp_reg[19];
                median_in_0[3] = tmp_reg[26];
                median_in_0[4] = tmp_reg[26];
                median_in_0[5] = tmp_reg[27];
                median_in_0[6] = tmp_reg[34];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[18];
                median_in_1[1] = tmp_reg[19];
                median_in_1[2] = tmp_reg[20];
                median_in_1[3] = tmp_reg[26];
                median_in_1[4] = tmp_reg[27];
                median_in_1[5] = tmp_reg[28];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[36];
            end
            else if(median_out_counter == 3)
            begin
                median_in_0[0] = tmp_reg[17];
                median_in_0[1] = tmp_reg[18];
                median_in_0[2] = tmp_reg[19];
                median_in_0[3] = tmp_reg[25];
                median_in_0[4] = tmp_reg[26];
                median_in_0[5] = tmp_reg[27];
                median_in_0[6] = tmp_reg[33];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[18];
                median_in_1[1] = tmp_reg[19];
                median_in_1[2] = tmp_reg[19];
                median_in_1[3] = tmp_reg[26];
                median_in_1[4] = tmp_reg[27];
                median_in_1[5] = tmp_reg[27];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[35];
            end
            else
            begin
                median_in_0[0] = tmp_reg[17];
                median_in_0[1] = tmp_reg[18];
                median_in_0[2] = tmp_reg[19];
                median_in_0[3] = tmp_reg[25];
                median_in_0[4] = tmp_reg[26];
                median_in_0[5] = tmp_reg[27];
                median_in_0[6] = tmp_reg[33];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[18];
                median_in_1[1] = tmp_reg[19];
                median_in_1[2] = tmp_reg[20];
                median_in_1[3] = tmp_reg[26];
                median_in_1[4] = tmp_reg[27];
                median_in_1[5] = tmp_reg[28];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[36];
            end
        end
    end
    2'd2:
    begin
        if(median_out_line_counter == 0)
        begin
            if(median_out_counter == 0)
            begin
                median_in_0[0] = tmp_reg[18];
                median_in_0[1] = tmp_reg[18];
                median_in_0[2] = tmp_reg[19];
                median_in_0[3] = tmp_reg[18];
                median_in_0[4] = tmp_reg[18];
                median_in_0[5] = tmp_reg[19];
                median_in_0[6] = tmp_reg[34];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[18];
                median_in_1[1] = tmp_reg[19];
                median_in_1[2] = tmp_reg[20];
                median_in_1[3] = tmp_reg[18];
                median_in_1[4] = tmp_reg[19];
                median_in_1[5] = tmp_reg[20];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[36];
            end
            else if(median_out_counter == 7)
            begin
                median_in_0[0] = tmp_reg[17];
                median_in_0[1] = tmp_reg[18];
                median_in_0[2] = tmp_reg[19];
                median_in_0[3] = tmp_reg[17];
                median_in_0[4] = tmp_reg[18];
                median_in_0[5] = tmp_reg[19];
                median_in_0[6] = tmp_reg[33];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[18];
                median_in_1[1] = tmp_reg[19];
                median_in_1[2] = tmp_reg[19];
                median_in_1[3] = tmp_reg[18];
                median_in_1[4] = tmp_reg[19];
                median_in_1[5] = tmp_reg[19];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[35];
            end
            else
            begin
                median_in_0[0] = tmp_reg[17];
                median_in_0[1] = tmp_reg[18];
                median_in_0[2] = tmp_reg[19];
                median_in_0[3] = tmp_reg[17];
                median_in_0[4] = tmp_reg[18];
                median_in_0[5] = tmp_reg[19];
                median_in_0[6] = tmp_reg[33];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[18];
                median_in_1[1] = tmp_reg[19];
                median_in_1[2] = tmp_reg[20];
                median_in_1[3] = tmp_reg[18];
                median_in_1[4] = tmp_reg[19];
                median_in_1[5] = tmp_reg[20];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[36];
            end
        end
        else if(median_out_line_counter == 15)
        begin
            if(median_out_counter == 0)
            begin
                median_in_0[0] = tmp_reg[2];
                median_in_0[1] = tmp_reg[2];
                median_in_0[2] = tmp_reg[3];
                median_in_0[3] = tmp_reg[18];
                median_in_0[4] = tmp_reg[18];
                median_in_0[5] = tmp_reg[19];
                median_in_0[6] = tmp_reg[18];
                median_in_0[7] = tmp_reg[18];
                median_in_0[8] = tmp_reg[19];
                median_in_1[0] = tmp_reg[2];
                median_in_1[1] = tmp_reg[3];
                median_in_1[2] = tmp_reg[4];
                median_in_1[3] = tmp_reg[18];
                median_in_1[4] = tmp_reg[19];
                median_in_1[5] = tmp_reg[20];
                median_in_1[6] = tmp_reg[18];
                median_in_1[7] = tmp_reg[19];
                median_in_1[8] = tmp_reg[20];
            end
            else if(median_out_counter == 7)
            begin
                median_in_0[0] = tmp_reg[1];
                median_in_0[1] = tmp_reg[2];
                median_in_0[2] = tmp_reg[3];
                median_in_0[3] = tmp_reg[17];
                median_in_0[4] = tmp_reg[18];
                median_in_0[5] = tmp_reg[19];
                median_in_0[6] = tmp_reg[17];
                median_in_0[7] = tmp_reg[18];
                median_in_0[8] = tmp_reg[19];
                median_in_1[0] = tmp_reg[2];
                median_in_1[1] = tmp_reg[3];
                median_in_1[2] = tmp_reg[3];
                median_in_1[3] = tmp_reg[18];
                median_in_1[4] = tmp_reg[19];
                median_in_1[5] = tmp_reg[19];
                median_in_1[6] = tmp_reg[18];
                median_in_1[7] = tmp_reg[19];
                median_in_1[8] = tmp_reg[19];
            end
            else
            begin
                median_in_0[0] = tmp_reg[1];
                median_in_0[1] = tmp_reg[2];
                median_in_0[2] = tmp_reg[3];
                median_in_0[3] = tmp_reg[17];
                median_in_0[4] = tmp_reg[18];
                median_in_0[5] = tmp_reg[19];
                median_in_0[6] = tmp_reg[17];
                median_in_0[7] = tmp_reg[18];
                median_in_0[8] = tmp_reg[19];
                median_in_1[0] = tmp_reg[2];
                median_in_1[1] = tmp_reg[3];
                median_in_1[2] = tmp_reg[4];
                median_in_1[3] = tmp_reg[18];
                median_in_1[4] = tmp_reg[19];
                median_in_1[5] = tmp_reg[20];
                median_in_1[6] = tmp_reg[18];
                median_in_1[7] = tmp_reg[19];
                median_in_1[8] = tmp_reg[20];
            end
        end
        else
        begin
            if(median_out_counter == 0)
            begin
                median_in_0[0] = tmp_reg[2];
                median_in_0[1] = tmp_reg[2];
                median_in_0[2] = tmp_reg[3];
                median_in_0[3] = tmp_reg[18];
                median_in_0[4] = tmp_reg[18];
                median_in_0[5] = tmp_reg[19];
                median_in_0[6] = tmp_reg[34];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[2];
                median_in_1[1] = tmp_reg[3];
                median_in_1[2] = tmp_reg[4];
                median_in_1[3] = tmp_reg[18];
                median_in_1[4] = tmp_reg[19];
                median_in_1[5] = tmp_reg[20];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[36];
            end
            else if(median_out_counter == 7)
            begin
                median_in_0[0] = tmp_reg[1];
                median_in_0[1] = tmp_reg[2];
                median_in_0[2] = tmp_reg[3];
                median_in_0[3] = tmp_reg[17];
                median_in_0[4] = tmp_reg[18];
                median_in_0[5] = tmp_reg[19];
                median_in_0[6] = tmp_reg[33];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[2];
                median_in_1[1] = tmp_reg[3];
                median_in_1[2] = tmp_reg[3];
                median_in_1[3] = tmp_reg[18];
                median_in_1[4] = tmp_reg[19];
                median_in_1[5] = tmp_reg[19];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[35];
            end
            else
            begin
                median_in_0[0] = tmp_reg[1];
                median_in_0[1] = tmp_reg[2];
                median_in_0[2] = tmp_reg[3];
                median_in_0[3] = tmp_reg[17];
                median_in_0[4] = tmp_reg[18];
                median_in_0[5] = tmp_reg[19];
                median_in_0[6] = tmp_reg[33];
                median_in_0[7] = tmp_reg[34];
                median_in_0[8] = tmp_reg[35];
                median_in_1[0] = tmp_reg[2];
                median_in_1[1] = tmp_reg[3];
                median_in_1[2] = tmp_reg[4];
                median_in_1[3] = tmp_reg[18];
                median_in_1[4] = tmp_reg[19];
                median_in_1[5] = tmp_reg[20];
                median_in_1[6] = tmp_reg[34];
                median_in_1[7] = tmp_reg[35];
                median_in_1[8] = tmp_reg[36];
            end
        end
    end
    default:
    begin
        median_in_0[0] = 8'd0;
        median_in_0[1] = 8'd0;
        median_in_0[2] = 8'd0;
        median_in_0[3] = 8'd0;
        median_in_0[4] = 8'd0;
        median_in_0[5] = 8'd0;
        median_in_0[6] = 8'd0;
        median_in_0[7] = 8'd0;
        median_in_0[8] = 8'd0;
        median_in_1[0] = 8'd0;
        median_in_1[1] = 8'd0;
        median_in_1[2] = 8'd0;
        median_in_1[3] = 8'd0;
        median_in_1[4] = 8'd0;
        median_in_1[5] = 8'd0;
        median_in_1[6] = 8'd0;
        median_in_1[7] = 8'd0;
        median_in_1[8] = 8'd0;
    end
    endcase
end
//==================================================================
// conv_in
//==================================================================
always @ (*)
begin
    case(now_image_size_reg)
    2'd0:
    begin
        if(conv_out_line_counter == 0)
        begin
            if(conv_out_counter == 0)
            begin
                conv_in_0[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[3] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[4] = tmp_reg[30];
                conv_in_0[5] = tmp_reg[31];
                conv_in_0[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[3] = tmp_reg[30];
                conv_in_1[4] = tmp_reg[31];
                conv_in_1[5] = tmp_reg[32];
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = tmp_reg[36];
            end
            else
            begin
                conv_in_0[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[3] = tmp_reg[29];
                conv_in_0[4] = tmp_reg[30];
                conv_in_0[5] = tmp_reg[31];
                conv_in_0[6] = tmp_reg[33];
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[3] = tmp_reg[30];
                conv_in_1[4] = tmp_reg[31];
                conv_in_1[5] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = (is_negative[action_counter])?8'hff:8'd0;
            end
        end
        else if(conv_out_line_counter == 3)
        begin
            if(conv_out_counter == 0)
            begin
                conv_in_0[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[1] = tmp_reg[26];
                conv_in_0[2] = tmp_reg[27];
                conv_in_0[3] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[4] = tmp_reg[30];
                conv_in_0[5] = tmp_reg[31];
                conv_in_0[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[8] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[0] = tmp_reg[26];
                conv_in_1[1] = tmp_reg[27];
                conv_in_1[2] = tmp_reg[28];
                conv_in_1[3] = tmp_reg[30];
                conv_in_1[4] = tmp_reg[31];
                conv_in_1[5] = tmp_reg[32];
                conv_in_1[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[8] = (is_negative[action_counter])?8'hff:8'd0;
            end
            else
            begin
                conv_in_0[0] = tmp_reg[25];
                conv_in_0[1] = tmp_reg[26];
                conv_in_0[2] = tmp_reg[27];
                conv_in_0[3] = tmp_reg[29];
                conv_in_0[4] = tmp_reg[30];
                conv_in_0[5] = tmp_reg[31];
                conv_in_0[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[8] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[0] = tmp_reg[26];
                conv_in_1[1] = tmp_reg[27];
                conv_in_1[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[3] = tmp_reg[30];
                conv_in_1[4] = tmp_reg[31];
                conv_in_1[5] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[8] = (is_negative[action_counter])?8'hff:8'd0;
            end
        end
        else
        begin
            if(conv_out_counter == 0)
            begin
                conv_in_0[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[1] = tmp_reg[26];
                conv_in_0[2] = tmp_reg[27];
                conv_in_0[3] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[4] = tmp_reg[30];
                conv_in_0[5] = tmp_reg[31];
                conv_in_0[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = tmp_reg[26];
                conv_in_1[1] = tmp_reg[27];
                conv_in_1[2] = tmp_reg[28];
                conv_in_1[3] = tmp_reg[30];
                conv_in_1[4] = tmp_reg[31];
                conv_in_1[5] = tmp_reg[32];
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = tmp_reg[36];
            end
            else
            begin
                conv_in_0[0] = tmp_reg[25];
                conv_in_0[1] = tmp_reg[26];
                conv_in_0[2] = tmp_reg[27];
                conv_in_0[3] = tmp_reg[29];
                conv_in_0[4] = tmp_reg[30];
                conv_in_0[5] = tmp_reg[31];
                conv_in_0[6] = tmp_reg[33];
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = tmp_reg[26];
                conv_in_1[1] = tmp_reg[27];
                conv_in_1[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[3] = tmp_reg[30];
                conv_in_1[4] = tmp_reg[31];
                conv_in_1[5] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = (is_negative[action_counter])?8'hff:8'd0;
            end
        end
    end
    2'd1:
    begin
        if(conv_out_line_counter == 0)
        begin
            if(conv_out_counter == 0)
            begin
                conv_in_0[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[3] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[4] = tmp_reg[26];
                conv_in_0[5] = tmp_reg[27];
                conv_in_0[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[3] = tmp_reg[26];
                conv_in_1[4] = tmp_reg[27];
                conv_in_1[5] = tmp_reg[28];
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = tmp_reg[36];
            end
            else if(conv_out_counter == 3)
            begin
                conv_in_0[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[3] = tmp_reg[25];
                conv_in_0[4] = tmp_reg[26];
                conv_in_0[5] = tmp_reg[27];
                conv_in_0[6] = tmp_reg[33];
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[3] = tmp_reg[26];
                conv_in_1[4] = tmp_reg[27];
                conv_in_1[5] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = (is_negative[action_counter])?8'hff:8'd0;
            end
            else
            begin
                conv_in_0[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[3] = tmp_reg[25];
                conv_in_0[4] = tmp_reg[26];
                conv_in_0[5] = tmp_reg[27];
                conv_in_0[6] = tmp_reg[33];
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[3] = tmp_reg[26];
                conv_in_1[4] = tmp_reg[27];
                conv_in_1[5] = tmp_reg[28];
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = tmp_reg[36];
            end
        end
        else if(conv_out_line_counter == 7)
        begin
            if(conv_out_counter == 0)
            begin
                conv_in_0[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[1] = tmp_reg[18];
                conv_in_0[2] = tmp_reg[19];
                conv_in_0[3] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[4] = tmp_reg[26];
                conv_in_0[5] = tmp_reg[27];
                conv_in_0[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[8] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[0] = tmp_reg[18];
                conv_in_1[1] = tmp_reg[19];
                conv_in_1[2] = tmp_reg[20];
                conv_in_1[3] = tmp_reg[26];
                conv_in_1[4] = tmp_reg[27];
                conv_in_1[5] = tmp_reg[28];
                conv_in_1[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[8] = (is_negative[action_counter])?8'hff:8'd0;
            end
            else if(conv_out_counter == 3)
            begin
                conv_in_0[0] = tmp_reg[17];
                conv_in_0[1] = tmp_reg[18];
                conv_in_0[2] = tmp_reg[19];
                conv_in_0[3] = tmp_reg[25];
                conv_in_0[4] = tmp_reg[26];
                conv_in_0[5] = tmp_reg[27];
                conv_in_0[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[8] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[0] = tmp_reg[18];
                conv_in_1[1] = tmp_reg[19];
                conv_in_1[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[3] = tmp_reg[26];
                conv_in_1[4] = tmp_reg[27];
                conv_in_1[5] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[8] = (is_negative[action_counter])?8'hff:8'd0;
            end
            else
            begin
                conv_in_0[0] = tmp_reg[17];
                conv_in_0[1] = tmp_reg[18];
                conv_in_0[2] = tmp_reg[19];
                conv_in_0[3] = tmp_reg[25];
                conv_in_0[4] = tmp_reg[26];
                conv_in_0[5] = tmp_reg[27];
                conv_in_0[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[8] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[0] = tmp_reg[18];
                conv_in_1[1] = tmp_reg[19];
                conv_in_1[2] = tmp_reg[20];
                conv_in_1[3] = tmp_reg[26];
                conv_in_1[4] = tmp_reg[27];
                conv_in_1[5] = tmp_reg[28];
                conv_in_1[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[8] = (is_negative[action_counter])?8'hff:8'd0;
            end
        end
        else
        begin
            if(conv_out_counter == 0)
            begin
                conv_in_0[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[1] = tmp_reg[18];
                conv_in_0[2] = tmp_reg[19];
                conv_in_0[3] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[4] = tmp_reg[26];
                conv_in_0[5] = tmp_reg[27];
                conv_in_0[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = tmp_reg[18];
                conv_in_1[1] = tmp_reg[19];
                conv_in_1[2] = tmp_reg[20];
                conv_in_1[3] = tmp_reg[26];
                conv_in_1[4] = tmp_reg[27];
                conv_in_1[5] = tmp_reg[28];
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = tmp_reg[36];
            end
            else if(conv_out_counter == 3)
            begin
                conv_in_0[0] = tmp_reg[17];
                conv_in_0[1] = tmp_reg[18];
                conv_in_0[2] = tmp_reg[19];
                conv_in_0[3] = tmp_reg[25];
                conv_in_0[4] = tmp_reg[26];
                conv_in_0[5] = tmp_reg[27];
                conv_in_0[6] = tmp_reg[33];
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = tmp_reg[18];
                conv_in_1[1] = tmp_reg[19];
                conv_in_1[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[3] = tmp_reg[26];
                conv_in_1[4] = tmp_reg[27];
                conv_in_1[5] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = (is_negative[action_counter])?8'hff:8'd0;
            end
            else
            begin
                conv_in_0[0] = tmp_reg[17];
                conv_in_0[1] = tmp_reg[18];
                conv_in_0[2] = tmp_reg[19];
                conv_in_0[3] = tmp_reg[25];
                conv_in_0[4] = tmp_reg[26];
                conv_in_0[5] = tmp_reg[27];
                conv_in_0[6] = tmp_reg[33];
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = tmp_reg[18];
                conv_in_1[1] = tmp_reg[19];
                conv_in_1[2] = tmp_reg[20];
                conv_in_1[3] = tmp_reg[26];
                conv_in_1[4] = tmp_reg[27];
                conv_in_1[5] = tmp_reg[28];
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = tmp_reg[36];
            end
        end
    end
    2'd2:
    begin
        if(conv_out_line_counter == 0)
        begin
            if(conv_out_counter == 0)
            begin
                conv_in_0[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[3] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[4] = tmp_reg[18];
                conv_in_0[5] = tmp_reg[19];
                conv_in_0[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[3] = tmp_reg[18];
                conv_in_1[4] = tmp_reg[19];
                conv_in_1[5] = tmp_reg[20];
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = tmp_reg[36];
            end
            else if(conv_out_counter == 7)
            begin
                conv_in_0[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[3] = tmp_reg[17];
                conv_in_0[4] = tmp_reg[18];
                conv_in_0[5] = tmp_reg[19];
                conv_in_0[6] = tmp_reg[33];
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[3] = tmp_reg[18];
                conv_in_1[4] = tmp_reg[19];
                conv_in_1[5] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = (is_negative[action_counter])?8'hff:8'd0;
            end
            else
            begin
                conv_in_0[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[3] = tmp_reg[17];
                conv_in_0[4] = tmp_reg[18];
                conv_in_0[5] = tmp_reg[19];
                conv_in_0[6] = tmp_reg[33];
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[1] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[3] = tmp_reg[18];
                conv_in_1[4] = tmp_reg[19];
                conv_in_1[5] = tmp_reg[20];
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = tmp_reg[36];
            end
        end
        else if(conv_out_line_counter == 15)
        begin
            if(conv_out_counter == 0)
            begin
                conv_in_0[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[1] = tmp_reg[2];
                conv_in_0[2] = tmp_reg[3];
                conv_in_0[3] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[4] = tmp_reg[18];
                conv_in_0[5] = tmp_reg[19];
                conv_in_0[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[8] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[0] = tmp_reg[2];
                conv_in_1[1] = tmp_reg[3];
                conv_in_1[2] = tmp_reg[4];
                conv_in_1[3] = tmp_reg[18];
                conv_in_1[4] = tmp_reg[19];
                conv_in_1[5] = tmp_reg[20];
                conv_in_1[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[8] = (is_negative[action_counter])?8'hff:8'd0;
            end
            else if(conv_out_counter == 7)
            begin
                conv_in_0[0] = tmp_reg[1];
                conv_in_0[1] = tmp_reg[2];
                conv_in_0[2] = tmp_reg[3];
                conv_in_0[3] = tmp_reg[17];
                conv_in_0[4] = tmp_reg[18];
                conv_in_0[5] = tmp_reg[19];
                conv_in_0[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[8] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[0] = tmp_reg[2];
                conv_in_1[1] = tmp_reg[3];
                conv_in_1[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[3] = tmp_reg[18];
                conv_in_1[4] = tmp_reg[19];
                conv_in_1[5] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[8] = (is_negative[action_counter])?8'hff:8'd0;
            end
            else
            begin
                conv_in_0[0] = tmp_reg[1];
                conv_in_0[1] = tmp_reg[2];
                conv_in_0[2] = tmp_reg[3];
                conv_in_0[3] = tmp_reg[17];
                conv_in_0[4] = tmp_reg[18];
                conv_in_0[5] = tmp_reg[19];
                conv_in_0[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[8] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[0] = tmp_reg[2];
                conv_in_1[1] = tmp_reg[3];
                conv_in_1[2] = tmp_reg[4];
                conv_in_1[3] = tmp_reg[18];
                conv_in_1[4] = tmp_reg[19];
                conv_in_1[5] = tmp_reg[20];
                conv_in_1[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[7] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[8] = (is_negative[action_counter])?8'hff:8'd0;
            end
        end
        else
        begin
            if(conv_out_counter == 0)
            begin
                conv_in_0[0] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[1] = tmp_reg[2];
                conv_in_0[2] = tmp_reg[3];
                conv_in_0[3] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[4] = tmp_reg[18];
                conv_in_0[5] = tmp_reg[19];
                conv_in_0[6] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = tmp_reg[2];
                conv_in_1[1] = tmp_reg[3];
                conv_in_1[2] = tmp_reg[4];
                conv_in_1[3] = tmp_reg[18];
                conv_in_1[4] = tmp_reg[19];
                conv_in_1[5] = tmp_reg[20];
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = tmp_reg[36];
            end
            else if(conv_out_counter == 7)
            begin
                conv_in_0[0] = tmp_reg[1];
                conv_in_0[1] = tmp_reg[2];
                conv_in_0[2] = tmp_reg[3];
                conv_in_0[3] = tmp_reg[17];
                conv_in_0[4] = tmp_reg[18];
                conv_in_0[5] = tmp_reg[19];
                conv_in_0[6] = tmp_reg[33];
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = tmp_reg[2];
                conv_in_1[1] = tmp_reg[3];
                conv_in_1[2] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[3] = tmp_reg[18];
                conv_in_1[4] = tmp_reg[19];
                conv_in_1[5] = (is_negative[action_counter])?8'hff:8'd0;
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = (is_negative[action_counter])?8'hff:8'd0;
            end
            else
            begin
                conv_in_0[0] = tmp_reg[1];
                conv_in_0[1] = tmp_reg[2];
                conv_in_0[2] = tmp_reg[3];
                conv_in_0[3] = tmp_reg[17];
                conv_in_0[4] = tmp_reg[18];
                conv_in_0[5] = tmp_reg[19];
                conv_in_0[6] = tmp_reg[33];
                conv_in_0[7] = tmp_reg[34];
                conv_in_0[8] = tmp_reg[35];
                conv_in_1[0] = tmp_reg[2];
                conv_in_1[1] = tmp_reg[3];
                conv_in_1[2] = tmp_reg[4];
                conv_in_1[3] = tmp_reg[18];
                conv_in_1[4] = tmp_reg[19];
                conv_in_1[5] = tmp_reg[20];
                conv_in_1[6] = tmp_reg[34];
                conv_in_1[7] = tmp_reg[35];
                conv_in_1[8] = tmp_reg[36];
            end
        end
    end
    default:
    begin
        conv_in_0[0] = 8'd0;
        conv_in_0[1] = 8'd0;
        conv_in_0[2] = 8'd0;
        conv_in_0[3] = 8'd0;
        conv_in_0[4] = 8'd0;
        conv_in_0[5] = 8'd0;
        conv_in_0[6] = 8'd0;
        conv_in_0[7] = 8'd0;
        conv_in_0[8] = 8'd0;
        conv_in_1[0] = 8'd0;
        conv_in_1[1] = 8'd0;
        conv_in_1[2] = 8'd0;
        conv_in_1[3] = 8'd0;
        conv_in_1[4] = 8'd0;
        conv_in_1[5] = 8'd0;
        conv_in_1[6] = 8'd0;
        conv_in_1[7] = 8'd0;
        conv_in_1[8] = 8'd0;
    end
    endcase
end

//==================================================================
// write_data
//==================================================================
always @ (*)
begin
    case(state)
    MAXPOOL:
    begin
        write_data = {maxpool_out, maxpool_out_reg};
    end
    MEDIAN:
    begin
        write_data = {median_out_1, median_out_0};
    end
    default:
    begin
        write_data = 15'd0;
    end
    endcase
end

//==================================================================
// sram_web_1
//==================================================================
always @ (*)
begin
    case(state)
    MAXPOOL:
    begin
        if(action_counter[0] == 1'b0)
        begin
            case(now_image_size_reg)
            2'd1:
            begin
                if((line_counter[0] == 1'b1) && (maxpool_out_counter[0] == 1'b1)) sram_web_1 = 1'b0;
                else sram_web_1 = 1'b1;
            end
            2'd2:
            begin
                if((line_counter[0] == 1'b1) && (maxpool_out_counter[0] == 1'b1)) sram_web_1 = 1'b0;
                else sram_web_1 = 1'b1;
            end
            default: sram_web_1 = 1'b1;
            endcase
        end
        else sram_web_1 = 1'b1;
    end
    MEDIAN:
    begin
        if(action_counter[0] == 1'b0)
        begin
            case(now_image_size_reg)
            2'd0:
            begin
                if((addr_counter >= 5) && (addr_counter <= 12)) sram_web_1 = 1'b0;
                else sram_web_1 = 1'b1;
            end
            2'd1:
            begin
                if((addr_counter >= 7) && (addr_counter <= 38)) sram_web_1 = 1'b0;
                else sram_web_1 = 1'b1;
            end
            2'd2:
            begin
                if((addr_counter >= 11) && (addr_counter <= 138)) sram_web_1 = 1'b0;
                else sram_web_1 = 1'b1;
            end
            default: sram_web_1 = 1'b1;
            endcase
        end
        else sram_web_1 = 1'b1;
    end
    default:
    begin
        if((input1_counter > 0) && (input1_counter[0] == 1'b0)) sram_web_1 = 1'b0;
        else sram_web_1 = 1'b1;
    end
    endcase
end

//==================================================================
// sram_web_2
//==================================================================
always @ (*)
begin
    case(state)
    MAXPOOL:
    begin
        if(action_counter[0] == 1'b1)
        begin
            case(now_image_size_reg)
            2'd1:
            begin
                if((line_counter[0] == 1'b1) && (maxpool_out_counter[0] == 1'b1)) sram_web_2 = 1'b0;
                else sram_web_2 = 1'b1;
            end
            2'd2:
            begin
                if((line_counter[0] == 1'b1) && (maxpool_out_counter[0] == 1'b1)) sram_web_2 = 1'b0;
                else sram_web_2 = 1'b1;
            end
            default: sram_web_2 = 1'b1;
            endcase
        end
        else sram_web_2 = 1'b1;
    end
    MEDIAN:
    begin
        if(action_counter[0] == 1'b1)
        begin
            case(now_image_size_reg)
            2'd0:
            begin
                if((addr_counter >= 5) && (addr_counter <= 12)) sram_web_2 = 1'b0;
                else sram_web_2 = 1'b1;
            end
            2'd1:
            begin
                if((addr_counter >= 7) && (addr_counter <= 38)) sram_web_2 = 1'b0;
                else sram_web_2 = 1'b1;
            end
            2'd2:
            begin
                if((addr_counter >= 11) && (addr_counter <= 138)) sram_web_2 = 1'b0;
                else sram_web_2 = 1'b1;
            end
            default: sram_web_2 = 1'b1;
            endcase
        end
        else sram_web_2 = 1'b1;
    end
    default:
    begin
        sram_web_2 = 1'b1;
    end
    endcase
end

//==================================================================
// next_tmp_reg
//==================================================================
always @ (*)
begin
    if(is_read)
    begin
        for(i = 0; i < 36; ++i)
        begin
            next_tmp_reg[i] = tmp_reg[i+2];
        end
        if(action_counter[0] == 1'b1)
        begin
            next_tmp_reg[36] = (is_flip[action_counter])?(sram_do_1[15:8]):(sram_do_1[7:0]);
            next_tmp_reg[37] = (is_flip[action_counter])?(sram_do_1[7:0]):(sram_do_1[15:8]);
        end
        else
        begin
            next_tmp_reg[36] = (is_flip[action_counter])?(sram_do_2[15:8]):(sram_do_2[7:0]);
            next_tmp_reg[37] = (is_flip[action_counter])?(sram_do_2[7:0]):(sram_do_2[15:8]);
        end
    end
    else if(is_hold)
    begin
        for(i = 0; i < 38; ++i)
        begin
            next_tmp_reg[i] = tmp_reg[i];
        end
    end
    else
    begin
        for(i = 0; i < 36; ++i)
        begin
            next_tmp_reg[i] = tmp_reg[i+2];
        end
        next_tmp_reg[36] = 8'd0;
        next_tmp_reg[37] = 8'd0;
    end
    /*if(is_read)
    begin
        for(i = 0; i < 36; ++i)
        begin
            next_tmp_reg[i] = tmp_reg[i+2];
        end
        if(action_counter[0] == 1'b1)
        begin
            next_tmp_reg[36] = (is_flip[action_counter])?((is_negative[action_counter])?(~sram_do_1[15:8]):(sram_do_1[15:8])):((is_negative[action_counter])?(~sram_do_1[7:0]):(sram_do_1[7:0]));
            next_tmp_reg[37] = (is_flip[action_counter])?((is_negative[action_counter])?(~sram_do_1[7:0]):(sram_do_1[7:0])):((is_negative[action_counter])?(~sram_do_1[15:8]):(sram_do_1[15:8]));
        end
        else
        begin
            next_tmp_reg[36] = (is_flip[action_counter])?((is_negative[action_counter])?(~sram_do_2[15:8]):(sram_do_2[15:8])):((is_negative[action_counter])?(~sram_do_2[7:0]):(sram_do_2[7:0]));
            next_tmp_reg[37] = (is_flip[action_counter])?((is_negative[action_counter])?(~sram_do_2[7:0]):(sram_do_2[7:0])):((is_negative[action_counter])?(~sram_do_2[15:8]):(sram_do_2[15:8]));
        end
    end
    else if(is_hold)
    begin
        for(i = 0; i < 38; ++i)
        begin
            next_tmp_reg[i] = tmp_reg[i];
        end
    end
    else
    begin
        for(i = 0; i < 36; ++i)
        begin
            next_tmp_reg[i] = tmp_reg[i+2];
        end
        next_tmp_reg[36] = 8'd0;
        next_tmp_reg[37] = 8'd0;
    end*/
end

//==================================================================
// is_read
//==================================================================
always @ (*)
begin
    if(state == CONV)
    begin
        if((addr_counter >= 8'd1) && (conv_counter == 4'd0)) is_read = 1'b1;
        else is_read = 1'b0;
    end
    else if(state == OUT)
    begin
        if((output_bit_counter == 5'd19) && (output_counter[0] == 1'b0)) is_read = 1'b1;
        else is_read = 1'b0;
    end
    else
    begin
        case(now_image_size_reg)
        2'd0:
        begin
            if((addr_counter >= 8'd1) && (addr_counter <= 8'd8)) is_read = 1'b1;
            else is_read = 1'b0;
        end
        2'd1:
        begin
            if((addr_counter >= 8'd1) && (addr_counter <= 8'd32)) is_read = 1'b1;
            else is_read = 1'b0;
        end
        2'd2:
        begin
            if((addr_counter >= 8'd1) && (addr_counter <= 8'd128)) is_read = 1'b1;
            else is_read = 1'b0;
        end
        default: is_read = 1'b0;
        endcase
    end
end
//==================================================================
// is_hold
//==================================================================
always @ (*)
begin
    if((state == CONV) || (state == OUT)) is_hold = 1'b1;
    else is_hold = 1'b0;
end
//==================================================================
// maxpool_done
//==================================================================
always @ (*)
begin
    if(state == MAXPOOL)
    begin
        case(now_image_size_reg)
        2'd0:
        begin
            maxpool_done = 1'b1;
        end
        2'd1:
        begin
            if(addr_counter == 8'd34) maxpool_done = 1'b1;
            else maxpool_done = 1'b0;
        end
        2'd2:
        begin
            if(addr_counter == 8'd130) maxpool_done = 1'b1;
            else maxpool_done = 1'b0;
        end
        default: maxpool_done = 1'b0;
        endcase
    end
    else maxpool_done = 1'b0;
end
//==================================================================
// median_done
//==================================================================
always @ (*)
begin
    if(state == MEDIAN)
    begin
        case(now_image_size_reg)
        2'd0:
        begin
            if(addr_counter == 8'd14) median_done = 1'b1;
            else median_done = 1'b0;
        end
        2'd1:
        begin
            if(addr_counter == 8'd38) median_done = 1'b1;
            else median_done = 1'b0;
        end
        2'd2:
        begin
            if(addr_counter == 8'd140) median_done = 1'b1;
            else median_done = 1'b0;
        end
        default: median_done = 1'b0;
        endcase
    end
    else median_done = 1'b0;
end
//==================================================================
// out
//==================================================================
always @ (*)
begin
    neg_conv_in_0[0] = ~(conv_in_0[0]);
    neg_conv_in_0[1] = ~(conv_in_0[1]);
    neg_conv_in_0[2] = ~(conv_in_0[2]);
    neg_conv_in_0[3] = ~(conv_in_0[3]);
    neg_conv_in_0[4] = ~(conv_in_0[4]);
    neg_conv_in_0[5] = ~(conv_in_0[5]);
    neg_conv_in_0[6] = ~(conv_in_0[6]);
    neg_conv_in_0[7] = ~(conv_in_0[7]);
    neg_conv_in_0[8] = ~(conv_in_0[8]);
    neg_conv_in_1[0] = ~(conv_in_1[0]);
    neg_conv_in_1[1] = ~(conv_in_1[1]);
    neg_conv_in_1[2] = ~(conv_in_1[2]);
    neg_conv_in_1[3] = ~(conv_in_1[3]);
    neg_conv_in_1[4] = ~(conv_in_1[4]);
    neg_conv_in_1[5] = ~(conv_in_1[5]);
    neg_conv_in_1[6] = ~(conv_in_1[6]);
    neg_conv_in_1[7] = ~(conv_in_1[7]);
    neg_conv_in_1[8] = ~(conv_in_1[8]);
end

always @ (*)
begin
    if(state == CONV)
    begin
        if((conv_counter >= 4'd1) && (conv_counter <= 4'd9))
        begin
            if(is_negative[action_counter])
            begin
                next_mac_reg = mac_reg + template_reg[conv_counter-1] * neg_conv_in_0[conv_counter-1];
            end
            else
            begin
                next_mac_reg = mac_reg + template_reg[conv_counter-1] * conv_in_0[conv_counter-1];
            end
        end
        else next_mac_reg = 15'b0;
    end
    else if(state == OUT)
    begin
        if(output_bit_counter == 5'd19) next_mac_reg = 15'b0;
        else if((output_bit_counter <=8) && (output_counter[0] == 1'b1))
        begin
            if(is_negative[action_counter]) next_mac_reg = mac_reg + template_reg[output_bit_counter] * neg_conv_in_0[output_bit_counter];
            else next_mac_reg = mac_reg + template_reg[output_bit_counter] * conv_in_0[output_bit_counter];
        end
        else if((output_bit_counter <=8) && (output_counter[0] == 1'b0))
        begin
            if(is_negative[action_counter]) next_mac_reg = mac_reg + template_reg[output_bit_counter] * neg_conv_in_1[output_bit_counter];
            else next_mac_reg = mac_reg + template_reg[output_bit_counter] * conv_in_1[output_bit_counter];
        end
        else next_mac_reg = mac_reg;
    end
    else next_mac_reg = 15'b0;
end

always @ (*)
begin
    if(state == CONV)
    begin
        if(conv_counter == 4'd10) next_out_value_reg = mac_reg;
        else next_out_value_reg = out_value_reg;
    end
    else if(state == OUT)
    begin
        if(output_bit_counter == 5'd19) next_out_value_reg = mac_reg;
        else next_out_value_reg = out_value_reg;
    end
    else next_out_value_reg = 15'b0;
end

always @ (*)
begin
    if(state == OUT) out_valid = 1'b1;
    else out_valid = 1'b0;
end

always @ (*)
begin
    if(state == OUT) out_value = out_value_reg[19 - output_bit_counter];
    else out_value = 1'b0;
end
endmodule

module MEDIAN_NINE(a, b, c, d, e, f, g, h, i, z);
    input [7:0] a, b, c, d, e, f, g, h, i;
    output reg [7:0] z;
    reg [7:0] net [41:0];
    COMPARATOR COMPARATOR_0(.a(a), .b(b), .bigger(net[0]), .smaller(net[4]));
    COMPARATOR COMPARATOR_1(.a(d), .b(e), .bigger(net[14]), .smaller(net[19]));
    COMPARATOR COMPARATOR_2(.a(g), .b(h), .bigger(net[31]), .smaller(net[36]));
    COMPARATOR COMPARATOR_3(.a(net[4]), .b(c), .bigger(net[5]), .smaller(net[9]));
    COMPARATOR COMPARATOR_4(.a(net[19]), .b(f), .bigger(net[20]), .smaller(net[27]));
    COMPARATOR COMPARATOR_5(.a(net[36]), .b(i), .bigger(net[37]), .smaller(net[40]));
    COMPARATOR COMPARATOR_6(.a(net[0]), .b(net[5]), .bigger(net[1]), .smaller(net[6]));
    COMPARATOR COMPARATOR_7(.a(net[14]), .b(net[20]), .bigger(net[15]), .smaller(net[21]));
    COMPARATOR COMPARATOR_8(.a(net[31]), .b(net[37]), .bigger(net[32]), .smaller(net[38]));
    COMPARATOR COMPARATOR_9(.a(net[1]), .b(net[15]), .bigger(net[2]), .smaller(net[16]));
    COMPARATOR COMPARATOR_10(.a(net[16]), .b(net[32]), .bigger(net[17]), .smaller(net[33]));
    COMPARATOR COMPARATOR_11(.a(net[2]), .b(net[17]), .bigger(net[3]), .smaller(net[18]));
    COMPARATOR COMPARATOR_12(.a(net[6]), .b(net[21]), .bigger(net[7]), .smaller(net[22]));
    COMPARATOR COMPARATOR_13(.a(net[22]), .b(net[38]), .bigger(net[23]), .smaller(net[39]));
    COMPARATOR COMPARATOR_14(.a(net[7]), .b(net[23]), .bigger(net[8]), .smaller(net[24]));
    COMPARATOR COMPARATOR_15(.a(net[9]), .b(net[27]), .bigger(net[10]), .smaller(net[28]));
    COMPARATOR COMPARATOR_16(.a(net[28]), .b(net[40]), .bigger(net[29]), .smaller(net[41]));
    COMPARATOR COMPARATOR_17(.a(net[10]), .b(net[29]), .bigger(net[11]), .smaller(net[30]));
    COMPARATOR COMPARATOR_18(.a(net[11]), .b(net[33]), .bigger(net[12]), .smaller(net[34]));
    COMPARATOR COMPARATOR_19(.a(net[24]), .b(net[34]), .bigger(net[25]), .smaller(net[35]));
    COMPARATOR COMPARATOR_20(.a(net[12]), .b(net[25]), .bigger(net[13]), .smaller(net[26]));
    always @ (*)
    begin
        z = net[26];
    end
endmodule

module COMPARATOR(a, b, bigger, smaller);
    input [7:0] a, b;
    output reg [7:0] bigger, smaller;
    always @ (*)
    begin
        if(a > b)
        begin
            bigger = a;
            smaller = b;
        end
        else
        begin
            bigger = b;
            smaller = a;
        end
    end
endmodule

module MAX_FOUR(a, b, c, d, z);
    input [7:0] a, b, c, d;
    output reg [7:0] z;
    reg [7:0] net [1:0];

    always @ (*)
    begin
        if(a > b) net[0] = a;
        else net[0] = b;
    end
    always @ (*)
    begin
        if(c > d) net[1] = c;
        else net[1] = d;
    end
    always @ (*)
    begin
        if(net[0] > net[1]) z = net[0];
        else z = net[1];
    end
endmodule