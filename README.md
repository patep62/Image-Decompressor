## COE3DQ5 project

### Objective

The main objective of the COE3DQ5 project is to make students comfortable to work on a larger design (than the labs) that also includes the hardware implementation of several types of digital signal processing algorithms. In addition, the hardware design and implementation must meet the 50 MHz clock constraint, some latency constraints (defined indirectly through multiplier utilization constraints), while ensuring that hardware resources are not wasted.

### Preparation

In terms of verification, there are two main additions: a software model of the image decoder is provided in the `sw` sub-folder and the backbones for two additional testbenches are provided in the `tb` sub-folder (they can be compiled to replace the default lab 5 experiment 4 testbench by updating `compile.do` in the `sim` sub-folder).
