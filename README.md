# log-fp8
Exploration of logarithm-based FP8 computation in hardware.

Currently Implemented:
1. FP8 Adder (tested and working correctly)
2. Multiplier (in progress, untested). For the FP8 multiplier, I intend to exploit the fact that the Significand can be normalized to a 3-bit value. Multiplying two significands is thus a function of 6 variables, which should fit nicely in a LUT-6
3. FP8 Logarithm (in progress). The design of the Logarithm unit exploits the semi-logarithmic representation of floating point numbers. With some normalization, this allows for a logarithm to be computed as a sum of the exponent with the log of the mantissa (a function of 3/4 variables that should fit nicely in a LUT-4).
