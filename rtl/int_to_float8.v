module IntToFloat8 #(
    parameter float8_type = 0, // tbi: 0->e4m3, 1->e5m2
    parameter input_bias = 7 // tbi: handle different biases
) (
    input wire [3:0] int_val,
    output wire [7:0] float_val
);

/* 
    This module is intended to convert exponents in e4m3 float8 values to full e4m3 floats
    int_val should be the 4 bit exponent from e4m3
*/
    
wire [3:0] input_val;

wire sign; 
wire [2:0] mant;
wire [3:0] exp; 

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
assign sum_arg1 = int_val[3]? int_val: ~int_val;  // exp_given: !exp_given 
assign sum_arg2 = 4'b1000 | int_val[3];  // 8 and -7 differ by only the last bit. 
                                          //We can play fast and loose with the signs here :)

assign input_val = sum_arg1 + sum_arg2; 

wire val_is_1;
wire val_2_1_is_0;

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
assign sign = !int_val[3]; 

assign mant[2] = input_val[1] & (input_val[0] | input_val[2]);
assign mant[1] = input_val[0] & input_val[2];
assign mant[0] = 1'b0;

assign exp[0] = input_val[2] | val_is_1; 
assign exp[1] = val_is_1 | input_val[3];
assign exp[2] = 1'b0;
assign exp[3] = !val_2_1_is_0; 

assign float_val = {sign, exp, mant}; 

endmodule