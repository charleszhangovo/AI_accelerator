import numpy as np

def write_hex(path, arr, bits):
    mask = (1 << bits) - 1
    width = bits // 4
    with open(path, "w") as f:
        for v in arr.flatten():
            f.write(f"{int(v) & mask:0{width}x}\n")

def make(name, A, B):
    A = np.array(A, dtype=np.int32)
    B = np.array(B, dtype=np.int32)
    C = A @ B                      # int32 math, so nothing overflows
    write_hex(f"model/{name}_A.hex", A, 8)
    write_hex(f"model/{name}_B.hex", B, 8)
    write_hex(f"model/{name}_C.hex", C, 32)
    print(name, "C =")
    print(C)

make("mat2_day1", [[1, 2], [3, 4]], [[5, 6], [7, 8]])

rng = np.random.default_rng(1)
make("mat4_rand", rng.integers(-128, 128, (4, 4)), rng.integers(-128, 128, (4, 4)))
make("mat4_extreme", np.full((4, 4), -128), np.full((4, 4), -128))