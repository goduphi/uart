`include "uart_common_macros.v"

module uart_receiver (
	input  wire			clk,
	input  wire			reset,
	input  wire			baud_in,
	input  wire			rx_data,
	input	 wire			use_parity_bit,
	output wire			busy,
	output reg	[7:0]	latch_data,

	// Fix me: Remove debug output
	output wire [2:0] dbg_uart_frame_detector_state,
	output wire [1:0] dbg_uart_rx_state,
	output wire [3:0] dbg_uart_frame_detector_counter,
	output wire [3:0] dbg_uart_rx_counter,
	output wire [3:0] dbg_bit_counter,
	output wire dbg_start_detected,
	output wire dbg_stop_detected
);

	// State machine parameters
	localparam SM_IDLE			= 2'd0;
	localparam SM_SAMPLE_DATA	= 2'd1;
	localparam SM_PARITY			= 2'd2;
	localparam SM_DETECT_STOP	= 2'd3;
	localparam SM_STATE_NUM		= 3'd4;

	// Module inter-connection signals
	wire rx_done;
	wire start_detected;
	wire baud_in_pos_edge;
	wire frame_detector_busy;
	wire _16th_tick;
	wire _8th_tick;

	// State machine variables
	reg [$clog2(SM_STATE_NUM) - 1:0] state;
	reg [$clog2(SM_STATE_NUM) - 1:0] next_state;
	reg [3:0]								counter;
	reg [2:0]					 			bit_counter;
	reg							 			stop_detected;
	reg							 			stop_error;

	always @ (posedge clk)
		if (reset) begin
			counter			<= 4'd0;
			bit_counter		<= 3'b0;
			stop_detected	<= 1'b0;
			stop_error		<= 1'b0;
		end
		else begin
			if (state == SM_IDLE) begin
				counter			<= 4'd0;
				bit_counter		<= 3'd0;
				stop_detected	<= 1'b0;
				stop_error		<= 1'b0;
			end
			else
				if (baud_in_pos_edge) begin
					// Sample data on the 8th tick of the x16 baud clock
					if (_8th_tick) begin
						if (state == SM_SAMPLE_DATA) begin
							latch_data[bit_counter] <= rx_data;
						end
						else if (state == SM_DETECT_STOP)
							if (rx_data)
								stop_detected <= 1'b1;
							else
								stop_error <= 1'b1;
					end

					// Change data on the 16th tick of the x16 baud clock
					if (_16th_tick)
						if (state == SM_SAMPLE_DATA)
							bit_counter <= (bit_counter + 1'b1);

					counter <= (counter + 1'b1);
				end
		end

	always @ (posedge clk)
		if (reset)
			state <= SM_IDLE;
		else
			state <= next_state;

	always @ (*) begin
		next_state = state;

		case (state)
			SM_IDLE:
				if (start_detected & ~stop_error)
					next_state = SM_SAMPLE_DATA;
			SM_SAMPLE_DATA:
				if (_16th_tick & (bit_counter == `COUNT_8))
					if (use_parity_bit)
						next_state = SM_PARITY;
					else
						next_state = SM_DETECT_STOP;
			SM_PARITY:
				next_state = SM_DETECT_STOP;
			SM_DETECT_STOP:
				if (_16th_tick & (stop_detected | stop_error))
					next_state = SM_IDLE;
		endcase
	end

	uart_frame_detector uart_start_detector (
		.clk(clk),
		.reset(reset),
		.baud_in_pos_edge(baud_in_pos_edge),
		.rx_data(rx_data),
		.rx_done(rx_done),
		.start_detected(start_detected),
		.busy(frame_detector_busy),

		// Fix me: Remove debug output
		.dbg_state(dbg_uart_frame_detector_state),
		.dbg_counter(dbg_uart_frame_detector_counter)
	);

	edge_detector #(
		.POS_EDGE_DETECT(1)
	) baud_in_pos_edge_detector (
		.clk(clk),
		.reset(reset),
		.signal_in(baud_in),
		.edge_detected(baud_in_pos_edge)
	);

	assign _16th_tick	= (counter == `COUNT_16);
	assign _8th_tick	= (counter == (`COUNT_16 >> 1));
	assign rx_done		= (state == SM_IDLE);
	assign busy			= ((state != SM_IDLE) | frame_detector_busy);

	// Fix me: Remove debug output
	assign dbg_start_detected	= start_detected;
	assign dbg_uart_rx_state	= state;
	assign dbg_uart_rx_counter	= counter;
	assign dbg_bit_counter		= bit_counter;
	assign dbg_stop_detected	= stop_detected;

endmodule
