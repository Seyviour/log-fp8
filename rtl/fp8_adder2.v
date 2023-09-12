module adderFP8 #(parameter FP8_TYPE = 1)(
    input wire [7:0] A,
    input wire [7:0] B,
    input wire clk, 
    output reg [7:0] C
);


wire [3:0] expA, expB;
wire [2:0] _mantA, _mantB; 
wire signA, signB; 

assign {signA, expA, _mantA} = A;
assign {signB, expB, _mantB} = B;


wire [3:0] mantA, mantB;

assign mantA = {|(expA), _mantA};
assign mantB = {|(expB), _mantB};

/*
 The arg1, arg2 notation is for internal manipulations
*/

reg sign_diff;
reg [3:0] _exp_diff, exp_diff;

reg [7:0] mant1, mant2, mant2S;
reg [8:0] _mant_sum, mant_sum; 
reg [3:0] exp1, exp2;

reg exp_diff_gt_4;

reg [4:0] exp_sum; 

reg is_roundable; 

reg result_sign; 
always @(*) begin
    sign_diff = signA ^ signB;
    mant1[3:0] = 4'b0;
    mant2[3:0] = 4'b0; 
    if ({expA, mantA} >= {expB, mantB}) begin
        _exp_diff = (expA | !(|(expA))) - (expB| !(|(expB)));
        mant1[7:4] = mantA;
        mant2[7:4] = mantB;
        exp1 = expA | !(|(expA));
        result_sign = signA; 
    end else begin
        _exp_diff = expB - expA;
        mant1[7:4] = mantB;
        mant2[7:4] = mantA;
        exp1 = expB | !(|(expB));
        result_sign = signB; 
    end

    
    exp_diff_gt_4 = _exp_diff > 4;
    exp_diff = (exp_diff_gt_4)? 4'd5: _exp_diff;
    mant2S = mant2 >> exp_diff; 
end

always @(*) begin
    if (sign_diff) begin
        _mant_sum = mant1 - mant2S;
        is_roundable = |(_mant_sum[2:0]); 
        mant_sum[8:4] = _mant_sum[8:4] + ((_mant_sum[7] | _mant_sum[8]) & _mant_sum[3]);
        mant_sum[3:0] = _mant_sum[3:0];  
    end else begin
        _mant_sum = mant1 + mant2S;
        is_roundable = |(_mant_sum[2:0]); 
        mant_sum[8:4] = _mant_sum[8:4] + ((_mant_sum[7] | _mant_sum[8]) & _mant_sum[3]);
        mant_sum[3:0] = _mant_sum[3:0];  
    end
end

reg [1:0] exp_neg;

always @(*) begin
    exp_neg[1] = !(mant_sum[8] || mant_sum[7] || mant_sum[6]) && (mant_sum[5] || mant_sum[4]);
    exp_neg[0] = !(mant_sum[8] || mant_sum[7]) && (!mant_sum[5] && mant_sum[4] || mant_sum[6]);
end

// reg [2:0] final_mant;
reg overflow, underflow;
reg [3:0] final_exp;

reg [2:0] true_shift;
always @(*) begin
    overflow = 1'b0;
    underflow = 1'b0;
    true_shift = 2'b0; 
    if (mant_sum[8] | mant_sum[7]) begin
        exp_sum = exp1 + mant_sum[8]; 
        overflow =  exp_sum[4];
        final_exp = overflow? 4'b1111: exp_sum[3:0]; 
    end else begin
        exp_sum = exp1 - exp_neg;
        underflow = !(|(exp_sum)) | exp_sum[4]; 
        true_shift = exp_neg + (exp_sum -1'b1); 
        final_exp = underflow? exp1 - true_shift: exp_sum;
    end
end



reg[3:0] final_mant;
reg[7:0] shifted_mant; 
always @(*) begin
    shifted_mant = mant_sum; 
    final_mant = mant_sum[7:4];
    if (mant_sum[8]) 
        final_mant = mant_sum[8:5]; 
    else if(!mant_sum[7]) begin
        shifted_mant = mant_sum << true_shift;
        final_mant = shifted_mant[7:4]; 
    end
end

reg[3:0] final_exp_fr; 

always @(*)begin
    final_exp_fr = (final_mant[3] == 1'b0)? 4'b0: final_exp;
end

always @(*) begin
    C = {result_sign, final_exp_fr, final_mant[2:0]}; 
end

// always @(*) 
/*
    Subnormal result is only possible for operands with exponents <= 0011
    Ergo max exponent difference in that caase is 0011 - 0001 = 0010 (2)
    
    maximum result left shift is also 2. Trust me, bro
*/


    
endmodule