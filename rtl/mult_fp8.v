`default_nettype none

module multFP8 (
    input wire [7:0] A, B,
    output reg [7:0] AB
);

    reg [3:0] _expA, _expB;
    reg signA, signB;
    reg signResult; 


    reg [2:0] _mantA, _mantB;
    reg [3:0] mantA, mantAN, mantB, mantBN; 

    reg [3:0] mant1, mant2;  
    
    reg redOrExpA, redOrExpB;
    reg a_is_subnormal, b_is_subnormal;
    reg [3:0] a_exp_or_sub_mant, b_exp_or_sub_mant; 

    always @(*) begin

        {signA, _expA, _mantA} = A;
        {signB, _expB, _mantB} = B; 

        signResult = signA ^ signB;

        redOrExpA = |(_expA);
        redOrExpB = |(_expB);

        a_is_subnormal = !redOrExpA;
        b_is_subnormal = !redOrExpB; 

        mantA = {redOrExpA, _mantA};
        mantB = {redOrExpB, _mantB}; 
    end

    always @(*) begin
        a_exp_or_sub_mant = a_is_subnormal? {1'b0, _mantA}: _expA;
        b_exp_or_sub_mant = b_is_subnormal? {1'b0, _mantB}: _expB;  
    end

    wire [5:0] expNA, expNB;
    wire [3:0] mantAmantB;
    wire plus_exp; 

    normalizeMant mantNormA (.mant(mantA), .mantN(mantAN));
    normalizeMant mantNormB (.mant(mantB), .mantN(mantBN));

    normalizeExp expNormA (.is_subnormal(a_is_subnormal), .exp_or_sub_mant(a_exp_or_sub_mant), .expN(expNA));
    normalizeExp expNormB (.is_subnormal(b_is_subnormal), .exp_or_sub_mant(b_exp_or_sub_mant), .expN(expNB));

    multMant myMult (.mantA(mantAN), .mantB(mantBN), .mantAmantB(mantAmantB), .plus_exp(plus_exp));

    reg [2:0] rs_amt;
    reg [3:0] resultExp;

    reg [5:0] _expSum;
    always @(*) begin
        _expSum = expNA + expNB + plus_exp - 6'd7;
    end

    always @(*) begin
        rs_amt = 3'b000;
        resultExp = _expSum[3:0];

        if (_expSum[5] || (_expSum == 6'b000_000)) begin
            resultExp = 4'b0000; //underflow
            rs_amt = 1 - _expSum; 
        end else if(_expSum [4])
            resultExp = 4'b1111;

    end

    reg [2:0] resultMant; 
    always @(*) begin
        resultMant = mantAmantB >> rs_amt;
    end

    always @(*) begin
        AB = {signResult, resultExp, resultMant };
    end
    //Negative Underflow -> _expSum[5] is set;
    //Positive Overflow -> _expSum[4] is set;
    //True shift -> -val if negative underflow
    //

endmodule



module multMant (
    input [3:0] mantA, mantB,
    output reg plus_exp,
    output reg [3:0] mantAmantB
);
    always @(*) begin

        case ({mantA[2:0], mantB[2:0]})

            6'b000_000: {plus_exp, mantAmantB} = {1'b0, 4'b1_000}; //000
            6'b000_001: {plus_exp, mantAmantB} = {1'b0, 4'b1_001}; //000
            6'b000_010: {plus_exp, mantAmantB} = {1'b0, 4'b1_010}; //000
            6'b000_011: {plus_exp, mantAmantB} = {1'b0, 4'b1_011}; //000
            6'b000_100: {plus_exp, mantAmantB} = {1'b0, 4'b1_100}; //000
            6'b000_101: {plus_exp, mantAmantB} = {1'b0, 4'b1_101}; //000
            6'b000_110: {plus_exp, mantAmantB} = {1'b0, 4'b1_110}; //000
            6'b000_111: {plus_exp, mantAmantB} = {1'b0, 4'b1_111}; //000

            6'b001_000: {plus_exp, mantAmantB} = {1'b0, 4'b1_001}; //000
            6'b001_001: {plus_exp, mantAmantB} = {1'b0, 4'b1_010}; //001
            6'b001_010: {plus_exp, mantAmantB} = {1'b0, 4'b1_011}; //010
            6'b001_011: {plus_exp, mantAmantB} = {1'b0, 4'b1_100}; //011
            6'b001_100: {plus_exp, mantAmantB} = {1'b0, 4'b1_101}; //100
            6'b001_101: {plus_exp, mantAmantB} = {1'b0, 4'b1_110}; //101
            6'b001_110: {plus_exp, mantAmantB} = {1'b0, 4'b1_111}; //110
            6'b001_111: {plus_exp, mantAmantB} = {1'b1, 4'b10_00}; //0111 nls

            6'b010_000: {plus_exp, mantAmantB} = {1'b0, 4'b1_010}; //000
            6'b010_001: {plus_exp, mantAmantB} = {1'b0, 4'b1_011}; //010
            6'b010_010: {plus_exp, mantAmantB} = {1'b0, 4'b1_100}; //100
            6'b010_011: {plus_exp, mantAmantB} = {1'b0, 4'b1_101}; //110
            6'b010_100: {plus_exp, mantAmantB} = {1'b0, 4'b1_111}; //000
            6'b010_101: {plus_exp, mantAmantB} = {1'b1, 4'b10_00}; //0010 nls
            6'b010_110: {plus_exp, mantAmantB} = {1'b1, 4'b10_00}; //1100 nls
            6'b010_111: {plus_exp, mantAmantB} = {1'b1, 4'b10_01}; //0110 nls

            6'b011_000: {plus_exp, mantAmantB} = {1'b0, 4'b1_011}; //000
            6'b011_001: {plus_exp, mantAmantB} = {1'b0, 4'b1_100}; //011
            6'b011_010: {plus_exp, mantAmantB} = {1'b0, 4'b1_101}; //110
            6'b011_011: {plus_exp, mantAmantB} = {1'b0, 4'b1_111}; //001
            6'b011_100: {plus_exp, mantAmantB} = {1'b1, 4'b10_00}; //0100 nls
            6'b011_101: {plus_exp, mantAmantB} = {1'b1, 4'b10_00}; //1111 nls
            6'b011_110: {plus_exp, mantAmantB} = {1'b1, 4'b10_01}; //1010 nls
            6'b011_111: {plus_exp, mantAmantB} = {1'b1, 4'b10_10}; //0101 nls

            6'b100_000: {plus_exp, mantAmantB} = {1'b0, 4'b1_100}; //000
            6'b100_001: {plus_exp, mantAmantB} = {1'b0, 4'b1_101}; //100
            6'b100_010: {plus_exp, mantAmantB} = {1'b0, 4'b1_111}; //000
            6'b100_011: {plus_exp, mantAmantB} = {1'b0, 4'b10_00}; //010
            6'b100_100: {plus_exp, mantAmantB} = {1'b1, 4'b10_01}; //0000 nls
            6'b100_101: {plus_exp, mantAmantB} = {1'b1, 4'b10_01}; //1100 nls
            6'b100_110: {plus_exp, mantAmantB} = {1'b1, 4'b10_10}; //1000 nls
            6'b100_111: {plus_exp, mantAmantB} = {1'b1, 4'b10_11}; //0100 nls

            6'b101_000: {plus_exp, mantAmantB} = {1'b0, 4'b1_101}; //000
            6'b101_001: {plus_exp, mantAmantB} = {1'b0, 4'b1_110}; //101
            6'b101_010: {plus_exp, mantAmantB} = {1'b1, 4'b10_00}; //0010 nls
            6'b101_011: {plus_exp, mantAmantB} = {1'b1, 4'b10_00}; //1111 nls
            6'b101_100: {plus_exp, mantAmantB} = {1'b1, 4'b10_01}; //1100 nls
            6'b101_101: {plus_exp, mantAmantB} = {1'b1, 4'b10_10}; //1001 nls
            6'b101_110: {plus_exp, mantAmantB} = {1'b1, 4'b10_11}; //0110 nls
            6'b101_111: {plus_exp, mantAmantB} = {1'b1, 4'b11_00}; //0011 nls

            6'b110_000: {plus_exp, mantAmantB} = {1'b0, 4'b1_110}; //000
            6'b110_001: {plus_exp, mantAmantB} = {1'b0, 4'b1_111}; //110
            6'b110_010: {plus_exp, mantAmantB} = {1'b1, 4'b10_00}; //1100 nls
            6'b110_011: {plus_exp, mantAmantB} = {1'b1, 4'b10_01}; //1010 nls
            6'b110_100: {plus_exp, mantAmantB} = {1'b1, 4'b10_10}; //1000 nls
            6'b110_101: {plus_exp, mantAmantB} = {1'b1, 4'b10_11}; //0110 nls
            6'b110_110: {plus_exp, mantAmantB} = {1'b1, 4'b11_00}; //0100 nls
            6'b110_111: {plus_exp, mantAmantB} = {1'b1, 4'b11_01}; //0010 nls

            6'b111_000: {plus_exp, mantAmantB} = {1'b0, 4'b1_111}; //000
            6'b111_001: {plus_exp, mantAmantB} = {1'b1, 4'b10_00}; //0111 nls 
            6'b111_010: {plus_exp, mantAmantB} = {1'b1, 4'b10_01}; //0110 nls
            6'b111_011: {plus_exp, mantAmantB} = {1'b1, 4'b10_10}; //0101 nls 
            6'b111_100: {plus_exp, mantAmantB} = {1'b1, 4'b10_11}; //0100 nls
            6'b111_101: {plus_exp, mantAmantB} = {1'b1, 4'b11_00}; //0011 nls
            6'b111_110: {plus_exp, mantAmantB} = {1'b1, 4'b11_01}; //0010 nls
            6'b111_111: {plus_exp, mantAmantB} = {1'b1, 4'b11_10}; //0001 nls

        
        endcase
    end
endmodule

module normalizeExp (
    input wire [3:0] exp_or_sub_mant,
    input wire is_subnormal,

    output reg [5:0] expN
);
    
    always @(*) begin
        case ({is_subnormal, exp_or_sub_mant})

            5'b101??: expN = 6'b00000;
            5'b1001?: expN = 6'b11111; 
            5'b10001: expN = 6'b11110;

            default: expN = {2'b0, exp_or_sub_mant}; 
        endcase
    end

endmodule

module normalizeMant (
    input wire[3:0] mant, 

    output reg [3:0] mantN
);

    always @(*) begin
        case(mant[2:0])
            4'b0001: mantN = 4'b1000;
            4'b0010: mantN = 4'b1000;
            4'b0011: mantN = 4'b1100;
            4'b0100: mantN = 4'b1000;
            4'b0101: mantN = 4'b1010;
            4'b0110: mantN = 4'b1100;
            4'b0111: mantN = 4'b1110;
            4'b0000: mantN = 4'b0000;

            default: mantN = mant; 
        endcase
    end
    
endmodule