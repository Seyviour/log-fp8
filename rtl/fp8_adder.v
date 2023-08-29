module adderFP8 #(
    parameter FP8_TYPE = 0
) (
    input wire [7:0] A, B,
    output wire [7:0] C
);

wire sign1, sign2;

wire [3:0] exp1, exp2; 

wire [2:0] mant1, mant2;

wire [3:0] exp_diff;

wire sign_difference; 

assign sign_difference = (A[7] ^ B[7]); 

always @(*) begin
    if (sign_difference) begin
        {sign1, exp1, mant1} = B[7]? A : B;
        {sign2, exp2, mant2} = B[7]? B: A; 
    end else begin 
        {sign1, exp1, mant1} = A; 
        {sign2, exp2, mant2} = B;
    end
end


reg result_sign; 
reg [3:0] mant1_ext, mant2_ext, mant1_norm, mant2_norm;
reg [4:0] start_exp;

always @(*) begin 
    mant1_ext = {|(exp1), mant1};
    mant2_ext = {|(exp2), mant2}; 
end

always @(*) begin
    if (exp1 > exp2) begin
        start_exp = exp1; // bias due to subnormal shifts
        exp_diff = exp1-exp2;
        mant1_norm = mant1_ext;
        mant2_norm = (exp_diff[2] | exp_diff[3])? 4'b0: mant2_ext>>exp_diff[1:0];
    end else begin
        start_exp = exp2; // bias because of subnormal shifts
        exp_diff = exp2-exp1;
        mant1_norm = (exp_diff[2] | exp_diff[3])? 4'b0: mant1_ext>>exp_diff[1:0];
        mant2_norm = mant2_ext; 
    end
end

always @(*) begin
    if (mant1_norm > mant2_norm) begin
        result_sign = sign1; 
    end else begin
        result_sign = sign2;
    end
end

reg [4:0] mant2_inv;
reg [4:0] mant_sum;  

always @(*) begin
    mant2_inv = (sign_difference)? !mant2_norm: mant2_norm; 
    mant_sum = mant1_norm + mant2_inv + sign_difference;
end

reg [4:0] exp_stage1, exp_stage2, exp_stage3;
reg [3:0] mant_stage1, mant_stage2, mant_stage3; 

always @(*) begin

    if (!mant_sum[3]) begin
        if (mant_sum[4] && !(&start_exp)) begin
            mant_stage1 = mant_sum >> 1'b1;
            exp_stage1 = start_exp + 1'b1; 
        end else begin
            mant_stage1 = (start_exp > 1'b1)? mant_sum << 1'b1: mant_sum;
            exp_stage1 = (start_exp > 1'b1)? start_exp - 1'b1: start_exp; 
        end
    end else begin
        mant_stage1 = mant_sum;
        exp_stage1 = start_exp; 
    end
end


always @(*) begin
    if (!mant_sum[3] && (exp_stage2 > 1'b1)) begin
        mant_stage2 = mant_stage1 << 1'b1;
        exp_stage2 = exp_stage1 - 1'b1;
    end else begin
        mant_stage2 = mant_stage1;
        exp_stage2 = exp_stage1; 
    end
end

always @(*) begin
    if (!mant_sum[3] && (exp_stage2 > 1'b1)) begin
        mant_stage3 = mant_stage2 << 1'b1;
        exp_stage3 = exp_stage2 - 1'b1;
    end else begin
        mant_stage3 = mant_stage2;
        exp_stage3 = exp_stage2; 
    end
end

reg [3:0] final_exp;
reg [3:0] final_mant;

always @(*) begin
    if (!mant_stage3[3])
        final_exp = 4'b0;
    else
        final_exp = exp_stage3;
    
    final_mant = mant_stage3[2:0]; 
end

assign C = {result_sign, final_exp, final_mant}; 
    
endmodule