/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: TETRIS
// FILE NAME: TETRIS.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / TETRIS
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module TETRIS (
	//INPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//OUTPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input				rst_n, clk, in_valid;
input		[2:0]	tetrominoes;
input		[2:0]	position;
output reg			tetris_valid, score_valid, fail;
output reg	[3:0]	score;
output reg 	[71:0]	tetris;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
parameter IDLE = 1'd0, PLAY = 1'd1;

//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg state;
reg next_state;
reg [3:0] counter_16;
reg [3:0] next_counter_16;
reg [2:0] score_ff;
reg [2:0] next_score_ff;
reg [5:0] tetris_ff [13:0];
reg [5:0] next_tetris_ff [13:0];
reg [3:0] top [5:0];
reg [3:0] next_top [5:0];
reg [3:0] highest_top;

reg is_line_fill;
//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//   CURRENT STATE
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state <= IDLE;
        score_ff <= 3'd0;
        counter_16 <= 4'd0;
        tetris_ff[0] <= 6'd0;
        tetris_ff[1] <= 6'd0;
        tetris_ff[2] <= 6'd0;
        tetris_ff[3] <= 6'd0;
        tetris_ff[4] <= 6'd0;
        tetris_ff[5] <= 6'd0;
        tetris_ff[6] <= 6'd0;
        tetris_ff[7] <= 6'd0;
        tetris_ff[8] <= 6'd0;
        tetris_ff[9] <= 6'd0;
        tetris_ff[10] <= 6'd0;
        tetris_ff[11] <= 6'd0;
        tetris_ff[12] <= 6'd0;
        tetris_ff[13] <= 6'd0;
        top[0] <= 4'd0;
        top[1] <= 4'd0;
        top[2] <= 4'd0;
        top[3] <= 4'd0;
        top[4] <= 4'd0;
        top[5] <= 4'd0;
    end
    else
    begin
        state <= next_state;
        score_ff <= next_score_ff;
        counter_16 <= next_counter_16;
        tetris_ff[0] <= next_tetris_ff[0];
        tetris_ff[1] <= next_tetris_ff[1];
        tetris_ff[2] <= next_tetris_ff[2];
        tetris_ff[3] <= next_tetris_ff[3];
        tetris_ff[4] <= next_tetris_ff[4];
        tetris_ff[5] <= next_tetris_ff[5];
        tetris_ff[6] <= next_tetris_ff[6];
        tetris_ff[7] <= next_tetris_ff[7];
        tetris_ff[8] <= next_tetris_ff[8];
        tetris_ff[9] <= next_tetris_ff[9];
        tetris_ff[10] <= next_tetris_ff[10];
        tetris_ff[11] <= next_tetris_ff[11];
        tetris_ff[12] <= next_tetris_ff[12];
        tetris_ff[13] <= next_tetris_ff[13];
        top[0] <= next_top[0];
        top[1] <= next_top[1];
        top[2] <= next_top[2];
        top[3] <= next_top[3];
        top[4] <= next_top[4];
        top[5] <= next_top[5];
    end
end

//---------------------------------------------------------------------
//   NEXT STATE
//---------------------------------------------------------------------
always @ (*)
begin
    case(state)
    IDLE:
    begin
        if(in_valid) next_state = PLAY;
        else next_state = IDLE;
    end
    PLAY:
    begin
        if(score_valid) next_state = IDLE;
        else next_state = PLAY;
    end
    default:
    begin
        next_state = IDLE;
    end
    endcase
end

//---------------------------------------------------------------------
//   OTHERS
//---------------------------------------------------------------------

always @ (*)
begin
    case(state)
    IDLE:
    begin
        next_tetris_ff[0] = tetris_ff[0];
        next_tetris_ff[1] = tetris_ff[1];
        next_tetris_ff[2] = tetris_ff[2];
        next_tetris_ff[3] = tetris_ff[3];
        next_tetris_ff[4] = tetris_ff[4];
        next_tetris_ff[5] = tetris_ff[5];
        next_tetris_ff[6] = tetris_ff[6];
        next_tetris_ff[7] = tetris_ff[7];
        next_tetris_ff[8] = tetris_ff[8];
        next_tetris_ff[9] = tetris_ff[9];
        next_tetris_ff[10] = tetris_ff[10];
        next_tetris_ff[11] = tetris_ff[11];
        next_tetris_ff[12] = tetris_ff[12];
        next_tetris_ff[13] = tetris_ff[13];
        if(in_valid)
        begin
            case(tetrominoes)
                3'd0:
                begin
                    next_tetris_ff[highest_top][position] = 1'b1;
                    next_tetris_ff[highest_top+1][position] = 1'b1;
                    next_tetris_ff[highest_top][position+1] = 1'b1;
                    next_tetris_ff[highest_top+1][position+1] = 1'b1;
                end
                3'd1:
                begin
                    next_tetris_ff[highest_top][position] = 1'b1;
                    next_tetris_ff[highest_top+1][position] = 1'b1;
                    if(highest_top<12) next_tetris_ff[highest_top+2][position] = 1'b1;
                    if(highest_top<11) next_tetris_ff[highest_top+3][position] = 1'b1;
                end
                3'd2:
                begin
                    next_tetris_ff[highest_top][position] = 1'b1;
                    next_tetris_ff[highest_top][position+1] = 1'b1;
                    next_tetris_ff[highest_top][position+2] = 1'b1;
                    next_tetris_ff[highest_top][position+3] = 1'b1;
                end
                3'd3:
                begin
                    if(highest_top<14) next_tetris_ff[highest_top][position] = 1'b1;
                    next_tetris_ff[highest_top-2][position+1] = 1'b1;
                    next_tetris_ff[highest_top-1][position+1] = 1'b1;
                    if(highest_top<14) next_tetris_ff[highest_top][position+1] = 1'b1;
                end
                3'd4:
                begin
                    next_tetris_ff[highest_top-1][position] = 1'b1;
                    next_tetris_ff[highest_top][position] = 1'b1;
                    next_tetris_ff[highest_top][position+1] = 1'b1;
                    next_tetris_ff[highest_top][position+2] = 1'b1;
                end
                3'd5:
                begin
                    next_tetris_ff[highest_top][position] = 1'b1;
                    next_tetris_ff[highest_top+1][position] = 1'b1;
                    if(highest_top<12) next_tetris_ff[highest_top+2][position] = 1'b1;
                    next_tetris_ff[highest_top][position+1] = 1'b1;
                end
                3'd6:
                begin
                    next_tetris_ff[highest_top][position] = 1'b1;
                    if(highest_top<13) next_tetris_ff[highest_top+1][position] = 1'b1;
                    next_tetris_ff[highest_top-1][position+1] = 1'b1;
                    next_tetris_ff[highest_top][position+1] = 1'b1;
                end
                3'd7:
                begin
                    next_tetris_ff[highest_top-1][position] = 1'b1;
                    next_tetris_ff[highest_top-1][position+1] = 1'b1;
                    next_tetris_ff[highest_top][position+1] = 1'b1;
                    next_tetris_ff[highest_top][position+2] = 1'b1;
                end
            endcase
        end
    end
    PLAY:
    begin
        if(&tetris_ff[0])
        begin
            next_tetris_ff[0] = tetris_ff[1];
            next_tetris_ff[1] = tetris_ff[2];
            next_tetris_ff[2] = tetris_ff[3];
            next_tetris_ff[3] = tetris_ff[4];
            next_tetris_ff[4] = tetris_ff[5];
            next_tetris_ff[5] = tetris_ff[6];
            next_tetris_ff[6] = tetris_ff[7];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[1])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[2];
            next_tetris_ff[2] = tetris_ff[3];
            next_tetris_ff[3] = tetris_ff[4];
            next_tetris_ff[4] = tetris_ff[5];
            next_tetris_ff[5] = tetris_ff[6];
            next_tetris_ff[6] = tetris_ff[7];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[2])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[3];
            next_tetris_ff[3] = tetris_ff[4];
            next_tetris_ff[4] = tetris_ff[5];
            next_tetris_ff[5] = tetris_ff[6];
            next_tetris_ff[6] = tetris_ff[7];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[3])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[4];
            next_tetris_ff[4] = tetris_ff[5];
            next_tetris_ff[5] = tetris_ff[6];
            next_tetris_ff[6] = tetris_ff[7];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[4])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[5];
            next_tetris_ff[5] = tetris_ff[6];
            next_tetris_ff[6] = tetris_ff[7];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[5])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[6];
            next_tetris_ff[6] = tetris_ff[7];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[6])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[5];
            next_tetris_ff[6] = tetris_ff[7];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[7])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[5];
            next_tetris_ff[6] = tetris_ff[6];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[8])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[5];
            next_tetris_ff[6] = tetris_ff[6];
            next_tetris_ff[7] = tetris_ff[7];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[9])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[5];
            next_tetris_ff[6] = tetris_ff[6];
            next_tetris_ff[7] = tetris_ff[7];
            next_tetris_ff[8] = tetris_ff[8];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[10])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[5];
            next_tetris_ff[6] = tetris_ff[6];
            next_tetris_ff[7] = tetris_ff[7];
            next_tetris_ff[8] = tetris_ff[8];
            next_tetris_ff[9] = tetris_ff[9];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[11])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[5];
            next_tetris_ff[6] = tetris_ff[6];
            next_tetris_ff[7] = tetris_ff[7];
            next_tetris_ff[8] = tetris_ff[8];
            next_tetris_ff[9] = tetris_ff[9];
            next_tetris_ff[10] = tetris_ff[10];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(fail || &counter_16)
        begin
            next_tetris_ff[0] = 6'd0;
            next_tetris_ff[1] = 6'd0;
            next_tetris_ff[2] = 6'd0;
            next_tetris_ff[3] = 6'd0;
            next_tetris_ff[4] = 6'd0;
            next_tetris_ff[5] = 6'd0;
            next_tetris_ff[6] = 6'd0;
            next_tetris_ff[7] = 6'd0;
            next_tetris_ff[8] = 6'd0;
            next_tetris_ff[9] = 6'd0;
            next_tetris_ff[10] = 6'd0;
            next_tetris_ff[11] = 6'd0;
            next_tetris_ff[12] = 6'd0;
            next_tetris_ff[13] = 6'd0;
        end
        else
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[5];
            next_tetris_ff[6] = tetris_ff[6];
            next_tetris_ff[7] = tetris_ff[7];
            next_tetris_ff[8] = tetris_ff[8];
            next_tetris_ff[9] = tetris_ff[9];
            next_tetris_ff[10] = tetris_ff[10];
            next_tetris_ff[11] = tetris_ff[11];
            next_tetris_ff[12] = tetris_ff[12];
            next_tetris_ff[13] = tetris_ff[13];
        end
    end
    default:
    begin
        next_tetris_ff[0] = tetris_ff[0];
        next_tetris_ff[1] = tetris_ff[1];
        next_tetris_ff[2] = tetris_ff[2];
        next_tetris_ff[3] = tetris_ff[3];
        next_tetris_ff[4] = tetris_ff[4];
        next_tetris_ff[5] = tetris_ff[5];
        next_tetris_ff[6] = tetris_ff[6];
        next_tetris_ff[7] = tetris_ff[7];
        next_tetris_ff[8] = tetris_ff[8];
        next_tetris_ff[9] = tetris_ff[9];
        next_tetris_ff[10] = tetris_ff[10];
        next_tetris_ff[11] = tetris_ff[11];
        next_tetris_ff[12] = tetris_ff[12];
        next_tetris_ff[13] = tetris_ff[13];
    end
    endcase
end

always @ (*)
begin
    case(tetrominoes)
        3'd0:
        begin
            highest_top = (top[position] > top[position + 4'd1])?top[position]:top[position+1];
        end
        3'd1:
        begin
            highest_top = top[position];
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
        end
        3'd3:
        begin
            highest_top = (top[position] >= (top[position+1] + 4'd2))?top[position]:(top[position+1] + 4'd2);
        end
        3'd4:
        begin
            if(((top[position] + 4'd1) >= top[position+1]) && ((top[position] + 4'd1) >= top[position+2]))
            begin
                highest_top = top[position] + 4'd1;
            end
            else if(top[position+1] >= top[position+2])
            begin
                highest_top = top[position+1];
            end
            else
            begin
                highest_top = top[position+2];
            end
        end
        3'd5:
        begin
            highest_top = (top[position] > top[position+1])?top[position]:top[position+1];
        end
        3'd6:
        begin
            highest_top = (top[position] >= (top[position+1] + 4'd1))?top[position]:(top[position+1] + 4'd1);
        end
        3'd7:
        begin
            if(((top[position] + 4'd1) >= (top[position+1] + 4'd1)) && ((top[position] + 4'd1) >= top[position+2]))
            begin
                highest_top = top[position] + 4'd1;
            end
            else if((top[position+1] + 4'd1) >= top[position+2])
            begin
                highest_top = top[position+1] + 4'd1;
            end
            else
            begin
                highest_top = top[position+2];
            end
        end
    endcase
end

always @ (*)
begin
    if(score_valid && (fail || &counter_16))
    begin
        next_top[0] = 4'd0;
        next_top[1] = 4'd0;
        next_top[2] = 4'd0;
        next_top[3] = 4'd0;
        next_top[4] = 4'd0;
        next_top[5] = 4'd0;
    end
    else
    begin
        if(tetris_ff[11][0] == 1'b1) next_top[0] = 4'd12;
        else if(tetris_ff[10][0] == 1'b1) next_top[0] = 4'd11;
        else if(tetris_ff[9][0] == 1'b1) next_top[0] = 4'd10;
        else if(tetris_ff[8][0] == 1'b1) next_top[0] = 4'd9;
        else if(tetris_ff[7][0] == 1'b1) next_top[0] = 4'd8;
        else if(tetris_ff[6][0] == 1'b1) next_top[0] = 4'd7;
        else if(tetris_ff[5][0] == 1'b1) next_top[0] = 4'd6;
        else if(tetris_ff[4][0] == 1'b1) next_top[0] = 4'd5;
        else if(tetris_ff[3][0] == 1'b1) next_top[0] = 4'd4;
        else if(tetris_ff[2][0] == 1'b1) next_top[0] = 4'd3;
        else if(tetris_ff[1][0] == 1'b1) next_top[0] = 4'd2;
        else if(tetris_ff[0][0] == 1'b1) next_top[0] = 4'd1;
        else next_top[0] = 4'd0;
        
        if(tetris_ff[11][1] == 1'b1) next_top[1] = 4'd12;
        else if(tetris_ff[10][1] == 1'b1) next_top[1] = 4'd11;
        else if(tetris_ff[9][1] == 1'b1) next_top[1] = 4'd10;
        else if(tetris_ff[8][1] == 1'b1) next_top[1] = 4'd9;
        else if(tetris_ff[7][1] == 1'b1) next_top[1] = 4'd8;
        else if(tetris_ff[6][1] == 1'b1) next_top[1] = 4'd7;
        else if(tetris_ff[5][1] == 1'b1) next_top[1] = 4'd6;
        else if(tetris_ff[4][1] == 1'b1) next_top[1] = 4'd5;
        else if(tetris_ff[3][1] == 1'b1) next_top[1] = 4'd4;
        else if(tetris_ff[2][1] == 1'b1) next_top[1] = 4'd3;
        else if(tetris_ff[1][1] == 1'b1) next_top[1] = 4'd2;
        else if(tetris_ff[0][1] == 1'b1) next_top[1] = 4'd1;
        else next_top[1] = 4'd0;

        if(tetris_ff[11][2] == 1'b1) next_top[2] = 4'd12;
        else if(tetris_ff[10][2] == 1'b1) next_top[2] = 4'd11;
        else if(tetris_ff[9][2] == 1'b1) next_top[2] = 4'd10;
        else if(tetris_ff[8][2] == 1'b1) next_top[2] = 4'd9;
        else if(tetris_ff[7][2] == 1'b1) next_top[2] = 4'd8;
        else if(tetris_ff[6][2] == 1'b1) next_top[2] = 4'd7;
        else if(tetris_ff[5][2] == 1'b1) next_top[2] = 4'd6;
        else if(tetris_ff[4][2] == 1'b1) next_top[2] = 4'd5;
        else if(tetris_ff[3][2] == 1'b1) next_top[2] = 4'd4;
        else if(tetris_ff[2][2] == 1'b1) next_top[2] = 4'd3;
        else if(tetris_ff[1][2] == 1'b1) next_top[2] = 4'd2;
        else if(tetris_ff[0][2] == 1'b1) next_top[2] = 4'd1;
        else next_top[2] = 4'd0;

        if(tetris_ff[11][3] == 1'b1) next_top[3] = 4'd12;
        else if(tetris_ff[10][3] == 1'b1) next_top[3] = 4'd11;
        else if(tetris_ff[9][3] == 1'b1) next_top[3] = 4'd10;
        else if(tetris_ff[8][3] == 1'b1) next_top[3] = 4'd9;
        else if(tetris_ff[7][3] == 1'b1) next_top[3] = 4'd8;
        else if(tetris_ff[6][3] == 1'b1) next_top[3] = 4'd7;
        else if(tetris_ff[5][3] == 1'b1) next_top[3] = 4'd6;
        else if(tetris_ff[4][3] == 1'b1) next_top[3] = 4'd5;
        else if(tetris_ff[3][3] == 1'b1) next_top[3] = 4'd4;
        else if(tetris_ff[2][3] == 1'b1) next_top[3] = 4'd3;
        else if(tetris_ff[1][3] == 1'b1) next_top[3] = 4'd2;
        else if(tetris_ff[0][3] == 1'b1) next_top[3] = 4'd1;
        else next_top[3] = 4'd0;

        if(tetris_ff[11][4] == 1'b1) next_top[4] = 4'd12;
        else if(tetris_ff[10][4] == 1'b1) next_top[4] = 4'd11;
        else if(tetris_ff[9][4] == 1'b1) next_top[4] = 4'd10;
        else if(tetris_ff[8][4] == 1'b1) next_top[4] = 4'd9;
        else if(tetris_ff[7][4] == 1'b1) next_top[4] = 4'd8;
        else if(tetris_ff[6][4] == 1'b1) next_top[4] = 4'd7;
        else if(tetris_ff[5][4] == 1'b1) next_top[4] = 4'd6;
        else if(tetris_ff[4][4] == 1'b1) next_top[4] = 4'd5;
        else if(tetris_ff[3][4] == 1'b1) next_top[4] = 4'd4;
        else if(tetris_ff[2][4] == 1'b1) next_top[4] = 4'd3;
        else if(tetris_ff[1][4] == 1'b1) next_top[4] = 4'd2;
        else if(tetris_ff[0][4] == 1'b1) next_top[4] = 4'd1;
        else next_top[4] = 4'd0;

        if(tetris_ff[11][5] == 1'b1) next_top[5] = 4'd12;
        else if(tetris_ff[10][5] == 1'b1) next_top[5] = 4'd11;
        else if(tetris_ff[9][5] == 1'b1) next_top[5] = 4'd10;
        else if(tetris_ff[8][5] == 1'b1) next_top[5] = 4'd9;
        else if(tetris_ff[7][5] == 1'b1) next_top[5] = 4'd8;
        else if(tetris_ff[6][5] == 1'b1) next_top[5] = 4'd7;
        else if(tetris_ff[5][5] == 1'b1) next_top[5] = 4'd6;
        else if(tetris_ff[4][5] == 1'b1) next_top[5] = 4'd5;
        else if(tetris_ff[3][5] == 1'b1) next_top[5] = 4'd4;
        else if(tetris_ff[2][5] == 1'b1) next_top[5] = 4'd3;
        else if(tetris_ff[1][5] == 1'b1) next_top[5] = 4'd2;
        else if(tetris_ff[0][5] == 1'b1) next_top[5] = 4'd1;
        else next_top[5] = 4'd0;
    end
end

always @ (*)
begin
    if(score_valid)
    begin
        if(&counter_16||fail) next_counter_16 = 4'd0;
        else next_counter_16 = counter_16 + 4'd1;
    end
    else next_counter_16 = counter_16;
end

/*always @ (*)
begin
    if(score_valid && (&counter_16||fail)) next_counter_16 = 4'd0;
    else if(score_valid) next_counter_16 = counter_16 + 4'd1;
    else next_counter_16 = counter_16;
end*/

always @ (*)
begin
    is_line_fill =  (&tetris_ff[0]) || (&tetris_ff[1]) || (&tetris_ff[2]) || (&tetris_ff[3]) || 
                    (&tetris_ff[4]) || (&tetris_ff[5]) || (&tetris_ff[6]) || (&tetris_ff[7]) || 
                    (&tetris_ff[8]) || (&tetris_ff[9]) || (&tetris_ff[10]) || (&tetris_ff[11]);
end
//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
always @ (*)
begin
    if(score_valid && (fail || &counter_16)) next_score_ff = 3'd0;
    else if(is_line_fill) next_score_ff = score_ff + 3'd1;
    else next_score_ff = score_ff;
end

always @ (*)
begin
    if(score_valid && (|tetris_ff[12])) fail = 1'b1;
    else fail = 1'b0;
end

always @ (*)
begin
    if((state == PLAY) && (is_line_fill == 1'b0)) score_valid = 1'b1;
    else score_valid = 1'b0;
end

always @ (*)
begin
    if(score_valid && (fail || &counter_16)) tetris_valid = 1'b1;
    else tetris_valid = 1'b0;
end

always @ (*)
begin
    if(score_valid) score = {1'b0, score_ff};
    else score = 3'd0;
end

always @ (*)
begin
    if(tetris_valid) tetris = {tetris_ff[11], tetris_ff[10], tetris_ff[9], tetris_ff[8], tetris_ff[7], tetris_ff[6], tetris_ff[5], tetris_ff[4], tetris_ff[3], tetris_ff[2], tetris_ff[1], tetris_ff[0]};
    else tetris = 72'd0;
end
endmodule





/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: TETRIS
// FILE NAME: TETRIS.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / TETRIS
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
/*module TETRIS (
	//INPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//OUTPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION          
//---------------------------------------------------------------------
input				rst_n, clk, in_valid;
input		[2:0]	tetrominoes;
input		[2:0]	position;
output reg			tetris_valid, score_valid, fail;
output reg	[3:0]	score;
output reg 	[71:0]	tetris;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
parameter IDLE = 2'd0, PLAY = 2'd1, SHIFT = 2'd2, RESULT = 2'd3;

//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
reg [2:0] last_tetrominoes;
reg [2:0] last_position;

reg [1:0] state;
reg [1:0] next_state;
reg [3:0] counter_16;
reg [3:0] next_counter_16;
reg [3:0] score_ff;
reg [3:0] next_score_ff;
reg [5:0] tetris_ff [13:0];
reg [5:0] next_tetris_ff [13:0];
reg [3:0] top [5:0];
reg [3:0] next_top [5:0];
reg [3:0] highest_top;

//reg [5:0] changed_row [3:0];
reg is_line_fill;
//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//   CURRENT STATE
//---------------------------------------------------------------------
always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state <= IDLE;
        score_ff <= 4'd0;
        counter_16 <= 4'd0;
        tetris_ff[0] <= 6'd0;
        tetris_ff[1] <= 6'd0;
        tetris_ff[2] <= 6'd0;
        tetris_ff[3] <= 6'd0;
        tetris_ff[4] <= 6'd0;
        tetris_ff[5] <= 6'd0;
        tetris_ff[6] <= 6'd0;
        tetris_ff[7] <= 6'd0;
        tetris_ff[8] <= 6'd0;
        tetris_ff[9] <= 6'd0;
        tetris_ff[10] <= 6'd0;
        tetris_ff[11] <= 6'd0;
        tetris_ff[12] <= 6'd0;
        tetris_ff[13] <= 6'd0;
        last_tetrominoes <= 3'd0;
        last_position <= 3'd0;
    end
    else
    begin
        state <= next_state;
        score_ff <= next_score_ff;
        counter_16 <= next_counter_16;
        tetris_ff[0] <= next_tetris_ff[0];
        tetris_ff[1] <= next_tetris_ff[1];
        tetris_ff[2] <= next_tetris_ff[2];
        tetris_ff[3] <= next_tetris_ff[3];
        tetris_ff[4] <= next_tetris_ff[4];
        tetris_ff[5] <= next_tetris_ff[5];
        tetris_ff[6] <= next_tetris_ff[6];
        tetris_ff[7] <= next_tetris_ff[7];
        tetris_ff[8] <= next_tetris_ff[8];
        tetris_ff[9] <= next_tetris_ff[9];
        tetris_ff[10] <= next_tetris_ff[10];
        tetris_ff[11] <= next_tetris_ff[11];
        tetris_ff[12] <= next_tetris_ff[12];
        tetris_ff[13] <= next_tetris_ff[13];
        last_tetrominoes <= tetrominoes;
        last_position <= position;
    end
end

//---------------------------------------------------------------------
//   NEXT STATE
//---------------------------------------------------------------------
always @ (*)
begin
    case(state)
    IDLE:
    begin
        if(in_valid) next_state = PLAY;
        else next_state = IDLE;
    end
    PLAY:
    begin
        if(is_line_fill) next_state = SHIFT;
        else next_state = RESULT;
    end
    SHIFT:
    begin
        if(is_line_fill) next_state = SHIFT;
        else next_state = RESULT;
    end
    RESULT:
    begin
        next_state = IDLE;
    end
    default:
    begin
        next_state = IDLE;
    end
    endcase
end

//---------------------------------------------------------------------
//   OTHERS
//---------------------------------------------------------------------

always @ (*)
begin
    case(state)
    IDLE:
    begin
        next_tetris_ff[0] = tetris_ff[0];
        next_tetris_ff[1] = tetris_ff[1];
        next_tetris_ff[2] = tetris_ff[2];
        next_tetris_ff[3] = tetris_ff[3];
        next_tetris_ff[4] = tetris_ff[4];
        next_tetris_ff[5] = tetris_ff[5];
        next_tetris_ff[6] = tetris_ff[6];
        next_tetris_ff[7] = tetris_ff[7];
        next_tetris_ff[8] = tetris_ff[8];
        next_tetris_ff[9] = tetris_ff[9];
        next_tetris_ff[10] = tetris_ff[10];
        next_tetris_ff[11] = tetris_ff[11];
        next_tetris_ff[12] = tetris_ff[12];
        next_tetris_ff[13] = tetris_ff[13];
    end
    PLAY:
    begin
        next_tetris_ff[0] = tetris_ff[0];
        next_tetris_ff[1] = tetris_ff[1];
        next_tetris_ff[2] = tetris_ff[2];
        next_tetris_ff[3] = tetris_ff[3];
        next_tetris_ff[4] = tetris_ff[4];
        next_tetris_ff[5] = tetris_ff[5];
        next_tetris_ff[6] = tetris_ff[6];
        next_tetris_ff[7] = tetris_ff[7];
        next_tetris_ff[8] = tetris_ff[8];
        next_tetris_ff[9] = tetris_ff[9];
        next_tetris_ff[10] = tetris_ff[10];
        next_tetris_ff[11] = tetris_ff[11];
        next_tetris_ff[12] = tetris_ff[12];
        next_tetris_ff[13] = tetris_ff[13];
        case(last_tetrominoes)
            3'd0:
            begin
                next_tetris_ff[highest_top][last_position] = 1'b1;
                next_tetris_ff[highest_top+1][last_position] = 1'b1;
                next_tetris_ff[highest_top][last_position+1] = 1'b1;
                next_tetris_ff[highest_top+1][last_position+1] = 1'b1;
            end
            3'd1:
            begin
                next_tetris_ff[highest_top][last_position] = 1'b1;
                next_tetris_ff[highest_top+1][last_position] = 1'b1;
                if(highest_top<12) next_tetris_ff[highest_top+2][last_position] = 1'b1;
                if(highest_top<11) next_tetris_ff[highest_top+3][last_position] = 1'b1;
            end
            3'd2:
            begin
                next_tetris_ff[highest_top][last_position] = 1'b1;
                next_tetris_ff[highest_top][last_position+1] = 1'b1;
                next_tetris_ff[highest_top][last_position+2] = 1'b1;
                next_tetris_ff[highest_top][last_position+3] = 1'b1;
            end
            3'd3:
            begin
                if(highest_top<14) next_tetris_ff[highest_top][last_position] = 1'b1;
                next_tetris_ff[highest_top-2][last_position+1] = 1'b1;
                next_tetris_ff[highest_top-1][last_position+1] = 1'b1;
                if(highest_top<14) next_tetris_ff[highest_top][last_position+1] = 1'b1;
            end
            3'd4:
            begin
                next_tetris_ff[highest_top-1][last_position] = 1'b1;
                next_tetris_ff[highest_top][last_position] = 1'b1;
                next_tetris_ff[highest_top][last_position+1] = 1'b1;
                next_tetris_ff[highest_top][last_position+2] = 1'b1;
            end
            3'd5:
            begin
                next_tetris_ff[highest_top][last_position] = 1'b1;
                next_tetris_ff[highest_top+1][last_position] = 1'b1;
                if(highest_top<12) next_tetris_ff[highest_top+2][last_position] = 1'b1;
                next_tetris_ff[highest_top][last_position+1] = 1'b1;
            end
            3'd6:
            begin
                next_tetris_ff[highest_top][last_position] = 1'b1;
                if(highest_top<13) next_tetris_ff[highest_top+1][last_position] = 1'b1;
                next_tetris_ff[highest_top-1][last_position+1] = 1'b1;
                next_tetris_ff[highest_top][last_position+1] = 1'b1;
            end
            3'd7:
            begin
                next_tetris_ff[highest_top-1][last_position] = 1'b1;
                next_tetris_ff[highest_top-1][last_position+1] = 1'b1;
                next_tetris_ff[highest_top][last_position+1] = 1'b1;
                next_tetris_ff[highest_top][last_position+2] = 1'b1;
            end
        endcase
    end
    SHIFT:
    begin
        if(&tetris_ff[0])
        begin
            next_tetris_ff[0] = tetris_ff[1];
            next_tetris_ff[1] = tetris_ff[2];
            next_tetris_ff[2] = tetris_ff[3];
            next_tetris_ff[3] = tetris_ff[4];
            next_tetris_ff[4] = tetris_ff[5];
            next_tetris_ff[5] = tetris_ff[6];
            next_tetris_ff[6] = tetris_ff[7];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[1])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[2];
            next_tetris_ff[2] = tetris_ff[3];
            next_tetris_ff[3] = tetris_ff[4];
            next_tetris_ff[4] = tetris_ff[5];
            next_tetris_ff[5] = tetris_ff[6];
            next_tetris_ff[6] = tetris_ff[7];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[2])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[3];
            next_tetris_ff[3] = tetris_ff[4];
            next_tetris_ff[4] = tetris_ff[5];
            next_tetris_ff[5] = tetris_ff[6];
            next_tetris_ff[6] = tetris_ff[7];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[3])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[4];
            next_tetris_ff[4] = tetris_ff[5];
            next_tetris_ff[5] = tetris_ff[6];
            next_tetris_ff[6] = tetris_ff[7];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[4])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[5];
            next_tetris_ff[5] = tetris_ff[6];
            next_tetris_ff[6] = tetris_ff[7];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[5])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[6];
            next_tetris_ff[6] = tetris_ff[7];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[6])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[5];
            next_tetris_ff[6] = tetris_ff[7];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[7])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[5];
            next_tetris_ff[6] = tetris_ff[6];
            next_tetris_ff[7] = tetris_ff[8];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[8])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[5];
            next_tetris_ff[6] = tetris_ff[6];
            next_tetris_ff[7] = tetris_ff[7];
            next_tetris_ff[8] = tetris_ff[9];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[9])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[5];
            next_tetris_ff[6] = tetris_ff[6];
            next_tetris_ff[7] = tetris_ff[7];
            next_tetris_ff[8] = tetris_ff[8];
            next_tetris_ff[9] = tetris_ff[10];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else if(&tetris_ff[10])
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[5];
            next_tetris_ff[6] = tetris_ff[6];
            next_tetris_ff[7] = tetris_ff[7];
            next_tetris_ff[8] = tetris_ff[8];
            next_tetris_ff[9] = tetris_ff[9];
            next_tetris_ff[10] = tetris_ff[11];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
        else //&tetris_ff[11]
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[5];
            next_tetris_ff[6] = tetris_ff[6];
            next_tetris_ff[7] = tetris_ff[7];
            next_tetris_ff[8] = tetris_ff[8];
            next_tetris_ff[9] = tetris_ff[9];
            next_tetris_ff[10] = tetris_ff[10];
            next_tetris_ff[11] = tetris_ff[12];
            next_tetris_ff[12] = tetris_ff[13];
            next_tetris_ff[13] = 6'd0;
        end
    end
    RESULT:
    begin
        if(fail || (counter_16 == 4'd15))
        begin
            next_tetris_ff[0] = 6'd0;
            next_tetris_ff[1] = 6'd0;
            next_tetris_ff[2] = 6'd0;
            next_tetris_ff[3] = 6'd0;
            next_tetris_ff[4] = 6'd0;
            next_tetris_ff[5] = 6'd0;
            next_tetris_ff[6] = 6'd0;
            next_tetris_ff[7] = 6'd0;
            next_tetris_ff[8] = 6'd0;
            next_tetris_ff[9] = 6'd0;
            next_tetris_ff[10] = 6'd0;
            next_tetris_ff[11] = 6'd0;
            next_tetris_ff[12] = 6'd0;
            next_tetris_ff[13] = 6'd0;
        end
        else
        begin
            next_tetris_ff[0] = tetris_ff[0];
            next_tetris_ff[1] = tetris_ff[1];
            next_tetris_ff[2] = tetris_ff[2];
            next_tetris_ff[3] = tetris_ff[3];
            next_tetris_ff[4] = tetris_ff[4];
            next_tetris_ff[5] = tetris_ff[5];
            next_tetris_ff[6] = tetris_ff[6];
            next_tetris_ff[7] = tetris_ff[7];
            next_tetris_ff[8] = tetris_ff[8];
            next_tetris_ff[9] = tetris_ff[9];
            next_tetris_ff[10] = tetris_ff[10];
            next_tetris_ff[11] = tetris_ff[11];
            next_tetris_ff[12] = tetris_ff[12];
            next_tetris_ff[13] = tetris_ff[13];
        end
    end
    default:
    begin
        next_tetris_ff[0] = 6'd0;
        next_tetris_ff[1] = 6'd0;
        next_tetris_ff[2] = 6'd0;
        next_tetris_ff[3] = 6'd0;
        next_tetris_ff[4] = 6'd0;
        next_tetris_ff[5] = 6'd0;
        next_tetris_ff[6] = 6'd0;
        next_tetris_ff[7] = 6'd0;
        next_tetris_ff[8] = 6'd0;
        next_tetris_ff[9] = 6'd0;
        next_tetris_ff[10] = 6'd0;
        next_tetris_ff[11] = 6'd0;
        next_tetris_ff[12] = 6'd0;
        next_tetris_ff[13] = 6'd0;
    end
    endcase
end

always @ (*)
begin
    case(last_tetrominoes)
        3'd0:
        begin
            highest_top = (top[last_position] > top[last_position + 4'd1])?top[last_position]:top[last_position+1];
        end
        3'd1:
        begin
            highest_top = top[last_position];
        end
        3'd2:
        begin
            if((top[last_position] >= top[last_position+1]) && (top[last_position] >= top[last_position+2]) && (top[last_position] >= top[last_position+3]))
            begin
                highest_top = top[last_position];
            end
            else if((top[last_position+1] >= top[last_position+2]) && (top[last_position+1] >= top[last_position+3]))
            begin
                highest_top = top[last_position+1];
            end
            else if(top[last_position+2] >= top[last_position+3])
            begin
                highest_top = top[last_position+2];
            end
            else
            begin
                highest_top = top[last_position+3];
            end
        end
        3'd3:
        begin
            highest_top = (top[last_position] >= (top[last_position+1] + 4'd2))?top[last_position]:(top[last_position+1] + 4'd2);
        end
        3'd4:
        begin
            if(((top[last_position] + 4'd1) >= top[last_position+1]) && ((top[last_position] + 4'd1) >= top[last_position+2]))
            begin
                highest_top = top[last_position] + 4'd1;
            end
            else if(top[last_position+1] >= top[last_position+2])
            begin
                highest_top = top[last_position+1];
            end
            else
            begin
                highest_top = top[last_position+2];
            end
        end
        3'd5:
        begin
            highest_top = (top[last_position] > top[last_position+1])?top[last_position]:top[last_position+1];
        end
        3'd6:
        begin
            highest_top = (top[last_position] >= (top[last_position+1] + 4'd1))?top[last_position]:(top[last_position+1] + 4'd1);
        end
        3'd7:
        begin
            if(((top[last_position] + 4'd1) >= (top[last_position+1] + 4'd1)) && ((top[last_position] + 4'd1) >= top[last_position+2]))
            begin
                highest_top = top[last_position] + 4'd1;
            end
            else if((top[last_position+1] + 4'd1) >= top[last_position+2])
            begin
                highest_top = top[last_position+1] + 4'd1;
            end
            else
            begin
                highest_top = top[last_position+2];
            end
        end
    endcase
end

always @ (posedge clk)
begin
    if(state==IDLE)
    begin
        top[0] <= next_top[0];
        top[1] <= next_top[1];
        top[2] <= next_top[2];
        top[3] <= next_top[3];
        top[4] <= next_top[4];
        top[5] <= next_top[5];
    end
    else
    begin
        top[0] <= top[0];
        top[1] <= top[1];
        top[2] <= top[2];
        top[3] <= top[3];
        top[4] <= top[4];
        top[5] <= top[5];
    end
end

always @ (*)
begin
    if(tetris_ff[11][0] == 1'b1) next_top[0] = 4'd12;
    else if(tetris_ff[10][0] == 1'b1) next_top[0] = 4'd11;
    else if(tetris_ff[9][0] == 1'b1) next_top[0] = 4'd10;
    else if(tetris_ff[8][0] == 1'b1) next_top[0] = 4'd9;
    else if(tetris_ff[7][0] == 1'b1) next_top[0] = 4'd8;
    else if(tetris_ff[6][0] == 1'b1) next_top[0] = 4'd7;
    else if(tetris_ff[5][0] == 1'b1) next_top[0] = 4'd6;
    else if(tetris_ff[4][0] == 1'b1) next_top[0] = 4'd5;
    else if(tetris_ff[3][0] == 1'b1) next_top[0] = 4'd4;
    else if(tetris_ff[2][0] == 1'b1) next_top[0] = 4'd3;
    else if(tetris_ff[1][0] == 1'b1) next_top[0] = 4'd2;
    else if(tetris_ff[0][0] == 1'b1) next_top[0] = 4'd1;
    else next_top[0] = 4'd0;
    
    if(tetris_ff[11][1] == 1'b1) next_top[1] = 4'd12;
    else if(tetris_ff[10][1] == 1'b1) next_top[1] = 4'd11;
    else if(tetris_ff[9][1] == 1'b1) next_top[1] = 4'd10;
    else if(tetris_ff[8][1] == 1'b1) next_top[1] = 4'd9;
    else if(tetris_ff[7][1] == 1'b1) next_top[1] = 4'd8;
    else if(tetris_ff[6][1] == 1'b1) next_top[1] = 4'd7;
    else if(tetris_ff[5][1] == 1'b1) next_top[1] = 4'd6;
    else if(tetris_ff[4][1] == 1'b1) next_top[1] = 4'd5;
    else if(tetris_ff[3][1] == 1'b1) next_top[1] = 4'd4;
    else if(tetris_ff[2][1] == 1'b1) next_top[1] = 4'd3;
    else if(tetris_ff[1][1] == 1'b1) next_top[1] = 4'd2;
    else if(tetris_ff[0][1] == 1'b1) next_top[1] = 4'd1;
    else next_top[1] = 4'd0;

    if(tetris_ff[11][2] == 1'b1) next_top[2] = 4'd12;
    else if(tetris_ff[10][2] == 1'b1) next_top[2] = 4'd11;
    else if(tetris_ff[9][2] == 1'b1) next_top[2] = 4'd10;
    else if(tetris_ff[8][2] == 1'b1) next_top[2] = 4'd9;
    else if(tetris_ff[7][2] == 1'b1) next_top[2] = 4'd8;
    else if(tetris_ff[6][2] == 1'b1) next_top[2] = 4'd7;
    else if(tetris_ff[5][2] == 1'b1) next_top[2] = 4'd6;
    else if(tetris_ff[4][2] == 1'b1) next_top[2] = 4'd5;
    else if(tetris_ff[3][2] == 1'b1) next_top[2] = 4'd4;
    else if(tetris_ff[2][2] == 1'b1) next_top[2] = 4'd3;
    else if(tetris_ff[1][2] == 1'b1) next_top[2] = 4'd2;
    else if(tetris_ff[0][2] == 1'b1) next_top[2] = 4'd1;
    else next_top[2] = 4'd0;

    if(tetris_ff[11][3] == 1'b1) next_top[3] = 4'd12;
    else if(tetris_ff[10][3] == 1'b1) next_top[3] = 4'd11;
    else if(tetris_ff[9][3] == 1'b1) next_top[3] = 4'd10;
    else if(tetris_ff[8][3] == 1'b1) next_top[3] = 4'd9;
    else if(tetris_ff[7][3] == 1'b1) next_top[3] = 4'd8;
    else if(tetris_ff[6][3] == 1'b1) next_top[3] = 4'd7;
    else if(tetris_ff[5][3] == 1'b1) next_top[3] = 4'd6;
    else if(tetris_ff[4][3] == 1'b1) next_top[3] = 4'd5;
    else if(tetris_ff[3][3] == 1'b1) next_top[3] = 4'd4;
    else if(tetris_ff[2][3] == 1'b1) next_top[3] = 4'd3;
    else if(tetris_ff[1][3] == 1'b1) next_top[3] = 4'd2;
    else if(tetris_ff[0][3] == 1'b1) next_top[3] = 4'd1;
    else next_top[3] = 4'd0;

    if(tetris_ff[11][4] == 1'b1) next_top[4] = 4'd12;
    else if(tetris_ff[10][4] == 1'b1) next_top[4] = 4'd11;
    else if(tetris_ff[9][4] == 1'b1) next_top[4] = 4'd10;
    else if(tetris_ff[8][4] == 1'b1) next_top[4] = 4'd9;
    else if(tetris_ff[7][4] == 1'b1) next_top[4] = 4'd8;
    else if(tetris_ff[6][4] == 1'b1) next_top[4] = 4'd7;
    else if(tetris_ff[5][4] == 1'b1) next_top[4] = 4'd6;
    else if(tetris_ff[4][4] == 1'b1) next_top[4] = 4'd5;
    else if(tetris_ff[3][4] == 1'b1) next_top[4] = 4'd4;
    else if(tetris_ff[2][4] == 1'b1) next_top[4] = 4'd3;
    else if(tetris_ff[1][4] == 1'b1) next_top[4] = 4'd2;
    else if(tetris_ff[0][4] == 1'b1) next_top[4] = 4'd1;
    else next_top[4] = 4'd0;

    if(tetris_ff[11][5] == 1'b1) next_top[5] = 4'd12;
    else if(tetris_ff[10][5] == 1'b1) next_top[5] = 4'd11;
    else if(tetris_ff[9][5] == 1'b1) next_top[5] = 4'd10;
    else if(tetris_ff[8][5] == 1'b1) next_top[5] = 4'd9;
    else if(tetris_ff[7][5] == 1'b1) next_top[5] = 4'd8;
    else if(tetris_ff[6][5] == 1'b1) next_top[5] = 4'd7;
    else if(tetris_ff[5][5] == 1'b1) next_top[5] = 4'd6;
    else if(tetris_ff[4][5] == 1'b1) next_top[5] = 4'd5;
    else if(tetris_ff[3][5] == 1'b1) next_top[5] = 4'd4;
    else if(tetris_ff[2][5] == 1'b1) next_top[5] = 4'd3;
    else if(tetris_ff[1][5] == 1'b1) next_top[5] = 4'd2;
    else if(tetris_ff[0][5] == 1'b1) next_top[5] = 4'd1;
    else next_top[5] = 4'd0;
end

always @ (*)
begin
    if(state == RESULT)
    begin
        if((counter_16 == 4'd15)||fail) next_counter_16 = 4'd0;
        else next_counter_16 = counter_16 + 4'd1;
    end
    else next_counter_16 = counter_16;
end

always @ (*)
begin
    is_line_fill =  (&next_tetris_ff[0]) || (&next_tetris_ff[1]) || (&next_tetris_ff[2]) || (&next_tetris_ff[3]) || 
                    (&next_tetris_ff[4]) || (&next_tetris_ff[5]) || (&next_tetris_ff[6]) || (&next_tetris_ff[7]) || 
                    (&next_tetris_ff[8]) || (&next_tetris_ff[9]) || (&next_tetris_ff[10]) || (&next_tetris_ff[11]);
end

//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
always @ (*)
begin
    if((state == RESULT)&&(fail || (counter_16 == 4'd15))) next_score_ff = 4'd0;
    else if(state == SHIFT) next_score_ff = score_ff + 4'd1;
    else next_score_ff = score_ff;
end

always @ (*)
begin
    if((state == RESULT)&&(|tetris_ff[12])) fail = 1'b1;
    else fail = 1'b0;
end

always @ (*)
begin
    if(state == RESULT) score_valid = 1'b1;
    else score_valid = 1'b0;
end

always @ (*)
begin
    if((state == RESULT)&&(fail || (counter_16 == 4'd15))) tetris_valid = 1'b1;
    else tetris_valid = 1'b0;
end

always @ (*)
begin
    if(score_valid) score = score_ff;
    else score = 4'd0;
end

always @ (*)
begin
    if(tetris_valid) tetris = {tetris_ff[11], tetris_ff[10], tetris_ff[9], tetris_ff[8], tetris_ff[7], tetris_ff[6], tetris_ff[5], tetris_ff[4], tetris_ff[3], tetris_ff[2], tetris_ff[1], tetris_ff[0]};
    else tetris = 72'd0;
end
endmodule*/