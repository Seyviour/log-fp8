`default_nettype none

module IntToFloat8 #(
    parameter float8_type = 0, // tbi: 0->e4m3, 1->e5m2
    parameter input_bias = 7 // tbi: handle different biases
) (
    input wire is_subnormal, 
    input wire [3:0] exp_val,
    output wire [7:0] float_val
);

/* 
    This module is intended to convert exponents in e4m3 float8 values to full e4m3 floats

    exp_val:  should be the 4 bit exponent from e4m3 float, except when `is_subnormal` is asserted
              When `is_subnormal` is asserted, exp_val should be the mantissa in e4m3; 
            assign sign = !exp_val[3];  

    is_subnormal: signal indicating that exp_val is the mantissa from a subnormal float
*/
    
wire [3:0] input_val;

wire [2:0] mant, normal_mant, subnormal_mant;
wire [3:0] exp, subnormal_exp, normal_exp; 

wire [3:0] sum_arg1, sum_arg2;


/*
    Due to the bias in e4m3 floats, 
    The "true" exponent exp_true is determined as exp_true = exp_given - 7

    e4m3 uses a sign bit, thus after extracting the sign of exp_given, it is convenient to work
    with the absolute value of exp_given

    When exp_given[3] == 1, exp_true resolves to a positive value
    when exp_given[3] == 0, it resolves to a negative value but we can find the absolute value as follows:
        -exp_abs = exp_given - 7 
        exp_abs = -exp_given + 7
        exp_abs = !exp_given + 1 + 7
        exp_abs = !exp_given + 8 
*/
wire [3:0] int_val;

assign int_val = is_subnormal? {3'b111, !exp_val[0] && (exp_val[1] | exp_val[2])}: exp_val; 
assign sum_arg1 = int_val[3]? int_val: ~int_val;  // exp_given: !exp_given 
assign sum_arg2 = 4'b1000 | int_val[3];  // 8 and -7 differ by only the last bit. 
                                          //We can play fast and loose with the signs here :)

assign input_val = sum_arg1 + sum_arg2; 


wire is_most_subnormal;
wire sign;
wire is_neg_inf;
wire val_is_1;
wire val_2_1_is_0;
 
assign sign = !exp_val[3];  

assign is_neg_inf = is_subnormal & !(exp_val[0] | exp_val[1] | exp_val[2]); 

assign is_most_subnormal = is_subnormal && !(exp_val[1] | exp_val[2]) && exp_val[0]; 

assign val_2_1_is_0 = !(input_val[1] | input_val[2]);

assign val_is_1 = val_2_1_is_0 & input_val[0];


/*
    int -> sign exponent mantissa
    0000 -> s 0000 000   
    0001 -> s 0111 000
    0010 -> s 1000 000
    0011 -> s 1000 100
    0100 -> s 1001 000
    0101 -> s 1001 010
    0110 -> s 1001 100
    0111 -> s 1001 110
    1000 -> 0 1010 000
*/


// always @(*) begin
//     subnormal_mant[0] = !(int_val[2] | int_val[1]) & int_val[0];
//     subnormal_mant[1] = int_val[2];
//     subnormal_mant[2] = int_val[2];

//     subnormal_exp[0] = int_val[2];
//     subnormal_exp[1] = !int_val[2]&&(int_val[1] | int_val[0]); 
//     subnormal_exp[2] = 1'b0; 
//     subnormal_exp[3] = 1'b1; 
// end

always @(*) begin
    normal_mant[2] = input_val[1] & (input_val[0] | input_val[2]);
    normal_mant[1] = input_val[0] & input_val[2];
    normal_mant[0] = is_most_subnormal | is_neg_inf;

    normal_exp[0] = input_val[2] | val_is_1; 
    normal_exp[1] = val_is_1 | input_val[3] | is_neg_inf;
    normal_exp[2] = is_neg_inf;
    normal_exp[3] = !val_2_1_is_0; 
end

always @(*) begin
    exp = normal_exp; 
    mant = normal_mant;
end

assign float_val = {sign, exp, mant}; 

endmodule