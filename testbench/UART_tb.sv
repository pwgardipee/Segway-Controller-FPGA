module UART_tb();
	reg clk, rst_n;
	logic [7:0] tx_data, rx_data;
	logic trmt, clr_rdy, rdy, tx_done;
	logic connect;

	UART_rcv r(.clk(clk), .rst_n(rst_n), .RX(connect), .clr_rdy(clr_rdy), .rx_data(rx_data), .rdy(rdy));
	UART_tx t(.clk(clk), .rst_n(rst_n), .TX(connect), .trmt(trmt), .tx_data(tx_data), .tx_done(tx_done));


	always #5 clk <= ~clk;

	initial begin
		clk = 0;
		rst_n = 0;
		clr_rdy = 0;
		trmt = 0;

		@(negedge clk);
		rst_n = 1;

		tx_data = 8'b01010101;
		@(posedge clk);
		trmt = 1'b1;
		@(posedge clk);
		trmt = 1'b0;
		wait(tx_done == 1'b1 && rdy == 1'b1);
		if(tx_data != rx_data)
			$stop();

		@(posedge clk);

		tx_data = 8'b11110000;
		@(posedge clk);
		trmt = 1'b1;
		@(posedge clk);
		trmt = 1'b0;
		@(posedge clk);
		wait(tx_done == 1'b1 && rdy == 1'b1);
		if(tx_data != rx_data)
			$stop();

		@(posedge clk);

		tx_data = 8'b00001111;
		@(posedge clk);
		trmt = 1'b1;
		@(posedge clk);
		trmt = 1'b0;
		@(posedge clk);
		wait(tx_done == 1'b1 && rdy == 1'b1);
		if(tx_data != rx_data)
			$stop();

		$stop();

	end


endmodule
