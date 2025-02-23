module Program(input clk, INF.Program_inf inf);
import usertype::*;

//==================================================================
// reg & wire
//==================================================================
State state;
Action action_reg;
Formula_Type formula_reg;
Mode mode_reg;
Data_No date_no_reg;
Data_Dir input_data_dir_reg;
Data_Dir dram_data_dir_reg;

Warn_Msg warn_reg;

logic [11:0] comp_a [0:3];
logic [11:0] comp_b [0:3];
logic comp_a_bigger_z [0:3];
logic comp_a_bigger_z_reg [0:3];

logic [12:0] add_sub_a [0:3];
logic [12:0] add_sub_b [0:3];
logic add_sub_ctrl;
logic [12:0] add_sub_z [0:3];
logic [12:0] add_sub_z_reg [0:3];

logic [11:0] sort_a [0:3];
logic [11:0] sort_net [0:3];
logic [11:0] sort_net_reg [0:3];
logic [11:0] sort_z [0:3];
logic [11:0] sort_z_reg [0:3];

logic [13:0] formula_add;
logic [13:0] formula_add_reg;
logic [11:0] formula_r;
logic [11:0] formula_r_reg;

logic [63:0] w_data_reg;
//==================================================================
// state
//==================================================================
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) state <= IDLE;
    else
    begin
        case(state)
        IDLE:
        begin
            if(inf.sel_action_valid) state <= READ_FORMULA;
            else state <= IDLE;
        end
        READ_FORMULA:
        begin
            if(inf.formula_valid) state <= READ_MODE;
            else if(inf.date_valid) state <= READ_NO;
            else state <= READ_FORMULA;
        end
        READ_MODE:
        begin
            if(inf.mode_valid) state <= READ_DATE;
            else state <= READ_MODE;
        end
        READ_DATE:
        begin
            if(inf.date_valid) state <= READ_NO;
            else state <= READ_DATE;
        end
        READ_NO:
        begin
            if(inf.data_no_valid)
            begin
                if(action_reg == Check_Valid_Date) state <= ADDR_READ;
                else state <= READ_A;
            end
            else state <= READ_NO;
        end
        READ_A:
        begin
            if(inf.index_valid) state <= READ_B;
            else state <= READ_A;
        end
        READ_B:
        begin
            if(inf.index_valid) state <= READ_C;
            else state <= READ_B;
        end
        READ_C:
        begin
            if(inf.index_valid) state <= READ_D;
            else state <= READ_C;
        end
        READ_D:
        begin
            if(inf.index_valid) state <= ADDR_READ;
            else state <= READ_D;
        end
        ADDR_READ:
        begin
            if(inf.AR_READY) state <= WAIT_READ;
            else state <= ADDR_READ;
        end
        WAIT_READ:
        begin
            if(inf.R_VALID)
            begin
                if(action_reg == Update) state <= CAL_G_VAR;
                else state <= DATE_WARN;
            end
            else state <= WAIT_READ;
        end
        DATE_WARN:
        begin
            if(action_reg == Index_Check)
            begin
                if((input_data_dir_reg.M < dram_data_dir_reg.M) || ((input_data_dir_reg.M == dram_data_dir_reg.M) && (input_data_dir_reg.D < dram_data_dir_reg.D))) state <= OUT;
                else state <= CAL_G_VAR;
            end
            else state <= OUT;
        end
        CAL_G_VAR:
        begin
            if(action_reg == Update) state <= DATA_WARN;
            else state <= MAX_MIN_A;
        end
        MAX_MIN_A:
        begin
            state <= MAX_MIN;
        end
        MAX_MIN:
        begin
            state <= FORMULA_ADD;
        end
        FORMULA_ADD:
        begin
            state <= FORMULA;
        end
        FORMULA:
        begin
            state <= DATA_WARN;
        end
        DATA_WARN:
        begin
            if(action_reg == Update) state <= ADDR_WRITE;
            else state <= OUT;
        end
        ADDR_WRITE:
        begin
            if(inf.AW_READY) state <= WAIT_WRITE;
            else state <= ADDR_WRITE;
        end
        WAIT_WRITE:
        begin
            if(inf.W_READY) state <= RESP_WRITE;
            else state <= WAIT_WRITE;
        end
        RESP_WRITE:
        begin
            if(inf.B_VALID) state <= OUT;
            else state <= RESP_WRITE;
        end
        OUT:
        begin
            state <= IDLE;
        end
        default: state <= IDLE;
        endcase
    end
end

//==================================================================
// reg
//==================================================================
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) action_reg <= Index_Check;
    else
    begin
        if(inf.sel_action_valid) action_reg <= inf.D.d_act[0];
        else action_reg <= action_reg;
    end
end

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) formula_reg <= Formula_A;
    else
    begin
        if(inf.formula_valid) formula_reg <= inf.D.d_formula[0];
        else formula_reg <= formula_reg;
    end
end

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) mode_reg <= Insensitive;
    else
    begin
        if(inf.mode_valid) mode_reg <= inf.D.d_mode[0];
        else mode_reg <= mode_reg;
    end
end

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        input_data_dir_reg.M <= 4'd0;
        input_data_dir_reg.D <= 5'd0;
    end
    else
    begin
        if(inf.date_valid)
        begin
            input_data_dir_reg.M <= inf.D.d_date[0].M;
            input_data_dir_reg.D <= inf.D.d_date[0].D;
        end
        else
        begin
            input_data_dir_reg.M <= input_data_dir_reg.M;
            input_data_dir_reg.D <= input_data_dir_reg.D;
        end
    end
end

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) date_no_reg <= 2'd0;
    else
    begin
        if(inf.data_no_valid) date_no_reg <= inf.D.d_data_no[0];
        else date_no_reg <= date_no_reg;
    end
end

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        input_data_dir_reg.Index_A <= 12'd0;
        input_data_dir_reg.Index_B <= 12'd0;
        input_data_dir_reg.Index_C <= 12'd0;
        input_data_dir_reg.Index_D <= 12'd0;
    end
    else
    begin
        if(inf.index_valid)
        begin
            if(state == READ_A) input_data_dir_reg.Index_A <= inf.D.d_index[0];
            else input_data_dir_reg.Index_A <= input_data_dir_reg.Index_A;
            if(state == READ_B) input_data_dir_reg.Index_B <= inf.D.d_index[0];
            else input_data_dir_reg.Index_B <= input_data_dir_reg.Index_B;
            if(state == READ_C) input_data_dir_reg.Index_C <= inf.D.d_index[0];
            else input_data_dir_reg.Index_C <= input_data_dir_reg.Index_C;
            if(state == READ_D) input_data_dir_reg.Index_D <= inf.D.d_index[0];
            else input_data_dir_reg.Index_D <= input_data_dir_reg.Index_D;
        end
        else
        begin
            input_data_dir_reg.Index_A <= input_data_dir_reg.Index_A;
            input_data_dir_reg.Index_B <= input_data_dir_reg.Index_B;
            input_data_dir_reg.Index_C <= input_data_dir_reg.Index_C;
            input_data_dir_reg.Index_D <= input_data_dir_reg.Index_D;
        end
    end
end

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        dram_data_dir_reg.Index_A <= 12'd0;
        dram_data_dir_reg.Index_B <= 12'd0;
        dram_data_dir_reg.M <= 4'd0;
        dram_data_dir_reg.Index_C <= 12'd0;
        dram_data_dir_reg.Index_D <= 12'd0;
        dram_data_dir_reg.D <= 5'd0;
    end
    else
    begin
        if(inf.R_VALID)
        begin
            dram_data_dir_reg.Index_A <= inf.R_DATA[63:52];
            dram_data_dir_reg.Index_B <= inf.R_DATA[51:40];
            dram_data_dir_reg.M <= inf.R_DATA[35:32];
            dram_data_dir_reg.Index_C <= inf.R_DATA[31:20];
            dram_data_dir_reg.Index_D <= inf.R_DATA[19:8];
            dram_data_dir_reg.D <= inf.R_DATA[4:0];
        end
        else
        begin
            dram_data_dir_reg.Index_A <= dram_data_dir_reg.Index_A;
            dram_data_dir_reg.Index_B <= dram_data_dir_reg.Index_B;
            dram_data_dir_reg.M <= dram_data_dir_reg.M;
            dram_data_dir_reg.Index_C <= dram_data_dir_reg.Index_C;
            dram_data_dir_reg.Index_D <= dram_data_dir_reg.Index_D;
            dram_data_dir_reg.D <= dram_data_dir_reg.D;
        end
    end
end

//==================================================================
// warn_reg
//==================================================================
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        warn_reg <= No_Warn;
    end
    else
    begin
        if(state == OUT)
        begin
            warn_reg <= No_Warn;
        end
        else if(state == DATE_WARN)
        begin
            if((input_data_dir_reg.M < dram_data_dir_reg.M) || ((input_data_dir_reg.M == dram_data_dir_reg.M) && (input_data_dir_reg.D < dram_data_dir_reg.D))) warn_reg <= Date_Warn;
            else warn_reg <= No_Warn;
        end
        else if(state == DATA_WARN)
        begin
            if(action_reg == Index_Check)
            begin
                case(mode_reg)
                Insensitive:
                begin
                    if((formula_reg == Formula_D) || (formula_reg == Formula_E))
                    begin
                        if(formula_r_reg >= 12'd3) warn_reg <= Risk_Warn;
                        else warn_reg <= warn_reg;
                    end
                    else if((formula_reg == Formula_A) || (formula_reg == Formula_C))
                    begin
                        if(formula_r_reg >= 12'd2047) warn_reg <= Risk_Warn;
                        else warn_reg <= warn_reg;
                    end
                    else
                    begin
                        if(formula_r_reg >= 12'd800) warn_reg <= Risk_Warn;
                        else warn_reg <= warn_reg;
                    end
                end
                Normal:
                begin
                    if((formula_reg == Formula_D) || (formula_reg == Formula_E))
                    begin
                        if(formula_r_reg >= 12'd2) warn_reg <= Risk_Warn;
                        else warn_reg <= warn_reg;
                    end
                    else if((formula_reg == Formula_A) || (formula_reg == Formula_C))
                    begin
                        if(formula_r_reg >= 12'd1023) warn_reg <= Risk_Warn;
                        else warn_reg <= warn_reg;
                    end
                    else
                    begin
                        if(formula_r_reg >= 12'd400) warn_reg <= Risk_Warn;
                        else warn_reg <= warn_reg;
                    end
                end
                Sensitive:
                begin
                    if((formula_reg == Formula_D) || (formula_reg == Formula_E))
                    begin
                        if(formula_r_reg >= 12'd1) warn_reg <= Risk_Warn;
                        else warn_reg <= warn_reg;
                    end
                    else if((formula_reg == Formula_A) || (formula_reg == Formula_C))
                    begin
                        if(formula_r_reg >= 12'd511) warn_reg <= Risk_Warn;
                        else warn_reg <= warn_reg;
                    end
                    else
                    begin
                        if(formula_r_reg >= 12'd200) warn_reg <= Risk_Warn;
                        else warn_reg <= warn_reg;
                    end
                end
                default: warn_reg <= warn_reg;
                endcase
            end
            else
            begin
                if(add_sub_z_reg[0][12] || add_sub_z_reg[1][12] || add_sub_z_reg[2][12] || add_sub_z_reg[3][12]) warn_reg <= Data_Warn;
                else warn_reg <= warn_reg;
            end
        end
        else
        begin
            warn_reg <= warn_reg;
        end
    end
end

//==================================================================
// add_sub
//==================================================================
always_comb
begin
    comp_a[0] = dram_data_dir_reg.Index_A;
    comp_a[1] = dram_data_dir_reg.Index_B;
    comp_a[2] = dram_data_dir_reg.Index_C;
    comp_a[3] = dram_data_dir_reg.Index_D;
end
always_comb
begin
    if(formula_reg == Formula_D)
    begin
        comp_b[0] = 12'd2047;
        comp_b[1] = 12'd2047;
        comp_b[2] = 12'd2047;
        comp_b[3] = 12'd2047;
    end
    else
    begin
        comp_b[0] = input_data_dir_reg.Index_A;
        comp_b[1] = input_data_dir_reg.Index_B;
        comp_b[2] = input_data_dir_reg.Index_C;
        comp_b[3] = input_data_dir_reg.Index_D;
    end
end

always_comb
begin
    if(comp_a[0] >= comp_b[0]) comp_a_bigger_z[0] = 1'b1;
    else comp_a_bigger_z[0] = 1'b0;
end
always_comb
begin
    if(comp_a[1] >= comp_b[1]) comp_a_bigger_z[1] = 1'b1;
    else comp_a_bigger_z[1] = 1'b0;
end
always_comb
begin
    if(comp_a[2] >= comp_b[2]) comp_a_bigger_z[2] = 1'b1;
    else comp_a_bigger_z[2] = 1'b0;
end
always_comb
begin
    if(comp_a[3] >= comp_b[3]) comp_a_bigger_z[3] = 1'b1;
    else comp_a_bigger_z[3] = 1'b0;
end

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        comp_a_bigger_z_reg[0] <= 1'b0;
        comp_a_bigger_z_reg[1] <= 1'b0;
        comp_a_bigger_z_reg[2] <= 1'b0;
        comp_a_bigger_z_reg[3] <= 1'b0;
    end
    else if(state == CAL_G_VAR)
    begin
        comp_a_bigger_z_reg[0] <= comp_a_bigger_z[0];
        comp_a_bigger_z_reg[1] <= comp_a_bigger_z[1];
        comp_a_bigger_z_reg[2] <= comp_a_bigger_z[2];
        comp_a_bigger_z_reg[3] <= comp_a_bigger_z[3];
    end
    else
    begin
        comp_a_bigger_z_reg[0] <= comp_a_bigger_z_reg[0];
        comp_a_bigger_z_reg[1] <= comp_a_bigger_z_reg[1];
        comp_a_bigger_z_reg[2] <= comp_a_bigger_z_reg[2];
        comp_a_bigger_z_reg[3] <= comp_a_bigger_z_reg[3];
    end
end

always_comb
begin
    if(action_reg == Index_Check)
    begin
        if(comp_a_bigger_z[0])
        begin
            add_sub_a[0] = {1'b0, dram_data_dir_reg.Index_A};
            add_sub_b[0] = {1'b0, input_data_dir_reg.Index_A};
        end
        else
        begin
            add_sub_a[0] = {1'b0, input_data_dir_reg.Index_A};
            add_sub_b[0] = {1'b0, dram_data_dir_reg.Index_A};
        end
        if(comp_a_bigger_z[1])
        begin
            add_sub_a[1] = {1'b0, dram_data_dir_reg.Index_B};
            add_sub_b[1] = {1'b0, input_data_dir_reg.Index_B};
        end
        else
        begin
            add_sub_a[1] = {1'b0, input_data_dir_reg.Index_B};
            add_sub_b[1] = {1'b0, dram_data_dir_reg.Index_B};
        end
        if(comp_a_bigger_z[2])
        begin
            add_sub_a[2] = {1'b0, dram_data_dir_reg.Index_C};
            add_sub_b[2] = {1'b0, input_data_dir_reg.Index_C};
        end
        else
        begin
            add_sub_a[2] = {1'b0, input_data_dir_reg.Index_C};
            add_sub_b[2] = {1'b0, dram_data_dir_reg.Index_C};
        end
        if(comp_a_bigger_z[3])
        begin
            add_sub_a[3] = {1'b0, dram_data_dir_reg.Index_D};
            add_sub_b[3] = {1'b0, input_data_dir_reg.Index_D};
        end
        else
        begin
            add_sub_a[3] = {1'b0, input_data_dir_reg.Index_D};
            add_sub_b[3] = {1'b0, dram_data_dir_reg.Index_D};
        end
    end
    else
    begin
        add_sub_a[0] = {1'b0, dram_data_dir_reg.Index_A};
        add_sub_b[0] = {input_data_dir_reg.Index_A[11], input_data_dir_reg.Index_A};
        add_sub_a[1] = {1'b0, dram_data_dir_reg.Index_B};
        add_sub_b[1] = {input_data_dir_reg.Index_B[11], input_data_dir_reg.Index_B};
        add_sub_a[2] = {1'b0, dram_data_dir_reg.Index_C};
        add_sub_b[2] = {input_data_dir_reg.Index_C[11], input_data_dir_reg.Index_C};
        add_sub_a[3] = {1'b0, dram_data_dir_reg.Index_D};
        add_sub_b[3] = {input_data_dir_reg.Index_D[11], input_data_dir_reg.Index_D};
    end
end

always_comb
begin
    if(action_reg == Index_Check) add_sub_ctrl = 1'b1;
    else add_sub_ctrl = 1'b0;
end

always_comb
begin
    if(add_sub_ctrl == 0) add_sub_z[0] = add_sub_a[0] + add_sub_b[0];
    else add_sub_z[0] = add_sub_a[0] - add_sub_b[0];
end
always_comb
begin
    if(add_sub_ctrl == 0) add_sub_z[1] = add_sub_a[1] + add_sub_b[1];
    else add_sub_z[1] = add_sub_a[1] - add_sub_b[1];
end
always_comb
begin
    if(add_sub_ctrl == 0) add_sub_z[2] = add_sub_a[2] + add_sub_b[2];
    else add_sub_z[2] = add_sub_a[2] - add_sub_b[2];
end
always_comb
begin
    if(add_sub_ctrl == 0) add_sub_z[3] = add_sub_a[3] + add_sub_b[3];
    else add_sub_z[3] = add_sub_a[3] - add_sub_b[3];
end

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        add_sub_z_reg[0] <= 13'd0;
        add_sub_z_reg[1] <= 13'd0;
        add_sub_z_reg[2] <= 13'd0;
        add_sub_z_reg[3] <= 13'd0;
    end
    else if(state == CAL_G_VAR)
    begin
        add_sub_z_reg[0] <= add_sub_z[0];
        add_sub_z_reg[1] <= add_sub_z[1];
        add_sub_z_reg[2] <= add_sub_z[2];
        add_sub_z_reg[3] <= add_sub_z[3];
    end
    else
    begin
        add_sub_z_reg[0] <= add_sub_z_reg[0];
        add_sub_z_reg[1] <= add_sub_z_reg[1];
        add_sub_z_reg[2] <= add_sub_z_reg[2];
        add_sub_z_reg[3] <= add_sub_z_reg[3];
    end
end

//==================================================================
// sort
//==================================================================
always_comb
begin
    if(action_reg == Index_Check)
    begin
        if((formula_reg == Formula_B) || (formula_reg == Formula_C))
        begin
            sort_a[0] = dram_data_dir_reg.Index_A;
            sort_a[1] = dram_data_dir_reg.Index_B;
            sort_a[2] = dram_data_dir_reg.Index_C;
            sort_a[3] = dram_data_dir_reg.Index_D;
        end
        else
        begin
            sort_a[0] = add_sub_z_reg[0][11:0];
            sort_a[1] = add_sub_z_reg[1][11:0];
            sort_a[2] = add_sub_z_reg[2][11:0];
            sort_a[3] = add_sub_z_reg[3][11:0];
        end
    end
    else
    begin
        sort_a[0] = 13'd0;
        sort_a[1] = 13'd0;
        sort_a[2] = 13'd0;
        sort_a[3] = 13'd0;
    end
end

always_comb
begin
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
end
always_comb
begin
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
end

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        sort_net_reg[0] <= 12'd0;
        sort_net_reg[1] <= 12'd0;
        sort_net_reg[2] <= 12'd0;
        sort_net_reg[3] <= 12'd0;
    end
    else if(state == MAX_MIN_A)
    begin
        sort_net_reg[0] <= sort_net[0];
        sort_net_reg[1] <= sort_net[1];
        sort_net_reg[2] <= sort_net[2];
        sort_net_reg[3] <= sort_net[3];
    end
    else
    begin
        sort_net_reg[0] <= sort_net_reg[0];
        sort_net_reg[1] <= sort_net_reg[1];
        sort_net_reg[2] <= sort_net_reg[2];
        sort_net_reg[3] <= sort_net_reg[3];
    end
end

always_comb
begin
    if(sort_net_reg[3] > sort_net_reg[1])
    begin
        sort_z[3] = sort_net_reg[3];
        sort_z[1] = sort_net_reg[1];
    end
    else
    begin
        sort_z[3] = sort_net_reg[1];
        sort_z[1] = sort_net_reg[3];
    end
end
always_comb
begin
    if(sort_net_reg[2] > sort_net_reg[0])
    begin
        sort_z[2] = sort_net_reg[2];
        sort_z[0] = sort_net_reg[0];
    end
    else
    begin
        sort_z[2] = sort_net_reg[0];
        sort_z[0] = sort_net_reg[2];
    end
end

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        sort_z_reg[0] <= 12'd0;
        sort_z_reg[1] <= 12'd0;
        sort_z_reg[2] <= 12'd0;
        sort_z_reg[3] <= 12'd0;
    end
    else if(state == MAX_MIN)
    begin
        sort_z_reg[0] <= sort_z[0];
        sort_z_reg[1] <= sort_z[1];
        sort_z_reg[2] <= sort_z[2];
        sort_z_reg[3] <= sort_z[3];
    end
    else
    begin
        sort_z_reg[0] <= sort_z_reg[0];
        sort_z_reg[1] <= sort_z_reg[1];
        sort_z_reg[2] <= sort_z_reg[2];
        sort_z_reg[3] <= sort_z_reg[3];
    end
end

//==================================================================
// formula
//==================================================================
/*always_comb
begin
    case(formula_reg)
    Formula_A:
    begin
        formula_add = dram_data_dir_reg.Index_A + dram_data_dir_reg.Index_B + dram_data_dir_reg.Index_C + dram_data_dir_reg.Index_D;
        formula_r = formula_add[13:2];
    end
    Formula_B:
    begin
        formula_add = sort_z_reg[3] - sort_z_reg[0];
        formula_r = formula_add[11:0];
    end
    Formula_C:
    begin
        formula_add = sort_z_reg[0];
        formula_r = formula_add[11:0];
    end
    Formula_D, Formula_E:
    begin
        formula_add = comp_a_bigger_z_reg[0] + comp_a_bigger_z_reg[1] + comp_a_bigger_z_reg[2] + comp_a_bigger_z_reg[3];
        formula_r = formula_add[11:0];
    end
    Formula_F:
    begin
        formula_add = sort_z_reg[2] + sort_z_reg[1] + sort_z_reg[0];
        formula_r = formula_add / 3;
    end
    Formula_G:
    begin
        formula_add = sort_z_reg[2][11:2] + sort_z_reg[1][11:2] + sort_z_reg[0][11:1];
        formula_r = formula_add[11:0];
    end
    Formula_H:
    begin
        formula_add = sort_z_reg[3] + sort_z_reg[2] + sort_z_reg[1] + sort_z_reg[0];
        formula_r = formula_add[13:2];
    end
    endcase
end*/

always_comb
begin
    case(formula_reg)
    Formula_A:
    begin
        formula_add = dram_data_dir_reg.Index_A + dram_data_dir_reg.Index_B + dram_data_dir_reg.Index_C + dram_data_dir_reg.Index_D;
    end
    Formula_B:
    begin
        formula_add = sort_z_reg[3] - sort_z_reg[0];
    end
    Formula_C:
    begin
        formula_add = sort_z_reg[0];
    end
    Formula_D, Formula_E:
    begin
        formula_add = comp_a_bigger_z_reg[0] + comp_a_bigger_z_reg[1] + comp_a_bigger_z_reg[2] + comp_a_bigger_z_reg[3];
    end
    Formula_F:
    begin
        formula_add = sort_z_reg[2] + sort_z_reg[1] + sort_z_reg[0];
    end
    Formula_G:
    begin
        formula_add = sort_z_reg[2][11:2] + sort_z_reg[1][11:2] + sort_z_reg[0][11:1];
    end
    Formula_H:
    begin
        formula_add = sort_z_reg[3] + sort_z_reg[2] + sort_z_reg[1] + sort_z_reg[0];
    end
    endcase
end

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        formula_add_reg <= 12'd0;
    end
    else if(state == FORMULA_ADD)
    begin
        formula_add_reg <= formula_add;
    end
    else
    begin
        formula_add_reg <= formula_add_reg;
    end
end

always_comb
begin
    case(formula_reg)
    Formula_A:
    begin
        formula_r = formula_add_reg[13:2];
    end
    Formula_B:
    begin
        formula_r = formula_add_reg[11:0];
    end
    Formula_C:
    begin
        formula_r = formula_add_reg[11:0];
    end
    Formula_D, Formula_E:
    begin
        formula_r = formula_add_reg[11:0];
    end
    Formula_F:
    begin
        formula_r = formula_add_reg / 3;
    end
    Formula_G:
    begin
        formula_r = formula_add_reg[11:0];
    end
    Formula_H:
    begin
        formula_r = formula_add_reg[13:2];
    end
    endcase
end

/*always_comb
begin
    if(formula_reg == Formula_F)
    begin
        formula_r = formula_add_reg / 3;
    end
    else
    begin
        case(formula_reg)
        Formula_A:
        begin
            formula_r = formula_add_reg[13:2];
        end
        Formula_B:
        begin
            formula_r = formula_add_reg[11:0];
        end
        Formula_C:
        begin
            formula_r = formula_add_reg[11:0];
        end
        Formula_D, Formula_E:
        begin
            formula_r = formula_add_reg[11:0];
        end
        Formula_G:
        begin
            formula_r = formula_add_reg[11:0];
        end
        Formula_H:
        begin
            formula_r = formula_add_reg[13:2];
        end
        default:
        begin
            formula_r = formula_add_reg[13:2];
        end
        endcase
    end
end*/

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        formula_r_reg <= 12'd0;
    end
    else if(state == FORMULA)
    begin
        formula_r_reg <= formula_r;
    end
    else
    begin
        formula_r_reg <= formula_r_reg;
    end
end

//==================================================================
// out
//==================================================================
always_comb
begin
    if(state == OUT) inf.out_valid = 1'b1;
    else inf.out_valid = 1'b0;
end

always_comb
begin
    if(state == OUT) inf.warn_msg = warn_reg;
    else inf.warn_msg = No_Warn;
end

always_comb
begin
    if((state == OUT) && (warn_reg == No_Warn)) inf.complete = 1'b1;
    else inf.complete = 1'b0;
end

//==================================================================
// w_data_reg
//==================================================================
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n)
    begin
        w_data_reg <= 64'd0;
    end
    else if(state == ADDR_WRITE)
    begin
        if(add_sub_z_reg[0][12])
        begin
            if(input_data_dir_reg.Index_A[11]) w_data_reg[63:52] <= 12'd0;
            else w_data_reg[63:52] <= 12'd4095;
        end
        else w_data_reg[63:52] <= add_sub_z_reg[0][11:0];
        if(add_sub_z_reg[1][12])
        begin
            if(input_data_dir_reg.Index_B[11]) w_data_reg[51:40] <= 12'd0;
            else w_data_reg[51:40] <= 12'd4095;
        end
        else w_data_reg[51:40] <= add_sub_z_reg[1][11:0];

        w_data_reg[39:32] <= {4'd0, input_data_dir_reg.M};

        if(add_sub_z_reg[2][12])
        begin
            if(input_data_dir_reg.Index_C[11]) w_data_reg[31:20] <= 12'd0;
            else w_data_reg[31:20] <= 12'd4095;
        end
        else w_data_reg[31:20] <= add_sub_z_reg[2][11:0];
        if(add_sub_z_reg[3][12])
        begin
            if(input_data_dir_reg.Index_D[11]) w_data_reg[19:8] <= 12'd0;
            else w_data_reg[19:8] <= 12'd4095;
        end
        else w_data_reg[19:8] <= add_sub_z_reg[3][11:0];

        w_data_reg[7:0] <= {3'd0, input_data_dir_reg.D};
    end
    else w_data_reg <= w_data_reg;
end

//==================================================================
// AXI READ
//==================================================================
always_comb
begin
    if(state == ADDR_READ) inf.AR_VALID = 1'b1;
    else inf.AR_VALID = 1'b0;
end
always_comb
begin
    if(state == ADDR_READ) inf.AR_ADDR = {6'b100000, date_no_reg, 3'd0};
    else inf.AR_ADDR = 17'd0;
end
always_comb
begin
    if(state == WAIT_READ) inf.R_READY = 1'b1;
    else inf.R_READY = 1'b0;
end

//==================================================================
// AXI WRITE
//==================================================================
always_comb
begin
    if(state == ADDR_WRITE) inf.AW_VALID = 1'b1;
    else inf.AW_VALID = 1'b0;
end
always_comb
begin
    if(state == ADDR_WRITE) inf.AW_ADDR = {6'b100000, date_no_reg, 3'd0};
    else inf.AW_ADDR = 17'd0;
end
always_comb
begin
    if(state == WAIT_WRITE) inf.W_VALID = 1'b1;
    else inf.W_VALID = 1'b0;
end
always_comb
begin
    if(state == WAIT_WRITE) inf.W_DATA = w_data_reg;
    else inf.W_DATA = 64'd0;
end
always_comb
begin
    if((state == WAIT_WRITE) || (state == RESP_WRITE)) inf.B_READY = 1'b1;
    else inf.B_READY = 1'b0;
end

endmodule
