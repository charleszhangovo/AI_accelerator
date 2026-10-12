import random

def to_signed(x, bits):
    x &= (1 << bits) - 1
    return x - (1 << bits) if x >= (1 << (bits - 1)) else x
#This function converts to signed integer of given bit width 
#1<<bits shift left by bits, (1<<bits)-1 gives a mask of bits 1s

def mac_model(cycles):
    acc = 0
    expected = []
    for clear, en, a, b in cycles:
        if clear:
            acc = 0
        elif en:
            acc = to_signed(acc + a * b, 32)
        expected.append(acc)
    return expected
#This function simulates the MAC operation based on the input cycles

def write_files(name, cycles):
    with open(f"model/{name}_stim.hex", "w") as f:
        for clear, en, a, b in cycles:
            word = (clear << 17) | (en << 16) | ((a & 0xFF) << 8) | (b & 0xFF) #combine clear, en, a, b into a single 18-bit word
            f.write(f"{word:05x}\n")
    with open(f"model/{name}_exp.hex", "w") as f:
        for e in mac_model(cycles):
            f.write(f"{e & 0xFFFFFFFF:08x}\n") #write the expected output with 32 bits mask to a file in hex format
    return len(cycles)


def random_cycles(seed, n):
    rng = random.Random(seed) #using seed cause we want reproducible randomness
    pool = [-128, -1, 0, 1, 127] #1 test positive, -1 test negative, 0 test zero, 127 test max positive, -128 test max negative
    cycles = [(1, 0, 0, 0)] #initialize with a clear, en, a, b 
    for _ in range(n):
        clear = 1 if rng.random() < 0.05 else 0 #5% chance to clear the accumulator
        en = 1 if rng.random() < 0.8 else 0 #80% chance to enable the MAC operation
        a = rng.choice(pool) if rng.random() < 0.2 else rng.randint(-128, 127) #20% chance to pick from pool, otherwise random between -128 and 127
        b = rng.choice(pool) if rng.random() < 0.2 else rng.randint(-128, 127)
        cycles.append((clear, en, a, b))
    return cycles

directed = [
    (1, 0, 0, 0),        # clear to start
    (0, 1, -128, -128),  # +16384
    (0, 1, -128, 127),   # -16256
    (0, 1, 127, 127),    # +16129
    (0, 1, 5, -3),       # -15
    (0, 1, 77, 0),       # times zero
    (0, 0, 100, 100),    # en low: hold
    (1, 1, 9, 9),        # clear wins over en
    (0, 1, 3, 4),
    (0, 1, -1, -1),
]

sets = {"directed": directed}
for seed in (1, 2, 3):
    sets[f"random{seed}"] = random_cycles(seed, 1000)
#set looks like sets = {"directed": directed,
#                       "random1": random_cycles(1, 1000),
#                       "random2": random_cycles(2, 1000),
#                       "random3": random_cycles(3, 1000)}

for name, cycles in sets.items():
    print(name, write_files(name, cycles))