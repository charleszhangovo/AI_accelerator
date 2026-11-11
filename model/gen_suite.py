import numpy as np

N_RANDOM = 200   # random pairs per size; total cases = 6 directed + 200 random = 206

def write_hex(path, arr, bits):
    mask = (1 << bits) - 1
    width = bits // 4
    with open(path, "w") as f:
        for v in np.asarray(arr).flatten():
            f.write(f"{int(v) & mask:0{width}x}\n")

def make_suite(N, seed):
    rng = np.random.default_rng(seed)
    rand = lambda: rng.integers(-128, 128, (N, N)) # lambda is a shortcut for defining a small Python function
    full = lambda v: np.full((N, N), v) # creates an N×N matrix filled with one particular value.
    eye = np.eye(N, dtype=int) #creates an identity matrix
    pairs = [
        (eye, rand()),             # identity times random
        (rand(), eye),             # random times identity
        (full(0), rand()),         # zeros
        (full(-128), full(-128)),  # most negative times most negative
        (full(127), full(127)),
        (full(-128), full(127)),
    ]
    pairs += [(rand(), rand()) for _ in range(N_RANDOM)]
    A = np.stack([p[0] for p in pairs]).astype(np.int64)
    B = np.stack([p[1] for p in pairs]).astype(np.int64)
    C = np.matmul(A, B)            # int64, so nothing overflows
    write_hex(f"model/suite{N}_A.hex", A, 8)
    write_hex(f"model/suite{N}_B.hex", B, 8)
    write_hex(f"model/suite{N}_C.hex", C, 32)
    print(f"N={N}: {len(pairs)} cases")

for N in (2, 4, 8):
    make_suite(N, seed=N)