`include "uart_common_macros.v"

module uart_frame_detector (
	input  wire clk,
	input  wire reset,
	input  wire baud_in_pos_edge,
	input  wire rx_data,
	input  wire rx_done,
	output wire start_detected,
	output wire busy,

	// Fix me: Remove debug output
	output wire [2:0] dbg_state,
	output wire [3:0] dbg_counter
);

	// State machine parameters
	localparam SM_IDLE				= 2'd0;
	localparam SM_SAMPLE_DATA_0	= 2'd1;
	localparam SM_SAMPLE_DATA_1	= 2'd2;
	localparam SM_START_DETECTED	= 3'd3;
	localparam SM_WAIT				= 3'd4;
	localparam SM_STATE_NUM			= 3'd5;

	// Module inter-connection signals
	wire rx_data_neg_edge;

	// State machine variables
	reg [$clog2(SM_STATE_NUM) - 1:0] state;
	reg [$clog2(SM_STATE_NUM) - 1:0] next_state;
	// There is an internal clock that runs @16x the baud rate.
	// Sample the start bit on the 8th clock.
	reg [3:0]								counter;

	always @ (posedge clk)
		if (reset)
			counter <= 4'd0;
		else
			if (state == SM_IDLE)
				counter <= `COUNT_16;
			else if (((state == SM_SAMPLE_DATA_0) || (state == SM_SAMPLE_DATA_1)) & baud_in_pos_edge)
				counter <= (counter + 1'b1);

	always @ (posedge clk)
		if (reset)
			state <= SM_IDLE;
		else
			state <= next_state;

	always @ (*) begin
		next_state = state;

		case (state)
			SM_IDLE:
				if (rx_data_neg_edge)									// Detection of first falling edge of RX Data
					next_state = SM_SAMPLE_DATA_0;
			SM_SAMPLE_DATA_0:
				if (counter == (`COUNT_16 >> 1))						// Declare a start detected on the 8th positive clock edge
					if (~rx_data)
						next_state = SM_SAMPLE_DATA_1;
					else
						next_state = SM_IDLE;
			SM_SAMPLE_DATA_1:												// Count up to 16 ticks
				if (counter == `COUNT_16)
					next_state = SM_START_DETECTED;
			SM_START_DETECTED:
				next_state = SM_WAIT;
			SM_WAIT:
				if (rx_done)
					next_state = SM_IDLE;
		endcase
	end

	edge_detector #(
		.POS_EDGE_DETECT(0)
	) rx_data_neg_edge_detector (
		.clk(clk),
		.reset(reset),
		.signal_in(rx_data),
		.edge_detected(rx_data_neg_edge)
	);

	assign start_detected	= (state == SM_START_DETECTED);
	assign busy					= (state != SM_IDLE);

	// Fix me: Remove debug output
	assign dbg_state		= state;
	assign dbg_counter	= counter;

endmodule
