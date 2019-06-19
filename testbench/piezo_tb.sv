module piezo_tb();
	logic clk, rst_n, nm, os, bl;
	logic out, out_n;
	
	piezo iDUT(.clk(clk), .rst_n(rst_n), .norm_mode(nm), .ovr_spd(os), .batt_low(bl),
				.sound(out), .sound_n(out_n));
				
	always #5 clk = ~clk;
	
	initial begin
		clk = 0;
		rst_n = 0;
		nm = 0;
		os = 1;
		bl = 0;
		
		repeat(2) @(negedge clk);
		rst_n = 1;
		
		repeat(600000000) @(posedge clk);
		$stop();
		
	end

endmodule
