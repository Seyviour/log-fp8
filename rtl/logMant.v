module logMant (
    input wire [3:0] mant,
    output reg [7:0] log_mant
);
    
/*
    input:
        mant [3:0] -> e4m3 mantissa
    
    output:
        log_mant[7:0] log2(mant), E4M3 representation
    Normalized log of mantissa
    Subnormal mantissas give the result they 
    would give if they left-shifted to be normal
*/

always @(*) begin
    case (mant)
        4'b0001: log_mant = 8'b0000_0000; 
        4'b0010: log_mant = 8'b0000_0000; 
        4'b0011: log_mant = 8'b0011_0001;
        4'b0100: log_mant = 8'b0000_0000; 
        4'b0101: log_mant = 8'b0010_1010;
        4'b0110: log_mant = 8'b0011_0001;
        4'b0111: log_mant = 8'b0011_0101;
        4'b1000: log_mant = 8'b0000_0000; 
        4'b1001: log_mant = 8'b0010_0011; 
        4'b1010: log_mant = 8'b0010_1010; 
        4'b1011: log_mant = 8'b0010_1111; 
        4'b1100: log_mant = 8'b0011_0001;
        4'b1101: log_mant = 8'b0011_0011;
        4'b1110: log_mant = 8'b0011_0101;
        4'b1111: log_mant = 8'b0011_0111;
        
        default: log_mant =  8'b0011_1111; 
    endcase
end


endmodule