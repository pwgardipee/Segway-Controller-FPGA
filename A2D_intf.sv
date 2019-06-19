module A2D_intf(clk, rst_n, nxt, lft_ld, rght_ld, batt, SS_n, SCLK, MOSI, MISO);
    localparam LFT_LD = 2'b00;
    localparam RGHT_LD = 2'b01;
    localparam BATT = 2'b10;

    typedef enum reg[1:0]{IDLE, WRITE, UPDATE, READ}state_t;
    state_t state, nxt_state;

    input clk, rst_n;
    input nxt; // When to read from ADC next
    output reg [11:0] lft_ld, rght_ld, batt;
    wire [2:0] channel; 

    // SPI interface
    input MISO;
    output MOSI, SCLK;
    output SS_n;

    // Other signals
    reg wrt, update; // wrt: start a SPI transaction, update: SPI transaction done
    wire done; // Done with both SPI transactions (READ/WRITE)
    wire [15:0] cmd, rd_data;

    // Round-robin counter
    reg [1:0] count;

    SPI_mstr16 master(.clk(clk), .rst_n(rst_n), .cmd(cmd),
                      .wrt(wrt), .done(done), .rd_data(rd_data),
                      .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));



    // Counter, counts 0 to 2 as we have 3 ADCs to read 
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            count <= 2'b00;
        else if(update)
            count <= (count == 2'b10) ? 2'b00 : count + 1;

	// Turn the counter value to the corresponding channel value
    assign channel = (count == LFT_LD) ? 3'b000 : (count == RGHT_LD) ? 3'b100 : 3'b101;
    assign cmd = {2'b00,channel,11'h000};

    // Flops for corresponding ADC channels //
	// update is asserted when the SPI receive is complete
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            lft_ld <= 12'h000;
        else if(update && count == LFT_LD)
            lft_ld <= rd_data[11:0];

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            rght_ld <= 12'h000;
        else if(update && count == RGHT_LD)
            rght_ld <= rd_data[11:0];

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            batt <= 12'h000;
        else if(update && count == BATT)
            batt <= rd_data[11:0];


///////////////State machine stuff here//////////////////
//State Machine- go to next state
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            state <= IDLE;
        else
            state <= nxt_state;

    //State Machine transition logic
    always_comb begin
        //set default values
        update = 1'b0;
        wrt = 1'b0;
        nxt_state = IDLE;

        //State transition logic
        case(state)
            IDLE: // Wait for signal telling us to start a transaction
                if(nxt)begin
                    wrt = 1'b1;
                    nxt_state = WRITE;
                end
                else
                    nxt_state = IDLE;
            WRITE: // Tell ADC what channel we want to read from
                if(done)
                    nxt_state = UPDATE;
                else
                    nxt_state = WRITE;
            UPDATE: begin
                // Use update state to delay for one clk
				// Allows done signal to fall
                nxt_state = READ;
                wrt = 1'b1;
            end
            READ: // Receive data from ADC channel specified in WRITE
				  // When we have data, write it into the corresponding reg
                if(done) begin
                    nxt_state = IDLE;
                    update = 1'b1;
                end else
                    nxt_state = READ;

        endcase

    end
endmodule
