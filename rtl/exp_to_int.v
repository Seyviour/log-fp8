module ExpToFP8 (
    input wire [3:0] exp_val,
    input wire is_subnormal, 

    output reg [7:0] exp_float
); 

/*
    input:
        is_subnormal[0:0] -> value under consideration is subnormal 
        exp_val[3:0] -> mantissa when is_subnormal is asserted, exponent otherwise (E4M3 FP8) 
*/


always @(*) begin
    case({is_subnormal, exp_val})

        5'b10001: exp_float = 8'b1_1010_001; //-9
        5'b1001?: exp_float = 8'b1_1010_000; //-8
        5'b101??: exp_float = 8'b1_1001_110; //-7
        5'b00001: exp_float = 8'b1_1001_100; //-6
        7'b00010: exp_float = 8'b1_1001_010; //-5
        7'b00011: exp_float = 8'b1_1001_000; //-4
        7'b00100: exp_float = 8'b1_1000_100; //-3
        7'b00101: exp_float = 8'b1_1000_000; //-2
        7'b00110: exp_float = 8'b1_0111_000; //-1
        7'b00111: exp_float = 8'b?_0000_000; // 0
        7'b01000: exp_float = 8'b0_0111_000; // 1
        7'b01001: exp_float = 8'b0_1000_000; // 2
        7'b01010: exp_float = 8'b0_1000_100; // 3
        7'b01011: exp_float = 8'b0_1001_000; // 4
        7'b01100: exp_float = 8'b0_1001_010; // 5
        7'b01101: exp_float = 8'b0_1001_100; // 6
        7'b01110: exp_float = 8'b0_1001_110; // 7
        7'b01111: exp_float = 8'b0_1010_000; // 8

        default: exp_float = 8'b?_0000_000; 
    endcase
end


endmodule