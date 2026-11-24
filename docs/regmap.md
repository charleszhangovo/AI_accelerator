# Register map (accel_axi, N = 4)

All registers are 32 bits. Addresses are byte offsets from the IP base address.

| Offset | Name | Access | Meaning |
| --- | --- | --- | --- |
| 0x00 | CTRL | W | Write 1 to bit 0 to start a run. Self-clearing. Reads as 0. |
| 0x04 | STATUS | R | Bit 0 = busy, bit 1 = done. Done stays high until the next start. |
| 0x10 + 4i | A_ROW[i] | R/W | Row i of A. Byte j (bits 8j+7 to 8j) = A[i][j], signed INT8. |
| 0x20 + 4k | B_ROW[k] | R/W | Row k of B. Byte j = B[k][j], signed INT8. |
| 0x40 + 4m | C[m] | R | m = i*N + j. C[i][j] as a signed 32-bit integer. |

Rules:
- Write A and B only while busy is low. Writes during a run corrupt the result.
- Only full 32-bit writes are supported; byte strobes are ignored.
- One run takes 3N - 1 cycles after start; poll STATUS until done = 1.
- This layout packs one row per word, so it supports N up to 4.
