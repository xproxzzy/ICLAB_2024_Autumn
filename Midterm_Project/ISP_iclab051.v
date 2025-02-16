module ISP(
    // Input Signals
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] in_pic_no,
    input       in_mode,
    input [1:0] in_ratio_mode,

    // Output Signals
    output reg out_valid,
    output reg [7:0] out_data,
    
    // DRAM Signals
    // axi write address channel
    // src master
    output [3:0]  awid_s_inf,
    output reg [31:0] awaddr_s_inf,
    output [2:0]  awsize_s_inf,
    output [1:0]  awburst_s_inf,
    output [7:0]  awlen_s_inf,
    output        awvalid_s_inf,
    // src slave
    input         awready_s_inf,
    // -----------------------------
  
    // axi write data channel 
    // src master
    output reg [127:0] wdata_s_inf,
    output reg         wlast_s_inf,
    output reg         wvalid_s_inf,
    // src slave
    input          wready_s_inf,
  
    // axi write response channel 
    // src slave
    input [3:0]    bid_s_inf,
    input [1:0]    bresp_s_inf,
    input          bvalid_s_inf,
    // src master 
    output reg        bready_s_inf,
    // -----------------------------
  
    // axi read address channel 
    // src master
    output [3:0]   arid_s_inf,
    output reg [31:0]  araddr_s_inf,
    output [7:0]   arlen_s_inf,
    output [2:0]   arsize_s_inf,
    output [1:0]   arburst_s_inf,
    output         arvalid_s_inf,
    // src slave
    input          arready_s_inf,
    // -----------------------------
  
    // axi read data channel 
    // slave
    input [3:0]    rid_s_inf,
    input [127:0]  rdata_s_inf,
    input [1:0]    rresp_s_inf,
    input          rlast_s_inf,
    input          rvalid_s_inf,
    // master
    output reg        rready_s_inf
    
);

//==================================================================
// parameter & integer
//==================================================================
parameter IDLE = 3'd0;
parameter SEL = 3'd1;
parameter WAIT_READ = 3'd2;
parameter WAIT_WRITE = 3'd3;
parameter WAIT_VALID = 3'd4;
parameter READ_WRITE = 3'd5;
parameter OUT = 3'd6;
integer i;

//==================================================================
// reg & wire
//==================================================================
reg [3:0] in_pic_no_reg;
reg [3:0] next_in_pic_no_reg;
reg in_mode_reg;
reg next_in_mode_reg;
reg [1:0] in_ratio_mode_reg;
reg [1:0] next_in_ratio_mode_reg;

reg [127:0] rdata_s_inf_reg;
reg [127:0] next_rdata_s_inf_reg;
reg [127:0] wdata_s_inf_reg [0:2];
reg [127:0] next_wdata_s_inf_reg [0:2];

reg [2:0] state;
reg [2:0] next_state;
reg [5:0] input_counter;
reg [5:0] next_input_counter;
reg [1:0] rgb_counter;
reg [1:0] next_rgb_counter;
reg [3:0] auto_focus_store_counter;
reg [3:0] next_auto_focus_store_counter;
reg [4:0] cal_counter;
reg [4:0] next_cal_counter;

reg [127:0] real_data;

reg [7:0] gray_data [0:35];
reg [7:0] next_gray_data [0:35];
reg [6:0] gray_adder_a [0:2];
reg [7:0] gray_adder_b [0:2];
reg [7:0] gray_adder_z [0:2];

reg [7:0] auto_focus_sub_a [0:2];
reg [7:0] auto_focus_sub_b [0:2];
reg [7:0] auto_focus_sub_bigger [0:2];
reg [7:0] auto_focus_sub_smaller [0:2];
reg [7:0] auto_focus_sub_bigger_reg [0:2];
reg [7:0] auto_focus_sub_smaller_reg [0:2];
reg [7:0] auto_focus_sub_z [0:2];
reg [7:0] auto_focus_sub_z_reg [0:2];
reg [7:0] auto_focus_adder_0_a;
reg [7:0] auto_focus_adder_0_b;
reg [8:0] auto_focus_adder_0_z;
reg [7:0] auto_focus_adder_1_a;
reg [8:0] auto_focus_adder_1_b;
reg [9:0] auto_focus_adder_1_z;
reg [7:0] auto_focus_partial_2;
reg [8:0] auto_focus_partial_4;
reg [9:0] auto_focus_partial_6;
reg [7:0] auto_focus_acc_2;
reg [8:0] auto_focus_acc_4;
reg [9:0] auto_focus_acc_6;
reg [9:0] auto_focus_data_2;
reg [12:0] auto_focus_data_4;
reg [13:0] auto_focus_data_6;
reg [7:0] auto_focus_div_2;
reg [8:0] auto_focus_div_4;
reg [8:0] auto_focus_div_6;
reg [1:0] auto_focus_ans;

reg [6:0] auto_exposure_adder_0_a [0:15];
reg [7:0] auto_exposure_adder_0_z [0:7];
reg [8:0] auto_exposure_adder_1_z [0:3];
reg [8:0] auto_exposure_adder_1_z_reg [0:3];
reg [9:0] auto_exposure_adder_2_z [0:1];
reg [10:0] auto_exposure_adder_3_z;
reg [10:0] auto_exposure_adder_3_z_reg;
reg [10:0] auto_exposure_acc;
reg [17:0] auto_exposure_data;
reg [7:0] auto_exposure_ans;

reg read_flag [0:15];
reg next_read_flag [0:15];
reg zero_flag [0:15];
reg next_zero_flag [0:15];
reg zero_flag_now;
reg next_zero_flag_now;
reg [1:0] last_auto_focus [0:15];
reg [1:0] next_last_auto_focus [0:15];
reg [7:0] last_auto_exposure [0:15];
reg [7:0] next_last_auto_exposure [0:15];
reg [7:0] out_data_reg;
reg [7:0] next_out_data_reg;
//==================================================================
// sequential
//==================================================================
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state <= IDLE;
        in_pic_no_reg <= 4'd0;
        in_mode_reg <= 1'b1;
        in_ratio_mode_reg <= 2'd0;
        rdata_s_inf_reg <= 128'd0;
        for(i = 0; i < 3; i = i+1)
        begin
            wdata_s_inf_reg[i] <= 128'd0;
        end
        input_counter <= 6'd0;
        rgb_counter <= 2'd0;
        auto_focus_store_counter <= 4'd0;
        cal_counter <= 5'd0;
        for(i = 0; i < 36; i = i+1)
        begin
            gray_data[i] <= 8'd0;
        end
        for(i = 0; i < 16; i = i+1)
        begin
            read_flag[i] <= 1'b0;
        end
        for(i = 0; i < 16; i = i+1)
        begin
            zero_flag[i] <= 1'b0;
        end
        zero_flag_now <= 1'b0;
        for(i = 0; i < 16; i = i+1)
        begin
            last_auto_focus[i] <= 2'd0;
        end
        for(i = 0; i < 16; i = i+1)
        begin
            last_auto_exposure[i] <= 8'd0;
        end
        out_data_reg <= 8'd0;
    end
    else
    begin
        state <= next_state;
        in_pic_no_reg <= next_in_pic_no_reg;
        in_mode_reg <= next_in_mode_reg;
        in_ratio_mode_reg <= next_in_ratio_mode_reg;
        rdata_s_inf_reg <= next_rdata_s_inf_reg;
        for(i = 0; i < 3; i = i+1)
        begin
            wdata_s_inf_reg[i] <= next_wdata_s_inf_reg[i];
        end
        input_counter <= next_input_counter;
        rgb_counter <= next_rgb_counter;
        auto_focus_store_counter <= next_auto_focus_store_counter;
        cal_counter <= next_cal_counter;
        for(i = 0; i < 36; i = i+1)
        begin
            gray_data[i] <= next_gray_data[i];
        end
        for(i = 0; i < 16; i = i+1)
        begin
            read_flag[i] <= next_read_flag[i];
        end
        for(i = 0; i < 16; i = i+1)
        begin
            zero_flag[i] <= next_zero_flag[i];
        end
        zero_flag_now <= next_zero_flag_now;
        for(i = 0; i < 16; i = i+1)
        begin
            last_auto_focus[i] <= next_last_auto_focus[i];
        end
        for(i = 0; i < 16; i = i+1)
        begin
            last_auto_exposure[i] <= next_last_auto_exposure[i];
        end
        out_data_reg <= next_out_data_reg;
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
        if(in_valid) next_state = SEL;
        else next_state = IDLE;
    end
    SEL:
    begin
        if((read_flag[in_pic_no_reg] == 1'b0) || ((in_mode_reg == 1'b1) && (in_ratio_mode_reg != 2'd2) && (zero_flag[in_pic_no_reg] != 1'b1))) next_state = WAIT_READ;
        else next_state = OUT;
    end
    WAIT_READ:
    begin
        if(arready_s_inf == 1'b1) next_state = WAIT_WRITE;
        else next_state = WAIT_READ;
    end
    WAIT_WRITE:
    begin
        if(awready_s_inf == 1'b1) next_state = WAIT_VALID;
        else next_state = WAIT_WRITE;
    end
    WAIT_VALID:
    begin
        if(rvalid_s_inf == 1'b1) next_state = READ_WRITE;
        else next_state = WAIT_VALID;
    end
    READ_WRITE:
    begin
        if(cal_counter == 5'd31) next_state = OUT;
        else next_state = READ_WRITE;
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
// next_in_pic_no_reg
//==================================================================
always @ (*)
begin
    if(in_valid) next_in_pic_no_reg = in_pic_no;
    else next_in_pic_no_reg = in_pic_no_reg;
end

//==================================================================
// next_in_mode_reg
//==================================================================
always @ (*)
begin
    if(in_valid) next_in_mode_reg = in_mode;
    else next_in_mode_reg = in_mode_reg;
end

//==================================================================
// next_in_ratio_mode_reg
//==================================================================
always @ (*)
begin
    if(in_valid)
    begin
        if(in_mode == 1'b1) next_in_ratio_mode_reg = in_ratio_mode;
        else next_in_ratio_mode_reg = 2'd2;
    end
    else next_in_ratio_mode_reg = in_ratio_mode_reg;
end

//==================================================================
// next_rdata_s_inf_reg
//==================================================================
always @ (*)
begin
    if(rvalid_s_inf == 1'b1) next_rdata_s_inf_reg = rdata_s_inf;
    else next_rdata_s_inf_reg = 128'd0;
end

//==================================================================
// next_wdata_s_inf_reg
//==================================================================
always @ (*)
begin
    next_wdata_s_inf_reg[0] = real_data;
    next_wdata_s_inf_reg[1] = wdata_s_inf_reg[0];
    next_wdata_s_inf_reg[2] = wdata_s_inf_reg[1];
end

//==================================================================
// next_input_counter
//==================================================================
always @ (*)
begin
    if(state == OUT) next_input_counter = 6'd0;
    else if(state == READ_WRITE) next_input_counter = input_counter + 6'd1;
    else next_input_counter = input_counter;
end

//==================================================================
// next_rgb_counter
//==================================================================
always @ (*)
begin
    if(state == OUT) next_rgb_counter = 2'd0;
    else if(input_counter == 6'd63) next_rgb_counter = rgb_counter + 2'd1;
    else next_rgb_counter = rgb_counter;
end

//==================================================================
// next_auto_focus_store_counter
//==================================================================
always @ (*)
begin
    if(input_counter == 6'd37) next_auto_focus_store_counter = 4'd0;
    else if((input_counter >= 6'd25) && (input_counter < 6'd37)) next_auto_focus_store_counter = auto_focus_store_counter + 4'd1;
    else next_auto_focus_store_counter = auto_focus_store_counter;
end

//==================================================================
// cal_counter
//==================================================================
always @ (*)
begin
    if(state == OUT) next_cal_counter = 5'd0;
    else if(((rgb_counter == 2'd2) && (input_counter == 6'd37)) || (cal_counter != 5'd0)) next_cal_counter = cal_counter + 5'd1;
    else next_cal_counter = cal_counter;
end

//==================================================================
// real_data
//==================================================================
always @ (*)
begin
    //if(wvalid_s_inf == 1'b1)
    //begin
        case(in_ratio_mode_reg)
        2'd0:
        begin
            real_data[7:0] = {2'd0, rdata_s_inf_reg[7:2]};
            real_data[15:8] = {2'd0, rdata_s_inf_reg[15:10]};
            real_data[23:16] = {2'd0, rdata_s_inf_reg[23:18]};
            real_data[31:24] = {2'd0, rdata_s_inf_reg[31:26]};
            real_data[39:32] = {2'd0, rdata_s_inf_reg[39:34]};
            real_data[47:40] = {2'd0, rdata_s_inf_reg[47:42]};
            real_data[55:48] = {2'd0, rdata_s_inf_reg[55:50]};
            real_data[63:56] = {2'd0, rdata_s_inf_reg[63:58]};
            real_data[71:64] = {2'd0, rdata_s_inf_reg[71:66]};
            real_data[79:72] = {2'd0, rdata_s_inf_reg[79:74]};
            real_data[87:80] = {2'd0, rdata_s_inf_reg[87:82]};
            real_data[95:88] = {2'd0, rdata_s_inf_reg[95:90]};
            real_data[103:96] = {2'd0, rdata_s_inf_reg[103:98]};
            real_data[111:104] = {2'd0, rdata_s_inf_reg[111:106]};
            real_data[119:112] = {2'd0, rdata_s_inf_reg[119:114]};
            real_data[127:120] = {2'd0, rdata_s_inf_reg[127:122]};
        end
        2'd1:
        begin
            real_data[7:0] = {1'b0, rdata_s_inf_reg[7:1]};
            real_data[15:8] = {1'b0, rdata_s_inf_reg[15:9]};
            real_data[23:16] = {1'b0, rdata_s_inf_reg[23:17]};
            real_data[31:24] = {1'b0, rdata_s_inf_reg[31:25]};
            real_data[39:32] = {1'b0, rdata_s_inf_reg[39:33]};
            real_data[47:40] = {1'b0, rdata_s_inf_reg[47:41]};
            real_data[55:48] = {1'b0, rdata_s_inf_reg[55:49]};
            real_data[63:56] = {1'b0, rdata_s_inf_reg[63:57]};
            real_data[71:64] = {1'b0, rdata_s_inf_reg[71:65]};
            real_data[79:72] = {1'b0, rdata_s_inf_reg[79:73]};
            real_data[87:80] = {1'b0, rdata_s_inf_reg[87:81]};
            real_data[95:88] = {1'b0, rdata_s_inf_reg[95:89]};
            real_data[103:96] = {1'b0, rdata_s_inf_reg[103:97]};
            real_data[111:104] = {1'b0, rdata_s_inf_reg[111:105]};
            real_data[119:112] = {1'b0, rdata_s_inf_reg[119:113]};
            real_data[127:120] = {1'b0, rdata_s_inf_reg[127:121]};
        end
        2'd2:
        begin
            real_data = rdata_s_inf_reg;
        end
        2'd3:
        begin
            real_data[7:0] = (rdata_s_inf_reg[7] == 1'b1)?(8'd255):({rdata_s_inf_reg[6:0], 1'b0});
            real_data[15:8] = (rdata_s_inf_reg[15] == 1'b1)?(8'd255):({rdata_s_inf_reg[14:8], 1'b0});
            real_data[23:16] = (rdata_s_inf_reg[23] == 1'b1)?(8'd255):({rdata_s_inf_reg[22:16], 1'b0});
            real_data[31:24] = (rdata_s_inf_reg[31] == 1'b1)?(8'd255):({rdata_s_inf_reg[30:24], 1'b0});
            real_data[39:32] = (rdata_s_inf_reg[39] == 1'b1)?(8'd255):({rdata_s_inf_reg[38:32], 1'b0});
            real_data[47:40] = (rdata_s_inf_reg[47] == 1'b1)?(8'd255):({rdata_s_inf_reg[46:40], 1'b0});
            real_data[55:48] = (rdata_s_inf_reg[55] == 1'b1)?(8'd255):({rdata_s_inf_reg[54:48], 1'b0});
            real_data[63:56] = (rdata_s_inf_reg[63] == 1'b1)?(8'd255):({rdata_s_inf_reg[62:56], 1'b0});
            real_data[71:64] = (rdata_s_inf_reg[71] == 1'b1)?(8'd255):({rdata_s_inf_reg[70:64], 1'b0});
            real_data[79:72] = (rdata_s_inf_reg[79] == 1'b1)?(8'd255):({rdata_s_inf_reg[78:72], 1'b0});
            real_data[87:80] = (rdata_s_inf_reg[87] == 1'b1)?(8'd255):({rdata_s_inf_reg[86:80], 1'b0});
            real_data[95:88] = (rdata_s_inf_reg[95] == 1'b1)?(8'd255):({rdata_s_inf_reg[94:88], 1'b0});
            real_data[103:96] = (rdata_s_inf_reg[103] == 1'b1)?(8'd255):({rdata_s_inf_reg[102:96], 1'b0});
            real_data[111:104] = (rdata_s_inf_reg[111] == 1'b1)?(8'd255):({rdata_s_inf_reg[110:104], 1'b0});
            real_data[119:112] = (rdata_s_inf_reg[119] == 1'b1)?(8'd255):({rdata_s_inf_reg[118:112], 1'b0});
            real_data[127:120] = (rdata_s_inf_reg[127] == 1'b1)?(8'd255):({rdata_s_inf_reg[126:120], 1'b0});
            /*if(rdata_s_inf_reg[7] == 1'b1) real_data[7:0] = 8'd255;
            else real_data[7:0] = {rdata_s_inf_reg[6:0], 1'b0};
            if(rdata_s_inf_reg[15] == 1'b1) real_data[15:8] = 8'd255;
            else real_data[15:8] = {rdata_s_inf_reg[14:8], 1'b0};
            if(rdata_s_inf_reg[23] == 1'b1) real_data[23:16] = 8'd255;
            else real_data[23:16] = {rdata_s_inf_reg[22:16], 1'b0};
            if(rdata_s_inf_reg[31] == 1'b1) real_data[31:24] = 8'd255;
            else real_data[31:24] = {rdata_s_inf_reg[30:24], 1'b0};
            if(rdata_s_inf_reg[39] == 1'b1) real_data[39:32] = 8'd255;
            else real_data[39:32] = {rdata_s_inf_reg[38:32], 1'b0};
            if(rdata_s_inf_reg[47] == 1'b1) real_data[47:40] = 8'd255;
            else real_data[47:40] = {rdata_s_inf_reg[46:40], 1'b0};
            if(rdata_s_inf_reg[55] == 1'b1) real_data[55:48] = 8'd255;
            else real_data[55:48] = {rdata_s_inf_reg[54:48], 1'b0};
            if(rdata_s_inf_reg[63] == 1'b1) real_data[63:56] = 8'd255;
            else real_data[63:56] = {rdata_s_inf_reg[62:56], 1'b0};
            if(rdata_s_inf_reg[71] == 1'b1) real_data[71:64] = 8'd255;
            else real_data[71:64] = {rdata_s_inf_reg[70:64], 1'b0};
            if(rdata_s_inf_reg[79] == 1'b1) real_data[79:72] = 8'd255;
            else real_data[79:72] = {rdata_s_inf_reg[78:72], 1'b0};
            if(rdata_s_inf_reg[87] == 1'b1) real_data[87:80] = 8'd255;
            else real_data[87:80] = {rdata_s_inf_reg[86:80], 1'b0};
            if(rdata_s_inf_reg[95] == 1'b1) real_data[95:88] = 8'd255;
            else real_data[95:88] = {rdata_s_inf_reg[94:88], 1'b0};
            if(rdata_s_inf_reg[103] == 1'b1) real_data[103:96] = 8'd255;
            else real_data[103:96] = {rdata_s_inf_reg[102:96], 1'b0};
            if(rdata_s_inf_reg[111] == 1'b1) real_data[111:104] = 8'd255;
            else real_data[111:104] = {rdata_s_inf_reg[110:104], 1'b0};
            if(rdata_s_inf_reg[119] == 1'b1) real_data[119:112] = 8'd255;
            else real_data[119:112] = {rdata_s_inf_reg[118:112], 1'b0};
            if(rdata_s_inf_reg[127] == 1'b1) real_data[127:120] = 8'd255;
            else real_data[127:120] = {rdata_s_inf_reg[126:120], 1'b0};*/
        end
        default: real_data = rdata_s_inf_reg;
        endcase
    //end
    //else real_data = 128'd0;
end

//==================================================================
// next_gray_data
//==================================================================
always @ (*)
begin
    if(state == OUT)
    begin
        for(i = 0; i < 36; i = i+1)
        begin
            next_gray_data[i] = 8'd0;
        end
    end
    else
    begin
        for(i = 0; i < 36; i = i+1)
        begin
            next_gray_data[i] = gray_data[i];
        end
        case(auto_focus_store_counter)
        4'd1:
        begin
            next_gray_data[0] = gray_adder_z[0];
            next_gray_data[1] = gray_adder_z[1];
            next_gray_data[2] = gray_adder_z[2];
        end
        4'd2:
        begin
            next_gray_data[3] = gray_adder_z[0];
            next_gray_data[4] = gray_adder_z[1];
            next_gray_data[5] = gray_adder_z[2];
        end
        4'd3:
        begin
            next_gray_data[6] = gray_adder_z[0];
            next_gray_data[7] = gray_adder_z[1];
            next_gray_data[8] = gray_adder_z[2];
        end
        4'd4:
        begin
            next_gray_data[9] = gray_adder_z[0];
            next_gray_data[10] = gray_adder_z[1];
            next_gray_data[11] = gray_adder_z[2];
        end
        4'd5:
        begin
            next_gray_data[12] = gray_adder_z[0];
            next_gray_data[13] = gray_adder_z[1];
            next_gray_data[14] = gray_adder_z[2];
        end
        4'd6:
        begin
            next_gray_data[15] = gray_adder_z[0];
            next_gray_data[16] = gray_adder_z[1];
            next_gray_data[17] = gray_adder_z[2];
        end
        4'd7:
        begin
            next_gray_data[18] = gray_adder_z[0];
            next_gray_data[19] = gray_adder_z[1];
            next_gray_data[20] = gray_adder_z[2];
        end
        4'd8:
        begin
            next_gray_data[21] = gray_adder_z[0];
            next_gray_data[22] = gray_adder_z[1];
            next_gray_data[23] = gray_adder_z[2];
        end
        4'd9:
        begin
            next_gray_data[24] = gray_adder_z[0];
            next_gray_data[25] = gray_adder_z[1];
            next_gray_data[26] = gray_adder_z[2];
        end
        4'd10:
        begin
            next_gray_data[27] = gray_adder_z[0];
            next_gray_data[28] = gray_adder_z[1];
            next_gray_data[29] = gray_adder_z[2];
        end
        4'd11:
        begin
            next_gray_data[30] = gray_adder_z[0];
            next_gray_data[31] = gray_adder_z[1];
            next_gray_data[32] = gray_adder_z[2];
        end
        4'd12:
        begin
            next_gray_data[33] = gray_adder_z[0];
            next_gray_data[34] = gray_adder_z[1];
            next_gray_data[35] = gray_adder_z[2];
        end
        endcase
    end
end

always @ (*)
begin
    if(rgb_counter[0] == 1'b0)
    begin
        if(auto_focus_store_counter[0] == 1'b1)
        begin
            gray_adder_a[0] = {1'b0, real_data[111:106]};
            gray_adder_a[1] = {1'b0, real_data[119:114]};
            gray_adder_a[2] = {1'b0, real_data[127:122]};
        end
        else
        begin
            gray_adder_a[0] = {1'b0, real_data[7:2]};
            gray_adder_a[1] = {1'b0, real_data[15:10]};
            gray_adder_a[2] = {1'b0, real_data[23:18]};
        end
    end
    else
    begin
        if(auto_focus_store_counter[0] == 1'b1)
        begin
            gray_adder_a[0] = real_data[111:105];
            gray_adder_a[1] = real_data[119:113];
            gray_adder_a[2] = real_data[127:121];
        end
        else
        begin
            gray_adder_a[0] = real_data[7:1];
            gray_adder_a[1] = real_data[15:9];
            gray_adder_a[2] = real_data[23:17];
        end
    end
end

always @ (*)
begin
    case(auto_focus_store_counter)
    4'd1:
    begin
        gray_adder_b[0] = gray_data[0];
        gray_adder_b[1] = gray_data[1];
        gray_adder_b[2] = gray_data[2];
    end
    4'd2:
    begin
        gray_adder_b[0] = gray_data[3];
        gray_adder_b[1] = gray_data[4];
        gray_adder_b[2] = gray_data[5];
    end
    4'd3:
    begin
        gray_adder_b[0] = gray_data[6];
        gray_adder_b[1] = gray_data[7];
        gray_adder_b[2] = gray_data[8];
    end
    4'd4:
    begin
        gray_adder_b[0] = gray_data[9];
        gray_adder_b[1] = gray_data[10];
        gray_adder_b[2] = gray_data[11];
    end
    4'd5:
    begin
        gray_adder_b[0] = gray_data[12];
        gray_adder_b[1] = gray_data[13];
        gray_adder_b[2] = gray_data[14];
    end
    4'd6:
    begin
        gray_adder_b[0] = gray_data[15];
        gray_adder_b[1] = gray_data[16];
        gray_adder_b[2] = gray_data[17];
    end
    4'd7:
    begin
        gray_adder_b[0] = gray_data[18];
        gray_adder_b[1] = gray_data[19];
        gray_adder_b[2] = gray_data[20];
    end
    4'd8:
    begin
        gray_adder_b[0] = gray_data[21];
        gray_adder_b[1] = gray_data[22];
        gray_adder_b[2] = gray_data[23];
    end
    4'd9:
    begin
        gray_adder_b[0] = gray_data[24];
        gray_adder_b[1] = gray_data[25];
        gray_adder_b[2] = gray_data[26];
    end
    4'd10:
    begin
        gray_adder_b[0] = gray_data[27];
        gray_adder_b[1] = gray_data[28];
        gray_adder_b[2] = gray_data[29];
    end
    4'd11:
    begin
        gray_adder_b[0] = gray_data[30];
        gray_adder_b[1] = gray_data[31];
        gray_adder_b[2] = gray_data[32];
    end
    4'd12:
    begin
        gray_adder_b[0] = gray_data[33];
        gray_adder_b[1] = gray_data[34];
        gray_adder_b[2] = gray_data[35];
    end
    default:
    begin
        gray_adder_b[0] = 8'd0;
        gray_adder_b[1] = 8'd0;
        gray_adder_b[2] = 8'd0;
    end
    endcase
end

always @ (*)
begin
    gray_adder_z[0] = gray_adder_a[0] + gray_adder_b[0];
    gray_adder_z[1] = gray_adder_a[1] + gray_adder_b[1];
    gray_adder_z[2] = gray_adder_a[2] + gray_adder_b[2];
end

//==================================================================
// auto_focus
//==================================================================
always @ (*)
begin
    case(cal_counter)
    5'd1:
    begin
        auto_focus_sub_a[0] = gray_data[0];
        auto_focus_sub_a[1] = gray_data[1];
        auto_focus_sub_a[2] = gray_data[2];
        auto_focus_sub_b[0] = gray_data[6];
        auto_focus_sub_b[1] = gray_data[7];
        auto_focus_sub_b[2] = gray_data[8];
    end
    5'd2:
    begin
        auto_focus_sub_a[0] = gray_data[5];
        auto_focus_sub_a[1] = gray_data[4];
        auto_focus_sub_a[2] = gray_data[3];
        auto_focus_sub_b[0] = gray_data[11];
        auto_focus_sub_b[1] = gray_data[10];
        auto_focus_sub_b[2] = gray_data[9];
    end
    5'd3:
    begin
        auto_focus_sub_a[0] = gray_data[6];
        auto_focus_sub_a[1] = gray_data[7];
        auto_focus_sub_a[2] = gray_data[8];
        auto_focus_sub_b[0] = gray_data[12];
        auto_focus_sub_b[1] = gray_data[13];
        auto_focus_sub_b[2] = gray_data[14];
    end
    5'd4:
    begin
        auto_focus_sub_a[0] = gray_data[11];
        auto_focus_sub_a[1] = gray_data[10];
        auto_focus_sub_a[2] = gray_data[9];
        auto_focus_sub_b[0] = gray_data[17];
        auto_focus_sub_b[1] = gray_data[16];
        auto_focus_sub_b[2] = gray_data[15];
    end
    5'd5:
    begin
        auto_focus_sub_a[0] = gray_data[12];
        auto_focus_sub_a[1] = gray_data[13];
        auto_focus_sub_a[2] = gray_data[14];
        auto_focus_sub_b[0] = gray_data[18];
        auto_focus_sub_b[1] = gray_data[19];
        auto_focus_sub_b[2] = gray_data[20];
    end
    5'd6:
    begin
        auto_focus_sub_a[0] = gray_data[17];
        auto_focus_sub_a[1] = gray_data[16];
        auto_focus_sub_a[2] = gray_data[15];
        auto_focus_sub_b[0] = gray_data[23];
        auto_focus_sub_b[1] = gray_data[22];
        auto_focus_sub_b[2] = gray_data[21];
    end
    5'd7:
    begin
        auto_focus_sub_a[0] = gray_data[18];
        auto_focus_sub_a[1] = gray_data[19];
        auto_focus_sub_a[2] = gray_data[20];
        auto_focus_sub_b[0] = gray_data[24];
        auto_focus_sub_b[1] = gray_data[25];
        auto_focus_sub_b[2] = gray_data[26];
    end
    5'd8:
    begin
        auto_focus_sub_a[0] = gray_data[23];
        auto_focus_sub_a[1] = gray_data[22];
        auto_focus_sub_a[2] = gray_data[21];
        auto_focus_sub_b[0] = gray_data[29];
        auto_focus_sub_b[1] = gray_data[28];
        auto_focus_sub_b[2] = gray_data[27];
    end
    5'd9:
    begin
        auto_focus_sub_a[0] = gray_data[24];
        auto_focus_sub_a[1] = gray_data[25];
        auto_focus_sub_a[2] = gray_data[26];
        auto_focus_sub_b[0] = gray_data[30];
        auto_focus_sub_b[1] = gray_data[31];
        auto_focus_sub_b[2] = gray_data[32];
    end
    5'd10:
    begin
        auto_focus_sub_a[0] = gray_data[29];
        auto_focus_sub_a[1] = gray_data[28];
        auto_focus_sub_a[2] = gray_data[27];
        auto_focus_sub_b[0] = gray_data[35];
        auto_focus_sub_b[1] = gray_data[34];
        auto_focus_sub_b[2] = gray_data[33];
    end
    5'd11:
    begin
        auto_focus_sub_a[0] = gray_data[0];
        auto_focus_sub_a[1] = gray_data[6];
        auto_focus_sub_a[2] = gray_data[12];
        auto_focus_sub_b[0] = gray_data[1];
        auto_focus_sub_b[1] = gray_data[7];
        auto_focus_sub_b[2] = gray_data[13];
    end
    5'd12:
    begin
        auto_focus_sub_a[0] = gray_data[30];
        auto_focus_sub_a[1] = gray_data[24];
        auto_focus_sub_a[2] = gray_data[18];
        auto_focus_sub_b[0] = gray_data[31];
        auto_focus_sub_b[1] = gray_data[25];
        auto_focus_sub_b[2] = gray_data[19];
    end
    5'd13:
    begin
        auto_focus_sub_a[0] = gray_data[1];
        auto_focus_sub_a[1] = gray_data[7];
        auto_focus_sub_a[2] = gray_data[13];
        auto_focus_sub_b[0] = gray_data[2];
        auto_focus_sub_b[1] = gray_data[8];
        auto_focus_sub_b[2] = gray_data[14];
    end
    5'd14:
    begin
        auto_focus_sub_a[0] = gray_data[31];
        auto_focus_sub_a[1] = gray_data[25];
        auto_focus_sub_a[2] = gray_data[19];
        auto_focus_sub_b[0] = gray_data[32];
        auto_focus_sub_b[1] = gray_data[26];
        auto_focus_sub_b[2] = gray_data[20];
    end
    5'd15:
    begin
        auto_focus_sub_a[0] = gray_data[2];
        auto_focus_sub_a[1] = gray_data[8];
        auto_focus_sub_a[2] = gray_data[14];
        auto_focus_sub_b[0] = gray_data[3];
        auto_focus_sub_b[1] = gray_data[9];
        auto_focus_sub_b[2] = gray_data[15];
    end
    5'd16:
    begin
        auto_focus_sub_a[0] = gray_data[32];
        auto_focus_sub_a[1] = gray_data[26];
        auto_focus_sub_a[2] = gray_data[20];
        auto_focus_sub_b[0] = gray_data[33];
        auto_focus_sub_b[1] = gray_data[27];
        auto_focus_sub_b[2] = gray_data[21];
    end
    5'd17:
    begin
        auto_focus_sub_a[0] = gray_data[3];
        auto_focus_sub_a[1] = gray_data[9];
        auto_focus_sub_a[2] = gray_data[15];
        auto_focus_sub_b[0] = gray_data[4];
        auto_focus_sub_b[1] = gray_data[10];
        auto_focus_sub_b[2] = gray_data[16];
    end
    5'd18:
    begin
        auto_focus_sub_a[0] = gray_data[33];
        auto_focus_sub_a[1] = gray_data[27];
        auto_focus_sub_a[2] = gray_data[21];
        auto_focus_sub_b[0] = gray_data[34];
        auto_focus_sub_b[1] = gray_data[28];
        auto_focus_sub_b[2] = gray_data[22];
    end
    5'd19:
    begin
        auto_focus_sub_a[0] = gray_data[4];
        auto_focus_sub_a[1] = gray_data[10];
        auto_focus_sub_a[2] = gray_data[16];
        auto_focus_sub_b[0] = gray_data[5];
        auto_focus_sub_b[1] = gray_data[11];
        auto_focus_sub_b[2] = gray_data[17];
    end
    5'd20:
    begin
        auto_focus_sub_a[0] = gray_data[34];
        auto_focus_sub_a[1] = gray_data[28];
        auto_focus_sub_a[2] = gray_data[22];
        auto_focus_sub_b[0] = gray_data[35];
        auto_focus_sub_b[1] = gray_data[29];
        auto_focus_sub_b[2] = gray_data[23];
    end
    default:
    begin
        auto_focus_sub_a[0] = 8'd0;
        auto_focus_sub_a[1] = 8'd0;
        auto_focus_sub_a[2] = 8'd0;
        auto_focus_sub_b[0] = 8'd0;
        auto_focus_sub_b[1] = 8'd0;
        auto_focus_sub_b[2] = 8'd0;
    end
    endcase
end

/*always @ (*)
begin
    auto_focus_sub_bigger[0] = (auto_focus_sub_a[0] >= auto_focus_sub_b[0])?(auto_focus_sub_a[0]):(auto_focus_sub_b[0]);
    auto_focus_sub_bigger[1] = (auto_focus_sub_a[1] >= auto_focus_sub_b[1])?(auto_focus_sub_a[1]):(auto_focus_sub_b[1]);
    auto_focus_sub_bigger[2] = (auto_focus_sub_a[2] >= auto_focus_sub_b[2])?(auto_focus_sub_a[2]):(auto_focus_sub_b[2]);
    auto_focus_sub_smaller[0] = (auto_focus_sub_a[0] >= auto_focus_sub_b[0])?(auto_focus_sub_b[0]):(auto_focus_sub_a[0]);
    auto_focus_sub_smaller[1] = (auto_focus_sub_a[1] >= auto_focus_sub_b[1])?(auto_focus_sub_b[1]):(auto_focus_sub_a[1]);
    auto_focus_sub_smaller[2] = (auto_focus_sub_a[2] >= auto_focus_sub_b[2])?(auto_focus_sub_b[2]):(auto_focus_sub_a[2]);
end*/

always @ (*)
begin
    if(auto_focus_sub_a[0] >= auto_focus_sub_b[0])
    begin
        auto_focus_sub_bigger[0] = auto_focus_sub_a[0];
        auto_focus_sub_smaller[0] = auto_focus_sub_b[0];
    end
    else
    begin
        auto_focus_sub_bigger[0] = auto_focus_sub_b[0];
        auto_focus_sub_smaller[0] = auto_focus_sub_a[0];
    end
end
always @ (*)
begin
    if(auto_focus_sub_a[1] >= auto_focus_sub_b[1])
    begin
        auto_focus_sub_bigger[1] = auto_focus_sub_a[1];
        auto_focus_sub_smaller[1] = auto_focus_sub_b[1];
    end
    else
    begin
        auto_focus_sub_bigger[1] = auto_focus_sub_b[1];
        auto_focus_sub_smaller[1] = auto_focus_sub_a[1];
    end
end
always @ (*)
begin
    if(auto_focus_sub_a[2] >= auto_focus_sub_b[2])
    begin
        auto_focus_sub_bigger[2] = auto_focus_sub_a[2];
        auto_focus_sub_smaller[2] = auto_focus_sub_b[2];
    end
    else
    begin
        auto_focus_sub_bigger[2] = auto_focus_sub_b[2];
        auto_focus_sub_smaller[2] = auto_focus_sub_a[2];
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        auto_focus_sub_bigger_reg[0] <= 8'd0;
        auto_focus_sub_bigger_reg[1] <= 8'd0;
        auto_focus_sub_bigger_reg[2] <= 8'd0;
    end
    else
    begin
        auto_focus_sub_bigger_reg[0] <= auto_focus_sub_bigger[0];
        auto_focus_sub_bigger_reg[1] <= auto_focus_sub_bigger[1];
        auto_focus_sub_bigger_reg[2] <= auto_focus_sub_bigger[2];
    end
end
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        auto_focus_sub_smaller_reg[0] <= 8'd0;
        auto_focus_sub_smaller_reg[1] <= 8'd0;
        auto_focus_sub_smaller_reg[2] <= 8'd0;
    end
    else
    begin
        auto_focus_sub_smaller_reg[0] <= auto_focus_sub_smaller[0];
        auto_focus_sub_smaller_reg[1] <= auto_focus_sub_smaller[1];
        auto_focus_sub_smaller_reg[2] <= auto_focus_sub_smaller[2];
    end
end

always @ (*)
begin
    auto_focus_sub_z[0] = auto_focus_sub_bigger_reg[0] - auto_focus_sub_smaller_reg[0];
    auto_focus_sub_z[1] = auto_focus_sub_bigger_reg[1] - auto_focus_sub_smaller_reg[1];
    auto_focus_sub_z[2] = auto_focus_sub_bigger_reg[2] - auto_focus_sub_smaller_reg[2];
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        auto_focus_sub_z_reg[0] <= 8'd0;
        auto_focus_sub_z_reg[1] <= 8'd0;
        auto_focus_sub_z_reg[2] <= 8'd0;
    end
    else
    begin
        auto_focus_sub_z_reg[0] <= auto_focus_sub_z[0];
        auto_focus_sub_z_reg[1] <= auto_focus_sub_z[1];
        auto_focus_sub_z_reg[2] <= auto_focus_sub_z[2];
    end
end

always @ (*)
begin
    auto_focus_adder_0_a = auto_focus_sub_z_reg[1];
    auto_focus_adder_0_b = auto_focus_sub_z_reg[2];
end

always @ (*)
begin
    auto_focus_adder_0_z = auto_focus_adder_0_a + auto_focus_adder_0_b;
end

always @ (*)
begin
    auto_focus_adder_1_a = auto_focus_sub_z_reg[0];
    auto_focus_adder_1_b = auto_focus_adder_0_z;
end

always @ (*)
begin
    auto_focus_adder_1_z = auto_focus_adder_1_a + auto_focus_adder_1_b;
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        auto_focus_partial_2 <= 8'd0;
        auto_focus_partial_4 <= 9'd0;
        auto_focus_partial_6 <= 10'd0;
    end
    else
    begin
        auto_focus_partial_2 <= auto_focus_sub_z_reg[2];
        auto_focus_partial_4 <= auto_focus_adder_0_z;
        auto_focus_partial_6 <= auto_focus_adder_1_z;
    end
end

/*always @ (*)
begin
    case(cal_counter)
    5'd3, 5'd4, 5'd11, 5'd12, 5'd13, 5'd14, 5'd21, 5'd22:
    begin
        auto_focus_acc_2 = 8'd0;
        auto_focus_acc_4 = 9'd0;
        auto_focus_acc_6 = auto_focus_partial_6;
    end
    5'd5, 5'd6, 5'd9, 5'd10, 5'd15, 5'd16, 5'd19, 5'd20:
    begin
        auto_focus_acc_2 = 8'd0;
        auto_focus_acc_4 = auto_focus_partial_4;
        auto_focus_acc_6 = auto_focus_partial_6;
    end
    5'd7, 5'd8, 5'd17, 5'd18:
    begin
        auto_focus_acc_2 = auto_focus_partial_2;
        auto_focus_acc_4 = auto_focus_partial_4;
        auto_focus_acc_6 = auto_focus_partial_6;
    end
    default:
    begin
        auto_focus_acc_2 = 8'd0;
        auto_focus_acc_4 = 9'd0;
        auto_focus_acc_6 = 10'd0;
    end
    endcase
end*/
always @ (*)
begin
    case(cal_counter)
    5'd4, 5'd5, 5'd12, 5'd13, 5'd14, 5'd15, 5'd22, 5'd23:
    begin
        auto_focus_acc_2 = 8'd0;
        auto_focus_acc_4 = 9'd0;
        auto_focus_acc_6 = auto_focus_partial_6;
    end
    5'd6, 5'd7, 5'd10, 5'd11, 5'd16, 5'd17, 5'd20, 5'd21:
    begin
        auto_focus_acc_2 = 8'd0;
        auto_focus_acc_4 = auto_focus_partial_4;
        auto_focus_acc_6 = auto_focus_partial_6;
    end
    5'd8, 5'd9, 5'd18, 5'd19:
    begin
        auto_focus_acc_2 = auto_focus_partial_2;
        auto_focus_acc_4 = auto_focus_partial_4;
        auto_focus_acc_6 = auto_focus_partial_6;
    end
    default:
    begin
        auto_focus_acc_2 = 8'd0;
        auto_focus_acc_4 = 9'd0;
        auto_focus_acc_6 = 10'd0;
    end
    endcase
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        auto_focus_data_2 <= 10'd0;
        auto_focus_data_4 <= 13'd0;
        auto_focus_data_6 <= 14'd0;
    end
    else if(state == OUT)
    begin
        auto_focus_data_2 <= 10'd0;
        auto_focus_data_4 <= 13'd0;
        auto_focus_data_6 <= 14'd0;
    end
    else
    begin
        auto_focus_data_2 <= auto_focus_data_2 + auto_focus_acc_2;
        auto_focus_data_4 <= auto_focus_data_4 + auto_focus_acc_4;
        auto_focus_data_6 <= auto_focus_data_6 + auto_focus_acc_6;
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        auto_focus_div_2 <= 8'd0;
        auto_focus_div_4 <= 9'd0;
        auto_focus_div_6 <= 9'd0;
    end
    else if(state == OUT)
    begin
        auto_focus_div_2 <= 8'd0;
        auto_focus_div_4 <= 9'd0;
        auto_focus_div_6 <= 9'd0;
    end
    else
    begin
        auto_focus_div_2 <= auto_focus_data_2 >> 2;
        auto_focus_div_4 <= auto_focus_data_4 >> 4;
        auto_focus_div_6 <= auto_focus_data_6 / 36;
        //auto_focus_div_6 <= auto_focus_data_6[8:0];
    end
end

//==================================================================
// auto_focus_ans
//==================================================================
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        auto_focus_ans <= 2'd0;
    end
    else if(state == OUT)
    begin
        auto_focus_ans <= 2'd0;
    end
    else
    begin
        if((auto_focus_div_2 >= auto_focus_div_4) && (auto_focus_div_2 >= auto_focus_div_6)) auto_focus_ans <= 2'd0;
        else if(auto_focus_div_4 >= auto_focus_div_6) auto_focus_ans <= 2'd1;
        else auto_focus_ans <= 2'd2;
    end
end

//==================================================================
// auto_exposure
//==================================================================
always @ (*)
begin
    if(rgb_counter[0] == 1'b0)
    begin
        auto_exposure_adder_0_a[0] = {1'b0, real_data[7:2]};
        auto_exposure_adder_0_a[1] = {1'b0, real_data[15:10]};
        auto_exposure_adder_0_a[2] = {1'b0, real_data[23:18]};
        auto_exposure_adder_0_a[3] = {1'b0, real_data[31:26]};
        auto_exposure_adder_0_a[4] = {1'b0, real_data[39:34]};
        auto_exposure_adder_0_a[5] = {1'b0, real_data[47:42]};
        auto_exposure_adder_0_a[6] = {1'b0, real_data[55:50]};
        auto_exposure_adder_0_a[7] = {1'b0, real_data[63:58]};
        auto_exposure_adder_0_a[8] = {1'b0, real_data[71:66]};
        auto_exposure_adder_0_a[9] = {1'b0, real_data[79:74]};
        auto_exposure_adder_0_a[10] = {1'b0, real_data[87:82]};
        auto_exposure_adder_0_a[11] = {1'b0, real_data[95:90]};
        auto_exposure_adder_0_a[12] = {1'b0, real_data[103:98]};
        auto_exposure_adder_0_a[13] = {1'b0, real_data[111:106]};
        auto_exposure_adder_0_a[14] = {1'b0, real_data[119:114]};
        auto_exposure_adder_0_a[15] = {1'b0, real_data[127:122]};
    end
    else
    begin
        auto_exposure_adder_0_a[0] = real_data[7:1];
        auto_exposure_adder_0_a[1] = real_data[15:9];
        auto_exposure_adder_0_a[2] = real_data[23:17];
        auto_exposure_adder_0_a[3] = real_data[31:25];
        auto_exposure_adder_0_a[4] = real_data[39:33];
        auto_exposure_adder_0_a[5] = real_data[47:41];
        auto_exposure_adder_0_a[6] = real_data[55:49];
        auto_exposure_adder_0_a[7] = real_data[63:57];
        auto_exposure_adder_0_a[8] = real_data[71:65];
        auto_exposure_adder_0_a[9] = real_data[79:73];
        auto_exposure_adder_0_a[10] = real_data[87:81];
        auto_exposure_adder_0_a[11] = real_data[95:89];
        auto_exposure_adder_0_a[12] = real_data[103:97];
        auto_exposure_adder_0_a[13] = real_data[111:105];
        auto_exposure_adder_0_a[14] = real_data[119:113];
        auto_exposure_adder_0_a[15] = real_data[127:121];
    end
end

always @ (*)
begin
    auto_exposure_adder_0_z[0] = auto_exposure_adder_0_a[0] + auto_exposure_adder_0_a[1];
    auto_exposure_adder_0_z[1] = auto_exposure_adder_0_a[2] + auto_exposure_adder_0_a[3];
    auto_exposure_adder_0_z[2] = auto_exposure_adder_0_a[4] + auto_exposure_adder_0_a[5];
    auto_exposure_adder_0_z[3] = auto_exposure_adder_0_a[6] + auto_exposure_adder_0_a[7];
    auto_exposure_adder_0_z[4] = auto_exposure_adder_0_a[8] + auto_exposure_adder_0_a[9];
    auto_exposure_adder_0_z[5] = auto_exposure_adder_0_a[10] + auto_exposure_adder_0_a[11];
    auto_exposure_adder_0_z[6] = auto_exposure_adder_0_a[12] + auto_exposure_adder_0_a[13];
    auto_exposure_adder_0_z[7] = auto_exposure_adder_0_a[14] + auto_exposure_adder_0_a[15];
end

always @ (*)
begin
    auto_exposure_adder_1_z[0] = auto_exposure_adder_0_z[0] + auto_exposure_adder_0_z[1];
    auto_exposure_adder_1_z[1] = auto_exposure_adder_0_z[2] + auto_exposure_adder_0_z[3];
    auto_exposure_adder_1_z[2] = auto_exposure_adder_0_z[4] + auto_exposure_adder_0_z[5];
    auto_exposure_adder_1_z[3] = auto_exposure_adder_0_z[6] + auto_exposure_adder_0_z[7];
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        auto_exposure_adder_1_z_reg[0] <= 9'd0;
        auto_exposure_adder_1_z_reg[1] <= 9'd0;
        auto_exposure_adder_1_z_reg[2] <= 9'd0;
        auto_exposure_adder_1_z_reg[3] <= 9'd0;
    end
    else
    begin
        auto_exposure_adder_1_z_reg[0] <= auto_exposure_adder_1_z[0];
        auto_exposure_adder_1_z_reg[1] <= auto_exposure_adder_1_z[1];
        auto_exposure_adder_1_z_reg[2] <= auto_exposure_adder_1_z[2];
        auto_exposure_adder_1_z_reg[3] <= auto_exposure_adder_1_z[3];
    end
end

always @ (*)
begin
    auto_exposure_adder_2_z[0] = auto_exposure_adder_1_z_reg[0] + auto_exposure_adder_1_z_reg[1];
    auto_exposure_adder_2_z[1] = auto_exposure_adder_1_z_reg[2] + auto_exposure_adder_1_z_reg[3];
end

always @ (*)
begin
    auto_exposure_adder_3_z = auto_exposure_adder_2_z[0] + auto_exposure_adder_2_z[1];
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        auto_exposure_adder_3_z_reg <= 11'd0;
    end
    else
    begin
        auto_exposure_adder_3_z_reg <= auto_exposure_adder_3_z;
    end
end

always @ (*)
begin
    auto_exposure_acc = auto_exposure_adder_3_z_reg;
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        auto_exposure_data <= 18'd0;
    end
    else if(state == OUT)
    begin
        auto_exposure_data <= 18'd0;
    end
    else
    begin
        auto_exposure_data <= auto_exposure_data + auto_exposure_acc;
    end
end

//==================================================================
// auto_exposure_ans
//==================================================================
always @ (*)
begin
    auto_exposure_ans = auto_exposure_data[17:10];
end

//==================================================================
// axi read
//==================================================================
assign arid_s_inf = 4'd0;
assign arlen_s_inf = (state == WAIT_READ)?8'd191:8'd0;
assign arsize_s_inf = (state == WAIT_READ)?3'b100:3'd0;
assign arburst_s_inf = (state == WAIT_READ)?2'b01:2'd0;
assign arvalid_s_inf = (state == WAIT_READ)?1'b1:1'b0;

always @ (*)
begin
    if(state == WAIT_READ)
    begin
        araddr_s_inf[31:16] = 16'd1;
        case(in_pic_no_reg)
        4'd0: araddr_s_inf[15:0] = 16'd0;
        4'd1: araddr_s_inf[15:0] = 16'd3072;
        4'd2: araddr_s_inf[15:0] = 16'd6144;
        4'd3: araddr_s_inf[15:0] = 16'd9216;
        4'd4: araddr_s_inf[15:0] = 16'd12288;
        4'd5: araddr_s_inf[15:0] = 16'd15360;
        4'd6: araddr_s_inf[15:0] = 16'd18432;
        4'd7: araddr_s_inf[15:0] = 16'd21504;
        4'd8: araddr_s_inf[15:0] = 16'd24576;
        4'd9: araddr_s_inf[15:0] = 16'd27648;
        4'd10: araddr_s_inf[15:0] = 16'd30720;
        4'd11: araddr_s_inf[15:0] = 16'd33792;
        4'd12: araddr_s_inf[15:0] = 16'd36864;
        4'd13: araddr_s_inf[15:0] = 16'd39936;
        4'd14: araddr_s_inf[15:0] = 16'd43008;
        4'd15: araddr_s_inf[15:0] = 16'd46080;
        endcase
    end
    else araddr_s_inf[31:0] = 32'd0;
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) rready_s_inf <= 1'b0;
    else if(arready_s_inf == 1'b1) rready_s_inf <= 1'b1;
    else if(rlast_s_inf == 1'b1) rready_s_inf <= 1'b0;
    else rready_s_inf <= rready_s_inf;
end

//==================================================================
// axi write
//==================================================================
assign awid_s_inf = 4'd0;
assign awlen_s_inf = (state == WAIT_WRITE)?8'd191:8'd0;
assign awsize_s_inf = (state == WAIT_WRITE)?3'b100:3'd0;
assign awburst_s_inf = (state == WAIT_WRITE)?2'b01:2'd0;
assign awvalid_s_inf = (state == WAIT_WRITE)?1'b1:1'b0;

always @ (*)
begin
    if(state == WAIT_WRITE)
    begin
        awaddr_s_inf[31:16] = 16'd1;
        case(in_pic_no_reg)
        4'd0: awaddr_s_inf[15:0] = 16'd0;
        4'd1: awaddr_s_inf[15:0] = 16'd3072;
        4'd2: awaddr_s_inf[15:0] = 16'd6144;
        4'd3: awaddr_s_inf[15:0] = 16'd9216;
        4'd4: awaddr_s_inf[15:0] = 16'd12288;
        4'd5: awaddr_s_inf[15:0] = 16'd15360;
        4'd6: awaddr_s_inf[15:0] = 16'd18432;
        4'd7: awaddr_s_inf[15:0] = 16'd21504;
        4'd8: awaddr_s_inf[15:0] = 16'd24576;
        4'd9: awaddr_s_inf[15:0] = 16'd27648;
        4'd10: awaddr_s_inf[15:0] = 16'd30720;
        4'd11: awaddr_s_inf[15:0] = 16'd33792;
        4'd12: awaddr_s_inf[15:0] = 16'd36864;
        4'd13: awaddr_s_inf[15:0] = 16'd39936;
        4'd14: awaddr_s_inf[15:0] = 16'd43008;
        4'd15: awaddr_s_inf[15:0] = 16'd46080;
        endcase
    end
    else awaddr_s_inf[31:0] = 32'd0;
end

always @ (*)
begin
    if(wvalid_s_inf == 1'b1) wdata_s_inf = wdata_s_inf_reg[2];
    else wdata_s_inf = 128'd0;
end

//always @ (posedge clk or negedge rst_n)
//begin
//    if(!rst_n) wlast_s_inf <= 1'b0;
//    else if((rgb_counter == 2'd2) && (input_counter == 6'd63)) wlast_s_inf <= 1'b1;
//    else wlast_s_inf <= 1'b0;
//end
always @ (*)
begin
    if((rgb_counter == 2'd3) && (input_counter == 6'd2)) wlast_s_inf = 1'b1;
    else wlast_s_inf = 1'b0;
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) wvalid_s_inf <= 1'b0;
    else if(rvalid_s_inf == 1'b1) wvalid_s_inf <= 1'b1;
    else if((rgb_counter == 2'd3) && (input_counter == 6'd2)) wvalid_s_inf <= 1'b0;
    else wvalid_s_inf <= wvalid_s_inf;
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n) bready_s_inf <= 1'b0;
    else if(awready_s_inf == 1'b1) bready_s_inf <= 1'b1;
    else if(bvalid_s_inf == 1'b1) bready_s_inf <= 1'b0;
    else bready_s_inf <= bready_s_inf;
end

//==================================================================
// out_valid
//==================================================================
always @ (*)
begin
    if(state == OUT) out_valid = 1'b1;
    else out_valid = 1'b0;
end

//==================================================================
// out_data
//==================================================================
/*always @ (*)
begin
    if(state == OUT)
    begin
        if((read_flag[in_pic_no_reg] == 1'b0) || ((in_mode_reg == 1'b1) && (in_ratio_mode_reg != 2'd2) && (zero_flag[in_pic_no_reg] != 1'b1)))
        begin
            if(in_mode_reg == 1'b0) out_data = {6'd0, auto_focus_ans};
            else out_data = auto_exposure_ans;
        end
        else
        begin
            if(in_mode_reg == 1'b0) out_data = {6'd0, last_auto_focus[in_pic_no_reg]};
            else out_data = last_auto_exposure[in_pic_no_reg];
        end
    end
    else out_data = 8'd0;
end*/
/*always @ (*)
begin
    if(state == OUT)
    begin
        if(in_mode_reg == 1'b0) out_data = {6'd0, last_auto_focus[in_pic_no_reg]};
        else out_data = last_auto_exposure[in_pic_no_reg];
    end
    else out_data = 8'd0;
end*/
always @ (*)
begin
    if((state == SEL) || (cal_counter == 5'd31))
    begin
        if(in_mode_reg == 1'b0) next_out_data_reg = {6'd0, last_auto_focus[in_pic_no_reg]};
        else next_out_data_reg = last_auto_exposure[in_pic_no_reg];
    end
    else next_out_data_reg = out_data_reg;
end
always @ (*)
begin
    if(state == OUT) out_data = out_data_reg;
    else out_data = 8'd0;
end

//==================================================================
// next_read_flag
//==================================================================
always @ (*)
begin
    for(i = 0; i < 16; i = i+1)
    begin
        next_read_flag[i] = read_flag[i];
    end
    if(state == OUT) next_read_flag[in_pic_no_reg] = 1'b1;
end

//==================================================================
// next_zero_flag
//==================================================================
/*always @ (*)
begin
    for(i = 0; i < 16; i = i+1)
    begin
        next_zero_flag[i] = zero_flag[i];
    end
    if((state == OUT) && ((read_flag[in_pic_no_reg] == 1'b0) || ((in_mode_reg == 1'b1) && (in_ratio_mode_reg != 2'd2) && (zero_flag[in_pic_no_reg] != 1'b1))))
    begin
        next_zero_flag[in_pic_no_reg] = zero_flag_now;
    end
end*/
always @ (*)
begin
    for(i = 0; i < 16; i = i+1)
    begin
        next_zero_flag[i] = zero_flag[i];
    end
    if(cal_counter == 5'd30)
    begin
        next_zero_flag[in_pic_no_reg] = zero_flag_now;
    end
end

//==================================================================
// next_zero_flag_now
//==================================================================
always @ (*)
begin
    if(state == WAIT_READ) next_zero_flag_now = 1'b1;
    else if((wvalid_s_inf == 1'b1) && (wdata_s_inf != 128'd0)) next_zero_flag_now = 1'b0;
    else next_zero_flag_now = zero_flag_now;
end

//==================================================================
// next_last_auto_focus
//==================================================================
/*always @ (*)
begin
    for(i = 0; i < 16; i = i+1)
    begin
        next_last_auto_focus[i] = last_auto_focus[i];
    end
    if((state == OUT) && ((read_flag[in_pic_no_reg] == 1'b0) || ((in_mode_reg == 1'b1) && (in_ratio_mode_reg != 2'd2) && (zero_flag[in_pic_no_reg] != 1'b1))))
    begin
        next_last_auto_focus[in_pic_no_reg] = auto_focus_ans;
    end
end*/
always @ (*)
begin
    for(i = 0; i < 16; i = i+1)
    begin
        next_last_auto_focus[i] = last_auto_focus[i];
    end
    if(cal_counter == 5'd30)
    begin
        next_last_auto_focus[in_pic_no_reg] = auto_focus_ans;
    end
end

//==================================================================
// next_last_auto_exposure
//==================================================================
/*always @ (*)
begin
    for(i = 0; i < 16; i = i+1)
    begin
        next_last_auto_exposure[i] = last_auto_exposure[i];
    end
    if((state == OUT) && ((read_flag[in_pic_no_reg] == 1'b0) || ((in_mode_reg == 1'b1) && (in_ratio_mode_reg != 2'd2) && (zero_flag[in_pic_no_reg] != 1'b1))))
    begin
        next_last_auto_exposure[in_pic_no_reg] = auto_exposure_ans;
    end
end*/
always @ (*)
begin
    for(i = 0; i < 16; i = i+1)
    begin
        next_last_auto_exposure[i] = last_auto_exposure[i];
    end
    if(cal_counter == 5'd30)
    begin
        next_last_auto_exposure[in_pic_no_reg] = auto_exposure_ans;
    end
end
endmodule