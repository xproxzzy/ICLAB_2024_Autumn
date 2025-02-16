
// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter MAX_CYCLE=1000;

integer SEED = 1124;
integer PAT_NUM = 5402;

integer i_pat, i, j;
integer latency;
integer total_latency;

//================================================================
// wire & registers 
//================================================================
logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];  // 32 box

//================================================================
// class random
//================================================================

/**
 * Class representing a random action.
 */
class random_act;
    randc Action act_id;
    function new(int SEED);
        this.srandom(SEED);
    endfunction
    constraint range{
        act_id inside{Index_Check, Update, Check_Valid_Date};
    }
endclass

class random_formula;
    randc Data_No formula_reg;
    function new(int SEED);
        this.srandom(SEED);
    endfunction
    constraint formula_range{
        formula_reg inside{Formula_A, Formula_B, Formula_C, Formula_D, Formula_E, Formula_F, Formula_G, Formula_H};
    }
endclass

class random_mode;
    randc Data_No mode_reg;
    function new(int SEED);
        this.srandom(SEED);
    endfunction
    constraint mode_range{
        mode_reg inside{Insensitive, Normal, Sensitive};
    }
endclass

class random_date;
    randc Month month_reg;
    randc Day day_reg;
    function new(int SEED);
        this.srandom(SEED);
    endfunction
    constraint month_range{
        month_reg inside{[1:12]};
    }
    constraint day_range{
        (month_reg == 4'd1) -> day_reg inside{[1:31]};
        (month_reg == 4'd2) -> day_reg inside{[1:28]};
        (month_reg == 4'd3) -> day_reg inside{[1:31]};
        (month_reg == 4'd4) -> day_reg inside{[1:30]};
        (month_reg == 4'd5) -> day_reg inside{[1:31]};
        (month_reg == 4'd6) -> day_reg inside{[1:30]};
        (month_reg == 4'd7) -> day_reg inside{[1:31]};
        (month_reg == 4'd8) -> day_reg inside{[1:31]};
        (month_reg == 4'd9) -> day_reg inside{[1:30]};
        (month_reg == 4'd10) -> day_reg inside{[1:31]};
        (month_reg == 4'd11) -> day_reg inside{[1:30]};
        (month_reg == 4'd12) -> day_reg inside{[1:31]};
    }
endclass

class random_data_no;
    randc Data_No data_no_reg;
    function new(int SEED);
        this.srandom(SEED);
    endfunction
    constraint data_no_range{
        data_no_reg inside{[0:255]};
    }
endclass

class random_index;
    randc Index index_reg;
    function new(int SEED);
        this.srandom(SEED);
    endfunction
    constraint index_range{
        index_reg inside{[0:4095]};
    }
endclass

Action action_reg;
Formula_Type formula_reg;
Mode mode_reg;
Date date_reg;
Data_No data_no_reg;
Index index_reg;

Index input_index_reg [0:3];
logic [63:0] dram_data;
Date dram_date_reg;
Index dram_index_reg [0:3];

logic [11:0] abs_index_reg [0:3];
logic [11:0] sort_a [0:3];
logic [11:0] sort_net [0:3];
logic [11:0] sort_z [0:3];
logic [11:0] comp_a [0:3];
logic [11:0] comp_b [0:3];
logic comp_a_bigger_z [0:3];
logic [13:0] formula_add;
logic [11:0] formula_r;

logic [12:0] add_a [0:3];
logic [12:0] add_b [0:3];
logic [12:0] add_z [0:3];
logic [63:0] w_data_reg;

Warn_Msg golden_warn_msg;
logic golden_complete;

random_act act_random = new(SEED);
random_formula fomula_random = new(SEED);
random_mode mode_random = new(SEED);
random_date date_random = new(SEED);
random_data_no data_no_random = new(SEED);
random_index index_random = new(SEED);

//================================================================
// simulation
//================================================================
initial
begin
    /*act_random = new(SEED);
    fomula_random = new(SEED);
    mode_random = new(SEED);
    date_random = new(SEED);
    data_no_random = new(SEED);
    index_random = new(SEED);*/

    $readmemh(DRAM_p_r, golden_DRAM);

    reset_task;

    for(i_pat = 0; i_pat < PAT_NUM; i_pat = i_pat + 1)
    begin
        @(negedge clk);
        input_task;
        wait_out_valid_task;
        check_ans_task;
    end

    $display("Congratulations");
    $finish;
end

task reset_task;
begin
    inf.rst_n = 1'b1;
    inf.sel_action_valid = 1'd0;
    inf.formula_valid = 1'd0;
    inf.mode_valid = 1'd0;
    inf.date_valid = 1'd0;
    inf.data_no_valid = 1'd0;
    inf.index_valid = 1'd0;
    inf.D = 72'dx;
    #6
    inf.rst_n = 1'b0;
    #24
    inf.rst_n = 1'b1;
end endtask

task input_task;
begin
    if((i_pat >= 0) && (i_pat <= 2999))
    begin
        action_reg = Index_Check;
    end
    else if((i_pat >= 3000) && (i_pat <= 3599))
    begin
        if((i_pat % 2) == 1'b0) action_reg = Check_Valid_Date;
        else action_reg = Index_Check;
    end
    else if((i_pat >= 3600) && (i_pat <= 4199))
    begin
        if((i_pat % 2) == 1'b0) action_reg = Update;
        else action_reg = Index_Check;
    end
    else if((i_pat >= 4200) && (i_pat <= 4499))
    begin
        action_reg = Check_Valid_Date;
    end
    else if((i_pat >= 4500) && (i_pat <= 5101))
    begin
        if((i_pat % 2) == 1'b0) action_reg = Check_Valid_Date;
        else action_reg = Update;
    end
    else if((i_pat >= 5102) && (i_pat <= 5401))
    begin
        action_reg = Update;
    end
    else
    begin
        i = act_random.randomize();
        action_reg = act_random.act_id;
    end

    inf.sel_action_valid = 1'd1;
    inf.D.d_act[0] = action_reg;
    @(negedge clk);
    inf.sel_action_valid = 1'd0;
    inf.D = 72'dx;

    if(action_reg == Index_Check)
    begin
        if((i_pat >= 0) && (i_pat <= 449))
        begin
            formula_reg = Formula_A;
        end
        else if((i_pat >= 450) && (i_pat <= 899))
        begin
            formula_reg = Formula_B;
        end
        else if((i_pat >= 900) && (i_pat <= 1349))
        begin
            formula_reg = Formula_C;
        end
        else if((i_pat >= 1350) && (i_pat <= 1799))
        begin
            formula_reg = Formula_D;
        end
        else if((i_pat >= 1800) && (i_pat <= 2249))
        begin
            formula_reg = Formula_E;
        end
        else if((i_pat >= 2250) && (i_pat <= 2699))
        begin
            formula_reg = Formula_F;
        end
        else if((i_pat >= 2700) && (i_pat <= 3299))
        begin
            formula_reg = Formula_G;
        end
        else if((i_pat >= 3300) && (i_pat <= 4199))
        begin
            formula_reg = Formula_H;
        end
        else
        begin
            i = fomula_random.randomize();
            formula_reg = fomula_random.formula_reg;
        end

        inf.formula_valid = 1'd1;
        inf.D.d_formula[0] = formula_reg;
        @(negedge clk);
        inf.formula_valid = 1'd0;
        inf.D = 72'dx;

        if(((i_pat >= 0) && (i_pat <= 149)) || ((i_pat >= 450) && (i_pat <= 599)) || ((i_pat >= 900) && (i_pat <= 1049)) || ((i_pat >= 1350) && (i_pat <= 1499)) || 
           ((i_pat >= 1800) && (i_pat <= 1949)) || ((i_pat >= 2250) && (i_pat <= 2399)) || ((i_pat >= 2700) && (i_pat <= 2849)) || ((i_pat >= 3300) && (i_pat <= 3599)))
        begin
            mode_reg = Insensitive;
        end
        else if(((i_pat >= 150) && (i_pat <= 299)) || ((i_pat >= 600) && (i_pat <= 749)) || ((i_pat >= 1050) && (i_pat <= 1199)) || ((i_pat >= 1500) && (i_pat <= 1649)) || 
                ((i_pat >= 1950) && (i_pat <= 2099)) || ((i_pat >= 2400) && (i_pat <= 2549)) || ((i_pat >= 2850) && (i_pat <= 2999)) || ((i_pat >= 3600) && (i_pat <= 3899)))
        begin
            mode_reg = Normal;
        end
        else if(((i_pat >= 300) && (i_pat <= 449)) || ((i_pat >= 750) && (i_pat <= 899)) || ((i_pat >= 1200) && (i_pat <= 1349)) || ((i_pat >= 1650) && (i_pat <= 1799)) || 
                ((i_pat >= 2100) && (i_pat <= 2249)) || ((i_pat >= 2550) && (i_pat <= 2699)) || ((i_pat >= 3000) && (i_pat <= 3299)) || ((i_pat >= 3900) && (i_pat <= 4199)))
        begin
            mode_reg = Sensitive;
        end
        else
        begin
            i = mode_random.randomize();
            mode_reg = mode_random.mode_reg;
        end

        inf.mode_valid = 1'd1;
        inf.D.d_mode[0] = mode_reg;
        @(negedge clk);
        inf.mode_valid = 1'd0;
        inf.D = 72'dx;
    end

    if(i_pat < 50)
    begin
        date_reg.M = 4'd8;
        date_reg.D = 5'd18;
    end
    else if(i_pat == 3301)
    begin
        date_reg.M = 4'd12;
        date_reg.D = 5'd31;
    end
    else if((i_pat >= 50) && (i_pat <= 4199))
    begin
        date_reg.M = 4'd5;
        date_reg.D = 5'd16;
    end
    else
    begin
        i = date_random.randomize();
        date_reg.M = date_random.month_reg;
        date_reg.D = date_random.day_reg;
    end

    inf.date_valid = 1'd1;
    inf.D.d_date[0] = date_reg;
    @(negedge clk);
    inf.date_valid = 1'd0;
    inf.D = 72'dx;

    if(i_pat < 50)
    begin
        data_no_reg = 8'd25;
    end
    else if(i_pat == 3301)
    begin
        data_no_reg = 8'd0;
    end
    else if((i_pat >= 50) && (i_pat <= 4199))
    begin
        if(action_reg == Index_Check) data_no_reg = 8'd24;
        else data_no_reg = 8'd1;
    end
    else
    begin
        i = data_no_random.randomize();
        data_no_reg = data_no_random.data_no_reg;
    end

    inf.data_no_valid = 1'd1;
    inf.D.d_data_no[0] = data_no_reg;
    @(negedge clk);
    inf.data_no_valid = 1'd0;
    inf.D = 72'dx;

    if((action_reg == Index_Check) || (action_reg == Update))
    begin
        for(j = 0;j < 4 ; j = j + 1)
        begin
            if(i_pat < 50)
            begin
                case(j)
                0: index_reg = 12'd1270;
                1: index_reg = 12'd1124;
                2: index_reg = 12'd1197;
                3: index_reg = 12'd978;
                endcase
            end
            else if(i_pat == 3301)
            begin
                case(j)
                0: index_reg = 12'd0;
                1: index_reg = 12'd0;
                2: index_reg = 12'd0;
                3: index_reg = 12'd0;
                endcase
            end
            else
            begin
                i = index_random.randomize();
                index_reg = index_random.index_reg;
            end

            input_index_reg[j] = index_reg;

            inf.index_valid = 1'd1;
            inf.D.d_index[0] = index_reg;
            @(negedge clk);
            inf.index_valid = 1'd0;
            inf.D = 72'dx;
        end
    end
end endtask

task wait_out_valid_task;
begin
    latency = 1;
    while (inf.out_valid !== 1'b1) begin
        latency = latency + 1;
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

task check_ans_task;
begin
    golden_warn_msg = No_Warn;
    golden_complete = 1'b0;

    dram_data[63:56] = golden_DRAM[65536 + data_no_reg * 8 + 7];
    dram_data[55:48] = golden_DRAM[65536 + data_no_reg * 8 + 6];
    dram_data[47:40] = golden_DRAM[65536 + data_no_reg * 8 + 5];
    dram_data[39:32] = golden_DRAM[65536 + data_no_reg * 8 + 4];
    dram_data[31:24] = golden_DRAM[65536 + data_no_reg * 8 + 3];
    dram_data[23:16] = golden_DRAM[65536 + data_no_reg * 8 + 2];
    dram_data[15:8] = golden_DRAM[65536 + data_no_reg * 8 + 1];
    dram_data[7:0] = golden_DRAM[65536 + data_no_reg * 8];

    dram_index_reg[0] = dram_data[63:52];
    dram_index_reg[1] = dram_data[51:40];
    dram_date_reg.M = dram_data[35:32];
    dram_index_reg[2] = dram_data[31:20];
    dram_index_reg[3] = dram_data[19:8];
    dram_date_reg.D = dram_data[4:0];

    if(action_reg == Index_Check)
    begin
        if(input_index_reg[0] > dram_index_reg[0]) abs_index_reg[0] = input_index_reg[0] - dram_index_reg[0];
        else abs_index_reg[0] = dram_index_reg[0] - input_index_reg[0];
        if(input_index_reg[1] > dram_index_reg[1]) abs_index_reg[1] = input_index_reg[1] - dram_index_reg[1];
        else abs_index_reg[1] = dram_index_reg[1] - input_index_reg[1];
        if(input_index_reg[2] > dram_index_reg[2]) abs_index_reg[2] = input_index_reg[2] - dram_index_reg[2];
        else abs_index_reg[2] = dram_index_reg[2] - input_index_reg[2];
        if(input_index_reg[3] > dram_index_reg[3]) abs_index_reg[3] = input_index_reg[3] - dram_index_reg[3];
        else abs_index_reg[3] = dram_index_reg[3] - input_index_reg[3];

        if((formula_reg == Formula_B) || (formula_reg == Formula_C))
        begin
            sort_a[0] = dram_index_reg[0];
            sort_a[1] = dram_index_reg[1];
            sort_a[2] = dram_index_reg[2];
            sort_a[3] = dram_index_reg[3];
        end
        else
        begin
            sort_a[0] = abs_index_reg[0];
            sort_a[1] = abs_index_reg[1];
            sort_a[2] = abs_index_reg[2];
            sort_a[3] = abs_index_reg[3];
        end
        
        if(sort_a[1] > sort_a[0])
        begin
            sort_net[1] = sort_a[1];
            sort_net[0] = sort_a[0];
        end
        else
        begin
            sort_net[1] = sort_a[0];
            sort_net[0] = sort_a[1];
        end
        if(sort_a[3] > sort_a[2])
        begin
            sort_net[3] = sort_a[3];
            sort_net[2] = sort_a[2];
        end
        else
        begin
            sort_net[3] = sort_a[2];
            sort_net[2] = sort_a[3];
        end
        if(sort_net[3] > sort_net[1])
        begin
            sort_z[3] = sort_net[3];
            sort_z[1] = sort_net[1];
        end
        else
        begin
            sort_z[3] = sort_net[1];
            sort_z[1] = sort_net[3];
        end
        if(sort_net[2] > sort_net[0])
        begin
            sort_z[2] = sort_net[2];
            sort_z[0] = sort_net[0];
        end
        else
        begin
            sort_z[2] = sort_net[0];
            sort_z[0] = sort_net[2];
        end

        comp_a[0] = dram_index_reg[0];
        comp_a[1] = dram_index_reg[1];
        comp_a[2] = dram_index_reg[2];
        comp_a[3] = dram_index_reg[3];

        if(formula_reg == Formula_D)
        begin
            comp_b[0] = 12'd2047;
            comp_b[1] = 12'd2047;
            comp_b[2] = 12'd2047;
            comp_b[3] = 12'd2047;
        end
        else
        begin
            comp_b[0] = input_index_reg[0];
            comp_b[1] = input_index_reg[1];
            comp_b[2] = input_index_reg[2];
            comp_b[3] = input_index_reg[3];
        end

        if(comp_a[0] >= comp_b[0]) comp_a_bigger_z[0] = 1'b1;
        else comp_a_bigger_z[0] = 1'b0;
        if(comp_a[1] >= comp_b[1]) comp_a_bigger_z[1] = 1'b1;
        else comp_a_bigger_z[1] = 1'b0;
        if(comp_a[2] >= comp_b[2]) comp_a_bigger_z[2] = 1'b1;
        else comp_a_bigger_z[2] = 1'b0;
        if(comp_a[3] >= comp_b[3]) comp_a_bigger_z[3] = 1'b1;
        else comp_a_bigger_z[3] = 1'b0;

        case(formula_reg)
        Formula_A:
        begin
            formula_add = dram_index_reg[0] + dram_index_reg[1] + dram_index_reg[2] + dram_index_reg[3];
            formula_r = formula_add[13:2];
        end
        Formula_B:
        begin
            formula_add = sort_z[3] - sort_z[0];
            formula_r = formula_add[11:0];
        end
        Formula_C:
        begin
            formula_add = sort_z[0];
            formula_r = formula_add[11:0];
        end
        Formula_D, Formula_E:
        begin
            formula_add = comp_a_bigger_z[0] + comp_a_bigger_z[1] + comp_a_bigger_z[2] + comp_a_bigger_z[3];
            formula_r = formula_add[11:0];
        end
        Formula_F:
        begin
            formula_add = sort_z[2] + sort_z[1] + sort_z[0];
            formula_r = formula_add / 3;
        end
        Formula_G:
        begin
            formula_add = sort_z[2][11:2] + sort_z[1][11:2] + sort_z[0][11:1];
            formula_r = formula_add[11:0];
        end
        Formula_H:
        begin
            formula_add = abs_index_reg[3] + abs_index_reg[2] + abs_index_reg[1] + abs_index_reg[0];
            formula_r = formula_add[13:2];
        end
        endcase

        if((date_reg.M < dram_date_reg.M) || ((date_reg.M == dram_date_reg.M) && (date_reg.D < dram_date_reg.D)))
        begin
            golden_warn_msg = Date_Warn;
        end
        else
        begin
            case(mode_reg)
            Insensitive:
            begin
                if((formula_reg == Formula_D) || (formula_reg == Formula_E))
                begin
                    if(formula_r >= 12'd3) golden_warn_msg = Risk_Warn;
                end
                else if((formula_reg == Formula_A) || (formula_reg == Formula_C))
                begin
                    if(formula_r >= 12'd2047) golden_warn_msg = Risk_Warn;
                end
                else
                begin
                    if(formula_r >= 12'd800) golden_warn_msg = Risk_Warn;
                end
            end
            Normal:
            begin
                if((formula_reg == Formula_D) || (formula_reg == Formula_E))
                begin
                    if(formula_r >= 12'd2) golden_warn_msg = Risk_Warn;
                end
                else if((formula_reg == Formula_A) || (formula_reg == Formula_C))
                begin
                    if(formula_r >= 12'd1023) golden_warn_msg = Risk_Warn;
                end
                else
                begin
                    if(formula_r >= 12'd400) golden_warn_msg = Risk_Warn;
                end
            end
            Sensitive:
            begin
                if((formula_reg == Formula_D) || (formula_reg == Formula_E))
                begin
                    if(formula_r >= 12'd1) golden_warn_msg = Risk_Warn;
                end
                else if((formula_reg == Formula_A) || (formula_reg == Formula_C))
                begin
                    if(formula_r >= 12'd511) golden_warn_msg = Risk_Warn;
                end
                else
                begin
                    if(formula_r >= 12'd200) golden_warn_msg = Risk_Warn;
                end
            end
            endcase
        end
    end
    else if(action_reg == Update)
    begin
        add_a[0] = {1'b0, dram_index_reg[0]};
        add_b[0] = {input_index_reg[0][11], input_index_reg[0]};
        add_a[1] = {1'b0, dram_index_reg[1]};
        add_b[1] = {input_index_reg[1][11], input_index_reg[1]};
        add_a[2] = {1'b0, dram_index_reg[2]};
        add_b[2] = {input_index_reg[2][11], input_index_reg[2]};
        add_a[3] = {1'b0, dram_index_reg[3]};
        add_b[3] = {input_index_reg[3][11], input_index_reg[3]};
        
        add_z[0] = add_a[0] + add_b[0];
        add_z[1] = add_a[1] + add_b[1];
        add_z[2] = add_a[2] + add_b[2];
        add_z[3] = add_a[3] + add_b[3];

        if(add_z[0][12] || add_z[1][12] || add_z[2][12] || add_z[3][12]) golden_warn_msg = Data_Warn;

        if(add_z[0][12])
        begin
            if(input_index_reg[0][11]) w_data_reg[63:52] = 12'd0;
            else w_data_reg[63:52] = 12'd4095;
        end
        else w_data_reg[63:52] = add_z[0][11:0];
        if(add_z[1][12])
        begin
            if(input_index_reg[1][11]) w_data_reg[51:40] = 12'd0;
            else w_data_reg[51:40] = 12'd4095;
        end
        else w_data_reg[51:40] = add_z[1][11:0];

        w_data_reg[39:32] = {4'd0, date_reg.M};

        if(add_z[2][12])
        begin
            if(input_index_reg[2][11]) w_data_reg[31:20] = 12'd0;
            else w_data_reg[31:20] = 12'd4095;
        end
        else w_data_reg[31:20] = add_z[2][11:0];
        if(add_z[3][12])
        begin
            if(input_index_reg[3][11]) w_data_reg[19:8] = 12'd0;
            else w_data_reg[19:8] = 12'd4095;
        end
        else w_data_reg[19:8] = add_z[3][11:0];

        w_data_reg[7:0] = {3'd0, date_reg.D};

        golden_DRAM[65536 + data_no_reg * 8 + 7] = w_data_reg[63:56];
        golden_DRAM[65536 + data_no_reg * 8 + 6] = w_data_reg[55:48];
        golden_DRAM[65536 + data_no_reg * 8 + 5] = w_data_reg[47:40];
        golden_DRAM[65536 + data_no_reg * 8 + 4] = w_data_reg[39:32];
        golden_DRAM[65536 + data_no_reg * 8 + 3] = w_data_reg[31:24];
        golden_DRAM[65536 + data_no_reg * 8 + 2] = w_data_reg[23:16];
        golden_DRAM[65536 + data_no_reg * 8 + 1] = w_data_reg[15:8];
        golden_DRAM[65536 + data_no_reg * 8] = w_data_reg[7:0];
    end
    else if(action_reg == Check_Valid_Date)
    begin
        if((date_reg.M < dram_date_reg.M) || ((date_reg.M == dram_date_reg.M) && (date_reg.D < dram_date_reg.D)))
        begin
            golden_warn_msg = Date_Warn;
        end
    end

    if(golden_warn_msg == No_Warn) golden_complete = 1'b1;
    else golden_complete = 1'b0;

    if((inf.warn_msg !== golden_warn_msg) || (inf.complete !== golden_complete))
    begin
        $display("Wrong Answer");
        $finish;
    end
    //else
    //begin
    //    $display(i_pat, "WARN:", golden_warn_msg, "ACT:", action_reg);
    //end
end endtask

endprogram
