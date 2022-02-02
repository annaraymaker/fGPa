import random
import matplotlib.pyplot as plt

low = 4
high = 13
num_cases = 10000

values = [None] * num_cases

for i in range(num_cases):
    print(i)
    init_fp = random.uniform(0, 1)
    mult_fp = init_fp * (high+1-low)
    add_fp = mult_fp + low
    values[i] = int(add_fp)

number_counts = [values.count(i) for i in range(0, high+5)]
plt.bar(range(0, high+5), number_counts)
plt.xlabel('Numbers')
plt.ylabel('Number counts')
plt.xticks(range(0, high+5))
plt.show()