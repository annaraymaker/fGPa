import matplotlib.pyplot as plt

# LFSR seed.
state = (1 << 127) | (1 << 37) | (1 << 8) | (1 << 7) | (1 << 3) | 1

# Bit-width of numbers to generate.
b = 8

# Number of possible `b`-bit values.
n = 2 ** b

# Number of `b`-bit numbers to generate.
sample_size = 20000

# Randomly generated `b`-bit numbers.
numbers = []

for i in range(sample_size):
    number = []
    for j in range(b):
        number.append(str(state & 1))
        # print(state & 1, end='')
        newbit = (state ^ (state >> 1) ^ (state >> 2) ^ (state >> 7))
        state = (state >> 1) | (newbit << 127)
    numbers.append(int(''.join(number), 2))

number_counts = [numbers.count(i) for i in range(n)]
plt.bar(range(n), number_counts)
plt.xlabel('Numbers')
plt.ylabel('Number counts')
plt.show()