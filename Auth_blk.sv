module Auth_blk(clk, rst_n, RX, rider_off, pwr_up);
	// Auth_blk needs to be sent 8'h87 or 'g' to start up
	// Auth_blk needs to be sent 8'h67 or 's' to shut down

    typedef enum reg [1:0] {OFF, PWR1, PWR2} state_t;
    state_t state, next_state;

    input clk, rst_n;
    input RX, rider_off;
    output reg pwr_up;

    reg clr_rdy;
    wire rdy;
    wire [7:0] rx_data;

	// UART receiver to communicate with phone
    UART_rcv rcv(.clk(clk), .rst_n(rst_n), .RX(RX), .clr_rdy(clr_rdy), .rx_data(rx_data), .rdy(rdy));


    // State ff
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            state <= OFF;
        else
            state <= next_state;

    always_comb begin
        next_state = PWR1;
        pwr_up = 0;
        clr_rdy = 0;

        case(state)
            OFF: // Waits for full transaction, checks if it's 'g'
                if(rx_data == 8'h67 && rdy)
                    pwr_up = 1;
                else
                    next_state = OFF;
            PWR1: // Waits for full transaction, checks if it's 's'
                if(rx_data == 8'h73 && rdy) begin
                    if(rider_off) // If the rider isn't on the board, can just shut down
                        next_state = OFF;
                    else begin // If there is a rider, don't shut down. Could cause injury
                        next_state = PWR2;
                        pwr_up = 1;
                    end
                end else
                    pwr_up = 1;
            PWR2:
                if(rider_off) // When rider steps off board, shut down ('s' was received in prev state)
                    next_state = OFF;
                else if(rx_data == 8'h67 && rdy) // If 'g' is sent, shouldn't shut down on step off. Goes back to pwr1
                    pwr_up = 1;
                else begin
                    next_state = PWR2;
                    pwr_up = 1;
                end
        endcase
    end


endmodule

