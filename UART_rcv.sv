module UART_rcv(clk, rst_n, RX, clr_rdy, rx_data, rdy);
    typedef enum reg [1:0] {IDLE, ACTIVE, SHIFT} state_t;
    state_t state, next_state;

    input clk, rst_n;
    input RX;
    input clr_rdy;

    output [7:0] rx_data;
    output reg rdy;

    reg RX_meta, RX_stab;
    reg [3:0] rx_counter;
    reg [11:0] baud_counter;
    reg [8:0] RX_DATA;

    reg shift, rst_rx_cnt, rst_baud_cnt, set_rdy, unset_rdy;

    // metastability flops for RX
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            RX_meta <= 1'b0;
            RX_stab <= 1'b0;
        end else begin
            RX_meta <= RX;
            RX_stab <= RX_meta;
        end
    end

    // baud counter
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            baud_counter <= 12'h000;
        else if(rst_baud_cnt && state == IDLE)
            baud_counter <= 12'd1302;
        else if(rst_baud_cnt && state == ACTIVE)
            baud_counter <= 12'h000;
        else if(state == ACTIVE)
            baud_counter <= baud_counter + 1;
    end

    // bits received counter
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            rx_counter <= 4'h0;
        else if(rst_rx_cnt)
            rx_counter <= 4'h0;
        else if(shift)
            rx_counter <= rx_counter + 1;
    end

    // RX shift reg
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            RX_DATA = 9'h000;
        else if(shift)
            RX_DATA = {RX_stab, RX_DATA[8:1]};


    //Shift register flip flop for rdy signal
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            rdy <= 1'b0;
        else if(clr_rdy || unset_rdy)
            rdy <= 1'b0;
        else if(set_rdy)
            rdy <= 1'b1;
    end
    assign rx_data = RX_DATA[7:0];


	//State machine- Go to next state
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    //State	machine next state logic
    always_comb begin
        shift = 0;
        rst_rx_cnt = 0;
        rst_baud_cnt = 0;
        next_state = ACTIVE;
        unset_rdy = 0;
        set_rdy = 0;


        case(state)
            IDLE: if(RX_stab == 1'b0) begin
                //Start bit a 0. Signal to initiate reading.
				unset_rdy = 1;
                rst_rx_cnt = 1;
                rst_baud_cnt = 1;
            end else begin
                next_state = IDLE;
                set_rdy = 1;
            end

            ACTIVE: if(baud_counter == 2604) begin
            	//Shift through UART data bits every 2604 clk cycles    
				rst_baud_cnt = 1;
                shift = 1;
            end else if(rx_counter == 10) begin
                //All bits of UART data have been read
				set_rdy = 1;
                next_state = IDLE;
            end
        endcase

    end

endmodule
