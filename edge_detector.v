module edge_detector #(
	parameter POS_EDGE_DETECT = 1
)(
	input clk,
	input reset,
	input signal_in,
	output edge_detected
);

	reg prev_signal_in;

	always @ (posedge clk)
		if (reset)
			prev_signal_in <= 1'b0;
		else
			prev_signal_in <= signal_in;

	generate
		if (POS_EDGE_DETECT)
			assign edge_detected = (~prev_signal_in & signal_in);
		else
			assign edge_detected = (prev_signal_in & ~signal_in);
	endgenerate

endmodule
