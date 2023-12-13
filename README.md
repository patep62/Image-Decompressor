## COE3DQ5 project

### Objective

The main objective of the COE3DQ5 project is to make students comfortable to work on a larger design (than the labs) that also includes the hardware implementation of several types of digital signal processing algorithms. In addition, the hardware design and implementation must meet the 50 MHz clock constraint, some latency constraints (defined indirectly through multiplier utilization constraints), while ensuring that hardware resources are not wasted.

### Preparation

The design code from the rtl sub-folder contains a copy of the code released for experiment 4 from lab 5, which is the start-up code for the project (note, only the top-level module name `experiment4` has been changed to `project`). 

In terms of verification, there are two main additions: a software model of the image decoder is provided in the `sw` sub-folder and the backbones for two additional testbenches are provided in the `tb` sub-folder (they can be compiled to replace the default lab 5 experiment 4 testbench by updating `compile.do` in the `sim` sub-folder).

* Revise the five labs
* Read [this](doc/3dq5-2021-project-description.pdf) detailed project document and get familiarized with the software model from the `sw` sub-folder 
* Attend the forthcoming classes because they are focused almost exclusively on the project (conceptual understanding, main challenges, thought process, design decisions, verification plan, ...)
* If needed, any updates, changes, revisions, ... will be communicated to the entire class in due time

### Evaluation

Push your source code and the 6-page report in GitHub before November 29 at 11 pm. The report should be in PDF format and should be placed in the `doc` sub-folder. Further details concerning the expectations for the project report and the cross-examinations in the week of November 29 will be provided in due time.
