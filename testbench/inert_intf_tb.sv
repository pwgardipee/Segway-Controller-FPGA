module inert_intf_tb();
logic clk, rst_n;

// SPI stuff
logic SS_n, SCLK, MOSI, MISO;

logic INT;


logic vld;
logic [15:0] ptch;
inert_intf intf(.clk(clk), .rst_n(rst_n), 
				.vld(vld), .ptch(ptch), 
				.SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .INT(INT));


SegwayModel seg(.clk(clk), .RST_n(rst_n),
				.SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .INT(INT),
				.PWM_rev_rght(1'b0), .PWM_frwrd_rght(1'b0), .PWM_rev_lft(1'b0), .PWM_frwrd_lft(1'b0),
				.rider_lean(16'h1fff));

always #5 clk = ~clk;

initial begin
	clk = 0;
	rst_n = 0;
	@(negedge clk);
	rst_n = 1;

	repeat(500000) @(posedge clk);
	$stop();
end

endmodule
