`timescale 1ns/1ps
module SPI_mstr_tb();
	logic clk, rst_n;
	logic [15:0] cmd, rd_data;
	logic wrt, done;
	logic SS_n, SCLK, MOSI, MISO;

	SPI_mstr16 DUT(.clk(clk), .rst_n(rst_n), .cmd(cmd),
				   .wrt(wrt), .done(done), .rd_data(rd_data), .SS_n(SS_n), 
				   .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));

	ADC128S slave(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI));

	always #1 clk = ~clk;

	initial begin
		clk = 0;
		rst_n = 0;
		cmd = {2'b00, 3'b101, 11'h000};
		wrt = 0;
		@(negedge clk);
		rst_n = 1;

		
		@(posedge clk);
		wrt = 1;
		@(posedge clk)
		wrt = 0;
		@(posedge done)
		if(rd_data !== 16'h0C00) begin
			$display("Incorrect rd_data for read, reads %h", rd_data);
			$stop();
		end

		@(posedge clk);
		wrt = 1;
		@(posedge clk)
		wrt = 0;
		@(posedge done)
		if(rd_data !== 16'h0C05) begin
			$display("Incorrect rd_data for read, reads %h", rd_data);
			$stop();
		end		
		
		@(negedge clk)
		cmd = {2'b00, 3'b100, 11'h000};
		
		@(posedge clk);
		wrt = 1;
		@(posedge clk)
		wrt = 0;
		@(posedge done)
		if(rd_data !== 16'h0BF5) begin
			$display("Incorrect rd_data for read, reads %h", rd_data);
			$stop();
		end
		
		@(posedge clk);
		wrt = 1;
		@(posedge clk)
		wrt = 0;
		@(posedge done)
		if(rd_data !== 16'h0BF4) begin
			$display("Incorrect rd_data for read, reads %h", rd_data);
			$stop();
		end		
		$display("Everything (that you tested) works!");
		$stop();
	end

endmodule
