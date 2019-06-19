module balance_cntrl_chk_tb();

reg clk;
reg [31:0] stim;
wire [23:0] resp;
reg [31:0] in_mem[0:999];
reg [23:0] out_mem[0:999];
integer i;

balance_cntrl DUT(.clk(clk), .rst_n(stim[31]), .vld(stim[30]), .ptch(stim[29:14]),
				  .ld_cell_diff(stim[13:2]), .rider_off(stim[1]), .en_steer(stim[0]),
				  .lft_rev(resp[23]), .lft_spd(resp[22:12]), .rght_rev(resp[11]), .rght_spd(resp[10:0])); 


initial begin
	$readmemh("balance_cntrl_stim.hex", in_mem);
	$readmemh("balance_cntrl_resp.hex", out_mem);
end
	
always #5 clk = ~clk;


initial begin
	clk = 0;
	@(posedge clk);

	for(i = 0; i < 1000; i = i + 1) begin
		stim <= in_mem[i];
		@(posedge clk);
		#1 if(resp !== out_mem[i]) begin
			$display("response isn't what it should be. %h, %h", resp, out_mem[i]);
			$stop();
		end
	end

	$display("You did it!");
	$stop();
end
endmodule
