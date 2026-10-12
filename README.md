# AI Accelerator

An INT8 matrix-multiply AI accelerator written in SystemVerilog, built to practice RTL design, verification, and timing analysis.

**Status: in progress.**

## What exists so far

- `rtl/mult8.sv`: 8-bit signed multiplier with a 16-bit product
- `rtl/reg8.sv`: 8-bit register with synchronous reset and enable
- `rtl/mac.sv`: multiply-accumulate (MAC) unit with a 32-bit signed accumulator, synchronous clear, and enable
- `model/`: Python scripts that generate test inputs and the expected results (the golden model)
- `tb/`: self-checking testbenches. One tests the multiplier on all 65,536 input pairs. The other checks the MAC's accumulator on every clock cycle against the Python model, using directed and random tests.
- `scripts/run_all.sh`: runs lint and every test

## How to run

You need Icarus Verilog, Verilator, and Python 3. On macOS:

```bash
brew install icarus-verilog verilator python
```

Then, from the repo's top folder:

```bash
./scripts/run_all.sh
```

If everything works, the last line printed is `ALL PASS`.