import random
import matplotlib.pyplot as plt

s1 = 0x59F57B02 #random.getrandbits(32)
s2 = 0xE10D3B9E #random.getrandbits(32)
s3 = 0xD0978CB9 #random.getrandbits(32)

def taus88():
    global s1, s2, s3
    b1_temp = ((s1 << 13) & 0xFFFFFFFF) ^ s1
    print("b1_temp: ", hex(b1_temp))
    b1 = b1_temp >> 19
    print("b1: ", hex(b1))
    s1_temp = ((s1 & 0xFFFFFFFE) << 12) & 0xFFFFFFFF
    print("s1_temp: ", hex(s1_temp))
    s1 = s1_temp ^ b1
    print("s1: ", hex(s1))

    b2_temp = ((s2 << 2) & 0xFFFFFFFF) ^ s2
    print("b2_temp: ", hex(b2_temp))
    b2 = b2_temp >> 25
    print("b2: ", hex(b2))
    s2_temp = ((s2 & 0xFFFFFFF8) << 4) & 0xFFFFFFFF
    print("s2_temp: ", hex(s2_temp))
    s2 = s2_temp ^ b2
    print("s2: ", hex(s2))

    b3_temp = ((s3 << 3) & 0xFFFFFFFF) ^ s3
    print("b3_temp: ", hex(b3_temp))
    b3 = b3_temp >> 11
    print("b3: ", hex(b3))
    s3_temp = ((s3 & 0xFFFFFFF0) << 17) & 0xFFFFFFFF
    print("s3_temp: ", hex(s3_temp))
    s3 = s3_temp ^ b3
    print("s3: ", hex(s3))

    xor_total = s1 ^ s2 ^ s3
    print("s1xs2: ", hex(s1 ^ s2))
    print("xor_total: ", hex(xor_total))

    return (xor_total * 2.3283064365e-10) #s1^s1^s3 = xor_total/xor_total_reg

    # b = ((((s1 << 13) & 0xFFFFFFFF)^ s1) >> 19)
    # print("start s1: ", hex(s1))
    # print("b1_temp: ", hex(((s1 << 13) & 0xFFFFFFFF)^ s1))
    # print("b1: ", hex(((s1 << 13) ^ s1) >> 19))
    # print("s1 temp: ", hex(((s1 & 4294967294) << 12) & 0xFFFFFFFF))
    # s1 = ((((s1 & 4294967294) << 12) & 0xFFFFFFFF) ^ b) & 4294967295 #s1 register
    # print("s1 reg: ", hex(s1))
    # b = (((s2 << 2) ^ s2) >> 25)
    # s2 = (((s2 & 4294967288) << 4) ^ b) & 4294967295 #s2 register
    # print("s2 reg: ", hex(s2))
    # b = (((s3 << 3) ^ s3) >> 11)
    # s3 = (((s3 & 4294967280) << 17) ^ b) & 4294967295 #s3 register
    # print("s3 reg: ", hex(s3))
    # print("xor_total: ", hex(s1^s2^s3))
    # return ((s1 ^ s2 ^ s3) * 2.3283064365e-10) #s1^s1^s3 = xor_total/xor_total_reg

low = 4
high = 20
num_cases = 100000

values = [None] * num_cases

for i in range(20):
    print("Iteration ", i)
    print("Final value ", i, ": ", taus88(), "\n")

# for i in range(num_cases):
#     #print(i)
#     init_fp = taus88()
#     mult_fp = init_fp * (high+1-low)
#     add_fp = mult_fp + low
#     values[i] = int(add_fp)

# number_counts = [values.count(i) for i in range(0, high+5)]
# plt.bar(range(0, high+5), number_counts)
# plt.xlabel('Numbers')
# plt.ylabel('Number counts')
# plt.xticks(range(0, high+5))
# plt.show()