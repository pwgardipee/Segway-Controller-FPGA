module mtr_drv_tb();

	reg clk, rst_n;
	reg [10:0] duty;
	reg neg;
	wire out_f_l, out_r_l, out_f_r, out_r_r;

//mtr_drv(clk, rst_n, lft_spd, lft_rev, PWM_rev_lft, PWM_frwrd_lft, rght_spd, rght_rev, PWM_rev_rght, PWM_frwrd_rght)
	mtr_drv DUT(.clk(clk), .rst_n(rst_n), .lft_spd(duty), .lft_rev(neg), .rght_spd(duty), .rght_rev(neg),
							.PWM_rev_lft(out_r_l), .PWM_frwrd_lft(out_f_l), .PWM_rev_rght(out_r_r), .PWM_frwrd_rght(out_f_r));

	always #5 clk <= ~clk;

	initial begin
		clk = 0;
		neg = 0;
		rst_n = 0;
		@(negedge clk);
		rst_n = 1;

		// Low duty
		duty = 11'h0;
		repeat(14'h2000) @(posedge clk);
		neg = 1;
		repeat(14'h2000) @(posedge clk);

		// High duty	
		duty = 11'h7ff;
		neg = 0;
		repeat(14'h2000) @(posedge clk);
		neg = 1;
		repeat(14'h2000) @(posedge clk);

		// Medium duty
		duty = 11'h1ff;
		neg = 0;
		repeat(14'h2000) @(posedge clk);
		neg = 1;
		repeat(14'h2000) @(posedge clk);

		$stop();
	end

endmodule
