# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

add wave -divider -height 20 {Top-level signals}
add wave -bin UUT/CLOCK_50_I
add wave -bin UUT/resetn
add wave UUT/top_state
add wave -uns UUT/UART_timer
add wave UUT/M2_state

add wave -divider -height 10 {M2 signals}
add wave -hex -unsigned UUT/address1
add wave -bin {UUT/write_enable_1}
add wave -hex {UUT/write_data_1}
add wave -uns UUT/i
add wave -uns UUT/j
add wave -dec UUT/address1
add wave -dec UUT/address2
add wave -dec UUT/address3
add wave -bin UUT/T_flag
add wave -bin UUT/write_enable_2
add wave -bin UUT/write_enable_3
#add wave -uns UUT/c_index_0
#add wave -uns UUT/c_index_1
#add wave -uns UUT/c_index_2
#add wave -dec UUT/C0
#add wave -dec UUT/C1
#add wave -dec UUT/C2
add wave -uns UUT/k
add wave -dec UUT/read_data_1
add wave -dec UUT/read_data_2
add wave -dec UUT/read_data_3
add wave -dec UUT/Accumulator0
add wave -dec UUT/Accumulator1
add wave -dec UUT/Accumulator2
add wave -dec UUT/Mult_resultA
add wave -dec UUT/Mult_resultB
add wave -dec UUT/Mult_resultC
add wave -dec UUT/Mult_op_1A
add wave -dec UUT/Mult_op_2A
add wave -dec UUT/Mult_op_1B
add wave -dec UUT/Mult_op_2B
add wave -dec UUT/Mult_op_1C
add wave -dec UUT/Mult_op_2C
#add wave -uns UUT/Dram2_last_add
#add wave -uns UUT/Dram3_last_add
add wave -uns UUT/row_counter
add wave -dec UUT/write_data_2
add wave -dec UUT/write_data_3
add wave -uns UUT/write_count
#add wave -uns UUT/row_address
#add wave -uns UUT/col_address
#add wave -uns UUT/C_counter

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/SRAM_address
add wave -hex UUT/M2_SRAM_write_data
add wave -bin UUT/M2_SRAM_we_n
add wave -hex UUT/SRAM_read_data

add wave -divider -height 10 {VGA signals}
add wave -bin UUT/VGA_unit/VGA_HSYNC_O
add wave -bin UUT/VGA_unit/VGA_VSYNC_O
add wave -uns UUT/VGA_unit/pixel_X_pos
add wave -uns UUT/VGA_unit/pixel_Y_pos
add wave -hex UUT/VGA_unit/VGA_red
add wave -hex UUT/VGA_unit/VGA_green
add wave -hex UUT/VGA_unit/VGA_blue

