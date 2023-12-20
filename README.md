# A Hardware Implementation of an Image Decompressor

### Introduction
This was an incredibly challenging and just as rewarding project to work on. Throughout it's inception, I learned the ins and outs of SystemVerilog, the intricacies of low-level hardware programming, and the importance of a structured design approach. The aim of this project was not to create something to rival existing image compression technologies, but to gain experience in digital system design, working with hardware constraints and components such as UARTs, SRAMs, and VGAs.
This README, although extensive, is a summarized version of the report found in the doc folder. 

The objective of this collaborative project is to decode a 320 x 240 pixel image
through a hardware implementation. Provided compressed data stored in the SRAM is
decoded through a series of stages, from which the original image will be restored.
Processing begins with lossless decoding and dequantization to revert the given data back to
the frequency domain. This is followed by inverse signal transformation, producing a set of
Y/U/V values. The Y data represents the brightness levels of each pixel, while U and V
provide colour. However, since the human eye is more sensitive to brightness, double the Y
values will be produced as opposed to the U/V values. This is done during compression to
maximize efficiency while maintaining image quality. Finally, the Y/U/V values are
processed through a series of up sampling (through interpolation) and colour space
conversion to restore the original raw RGB data which is then sent to the VGA controller to
be displayed as a .ppm file. The following figure [1] depicts the conceptual flow for basic image compression and decompression. The relative
amount of data at each stage is roughly indicated by the size of the arrow.

![image](https://github.com/patep62/Image-Decompressor/assets/71285160/ae0061c6-de6e-4cf0-948a-378a043543f2)

The following figure [1] shows, at the high level, how the image can be decomposed into 
![image](https://github.com/patep62/Image-Decompressor/assets/71285160/d777d349-3e77-4089-affc-a15eabfda759)


### Design Structure

In this project both Milestone 1 and 2 were implemented in the top-level FSM in
order to design an image hardware decompressor. In this top level FSM three data busses
were used in order to flow data within the module; SRAM_address, SRAM_we_n and
SRAM_write_data. Other modules used throughout this project were
UART_SRAM_Interface and VGA_SRAM_Interface.

# Implementation Details
## Milestone 1: Up Sampling and Colour Space Conversion.
The hardware constraints applied to this segment of design are as follows. We are
only able to use two multipliers, which must be utilized in at least 85% of all clock cycles in
this milestone. As a result, the processes of up sampling and colorspace conversion must be
done simultaneously in order to meet the utilization constraint. Where U’ and U represent the
up sampled and down sampled values respectively, for pixel j on the image. The down
sampled U values can represent a 160 x 240 pixel image, whereas the up sampled U’ values
represent a 320 x 240 pixel image. For example, in processing pixel 1, the first partial
product yields 21*U[-2]. This value obviously does not exist, and thus must be handled
differently as opposed to the interpolation of pixels away from the image edges. As a result
of these design requirements, Milestone 1 is split up into a series of lead in cases, lead out
cases, and a common case. The designed FSM will rotate through these stages (performing
up sampling and color space conversion) until all rows of pixel data are produced.

### The Common Case States
During execution, the hardware will be spending the vast majority of it’s time and
computations in the common case states. As such, meeting the 85% utilization constraint is
imperative, and will allow a large amount of leniency with the design of our lead in and lead
out cases. Every iteration of the common case will produce a pair of pixels. The interpolation
is done differently for even and odd pixels, therefore it makes sense to process one pair at a
time consisting of an even and an odd pixel. So, when considering the number of
multiplications that needs to be done in each iteration of the common case, 6 are required for
the interpolation of the odd U/V values (when exploiting the symmetry in the equation), and
then 5 are required for each even/odd pixel during colorspace conversion. This totals to 16
multiplications per common case, which will require minimum 8 clock cycles since we are
given 2 multipliers to use. We can use them at most, 2*k times per common case, where k is
the number of clock cycles. If we have 9 clock cycles, we have a utilization of 16/18 which is
88.89%. However, with 10 clock cycles we have a utilization of 16/20 which is only 80%. As
such, our common case consists of 9 clock cycles instead of 8 to allow for some leniency.

The design consists of 6 U and 6 V registers which
will store a series of U/V values depending on which iteration of the common case we are on.
6 registers are necessary because each odd interpolated U’/V’ value is a function of 6 U/V
values. Exploiting symmetry, it is always going to be the opposite registers whose values will
be added together. Therefore, R5 and R0 are passed through an adder, just as R4 and R1, and
R3 and R2. The sums are then sent into a 4 input MUX from which the sum selected will be
the input of the a multiplier. The other input for the multiplier is provided by a single 4 input
MUX that will pass through the appropriate coefficient. The partial product is then stored
into an accumulator (MAC unit). The hardware circuit used is drawn out below.

![image](https://github.com/patep62/Image-Decompressor/assets/71285160/cdf5920a-d2a3-474e-b0e8-c5f31a082fda)

### The Lead in/out Cases

As mentioned earlier, the purpose of these lead in/out cases is to cover the unique
computations for edge pixels. However, the lead in cases will also load the first 6 U/V values
for every new row. As a result, no additional reads are necessary during the lead out cases.
The lead out states will transition directly into the lead in states where 3 reads are done,
filling all 6 registers. The multipliers are not being used during these clock cycles, but we
have a quite a bit of leniency with the utilization in these states. With reference to the
interpolation formula, there are two pixel pairs that require unique computations are the
beginning of each row, and three pixel pairs at the end. The lead in/out states compute just
these pixels.

In terms of the critical path, we can observe from the Timing analyzer that the critical path
starts from the node Mult_op_2A[17:0] and ends at the node AccumulatorV[30]. The reason
why this path has the longest delay is due to the fact the largest value in Mult_op_2A is
132251 which is 18 bits ([17:0]), this register goes through a series of calculations that are
needed to calculate data for V’[odd] before it reaches AccumulatorV[30], thus it will be the
longest path.

## Milestone 2: IDCT and DPRAM Organization

For this milestone we were given permission to use 3 Dual-Port RAMs that are 32 bits wide
by 128 bits long (addresses) (4096 bits) . We chose to use the first half of DPRAM 1,
addresses 0-63 to load in a single S’ value at a time per each address of the DPRAM. Since
the DPRAM has 32 bits per address and S’ is only 16 bits we had to use signed extension
replicating the 15th of bit SRAM_read_data 15 times and contacanting that with
SRAM_read_data and the passing this to the write data register port to load in one S’ value
at a time. Furthermore the bottom half of the ram was used to pack three 8-bit S values in one
single address which can hold up to 32 bits. Which are then read in MSA. DPRAM 2 was
used to hold T even values and DPRAM 3 was used to hold Todd values. We repeat this
process 7 more times for the remaining Matrix A rows.


Reference:
[1]  J. Thong, A. Kinsman, N. Nicolici Class Lecture, Topic: "COE3DQ5 Project Description 2021
Hardware Implementation of an Image Decompressor.” Digital Systems Design Course at McMaster University, Canada.


