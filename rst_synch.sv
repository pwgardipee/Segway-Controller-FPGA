module rst_synch(RST_n, clk, rst_n);
input RST_n, clk;
output reg rst_n;

reg metastab;

// Does 2 flip-flops back to back to remove metastability issues
always_ff @(negedge clk, negedge RST_n) begin
	if (!RST_n)
		metastab <= 1'b0;
	else
		metastab <= 1'b1;
end

always_ff @(negedge clk, negedge RST_n) begin
	if (!RST_n)
		rst_n <= 1'b0;
	else
		rst_n <= metastab;
end


endmodule
