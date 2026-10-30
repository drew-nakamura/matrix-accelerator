# matrix-accelerato
Drew &amp; Mariella's Matrix-Accelerator

## AI Use Disclosure

AI assistance was used **only** for the CPU verification workflow, and only in these places:

- **Makefile**: AI-assisted, used to build and run the CPU regression in Cadence Xcelium.
- **riscv-tests assertions**: AI-assisted, used to check that the CPU still works as the rest of the design is added.

All CPU RTL was written by hand. AI did not write any RTL.

AI was not used for the systolic array. All of its RTL and verification are written by hand, with no AI-generated tests, assertions or scripts.
