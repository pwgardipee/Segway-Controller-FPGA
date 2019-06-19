module Auth_blk_tb();
reg clk, rst_n;
reg TXRX;
logic rider_off, trmt, tx_done, pwr_up;
reg [7:0] tx_data;

Auth_blk DUT(.clk(clk), .rst_n(rst_n), .RX(TXRX), .rider_off(rider_off), .pwr_up(pwr_up));
UART_tx tmit(.clk(clk), .rst_n(rst_n), .TX(TXRX), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done));

always #5 clk = ~clk;

initial begin
	clk = 0;
	rst_n = 0;
	@(negedge clk)
	rst_n = 1;
	


end

endmodule
