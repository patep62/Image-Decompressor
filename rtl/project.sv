/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

// This is the top module (same as experiment4 from lab 5 - just module renamed to "project")
// It connects the UART, SRAM and VGA together.
// It gives access to the SRAM for UART and VGA
module project (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[3:0] PUSH_BUTTON_N_I,         // pushbuttons
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays
		output logic[8:0] LED_GREEN_O,            // 9 green LEDs

		/////// VGA interface                     ////////////
		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[7:0] VGA_RED_O,              // VGA red
		output logic[7:0] VGA_GREEN_O,            // VGA green
		output logic[7:0] VGA_BLUE_O,             // VGA blue
		
		/////// SRAM Interface                    ////////////
		inout wire[15:0] SRAM_DATA_IO,            // SRAM data bus 16 bits
		output logic[19:0] SRAM_ADDRESS_O,        // SRAM address bus 18 bits
		output logic SRAM_UB_N_O,                 // SRAM high-byte data mask 
		output logic SRAM_LB_N_O,                 // SRAM low-byte data mask 
		output logic SRAM_WE_N_O,                 // SRAM write enable
		output logic SRAM_CE_N_O,                 // SRAM chip enable
		output logic SRAM_OE_N_O,                 // SRAM output logic enable
		
		/////// UART                              ////////////
		input logic UART_RX_I,                    // UART receive signal
		output logic UART_TX_O                    // UART transmit signal
);
	
logic resetn;

top_state_type top_state;
M1_state_type M1_state;
M2_state_type M2_state;

//Milestone 2: @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
parameter preIDCT_offsetY = 18'd76800;
parameter preIDCT_offsetU = 18'd153600;
parameter preIDCT_offsetV = 18'd192000;

logic [8:0] address1 [1:0]; //LSB refers to top port, MSB refers to bottom port.
logic [8:0] address2 [1:0];
logic [8:0] address3 [1:0];

logic [31:0] write_data_1 [1:0]; //LSB refers to top port, MSB refers to bottom port.
logic [31:0] write_data_2 [1:0];
logic [31:0] write_data_3 [1:0];

logic [31:0] read_data_1 [1:0]; //LSB refers to top port, MSB refers to bottom port.
logic [31:0] read_data_2 [1:0];
logic [31:0] read_data_3 [1:0];

logic write_enable_1 [1:0]; //LSB refers to top port, MSB refers to bottom port.
logic write_enable_2 [1:0];
logic write_enable_3 [1:0];
logic [31:0] C_counter;
logic [15:0] Ybuffer;
logic [5:0] cycle_counter; 


logic Ct_flag;
logic T_flag;
logic signed [31:0] C0,C1,C2;
logic [5:0] c_index_0, c_index_1,c_index_2;
logic unsigned [4:0] i,j;
logic unsigned [9:0] k;

logic [31:0] Accumulator0, Accumulator1, Accumulator2;

logic [8:0] Dram2_last_add, Dram3_last_add;


logic [31:0] row_address, col_address;
//Milestone 2: @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@







//Milestone 1:
parameter U_offset = 18'd38400;
parameter V_offset = 18'd57600;
parameter RGB_offset = 18'd146944;

logic [17:0] data_counterY;
logic [17:0] data_counterU;
logic [17:0] data_counterV;
logic [17:0] temp_counter;

//logic [17:0] line_counter;
logic [31:0] red [1:0];
logic [31:0] blue [1:0];
logic [31:0] green [1:0];
//logic [15:0] Y_buffer;

logic M1_start;
logic M2_start;
logic M1_finish;

logic [7:0] RegisterU [5:0];
logic [7:0] RegisterV [5:0];
logic [31:0] AccumulatorU;
logic [31:0] AccumulatorV;
logic [7:0] RegisterY [1:0];
logic [31:0] UPrime [1:0];
logic [31:0] VPrime [1:0];
logic [17:0] write_count;
logic [15:0] CC_counter;
logic [17:0] pixel_count;
logic [7:0] write [1:0];

//logic [4:0] row_counter;






logic M1_read_odd_even;


// For Push button
logic [3:0] PB_pushed;

// For VGA SRAM interface
logic VGA_enable;
logic [17:0] VGA_base_address;
logic [17:0] VGA_SRAM_address;

// For SRAM
logic [17:0] SRAM_address;
logic [17:0] M1_SRAM_address;
logic [15:0] SRAM_write_data;
logic [15:0] M1_SRAM_write_data;
logic [15:0] row_counter;
logic SRAM_we_n;
logic M1_SRAM_we_n;
logic [15:0] SRAM_read_data;
logic SRAM_ready;

logic [17:0] M2_SRAM_address;
logic [15:0] M2_SRAM_write_data;
logic M2_SRAM_we_n;

// For UART SRAM interface
logic UART_rx_enable;
logic UART_rx_initialize;
logic [17:0] UART_SRAM_address;
logic [15:0] UART_SRAM_write_data;
logic UART_SRAM_we_n;
logic [25:0] UART_timer;

logic [6:0] value_7_segment [7:0];

// For error detection in UART
logic Frame_error;

// For disabling UART transmit
assign UART_TX_O = 1'b1;

assign resetn = ~SWITCH_I[17] && SRAM_ready;


dual_port_RAM DRAM_inst0 (
    .address_a ( address1[0] ),
    .address_b ( address1[1] ),
    .clock ( CLOCK_50_I ),
    .data_a ( write_data_1[0] ),
    .data_b ( write_data_1[1] ),
    .wren_a ( write_enable_1[0] ),
    .wren_b ( write_enable_1[1] ),
    .q_a ( read_data_1[0] ),
    .q_b ( read_data_1[1] )
    );

dual_port_RAM DRAM_inst1 (
    .address_a ( address2[0] ),
    .address_b ( address2[1] ),
    .clock ( CLOCK_50_I ),
    .data_a ( write_data_2[0] ),
    .data_b ( write_data_2[1] ),
    .wren_a ( write_enable_2[0] ),
    .wren_b ( write_enable_2[1] ),
    .q_a ( read_data_2[0] ),
    .q_b ( read_data_2[1] )
    );


dual_port_RAM DRAM_inst2 (
    .address_a ( address3[0] ),
    .address_b ( address3[1] ),
    .clock ( CLOCK_50_I ),
    .data_a ( write_data_3[0] ),
    .data_b ( write_data_3[1] ),
    .wren_a ( write_enable_3[0] ),
    .wren_b ( write_enable_3[1] ),
    .q_a ( read_data_3[0] ),
    .q_b ( read_data_3[1] )
    );


// Push Button unit
PB_controller PB_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	.PB_signal(PUSH_BUTTON_N_I),	
	.PB_pushed(PB_pushed)
);

VGA_SRAM_interface VGA_unit (
	.Clock(CLOCK_50_I),
	.Resetn(resetn),
	.VGA_enable(VGA_enable),
   
	// For accessing SRAM
	.SRAM_base_address(VGA_base_address),
	.SRAM_address(VGA_SRAM_address),
	.SRAM_read_data(SRAM_read_data),
   
	// To VGA pins
	.VGA_CLOCK_O(VGA_CLOCK_O),
	.VGA_HSYNC_O(VGA_HSYNC_O),
	.VGA_VSYNC_O(VGA_VSYNC_O),
	.VGA_BLANK_O(VGA_BLANK_O),
	.VGA_SYNC_O(VGA_SYNC_O),
	.VGA_RED_O(VGA_RED_O),
	.VGA_GREEN_O(VGA_GREEN_O),
	.VGA_BLUE_O(VGA_BLUE_O)
);

// UART SRAM interface
UART_SRAM_interface UART_unit(
	.Clock(CLOCK_50_I),
	.Resetn(resetn), 
   
	.UART_RX_I(UART_RX_I),
	.Initialize(UART_rx_initialize),
	.Enable(UART_rx_enable),
   
	// For accessing SRAM
	.SRAM_address(UART_SRAM_address),
	.SRAM_write_data(UART_SRAM_write_data),
	.SRAM_we_n(UART_SRAM_we_n),
	.Frame_error(Frame_error)
);

// SRAM unit
SRAM_controller SRAM_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(~SWITCH_I[17]),
	.SRAM_address(SRAM_address),
	.SRAM_write_data(SRAM_write_data),
	.SRAM_we_n(SRAM_we_n),
	.SRAM_read_data(SRAM_read_data),		
	.SRAM_ready(SRAM_ready),
		
	// To the SRAM pins
	.SRAM_DATA_IO(SRAM_DATA_IO),
	.SRAM_ADDRESS_O(SRAM_ADDRESS_O[17:0]),
	.SRAM_UB_N_O(SRAM_UB_N_O),
	.SRAM_LB_N_O(SRAM_LB_N_O),
	.SRAM_WE_N_O(SRAM_WE_N_O),
	.SRAM_CE_N_O(SRAM_CE_N_O),
	.SRAM_OE_N_O(SRAM_OE_N_O)
);

assign SRAM_ADDRESS_O[19:18] = 2'b00;

logic signed [31:0] Mult_op_1A, Mult_op_2A, Mult_resultA;
logic [63:0] Mult_result_longA;

logic signed [31:0] Mult_op_1B, Mult_op_2B, Mult_resultB;
logic [63:0] Mult_result_longB;

logic signed [31:0] Mult_op_1C, Mult_op_2C, Mult_resultC;
logic [63:0] Mult_result_longC;

//Multiplier 1
assign Mult_result_longA = Mult_op_1A * Mult_op_2A;
assign Mult_resultA = Mult_result_longA[31:0]; 

//Multiplier 2
assign Mult_result_longB = Mult_op_1B * Mult_op_2B;
assign Mult_resultB = Mult_result_longB[31:0]; 

//Multiplier 3
assign Mult_result_longC = Mult_op_1C * Mult_op_2C;
assign Mult_resultC = Mult_result_longC[31:0]; 


always @(posedge CLOCK_50_I or negedge resetn) begin
	if (~resetn) begin
		top_state <= S_IDLE;
		//M1_start <= 1'b1;
		UART_rx_initialize <= 1'b0;
		UART_rx_enable <= 1'b0;
		UART_timer <= 26'd0;
		
		VGA_enable <= 1'b1;
	end else begin

		// By default the UART timer (used for timeout detection) is incremented
		// it will be synchronously reset to 0 under a few conditions (see below)
		UART_timer <= UART_timer + 26'd1;

		case (top_state)
		S_IDLE: begin
			VGA_enable <= 1'b1;  
			if (~UART_RX_I) begin
				// Start bit on the UART line is detected
				UART_rx_initialize <= 1'b1;
				UART_timer <= 26'd0;
				VGA_enable <= 1'b0;
				top_state <= S_UART_RX;
			end
		end

		S_UART_RX: begin
			// The two signals below (UART_rx_initialize/enable)
			// are used by the UART to SRAM interface for 
			// synchronization purposes (no need to change)
			UART_rx_initialize <= 1'b0;
			UART_rx_enable <= 1'b0;
			if (UART_rx_initialize == 1'b1) 
				UART_rx_enable <= 1'b1;

			// UART timer resets itself every time two bytes have been received
			// by the UART receiver and a write in the external SRAM can be done
			if (~UART_SRAM_we_n) 
				UART_timer <= 26'd0;

			// Timeout for 1 sec on UART (detect if file transmission is finished)
			if (UART_timer == 26'd49999999) begin
				top_state <= S_M2;
				M1_start <= 1'b0;
				M2_start <= 1'b1;
				UART_timer <= 26'd0;
			end
		end
		
		S_M1: begin
		
			case(M1_state)
			
			
			S_M1_IDLE: begin
			
			M1_SRAM_we_n <= 1'b1;
			
			if (M1_start == 1'b1) begin
				
				M1_start <= 1'b0;
				
				data_counterY <= 18'd0;
				data_counterU <= 18'd0;
				data_counterV <= 18'd0;
				write_count <= 18'd0;
				
				red[0] <= 32'd0;
				red[1] <= 32'd0;
				green[0] <= 32'd0;
				green[1] <= 32'd0;
				blue[0] <= 32'd0;
				blue[1] <= 32'd0;
				
				RegisterU[0] <= 8'd0;
				RegisterU[1] <= 8'd0;
				RegisterU[2] <= 8'd0;
				RegisterU[3] <= 8'd0;
				RegisterU[4] <= 8'd0;
				RegisterU[5] <= 8'd0;
				
				RegisterV[0] <= 8'd0;
				RegisterV[1] <= 8'd0;
				RegisterV[2] <= 8'd0;
				RegisterV[3] <= 8'd0;
				RegisterV[4] <= 8'd0;
				RegisterV[5] <= 8'd0;
				
				RegisterY[0] <= 8'd0;
				RegisterY[1] <= 8'd0;
				
				UPrime[0] <= 32'd0;
				UPrime[1] <= 32'd0;
				VPrime[0] <= 32'd0;
				VPrime[1] <= 32'd0;
				
				write[0] <= 8'd0;
				write[1] <= 8'd1;
				
				M1_SRAM_we_n <= 1'b1;
				M1_SRAM_write_data <= 16'b0;
				
				M1_read_odd_even <= 1'b0;
				
				CC_counter <= 16'd0;
				pixel_count <= 18'd0;
				row_counter <= 16'd0;
				temp_counter <= 18'd5;
				
				//Y_buffer <= 16'd0;
				
				AccumulatorU <= 32'd128;
				AccumulatorV <= 32'd128;
				
				M1_state <= S_M1_LEADIN_0;
			
			end
			
			end
			
			S_M1_LEADIN_0: begin
			
			//Initiate reads for U values.
			M1_SRAM_address <= U_offset + data_counterU;
			data_counterU <= data_counterU + 18'd1;
			
			AccumulatorU <= 32'd128;
			AccumulatorV <= 32'd128;
			
			M1_state <= S_M1_LEADIN_1;
			
			end
			
			S_M1_LEADIN_1: begin
			
			//Request a read for U values.
			M1_SRAM_address <= U_offset + data_counterU;
			data_counterU <= data_counterU + 18'd1;
			
			M1_state <= S_M1_LEADIN_2;
			
			end
			
			S_M1_LEADIN_2: begin
			
			//Request a read for  last U values.
			M1_SRAM_address <= U_offset + data_counterU;
			data_counterU <= data_counterU + 18'd1;
			
			M1_state <= S_M1_LEADIN_3;
			
			
			end
			
			S_M1_LEADIN_3: begin
			
			//Initiate reads for V values.
			M1_SRAM_address <= V_offset + data_counterV;
			data_counterV <= data_counterV + 18'd1;
			
			//Load first U values into their registers
			RegisterU[0] <= SRAM_read_data[15:8];
			RegisterU[1] <= SRAM_read_data[7:0];
			
			//Load even U Prime right away cuz why not?
			UPrime[0] <= SRAM_read_data[15:8];
			
			//159 * (U0 + U1)
			Mult_op_1A <= (SRAM_read_data[15:8] + SRAM_read_data[7:0]);
			Mult_op_2A <= 32'sd159;
			
			M1_state <= S_M1_LEADIN_4;
			
			end
			
			S_M1_LEADIN_4: begin
			
			//Request a read for V value.
			M1_SRAM_address <= V_offset + data_counterV;
			data_counterV <= data_counterV + 18'd1;
			
			//Load 159 * (U0 + U1) into U Accumulator
			AccumulatorU <= AccumulatorU + Mult_resultA;
			
			//21 * (U0 + U3)
			Mult_op_1A <= (RegisterU[0] + SRAM_read_data[7:0]);
			Mult_op_2A <= 32'sd21;
			
			//52 * (U0 + U2)
			Mult_op_1B <= (RegisterU[0] + SRAM_read_data[15:8]);
			Mult_op_2B <= 32'sd52;
			
			//Load U value.
			RegisterU[2] <= SRAM_read_data[15:8];
			RegisterU[3] <= SRAM_read_data[7:0];
			
						
			M1_state <= S_M1_LEADIN_5;
			
			
			end
			
			S_M1_LEADIN_5: begin
			
			//Request a read for V value.
			M1_SRAM_address <= V_offset + data_counterV;
			data_counterV <= data_counterV + 18'd1;
			
			//Load 21 * (U0 + U3) and -52 * (U0 + U2) into U Accumulator. 
			AccumulatorU <= AccumulatorU + Mult_resultA - Mult_resultB;
			
			//Load last U values.
			RegisterU[4] <= SRAM_read_data[15:8];
			RegisterU[5] <= SRAM_read_data[7:0];
			
			M1_state <= S_M1_LEADIN_6;		
			
			end
			
			S_M1_LEADIN_6: begin
			
			//Request a read for Y values.
			M1_SRAM_address <= data_counterY;
			data_counterY <= data_counterY + 18'd1;	
			
			//Load the first V values.
			RegisterV[0] <= SRAM_read_data[15:8];
			RegisterV[1] <= SRAM_read_data[7:0];
			
			//Load the U Accumulator into the odd U Prime register with a non-clipping right bit shift.
			UPrime[1] <= {{8{AccumulatorU[31]}}, AccumulatorU[31:8]}; 
			
			//Load the even V Prime value. 
			VPrime[0] <= SRAM_read_data[15:8];
			
			//159 * (V0 + V1)
			Mult_op_1A <= (SRAM_read_data[15:8] + SRAM_read_data[7:0]);
			Mult_op_2A <= 32'sd159;
			
			
			M1_state <= S_M1_LEADIN_7;
			
			end
			
			S_M1_LEADIN_7: begin
			
			//Load V values into V registers.
			RegisterV[2] <= SRAM_read_data[15:8];
			RegisterV[3] <= SRAM_read_data[7:0];
			
			//Load 159 * (V0 + V1) into V Accumulator.
			AccumulatorV <= AccumulatorV + Mult_resultA;
			
			//21 * (V0 + V3)
			Mult_op_1A <= (RegisterV[0] + SRAM_read_data[7:0]);
			Mult_op_2A <= 32'sd21;
			
			//52 * (V0 + V2)
			Mult_op_1B <= (RegisterV[0] + SRAM_read_data[15:8]);
			Mult_op_2B <= 32'sd52;
			
			
			M1_state <= S_M1_LEADIN_8;
			
			end
			
			S_M1_LEADIN_8: begin
			
			//Load 21 * (V0 + V3) and -52 * (V0 + V2) into V Accumulator.
			AccumulatorV <= AccumulatorV + Mult_resultA - Mult_resultB;
			
			//Load last V values into registers.
			RegisterV[4] <= SRAM_read_data[15:8];
			RegisterV[5] <= SRAM_read_data[7:0];
			
			M1_state <= S_M1_LEADIN_9;
			
			end
			
			S_M1_LEADIN_9: begin
			
			//Load V accumulator into odd V Prime register with non-clipping right bit shift.
			VPrime[1] <= {{8{AccumulatorV[31]}}, AccumulatorV[31:8]}; 
			
			//Load Y values into Y registers.
			RegisterY[0] <= SRAM_read_data[15:8];
			RegisterY[1] <= SRAM_read_data[7:0];
			
			//A00 * Ye
			
			Mult_op_1A <= (SRAM_read_data[15:8] - 32'd16);
			Mult_op_2A <= 32'sd76284;
			
			//A02 * Ve
			Mult_op_1B <= VPrime[0] - 32'd128;
			Mult_op_2B <= 32'sd104595;
		
			M1_state <= S_M1_LEADIN_10;
			
			end
			
			S_M1_LEADIN_10: begin
			
			//Load A00 * Ye into all even registers, and A02 * Ve into even red register.
			red[0] <= (Mult_resultA + Mult_resultB);
			blue[0] <= Mult_resultA;
			green[0] <= Mult_resultA;
			
			//Reset accumulators for next computation.
			AccumulatorV <= 32'd128;
			AccumulatorU <= 32'd128;
			
			//A11 * Ue
			Mult_op_1A <= UPrime[0] - 32'd128;
			Mult_op_2A <= 32'sd25624;
			
			//A12 * Ve
			Mult_op_1B <= VPrime[0] - 32'd128;
			Mult_op_2B <= 32'sd53281;
			
			M1_state <= S_M1_LEADIN_11;
			
			end
			
			S_M1_LEADIN_11: begin
			
			//Load A11 * Ue and A12 * Ve into even green. 
			green[0] <= (green[0] - Mult_resultA - Mult_resultB);
			
			//A21 * Ue
			Mult_op_1A <= UPrime[0] - 32'd128;
			Mult_op_2A <= 32'sd132251;

			
			M1_state <= S_M1_LEADIN_12;
			
			end
			
			S_M1_LEADIN_12: begin
			
			//Load A21 * Ye into even blue register.
			blue[0] <= (blue[0] + Mult_resultA);
			
			//Initiate a write at the appropriate RGB address for R0,G0
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			
			M1_SRAM_we_n <= 1'b0;
			M1_SRAM_write_data <= {(red[0][31]) ? 8'd0 : (red[0][30:24]) ? 8'd255 : red[0][23:16], (green[0][31]) ? 8'd0 : (green[0][30:24]) ? 8'd255 : green[0][23:16]};
			
			//A00 * Yo
			Mult_op_1A <= RegisterY[1] - 32'd16;
			Mult_op_2A <= 32'sd76284;
			
			//A02 * Vo
			Mult_op_1B <= VPrime[1] - 32'd128;
			Mult_op_2B <= 32'sd104595;
			
			
			M1_state <= S_M1_LEADIN_13;
			
			end
			
			S_M1_LEADIN_13: begin
			
			//Load odd RGB registers.
			red[1] <= (Mult_resultA + Mult_resultB);
			green[1] <= Mult_resultA;
			blue[1] <= Mult_resultA;
			
			//A11 * Uo
			Mult_op_1A <= UPrime[1] - 32'd128;
			Mult_op_2A <= 32'sd25624;
			
			//A12 * Vo
			Mult_op_1B <= VPrime[1] - 32'd128;
			Mult_op_2B <= 32'sd53281;
						
			M1_SRAM_we_n <= 1'b1;
			
			M1_state <= S_M1_LEADIN_14;
					
			end
			
			S_M1_LEADIN_14: begin
			
			//Load odd green register
			green[1] <= (green[1] - Mult_resultA - Mult_resultB);
			
			//Initiate a write for B0,R1
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			pixel_count <= pixel_count + 18'd1;
			
			
			M1_SRAM_write_data <= {(blue[0][31]) ? 8'd0 : (blue[0][30:24]) ? 8'd255 : blue[0][23:16], (red[1][31]) ? 8'd0 : (red[1][30:24]) ? 8'd255 : red[1][23:16]};
			M1_SRAM_we_n <= 1'b0;
			
			//A21 * Uo
			Mult_op_1A <= UPrime[1] - 32'd128;
			Mult_op_2A <= 32'sd132251;
			
			M1_state <= S_M1_LEADIN_15;
					
			end
			
			S_M1_LEADIN_15: begin
			
			//Load last multiplication for blue odd.
			blue[1] <= (blue[1] + Mult_resultA);
			
			//Begin upsampling for next pair of writes.
			//21 * (U0 + U4)
			Mult_op_1A <= (RegisterU[0] + RegisterU[4]);
			Mult_op_2A <= 32'sd21;
			
			//21 * (V0 + V4)
			Mult_op_1B <= (RegisterV[0] + RegisterV[4]);
			Mult_op_2B <= 32'sd21;
			
			M1_SRAM_we_n <= 1'b1;
			
			M1_state <= S_M1_LEADIN_15_interm;
					
			end
			
			S_M1_LEADIN_15_interm: begin
			
			//Write G1,B1
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			pixel_count <= pixel_count + 18'd1;
			
			M1_SRAM_write_data <= {(green[1][31]) ? 8'd0 : (green[1][30:24]) ? 8'd255 : green[1][23:16], (blue[1][31]) ? 8'd0 : (blue[1][30:24]) ? 8'd255 : blue[1][23:16]};
			M1_SRAM_we_n <= 1'b0;
			
			//Load U and V accumulators.
			AccumulatorU <= AccumulatorU + Mult_resultA;
			AccumulatorV <= AccumulatorV + Mult_resultB;
			
			//52 * (U0 + U3)
			Mult_op_1A <= RegisterU[0] + RegisterU[3];
			Mult_op_2A <= 32'sd52;
			
			//52 * (V0 + V3)
			Mult_op_1B <= RegisterV[0] + RegisterV[3];
			Mult_op_2B <= 32'sd52;
			
			M1_state <= S_M1_LEADIN_16;
			
			end
			
			S_M1_LEADIN_16: begin
			
			//Disable writes.
			M1_SRAM_we_n <= 1'b1;
			
			//Request a read for next Y values.
			M1_SRAM_address <= data_counterY;
			data_counterY <= data_counterY + 18'b1;

			//Accumulator U and V values.
			AccumulatorU <= AccumulatorU - Mult_resultA;
			AccumulatorV <= AccumulatorV - Mult_resultB;
					
			//159 * (U1 + U2)
			Mult_op_1A <= RegisterU[1] + RegisterU[2];
			Mult_op_2A <= 32'sd159;
			
			//159 * (V1 + V2)
			Mult_op_1B <= RegisterV[1] + RegisterV[2];
			Mult_op_2B <= 32'sd159;		
						
			M1_state <= S_M1_LEADIN_17;
			
					
			end
			
			S_M1_LEADIN_17: begin
			
			//Accumulate U and V values.
			AccumulatorU <= AccumulatorU + Mult_resultA;
			AccumulatorV <= AccumulatorV + Mult_resultB;
			
					
			M1_state <= S_M1_LEADIN_18;
					
			end
			
			S_M1_LEADIN_18: begin
			
			//Load U Prime values.
			UPrime[0] <= RegisterU[1];
			UPrime[1] <= {{8{AccumulatorU[31]}}, AccumulatorU[31:8]}; // >> 8
			VPrime[0] <= RegisterV[1];
			VPrime[1] <= {{8{AccumulatorV[31]}}, AccumulatorV[31:8]};
			
			
			M1_state <= S_M1_LEADIN_19;
			
			end
			
			S_M1_LEADIN_19: begin
			
			//Reset the Accumulators.
			AccumulatorV <= 32'd128;
			AccumulatorU <= 32'd128;
			
			RegisterY[0] = SRAM_read_data[15:8];
			RegisterY[1] = SRAM_read_data[7:0];
			
			//A00 * Ye
			Mult_op_1A <= SRAM_read_data[15:8] - 32'd16;
			Mult_op_2A <= 32'sd76284;
			
			//A02 * Ve
			Mult_op_1B <= VPrime[0] - 32'd128;
			Mult_op_2B <= 32'sd104595;
			
			
			M1_state <= S_M1_LEADIN_20;
			
			end
			
			S_M1_LEADIN_20: begin
			
			red[0] <= (Mult_resultA + Mult_resultB);
			blue[0] <= Mult_resultA;
			green[0] <= Mult_resultA;
			
			//A11 * Ue
			Mult_op_1A <= UPrime[0] - 32'd128;
			Mult_op_2A <= 32'sd25624;
			
			//A12 * Ve
			Mult_op_1B <= VPrime[0] - 32'd128;
			Mult_op_2B <= 32'sd53281;
						
			M1_state <= S_M1_LEADIN_21;
			
			end
			
			S_M1_LEADIN_21: begin
			
			green[0] <= (green[0] - Mult_resultA - Mult_resultB);
			
			//A21 * Ue
			Mult_op_1A <= UPrime[0] - 32'd128;
			Mult_op_2A <= 32'sd132251;
			
			
			M1_state <= S_M1_LEADIN_22;
			
			end
			
			S_M1_LEADIN_22: begin
			
			blue[0] <= (blue[0] + Mult_resultA);
			
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			
			M1_SRAM_write_data <= {(red[0][31]) ? 8'd0 : (red[0][30:24]) ? 8'd255 : red[0][23:16], (green[0][31]) ? 8'd0 : (green[0][30:24]) ? 8'd255 : green[0][23:16]};
			M1_SRAM_we_n <= 1'b0;
			
			//A00 * Yo
			Mult_op_1A <= RegisterY[1] - 32'd16;
			Mult_op_2A <= 32'sd76284;
			
			//A02 * Vo
			Mult_op_1B <= VPrime[1] - 32'd128;
			Mult_op_2B <= 32'sd104595;
			
			M1_state <= S_M1_LEADIN_23;
			
			end
			
			S_M1_LEADIN_23: begin
			
			red[1] <= (Mult_resultA + Mult_resultB);
			green[1] <= Mult_resultA;
			blue[1] <= Mult_resultA;
			
			//A11 * Uo
			Mult_op_1A <= UPrime[1] - 32'd128;
			Mult_op_2A <= 32'sd25624;
			
			//A12 * Vo
			Mult_op_1B <= VPrime[1] - 32'd128;
			Mult_op_2B <= 32'sd53281;
		
			M1_SRAM_we_n <= 1'b1;
			
			M1_state <= S_M1_LEADIN_24;
			
			end
			
			S_M1_LEADIN_24: begin
			
			green[1] <= (green[1] - Mult_resultA - Mult_resultB);
			
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			pixel_count <= pixel_count + 18'd1;
			
			M1_SRAM_write_data <= {(blue[0][31]) ? 8'd0 : (blue[0][30:24]) ? 8'd255 : blue[0][23:16], (red[1][31]) ? 8'd0 : (red[1][30:24]) ? 8'd255 : red[1][23:16]};
			M1_SRAM_we_n <= 1'b0;
			
			//A21 * Uo
			Mult_op_1A <= UPrime[1] - 32'd128;
			Mult_op_2A <= 32'sd132251;
			
			M1_state <= S_M1_LEADIN_25;
			
			end
			
			S_M1_LEADIN_25: begin
			
			//Initiate read for Y values to spill over into common case.
			M1_SRAM_address <= data_counterY;
			data_counterY <= data_counterY + 18'd1;
			
			blue[1] <= (blue[1] + Mult_resultA);
			
			M1_SRAM_we_n <= 1'b1;
			
			M1_state <= S_M1_LEADIN_26;
			
			end
			
			S_M1_LEADIN_26: begin
			
			
			//This is a buffer CC to ensure the Y values we read in LEADIN_25 arrive at the correct CC in the common case.
			
			M1_state <= S_M1_CC0;
			
			end
			
			S_M1_CC0: begin
			
			
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			
			//Write the values that spilled over from CC8
			
			/*
			if(green[1][31] == 32'd1) begin
				
				write[0] = 8'd0;
			
			end else if(green[1][30:24] != 8'd0) begin
			
				write[0] = 8'd255;
			
			end else begin
				
				write[0] = green[1][23:16];
				
			end
			*/
			
			M1_SRAM_write_data <= {(green[1][31]) ? 8'd0 : (green[1][30:24]) ? 8'd255 : green[1][23:16], (blue[1][31]) ? 8'd0 : (blue[1][30:24]) ? 8'd255 : blue[1][23:16]};
			M1_SRAM_we_n <= 1'b0;
			pixel_count <= pixel_count + 18'd1;
			
			//Multiplier 1
			Mult_op_1A <= RegisterU[0] + RegisterU[5];
			Mult_op_2A <= 32'sd21;
			
			
			//Mulitplier 2
			Mult_op_1B <= RegisterV[0] + RegisterV[5];
			Mult_op_2B <= 32'sd21;
			
			//Reset accumulators for next computation.
			AccumulatorV <= 32'd0;
			AccumulatorU <= 32'd0;
			
		
			UPrime[0] <= RegisterU[2];
			VPrime[0] <= RegisterV[2];
			
			M1_state <= S_M1_CC2;
			
			end
			
			S_M1_CC1: begin
			
			M1_SRAM_we_n <= 1'b1;
			
			M1_SRAM_address <= V_offset + data_counterV;
			//We only increase data counters every other iteration of common case (when we read odd U/V values)
			
			//Multiplier 1
			Mult_op_1A <= RegisterU[1] + RegisterU[4];
			Mult_op_2A <= 32'sd52;
			
			AccumulatorU <= Mult_resultA;
			
			
			//Mulitplier 2
			Mult_op_1B <= RegisterV[1] + RegisterV[4];
			Mult_op_2B <= 32'sd52;
			
			AccumulatorV <= Mult_resultB;
			
			RegisterY[0] <= SRAM_read_data[15:8];
			RegisterY[1] <= SRAM_read_data[7:0];
			
			M1_state <= S_M1_CC2;
			
			end
			
			S_M1_CC2: begin
			
			M1_SRAM_address <= U_offset + data_counterU;
			//We only increase data counters every other iteration of common case (when we read odd U/V values)
			
			Mult_op_1A <= RegisterU[2] + RegisterU[3];
			Mult_op_2A <= 32'sd159;
			
			AccumulatorU <= AccumulatorU - Mult_resultA;
			
			//Mulitplier 2
			Mult_op_1B <= RegisterV[2] + RegisterV[3];
			Mult_op_2B <= 32'sd159;
			
			AccumulatorV <= AccumulatorV - Mult_resultB;
			
			M1_state <= S_M1_CC3;
			
			end

			S_M1_CC3: begin
			
			Mult_op_1A <= RegisterY[0] - 32'd16; //A00*Yeven
			Mult_op_2A <= 32'sd76284;
			
			Mult_op_1B <= VPrime[0] - 32'd128; //A02*Veven
			Mult_op_2B <= 32'sd104595;
			
			AccumulatorU <= (AccumulatorU + Mult_resultA + 32'd128); //U'odd
			AccumulatorV <= (AccumulatorV + Mult_resultB + 32'd128); //V'odd			
			
			
			M1_state <= S_M1_CC4;
			
			end
			
			
			S_M1_CC4: begin
			
			temp_counter <= temp_counter + 18'd1;
			
			if(M1_read_odd_even == 1'b1) begin
				RegisterV[0] <= RegisterV[1];
				RegisterV[1] <= RegisterV[2];
				RegisterV[2] <= RegisterV[3];
				RegisterV[3] <= RegisterV[4];
				RegisterV[4] <= RegisterV[5];
				RegisterV[5] <= SRAM_read_data[7:0]; //Vodd (V9)
				
				//We increment U/V counters here because we just read an odd value. Now we jump to the next write pair.
				data_counterV <= data_counterV + 18'd1;
				
			end else begin
				RegisterV[0] <= RegisterV[1];
				RegisterV[1] <= RegisterV[2];
				RegisterV[2] <= RegisterV[3];
				RegisterV[3] <= RegisterV[4];
				RegisterV[4] <= RegisterV[5];
				RegisterV[5] <= SRAM_read_data[15:8]; //Veven(V8)
				
			end
			
			Mult_op_1A <= UPrime[0] - 32'd128; //A11*Ueven
			Mult_op_2A <= 32'sd25624;
			
			Mult_op_1B <= VPrime[0] - 32'd128; //A12*Veven
			Mult_op_2B <= 32'sd53281;
			
			UPrime[1] <= {{8{AccumulatorU[31]}}, AccumulatorU[31:8]}; //U'odd
			VPrime[1] <= {{8{AccumulatorV[31]}}, AccumulatorV[31:8]}; //V'odd
			
			
			red[0] <= (Mult_resultA + Mult_resultB); //Full Computation for Reven
			green[0] <= Mult_resultA; 
			blue[0] <=  Mult_resultA;
			
			M1_state <= S_M1_CC5;
			
			end		
			
			S_M1_CC5: begin
			
			if(M1_read_odd_even == 1'b1) begin
				RegisterU[0] <= RegisterU[1];
				RegisterU[1] <= RegisterU[2];
				RegisterU[2] <= RegisterU[3];
				RegisterU[3] <= RegisterU[4];
				RegisterU[4] <= RegisterU[5];
				RegisterU[5] <= SRAM_read_data[7:0]; //U9, Uodd
				
				//We increment U/V counters here because we just read an odd value. Now we jump to the next U/V pair.
				data_counterU <= data_counterU + 18'd1;
				
			end else begin
			
				RegisterU[0] <= RegisterU[1];
				RegisterU[1] <= RegisterU[2];
				RegisterU[2] <= RegisterU[3];
				RegisterU[3] <= RegisterU[4];
				RegisterU[4] <= RegisterU[5];
				RegisterU[5] <= SRAM_read_data[15:8]; //U8, Ueven
				
			end
 
			
			Mult_op_1A <= UPrime[0] - 32'd128; //A21*Ueven
			Mult_op_2A <= 32'sd132251;
			
			Mult_op_1B <= RegisterY[1] - 32'd16; //A00*Yodd
			Mult_op_2B <= 32'sd76284;
			
			green[0] <= (green[0] - Mult_resultA - Mult_resultB); //Full Computation for Geven
		
			
			M1_state <= S_M1_CC6;
			
			end			
			
			
			S_M1_CC6: begin
			
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			
			M1_SRAM_write_data <= {(red[0][31]) ? 8'd0 : (red[0][30:24]) ? 8'd255 : red[0][23:16], (green[0][31]) ? 8'd0 : (green[0][30:24]) ? 8'd255 : green[0][23:16]};
			M1_SRAM_we_n <= 1'b0;
			
			Mult_op_1A <= VPrime[1] - 32'd128; //A02*Vodd
			Mult_op_2A <= 32'sd104595;
			
			Mult_op_1B <= UPrime[1] - 32'd128; //A11*uodd
			Mult_op_2B <= 32'sd25624;
			
			red[1] <= Mult_resultB; 
			green[1] <= Mult_resultB; 
			blue[0] <= (blue[0] + Mult_resultA); //Full Computation for Beven
			blue[1] <= Mult_resultB;
			
			
			M1_state <= S_M1_CC7;
			
			end			
			
			
			
			S_M1_CC7: begin
			
			Mult_op_1A <= VPrime[1] - 32'd128; //A12*Vodd
			Mult_op_2A <= 32'sd53281;
			
			Mult_op_1B <= UPrime[1] - 32'd128; //A21*uodd
			Mult_op_2B <= 32'sd132251;
			
			red[1] <= (red[1] + Mult_resultA); //Full Computation for Rodd
			green[1] <= green[1] - Mult_resultB;
			
			M1_SRAM_we_n <= 1'b1;
			
			//Initiate read for spill over Y value.
			M1_SRAM_address <= data_counterY;
			data_counterY <= data_counterY + 18'd1;
			
			M1_state <= S_M1_CC8;
			
			
			end			
			
			
			S_M1_CC8: begin
			
			
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			
			M1_SRAM_we_n <= 1'b0;
			M1_SRAM_write_data <= {(blue[0][31]) ? 8'd0 : (blue[0][30:24]) ? 8'd255 : blue[0][23:16], (red[1][31]) ? 8'd0 : (red[1][30:24]) ? 8'd255 : red[1][23:16]};
			pixel_count <= pixel_count + 18'd1;
			
			//The writes for these values spill over to CC0.
			green[1] <= (green[1] - Mult_resultA); //Full Computation for Godd
			blue[1] <= (blue[1] + Mult_resultB); //Full Computation for Bodd
			
			M1_read_odd_even <= ~M1_read_odd_even;
			
			//CC starts with writes 4/5, ends with writes 312/313. Therefore, the common case will be run exactly 154 times before getting to the end of the row.
			//At this point we switch out of the common case loop and into the lead out.
			if(CC_counter == 16'd154) begin
				
				M1_state <= S_M1_LEADOUT_0;
			   CC_counter <= 16'd0;	
			
			end else begin
			
				M1_state <= S_M1_CC0;
				CC_counter <= CC_counter + 16'd1;
				
			end
			
			end
			
			S_M1_LEADOUT_0: begin
			
			//Write the values that spilled over from CC8
			
			M1_SRAM_address <= RGB_offset + write_count;
			M1_SRAM_write_data <= {(green[1][31]) ? 8'd0 : (green[1][30:24]) ? 8'd255 : green[1][23:16], (blue[1][31]) ? 8'd0 : (blue[1][30:24]) ? 8'd255 : blue[1][23:16]};
			M1_SRAM_we_n <= 1'b0;
			pixel_count <= pixel_count + 18'd1;
			write_count <= write_count + 18'd1;
			
			AccumulatorU <= 32'd128;
			AccumulatorV <= 32'd128;
			
			
			M1_state <= S_M1_LEADOUT_1;
			
			end
			
			
			S_M1_LEADOUT_1: begin
			
			M1_SRAM_we_n <= 1'b1;
			
			RegisterY[0] <= SRAM_read_data[15:8];
			RegisterY[1] <= SRAM_read_data[7:0];
			
			//21 * (U0 + U4)
			Mult_op_1A <= (RegisterU[0] + RegisterU[4]);
			Mult_op_2A <= 32'sd21;
			
			//21 * (V0 + V4)
			Mult_op_1B <= (RegisterV[0] + RegisterV[4]);
			Mult_op_2B <= 32'sd21;
			
			M1_state <= S_M1_LEADOUT_2;
			
			end
			
			S_M1_LEADOUT_2: begin
			
			//Load U and V accumulators.
			AccumulatorU <= AccumulatorU + Mult_resultA;
			AccumulatorV <= AccumulatorV + Mult_resultB;
			
			//52 * (U1 + U4)
			Mult_op_1A <= RegisterU[1] + RegisterU[4];
			Mult_op_2A <= 32'sd52;
			
			//52 * (V1 + V4)
			Mult_op_1B <= RegisterV[1] + RegisterV[4];
			Mult_op_2B <= 32'sd52;
			
			M1_state <= S_M1_LEADOUT_3;
			
			
			end
			
			S_M1_LEADOUT_3: begin
			
			
			//Accumulator U and V values.
			AccumulatorU <= AccumulatorU - Mult_resultA;
			AccumulatorV <= AccumulatorV - Mult_resultB;
					
			//159 * (U2 + U4)
			Mult_op_1A <= RegisterU[2] + RegisterU[3];
			Mult_op_2A <= 32'sd159;
			
			//159 * (V2 + V4)
			Mult_op_1B <= RegisterV[2] + RegisterV[3];
			Mult_op_2B <= 32'sd159;		
			
			M1_state <= S_M1_LEADOUT_4;
			
			end
			
			S_M1_LEADOUT_4: begin
			
			
			//Accumulate U and V values.
			AccumulatorU <= AccumulatorU + Mult_resultA;
			AccumulatorV <= AccumulatorV + Mult_resultB;
						
			M1_state <= S_M1_LEADOUT_5;
			
			
			end
			
			S_M1_LEADOUT_5: begin
			
			//Load U Prime values.
			UPrime[0] <= RegisterU[2];
			UPrime[1] <= {{8{AccumulatorU[31]}}, AccumulatorU[31:8]};
			VPrime[0] <= RegisterV[2];
			VPrime[1] <= {{8{AccumulatorV[31]}}, AccumulatorV[31:8]};
			
			M1_state <= S_M1_LEADOUT_6;		
			
			end
			
			S_M1_LEADOUT_6: begin
			
			//Reset the Accumulators.
			AccumulatorV <= 32'd128;
			AccumulatorU <= 32'd128;
			
			//A00 * Ye
			Mult_op_1A <= RegisterY[0] - 32'd16;
			Mult_op_2A <= 32'sd76284;
			
			//A02 * Ve
			Mult_op_1B <= VPrime[0] - 32'd128;
			Mult_op_2B <= 32'sd104595;
			
			
			M1_state <= S_M1_LEADOUT_7;
			
			end
			
			S_M1_LEADOUT_7: begin
			
			red[0] <= (Mult_resultA + Mult_resultB);
			blue[0] <= Mult_resultA;
			green[0] <= Mult_resultA;
			
			//A11 * Ue
			Mult_op_1A <= UPrime[0] - 32'd128;
			Mult_op_2A <= 32'sd25624;
			
			//A12 * Ve
			Mult_op_1B <= VPrime[0] - 32'd128;
			Mult_op_2B <= 32'sd53281;
			
			
			M1_state <= S_M1_LEADOUT_8;
			
			end
			
			S_M1_LEADOUT_8: begin
			
			green[0] <= (green[0] - Mult_resultA - Mult_resultB);
			
			//A21 * Ue
			Mult_op_1A <= UPrime[0] - 32'd128;
			Mult_op_2A <= 32'sd132251;
			
			M1_state <= S_M1_LEADOUT_9;
			
			end
			
			S_M1_LEADOUT_9: begin
			
			blue[0] <= (blue[0] + Mult_resultA);
			
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			
			M1_SRAM_write_data <= {(red[0][31]) ? 8'd0 : (red[0][30:24]) ? 8'd255 : red[0][23:16], (green[0][31]) ? 8'd0 : (green[0][30:24]) ? 8'd255 : green[0][23:16]};
			M1_SRAM_we_n <= 1'b0;
			
			//A00 * Yo
			Mult_op_1A <= RegisterY[1] - 32'd16;
			Mult_op_2A <= 32'sd76284;
			
			//A02 * Vo
			Mult_op_1B <= VPrime[1] - 32'd128;
			Mult_op_2B <= 32'sd104595;
		
			M1_state <= S_M1_LEADOUT_10;
			
			end
			
			S_M1_LEADOUT_10: begin
			
			red[1] <= (Mult_resultA + Mult_resultB);
			green[1] <= Mult_resultA;
			blue[1] <= Mult_resultA;
			
			//A11 * Uo
			Mult_op_1A <= UPrime[1] - 32'd128;
			Mult_op_2A <= 32'sd25624;
			
			//A12 * Vo
			Mult_op_1B <= VPrime[1] - 32'd128;
			Mult_op_2B <= 32'sd53281;
		
			M1_SRAM_we_n <= 1'b1;
			
			M1_state <= S_M1_LEADOUT_11;
			
			end
			
			S_M1_LEADOUT_11: begin
			
			green[1] <= (green[1] - Mult_resultA - Mult_resultB);
			
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			pixel_count <= pixel_count + 18'd1;
			
			M1_SRAM_write_data <= {(blue[0][31]) ? 8'd0 : (blue[0][30:24]) ? 8'd255 : blue[0][23:16], (red[1][31]) ? 8'd0 : (red[1][30:24]) ? 8'd255 : red[1][23:16]};
			M1_SRAM_we_n <= 1'b0;
			
			//A21 * Uo
			Mult_op_1A <= UPrime[1] - 32'd128;
			Mult_op_2A <= 32'sd132251;

			
			M1_state <= S_M1_LEADOUT_12;
			
			end
			
			S_M1_LEADOUT_12: begin
			
			blue[1] <= (blue[1] + Mult_resultA);
			M1_SRAM_we_n <= 1'b1;
			
			M1_state <= S_M1_LEADOUT_13;
			
			end
			
			S_M1_LEADOUT_13: begin
			
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			
			M1_SRAM_write_data <= {(green[1][31]) ? 8'd0 : (green[1][30:24]) ? 8'd255 : green[1][23:16], (blue[1][31]) ? 8'd0 : (blue[1][30:24]) ? 8'd255 : blue[1][23:16]};
			M1_SRAM_we_n <= 1'b0;
			pixel_count <= pixel_count + 18'd1;
			
			M1_state <= S_M1_LEADOUT_14;
					
			end
			
			S_M1_LEADOUT_14: begin
			
			//Initiate reads for Y values.
			M1_SRAM_address <= data_counterY;
			data_counterY <= data_counterY + 18'd1;
			
			M1_SRAM_we_n <= 1'b1;
			
			M1_state <= S_M1_LEADOUT_15;
			
			end
			
			S_M1_LEADOUT_15: begin
			
			//21 * (U1 + U4)
			Mult_op_1A <= (RegisterU[1] + RegisterU[4]);
			Mult_op_2A <= 32'sd21;
			
			//21 * (V1 + V4)
			Mult_op_1B <= (RegisterV[1] + RegisterV[4]);
			Mult_op_2B <= 32'sd21;
			
			M1_state <= S_M1_LEADOUT_16;
			
			end
			
			S_M1_LEADOUT_16: begin
			
			//Load U and V accumulators.
			AccumulatorU <= AccumulatorU + Mult_resultA;
			AccumulatorV <= AccumulatorV + Mult_resultB;
			
			//52 * (U2 + U4)
			Mult_op_1A <= RegisterU[2] + RegisterU[4];
			Mult_op_2A <= 32'sd52;
			
			//52 * (V2 + V4)
			Mult_op_1B <= RegisterV[2] + RegisterV[4];
			Mult_op_2B <= 32'sd52;
			
			M1_state <= S_M1_LEADOUT_17;
			
			
			end
			
			S_M1_LEADOUT_17: begin
			
			RegisterY[0] <= SRAM_read_data[15:8];
			RegisterY[1] <= SRAM_read_data[7:0];
			
			//Accumulator U and V values.
			AccumulatorU <= AccumulatorU - Mult_resultA;
			AccumulatorV <= AccumulatorV - Mult_resultB;
					
			//159 * (U3 + U4)
			Mult_op_1A <= RegisterU[3] + RegisterU[4];
			Mult_op_2A <= 32'sd159;
			
			//159 * (V3 + V4)
			Mult_op_1B <= RegisterV[3] + RegisterV[4];
			Mult_op_2B <= 32'sd159;		
			
			M1_state <= S_M1_LEADOUT_18;
			
			end
			
			S_M1_LEADOUT_18: begin
			
			//Accumulate U and V values.
			AccumulatorU <= AccumulatorU + Mult_resultA;
			AccumulatorV <= AccumulatorV + Mult_resultB;
						
			M1_state <= S_M1_LEADOUT_19;
			
			
			end
			
			S_M1_LEADOUT_19: begin
			
			//Load U Prime values.
			UPrime[0] <= RegisterU[3];
			UPrime[1] <= {{8{AccumulatorU[31]}}, AccumulatorU[31:8]};
			VPrime[0] <= RegisterV[3];
			VPrime[1] <= {{8{AccumulatorV[31]}}, AccumulatorV[31:8]};
			
			M1_state <= S_M1_LEADOUT_20;		
			
			end
			
			S_M1_LEADOUT_20: begin
			
			//Reset the Accumulators.
			AccumulatorV <= 32'd128;
			AccumulatorU <= 32'd128;
			
			//A00 * Ye
			Mult_op_1A <= RegisterY[0] - 32'd16;
			Mult_op_2A <= 32'sd76284;
			
			//A02 * Ve
			Mult_op_1B <= VPrime[0] - 32'd128;
			Mult_op_2B <= 32'sd104595;
			
			
			M1_state <= S_M1_LEADOUT_21;
			
			end
			
			S_M1_LEADOUT_21: begin
			
			red[0] <= (Mult_resultA + Mult_resultB);
			blue[0] <= Mult_resultA;
			green[0] <= Mult_resultA;
			
			//A11 * Ue
			Mult_op_1A <= UPrime[0] - 32'd128;
			Mult_op_2A <= 32'sd25624;
			
			//A12 * Ve
			Mult_op_1B <= VPrime[0] - 32'd128;
			Mult_op_2B <= 32'sd53281;
			
			
			M1_state <= S_M1_LEADOUT_22;
			
			end
			
			S_M1_LEADOUT_22: begin
			
			green[0] <= (green[0] - Mult_resultA - Mult_resultB);
			
			//A21 * Ue
			Mult_op_1A <= UPrime[0] - 32'd128;
			Mult_op_2A <= 32'sd132251;
			
			M1_state <= S_M1_LEADOUT_23;
			
			end
			
			S_M1_LEADOUT_23: begin
			
			blue[0] <= (blue[0] + Mult_resultA);
			
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			
			M1_SRAM_write_data <= {(red[0][31]) ? 8'd0 : (red[0][30:24]) ? 8'd255 : red[0][23:16], (green[0][31]) ? 8'd0 : (green[0][30:24]) ? 8'd255 : green[0][23:16]};
			M1_SRAM_we_n <= 1'b0;
			
			//A00 * Yo
			Mult_op_1A <= RegisterY[1] - 32'd16;
			Mult_op_2A <= 32'sd76284;
			
			//A02 * Vo
			Mult_op_1B <= VPrime[1] - 32'd128;
			Mult_op_2B <= 32'sd104595;
		
			M1_state <= S_M1_LEADOUT_24;
			
			end
			
			S_M1_LEADOUT_24: begin
			
			red[1] <= (Mult_resultA + Mult_resultB);
			green[1] <= Mult_resultA;
			blue[1] <= Mult_resultA;
			
			//A11 * Uo
			Mult_op_1A <= UPrime[1] - 32'd128;
			Mult_op_2A <= 32'sd25624;
			
			//A12 * Vo
			Mult_op_1B <= VPrime[1] - 32'd128;
			Mult_op_2B <= 32'sd53281;
		
			M1_SRAM_we_n <= 1'b1;
			
			M1_state <= S_M1_LEADOUT_25;
			
			end
			
			S_M1_LEADOUT_25: begin
			
			green[1] <= (green[1] - Mult_resultA - Mult_resultB);
			
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			
			M1_SRAM_write_data <= {(blue[0][31]) ? 8'd0 : (blue[0][30:24]) ? 8'd255 : blue[0][23:16], (red[1][31]) ? 8'd0 : (red[1][30:24]) ? 8'd255 : red[1][23:16]};
			M1_SRAM_we_n <= 1'b0;
			pixel_count <= pixel_count + 18'd1;
			
			//A21 * Uo
			Mult_op_1A <= UPrime[1] - 32'd128;
			Mult_op_2A <= 32'sd132251;

			
			M1_state <= S_M1_LEADOUT_26;
			
			end
			
			S_M1_LEADOUT_26: begin
			
			blue[1] <= (blue[1] + Mult_resultA);
			M1_SRAM_we_n <= 1'b1;
			
			M1_state <= S_M1_LEADOUT_27;
			
			end
			
			S_M1_LEADOUT_27: begin
			
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			
			M1_SRAM_write_data <= {(green[1][31]) ? 8'd0 : (green[1][30:24]) ? 8'd255 : green[1][23:16], (blue[1][31]) ? 8'd0 : (blue[1][30:24]) ? 8'd255 : blue[1][23:16]};
			M1_SRAM_we_n <= 1'b0;
			pixel_count <= pixel_count + 18'd1;
			
			M1_state <= S_M1_LEADOUT_28;
					
			end
			
			S_M1_LEADOUT_28: begin
			
			//Initiate reads for Y values.
			M1_SRAM_address <= data_counterY;
			data_counterY <= data_counterY + 18'd1;
			
			M1_SRAM_we_n <= 1'b1;
			
			M1_state <= S_M1_LEADOUT_29;
			
			end
			
			S_M1_LEADOUT_29: begin
			
			//21 * (U2 + U4)
			Mult_op_1A <= (RegisterU[2] + RegisterU[4]);
			Mult_op_2A <= 32'sd21;
			
			//21 * (V2 + V4)
			Mult_op_1B <= (RegisterV[2] + RegisterV[4]);
			Mult_op_2B <= 32'sd21;
			
			M1_state <= S_M1_LEADOUT_30;
			
			end
			
			S_M1_LEADOUT_30: begin
			
			//Load U and V accumulators.
			AccumulatorU <= AccumulatorU + Mult_resultA;
			AccumulatorV <= AccumulatorV + Mult_resultB;
			
			//52 * (U3 + U4)
			Mult_op_1A <= RegisterU[3] + RegisterU[4];
			Mult_op_2A <= 32'sd52;
			
			//52 * (V3 + V4)
			Mult_op_1B <= RegisterV[3] + RegisterV[4];
			Mult_op_2B <= 32'sd52;
			
			M1_state <= S_M1_LEADOUT_31;
			
			
			end
			
			S_M1_LEADOUT_31: begin
			
			RegisterY[0] <= SRAM_read_data[15:8];
			RegisterY[1] <= SRAM_read_data[7:0];
			
			//Accumulator U and V values.
			AccumulatorU <= AccumulatorU - Mult_resultA;
			AccumulatorV <= AccumulatorV - Mult_resultB;
					
			//159 * (U4 + U4)
			Mult_op_1A <= RegisterU[4] + RegisterU[4];
			Mult_op_2A <= 32'sd159;
			
			//159 * (V4 + V4)
			Mult_op_1B <= RegisterV[4] + RegisterV[4];
			Mult_op_2B <= 32'sd159;		
			
			M1_state <= S_M1_LEADOUT_32;
			
			end
			
			S_M1_LEADOUT_32: begin
			
			//Accumulate U and V values.
			AccumulatorU <= AccumulatorU + Mult_resultA;
			AccumulatorV <= AccumulatorV + Mult_resultB;
						
			M1_state <= S_M1_LEADOUT_33;
			
			
			end
			
			S_M1_LEADOUT_33: begin
			
			//Load U Prime values.
			UPrime[0] <= RegisterU[4];
			UPrime[1] <= {{8{AccumulatorU[31]}}, AccumulatorU[31:8]};
			VPrime[0] <= RegisterV[4];
			VPrime[1] <= {{8{AccumulatorV[31]}}, AccumulatorV[31:8]};
			
			M1_state <= S_M1_LEADOUT_34;		
			
			end
			
			S_M1_LEADOUT_34: begin
			
			//Reset the Accumulators.
			AccumulatorV <= 32'd128;
			AccumulatorU <= 32'd128;
			
			//A00 * Ye
			Mult_op_1A <= RegisterY[0] - 32'd16;
			Mult_op_2A <= 32'sd76284;
			
			//A02 * Ve
			Mult_op_1B <= VPrime[0] - 32'd128;
			Mult_op_2B <= 32'sd104595;
			
			
			M1_state <= S_M1_LEADOUT_35;
			
			end
			
			S_M1_LEADOUT_35: begin
			
			red[0] <= (Mult_resultA + Mult_resultB);
			blue[0] <= Mult_resultA;
			green[0] <= Mult_resultA;
			
			//A11 * Ue
			Mult_op_1A <= UPrime[0] - 32'd128;
			Mult_op_2A <= 32'sd25624;
			
			//A12 * Ve
			Mult_op_1B <= VPrime[0] - 32'd128;
			Mult_op_2B <= 32'sd53281;
			
			
			M1_state <= S_M1_LEADOUT_36;
			
			end
			
			S_M1_LEADOUT_36: begin
			
			green[0] <= (green[0] - Mult_resultA - Mult_resultB);
			
			//A21 * Ue
			Mult_op_1A <= UPrime[0] - 32'd128;
			Mult_op_2A <= 32'sd132251;
			
			M1_state <= S_M1_LEADOUT_37;
			
			end
			
			S_M1_LEADOUT_37: begin
			
			blue[0] <= (blue[0] + Mult_resultA);
			
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			
			M1_SRAM_write_data <= {(red[0][31]) ? 8'd0 : (red[0][30:24]) ? 8'd255 : red[0][23:16], (green[0][31]) ? 8'd0 : (green[0][30:24]) ? 8'd255 : green[0][23:16]};
			M1_SRAM_we_n <= 1'b0;
			
			//A00 * Yo
			Mult_op_1A <= RegisterY[1] - 32'd16;
			Mult_op_2A <= 32'sd76284;
			
			//A02 * Vo
			Mult_op_1B <= VPrime[1] - 32'd128;
			Mult_op_2B <= 32'sd104595;
		
			M1_state <= S_M1_LEADOUT_38;
			
			end
			
			S_M1_LEADOUT_38: begin
			
			red[1] <= (Mult_resultA + Mult_resultB);
			green[1] <= Mult_resultA;
			blue[1] <= Mult_resultA;
			
			//A11 * Uo
			Mult_op_1A <= UPrime[1] - 32'd128;
			Mult_op_2A <= 32'sd25624;
			
			//A12 * Vo
			Mult_op_1B <= VPrime[1] - 32'd128;
			Mult_op_2B <= 32'sd53281;
		
			M1_SRAM_we_n <= 1'b1;
			
			M1_state <= S_M1_LEADOUT_39;
			
			end
			
			S_M1_LEADOUT_39: begin
			
			green[1] <= (green[1] - Mult_resultA - Mult_resultB);
			
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			
			M1_SRAM_write_data <= {(blue[0][31]) ? 8'd0 : (blue[0][30:24]) ? 8'd255 : blue[0][23:16], (red[1][31]) ? 8'd0 : (red[1][30:24]) ? 8'd255 : red[1][23:16]};
			M1_SRAM_we_n <= 1'b0;
			pixel_count <= pixel_count + 18'd1;
			
			//A21 * Uo
			Mult_op_1A <= UPrime[1] - 32'd128;
			Mult_op_2A <= 32'sd132251;

			
			M1_state <= S_M1_LEADOUT_40;
			
			end
			
			S_M1_LEADOUT_40: begin
			
			blue[1] <= (blue[1] + Mult_resultA);
			M1_SRAM_we_n <= 1'b1;
			
			M1_state <= S_M1_LEADOUT_41;
			
			end
			
			S_M1_LEADOUT_41: begin
			
			M1_SRAM_address <= RGB_offset + write_count;
			write_count <= write_count + 18'd1;
			
			M1_SRAM_write_data <= {(green[1][31]) ? 8'd0 : (green[1][30:24]) ? 8'd255 : green[1][23:16], (blue[1][31]) ? 8'd0 : (blue[1][30:24]) ? 8'd255 : blue[1][23:16]};
			M1_SRAM_we_n <= 1'b0;
			pixel_count <= pixel_count + 18'd1;
			
			M1_state <= S_M1_LEADOUT_42;
					
			end
			
			S_M1_LEADOUT_42: begin
			
			M1_SRAM_we_n <= 1'b1;
			M1_read_odd_even <= 1'b0;
			
			//We keep going back to lead in states until we have completed all RGB writes
			if(write_count < 115200) begin
			
				M1_state <= S_M1_LEADIN_0;
				row_counter <= row_counter + 16'd1;
			
			end else begin
			
				M1_state <= S_M1_IDLE;
				top_state <= S_IDLE;
			
			end
			
			end
			
			default: M1_state <= S_M1_IDLE;
			
			endcase
		
		end
		
		S_M2: begin
		
			case(M2_state)
				
			M2_IDLE: begin
			
			if(M2_start == 1'd1) begin
				address1[0] <= 9'd0;
				address1[1] <= 9'd0;
				address2[0] <= 9'd0;
				address2[1] <= 9'd0;
				address3[0] <= 9'd0;
				address3[1] <= 9'd0;
				Dram2_last_add <= 9'd0;
				Dram3_last_add <= 9'd0;
				
				c_index_0 <= 6'd0;
				c_index_1 <= 6'd0;
				c_index_2 <= 6'd0;
				
				
				T_flag <= 1'd0;
				i <= 5'd0;
				j <= 5'd0;

				write_enable_1[0] <= 1'd0;
				write_enable_1[1] <= 1'd0;
				write_enable_2[0] <= 1'd0;
				write_enable_2[1] <= 1'd0;
				write_enable_3[0] <= 1'd0;
				write_enable_3[1] <= 1'd0;
				
				Accumulator0 <= 32'd0;
				Accumulator1 <= 32'd0;
				Accumulator2 <= 32'd0;
				
				row_address <= 32'd320;
				col_address <= 32'd8;
				
				C_counter <= 32'd0;
				
				row_counter <= 16'd0;
				
				M2_SRAM_we_n <= 1'd1;
				M2_SRAM_write_data <= 16'b0;
				
				write_count <= 18'd0;
				M2_start <= 1'd0;
				temp_counter <= 18'd0;
				
				Ybuffer <= 16'd0;
				cycle_counter <= 6'd0;
			
				M2_state <= M2_FETCH_0;
			end
			
			end
			
			M2_FETCH_0: begin
			
			M2_SRAM_address <= preIDCT_offsetY + write_count + i;
			//write_count <= write_count + 18'd1;
			
			i <= i + 5'd1;
			
			M2_state <= M2_FETCH_1;
			
			end
			
			M2_FETCH_1: begin
			
			M2_SRAM_address <= preIDCT_offsetY + write_count + i;
			//write_count <= write_count + 18'd1;
			
			i <= i + 5'd1;
			
			M2_state <= M2_FETCH_2;
			
			end
			
			M2_FETCH_2: begin
		
			write_enable_1[0] <= 1'd1;
			
			M2_SRAM_address <= preIDCT_offsetY + write_count + i;
			//write_count <= write_count + 18'd1;

			i <= i + 5'd1;
			
			M2_state <= M2_FETCH_3;
			
			end
			
			M2_FETCH_3: begin
			
			//write_enable_1[0] <= 1'd1;
			
			M2_SRAM_address <= preIDCT_offsetY + write_count + i;
			//write_count <= write_count + 18'd1;
			
			address1[0] <= address1[0] +9'd1; 
			
			i <= i + 5'd1;
			
			if(write_count > 2240) begin
				
				// dram 1
				write_enable_1[0] <= 1'd0;
				write_enable_1[1] <= 1'd0;
				
				k <= 9'd0;
				address1[1] <= 9'd0;
				j <= 5'd0;
				
				M2_state <= M2_COMPUTE_T_1;
				
			end else
			
			if(i > 5'd7) begin
					
					i <= 5'd0;
					
					write_count <= write_count + 18'd320;
							
					M2_state <= M2_FETCH_3;
			
			
			end else begin
			
			M2_state <= M2_FETCH_3;
			
			end

			end
			
	
			M2_COMPUTE_T_1: begin
			
			//if(j != 0) begin
			
			write_enable_1[0] <= 1'd0;
			write_enable_1[1] <= 1'd0;
			
			Mult_op_1A <= C0;
			Mult_op_2A <= read_data_1[1];
			
			Mult_op_1B <= C1;
			Mult_op_2B <= read_data_1[1];
			
			Mult_op_1C <= C2;
			Mult_op_2C <= read_data_1[1];
			
			if(j > 1) begin
				Accumulator0 <= Accumulator0 + Mult_resultA;
				Accumulator1 <= Accumulator1 + Mult_resultB;
				Accumulator2 <= Accumulator2 + Mult_resultC;
				
			end
			
			address1[1] <= address1[1] + 9'd1;
			
			c_index_0 <= (k);
			c_index_1 <= (k + 10'd1);
			c_index_2 <= (k + 10'd2);
			
			
			if(k > 64) begin

			i <= 3'd0;
			k <= 9'd3;
			
			M2_state <= M2_COMPUTE_T_1write; 
			
			end else begin
			
			k <= k + 9'd8;
			i <= i + 3'd1;
			j <= j + 5'd1;
			
			write_enable_2[0] <= 1'd0;
			write_enable_2[1] <= 1'd0;
			write_enable_3[0] <= 1'd0;
			write_enable_3[1] <= 1'd0;

			M2_state <= M2_COMPUTE_T_1;
			
			end
			
			end
			
			M2_COMPUTE_T_1write: begin
			
			write_enable_2[0] <= 1'd1; // Teven top port to write
			write_enable_2[1] <= 1'd1;// Teven bot port to write
			
			
			write_enable_3[0] <= 1'd1; // Todd top port to write
			write_enable_3[1] <= 1'd0;// Todd bot port set to read.
			
			
			//D2 addressing
			Dram2_last_add <=Dram2_last_add + 9'd2;
			Dram3_last_add <=Dram3_last_add + 9'd1;
			
			
			address2[0] <= Dram2_last_add; 
			address2[1] <= Dram2_last_add + 9'd1;
			
			address3[0] <= Dram3_last_add;
			
			//{{8{AccumulatorU[31]}}, AccumulatorU[31:8]};
			
			write_data_2[0] <= {{8{Accumulator0[31]}}, Accumulator0[31:8]};
			write_data_2[1] <= {{8{Accumulator2[31]}}, Accumulator2[31:8]};
			write_data_3[0] <= {{8{Accumulator1[31]}}, Accumulator2[31:8]};
			
			address1[1] <= row_counter;
			Accumulator0 <= 32'd0;
			Accumulator1 <= 32'd0;
			Accumulator2 <= 32'd0;
			j <= 5'd0;
			
			M2_state <= M2_COMPUTE_T_2;
			
			end
			
			M2_COMPUTE_T_2: begin
						
			Mult_op_1A <= C0;
			Mult_op_2A <= read_data_1[1];
			
			Mult_op_1B <= C1;
			Mult_op_2B <= read_data_1[1];
			
			Mult_op_1C <= C2;
			Mult_op_2C <= read_data_1[1];
			
			if(j > 1) begin
				Accumulator0 <= Accumulator0 + Mult_resultA;
				Accumulator1 <= Accumulator1 + Mult_resultB;
				Accumulator2 <= Accumulator2 + Mult_resultC;
			end
			

			address1[1] <= address1[1] + 9'd1; // reading from top part (we are writing to location 64-127 T even
			
			c_index_0 <= (k);
			c_index_1 <= (k + 10'd1);
			c_index_2 <= (k + 10'd2);
			
			
			if(k > 10'd67) begin
			
			i <= 5'd0;
			k <= 10'd6;
			
			M2_state <= M2_COMPUTE_T_2write; 
			
			end else begin
			
			k <= k + 9'd8;
			i <= i + 3'd1;
			j <= j + 5'd1;
			
			write_enable_2[0] <= 1'd0;
			write_enable_2[1] <= 1'd0;
			write_enable_3[0] <= 1'd0;
			write_enable_3[1] <= 1'd0;
			
			M2_state <= M2_COMPUTE_T_2;
			
			end
			
			end
			
			M2_COMPUTE_T_2write: begin
			
			write_enable_2[0] <= 1'd1; // Teven top port to write
			write_enable_2[1] <= 1'd0; // Teven bot port to write
			
			write_enable_3[0] <= 1'd1; // Todd top port to write
			write_enable_3[1] <= 1'd1;// Todd bot port set to read.
			
			//D2 addressing
			Dram2_last_add <=Dram2_last_add +9'd1;
			Dram3_last_add <=Dram3_last_add +9'd2;
				
				
			//D3 addressing
			address3[0] <= Dram3_last_add; 
			address3[1] <= Dram3_last_add + 9'd1;
			
			address2[0] <= Dram2_last_add;
			
			address1[1] <= row_counter;
			write_data_2[0] <= {{8{Accumulator1[31]}}, Accumulator1[31:8]};
			write_data_3[0] <= {{8{Accumulator0[31]}}, Accumulator0[31:8]};
			write_data_3[1] <= {{8{Accumulator2[31]}}, Accumulator2[31:8]};
			
			Accumulator0 <= 32'd0;
			Accumulator1 <= 32'd0;
			Accumulator2 <= 32'd0;
			
			M2_state <= M2_COMPUTE_T_3;
			j <= 5'd0;
			
			end
				
			M2_COMPUTE_T_3: begin
			
			Mult_op_1A <= C0;
			Mult_op_2A <= read_data_1[1];
			
			Mult_op_1B <= C1;
			Mult_op_2B <= read_data_1[1];
			
			if(j > 1) begin
				Accumulator0 <= Accumulator0 + Mult_resultA;
				Accumulator1 <= Accumulator1 + Mult_resultB;
				//Accumulator2 <= Accumulator2 + Mult_resultC;
			end
			

			address1[1] <= address1[1] + 9'd1; // reading from top part (we are writing to location 64-127 T even)
		

			
			c_index_0 <= (k);
			c_index_1 <= (k + 9'd1);
			//c_index_2 <= (k + 9'd2);
			
			
			if(k > 10'd70) begin
			
			i <= 5'd0;
			k <= 10'd6;
			
			M2_state <= M2_COMPUTE_T_3write; 
			
			end else begin
			
			k <= k + 9'd8;
			i <= i + 3'd1;
			j <= j + 5'd1;
			
			write_enable_2[0] <= 1'd0;
			write_enable_2[1] <= 1'd0;
			write_enable_3[0] <= 1'd0;
			write_enable_3[1] <= 1'd0;
			
			M2_state <= M2_COMPUTE_T_3;
			
			end
			
			end
			
			M2_COMPUTE_T_3write: begin
			
			write_enable_2[0] <= 1'd1; // Teven top port to write
			write_enable_2[1] <= 1'd0;// Teven bot port to write
			
			
			write_enable_3[0] <= 1'd1; // Todd top port to write
			write_enable_3[1] <= 1'd0;// Todd bot port set to read.
			
			//D2 addressing
			Dram2_last_add <=Dram2_last_add +9'd1;
			Dram3_last_add <=Dram3_last_add +9'd1;
				
				
			//D3 addressing
			address3[0] <= Dram3_last_add;
			address2[0] <= Dram2_last_add;
			
			write_data_2[0] <= {{8{Accumulator0[31]}}, Accumulator0[31:8]};
			write_data_3[0] <= {{8{Accumulator1[31]}}, Accumulator1[31:8]};
			
			
			if(row_counter >= 16'd56) begin
			
			Accumulator0 <= 32'd0;
			Accumulator1 <= 32'd0;
			Accumulator2 <= 32'd0;
			
			row_counter <= 16'd0;
			i <= 5'd0;
			k <= 10'd0;
			j <= 5'd0;
			
			M2_state <= M2_MEGASTATE_A;
			
			end else begin
			
			row_counter <= row_counter + 16'd8;
			
			j <= 5'd0;
			k <= 10'd0;
			i <= 3'd0;
			
			Accumulator0 <= 32'd0;
			Accumulator1 <= 32'd0;
			Accumulator2 <= 32'd0;
			
			address1[0] <= row_counter + 16'd8;
			
			M2_state <= M2_COMPUTE_T_1;
			
			end
			
			//M2_state <= M2_IDLE; 
			
			end
			
			M2_MEGASTATE_A: begin
			
			address3[1] <= 9'd0;
			address2[1] <= 9'd0;
			
			write_enable_1[0] <= 1'd0;
			write_enable_1[1] <= 1'd0;
			
			
			write_enable_2[0] <= 1'd0;
			write_enable_2[1] <= 1'd0;
			write_enable_3[0] <= 1'd0;
			write_enable_3[1] <= 1'd0;
			
			address1[1] <= 9'd63;
			address1[0] <= 9'd0;
			write_count <= 19'd0;
			
			col_address <= 32'd8;
			row_address <= 32'd0;
			
			i <= 5'd0;
			
			T_flag <= 1'b1;
			
			M2_state <= M2_COMPUTE_S_1;
			
			end
			
			M2_COMPUTE_S_1: begin
			
			M2_SRAM_address <= preIDCT_offsetY + row_address + col_address + i;	
			
			write_enable_1[1] <= 1'd0;
			
			if(j > 1) begin
				
				Accumulator0 <= Accumulator0 + Mult_resultA;
				Accumulator1 <= Accumulator1 + Mult_resultB;
				Accumulator2 <= Accumulator2 + Mult_resultC;
				
			end
			
			if(j > 0) begin
			
				if(T_flag) begin
				
				address3[1] <= address3[1] + 9'd1;
				
				Mult_op_1A <= C0;
				Mult_op_2A <= read_data_3[1];
				
				Mult_op_1B <= C1;
				Mult_op_2B <= read_data_3[1];
				
				Mult_op_1C <= C2;
				Mult_op_2C <= read_data_3[1];
				
				
				end else begin
				
				address2[1] <= address2[1] + 9'd1;
				
				Mult_op_1A <= C0;
				Mult_op_2A <= read_data_2[1];
				
				Mult_op_1B <= C1;
				Mult_op_2B <= read_data_2[1];
				
				Mult_op_1C <= C2;
				Mult_op_2C <= read_data_2[1];
				
				end
			end
			
	
			
			c_index_0 <= (k);
			c_index_1 <= (k + 10'd8);
			c_index_2 <= (k + 10'd16);
			
			
			if(k > 10'd8) begin

			k <= 10'd24;
			
			i <= 5'd0;	
			
		
			row_address <= row_address + 32'd320;
			C_counter <= C_counter + 32'd1;
			
						
			M2_state <= M2_COMPUTE_S_1write; 
			
			end else begin
			
			T_flag <= ~T_flag;
			
			k <= k + 9'd1;
			i <= i + 5'd1;
			j <= j + 5'd1;
			
			write_enable_2[0] <= 1'd0;
			write_enable_2[1] <= 1'd0;
			write_enable_3[0] <= 1'd0;
			write_enable_3[1] <= 1'd0;

			M2_state <= M2_COMPUTE_S_1;
			
			end
			
			end
			
			M2_COMPUTE_S_1write: begin
						
			write_enable_1[1] <= 1'd1; // Teven top port to write
			write_enable_1[0] <= 1'd0;
			address1[1] <= address1[1] + 9'd1;
			
			write_data_1[1] <= {(Accumulator0[31]) ? 8'd0 : (Accumulator0[30:24]) ? 8'd255 : Accumulator0[23:16], (Accumulator1[31]) ? 8'd0 : (Accumulator1[30:24]) ? 8'd255 : Accumulator1[23:16], (Accumulator2[31]) ? 8'd0 : (Accumulator2[30:24]) ? 8'd255 : Accumulator2[23:16], 8'd0};
			
			address2[1] <= row_counter;
			address3[1] <= row_counter;
			
			Accumulator0 <= 32'd0;
			Accumulator1 <= 32'd0;
			Accumulator2 <= 32'd0;
			j <= 5'd0;
			
			T_flag <= 1'b1;
			
			M2_state <= M2_COMPUTE_S_2;
			
			end
			
			M2_COMPUTE_S_2: begin
			
			write_enable_1[1] <= 1'd0;
			
			if(j > 0) begin
			
				if(T_flag) begin
				
				address3[1] <= address3[1] + 9'd1;
				
				Mult_op_1A <= C0;
				Mult_op_2A <= read_data_3[1];
				
				Mult_op_1B <= C1;
				Mult_op_2B <= read_data_3[1];
				
				Mult_op_1C <= C2;
				Mult_op_2C <= read_data_3[1];
				
				
				end else begin
				
				address2[1] <= address2[1] + 9'd1;
				
				Mult_op_1A <= C0;
				Mult_op_2A <= read_data_2[1];
				
				Mult_op_1B <= C1;
				Mult_op_2B <= read_data_2[1];
				
				Mult_op_1C <= C2;
				Mult_op_2C <= read_data_2[1];
				
				end
				
			end
			
			if(j > 1) begin
				Accumulator0 <= Accumulator0 + Mult_resultA;
				Accumulator1 <= Accumulator1 + Mult_resultB;
				Accumulator2 <= Accumulator2 + Mult_resultC;
			end
	
			
			c_index_0 <= (k);
			c_index_1 <= (k + 9'd8);
			c_index_2 <= (k + 9'd16);
			
			
			if(k > 10'd32) begin
			
			i <= 5'd0;
			k <= 10'd48;
			
			M2_state <= M2_COMPUTE_S_2write; 
			
			end else begin
			
			k <= k + 9'd1;
			i <= i + 3'd1;
			j <= j + 5'd1;
			
			write_enable_2[0] <= 1'd0;
			write_enable_2[1] <= 1'd0;
			write_enable_3[0] <= 1'd0;
			write_enable_3[1] <= 1'd0;
			
			T_flag <= ~T_flag;
			
			M2_state <= M2_COMPUTE_S_2;
			
			end
			
			end
			
			M2_COMPUTE_S_2write: begin
			
			write_enable_1[1] <= 1'b1;
			address1[1] <= address1[1] + 9'd1;
			write_data_1[1] <= {(Accumulator0[31]) ? 8'd0 : (Accumulator0[30:24]) ? 8'd255 : Accumulator0[23:16], (Accumulator1[31]) ? 8'd0 : (Accumulator1[30:24]) ? 8'd255 : Accumulator1[23:16], (Accumulator2[31]) ? 8'd0 : (Accumulator2[30:24]) ? 8'd255 : Accumulator2[23:16], 8'd0};
			
			address3[1] <= row_counter;
			address2[1] <= row_counter;
			
			Accumulator0 <= 32'd0;
			Accumulator1 <= 32'd0;
			Accumulator2 <= 32'd0;
			
			T_flag <= 1'b1;
			
			M2_state <= M2_COMPUTE_S_3;
			j <= 5'd0;
			
			end
				
			M2_COMPUTE_S_3: begin
			
			write_enable_1[1] <= 1'b0;
			
			if(j > 0) begin
				if(T_flag) begin
				
				address3[1] <= address3[1] + 9'd1;
				
				Mult_op_1A <= C0;
				Mult_op_2A <= read_data_3[1];
				
				Mult_op_1B <= C1;
				Mult_op_2B <= read_data_3[1];
				
				
				end else begin
				
				address2[1] <= address2[1] + 9'd1;
				
				Mult_op_1A <= C0;
				Mult_op_2A <= read_data_2[1];
				
				Mult_op_1B <= C1;
				Mult_op_2B <= read_data_2[1];
				
				end
			end
			
			if(j > 1) begin
				Accumulator0 <= Accumulator0 + Mult_resultA;
				Accumulator1 <= Accumulator1 + Mult_resultB;
				//Accumulator2 <= Accumulator2 + Mult_resultC;
			end
			

			
			c_index_0 <= (k);
			c_index_1 <= (k + 9'd8);
			//c_index_2 <= (k + 9'd2);
			
			
			if(k > 10'd56) begin
			
			i <= 3'd0;
			k <= 9'd0;
			
			M2_state <= M2_COMPUTE_S_3write; 
			
			end else begin
			
			k <= k + 9'd1;
			i <= i + 3'd1;
			j <= j + 5'd1;
			
			T_flag <= ~T_flag;
			
			write_enable_2[0] <= 1'd0;
			write_enable_2[1] <= 1'd0;
			write_enable_3[0] <= 1'd0;
			write_enable_3[1] <= 1'd0;
			
			M2_state <= M2_COMPUTE_S_3;
			
			end
			
			end
			
			M2_COMPUTE_S_3write: begin
				
			write_enable_1[1] <= 1'b1;
			address1[1] <= address1[1] + 1'd1;

			write_data_1[1] <= {(Accumulator0[31]) ? 8'd0 : (Accumulator0[30:24]) ? 8'd255 : Accumulator0[23:16], (Accumulator1[31]) ? 8'd0 : (Accumulator1[30:24]) ? 8'd255 : Accumulator1[23:16], 8'd0, 8'd0};
			
			//REMEMBER EVERY 3 VALUES IN S ONLY HAVE 2 PACKED Y VALUES.

			if(row_counter >= 16'd28) begin
			
			M2_state <= M2_MEGASTATE_B;
			
			end else begin
			
			row_counter <= row_counter + 16'd4;
			
			j <= 5'd0;
			k <= 10'd0;
			i <= 3'd0;
			Accumulator0 <= 32'd0;
			Accumulator1 <= 32'd0;
			Accumulator2 <= 32'd0;
			
			T_flag <= 1'b1;
			
			address2[1] <= row_counter + 16'd4;
			address3[1] <= row_counter + 16'd4;
			
			//row_address <= row_address + 8'd320;
			
			M2_state <= M2_COMPUTE_S_1;
			
			end
			
			//M2_state <= M2_IDLE; 
			
			end	
			
			M2_MEGASTATE_B: begin
			
			write_enable_1[0] <= 1'b0;
			write_enable_1[1] <= 1'b0;
			write_enable_2[0] <= 1'b0;
			write_enable_2[1] <= 1'b0;
			write_enable_3[0] <= 1'b0;
			write_enable_3[1] <= 1'b0;
			
			Accumulator0 <= 32'd0;
			Accumulator1 <= 32'd0;
			Accumulator2 <= 32'd0;
			
			i <= 5'd0;
			j <= 5'd0;
			C_counter <= 32'd0;
			
			address1[0] <= 9'd63;
			address1[1] <= 9'd0;
			address2[0] <= 9'd0;
			address2[1] <= 9'd0;
			address3[0] <= 9'd0;
			address3[1] <= 9'd0;
			
			Dram2_last_add <= 9'd0;
			Dram3_last_add <= 9'd0;
			
			M2_SRAM_address <= 18'd0;
			
			
			
			M2_state <= M2_COMPUTE_T_1b;
			
			end
			
			M2_COMPUTE_T_1b: begin
			
			//if(j != 0) begin
			
			write_enable_2[0] <= 1'd0;
			write_enable_2[1] <= 1'd0;
			write_enable_3[0] <= 1'd0;
			write_enable_3[1] <= 1'd0;
			
			if(C_counter > 7) begin
				
				M2_SRAM_we_n <= 1'b1;
			
			end else begin
			
				case(cycle_counter)
				
				0 : begin
				
				M2_SRAM_write_data <= {read_data_1[0][31:24], read_data_1[0][23:16]};
				M2_SRAM_address <= SRAM_address + 18'd1;
				M2_SRAM_we_n <= 1'b0;
				
				Ybuffer <= {read_data_1[0][15:8]};
				
				address1[0] <= address1[0] + 9'd1;
				
				cycle_counter <= 6'd1;
				
				end
				
				
				1 : begin
			
				M2_SRAM_write_data <= {Ybuffer, read_data_1[0][31:24]};
				M2_SRAM_address <= SRAM_address + 18'd1;
				
				Ybuffer <= {read_data_1[0][23:16], read_data_1[0][15:8]};
				
				cycle_counter <= 6'd2;
				
				end
				
				2 : begin
			
				M2_SRAM_write_data <= {Ybuffer};
				M2_SRAM_address <= SRAM_address + 18'd1;
				
				address1[0] <= address1[0] + 9'd1;
				
				
				cycle_counter <= 6'd3;
				

				end
				
				3 : begin
				
				M2_SRAM_write_data <= {read_data_1[0][31:24], read_data_1[0][23:16]};
				M2_SRAM_address <= SRAM_address + 18'd1;
				
				address1[0] <= address1[0] + 9'd1;
				
				C_counter <= C_counter + 32'd1;
				
				cycle_counter <= 6'd0;
				
				end
				
				endcase
				
			end
			
			write_enable_1[0] <= 1'd0;
			write_enable_1[1] <= 1'd0;
			
			Mult_op_1A <= C0;
			Mult_op_2A <= read_data_1[1];
			
			Mult_op_1B <= C1;
			Mult_op_2B <= read_data_1[1];
			
			Mult_op_1C <= C2;
			Mult_op_2C <= read_data_1[1];
			
			if(j > 1) begin
				Accumulator0 <= Accumulator0 + Mult_resultA;
				Accumulator1 <= Accumulator1 + Mult_resultB;
				Accumulator2 <= Accumulator2 + Mult_resultC;
				
			end
			
			address1[1] <= address1[1] + 9'd1;
			
			c_index_0 <= (k);
			c_index_1 <= (k + 9'd1);
			c_index_2 <= (k + 9'd2);
			
			
			if(k > 10'd64) begin

			i <= 3'd0;
			k <= 10'd3;
			M2_SRAM_we_n <= 1'b1;
			
			M2_state <= M2_COMPUTE_T_1writeb; 
			
			end else begin
			
			k <= k + 9'd8;
			i <= i + 3'd1;
			j <= j + 5'd1;
			
			write_enable_2[0] <= 1'd0;
			write_enable_2[1] <= 1'd0;
			write_enable_3[0] <= 1'd0;
			write_enable_3[1] <= 1'd0;

			M2_state <= M2_COMPUTE_T_1b;
			
			end
			
			end
			
			M2_COMPUTE_T_1writeb: begin
			
			write_enable_2[0] <= 1'd1; // Teven top port to write
			write_enable_2[1] <= 1'd1;// Teven bot port to write
			
			
			write_enable_3[0] <= 1'd1; // Todd top port to write
			write_enable_3[1] <= 1'd0;// Todd bot port set to read.
			
			
			//D2 addressing
			Dram2_last_add <=Dram2_last_add + 9'd2;
			Dram3_last_add <=Dram3_last_add + 9'd1;
			
			
			address2[0] <= Dram2_last_add; 
			address2[1] <= Dram2_last_add + 9'd1;
			
			address3[0] <= Dram3_last_add;
			
			//{{8{AccumulatorU[31]}}, AccumulatorU[31:8]};
			
			write_data_2[0] <= {{8{Accumulator0[31]}}, Accumulator0[31:8]};
			write_data_2[1] <= {{8{Accumulator2[31]}}, Accumulator2[31:8]};
			write_data_3[0] <= {{8{Accumulator1[31]}}, Accumulator1[31:8]};
			
			address1[1] <= row_counter;
			Accumulator0 <= 32'd0;
			Accumulator1 <= 32'd0;
			Accumulator2 <= 32'd0;
			j <= 5'd0;
			
			M2_state <= M2_COMPUTE_T_2b;
			
			end
			
			M2_COMPUTE_T_2b: begin
			
			write_enable_2[0] <= 1'd0;
			write_enable_2[1] <= 1'd0;
			write_enable_3[0] <= 1'd0;
			write_enable_3[1] <= 1'd0;
			
			
			
			Mult_op_1A <= C0;
			Mult_op_2A <= read_data_1[1];
			
			Mult_op_1B <= C1;
			Mult_op_2B <= read_data_1[1];
			
			Mult_op_1C <= C2;
			Mult_op_2C <= read_data_1[1];
			
			if(j > 1) begin
				Accumulator0 <= Accumulator0 + Mult_resultA;
				Accumulator1 <= Accumulator1 + Mult_resultB;
				Accumulator2 <= Accumulator2 + Mult_resultC;
			end
			

			address1[1] <= address1[1] + 9'd1; 
	
			
			c_index_0 <= (k);
			c_index_1 <= (k + 10'd1);
			c_index_2 <= (k + 10'd2);
			
			
			if(k > 10'd67) begin
			
			i <= 5'd0;
			k <= 10'd6;
			
			M2_state <= M2_COMPUTE_T_2writeb; 
			
			end else begin
			
			k <= k + 9'd8;
			i <= i + 3'd1;
			j <= j + 5'd1;
			
			write_enable_2[0] <= 1'd0;
			write_enable_2[1] <= 1'd0;
			write_enable_3[0] <= 1'd0;
			write_enable_3[1] <= 1'd0;
			
			M2_state <= M2_COMPUTE_T_2b;
			
			end
			
			end
			
			M2_COMPUTE_T_2writeb: begin
			
			write_enable_2[0] <= 1'd1; // Teven top port to write
			write_enable_2[1] <= 1'd0; // Teven bot port to write
			
			write_enable_3[0] <= 1'd1; // Todd top port to write
			write_enable_3[1] <= 1'd1;// Todd bot port set to read.
			
			//D2 addressing
			Dram2_last_add <=Dram2_last_add +9'd1;
			Dram3_last_add <=Dram3_last_add +9'd2;
				
				
			//D3 addressing
			address3[0] <= Dram3_last_add; 
			address3[1] <= Dram3_last_add + 9'd1;
			
			address2[0] <= Dram2_last_add;
			
			address1[1] <= row_counter;
			write_data_2[0] <= {{8{Accumulator1[31]}}, Accumulator1[31:8]};
			write_data_3[0] <= {{8{Accumulator0[31]}}, Accumulator0[31:8]};
			write_data_3[1] <= {{8{Accumulator2[31]}}, Accumulator2[31:8]};
			
			Accumulator0 <= 32'd0;
			Accumulator1 <= 32'd0;
			Accumulator2 <= 32'd0;
			
			M2_state <= M2_COMPUTE_T_3b;
			j <= 5'd0;
			
			end
				
			M2_COMPUTE_T_3b: begin
			
			write_enable_2[0] <= 1'd0;
			write_enable_2[1] <= 1'd0;
			write_enable_3[0] <= 1'd0;
			write_enable_3[1] <= 1'd0;
			
			Mult_op_1A <= C0;
			Mult_op_2A <= read_data_1[1];
			
			Mult_op_1B <= C1;
			Mult_op_2B <= read_data_1[1];
			
			if(j > 1) begin
				Accumulator0 <= Accumulator0 + Mult_resultA;
				Accumulator1 <= Accumulator1 + Mult_resultB;
				//Accumulator2 <= Accumulator2 + Mult_resultC;
			end
			

			address1[1] <= address1[1] + 9'd1; // reading from top part (we are writing to location 64-127 T even)
		

			
			c_index_0 <= (k);
			c_index_1 <= (k + 9'd1);
			//c_index_2 <= (k + 9'd2);
			
			
			if(k > 10'd70) begin
			
			i <= 5'd0;
			k <= 10'd6;
			
			M2_state <= M2_COMPUTE_T_3writeb; 
			
			end else begin
			
			k <= k + 9'd8;
			i <= i + 3'd1;
			j <= j + 5'd1;
			
			write_enable_2[0] <= 1'd0;
			write_enable_2[1] <= 1'd0;
			write_enable_3[0] <= 1'd0;
			write_enable_3[1] <= 1'd0;
			
			M2_state <= M2_COMPUTE_T_3b;
			
			end
			
			end
			
			M2_COMPUTE_T_3writeb: begin
			
			write_enable_2[0] <= 1'd1; // Teven top port to write
			write_enable_2[1] <= 1'd0;// Teven bot port to write
			
			
			write_enable_3[0] <= 1'd1; // Todd top port to write
			write_enable_3[1] <= 1'd0;// Todd bot port set to read.
			
			//D2 addressing
			Dram2_last_add <= Dram2_last_add +9'd1;
			Dram3_last_add <= Dram3_last_add +9'd1;
				
				
			//D3 addressing
			address3[0] <= Dram3_last_add;
			address2[0] <= Dram2_last_add;
			
			write_data_2[0] <= {{8{Accumulator0[31]}}, Accumulator0[31:8]};
			write_data_3[0] <= {{8{Accumulator1[31]}}, Accumulator1[31:8]};
			
			
			if(row_counter >= 16'd56) begin
			
			Accumulator0 <= 32'd0;
			Accumulator1 <= 32'd0;
			Accumulator2 <= 32'd0;
			
			row_counter <= 16'd0;
			i <= 5'd0;
			k <= 10'd0;
			j <= 5'd0;
			
			M2_state <= M2_IDLE;
			
			end else begin
			
			row_counter <= row_counter + 16'd8;
			
			j <= 5'd0;
			k <= 10'd0;
			i <= 3'd0;
			
			Accumulator0 <= 32'd0;
			Accumulator1 <= 32'd0;
			Accumulator2 <= 32'd0;
			
			address1[0] <= row_counter + 16'd8;
			
			M2_state <= M2_COMPUTE_T_1b;
			
			end
			
			//M2_state <= M2_IDLE; 
			
			end
			
			
			default: M2_state <= M2_IDLE;
		
			endcase
		
		end
		
		
		default: top_state <= S_IDLE;

		endcase
	end
end

// for this design we assume that the RGB data starts at location 0 in the external SRAM
// if the memory layout is different, this value should be adjusted 
// to match the starting address of the raw RGB data segment
assign VGA_base_address = 18'd146944; //Do i have to change for M1?

// Give access to SRAM for UART and VGA at appropriate time
assign SRAM_address = (top_state == S_UART_RX) ? UART_SRAM_address : (top_state == S_M1) ? M1_SRAM_address : (top_state == S_M2) ? M2_SRAM_address : VGA_SRAM_address;

assign SRAM_write_data = (top_state == S_UART_RX) ? UART_SRAM_write_data : (top_state == S_M1) ? M1_SRAM_write_data : (top_state == S_M2) ? M2_SRAM_write_data : 16'd0;

assign SRAM_we_n = (top_state == S_UART_RX) ? UART_SRAM_we_n : (top_state == S_M1) ? M1_SRAM_we_n : (top_state == S_M2) ? M2_SRAM_we_n : 1'b1;

//Milestone 2 assign
assign write_data_1[0] = {{16{SRAM_read_data[15]}},SRAM_read_data[15:0]}; //DO SIGN EXTENSION AND CHANGE WRITE DATA TO 32 BITS.
//assign write_data_1[0] = SRAM_read_data;


always_comb begin
	case(c_index_0)
	0:   C0 = 32'sd1448;   //C00
	1:   C0 = 32'sd1448;   //C01
	2:   C0 = 32'sd1448;   //C02
	3:   C0 = 32'sd1448;   //C03
	4:   C0 = 32'sd1448;   //C04
	5:   C0 = 32'sd1448;   //C05
	6:   C0 = 32'sd1448;   //C06
	7:   C0 = 32'sd1448;   //C07
	8:   C0 = 32'sd2008;   //C20
	9:   C0 = 32'sd1702;   //C21
	10:  C0 = 32'sd1137;   //C22
	11:  C0 = 32'sd399;    //C23
	12:  C0 = -32'sd399;   //C24
	13:  C0 = -32'sd1137;  //C25
	14:  C0 = -32'sd1702;  //C26
	15:  C0 = -32'sd2008;  //C27
	16:  C0 = 32'sd1892;   //C20
	17:  C0 = 32'sd783;    //C21
	18:  C0 = -32'sd783;   //C22
	19:  C0 = -32'sd1892;  //C23
	20:  C0 = -32'sd1892;  //C24
	21:  C0 = -32'sd783;   //C25
	22:  C0 = 32'sd783;    //C26
	23:  C0 = 32'sd1892;   //C27
	24:  C0 = 32'sd1702;   //C30
	25:  C0 = -32'sd399;   //C31
	26:  C0 = -32'sd2008;  //C32
	27:  C0 = -32'sd1137;  //C33
	28:  C0 = 32'sd1137;   //C34
	29:  C0 = 32'sd2008;   //C35
	30:  C0 = 32'sd399;    //C36
	31:  C0 = -32'sd1702;  //C37
	32:  C0 = 32'sd1448;   //C40
	33:  C0 = -32'sd1448;  //C41
	34:  C0 = -32'sd1448;  //C42
	35:  C0 = 32'sd1448;   //C43
	36:  C0 = 32'sd1448;   //C44
	37:  C0 = -32'sd1448;  //C45
	38:  C0 = -32'sd1448;  //C46
	39:  C0 = 32'sd1448;   //C47
	40:  C0 = 32'sd1137;   //C50
	41:  C0 = -32'sd2008;  //C51
	42:  C0 = 32'sd399;    //C52
	43:  C0 = 32'sd1702;   //C53
	44:  C0 = -32'sd1702;  //C54
	45:  C0 = -32'sd399;   //C55
	46:  C0 = 32'sd2008;   //C56
	47:  C0 = -32'sd1137;  //C57
	48:  C0 = 32'sd783;    //C60
	49:  C0 = -32'sd1892;  //C61
	50:  C0 = 32'sd1892;   //C62
	51:  C0 = -32'sd783;   //C63
	52:  C0 = -32'sd783;   //C64
	53:  C0 = 32'sd1892;   //C65
	54:  C0 = -32'sd1892;  //C66
	55:  C0 = 32'sd783;    //C67
	56:  C0 = 32'sd399;    //C70
    57:  C0 = -32'sd1137;  //C71
    58:  C0 = 32'sd1702;   //C72
    59:  C0 = -32'sd2008;  //C73
    60:  C0 = 32'sd2008;   //C74
    61:  C0 = -32'sd1702;  //C75
    62:  C0 = 32'sd1137;   //C76
    63:  C0 = -32'sd399;   //C77
	endcase
end
always_comb begin
	case(c_index_1)
	0:   C1 = 32'sd1448;
	1:   C1 = 32'sd1448;
	2:   C1 = 32'sd1448;
	3:   C1 = 32'sd1448;
	4:   C1 = 32'sd1448;
	5:   C1 = 32'sd1448;
	6:   C1 = 32'sd1448;
	7:   C1 = 32'sd1448;
	8:   C1 = 32'sd2008;
	9:   C1 = 32'sd1702;
	10:  C1 = 32'sd1137;
	11:  C1 = 32'sd399;
	12:  C1 = -32'sd399;
	13:  C1 = -32'sd1137;
	14:  C1 = -32'sd1702;
	15:  C1 = -32'sd2008;
	16:  C1 = 32'sd1892;
	17:  C1 = 32'sd783;
	18:  C1 = -32'sd783;
	19:  C1 = -32'sd1892;
	20:  C1 = -32'sd1892;
	21:  C1 = -32'sd783;
	22:  C1 = 32'sd783;
	23:  C1 = 32'sd1892;
	24:  C1 = 32'sd1702;
	25:  C1 = -32'sd399;
	26:  C1 = -32'sd2008;
	27:  C1 = -32'sd1137;
	28:  C1 = 32'sd1137;
	29:  C1 = 32'sd2008;
	30:  C1 = 32'sd399;
	31:  C1 = -32'sd1702;
	32:  C1 = 32'sd1448;
	33:  C1 = -32'sd1448;
	34:  C1 = -32'sd1448;
	35:  C1 = 32'sd1448;
	36:  C1 = 32'sd1448;
	37:  C1 = -32'sd1448;
	38:  C1 = -32'sd1448;
	39:  C1 = 32'sd1448;
	40:  C1 = 32'sd1137;
	41:  C1 = -32'sd2008;
	42:  C1 = 32'sd399;
	43:  C1 = 32'sd1702;
	44:  C1 = -32'sd1702;
	45:  C1 = -32'sd399;
	46:  C1 = 32'sd2008;
	47:  C1 = -32'sd1137;
	48:  C1 = 32'sd783;
	49:  C1 = -32'sd1892;
	50:  C1 = 32'sd1892;
	51:  C1 = -32'sd783;
	52:  C1 = -32'sd783;
	53:  C1 = 32'sd1892;
	54:  C1 = -32'sd1892;
	55:  C1 = 32'sd783;
	56:  C1 = 32'sd399;
    57:  C1 = -32'sd1137;
    58:  C1 = 32'sd1702;
    59:  C1 = -32'sd2008;
    60:  C1 = 32'sd2008;
    61:  C1 = -32'sd1702;
    62:  C1 = 32'sd1137;
    63:  C1 = -32'sd399;
	endcase	
end



always_comb begin
	case(c_index_2)
	0:   C2 = 32'sd1448;
	1:   C2 = 32'sd1448;
	2:   C2 = 32'sd1448;
	3:   C2 = 32'sd1448;
	4:   C2 = 32'sd1448;
	5:   C2 = 32'sd1448;
	6:   C2 = 32'sd1448;
	7:   C2 = 32'sd1448;
	8:   C2 = 32'sd2008;
	9:   C2 = 32'sd1702;
	10:  C2 = 32'sd1137;
	11:  C2 = 32'sd399;
	12:  C2 = -32'sd399;
	13:  C2 = -32'sd1137;
	14:  C2 = -32'sd1702;
	15:  C2 = -32'sd2008;
	16:  C2 = 32'sd1892;
	17:  C2 = 32'sd783;
	18:  C2 = -32'sd783;
	19:  C2 = -32'sd1892;
	20:  C2 = -32'sd1892;
	21:  C2 = -32'sd783;
	22:  C2 = 32'sd783;
	23:  C2 = 32'sd1892;
	24:  C2 = 32'sd1702;
	25:  C2 = -32'sd399;
	26:  C2 = -32'sd2008;
	27:  C2 = -32'sd1137;
	28:  C2 = 32'sd1137;
	29:  C2 = 32'sd2008;
	30:  C2 = 32'sd399;
	31:  C2 = -32'sd1702;
	32:  C2 = 32'sd1448;
	33:  C2 = -32'sd1448;
	34:  C2 = -32'sd1448;
	35:  C2 = 32'sd1448;
	36:  C2 = 32'sd1448;
	37:  C2 = -32'sd1448;
	38:  C2 = -32'sd1448;
	39:  C2 = 32'sd1448;
	40:  C2 = 32'sd1137;
	41:  C2 = -32'sd2008;
	42:  C2 = 32'sd399;
	43:  C2 = 32'sd1702;
	44:  C2 = -32'sd1702;
	45:  C2 = -32'sd399;
	46:  C2 = 32'sd2008;
	47:  C2 = -32'sd1137;
	48:  C2 = 32'sd783;
	49:  C2 = -32'sd1892;
	50:  C2 = 32'sd1892;
	51:  C2 = -32'sd783;
	52:  C2 = -32'sd783;
	53:  C2 = 32'sd1892;
	54:  C2 = -32'sd1892;
	55:  C2 = 32'sd783;
	56:  C2 = 32'sd399;
    57:  C2 = -32'sd1137;
    58:  C2 = 32'sd1702;
    59:  C2 = -32'sd2008;
    60:  C2 = 32'sd2008;
    61:  C2 = -32'sd1702;
    62:  C2 = 32'sd1137;
    63:  C2 = -32'sd399;
	endcase	
end

// 7 segment displays
convert_hex_to_seven_segment unit7 (
	.hex_value(SRAM_read_data[15:12]), 
	.converted_value(value_7_segment[7])
);

convert_hex_to_seven_segment unit6 (
	.hex_value(SRAM_read_data[11:8]), 
	.converted_value(value_7_segment[6])
);

convert_hex_to_seven_segment unit5 (
	.hex_value(SRAM_read_data[7:4]), 
	.converted_value(value_7_segment[5])
);

convert_hex_to_seven_segment unit4 (
	.hex_value(SRAM_read_data[3:0]), 
	.converted_value(value_7_segment[4])
);

convert_hex_to_seven_segment unit3 (
	.hex_value({2'b00, SRAM_address[17:16]}), 
	.converted_value(value_7_segment[3])
);

convert_hex_to_seven_segment unit2 (
	.hex_value(SRAM_address[15:12]), 
	.converted_value(value_7_segment[2])
);

convert_hex_to_seven_segment unit1 (
	.hex_value(SRAM_address[11:8]), 
	.converted_value(value_7_segment[1])
);

convert_hex_to_seven_segment unit0 (
	.hex_value(SRAM_address[7:4]), 
	.converted_value(value_7_segment[0])
);

assign   
   SEVEN_SEGMENT_N_O[0] = value_7_segment[0],
   SEVEN_SEGMENT_N_O[1] = value_7_segment[1],
   SEVEN_SEGMENT_N_O[2] = value_7_segment[2],
   SEVEN_SEGMENT_N_O[3] = value_7_segment[3],
   SEVEN_SEGMENT_N_O[4] = value_7_segment[4],
   SEVEN_SEGMENT_N_O[5] = value_7_segment[5],
   SEVEN_SEGMENT_N_O[6] = value_7_segment[6],
   SEVEN_SEGMENT_N_O[7] = value_7_segment[7];

assign LED_GREEN_O = {resetn, VGA_enable, ~SRAM_we_n, Frame_error, UART_rx_initialize, PB_pushed};

endmodule
