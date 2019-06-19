module inertial_integrator(clk, rst_n, vld, ptch_rt, AZ, ptch);
	// Kyle Roarty
	// Peyton Gardipee

	input clk, rst_n;

	input vld;
	input [15:0] ptch_rt, AZ;
	output signed [15:0] ptch;

	reg [26:0] ptch_int;

	wire [15:0] ptch_rt_comp;
	wire signed [15:0] AZ_comp, ptch_acc;
	wire signed [26:0] fusion_ptch_offset;
	wire signed [25:0] ptch_acc_product;

	localparam PTCH_RT_OFFSET 	= 16'h03c2;
	localparam AZ_OFFSET 		= 16'hfe80;
	localparam FUDGE 			= 327;

	assign ptch_rt_comp = ptch_rt - PTCH_RT_OFFSET;
	assign AZ_comp = AZ - AZ_OFFSET;

	// Angle from accelerometer
	assign ptch_acc_product = AZ_comp * $signed(FUDGE);
	assign ptch_acc = {{3{ptch_acc_product[25]}}, ptch_acc_product[25:13]};

	// ptch_acc and ptch need to be signed for this comparison to work
	// drift correction factor
	assign fusion_ptch_offset = (ptch_acc > ptch) ? 1024 : -1024;

	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			ptch_int <= 0;
		else if(vld)
			// "Integration" of ptch_int and the correction factor to account for drift
			ptch_int <= ptch_int - {{11{ptch_rt_comp[15]}}, ptch_rt_comp} +
						fusion_ptch_offset;

	assign ptch = ptch_int[26:11];


endmodule
