/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

// integer fp_w;

// initial begin
// fp_w = $fopen("out_valid.txt", "w");
// end

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */

class Formula_and_mode;
    Formula_Type f_type;
    Mode f_mode;
endclass

Formula_and_mode fm_info = new();

Action action_reg;
Action action_comb;
Mode mode_comb;
Formula_Type formula_reg;
Formula_Type formula_comb;
Index index_comb;
Warn_Msg warn_comb;

always_comb action_comb = inf.D.d_act[0];
always_comb mode_comb = inf.D.d_mode[0];
always_comb formula_comb = inf.D.d_formula[0];
always_comb index_comb = inf.D.d_index[0];
always_comb warn_comb = inf.warn_msg;

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) action_reg <= 2'd0;
    else
    begin
        if(inf.sel_action_valid) action_reg <= inf.D.d_act[0];
        else action_reg <= action_reg;
    end
end

always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) formula_reg <= 3'd0;
    else
    begin
        if(inf.formula_valid) formula_reg <= inf.D.d_formula[0];
        else formula_reg <= formula_reg;
    end
end

//==================================================================
// Coverage
//==================================================================
covergroup SPEC1 @ (posedge clk iff(inf.formula_valid));
    option.per_instance = 1;
    option.at_least = 150;
    coverpoint formula_comb
    {
        bins bins_formula [] = {[Formula_A:Formula_H]};
    }
endgroup

covergroup SPEC2 @ (posedge clk iff(inf.mode_valid));
    option.per_instance = 1;
    option.at_least = 150;
    coverpoint mode_comb
    {
        bins bins_mode [] = {[Insensitive:Sensitive]};
    }
endgroup

covergroup SPEC3 @ (posedge clk iff(inf.mode_valid));
    option.per_instance = 1;
    option.at_least = 150;
    coverpoint formula_reg;
    coverpoint mode_comb;
    cross formula_reg, mode_comb;
endgroup

covergroup SPEC4 @ (negedge clk iff(inf.out_valid));
    option.per_instance = 1;
    option.at_least = 50;
    coverpoint warn_comb
    {
        bins bins_warn [] = {[No_Warn:Data_Warn]};
    }
endgroup

covergroup SPEC5 @ (posedge clk iff(inf.sel_action_valid));
    option.per_instance = 1;
    option.at_least = 300;
    coverpoint action_comb
    {
        bins bins_act [] = ([Index_Check:Check_Valid_Date] => [Index_Check:Check_Valid_Date]);
    }
endgroup

covergroup SPEC6 @ (posedge clk iff(inf.index_valid && (action_reg == Update)));
    option.per_instance = 1;
    option.at_least = 1;
    coverpoint index_comb
    {
        option.auto_bin_max = 32;
    }
endgroup

SPEC1 SPEC1_inst = new();
SPEC2 SPEC2_inst = new();
SPEC3 SPEC3_inst = new();
SPEC4 SPEC4_inst = new();
SPEC5 SPEC5_inst = new();
SPEC6 SPEC6_inst = new();
//==================================================================
// Assertions
//==================================================================
//==================================================================
// SPEC_1
//==================================================================
property SPEC_1;
    @ (posedge inf.rst_n) (inf.rst_n === 1'b0) |-> ((inf.out_valid === 1'b0) && (inf.warn_msg === No_Warn) && (inf.complete === 1'b0) && 
                                     (inf.AR_VALID === 1'b0) && (inf.AR_ADDR === 17'd0) && (inf.R_READY === 1'b0) && 
                                     (inf.AW_VALID === 1'b0) && (inf.AW_ADDR === 17'b0) && (inf.W_VALID === 1'b0) && (inf.W_DATA === 1'b0) && (inf.B_READY === 1'b0));
endproperty

assert property (SPEC_1) else $fatal(0, "Assertion 1 is violated");

//==================================================================
// SPEC_2
//==================================================================
logic [2:0] index_valid_counter;
always_ff @ (posedge clk or negedge inf.rst_n)
begin
    if(!inf.rst_n) index_valid_counter <= 3'd0;
    else if(inf.out_valid) index_valid_counter <= 3'd0;
    else if(inf.index_valid) index_valid_counter <= index_valid_counter + 3'd1;
    else index_valid_counter <= index_valid_counter;
end

property SPEC_2;
    @ (posedge clk) (((action_reg === Index_Check) && (index_valid_counter === 3'd4)) || ((action_reg === Update) && (index_valid_counter === 3'd4)) || ((action_reg === Check_Valid_Date) && (inf.data_no_valid === 1'b1))) |-> ##[1:1000] inf.out_valid;
endproperty

assert property (SPEC_2) else $fatal(0, "Assertion 2 is violated");

//==================================================================
// SPEC_3
//==================================================================
property SPEC_3;
    @ (negedge clk) (inf.complete === 1'b1) |-> (inf.warn_msg === No_Warn);
endproperty

assert property (SPEC_3) else $fatal(0, "Assertion 3 is violated");

//==================================================================
// SPEC_4
//==================================================================
property SPEC_4_INDEX_CHECK;
    @ (posedge clk) ((inf.sel_action_valid === 1'b1) && (inf.D.d_act[0] === Index_Check)) |-> ##[1:4] (inf.formula_valid === 1'b1) ##[1:4] (inf.mode_valid === 1'b1) ##[1:4] (inf.date_valid === 1'b1) ##[1:4] (inf.data_no_valid === 1'b1) ##[1:4] (inf.index_valid === 1'b1) ##[1:4] (inf.index_valid === 1'b1) ##[1:4] (inf.index_valid === 1'b1) ##[1:4] (inf.index_valid === 1'b1);
endproperty

property SPEC_4_UPDATE;
    @ (posedge clk) ((inf.sel_action_valid === 1'b1) && (inf.D.d_act[0] === Update)) |-> ##[1:4] (inf.date_valid === 1'b1) ##[1:4] (inf.data_no_valid === 1'b1) ##[1:4] (inf.index_valid === 1'b1) ##[1:4] (inf.index_valid === 1'b1) ##[1:4] (inf.index_valid === 1'b1) ##[1:4] (inf.index_valid === 1'b1);
endproperty

property SPEC_4_CHECK_VALID_DATE;
    @ (posedge clk) ((inf.sel_action_valid === 1'b1) && (inf.D.d_act[0] === Check_Valid_Date)) |-> ##[1:4] (inf.date_valid === 1'b1) ##[1:4] (inf.data_no_valid === 1'b1);
endproperty

property SPEC_4;
    SPEC_4_INDEX_CHECK and SPEC_4_UPDATE and SPEC_4_CHECK_VALID_DATE;
endproperty

assert property (SPEC_4) else $fatal(0, "Assertion 4 is violated");

//==================================================================
// SPEC_5
//==================================================================
property SPEC_5_SEL_ACTION_VALID;
    @ (posedge clk) (inf.sel_action_valid === 1'b1) |-> ((inf.formula_valid === 1'b0) && (inf.mode_valid === 1'b0) && (inf.date_valid === 1'b0) && (inf.data_no_valid === 1'b0) && (inf.index_valid === 1'b0));
endproperty

property SPEC_5_FORMULA_VALID;
    @ (posedge clk) (inf.formula_valid === 1'b1) |-> ((inf.sel_action_valid === 1'b0) && (inf.mode_valid === 1'b0) && (inf.date_valid === 1'b0) && (inf.data_no_valid === 1'b0) && (inf.index_valid === 1'b0));
endproperty

property SPEC_5_MODE_VALID;
    @ (posedge clk) (inf.mode_valid === 1'b1) |-> ((inf.sel_action_valid === 1'b0) && (inf.formula_valid === 1'b0) && (inf.date_valid === 1'b0) && (inf.data_no_valid === 1'b0) && (inf.index_valid === 1'b0));
endproperty

property SPEC_5_DATE_VALID;
    @ (posedge clk) (inf.date_valid === 1'b1) |-> ((inf.sel_action_valid === 1'b0) && (inf.formula_valid === 1'b0) && (inf.mode_valid === 1'b0) && (inf.data_no_valid === 1'b0) && (inf.index_valid === 1'b0));
endproperty

property SPEC_5_DATA_NO_VALID;
    @ (posedge clk) (inf.data_no_valid === 1'b1) |-> ((inf.sel_action_valid === 1'b0) && (inf.formula_valid === 1'b0) && (inf.mode_valid === 1'b0) && (inf.date_valid === 1'b0) && (inf.index_valid === 1'b0));
endproperty

property SPEC_5_INDEX_VALID;
    @ (posedge clk) (inf.index_valid === 1'b1) |-> ((inf.sel_action_valid === 1'b0) && (inf.formula_valid === 1'b0) && (inf.mode_valid === 1'b0) && (inf.date_valid === 1'b0) && (inf.data_no_valid === 1'b0));
endproperty

property SPEC_5;
    SPEC_5_SEL_ACTION_VALID and SPEC_5_FORMULA_VALID and SPEC_5_MODE_VALID and SPEC_5_DATE_VALID and SPEC_5_DATA_NO_VALID and SPEC_5_INDEX_VALID;
endproperty

assert property (SPEC_5) else $fatal(0, "Assertion 5 is violated");

//==================================================================
// SPEC_6
//==================================================================
property SPEC_6;
    @ (posedge clk) (inf.out_valid === 1'b1) |-> ##1 (inf.out_valid === 1'b0);
endproperty

assert property (SPEC_6) else $fatal(0, "Assertion 6 is violated");

//==================================================================
// SPEC_7
//==================================================================
property SPEC_7;
    @ (posedge clk) (inf.out_valid === 1'b1) |-> ##[1:4] (inf.sel_action_valid === 1'b1);
endproperty

assert property (SPEC_7) else $fatal(0, "Assertion 7 is violated");

//==================================================================
// SPEC_8
//==================================================================
property SPEC_8;
    @ (posedge clk) (inf.date_valid === 1'b1) |-> (((inf.D.d_date[0].M === 4'd1) && (inf.D.d_date[0].D !== 5'd0) && (inf.D.d_date[0].D <= 5'd31)) || 
                                                   ((inf.D.d_date[0].M === 4'd2) && (inf.D.d_date[0].D !== 5'd0) && (inf.D.d_date[0].D <= 5'd28)) || 
                                                   ((inf.D.d_date[0].M === 4'd3) && (inf.D.d_date[0].D !== 5'd0) && (inf.D.d_date[0].D <= 5'd31)) || 
                                                   ((inf.D.d_date[0].M === 4'd4) && (inf.D.d_date[0].D !== 5'd0) && (inf.D.d_date[0].D <= 5'd30)) || 
                                                   ((inf.D.d_date[0].M === 4'd5) && (inf.D.d_date[0].D !== 5'd0) && (inf.D.d_date[0].D <= 5'd31)) || 
                                                   ((inf.D.d_date[0].M === 4'd6) && (inf.D.d_date[0].D !== 5'd0) && (inf.D.d_date[0].D <= 5'd30)) || 
                                                   ((inf.D.d_date[0].M === 4'd7) && (inf.D.d_date[0].D !== 5'd0) && (inf.D.d_date[0].D <= 5'd31)) || 
                                                   ((inf.D.d_date[0].M === 4'd8) && (inf.D.d_date[0].D !== 5'd0) && (inf.D.d_date[0].D <= 5'd31)) || 
                                                   ((inf.D.d_date[0].M === 4'd9) && (inf.D.d_date[0].D !== 5'd0) && (inf.D.d_date[0].D <= 5'd30)) || 
                                                   ((inf.D.d_date[0].M === 4'd10) && (inf.D.d_date[0].D !== 5'd0) && (inf.D.d_date[0].D <= 5'd31)) || 
                                                   ((inf.D.d_date[0].M === 4'd11) && (inf.D.d_date[0].D !== 5'd0) && (inf.D.d_date[0].D <= 5'd30)) || 
                                                   ((inf.D.d_date[0].M === 4'd12) && (inf.D.d_date[0].D !== 5'd0) && (inf.D.d_date[0].D <= 5'd31)));
endproperty

assert property (SPEC_8) else $fatal(0, "Assertion 8 is violated");

//==================================================================
// SPEC_9
//==================================================================
property SPEC_9_AR_VALID;
    @ (posedge clk) (inf.AR_VALID === 1'b1) |-> (inf.AW_VALID === 1'b0);
endproperty

property SPEC_9_AW_VALID;
    @ (posedge clk) (inf.AW_VALID === 1'b1) |-> (inf.AR_VALID === 1'b0);
endproperty

property SPEC_9;
    SPEC_9_AR_VALID and SPEC_9_AW_VALID;
endproperty

assert property (SPEC_9) else $fatal(0, "Assertion 9 is violated");

endmodule