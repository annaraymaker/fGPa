import random
import matplotlib.pyplot as plt

s1 = random.getrandbits(32)
s2 = random.getrandbits(32)
s3 = random.getrandbits(32)

def taus88():
    global s1, s2, s3
    b = (((s1 << 13) ^ s1) >> 19)
    s1 = (((s1 & 4294967294) << 12) ^ b) & 4294967295
    b = (((s2 << 2) ^ s2) >> 25)
    s2 = (((s2 & 4294967288) << 4) ^ b) & 4294967295
    b = (((s3 << 3) ^ s3) >> 11)
    s3 = (((s3 & 4294967280) << 17) ^ b) & 4294967295
    return ((s1 ^ s2 ^ s3) * 2.3283064365e-10)

low = 4
high = 200
num_cases = 100000

values = [None] * num_cases

# for i in range(1000):
#     print(taus88())

for i in range(num_cases):
    #print(i)
    init_fp = taus88()
    mult_fp = init_fp * (high+1-low)
    add_fp = mult_fp + low
    values[i] = int(add_fp)

number_counts = [values.count(i) for i in range(0, high+5)]
plt.bar(range(0, high+5), number_counts)
plt.xlabel('Numbers')
plt.ylabel('Number counts')
plt.xticks(range(0, high+5))
plt.show()