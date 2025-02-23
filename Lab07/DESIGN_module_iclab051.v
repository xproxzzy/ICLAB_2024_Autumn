module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_row,
    in_kernel,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_data,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);
input clk;
input rst_n;
input in_valid;
input [17:0] in_row;
input [11:0] in_kernel;
input out_idle;
output reg handshake_sready;
output reg [29:0] handshake_din;
// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;
output flag_clk1_to_handshake;

input fifo_empty;
input [7:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [7:0] out_data;
// You can use the the custom flag ports for your design
output flag_clk1_to_fifo;
input flag_fifo_to_clk1;

//==================================================================
// parameter & integer
//==================================================================
parameter IDLE = 3'd0;
parameter GET = 3'd1;
parameter SEND = 3'd2;
parameter WAIT_SEND = 3'd3;
parameter WAIT_ANS = 3'd4;
parameter READ = 3'd5;
integer i;

//==================================================================
// reg & wire
//==================================================================
reg [2:0] input_counter;
reg [2:0] next_input_counter;
reg [17:0] row_reg [5:0];
reg [17:0] next_row_reg [5:0];
reg [11:0] kernel_reg [5:0];
reg [11:0] next_kernel_reg [5:0];
reg [2:0] send_counter;
reg [2:0] next_send_counter;
reg [7:0] output_counter;
reg [7:0] next_output_counter;
reg [2:0] state;
reg [2:0] next_state;
reg [1:0] fifo_rinc_reg;
reg [1:0] next_fifo_rinc_reg;

//==================================================================
// sequential
//==================================================================
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state <= 3'd0;
        input_counter <= 3'd0;
        for(i = 0; i < 6; i = i+1)
        begin
            row_reg[i] <= 18'd0;
        end
        for(i = 0; i < 6; i = i+1)
        begin
            kernel_reg[i] <= 12'd0;
        end
        send_counter <= 3'd0;
        output_counter <= 8'd0;
        fifo_rinc_reg <= 2'd0;
    end
    else
    begin
        state <= next_state;
        input_counter <= next_input_counter;
        for(i = 0; i < 6; i = i+1)
        begin
            row_reg[i] <= next_row_reg[i];
        end
        for(i = 0; i < 6; i = i+1)
        begin
            kernel_reg[i] <= next_kernel_reg[i];
        end
        send_counter <= next_send_counter;
        output_counter <= next_output_counter;
        fifo_rinc_reg <= next_fifo_rinc_reg;
    end
end

//==================================================================
// next_state
//==================================================================
always @ (*)
begin
    case(state)
    IDLE:
    begin
        if(in_valid) next_state = GET;
        else next_state = IDLE;
    end
    GET:
    begin
        if(input_counter == 3'd5) next_state = SEND;
        else next_state = GET;
    end
    SEND:
    begin
        if((send_counter == 3'd5) && (handshake_sready == 1'b1)) next_state = READ;
        else next_state = SEND;
    end
    READ:
    begin
        if(output_counter == 8'd149) next_state = IDLE;
        else next_state = READ;
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
    if(in_valid) next_input_counter = input_counter + 3'd1;
    else next_input_counter = 3'd0;
end

always @ (*)
begin
    if(handshake_sready == 1'b1)
    begin
        if(send_counter == 3'd5) next_send_counter = 3'd0;
        else  next_send_counter = send_counter + 3'd1;
    end
    else next_send_counter = send_counter;
end

always @ (*)
begin
    if(out_valid == 1'b1)
    begin
        if(output_counter == 8'd149) next_output_counter = 8'd0;
        else next_output_counter = output_counter + 8'd1;
    end
    else next_output_counter = output_counter;
end

//==================================================================
// next_row_reg
//==================================================================
always @ (*)
begin
    for(i = 0; i < 6; i = i+1)
    begin
        next_row_reg[i] = row_reg[i];
    end
    if(in_valid) next_row_reg[input_counter] = in_row;
end

//==================================================================
// next_kernel_reg
//==================================================================
always @ (*)
begin
    for(i = 0; i < 6; i = i+1)
    begin
        next_kernel_reg[i] = kernel_reg[i];
    end
    if(in_valid) next_kernel_reg[input_counter] = in_kernel;
end

//==================================================================
// handshake_sready
//==================================================================
always @ (*)
begin
    if((state == SEND) && (out_idle == 1'b1)) handshake_sready = 1'b1;
    else handshake_sready = 1'b0;
end

//==================================================================
// handshake_din
//==================================================================
always @ (*)
begin
    if((state == SEND) && (out_idle == 1'b1)) handshake_din = {row_reg[send_counter], kernel_reg[send_counter]};
    else handshake_din = 30'd0;
end

//==================================================================
// fifo_rinc
//==================================================================
assign fifo_rinc = ((state == READ) && (fifo_empty == 1'b0))?(1'b1):(1'b0);

//==================================================================
// next_fifo_rinc_reg
//==================================================================
always @ (*)
begin
    next_fifo_rinc_reg[1] = fifo_rinc_reg[0];
    next_fifo_rinc_reg[0] = fifo_rinc;
end

//==================================================================
// out_valid
//==================================================================
always @ (*)
begin
    out_valid = fifo_rinc_reg[1];
end

//==================================================================
// out_data
//==================================================================
always @ (*)
begin
    if(out_valid == 1'b1) out_data = fifo_rdata;
    else out_data = 8'd0;
end

endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_data,
    out_valid,
    out_data,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [29:0] in_data;
output reg out_valid;
output reg [7:0] out_data;
output reg busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;

//==================================================================
// parameter & integer
//==================================================================
parameter IDLE = 3'd0;
parameter GET = 3'd1;
parameter CAL = 3'd2;

integer i;

//==================================================================
// reg & wire
//==================================================================
reg [2:0] input_counter;
reg [2:0] next_input_counter;
reg [17:0] row_reg [5:0];
reg [17:0] next_row_reg [5:0];
reg [11:0] kernel_reg [5:0];
reg [11:0] next_kernel_reg [5:0];
reg [7:0] output_counter;
reg [7:0] next_output_counter;
reg [2:0] state;
reg [2:0] next_state;

reg [2:0] column_counter;
reg [2:0] next_column_counter;
reg [2:0] row_counter;
reg [2:0] next_row_counter;
reg [2:0] kernel_counter;
reg [2:0] next_kernel_counter;
//==================================================================
// sequential
//==================================================================
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state <= 3'd0;
        input_counter <= 3'd0;
        for(i = 0; i < 6; i = i+1)
        begin
            row_reg[i] <= 18'd0;
        end
        for(i = 0; i < 6; i = i+1)
        begin
            kernel_reg[i] <= 12'd0;
        end
        column_counter <= 3'd0;
        row_counter <= 3'd0;
        kernel_counter <= 3'd0;
        output_counter <= 8'd0;
    end
    else
    begin
        state <= next_state;
        input_counter <= next_input_counter;
        for(i = 0; i < 6; i = i+1)
        begin
            row_reg[i] <= next_row_reg[i];
        end
        for(i = 0; i < 6; i = i+1)
        begin
            kernel_reg[i] <= next_kernel_reg[i];
        end
        column_counter <= next_column_counter;
        row_counter <= next_row_counter;
        kernel_counter <= next_kernel_counter;
        output_counter <= next_output_counter;
    end
end

//==================================================================
// next_state
//==================================================================
always @ (*)
begin
    case(state)
    IDLE:
    begin
        if(in_valid && (input_counter == 3'd5)) next_state = CAL;
        else next_state = IDLE;
    end
    CAL:
    begin
        if((output_counter == 8'd149) && (out_valid == 1'b1)) next_state = IDLE;
        else next_state = CAL;
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
        if(input_counter == 3'd5) next_input_counter = 3'd0;
        else next_input_counter = input_counter + 3'd1;
    end
    else next_input_counter = input_counter;
end

always @ (*)
begin
    if(out_valid == 1'b1)
    begin
        if(column_counter == 3'd4) next_column_counter = 3'd0;
        else next_column_counter = column_counter + 3'd1;
    end
    else next_column_counter = column_counter;
end

always @ (*)
begin
    if((out_valid == 1'b1) && (column_counter == 3'd4))
    begin
        if(row_counter == 3'd4) next_row_counter = 3'd0;
        else next_row_counter = row_counter + 3'd1;
    end
    else next_row_counter = row_counter;
end

always @ (*)
begin
    if((out_valid == 1'b1) && (row_counter == 3'd4) && (column_counter == 3'd4))
    begin
        if(kernel_counter == 3'd5) next_kernel_counter = 3'd0;
        else next_kernel_counter = kernel_counter + 3'd1;
    end
    else next_kernel_counter = kernel_counter;
end

always @ (*)
begin
    if(out_valid == 1'b1)
    begin
        if(output_counter == 8'd149) next_output_counter = 8'd0;
        else next_output_counter = output_counter + 8'd1;
    end
    else next_output_counter = output_counter;
end

//==================================================================
// next_row_reg
//==================================================================
always @ (*)
begin
    for(i = 0; i < 6; i = i+1)
    begin
        next_row_reg[i] = row_reg[i];
    end
    if(in_valid) next_row_reg[input_counter] = in_data[29:12];
end

//==================================================================
// next_kernel_reg
//==================================================================
always @ (*)
begin
    for(i = 0; i < 6; i = i+1)
    begin
        next_kernel_reg[i] = kernel_reg[i];
    end
    if(in_valid) next_kernel_reg[input_counter] = in_data[11:0];
end

//==================================================================
// busy
//==================================================================
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) busy <= 1'b0;
    else busy <= busy;
end

//==================================================================
// out_valid
//==================================================================
always @ (*)
begin
    if((state == CAL) && (fifo_full == 1'b0)) out_valid = 1'b1;
    else out_valid = 1'b0;
end

//==================================================================
// out_data
//==================================================================
always @ (*)
begin
    if(state == CAL)
    begin
        case(column_counter)
        3'd0:
        begin
            out_data =  row_reg[row_counter][2:0] * kernel_reg[kernel_counter][2:0] + 
                        row_reg[row_counter][5:3] * kernel_reg[kernel_counter][5:3] + 
                        row_reg[row_counter+1][2:0] * kernel_reg[kernel_counter][8:6] + 
                        row_reg[row_counter+1][5:3] * kernel_reg[kernel_counter][11:9];
        end
        3'd1:
        begin
            out_data =  row_reg[row_counter][5:3] * kernel_reg[kernel_counter][2:0] + 
                        row_reg[row_counter][8:6] * kernel_reg[kernel_counter][5:3] + 
                        row_reg[row_counter+1][5:3] * kernel_reg[kernel_counter][8:6] + 
                        row_reg[row_counter+1][8:6] * kernel_reg[kernel_counter][11:9];
        end
        3'd2:
        begin
            out_data =  row_reg[row_counter][8:6] * kernel_reg[kernel_counter][2:0] + 
                        row_reg[row_counter][11:9] * kernel_reg[kernel_counter][5:3] + 
                        row_reg[row_counter+1][8:6] * kernel_reg[kernel_counter][8:6] + 
                        row_reg[row_counter+1][11:9] * kernel_reg[kernel_counter][11:9];
        end
        3'd3:
        begin
            out_data =  row_reg[row_counter][11:9] * kernel_reg[kernel_counter][2:0] + 
                        row_reg[row_counter][14:12] * kernel_reg[kernel_counter][5:3] + 
                        row_reg[row_counter+1][11:9] * kernel_reg[kernel_counter][8:6] + 
                        row_reg[row_counter+1][14:12] * kernel_reg[kernel_counter][11:9];
        end
        3'd4:
        begin
            out_data =  row_reg[row_counter][14:12] * kernel_reg[kernel_counter][2:0] + 
                        row_reg[row_counter][17:15] * kernel_reg[kernel_counter][5:3] + 
                        row_reg[row_counter+1][14:12] * kernel_reg[kernel_counter][8:6] + 
                        row_reg[row_counter+1][17:15] * kernel_reg[kernel_counter][11:9];
        end
        default:
        begin
            out_data = 8'd0;
        end
        endcase
    end
    else out_data = 8'd0;
end

endmodule