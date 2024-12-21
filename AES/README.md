# AES Hardware Implementation

This project is a Verilog-based hardware implementation of the **AES (Advanced Encryption Standard)** algorithm. It includes the core AES functionalities like `SubBytes`, `ShiftRows`, `MixColumns`, and `Key Expansion`, which are implemented as individual modules and integrated into a complete AES system.

---

## Getting Started

This guide will walk you through the prerequisites, setup, and operation of the AES hardware implementation on an FPGA or in simulation.

---

### Prerequisites

1. **OSS CAD Suite**: Install [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build) for synthesis, place-and-route, and simulation.
2. **FPGA**: The design is targeted for the **Lattice iCE40HX8K** FPGA. Make sure you have a compatible FPGA board.
3. **Python**: Install Python to run the testbench (using **Cocotb**).
4. **GTKWAVE**: Use GTKWAVE to visualize waveforms during simulation.

---

## How to Run the Project

### 1. Setup and Synthesis
- Ensure your environment is correctly configured for **OSS CAD Suite**.
- Run the following command to synthesize, place, and route the design:
  ```bash
  make all
  ```
- Program the FPGA with:
  ```bash
  make prog-flash
  ```

---

### 2. Running Simulations
- To simulate the design and view waveforms, use:
  ```bash
  make sim
  make waveform
  ```

---

## Running at Different Clock Rates

The project uses the **SB_PLL40_CORE** module to generate clock frequencies. Follow these steps to test different clock rates:

1. **Edit the Clock PLL Configuration:**
   Use the `icepll` tool to configure the clock generator:
   ```bash
   icepll -i 12 -o <desired_frequency> > clkgen48.v
   ```
   Replace `<desired_frequency>` with the target frequency (e.g., 16, 24, 48 MHz).

2. **Update the UART Configuration:**
   Adjust the `CLKS_PER_BIT` parameter in `top_level.v` based on the new frequency:
   ```verilog
   defparam uart_inst.CLKS_PER_BIT = <calculated_value>;
   ```
   Refer to the following table for common frequencies:

   | Clock Frequency | `CLKS_PER_BIT` Value |
   |------------------|----------------------|
   | 12 MHz           | 104                  |
   | 16 MHz           | 139                  |
   | 24 MHz           | 208                  |
   | 48 MHz           | 416                  |

---

## Modules in the Design

### Key Modules
- **SubBytes**: Implements the AES S-box substitution.
- **ShiftRows**: Performs row-wise shifting in AES.
- **MixColumns**: Applies polynomial multiplication over GF(2^8).
- **Key Expansion**: Generates round keys required for encryption.

---

## Testbench

The project includes a comprehensive testbench implemented in **Cocotb** to verify:
1. Full encryption functionality.
2. Individual module correctness (`SubBytes`, `ShiftRows`, etc.).

To run the testbench:
```bash
make sim
```

---

## Known Issues

- **Simulation Limitations**: The `SB_PLL40_CORE` module is not fully supported in simulation. For testing, you may simulate with a static clock instead of using PLL-generated clocks.

---

### Contributions and Improvements
Feel free to fork this repository, make changes, and submit pull requests to improve the design or documentation.

---
