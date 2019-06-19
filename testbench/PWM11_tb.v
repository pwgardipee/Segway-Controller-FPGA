module PWM_tb();

reg clk, rst_n;
reg [10:0] duty, duty_cnt;
reg [11:0] count;
wire out;

PWM11 DUT(.clk(clk), .rst_n(rst_n), .duty(duty), .PWM_sig(out));

always #5 clk <= ~clk;

initial begin
	clk = 0;
	rst_n = 0;
	@(negedge clk);
	rst_n = 1;

	// Low duty
	duty = 11'h0;
	repeat(14'h2000) @(posedge clk);


	// High duty	
	duty = 11'h7ff;
	repeat(14'h2000) @(posedge clk);


	// Medium duty
	duty = 11'h1ff;
	repeat(14'h2000) @(posedge clk);

	$stop();
end

endmodule
