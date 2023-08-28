import math, bisect


MASK_8BIT = (2**8)-1
MASK_MANT = (2**3)-1
MASK_EXP = ((2**4)-1) << 3


def to_float(bin_repr):
    if isinstance(bin_repr, str):
        bin_repr = bin_repr if bin_repr[:2]!="0b" else bin_repr[2:]
        bin_repr = int(bin_repr, 2)
    int_val = bin_repr & MASK_8BIT

    # print(int_val)
    exp = (int_val & MASK_EXP) >> 3
    # print(exp)
    mant = (int_val & MASK_MANT)
    # print(mant)
    sign = -1 if (int_val>>7) else 1
    # print(sign)

    if (exp == 0):
        return (sign * (mant/8) * (2 ** (exp+1-7) ))
    else:
        return (sign * (1 + mant/8) * (2 ** (exp-7)))

#https://arxiv.org/pdf/2209.05433
class FP8:

    fp8_vals = sorted([(x, to_float(x)) for x in range(256)], key = lambda x: x[1])
    


    # """If you like, change am /s. Yes, I'm ignoring the Nans for now. This class is intended for a certain kind of analysis"""
    # fp8_vals = tuple([FP8.to_float(x) for x in range(256)])

    MASK_8BIT = (2**8)-1
    MASK_MANT = (2**3)-1
    MASK_EXP = ((2**4)-1) << 3





    def __init__(self, init_val:str|float|int|tuple):
        if isinstance(init_val, str):
            if init_val[:2] == "0b":
                init_val = init_val[2:]

            try: 
                init_val = int(str, 2)
                self._int_val = init_val & FP8.MASK_8BIT
            except:
                raise Exception("Init Error: Init arg should be a binary string")
        
        elif isinstance(init_val, float):
            self._int_val = FP8.get_int_repr(init_val)
        
        elif isinstance(init_val, int):
            self._int_val = init_val & FP8.MASK_8BIT
        
        elif isinstance(init_val, tuple) or isinstance(init_val, list):
            self._int_val = FP8.fp8_int_from_fields(init_val)

        else:
            raise Exception("init argument should be binary string")
    

    @staticmethod
    def fp8_int_from_fields(arg_tuple):
        (sign, exp, mant) = arg_tuple
        val = sign << 7
        val = val | ((exp & 15) << 3)
        val = val | ((mant & 7))
        return val
    
    def is_subnormal(self):
        return self.filter_exp() == 0
    
    def get_sign_bit(self):
        return (self._int_val & MASK_8BIT) >> 7

    def get_bin_repr(self):
        bin_repr = bin(self._int_val & FP8.MASK_8BIT)
        return bin_repr[2:]
    
    def filter_mantissa(self):
        return ((self._int_val & FP8.MASK_8BIT & FP8.MASK_MANT))

    def filter_exp(self):
        return ((self._int_val & FP8.MASK_8BIT & FP8.MASK_EXP)>>3)
    
    def filter_sign(self):
        return ((self._int_val & FP8.MASK_8BIT) >> 7)

    def get_sign(self):
        return -1 if self.filter_sign() else 1 

    def get_exp(self):
        if ((g:=self.filter_exp())): 
            return (g - 7)
        else: 
            return g +1 -7
    
    

    def get_partial_mantissa(self):
        return self.filter_mantissa()/8
    
    def get_mantissa(self):
        mantissa = self.get_partial_mantissa()
        
        if (self.is_subnormal()):
            return mantissa
        
        return (mantissa+1)
    
    def get_float(self):
        exp = self.get_exp()
        mant = self.get_mantissa()
        sign = self.get_sign()

        return sign * mant * (2 ** exp)
        
    
    def get_exp_repr(self):
        return bin(self.get_exp())[2:]
    
    def get_mant_repr(self):
        return bin(self.get_mantissa())[2:]
    
    def __repr__(self):
        # fstring = ""
        return ("int_repr: {} \t float_repr: {:3.10f} \t bin_repr: {:0>8b} ".format(self._int_val, self.get_float(), self._int_val))
    

    def my_log_2(): pass
    
    @staticmethod
    def to_float(bin_repr):
        if isinstance(bin_repr, str):
            bin_repr = bin_repr if bin_repr[:2]!="0b" else bin_repr[2:]
            bin_repr = int(bin_repr, 2)
        int_val = bin_repr & FP8.MASK_8BIT

        # print(int_val)
        exp = (int_val & FP8.MASK_EXP) >> 3
        # print(exp)
        mant = (int_val & FP8.MASK_MANT)
        # print(mant)
        sign = -1 if (int_val>>7) else 1
        # print(sign)

        if (exp == 0):
            return (sign * (mant/8) * (2 ** (exp+1-7) ))
        else:
            return (sign * (1 + mant/8) * (2 ** (exp-7)))
    
    # @staticmethod
    def log2(self):
        x = self.get_float()
        if (x <= 0): return 0
        x = math.log2(x)
        return FP8.get_closeset_fp8_val(x)
    
    # @staticmethod
    def exp2(self):
        x = self.get_float()
        x = 2 ** (x)
        return FP8.get_closeset_fp8_val(x)


    @staticmethod
    def get_closeset_fp8_val(x):
        x = FP8.__find_val(x)
        return x[1]
    

    @staticmethod
    def __find_val(x):
        idx = bisect.bisect_left(FP8.fp8_vals, x, key=lambda x: x[1])

        if ((idx) >= (g:=len(FP8.fp8_vals)-1)):
            return FP8.fp8_vals[g]
        elif (idx == 0):
            return FP8.fp8_vals[idx]
        else:
            idx =  min([idx, idx-1, idx+1], key = lambda t: abs(FP8.fp8_vals[t][1]-x))
            return FP8.fp8_vals[idx]


    
    # @classmethod
    # def init_fp8_vals(cls):
    #     cls.fp8_vals = tuple([cls.to_float(x) for x in range(256)])

    @staticmethod
    def get_int_repr(x:float):
        x = FP8.__find_val(x)
        return x[0]
        
            
def sim_fp_add(f1:FP8, f2:FP8):

    sign1, exp1, mant1 = f1.filter_sign(), f1.filter_exp(), f1.filter_mantissa()
    sign2, exp2, mant2 = f2.filter_sign(), f2.filter_exp(), f2.filter_mantissa()

    exp_diff = exp1 - exp2

    exp_diff = min(4, exp_diff) #only 3 bits of difference relevant


    result_exp = exp1 if (exp_diff >= 0) else exp2

    mant1 = mant1 >> abs(exp_diff) if (exp_diff < 0) else mant1
    mant2 = mant2 if (exp_diff < 0) else mant2 >> exp_diff

    if (exp_diff < 0): # check bit 4 of exp
        # result_exp = exp2
        mant1 = mant1 >> abs(exp_diff)
    else:
        # result_exp = exp1
        mant2 = mant2 >> exp_diff

    #post-alignment, this should be accurate
    result_sign = sign1 if (mant1 > mant2) else sign2

    mant1 = mant1 if (exp1 == 0) else (8 + mant1)
    mant2 = mant2 if (exp2 == 0) else (8 + mant2)


    sign1 = 1 if sign1==0 else -1
    sign2 = 1 if sign2==0 else -1

    orig_mant_sum = mant_sum = abs(sign1 * mant1 + sign2 * mant2)
    

    while (mant_sum > 15 and result_exp<15):
        mant_sum = mant_sum >> 1
        result_exp = result_exp + 1
    
    while (mant_sum < 8 and result_exp > 1):
        mant_sum = mant_sum << 1
        result_exp = result_exp -1
    
    if (result_exp == 1 and mant_sum < 8):
        result_exp = 0

    if (mant_sum == 0): result_exp = 0
    
    return FP8((result_sign, result_exp, mant_sum))


# FP8.init_fp8_vals()

if __name__ == "__main__": 


    fp8s = [FP8(x) for x in range(256) ]

    x = 0
    val1 = FP8(0)

    for idx in range(x, 256):
        val2 = FP8(idx)

        sum1 = sim_fp_add(val1, val2)
        sum2 = FP8(val1.get_float() + val2.get_float())

        if (sum1.get_float() != sum2.get_float()):
            print(val1.get_float(), val2.get_float(), sum1.get_float(), sum2.get_float())

        if (idx == 255):
            x += 1
        

    # with open
    # a = FP8(2)
    # b = FP8(100)

    # print(sim_fp_add(a, b))

    # with open("logarithms.txt", "w") as f, open("antilogarithms.txt", "w") as g:
    #     f.write("Values \t \t || \t \t Logarithms\n")

    #     g.write("Values \t \t || \t \t Anti-logarithms\n")
    #     vals = [FP8(x) for x in range(256)]
    #     logs = [FP8(x.log2()) for x in vals]
    #     anti_logs = [FP8(x.exp2()) for x in vals]

    #     for (val, log) in zip(vals, logs):
    #         f.write(f"{val.__repr__()} \t \t || \t \t {log.__repr__()}\n")
        
    #     for (val, log) in zip(vals, anti_logs):
    #         g.write(f"{val.__repr__()} \t \t || \t \t {log.__repr__()}\n")


    # with open("anti_log_data", "w") as f, open("friendly_antilogs", "w") as g:
    #     f.write("Value \t\t exp_float \t\t mant_float \t\t Anti-log \t\t antilog-exp_float \t\t True mants\n")
    #     vals = [FP8(x) for x in range(256)]

    #     anti_logs = [FP8(x.exp2() + 0.0) for x in vals]

    #     exp_floats = [FP8(float(x.get_exp())) for x in anti_logs]

    #     mant_floats = [FP8(float(x.get_mantissa())) for x in anti_logs]

    #     subs = [FP8(val.get_float() - exp.get_float()) for (val, exp) in zip(vals, exp_floats)]

    #     true_mants = [FP8(x.exp2()+0.0) for x in subs]

    #     unique_subs = list(set([x.get_float() for x in subs]))
    #     unique_subs.sort()
    #     unique_subs = [FP8(x) for x in unique_subs]
    #     unique_true_mants = [FP8(x.exp2()) for x in unique_subs]

    #     # print(len(set(unique)))

    #     for (val, ef, mf, al, sub, trm) in zip (vals, exp_floats, mant_floats, anti_logs, subs, true_mants):
            
    #         f.write("{:+015.10f} \t {:+015.10f} \t {:+015.10f} \t {:+015.10f} \t {:+015.10f} \t {:+015.10f} \n".format(val.get_float(), ef.get_float(), mf.get_float(),al.get_float(), sub.get_float(), trm.get_float()))

    #     for (us, utm) in zip(unique_subs, unique_true_mants): 
    #         g.write("{:+015.10f} \t {:08b} \t {:+015.10f} \t {:08b}\n".format(us.get_float(), us._int_val, utm.get_float(), utm._int_val))







