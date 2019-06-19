module UART_tx(clk, rst_n, TX, trmt, tx_data, tx_done);
	typedef enum reg {IDLE, ACTIVE} state_t;
	state_t state, next_state;

	input clk, rst_n;
	input trmt;
	input [7:0] tx_data;
	output reg tx_done;
	output TX;

	reg [8:0] TX_DATA;
	reg [11:0] baud_counter;
	reg [3:0] tx_counter;
	logic rst_baud_counter, rst_tx_counter, load_sr, shift;

	// State machine
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			state <= IDLE;
		else
			state <= next_state;
	
	// baud counter
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			baud_counter <= 11'h000;
		else if(rst_baud_counter)
			baud_counter <= 11'h000;
		else if(state == ACTIVE)
			baud_counter <= baud_counter + 1;

	// bits transmitted counter
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			tx_counter <= 4'h0;
		else if(rst_tx_counter)
			tx_counter <= 4'h0;
		else if(shift)
			tx_counter <= tx_counter + 1;

	// TX data shift reg
	always_ff @(posedge clk, negedge rst_n)
		if(!rst_n)
			TX_DATA <= 9'h1ff;
		else if(load_sr)
			TX_DATA <= {tx_data, 1'b0};
		else if(shift)
			TX_DATA <= {1'b1, TX_DATA[8:1]};

	//tx_done SRFF
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			tx_done <= 1'b0;
		else if(state == IDLE && next_state == ACTIVE)
			tx_done <= 1'b0;
		else if(state == ACTIVE && next_state == IDLE)
			tx_done <= 1'b1;
	end

	assign TX = TX_DATA[0];		

	always_comb begin
		rst_baud_counter = 1'b0;
		rst_tx_counter = 1'b0;
		load_sr = 1'b0;
		shift = 1'b0;
		next_state = ACTIVE;
		
		case(state)
			IDLE : if(trmt) begin
				rst_tx_counter = 1'b1;
				rst_baud_counter = 1'b1;
				load_sr = 1'b1;
			end else begin
				next_state = IDLE;
			end
			ACTIVE : if(baud_counter == 2604) begin
				rst_baud_counter = 1'b1;
				shift = 1'b1;				
			end else if(tx_counter == 9) begin
				next_state = IDLE;
			end
		endcase
	end


endmodule
