# MAC Spec

## Purpose
The MAC multiplies two signed 8-bit numbers every clock cycle and adds the result into a running 32-bit total.

## Ports
- `clk`: clock
- `clear`: sets the total to 0
- `en`: enables the update

## Behavior
On each rising clock edge:
1. If `clear` is high, `acc` becomes 0.
2. Otherwise, if `en` is high, `acc` becomes `acc + a * b`.
3. Otherwise, `acc` holds.