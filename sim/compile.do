
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET +define+SIMULATION $rtl/SRAM_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/PB_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/VGA_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/convert_hex_to_seven_segment.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET +define+SIMULATION $rtl/UART_receive_controller.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/UART_SRAM_interface.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/VGA_SRAM_interface.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/project.sv
vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $rtl/dual_port_RAM.v

vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/tb_SRAM_Emulator.sv
#vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/testbench.sv

# while trouble-shooting you should first use version 0 of the testbench (tb_project_v0.sv)
# this can be done by commenting the above vlog line and commenting out the one below

vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/tb_project_v0.sv

# once the project passes a given milestone for the version 0 of the testbench
# do a final check with version 1, which should help validate the top-level integration

#vlog -sv -work my_work +define+DISABLE_DEFAULT_NET $tb/tb_project_v1.sv

