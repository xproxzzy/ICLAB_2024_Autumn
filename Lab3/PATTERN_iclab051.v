/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: PATTERN
// FILE NAME: PATTERN.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / PATTERN
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

`ifdef RTL
    `define CYCLE_TIME 40.0
`endif
`ifdef GATE
    `define CYCLE_TIME 8.3
`endif

module PATTERN(
	//OUTPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//INPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
output reg			rst_n, clk, in_valid;
output reg	[2:0]	tetrominoes;
output reg  [2:0]	position;
input 				tetris_valid, score_valid, fail;
input 		[3:0]	score;
input		[71:0]	tetris;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer input_file;
integer total_latency;
real CYCLE = `CYCLE_TIME;
integer i_pat, a;
integer f_in;
integer latency;
integer patnum;
integer i, j;
integer now_pat;

integer total_score;
integer minimum_latency;
//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg last_tetris_valid;
reg last_score_valid;
reg tetris_valid_gold, score_valid_gold, fail_gold;
reg [3:0] score_gold;
reg [71:0] tetris_gold;
reg [5:0] tetris_now [15:0];
reg [3:0] top [5:0];
reg [3:0] highest_top;
reg	[2:0] tetrominoes_after_fail;
reg [2:0] position_after_fail;

//---------------------------------------------------------------------
//  CLOCK
//---------------------------------------------------------------------
always #(CYCLE/2.0) clk = ~clk;

//---------------------------------------------------------------------
//  SIMULATION
//---------------------------------------------------------------------
initial
begin
    f_in = $fopen("../00_TESTBED/input.txt", "r");
    if(f_in == 0)
	begin
        $display("Failed to open input.txt");
        $finish;
    end

	rst_n = 1'b1;
	in_valid = 1'b0;
	tetrominoes = 3'bxxx;
	position = 3'bxxx;
	total_latency = 0;

    total_score = 0;
    minimum_latency = 0;

	force clk = 0;

	#0.5;
    rst_n = 1'b0;
    #50;
    check_spec_4;
    #10;
    rst_n = 1'b1;

    #3;
    release clk;

    check_spec_5;
    check_spec_8;
    @(negedge clk);
    check_spec_5;
    check_spec_8;
    @(negedge clk);
    check_spec_5;
    check_spec_8;
    @(negedge clk);
    check_spec_5;
    check_spec_8;
    @(negedge clk);
    check_spec_5;
    check_spec_8;
    @(negedge clk);
    check_spec_5;
    check_spec_8;
    @(negedge clk);
    check_spec_5;
    check_spec_8;
    @(negedge clk);
    check_spec_5;
    check_spec_8;
    @(negedge clk);
    check_spec_5;
    check_spec_8;
    @(negedge clk);
    check_spec_5;
    check_spec_8;
    @(negedge clk);

	a = $fscanf(f_in, "%d", patnum);

	for(i_pat = 0; i_pat < patnum; i_pat = i_pat + 1)
	begin
		a = $fscanf(f_in, "%d", now_pat);

        reset_gold;

		for(i = 0; i < 16; i++)
		begin
            input_task;
            wait_score_valid_task;

            check_spec_5;
            check_ans_task; //spec7
            check_spec_8;
            @(negedge clk);

            if(fail_gold === 1'b1)
            begin
                i++;
                for(; i < 16; i++)
		        begin
                    a = $fscanf(f_in, "%d", tetrominoes_after_fail);
	                a = $fscanf(f_in, "%d", position_after_fail);
                    /*$monitor("tetrominoes_after_fail change to value %d at the time %t.", tetrominoes_after_fail, $time);
                    #1
                    $monitor("position_after_fail change to value %d at the time %t.", position_after_fail, $time);
                    #1;*/
                end
            end

            check_spec_5;
            check_spec_8;
            @(negedge clk);
            check_spec_5;
            check_spec_8;
            @(negedge clk);
            check_spec_5;
            check_spec_8;
            @(negedge clk);
		end
	end
	YOU_PASS_task;
end

task reset_gold;
begin
    tetris_valid_gold = 1'b0;
	score_valid_gold = 1'b0;
	fail_gold = 1'b0;
	score_gold = 4'd0;
	tetris_now[0] = 6'd0;
	tetris_now[1] = 6'd0;
	tetris_now[2] = 6'd0;
	tetris_now[3] = 6'd0;
	tetris_now[4] = 6'd0;
	tetris_now[5] = 6'd0;
	tetris_now[6] = 6'd0;
	tetris_now[7] = 6'd0;
	tetris_now[8] = 6'd0;
	tetris_now[9] = 6'd0;
	tetris_now[10] = 6'd0;
	tetris_now[11] = 6'd0;
	tetris_now[12] = 6'd0;
	tetris_now[13] = 6'd0;
	tetris_now[14] = 6'd0;
	tetris_now[15] = 6'd0;
	top[0] = 4'd0;
	top[1] = 4'd0;
	top[2] = 4'd0;
	top[3] = 4'd0;
	top[4] = 4'd0;
	top[5] = 4'd0;
	highest_top = 6'd0;
end endtask

task input_task;
begin
    a = $fscanf(f_in, "%d", tetrominoes);
	a = $fscanf(f_in, "%d", position);
	in_valid = 1'b1;

    minimum_latency = minimum_latency + 2;

    put_tetris_in;
	score_and_shift;
    set_top;
	determine_fail;

    check_spec_5;
    check_spec_8;
	@(negedge clk);
	tetrominoes = 3'bxxx;
	position = 3'bxxx;
	in_valid = 1'b0;
end endtask

task put_tetris_in;
begin
    case(tetrominoes)
		3'd0:
		begin
			highest_top = (top[position] > top[position + 1])?top[position]:top[position + 1];
			tetris_now[highest_top][position] = 1'b1;
			tetris_now[highest_top+1][position] = 1'b1;
			tetris_now[highest_top][position+1] = 1'b1;
			tetris_now[highest_top+1][position+1] = 1'b1;
			top[position] = highest_top + 2;
			top[position+1] = highest_top + 2;
		end
		3'd1:
		begin
			highest_top = top[position];
			tetris_now[highest_top][position] = 1'b1;
			tetris_now[highest_top+1][position] = 1'b1;
			tetris_now[highest_top+2][position] = 1'b1;
			tetris_now[highest_top+3][position] = 1'b1;
			top[position] = highest_top + 4;
		end
		3'd2:
		begin
			if((top[position] >= top[position+1]) && (top[position] >= top[position+2]) && (top[position] >= top[position+3]))
			begin
				highest_top = top[position];
			end
			else if((top[position+1] >= top[position+2]) && (top[position+1] >= top[position+3]))
			begin
				highest_top = top[position+1];
			end
			else if(top[position+2] >= top[position+3])
			begin
				highest_top = top[position+2];
			end
			else
			begin
				highest_top = top[position+3];
			end
			tetris_now[highest_top][position] = 1'b1;
			tetris_now[highest_top][position+1] = 1'b1;
			tetris_now[highest_top][position+2] = 1'b1;
			tetris_now[highest_top][position+3] = 1'b1;
			top[position] = highest_top + 1;
			top[position+1] = highest_top + 1;
			top[position+2] = highest_top + 1;
			top[position+3] = highest_top + 1;
		end
		3'd3:
		begin
			if(top[position] >= (top[position+1]+2))
			begin
				highest_top = top[position];
				tetris_now[highest_top][position] = 1'b1;
				tetris_now[highest_top][position+1] = 1'b1;
				tetris_now[highest_top-1][position+1] = 1'b1;
				tetris_now[highest_top-2][position+1] = 1'b1;
				top[position] = highest_top + 1;
				top[position+1] = highest_top + 1;
			end
			else
			begin
				highest_top = top[position+1];
				tetris_now[highest_top+2][position] = 1'b1;
				tetris_now[highest_top][position+1] = 1'b1;
				tetris_now[highest_top+1][position+1] = 1'b1;
				tetris_now[highest_top+2][position+1] = 1'b1;
				top[position] = highest_top + 3;
				top[position+1] = highest_top + 3;
			end
		end
		3'd4:
		begin
            if(((top[position]+1) >= top[position+1]) && ((top[position]+1) >= top[position+2]))
			begin
				highest_top = top[position];
				tetris_now[highest_top][position] = 1'b1;
				tetris_now[highest_top+1][position] = 1'b1;
				tetris_now[highest_top+1][position+1] = 1'b1;
				tetris_now[highest_top+1][position+2] = 1'b1;
				top[position] = highest_top + 2;
				top[position+1] = highest_top + 2;
                top[position+2] = highest_top + 2;
			end
            else if(top[position+1] >= top[position+2])
			begin
				highest_top = top[position+1];
				tetris_now[highest_top-1][position] = 1'b1;
				tetris_now[highest_top][position] = 1'b1;
				tetris_now[highest_top][position+1] = 1'b1;
				tetris_now[highest_top][position+2] = 1'b1;
				top[position] = highest_top + 1;
				top[position+1] = highest_top + 1;
                top[position+2] = highest_top + 1;
			end
			else
			begin
				highest_top = top[position+2];
				tetris_now[highest_top-1][position] = 1'b1;
				tetris_now[highest_top][position] = 1'b1;
				tetris_now[highest_top][position+1] = 1'b1;
				tetris_now[highest_top][position+2] = 1'b1;
				top[position] = highest_top + 1;
				top[position+1] = highest_top + 1;
                top[position+2] = highest_top + 1;
			end
		end
		3'd5:
		begin
            highest_top = (top[position] > top[position + 1])?top[position]:top[position + 1];
			tetris_now[highest_top][position] = 1'b1;
			tetris_now[highest_top+1][position] = 1'b1;
			tetris_now[highest_top+2][position] = 1'b1;
			tetris_now[highest_top][position+1] = 1'b1;
			top[position] = highest_top + 3;
			top[position+1] = highest_top + 1;
		end
		3'd6:
		begin
            if(top[position] >= (top[position+1]+1))
			begin
				highest_top = top[position];
				tetris_now[highest_top][position] = 1'b1;
				tetris_now[highest_top+1][position] = 1'b1;
				tetris_now[highest_top][position+1] = 1'b1;
				tetris_now[highest_top-1][position+1] = 1'b1;
				top[position] = highest_top + 2;
				top[position+1] = highest_top + 1;
			end
			else
			begin
				highest_top = top[position+1];
				tetris_now[highest_top+1][position] = 1'b1;
				tetris_now[highest_top+2][position] = 1'b1;
				tetris_now[highest_top][position+1] = 1'b1;
				tetris_now[highest_top+1][position+1] = 1'b1;
				top[position] = highest_top + 3;
				top[position+1] = highest_top + 2;
			end
		end
		3'd7:
		begin
            if((top[position] >= top[position+1]) && ((top[position]+1) >= top[position+2]))
			begin
				highest_top = top[position];
				tetris_now[highest_top][position] = 1'b1;
				tetris_now[highest_top][position+1] = 1'b1;
				tetris_now[highest_top+1][position+1] = 1'b1;
				tetris_now[highest_top+1][position+2] = 1'b1;
				top[position] = highest_top + 1;
				top[position+1] = highest_top + 2;
                top[position+2] = highest_top + 2;
			end
            else if((top[position+1]+1) >= top[position+2])
			begin
				highest_top = top[position+1];
				tetris_now[highest_top][position] = 1'b1;
				tetris_now[highest_top][position+1] = 1'b1;
				tetris_now[highest_top+1][position+1] = 1'b1;
				tetris_now[highest_top+1][position+2] = 1'b1;
				top[position] = highest_top + 1;
				top[position+1] = highest_top + 2;
                top[position+2] = highest_top + 2;
			end
			else
			begin
				highest_top = top[position+2];
				tetris_now[highest_top-1][position] = 1'b1;
				tetris_now[highest_top-1][position+1] = 1'b1;
				tetris_now[highest_top][position+1] = 1'b1;
				tetris_now[highest_top][position+2] = 1'b1;
				top[position] = highest_top;
				top[position+1] = highest_top + 1;
                top[position+2] = highest_top + 1;
			end
		end
	endcase
end endtask

task score_and_shift;
begin
    while((tetris_now[0] === 6'd63) || (tetris_now[1] === 6'd63) || (tetris_now[2] === 6'd63) || (tetris_now[3] === 6'd63) || 
          (tetris_now[4] === 6'd63) || (tetris_now[5] === 6'd63) || (tetris_now[6] === 6'd63) || (tetris_now[7] === 6'd63) || 
          (tetris_now[8] === 6'd63) || (tetris_now[9] === 6'd63) || (tetris_now[10] === 6'd63) || (tetris_now[11] === 6'd63))
    begin
        score_gold = score_gold + 1;
        if(tetris_now[0] === 6'd63)
        begin
            tetris_now[0] = tetris_now[1];
            tetris_now[1] = tetris_now[2];
            tetris_now[2] = tetris_now[3];
            tetris_now[3] = tetris_now[4];
            tetris_now[4] = tetris_now[5];
            tetris_now[5] = tetris_now[6];
            tetris_now[6] = tetris_now[7];
            tetris_now[7] = tetris_now[8];
            tetris_now[8] = tetris_now[9];
            tetris_now[9] = tetris_now[10];
            tetris_now[10] = tetris_now[11];
            tetris_now[11] = tetris_now[12];
            tetris_now[12] = tetris_now[13];
            tetris_now[13] = tetris_now[14];
            tetris_now[14] = tetris_now[15];
            tetris_now[15] = 6'd0;
        end
        else if(tetris_now[1] === 6'd63)
        begin
            tetris_now[1] = tetris_now[2];
            tetris_now[2] = tetris_now[3];
            tetris_now[3] = tetris_now[4];
            tetris_now[4] = tetris_now[5];
            tetris_now[5] = tetris_now[6];
            tetris_now[6] = tetris_now[7];
            tetris_now[7] = tetris_now[8];
            tetris_now[8] = tetris_now[9];
            tetris_now[9] = tetris_now[10];
            tetris_now[10] = tetris_now[11];
            tetris_now[11] = tetris_now[12];
            tetris_now[12] = tetris_now[13];
            tetris_now[13] = tetris_now[14];
            tetris_now[14] = tetris_now[15];
            tetris_now[15] = 6'd0;
        end
        else if(tetris_now[2] === 6'd63)
        begin
            tetris_now[2] = tetris_now[3];
            tetris_now[3] = tetris_now[4];
            tetris_now[4] = tetris_now[5];
            tetris_now[5] = tetris_now[6];
            tetris_now[6] = tetris_now[7];
            tetris_now[7] = tetris_now[8];
            tetris_now[8] = tetris_now[9];
            tetris_now[9] = tetris_now[10];
            tetris_now[10] = tetris_now[11];
            tetris_now[11] = tetris_now[12];
            tetris_now[12] = tetris_now[13];
            tetris_now[13] = tetris_now[14];
            tetris_now[14] = tetris_now[15];
            tetris_now[15] = 6'd0;
        end
        else if(tetris_now[3] === 6'd63)
        begin
            tetris_now[3] = tetris_now[4];
            tetris_now[4] = tetris_now[5];
            tetris_now[5] = tetris_now[6];
            tetris_now[6] = tetris_now[7];
            tetris_now[7] = tetris_now[8];
            tetris_now[8] = tetris_now[9];
            tetris_now[9] = tetris_now[10];
            tetris_now[10] = tetris_now[11];
            tetris_now[11] = tetris_now[12];
            tetris_now[12] = tetris_now[13];
            tetris_now[13] = tetris_now[14];
            tetris_now[14] = tetris_now[15];
            tetris_now[15] = 6'd0;
        end
        else if(tetris_now[4] === 6'd63)
        begin
            tetris_now[4] = tetris_now[5];
            tetris_now[5] = tetris_now[6];
            tetris_now[6] = tetris_now[7];
            tetris_now[7] = tetris_now[8];
            tetris_now[8] = tetris_now[9];
            tetris_now[9] = tetris_now[10];
            tetris_now[10] = tetris_now[11];
            tetris_now[11] = tetris_now[12];
            tetris_now[12] = tetris_now[13];
            tetris_now[13] = tetris_now[14];
            tetris_now[14] = tetris_now[15];
            tetris_now[15] = 6'd0;
        end
        else if(tetris_now[5] === 6'd63)
        begin
            tetris_now[5] = tetris_now[6];
            tetris_now[6] = tetris_now[7];
            tetris_now[7] = tetris_now[8];
            tetris_now[8] = tetris_now[9];
            tetris_now[9] = tetris_now[10];
            tetris_now[10] = tetris_now[11];
            tetris_now[11] = tetris_now[12];
            tetris_now[12] = tetris_now[13];
            tetris_now[13] = tetris_now[14];
            tetris_now[14] = tetris_now[15];
            tetris_now[15] = 6'd0;
        end
        else if(tetris_now[6] === 6'd63)
        begin
            tetris_now[6] = tetris_now[7];
            tetris_now[7] = tetris_now[8];
            tetris_now[8] = tetris_now[9];
            tetris_now[9] = tetris_now[10];
            tetris_now[10] = tetris_now[11];
            tetris_now[11] = tetris_now[12];
            tetris_now[12] = tetris_now[13];
            tetris_now[13] = tetris_now[14];
            tetris_now[14] = tetris_now[15];
            tetris_now[15] = 6'd0;
        end
        else if(tetris_now[7] === 6'd63)
        begin
            tetris_now[7] = tetris_now[8];
            tetris_now[8] = tetris_now[9];
            tetris_now[9] = tetris_now[10];
            tetris_now[10] = tetris_now[11];
            tetris_now[11] = tetris_now[12];
            tetris_now[12] = tetris_now[13];
            tetris_now[13] = tetris_now[14];
            tetris_now[14] = tetris_now[15];
            tetris_now[15] = 6'd0;
        end
        else if(tetris_now[8] === 6'd63)
        begin
            tetris_now[8] = tetris_now[9];
            tetris_now[9] = tetris_now[10];
            tetris_now[10] = tetris_now[11];
            tetris_now[11] = tetris_now[12];
            tetris_now[12] = tetris_now[13];
            tetris_now[13] = tetris_now[14];
            tetris_now[14] = tetris_now[15];
            tetris_now[15] = 6'd0;
        end
        else if(tetris_now[9] === 6'd63)
        begin
            tetris_now[9] = tetris_now[10];
            tetris_now[10] = tetris_now[11];
            tetris_now[11] = tetris_now[12];
            tetris_now[12] = tetris_now[13];
            tetris_now[13] = tetris_now[14];
            tetris_now[14] = tetris_now[15];
            tetris_now[15] = 6'd0;
        end
        else if(tetris_now[10] === 6'd63)
        begin
            tetris_now[10] = tetris_now[11];
            tetris_now[11] = tetris_now[12];
            tetris_now[12] = tetris_now[13];
            tetris_now[13] = tetris_now[14];
            tetris_now[14] = tetris_now[15];
            tetris_now[15] = 6'd0;
        end
        else if(tetris_now[11] === 6'd63)
        begin
            tetris_now[11] = tetris_now[12];
            tetris_now[12] = tetris_now[13];
            tetris_now[13] = tetris_now[14];
            tetris_now[14] = tetris_now[15];
            tetris_now[15] = 6'd0;
        end
    end
end endtask

task set_top;
begin
    top[0] = 4'd0;
	top[1] = 4'd0;
	top[2] = 4'd0;
	top[3] = 4'd0;
	top[4] = 4'd0;
	top[5] = 4'd0;
    for(j = 15; j >= 0; j--)
	begin
        if(tetris_now[j][0]===1'b1)
        begin
            top[0] = j + 1;
            break;
        end
    end
    for(j = 15; j >= 0; j--)
	begin
        if(tetris_now[j][1]===1'b1)
        begin
            top[1] = j + 1;
            break;
        end
    end
    for(j = 15; j >= 0; j--)
	begin
        if(tetris_now[j][2]===1'b1)
        begin
            top[2] = j + 1;
            break;
        end
    end
    for(j = 15; j >= 0; j--)
	begin
        if(tetris_now[j][3]===1'b1)
        begin
            top[3] = j + 1;
            break;
        end
    end
    for(j = 15; j >= 0; j--)
	begin
        if(tetris_now[j][4]===1'b1)
        begin
            top[4] = j + 1;
            break;
        end
    end
    for(j = 15; j >= 0; j--)
	begin
        if(tetris_now[j][5]===1'b1)
        begin
            top[5] = j + 1;
            break;
        end
    end
end endtask

task determine_fail;
begin
	score_valid_gold = 1'b1;
    if((tetris_now[12]===6'd0)&&(tetris_now[13]===6'd0)&&(tetris_now[14]===6'd0)&&(tetris_now[15]===6'd0)) fail_gold = 1'b0;
    else fail_gold = 1'b1;
	if((fail_gold === 1'b1) || (i == 15))
    begin
        tetris_valid_gold = 1'b1;
        total_score = total_score + score_gold;
    end
	else tetris_valid_gold = 1'b0;
    tetris_gold = {tetris_now[11], tetris_now[10], tetris_now[9], tetris_now[8], tetris_now[7], tetris_now[6], tetris_now[5], tetris_now[4], tetris_now[3], tetris_now[2], tetris_now[1], tetris_now[0]};
end endtask

task wait_score_valid_task;
begin
    latency = 1;
    while (score_valid !== 1'b1) begin
        latency = latency + 1;
        check_spec_5;
        check_spec_6;
        check_spec_8;
        @(negedge clk);
    end
    total_latency = total_latency + latency;
end endtask

task check_ans_task;
begin
    if(tetris_valid_gold == 1'b1)
	begin
		if((tetris_valid!==tetris_valid_gold)||(score_valid!==score_valid_gold)||(fail!==fail_gold)||(score!==score_gold)||(tetris!==tetris_gold))
		begin
			$display("                    SPEC-7 FAIL                   ");
			$finish;
		end
	end
	else
	begin
		if((tetris_valid!==tetris_valid_gold)||(score_valid!==score_valid_gold)||(fail!==fail_gold)||(score!==score_gold)||(tetris!==72'd0))
        begin
			$display("                    SPEC-7 FAIL                   ");
			$finish;
		end
	end
end endtask

task check_spec_4;
begin
    if(tetris_valid !== 1'b0 || score_valid !== 1'b0 || fail !== 1'b0 || score !== 4'd0 || tetris !== 72'd0)
	begin
        $display("                    SPEC-4 FAIL                   ");
        $finish;
    end
end endtask

task check_spec_5;
begin
    if(score_valid === 1'b0)
	begin
		if((|score === 1'b1) || (|fail === 1'b1) || (|tetris_valid === 1'b1))
		begin
			$display("                    SPEC-5 FAIL                   ");
			$finish;
		end
	end
	if(tetris_valid === 1'b0)
	begin
		if(|tetris === 1'b1)
		begin
			$display("                    SPEC-5 FAIL                   ");
			$finish;
		end
	end
end endtask

task check_spec_6;
begin
    if(latency == 1000)
    begin
        $display("                    SPEC-6 FAIL                   ");
        $finish;
    end
end endtask

task check_spec_8;
begin
    if((last_tetris_valid === 1'b1) && (tetris_valid === 1'b1))
    begin
        $display("                    SPEC-8 FAIL                   ");
        $finish;
    end
    if((last_score_valid === 1'b1) && (score_valid === 1'b1))
    begin
        $display("                    SPEC-8 FAIL                   ");
        $finish;
    end
end endtask

task YOU_PASS_task;
begin
    $display("                  Congratulations!               ");
    $display("              execution cycles = %7d", total_latency);
    $display("              clock period = %4fns", CYCLE);
    $finish;
end endtask

always @ (posedge clk)
begin
    last_tetris_valid = tetris_valid;
    last_score_valid = score_valid;
end

/*initial
begin
	#1000000 $finish;
end*/

endmodule
// for spec check
// $display("                    SPEC-4 FAIL                   ");
// $display("                    SPEC-5 FAIL                   ");
// $display("                    SPEC-6 FAIL                   ");
// $display("                    SPEC-7 FAIL                   ");
// $display("                    SPEC-8 FAIL                   ");
// for successful design
// $display("                  Congratulations!               ");
// $display("              execution cycles = %7d", total_latency);
// $display("              clock period = %4fns", CYCLE);