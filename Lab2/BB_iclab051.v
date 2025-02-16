module BB(
    //Input Ports
    input clk,
    input rst_n,
    input in_valid,
    input [1:0] inning,   // Current inning number
    input half,           // 0: top of the inning, 1: bottom of the inning
    input [2:0] action,   // Action code

    //Output Ports
    output reg out_valid,  // Result output valid
    output reg [7:0] score_A,  // Score of team A (guest team)
    output reg [7:0] score_B,  // Score of team B (home team)
    output reg [1:0] result    // 0: Team A wins, 1: Team B wins, 2: Darw
);

//==============================================//
//             Action Memo for Students         //
// Action code interpretation:
// 3’d0: Walk (BB)
// 3’d1: 1H (single hit)
// 3’d2: 2H (double hit)
// 3’d3: 3H (triple hit)
// 3’d4: HR (home run)
// 3’d5: Bunt (short hit)
// 3’d6: Ground ball
// 3’d7: Fly ball
//==============================================//

//==============================================//
//             Parameter and Integer            //
//==============================================//
// State declaration for FSM
// Example: parameter IDLE = 3'b000;
parameter WALK = 3'd0, SINGLE = 3'd1, DOUBLE = 3'd2, TRIPLE = 3'd3, HR = 3'd4, BUNT = 3'd5, GROUND = 3'd6, FLY = 3'd7;
parameter IDLE = 2'd0, PLAY = 2'd1, WAIT = 2'd2, RESULT = 2'd3;

//==============================================//
//                 reg declaration              //
//==============================================//
reg [1:0] state;
reg [1:0] next_state;
reg [1:0] out;
reg [1:0] next_out;
reg [2:0] base;
reg [2:0] next_base;
reg [3:0] now_score;
reg [3:0] get_score;
reg [7:0] update_score;

reg [1:0] last_inning;
reg last_half;
reg [2:0] last_action;

reg is_two_out;
reg is_one_out;
//reg is_double_play;
//reg is_third_inning;
reg [1:0] base_2_1;
reg [1:0] base_2_1_0;
//reg [1:0] out_1;

reg [3:0] score_A_ff;
reg [2:0] score_B_ff;

always @ (*)
begin
    now_score = (last_half)?score_B_ff:score_A_ff;
    update_score = now_score + get_score;
    //is_two_out = (out == 2'd2);
    is_two_out = out[1];
    //is_one_out = (out == 2'd1);
    is_one_out = out[0];
    //is_double_play = ((out == 2'd1) && (base[0] == 1'b1));

    //is_third_inning = (last_inning == 2'd3)
    base_2_1 = base[2] + base[1];
    base_2_1_0 = base[2] + base[1] + base[0];
    //out_1 = out + 2'd1;

    score_A = {4'd0, score_A_ff};
    score_B = {5'd0, score_B_ff};
end
//==============================================//
//             Current State Block              //
//==============================================//
always @ (posedge clk or negedge rst_n)
begin
    if(rst_n == 1'b0)
    begin
        state <= IDLE;
        score_A_ff <= 4'd0;
        score_B_ff <= 3'd0;
        last_inning <= 2'd0;
        last_half <= 1'b0;
        last_action <= 3'd0;
    end
    else
    begin
        state <= next_state;
        if(state == PLAY)
        begin
            if(last_half)
            begin
                score_A_ff <= score_A_ff;
                score_B_ff <= update_score;
            end
            else
            begin
                score_A_ff <= update_score;
                score_B_ff <= score_B_ff;
            end
        end
        else if(state == RESULT)
        begin
            score_A_ff <= 4'd0;
            score_B_ff <= 3'd0;
        end
        else
        begin
            score_A_ff <= score_A_ff;
            score_B_ff <= score_B_ff;
        end
        last_inning <= inning;
        last_half <= half;
        last_action <= action;
    end
end

//==============================================//
//              Next State Block                //
//==============================================//

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
        case(last_action)
        WALK:
        begin
            next_state = PLAY;
        end
        SINGLE:
        begin
            next_state = PLAY;
        end
        DOUBLE:
        begin
            next_state = PLAY;
        end
        TRIPLE:
        begin
            next_state = PLAY;
        end
        HR:
        begin
            next_state = PLAY;
        end
        BUNT:
        begin
            if((is_two_out) && (last_inning[0] == last_inning[1]))
            begin
                if(last_half == 1'd0)
                begin
                    if(score_B_ff > score_A_ff)
                    begin
                        next_state = WAIT;
                    end
                    else
                    begin
                        next_state = PLAY;
                    end
                end
                else
                begin
                    next_state = RESULT;
                end
            end
            else
            begin
                next_state = PLAY;
            end
        end
        GROUND:
        begin
            if((is_two_out || (is_one_out && (base[0] == 1'b1))) && (last_inning[0] == last_inning[1]))
            begin
                if(last_half == 1'd0)
                begin
                    if(score_B_ff > score_A_ff)
                    begin
                        next_state = WAIT;
                    end
                    else
                    begin
                        next_state = PLAY;
                    end
                end
                else
                begin
                    next_state = RESULT;
                end
            end
            else
            begin
                next_state = PLAY;
            end
        end
        FLY:
        begin
            if((is_two_out) && (last_inning[0] == last_inning[1]))
            begin
                if(last_half == 1'd0)
                begin
                    if(score_B_ff > score_A_ff)
                    begin
                        next_state = WAIT;
                    end
                    else
                    begin
                        next_state = PLAY;
                    end
                end
                else
                begin
                    next_state = RESULT;
                end
            end
            else
            begin
                next_state = PLAY;
            end
        end
        default:
        begin
            next_state = PLAY;
        end
        endcase
    end
    WAIT:
    begin
        if(in_valid) next_state = WAIT;
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

//==============================================//
//             Base and Score Logic             //
//==============================================//
// Handle base runner movements and score calculation.
// Update bases and score depending on the last_action:
// Example: Walk, Hits (1H, 2H, 3H), Home Runs, etc.
always @ (posedge clk)
begin
    if(state==IDLE)
    begin
        out <= 2'd0;
        base <= 3'd0;
    end
    else
    begin
        out <= next_out;
        base <= next_base;
    end
end

always @ (*)
begin
    case(last_action)
    WALK:
    begin
        next_out = out;
    end
    SINGLE:
    begin
        next_out = out;
    end
    DOUBLE:
    begin
        next_out = out;
    end
    TRIPLE:
    begin
        next_out = out;
    end
    HR:
    begin
        next_out = out;
    end
    BUNT:
    begin
        if(is_two_out) next_out = 2'd0;
        else next_out = out + 2'd1;
    end
    GROUND:
    begin
        if(is_two_out || (is_one_out && (base[0] == 1'b1))) next_out = 2'd0;
        else if(base[0] == 1'b1) next_out = out + 2'd2;
        else next_out = out + 2'd1;
    end
    FLY:
    begin
        if(is_two_out) next_out = 2'd0;
        else next_out = out + 2'd1;
    end
    default:next_out = out;
    endcase
end

always @ (*)
begin
    case(last_action)
    WALK:
    begin
        case(base)
        3'b001:next_base = 3'b011;
        3'b011, 3'b101, 3'b111:next_base = 3'b111;
        default:next_base = {base[2:1], 1'b1};
        endcase
    end
    SINGLE:
    begin
        if(is_two_out) next_base = {base[0], 2'b01};
        else next_base = {base[1:0], 1'b1};
    end
    DOUBLE:
    begin
        if(is_two_out) next_base = 3'b010;
        else next_base = {base[0], 2'b10};
    end
    TRIPLE:
    begin
        next_base = 3'b100;
    end
    HR:
    begin
        next_base = 3'd0;
    end
    BUNT:
    begin
        if(is_two_out) next_base = 3'd0;
        else next_base = {base[1:0], 1'b0};
    end
    GROUND:
    begin
        if(is_two_out || (is_one_out && (base[0] == 1'b1))) next_base = 3'd0;
        else next_base = {base[1], 2'b00};
    end
    FLY:
    begin
        if(is_two_out) next_base = 3'd0;
        else next_base = {1'b0, base[1:0]};
    end
    default:next_base = base;
    endcase
end

//==============================================//
//                Output Block                  //
//==============================================//
// Decide when to set out_valid high, and output score_A, score_B, and result.

always @ (*)
begin
    case(last_action)
    WALK:
    begin
        if(base == 3'b111) get_score = 4'd1;
        else get_score = 4'd0;
    end
    SINGLE:
    begin
        if(is_two_out) get_score = base_2_1;
        else get_score = base[2];
    end
    DOUBLE:
    begin
        if(is_two_out) get_score = base_2_1_0;
        else get_score = base_2_1;
    end
    TRIPLE:
    begin
        get_score = base_2_1_0;
    end
    HR:
    begin
        get_score = base_2_1_0 + 4'd1;
    end
    BUNT:
    begin
        if(base[2]) get_score = 4'd1;
        else get_score = 4'd0;
    end
    GROUND:
    begin
        if(is_two_out || (is_one_out && (base[0] == 1'b1)) || (base[2] == 1'b0)) get_score = 4'd0;
        else get_score = 4'd1;
    end
    FLY:
    begin
        if(is_two_out || (base[2] == 1'b0)) get_score = 4'd0;
        else get_score = 4'd1;
    end
    default: get_score = 4'd0;
    endcase
end

always @ (*)
begin
    if(rst_n == 1'b0) result = 2'd0;
    else if(score_A_ff == score_B_ff) result = 2'd2;
    else if(score_A_ff < score_B_ff) result = 2'd1;
    else result = 2'd0;
end

always @ (*)
begin
    if(state == RESULT) out_valid = 1'b1;
    else out_valid = 1'b0;
end

endmodule