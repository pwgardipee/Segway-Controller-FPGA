module inertial_integrator_tb();
	// Kyle Roarty
	// Peyton Gardipee

	localparam PTCH_RT_OFFSET 	= 16'h03c2;

	reg clk, rst_n;

	logic vld;
	logic signed [15:0] ptch_rt, AZ, ptch;


	inertial_integrator DUT(.clk(clk), .rst_n(rst_n), .vld(vld), .ptch_rt(ptch_rt), .AZ(AZ), .ptch(ptch));

	always #5 clk = ~clk;

	initial begin
		clk = 0;
		rst_n = 0;

		@(negedge clk);
		rst_n = 1;
		ptch_rt = 16'h1000 + PTCH_RT_OFFSET;
		AZ = 16'h0000;
		vld = 1;

		repeat(500) @(posedge clk);
		ptch_rt = PTCH_RT_OFFSET;
		repeat(1000) @(posedge clk);
		ptch_rt = PTCH_RT_OFFSET - 16'h1000;
		repeat(500) @(posedge clk);
		ptch_rt = PTCH_RT_OFFSET;
		repeat(1000) @(posedge clk);
		AZ = 16'h0800;
		repeat(200) @(posedge clk); // Maybe not needed?
		$stop();

	end


endmodule
