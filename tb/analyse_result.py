from fp8 import FP8

# print(FP8(449.0))
count = 0
cum_error = 0
with open("tb/result.txt", "r") as f, open("tb/failing.txt", "w") as f2:
    print ("Reading results from 'result.txt' \nFailing cases will be written to 'failing.txt' \n")

    for line in f:
        A, B, C = [FP8(int(x,2)) for x in line.strip().split()]
        full_res = A.get_float() + B.get_float()
        D = FP8(full_res)
        e1 = abs(C.get_float() - full_res)
        e2 = abs(D.get_float()- full_res)
        g = abs(e1 - e2)

        ie = abs(C._int_val - D._int_val)

        #failing criteria: Error from fp8_adder.v greater than error from full precision computation (cast back to FP*)

        if (g!=0): 
            f2.write(f"{A._int_val:08b} {A.get_float():+015.10f} \
                    {B._int_val:08b} {B.get_float():+015.10f} \
                    {C._int_val:08b} {C.get_float():+015.10f} \
                    {D._int_val:08b} {D.get_float():+015.10f}\n")
            
        if (D.get_float() != 0):
            cum_error += abs((C.get_float() - D.get_float())/D.get_float())
            count += 1


    print("Cumulative % error:", cum_error)
    print("Testcases considered (computations resulting in `0` are excluded ): ", count)
    print("Average % error: ", cum_error/count)
