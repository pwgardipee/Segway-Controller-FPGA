module inert_intf(clk, rst_n, vld, ptch, SS_n, SCLK, MOSI, MISO, INT);
    typedef enum reg[3:0]{INIT1, INIT2, INIT3, INIT4, CHECK, READ1, READ2, READ3, READ4, VALID}state_t;
    state_t state, nxt_state;

    input clk, rst_n;

    output reg vld;
    output [15:0] ptch;

    //SPI signals
    output SS_n, SCLK, MOSI;
    input MISO;

    input INT; // Double flop for meta-stability

    reg [15:0] timer; // timer for state machine

    // Signals saying what byte is ready //
    reg C_P_H, C_P_L, C_AZ_H, C_AZ_L;

    // Initialize SPI master
    reg wrt;
    wire done; // State machine output, input
    wire [15:0] rd_data;
    reg [15:0] cmd; // State machine output
    SPI_mstr16 mstr(.clk(clk), .rst_n(rst_n),
                    .cmd(cmd), .wrt(wrt), .done(done), .rd_data(rd_data),
                    .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));

    // Initialize inertial integrator
    wire [15:0] ptch_rt, ptch, AZ;
    inertial_integrator integ(.clk(clk), .rst_n(rst_n),
                                .vld(vld), .ptch_rt(ptch_rt), .AZ(AZ), .ptch(ptch));


    // Double-flop INT for meta-stability
	//INT_stab is SM input
    reg INT_meta, INT_stab;
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            INT_meta <= 1'b0;
            INT_stab <= 1'b0;
        end else begin
            INT_meta <= INT;
            INT_stab <= INT_meta;
        end
    end

    //////////////
    // AZ flops //
    //////////////
    reg [7:0] AZ_h, AZ_l;
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            AZ_h <= 8'h00;
        else if(C_AZ_H)
            AZ_h <= rd_data[7:0];

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            AZ_l <= 8'h00;
        else if(C_AZ_L)
            AZ_l <= rd_data[7:0];

    // Assign AZ from AZ_h, AZ_l
    assign AZ = {AZ_h, AZ_l};

    ///////////////////
    // ptch_rt flops //
    ///////////////////
    reg [7:0] ptch_h, ptch_l;
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            ptch_h <= 8'h00;
        else if(C_P_H)
            ptch_h <= rd_data[7:0];

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            ptch_l <= 8'h00;
        else if(C_P_L)
            ptch_l <= rd_data[7:0];

    // Assign ptch_rt from ptch_h, ptch_l
    assign ptch_rt = {ptch_h, ptch_l};

    ////////////////////////////
    // State machine goodness //
    ////////////////////////////

    // 16 bit timer for startup logic //
    always @(posedge clk, negedge rst_n)
        if(!rst_n)
            timer <= 16'h0000;
        else
            timer <= timer + 1'b1;

    // State machine state thing //
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            state <= INIT1;
        else
            state <= nxt_state;


    //State Machine transition logic
    always_comb begin
        //set default values
        nxt_state = INIT1;
        wrt = 1'b0;
        cmd = 16'h0D02;
        vld = 1'b0;
        C_P_H = 1'b0;
        C_P_L = 1'b0;
        C_AZ_H = 1'b0;
        C_AZ_L = 1'b0;

        //State transition logic
        case(state)
            INIT1: // INIT1-4 run setup commands
                if(&timer) begin
                    wrt = 1'b1;
                    nxt_state = INIT2;
                end
                else
                    nxt_state = INIT1;

            INIT2:
                begin
                    cmd = 16'h1053;
                    if(done) begin
                        wrt = 1'b1;
                        nxt_state = INIT3;
                    end
                    else begin
                        nxt_state = INIT2;
                    end
                end

            INIT3:
                begin
                    cmd = 16'h1150;
                    if(done) begin
                        wrt = 1'b1;
                        nxt_state = INIT4;
                    end
                    else
                        nxt_state = INIT3;
                end

            INIT4:
                begin
                    cmd = 16'h1460;
                    if(done) begin
                        wrt = 1'b1;
                        nxt_state = CHECK;
                    end
                    else
                        nxt_state = INIT4;
                end
            CHECK: // INT_stab means we should read new data
                if(INT_stab == 1)
                    nxt_state = READ1;
                else
                    nxt_state = CHECK;
            READ1: // Sends out command to read lower ptch byte
                begin
                    cmd = 16'hA200;
                    if(done) begin
                        wrt = 1'b1;
                        nxt_state = READ2;
                    end
                    else
                        nxt_state = READ1;
                end
            READ2: // Receives lower ptch byte,
				   // Sends out cmd to read higher ptch bytes
                begin
                    cmd = 16'hA300;
                    if(done) begin
                        wrt = 1'b1;
                        C_P_L = 1'b1;
                        nxt_state = READ3;
                    end
                    else
                        nxt_state = READ2;
                end
            READ3: // Receives higher ptch byte,
				   // Sends cmd to get lower AZ byte
                begin
                    cmd = 16'hAC00;
                    if(done) begin
                        wrt = 1'b1;
                        C_P_H = 1'b1;
                        nxt_state = READ4;
                    end
                    else
                        nxt_state = READ3;
                end
            READ4: // Receives lower AZ byte
				   // Sends cmd to receive higher AZ byte
                begin
                    cmd = 16'hAD00;
                    if(done) begin
                        wrt = 1'b1;
                        C_AZ_L = 1'b1;
                        nxt_state = VALID;
                    end
                    else
                        nxt_state = READ4;
                end
            VALID: // Gets higher AZ byte
				   // Tells inertial integrator we have new data to process
                begin
                    if(done) begin
                        C_AZ_H = 1'b1;
                        vld = 1'b1;
                        nxt_state = CHECK;
                    end
                    else
                        nxt_state = VALID;
                end
        endcase
    end
endmodule
