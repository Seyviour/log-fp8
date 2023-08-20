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





    def __init__(self, init_val:str|float|int):
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

        else:
            raise Exception("init argument should be binary string")

        
    def get_bin_repr(self):
        bin_repr = bin(self._int_val & FP8.MASK_8BIT)
        return bin_repr[2:]
    
    def get_mantissa(self):
        return ((self._int_val & FP8.MASK_8BIT & FP8.MASK_MANT))

    def get_exp(self):
        return ((self._int_val & FP8.MASK_8BIT & FP8.MASK_EXP)>>3)
    
    def get_sign(self):
        return ((self._int_val & FP8.MASK_8BIT) >> 7)
    
    def get_float(self):
        exp = self.get_exp()
        mant = self.get_mantissa()
        sign = self.get_sign()

        if (exp == 0):
            return (sign * (mant/8) * (2 ** (1-7)))
        
        else:
            return (2 **(exp-7)) * (1 + mant/8) * sign
        
    
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
            idx =  min([idx, idx-1], key = lambda t: abs(FP8.fp8_vals[t][1]-x))
            return FP8.fp8_vals[idx]


    
    # @classmethod
    # def init_fp8_vals(cls):
    #     cls.fp8_vals = tuple([cls.to_float(x) for x in range(256)])

    @staticmethod
    def get_int_repr(x:float):
        x = FP8.__find_val(x)
        return x[0]
        
            
        


# FP8.init_fp8_vals()

if __name__ == "__main__": 

    with open("logarithms.txt", "w") as f, open("antilogarithms.txt", "w") as g:
        f.write("Values \t \t || \t \t Logarithms\n")

        g.write("Values \t \t || \t \t Anti-logarithms\n")
        vals = [FP8(x) for x in range(256)]
        logs = [FP8(x.log2()) for x in vals]
        anti_logs = [FP8(x.exp2()) for x in vals]

        for (val, log) in zip(vals, logs):
            f.write(f"{val.__repr__()} \t \t || \t \t {log.__repr__()}\n")
        
        for (val, log) in zip(vals, anti_logs):
            g.write(f"{val.__repr__()} \t \t || \t \t {log.__repr__()}\n")






