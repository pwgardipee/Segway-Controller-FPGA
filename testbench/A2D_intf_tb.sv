module A2D_intf_tb();
	logic clk, rst_n;

	logic wrt, done;
	logic SS_n, SCLK, MOSI, MISO;

	logic nxt;
	logic [11:0] lft_ld, rght_ld, batt;

	A2D_intf DUT(.clk(clk), .rst_n(rst_n), .nxt(nxt),
				 .lft_ld(lft_ld), .rght_ld(rght_ld), .batt(batt),
				 .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));

	ADC128S slave(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI));

	always #5 clk = ~clk;

	initial begin
		clk = 0;
		rst_n = 0;
		@(negedge clk);
		rst_n = 1;
		nxt = 1;
		@(negedge clk);
		nxt = 0;
		@(posedge DUT.done);
		@(posedge DUT.done);
		@(posedge clk);
		@(posedge clk);
		if(lft_ld !== 12'hC00)
			$stop();

		@(negedge clk);
		nxt = 1;
		@(negedge clk);
		nxt = 0;
		@(posedge DUT.done);
		@(posedge DUT.done);
		@(posedge clk);
		@(posedge clk);
		if(rght_ld !== 12'hBF4)
			$stop();
		if(lft_ld !== 12'hC00)
			$stop();

		@(negedge clk);
		nxt = 1;
		@(negedge clk);
		nxt = 0;
		@(posedge DUT.done);
		@(posedge DUT.done);
		@(posedge clk);
		@(posedge clk);
		if(batt !== 12'hBE5)
			$stop();
		if(rght_ld !== 12'hBF4)
			$stop();
		if(lft_ld !== 12'hC00)
			$stop();


		@(negedge clk);
		nxt = 1;
		@(negedge clk);
		nxt = 0;
		@(posedge DUT.done);
		@(posedge DUT.done);
		@(posedge clk);
		@(posedge clk);
		if(lft_ld !== 12'hBD0)
			$stop();
		if(batt !== 12'hBE5)
			$stop();
		if(rght_ld !== 12'hBF4)
			$stop();

		$stop();

	end
endmodule
