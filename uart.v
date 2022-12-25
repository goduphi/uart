module uart (
	input  wire clk,
	input  wire reset,
	input  wire rx_data,
	output wire tx_data,

	// Fix me: Remove debug outputs
	output wire [9:0] LEDR,
	output wire [2:0] dbg_uart_frame_detector_state,
	output wire [1:0] dbg_uart_rx_state,
	output wire [3:0] dbg_uart_frame_detector_counter,
	output wire [3:0] dbg_uart_rx_counter,
	output wire [3:0] dbg_bit_counter,
	output wire dbg_start_detected,
	output wire dbg_stop_detected,
	output wire dbg_baud_out,
	output wire dbg_busy_out
);

	wire baud_out;
	wire rx_busy;
	wire rx_data_metastable;
	wire reset_inv;

	synchronizer #(
		.FF_NUM(2)
	) rx_data_synchronizer (
		.clk(clk),
		.reset(reset_inv),
		.signal_in(rx_data),
		.signal_out(rx_data_metastable)
	);

	uart_receiver uart_receiver (
		.clk(clk),
		.reset(reset_inv),
		.baud_in(baud_out),
		.rx_data(rx_data_metastable),
		.use_parity_bit(0),
		.busy(rx_busy),
		.latch_data(LEDR[7:0]),

		// Fix me: Remove debug outputs
		.dbg_uart_frame_detector_state(dbg_uart_frame_detector_state),
		.dbg_uart_rx_state(dbg_uart_rx_state),
		.dbg_uart_frame_detector_counter(dbg_uart_frame_detector_counter),
		.dbg_uart_rx_counter(dbg_uart_rx_counter),
		.dbg_bit_counter(dbg_bit_counter),
		.dbg_start_detected(dbg_start_detected),
		.dbg_stop_detected(dbg_stop_detected)
	);

	baud_rate_generator baud_rate_generator (
		.clk(clk),
		.reset(reset_inv),
		.enable(rx_busy),
		.divisor(32'd1736),								// 115200 bps, ((50MHz / (16 * 115200)) * 64) = (27.126736 * 64) = 1736.11 ...
		.baud_out(baud_out)
	);

	assign tx_data		= 1'b0;
	assign LEDR[9:8]	= 2'b00;
	assign reset_inv	= ~reset;

	// Debug outputs
	assign dbg_baud_out = baud_out;
	assign dbg_busy_out = rx_busy;

endmodule
