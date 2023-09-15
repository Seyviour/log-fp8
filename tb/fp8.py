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
    

    def __add__(self, other):
        return FP8.fp8_add(self, other)

    def __sub__(self, other):
        other = (other ^ (1 << 7)) & MASK_8BIT #invert sign of 'other' to perform subtraction
        return FP8.fp8_add(self, other)
    
    def __eq__(self, other):
        return self.get_bits() == other.get_bits()

    def __abs__(self):
        return FP8(self._int_val & (MASK_8BIT >> 1))

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
    
    def get_bits(self):
        return self._int_val & MASK_8BIT

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
    
    def with_sign(self, new_sign_bit):
        if new_sign_bit ==0:
            return FP8(self._int_val & (MASK_8BIT >> 1))
        elif new_sign_bit == 1:
            return FP8(self._int_val | ((MASK_8BIT >> 1) + 1))
        else:
            raise Exception
    
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

        if (self._int_val & (MASK_8BIT >> 1)) == 0:
            return FP8(-math.inf)
        elif(self.get_sign_bit()):
            # print(self)
            raise Exception
        else:
            x = self.get_float()
            x = math.log2(x)
            return FP8(x)
    
    # @staticmethod
    def exp2(self):
        x = self.get_float()
        x = 2 ** (x)
        return FP8(x)


    @staticmethod
    def get_closeset_fp8_val(x):
        x = FP8.__find_val(x)
        return x[1]
    

    @staticmethod
    def __find_val(x):
        idx = bisect.bisect_left(FP8.fp8_vals, x, key=lambda x: x[1])
        g = len(FP8.fp8_vals)-1
        arr = []
        if ((idx) >= g):
            arr =  [g, g-1]
        elif (idx == 0):
            arr = [idx, idx+1]
        else:
            arr = [idx, idx-1, idx+1]
        idx =  min(arr, key = lambda t: abs(FP8.fp8_vals[t][1]-x))
        return FP8.fp8_vals[idx]


    
    # @classmethod
    # def init_fp8_vals(cls):
    #     cls.fp8_vals = tuple([cls.to_float(x) for x in range(256)])

    @staticmethod
    def get_int_repr(x:float):
        x = FP8.__find_val(x)
        return x[0]
        
    @staticmethod  
    def fp8_add(f1, f2):

        """
            Arguments:
                f1: FP8
                f2: FP8
            
            Returns:
                sum: FP8
        """

        #This method is currently broken hence the stub on the next line
        return FP8(f1.get_float() + f2.get_float())

        sign1, exp1, mant1 = f1.filter_sign(), f1.filter_exp(), f1.filter_mantissa()
        sign2, exp2, mant2 = f2.filter_sign(), f2.filter_exp(), f2.filter_mantissa()

        exp_diff = exp1 - exp2

        exp_diff = min(4, exp_diff) #only 3 bits of difference relevant


        result_exp = exp1 if (exp_diff >= 0) else exp2

        #necessarily requires two pathways for parallelism.
        #+8 is simply a multiplexed bit3 (1 or 0) in this case
        mant1 = mant1 if (exp1 == 0) else (8 + mant1)
        mant2 = mant2 if (exp2 == 0) else (8 + mant2)

        # achievable by multiplexing the pathway mant1 and mant2 follow
        mant1 = mant1 >> abs(exp_diff) if (exp_diff < 0) else mant1
        mant2 = mant2 if (exp_diff < 0) else mant2 >> exp_diff

        # if (exp_diff < 0): # check bit 4 of exp
        #     # result_exp = exp2
        #     mant1 = mant1 >> abs(exp_diff)
        # else:
        #     # result_exp = exp1
        #     mant2 = mant2 >> exp_diff

        #post-alignment, this should be accurate

        #same comparator can be used if process is multi-cycle
        result_sign = sign1 if (mant1 > mant2) else sign2

       


        sign1 = 1 if sign1==0 else -1
        sign2 = 1 if sign2==0 else -1

        #two-s complement + incrementer. Could be possible with 4 lut6s 
        #or multiplex routed value with lut4 result
        #addition is addition
        orig_mant_sum = mant_sum = abs(sign1 * mant1 + sign2 * mant2)
        


        #definitely the most tricky part
        #need to determine if right-shift or left-shift

        #adder needs to handle + (-3, 1)
        #barrel shifter needed
        #need to determine shift amount. Not straightforward at all
        #only one-bit right shift will ever be necessary?
        #but left shift can be up to 3 bits
        #if left-shift of 4 is ever necessary, we know that'll simply translate to 0
        #ultimately, two functions of four variables to determine shift amount
        #3lut-4s to generate shift ammount
        #4lut-6s or 6 lut-4s to compute shift result
        #adder to do addition (addition needs to be clipped)

        while (mant_sum > 15 and result_exp<15):
            mant_sum = mant_sum >> 1
            result_exp = result_exp + 1
        
        while (mant_sum < 8 and result_exp > 1):
            mant_sum = mant_sum << 1
            result_exp = result_exp -1
        
        if (result_exp == 1 and mant_sum < 8):
            result_exp = 0

        if (mant_sum == 0): result_exp = 0

        if (mant_sum > 15): mant_sum = 7
        
        return FP8((result_sign, result_exp, mant_sum))


# FP8.init_fp8_vals()

if __name__ == "__main__": 


    fp8s = [FP8(x) for x in range(256) ]

    x = 0
    val1 = FP8(0)
    
    with open('sum_compare.txt', "w") as f:
        f.write(f"{'x1':25}\t\
                {'x2':25}\t\
                {'x1+x2(FP8)':25}\t\
                {'x1+x2(CAST)':25}\t\
                {'difference':25}\n")
        for idx1 in range(256):
            val1 = FP8(idx1)
            for idx2 in range(idx1, 256):
                val2 = FP8(idx2)

                sum1 = val1 + val2
                sum2 = FP8(val1.get_float() + val2.get_float() + 0.0)
                error = sum2.get_float() - sum1.get_float()

                f.write(f"{val1.get_float():+015.10f} \t \
                        {val2.get_float():+015.10f} \t\
                        {sum1.get_float():+015.10f} \t \
                        {sum2.get_float():+015.10f} \t \
                        {error:+015.10f}\n")

                # if (sum1.get_float() != sum2.get_float()):
                #     print(val1.get_float(), val2.get_float(), sum1.get_float(), sum2.get_float())

    
    with open('mult_compare.txt', "w") as f: 
        x = 0
        val1 = FP8(0)
        seen = set()
        f.write(f"{'x1':25}\t\
                {'x2':25}\t\
                {'log_mult':25}\t\
                {'full_mult':25}\t\
                {'difference':25}\n")
        cumulative_error = 0
        error_count = 0 
        for idx1 in range(256):
            val1 = FP8(idx1)
            for idx2 in range(idx1, 256):
                val2 = FP8(idx2)

                if (idx1, idx2) in seen:
                    continue
                else:
                    seen.add((idx2,idx1))

                prod = FP8(val1.get_float() * val2.get_float())

                sign1 = val1.get_sign()
                sign2 = val2.get_sign()
                result_sign = sign1 * sign2
                result_sign = 0 if result_sign == 1 else 1
                
                abs_val1 = abs(val1)
                abs_val2 = abs(val2)

                log_val1 =  abs_val1.log2()#val1.with_sign(0).log2()
                log_val2 = abs_val2.log2()#val2.with_sign(0).log2()
                log_sum = log_val1 + log_val2

                anti_log = log_sum.exp2()
                log_prod = anti_log.with_sign(result_sign)

                error = prod.get_float()-log_prod.get_float()

                if (error != 0.0) : error_count +=1 

                cumulative_error += error

                f.write(f"{val1.get_float():+015.10f} \t \
                        {val2.get_float():+015.10f} \t\
                        {log_prod.get_float():+015.10f} \t \
                        {prod.get_float():+015.10f} \t \
                        {error:+015.10f}\n")
        f.write(f"{cumulative_error} \t {error_count}")
