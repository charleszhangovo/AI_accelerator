with open("model/products.hex", "w") as f:
    for a_u in range(256):
        for b_u in range(256):
            a = a_u - 256 if a_u >= 128 else a_u   
            b = b_u - 256 if b_u >= 128 else b_u
            p = a * b
            f.write(f"{p & 0xFFFF:04x}\n")          