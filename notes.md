### Things to be aware of:

`Load_Use_Detected (Data Hazard)`

- Cause: Instruction in ID needs data from the instruction currently in EX (which is a Load).

- Action: Stall PC, Stall IF/ID, Flush ID/EX.

`Branch_Taken (Control Hazard)`

- Cause: BEQ/BNE/BLT etc. in EX stage evaluates to true.

- Action: Flush IF/ID, Flush ID/EX. (Update PC).

`IMem_Stall (Structural Hazard)`

- Cause: Instruction fetch not ready (cache miss or bus wait).

- Action: Stall PC, Stall IF/ID. (Inject bubble into ID/EX).

`DMem_Stall (Structural Hazard)`

- Cause: Load/Store in MEM stage not ready.

- Action: Stall PC, Stall IF/ID, Stall ID/EX, Stall EX/MEM. Flush MEM/WB.