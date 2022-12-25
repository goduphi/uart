module synchronizer #(
	parameter FF_NUM = 2
)(
	input  wire clk,
	input  wire reset,
	input  wire signal_in,
	output wire signal_out
);

	generate
		if (FF_NUM < 2) begin
			reg [1:0] signal_prev;

			always @ (posedge clk)
				if (reset)
					signal_prev <= 0;
				else begin
					signal_prev[0] <= signal_in;
					signal_prev[1] <= signal_prev[0];
				end

			assign signal_out = signal_prev[1];
		end
		else begin
			reg [FF_NUM - 1:0]	signal_prev	= 0;
			integer					ff_index		= 0;

			always @ (posedge clk)
				if (reset)
					signal_prev <= 0;
				else begin
					signal_prev[0] <= signal_in;

					for (ff_index = 1; ff_index < FF_NUM; ff_index = ff_index + 1'b1)
						signal_prev[ff_index] <= signal_prev[ff_index - 1'b1];
				end

			assign signal_out = signal_prev[FF_NUM - 1'b1];
		end
	endgenerate

endmodule
