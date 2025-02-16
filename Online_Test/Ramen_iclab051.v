module Ramen(
    // Input Registers
    input clk, 
    input rst_n, 
    input in_valid,
    input selling,
    input portion, 
    input [1:0] ramen_type,

    // Output Signals
    output reg out_valid_order,
    output reg success,

    output reg out_valid_tot,
    output reg [27:0] sold_num,
    output reg [14:0] total_gain
);


//==============================================//
//             Parameter and Integer            //
//==============================================//

// ramen_type
parameter TONKOTSU = 0;
parameter TONKOTSU_SOY = 1;
parameter MISO = 2;
parameter MISO_SOY = 3;

// initial ingredient
parameter NOODLE_INIT = 12000;
parameter BROTH_INIT = 41000;
parameter TONKOTSU_SOUP_INIT =  9000;
parameter MISO_INIT = 1000;
parameter SOY_SAUSE_INIT = 1500;

parameter IDLE = 0;
parameter GET = 1;
parameter JUDGE = 2;
parameter CAL = 3;
parameter IDLE2 = 4;
parameter OUT_ORDER_OK = 5;
parameter OUT_ORDER_NOT = 6;
parameter OUT_TOTAL = 7;

//==============================================//
//                 reg declaration              //
//==============================================// 
reg [2:0] state;
reg [2:0] next_state;
reg invald_counter;
reg next_invald_counter;
reg [1:0] ramen_type_reg;
reg [1:0] next_ramen_type_reg;
reg portion_reg;
reg next_portion_reg;
reg [27:0] sold_num_reg;
reg [27:0] next_sold_num_reg;

reg [13:0] noodle_reg;
reg [15:0] broth_reg;
reg [13:0] tonkotsu_soup_reg;
reg [10:0] soy_sauce_reg;
reg [9:0] miso_reg;

reg [13:0] next_noodle_reg;
reg [15:0] next_broth_reg;
reg [13:0] next_tonkotsu_soup_reg;
reg [10:0] next_soy_sauce_reg;
reg [9:0] next_miso_reg;

//==============================================//
//                    Design                    //
//==============================================//
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state <= IDLE;
        invald_counter <= 1'd0;
        ramen_type_reg <= 2'd0;
        portion_reg <= 1'd0;
        sold_num_reg <= 28'd0;
        noodle_reg <= 14'd0;
        broth_reg <= 16'd0;
        tonkotsu_soup_reg <= 14'd0;
        soy_sauce_reg <= 11'd0;
        miso_reg <= 10'd0;
    end
    else
    begin
        state <= next_state;
        invald_counter <= next_invald_counter;
        ramen_type_reg <= next_ramen_type_reg;
        portion_reg <= next_portion_reg;
        sold_num_reg <= next_sold_num_reg;
        noodle_reg <= next_noodle_reg;
        broth_reg <= next_broth_reg;
        tonkotsu_soup_reg <= next_tonkotsu_soup_reg;
        soy_sauce_reg <= next_soy_sauce_reg;
        miso_reg <= next_miso_reg;
    end
end

always @ (*)
begin
    case(state)
    IDLE:
    begin
        if(selling == 1) next_state = GET;
        else next_state = IDLE;
    end
    GET:
    begin
        next_state = JUDGE;
    end
    JUDGE:
    begin
        case(ramen_type_reg)
        TONKOTSU:
        begin
            if(portion_reg == 0) //small
            begin
                if((noodle_reg >= 100) && (broth_reg >= 300) && (tonkotsu_soup_reg >= 150)) next_state = CAL;
                else next_state = OUT_ORDER_NOT;
            end
            else //big
            begin
                if((noodle_reg >= 150) && (broth_reg >= 500) && (tonkotsu_soup_reg >= 200)) next_state = CAL;
                else next_state = OUT_ORDER_NOT;
            end
        end
        TONKOTSU_SOY:
        begin
            if(portion_reg == 0) //small
            begin
                if((noodle_reg >= 100) && (broth_reg >= 300) && (tonkotsu_soup_reg >= 100) && (soy_sauce_reg >= 30)) next_state = CAL;
                else next_state = OUT_ORDER_NOT;
            end
            else //big
            begin
                if((noodle_reg >= 150) && (broth_reg >= 500) && (tonkotsu_soup_reg >= 150) && (soy_sauce_reg >= 50)) next_state = CAL;
                else next_state = OUT_ORDER_NOT;
            end
        end
        MISO:
        begin
            if(portion_reg == 0) //small
            begin
                if((noodle_reg >= 100) && (broth_reg >= 400) && (miso_reg >= 30)) next_state = CAL;
                else next_state = OUT_ORDER_NOT;
            end
            else //big
            begin
                if((noodle_reg >= 150) && (broth_reg >= 650) && (miso_reg >= 50)) next_state = CAL;
                else next_state = OUT_ORDER_NOT;
            end
        end
        MISO_SOY:
        begin
            if(portion_reg == 0) //small
            begin
                if((noodle_reg >= 100) && (broth_reg >= 300) && (tonkotsu_soup_reg >= 70) && (soy_sauce_reg >= 15) && (miso_reg >= 15)) next_state = CAL;
                else next_state = OUT_ORDER_NOT;
            end
            else //big
            begin
                if((noodle_reg >= 150) && (broth_reg >= 500) && (tonkotsu_soup_reg >= 100) && (soy_sauce_reg >= 25) && (miso_reg >= 25)) next_state = CAL;
                else next_state = OUT_ORDER_NOT;
            end
        end
        default:
        begin
            next_state = OUT_ORDER_NOT;
        end
        endcase
    end
    CAL:
    begin
        next_state = OUT_ORDER_OK;
    end
    IDLE2:
    begin
        if(in_valid) next_state = GET;
        else if(selling == 0) next_state = OUT_TOTAL;
        else next_state = IDLE2;
    end
    OUT_ORDER_OK:
    begin
        next_state = IDLE2;
    end
    OUT_ORDER_NOT:
    begin
        next_state = IDLE2;
    end
    OUT_TOTAL:
    begin
        next_state = IDLE;
    end
    default:
    begin
        next_state = IDLE;
    end
    endcase
end

always @ (*)
begin
    if(in_valid) next_invald_counter = invald_counter+1;
    else next_invald_counter = 0;
end

always @ (*)
begin
    if(in_valid && (invald_counter == 0)) next_ramen_type_reg = ramen_type;
    else if(state == CAL) next_ramen_type_reg = 0;
    else next_ramen_type_reg = ramen_type_reg;
end

always @ (*)
begin
    if(in_valid && (invald_counter == 1)) next_portion_reg = portion;
    else if(state == CAL) next_portion_reg = 0;
    else next_portion_reg = portion_reg;
end

always @ (*)
begin
    if(selling == 0)
    begin
        next_noodle_reg = 14'd12000;
        next_broth_reg = 16'd41000;
        next_tonkotsu_soup_reg = 14'd9000;
        next_soy_sauce_reg = 11'd1500;
        next_miso_reg = 10'd1000;
    end
    else if(state == CAL)
    begin
        case(ramen_type_reg)
        TONKOTSU:
        begin
            if(portion_reg == 0) //small
            begin
                next_noodle_reg = noodle_reg - 100;
                next_broth_reg = broth_reg - 300;
                next_tonkotsu_soup_reg = tonkotsu_soup_reg - 150;
                next_soy_sauce_reg = soy_sauce_reg;
                next_miso_reg = miso_reg;
            end
            else //big
            begin
                next_noodle_reg = noodle_reg - 150;
                next_broth_reg = broth_reg - 500;
                next_tonkotsu_soup_reg = tonkotsu_soup_reg - 200;
                next_soy_sauce_reg = soy_sauce_reg;
                next_miso_reg = miso_reg;
            end
        end
        TONKOTSU_SOY:
        begin
            if(portion_reg == 0) //small
            begin
                next_noodle_reg = noodle_reg - 100;
                next_broth_reg = broth_reg - 300;
                next_tonkotsu_soup_reg = tonkotsu_soup_reg - 100;
                next_soy_sauce_reg = soy_sauce_reg - 30;
                next_miso_reg = miso_reg;
            end
            else //big
            begin
                next_noodle_reg = noodle_reg - 150;
                next_broth_reg = broth_reg - 500;
                next_tonkotsu_soup_reg = tonkotsu_soup_reg - 150;
                next_soy_sauce_reg = soy_sauce_reg - 50;
                next_miso_reg = miso_reg;
            end
        end
        MISO:
        begin
            if(portion_reg == 0) //small
            begin
                next_noodle_reg = noodle_reg - 100;
                next_broth_reg = broth_reg - 400;
                next_tonkotsu_soup_reg = tonkotsu_soup_reg;
                next_soy_sauce_reg = soy_sauce_reg;
                next_miso_reg = miso_reg - 30;
            end
            else //big
            begin
                next_noodle_reg = noodle_reg - 150;
                next_broth_reg = broth_reg - 650;
                next_tonkotsu_soup_reg = tonkotsu_soup_reg;
                next_soy_sauce_reg = soy_sauce_reg;
                next_miso_reg = miso_reg - 50;
            end
        end
        MISO_SOY:
        begin
            if(portion_reg == 0) //small
            begin
                next_noodle_reg = noodle_reg - 100;
                next_broth_reg = broth_reg - 300;
                next_tonkotsu_soup_reg = tonkotsu_soup_reg - 70;
                next_soy_sauce_reg = soy_sauce_reg - 15;
                next_miso_reg = miso_reg - 15;
            end
            else //big
            begin
                next_noodle_reg = noodle_reg - 150;
                next_broth_reg = broth_reg - 500;
                next_tonkotsu_soup_reg = tonkotsu_soup_reg - 100;
                next_soy_sauce_reg = soy_sauce_reg - 25;
                next_miso_reg = miso_reg - 25;
            end
        end
        default:
        begin
            next_noodle_reg = noodle_reg;
            next_broth_reg = broth_reg;
            next_tonkotsu_soup_reg = tonkotsu_soup_reg;
            next_soy_sauce_reg = soy_sauce_reg;
            next_miso_reg = miso_reg;
        end
        endcase
    end
    else
    begin
        next_noodle_reg = noodle_reg;
        next_broth_reg = broth_reg;
        next_tonkotsu_soup_reg = tonkotsu_soup_reg;
        next_soy_sauce_reg = soy_sauce_reg;
        next_miso_reg = miso_reg;
    end
end

always @ (*)
begin
    if(state == IDLE)
    begin
        next_sold_num_reg = 0;
    end
    else if(state == CAL)
    begin
        case(ramen_type_reg)
        TONKOTSU:
        begin
            next_sold_num_reg = sold_num_reg;
            next_sold_num_reg[27:21] = sold_num_reg[27:21] + 1;
        end
        TONKOTSU_SOY:
        begin
            next_sold_num_reg = sold_num_reg;
            next_sold_num_reg[20:14] = sold_num_reg[20:14] + 1;
        end
        MISO:
        begin
            next_sold_num_reg = sold_num_reg;
            next_sold_num_reg[13:7] = sold_num_reg[13:7] + 1;
        end
        MISO_SOY:
        begin
            next_sold_num_reg = sold_num_reg;
            next_sold_num_reg[6:0] = sold_num_reg[6:0] + 1;
        end
        default:
        begin
            next_sold_num_reg = sold_num_reg;
        end
        endcase
    end
    else
    begin
        next_sold_num_reg = sold_num_reg;
    end
end

always @ (*)
begin
    if((state == OUT_ORDER_OK) || (state == OUT_ORDER_NOT)) out_valid_order = 1;
    else out_valid_order = 0;
end

always @ (*)
begin
    if(state == OUT_ORDER_OK) success = 1;
    else success = 0;
end

always @ (*)
begin
    if(state == OUT_TOTAL) out_valid_tot = 1;
    else out_valid_tot = 0;
end

always @ (*)
begin
    if(state == OUT_TOTAL)
    begin
        sold_num = sold_num_reg;
    end
    else sold_num = 0;
end

always @ (*)
begin
    if(state == OUT_TOTAL)
    begin
        total_gain = next_sold_num_reg[27:21] * 200
                   + next_sold_num_reg[20:14] * 250
                   + next_sold_num_reg[13:7] * 200
                   + next_sold_num_reg[6:0] * 250;
    end
    else total_gain = 0;
end

endmodule
