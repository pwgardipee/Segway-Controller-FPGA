module SPI_mstr16(clk, rst_n, cmd, wrt, done, rd_data, SS_n, SCLK, MOSI, MISO);
    typedef enum reg [1:0] {IDLE, PORCH, ACTIVE, FINAL} state_t;
    state_t state, next_state;

    input clk, rst_n;
    input [15:0] cmd;
    input wrt;
    input MISO;

    output [15:0] rd_data;
    output MOSI, SCLK;
    output reg SS_n;
    output reg done;

    logic rst_cnt, smpl, shft, set_done, clr_done; // State machine outputs

    reg [4:0] rcv_cnt;
    reg [4:0] sclk_div;
    reg [15:0] shft_reg;
    reg MISO_smpl;

    // Master generates SCLK, 1/32nd of base clk
    assign SCLK = sclk_div[4];
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            sclk_div <= 5'b00000;
        else if(rst_cnt)
            sclk_div <= 5'b10111;
        else
            sclk_div <= sclk_div + 1;


    // Stores MISO every posedge SCLK
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            MISO_smpl <= 1'b0;
        else if(smpl)
            MISO_smpl <= MISO;
        else
            MISO_smpl <= MISO_smpl;

    // Set lsb of shift reg on "negedge" SCLK
    assign rd_data = shft_reg;
    assign MOSI = shft_reg[15];
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            shft_reg <= 16'h0000;
        else if(wrt)
            shft_reg <= cmd;
        else if(shft)
            shft_reg <= {shft_reg[14:0], MISO_smpl};
        else
            shft_reg <= shft_reg;

    // count number of bits transferred
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            rcv_cnt <= 5'b00000;
        else if(rst_cnt)
            rcv_cnt <= 5'b00000;
        else if(smpl)
            rcv_cnt <= rcv_cnt + 1;
        else
            rcv_cnt <= rcv_cnt;

    // SS flip flop because it can't glitch
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            SS_n <= 1'b1;
        else if(clr_done)
            SS_n <= 1'b0;
        else if(set_done)
            SS_n <= 1'b1;

    // Set after we transferred all the bits
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            done <= 1'b0;
        else if(clr_done)
            done <= 1'b0;
        else if(set_done & SS_n)
            done <= 1'b1;

    // FF for state machine
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            state <= IDLE;
        else
            state <= next_state;

    always_comb begin
        next_state = ACTIVE;
        rst_cnt = 0;
        smpl = 0;
        shft = 0;
        set_done = 0;
        clr_done = 0;

        case(state)
            IDLE: //Wait until told we want to make a transaction
                if(wrt) begin
                    rst_cnt = 1;
                    clr_done = 1;
                    next_state = PORCH;
                end else
                    next_state = IDLE;

            PORCH: //Wait until falling edge to go to active
                if(!(&sclk_div)) // not on falling edge/sclk != 11111
                    next_state = PORCH;

            ACTIVE: 
                if(&sclk_div) // sclk = 11111
                    shft = 1; // Save value on falling edge
                else if(&sclk_div[3:0]) // sclk = 01111
                    smpl = 1; // Get new value on rising edge
                else if(rcv_cnt[4]) begin // rcv = 16
                    set_done = 1; // Once we have gotten 16 values, go to back porch
                    next_state = FINAL;
                end

            FINAL:
                if(SS_n) begin //Shift when SS_n goes high
                    shft = 1; // Save final value 
                    set_done = 1; // Let it be known we're done
                    next_state = IDLE;
                end else
                    next_state = FINAL;
        endcase
    end

endmodule
