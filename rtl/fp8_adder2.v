module adderFP8 #(parameter FP8_TYPE = 1)(
    input wire [7:0] A,
    input wire [7:0] B,
    input wire clk,
    output reg [7:0] C
);


wire [3:0] expA, expB;
wire [2:0] _mantA, _mantB; 
wire signA, signB;

wire redOrExpA,  redOrExpB;

assign redOrExpA = |(expA);
assign redOrExpB = |(expB); 

assign {signA, expA, _mantA} = A;
assign {signB, expB, _mantB} = B;


wire [3:0] mantA, mantB;

assign mantA = {redOrExpA, _mantA};
assign mantB = {redOrExpB, _mantB};

/*
 The arg1, arg2 notation is for internal manipulations
*/

reg sign_diff;
reg [3:0]  exp_diff;

reg [7:0] mant1, mant2;
reg [8:0] mant2S;
reg deg_check; 
reg [8:0] _mant_sum, mant_sum; 
reg [3:0] exp1;

reg [3:0] exp_sum; 

reg is_roundable;
// reg is_degen;

reg [3:0] expAReg, expBReg; 

reg result_sign;
reg gt;

reg [3:0] expSubArg1, expSubArg2;
always @(*) begin
    expAReg = expA | (!redOrExpA);
    expBReg = expB | (!redOrExpB); 
    sign_diff = signA ^ signB;
    mant1[3:0] = 4'b0;
    mant2[3:0] = 4'b0;
    gt = {expA, mantA} >= {expB, mantB};
    expSubArg1 = gt? expAReg: expBReg;
    expSubArg2 = gt? expBReg: expAReg;
    exp_diff = expSubArg1 - expSubArg2;
    
    mant1[7:4] = gt? mantA: mantB;
    mant2[7:4] = gt? mantB: mantA;
    result_sign = gt? signA: signB;
    exp1 = gt? expAReg: expBReg;
    // exp_diff_gt_4 = _exp_diff > 4;
    
    {mant2S, deg_check} = {mant2, 1'b0} >> exp_diff; 
end
/* 
{8765} is rounded when bit 4 is set
{7654} is rounded when bit 3 is set
in both cases, adding 1 to bit 4 accomplishes rounding

{6543} is rounded when bit 2 is set
{5432} is rounded when bit 1 is set
in both cases, adding 1 to bit 2 accomplishes rounding

{4321} is rounded when bit 0 is set
{3210} is never rounded? 

*/

// 8 7 6 5 4 3 3 2 1 0
//         x  
reg [1:0] round; 
always @(*) begin
    _mant_sum = mant1 + (sign_diff? (-(mant2S|deg_check)): mant2S); 
    // is_roundable = !({mant2S[1:0], deg_check} == 3'b001); 
    round[1] = (_mant_sum[8] & _mant_sum[4]) || (_mant_sum[7] & _mant_sum[3]);
    round[0] =  !round[1] && ((_mant_sum[6] & _mant_sum[2]) || ( (_mant_sum[5]) && _mant_sum[1])); 
    mant_sum = {_mant_sum[8:2] + {round[1], 1'b0, round[0]}, _mant_sum[1:0]}; 

end

reg [1:0] exp_neg;
reg [2:0] sh_req; 

reg left_shift;

always @(*) begin
    left_shift = !(mant_sum[8] || mant_sum[7]);
    exp_neg[1] = (left_shift && !mant_sum[6]) && (mant_sum[5] || mant_sum[4]);
    exp_neg[0] = left_shift && (!mant_sum[5] && mant_sum[4] || mant_sum[6]);
end


reg [3:0] final_exp;

reg [3:0] true_shift_or_exp;
reg [4:0] exp_sum_arg;
reg over_under_flow;


always @(*) begin
    sh_req = {mant_sum==5'b1000, exp_neg}; 
    exp_sum_arg = ({2'b00, sh_req} ^ {5{left_shift}}) | mant_sum[8]; 
    {over_under_flow, exp_sum} = exp1 + exp_sum_arg;
    true_shift_or_exp = exp_sum + (({4{over_under_flow}} & sh_req) | (!over_under_flow));
end

reg[3:0] final_mant;
reg[8:0] shifted_mant;


always @(*) begin
    shifted_mant = mant_sum << (over_under_flow? true_shift_or_exp: sh_req);

    if (shifted_mant[8]) 
        final_mant = mant_sum[8:5] | {4{over_under_flow}}; 
    else
        final_mant = shifted_mant[7:4];

    if (left_shift) begin
        final_exp = {4{!over_under_flow}} & true_shift_or_exp;
    end else begin
        final_exp = {4{over_under_flow}} | exp_sum[3:0];
    end
    
end


always @(*) begin
    C = {result_sign, final_exp, final_mant[2:0]}; 
end

// always @(*) 
/*
    Subnormal result is only possible for operands with exponents <= 0011
    Ergo max exponent difference in that caase is 0011 - 0001 = 0010 (2)
    
    maximum result left shift is also 2. Trust me, bro
*/


    
endmodule