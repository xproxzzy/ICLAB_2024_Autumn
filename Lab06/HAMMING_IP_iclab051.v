//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/10
//		Version		: v1.0
//   	File Name   : HAMMING_IP.v
//   	Module Name : HAMMING_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module HAMMING_IP #(parameter IP_BIT = 8) (
    // Input signals
    IN_code,
    // Output signals
    OUT_code
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_BIT+4-1:0]  IN_code;

output reg [IP_BIT-1:0] OUT_code;

// ===============================================================
// Design
// ===============================================================
reg [3:0] hamming_code;
reg [IP_BIT+4-1:0] true_IN_code;

generate
    case(IP_BIT)
        5:
        begin: HAMMING_5
            always @ (*)
            begin
                hamming_code[0] = IN_code[0] ^ IN_code[2] ^ IN_code[4] ^ IN_code[6] ^ IN_code[8];
                hamming_code[1] = IN_code[2] ^ IN_code[3] ^ IN_code[6] ^ IN_code[7];
                hamming_code[2] = IN_code[2] ^ IN_code[3] ^ IN_code[4] ^ IN_code[5];
                hamming_code[3] = IN_code[0] ^ IN_code[1];
                true_IN_code = IN_code;
                if(hamming_code != 4'd0)
                begin
                    true_IN_code[9-hamming_code] = !IN_code[9-hamming_code];
                end
                OUT_code = {true_IN_code[6], true_IN_code[4:2], true_IN_code[0]};
            end
        end
        6:
        begin: HAMMING_6
            always @ (*)
            begin
                hamming_code[0] = IN_code[1] ^ IN_code[3] ^ IN_code[5] ^ IN_code[7] ^ IN_code[9];
                hamming_code[1] = IN_code[0] ^ IN_code[3] ^ IN_code[4] ^ IN_code[7] ^ IN_code[8];
                hamming_code[2] = IN_code[3] ^ IN_code[4] ^ IN_code[5] ^ IN_code[6];
                hamming_code[3] = IN_code[0] ^ IN_code[1] ^ IN_code[2];
                true_IN_code = IN_code;
                if(hamming_code != 4'd0)
                begin
                    true_IN_code[10-hamming_code] = !IN_code[10-hamming_code];
                end
                OUT_code = {true_IN_code[7], true_IN_code[5:3], true_IN_code[1:0]};
            end
        end
        7:
        begin: HAMMING_7
            always @ (*)
            begin
                hamming_code[0] = IN_code[0] ^ IN_code[2] ^ IN_code[4] ^ IN_code[6] ^ IN_code[8] ^ IN_code[10];
                hamming_code[1] = IN_code[0] ^ IN_code[1] ^ IN_code[4] ^ IN_code[5] ^ IN_code[8] ^ IN_code[9];
                hamming_code[2] = IN_code[4] ^ IN_code[5] ^ IN_code[6] ^ IN_code[7];
                hamming_code[3] = IN_code[0] ^ IN_code[1] ^ IN_code[2] ^ IN_code[3];
                true_IN_code = IN_code;
                if(hamming_code != 4'd0)
                begin
                    true_IN_code[11-hamming_code] = !IN_code[11-hamming_code];
                end
                OUT_code = {true_IN_code[8], true_IN_code[6:4], true_IN_code[2:0]};
            end
        end
        8:
        begin: HAMMING_8
            always @ (*)
            begin
                hamming_code[0] = IN_code[1] ^ IN_code[3] ^ IN_code[5] ^ IN_code[7] ^ IN_code[9] ^ IN_code[11];
                hamming_code[1] = IN_code[1] ^ IN_code[2] ^ IN_code[5] ^ IN_code[6] ^ IN_code[9] ^ IN_code[10];
                hamming_code[2] = IN_code[0] ^ IN_code[5] ^ IN_code[6] ^ IN_code[7] ^ IN_code[8];
                hamming_code[3] = IN_code[0] ^ IN_code[1] ^ IN_code[2] ^ IN_code[3] ^ IN_code[4];
                true_IN_code = IN_code;
                if(hamming_code != 4'd0)
                begin
                    true_IN_code[12-hamming_code] = !IN_code[12-hamming_code];
                end
                OUT_code = {true_IN_code[9], true_IN_code[7:5], true_IN_code[3:0]};
            end
        end
        9:
        begin: HAMMING_9
            always @ (*)
            begin
                hamming_code[0] = IN_code[0] ^ IN_code[2] ^ IN_code[4] ^ IN_code[6] ^ IN_code[8] ^ IN_code[10] ^ IN_code[12];
                hamming_code[1] = IN_code[2] ^ IN_code[3] ^ IN_code[6] ^ IN_code[7] ^ IN_code[10] ^ IN_code[11];
                hamming_code[2] = IN_code[0] ^ IN_code[1] ^ IN_code[6] ^ IN_code[7] ^ IN_code[8] ^ IN_code[9];
                hamming_code[3] = IN_code[0] ^ IN_code[1] ^ IN_code[2] ^ IN_code[3] ^ IN_code[4] ^ IN_code[5];
                true_IN_code = IN_code;
                if(hamming_code != 4'd0)
                begin
                    true_IN_code[13-hamming_code] = !IN_code[13-hamming_code];
                end
                OUT_code = {true_IN_code[10], true_IN_code[8:6], true_IN_code[4:0]};
            end
        end
        10:
        begin: HAMMING_10
            always @ (*)
            begin
                hamming_code[0] = IN_code[1] ^ IN_code[3] ^ IN_code[5] ^ IN_code[7] ^ IN_code[9] ^ IN_code[11] ^ IN_code[13];
                hamming_code[1] = IN_code[0] ^ IN_code[3] ^ IN_code[4] ^ IN_code[7] ^ IN_code[8] ^ IN_code[11] ^ IN_code[12];
                hamming_code[2] = IN_code[0] ^ IN_code[1] ^ IN_code[2] ^ IN_code[7] ^ IN_code[8] ^ IN_code[9] ^ IN_code[10];
                hamming_code[3] = IN_code[0] ^ IN_code[1] ^ IN_code[2] ^ IN_code[3] ^ IN_code[4] ^ IN_code[5] ^ IN_code[6];
                true_IN_code = IN_code;
                if(hamming_code != 4'd0)
                begin
                    true_IN_code[14-hamming_code] = !IN_code[14-hamming_code];
                end
                OUT_code = {true_IN_code[11], true_IN_code[9:7], true_IN_code[5:0]};
            end
        end
        default:
        begin: HAMMING_11
            always @ (*)
            begin
                hamming_code[0] = IN_code[0] ^ IN_code[2] ^ IN_code[4] ^ IN_code[6] ^ IN_code[8] ^ IN_code[10] ^ IN_code[12] ^ IN_code[14];
                hamming_code[1] = IN_code[0] ^ IN_code[1] ^ IN_code[4] ^ IN_code[5] ^ IN_code[8] ^ IN_code[9] ^ IN_code[12] ^ IN_code[13];
                hamming_code[2] = IN_code[0] ^ IN_code[1] ^ IN_code[2] ^ IN_code[3] ^ IN_code[8] ^ IN_code[9] ^ IN_code[10] ^ IN_code[11];
                hamming_code[3] = IN_code[0] ^ IN_code[1] ^ IN_code[2] ^ IN_code[3] ^ IN_code[4] ^ IN_code[5] ^ IN_code[6] ^ IN_code[7];
                true_IN_code = IN_code;
                if(hamming_code != 4'd0)
                begin
                    true_IN_code[15-hamming_code] = !IN_code[15-hamming_code];
                end
                OUT_code = {true_IN_code[12], true_IN_code[10:8], true_IN_code[6:0]};
            end
        end
    endcase
endgenerate

endmodule