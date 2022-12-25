module baud_rate_generator (
	input	 wire				clk,
	input	 wire				reset,
	input  wire				enable,
	input  wire [31:0]	divisor,
	output reg				baud_out
);

	reg [31:0] counter;
	reg [31:0] target;

	always @ (posedge clk)
		if (reset || ~enable) begin
			counter  <= 32'd0;
			baud_out <= 1'b0;
			target   <= divisor;
		end
		else begin
			counter <= (counter + 32'b10000000);

			if (counter[31:7] == target[31:7]) begin
				target	<= (target + divisor);
				baud_out <= ~baud_out;
			end
		end

endmodule
