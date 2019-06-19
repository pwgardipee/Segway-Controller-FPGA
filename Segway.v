module Segway(clk,RST_n,LED,INERT_SS_n,INERT_MOSI,
              INERT_SCLK,INERT_MISO,A2D_SS_n,A2D_MOSI,A2D_SCLK,
              A2D_MISO,PWM_rev_rght,PWM_frwrd_rght,PWM_rev_lft,
              PWM_frwrd_lft,piezo_n,piezo,INT,RX);

    input clk,RST_n;
    input INERT_MISO;                     // Serial in from inertial sensor
    input A2D_MISO;                       // Serial in from A2D
    input INT;                            // Interrupt from inertial indicating data ready
    input RX;                             // UART input from BLE module


    output [7:0] LED;                     // These are the 8 LEDs on the DE0, your choice what to do
    output A2D_SS_n, INERT_SS_n;          // Slave selects to A2D and inertial sensor
    output A2D_MOSI, INERT_MOSI;          // MOSI signals to A2D and inertial sensor
    output A2D_SCLK, INERT_SCLK;          // SCLK signals to A2D and inertial sensor
    output PWM_rev_rght, PWM_frwrd_rght;  // right motor speed controls
    output PWM_rev_lft, PWM_frwrd_lft;    // left motor speed controls
    output piezo_n,piezo;                 // diff drive to piezo for sound

    ////////////////////////////////////////////////////////////////////////
    // fast_sim is asserted to speed up fullchip simulations.  Should be //
    // passed to both balance_cntrl and to steer_en.  Should be set to  //
    // 0 when we map to the DE0-Nano.                                  //
    ////////////////////////////////////////////////////////////////////
    localparam fast_sim = 1;  // asserted to speed up simulations.

    ///////////////////////////////////////////////////////////
    ////// Internal interconnecting sigals defined here //////
    /////////////////////////////////////////////////////////

    wire rst_n;                           // internal global reset that goes to all units
    wire pwr_up;                          // Signal to specify person is on board and authenticated
    wire [11:0] lft_ld, rght_ld, batt;    // Converted signals specifying load on lft/rght cell and batt level
    wire [15:0] ptch;                     // Pitch value of segway from accelerometer and gyro
    wire vld;                             // Connection between inertial interface and balance controller

    wire en_steer;                        // Whether steering should be on or not, from steer_en
    wire rider_off;                       // If rider is on the board. From steer_en
    wire [11:0] ld_cell_diff;             // Load cell difference. From steer_en (signed)

    // Connections between balance controller and motor pwm mapper
    wire [10:0] lft_spd, rght_spd;        // Unsigned speed of the motors
    wire lft_rev, rght_rev;               // Set when motor is going in reverse

    wire too_fast;                        // Goes to piezo to indicate balance control may fail

    ///////////////////////////////
    // Instantiate authenticator //
    ///////////////////////////////
    Auth_blk iAUTH(.clk(clk), .rst_n(rst_n),
                    .RX(RX), .rider_off(rider_off),                                             //Inputs
                    .pwr_up(pwr_up));                                                           //Outputs

    ////////////////////////////////////
    // Instantiate inertial interface //
    ////////////////////////////////////
    inert_intf iININT(.clk(clk), .rst_n(rst_n),
                    .INT(INT),                                                                  //Inputs
                    .vld(vld), .ptch(ptch),                                                     //Outputs
                    .SS_n(INERT_SS_n), .SCLK(INERT_SCLK), .MOSI(INERT_MOSI), .MISO(INERT_MISO));//SPI signals


    ////////////////////////////////////
    // Instantiate balance controller //
    ////////////////////////////////////
    balance_cntrl iBAL(.clk(clk), .rst_n(rst_n),
                    .vld(vld), .ptch(ptch), .rider_off(rider_off),                              //Inputs
                    .en_steer(en_steer), .pwr_up(pwr_up), .ld_cell_diff(ld_cell_diff),          //Inputs
                    .too_fast(too_fast), .lft_spd(lft_spd), .lft_rev(lft_rev),                  //Outputs
                    .rght_spd(rght_spd), .rght_rev(rght_rev));                                  //Outputs
    defparam iBAL.fast_sim = fast_sim;

    /////////////////////////////////////
    // Instantiate steering controller //
    /////////////////////////////////////
    steer_en iSTEER(.clk(clk), .rst_n(rst_n),
                    .lft_ld(lft_ld), .rght_ld(rght_ld),                                         //Inputs
                    .en_steer(en_steer), .rider_off(rider_off),                                 //Outputs
                    .ld_cell_diff(ld_cell_diff));                                               //Outputs
    defparam iSTEER.fast_sim = fast_sim;

    ////////////////////////////////////////
    // Instantiate speed -> pwm converter //
    ////////////////////////////////////////
    mtr_drv iMTR(.clk(clk), .rst_n(rst_n),
                .lft_spd(lft_spd), .lft_rev(lft_rev),                                           //Inputs
                .rght_spd(rght_spd), .rght_rev(rght_rev),                                       //Inputs
                .PWM_rev_lft(PWM_rev_lft), .PWM_frwrd_lft(PWM_frwrd_lft),                       //Outputs
                .PWM_rev_rght(PWM_rev_rght), .PWM_frwrd_rght(PWM_frwrd_rght));                  //Outputs


    ///////////////////////////////////////////////////
    // Instantiate reader for battery and load cells //
    ///////////////////////////////////////////////////
	// Tell A2D interface to read from A2D converter
	// Whenever we get new inertial values for convenience
    A2D_intf iA2DINT(.clk(clk), .rst_n(rst_n),
                    .nxt(vld),                                                                  //Inputs
                    .lft_ld(lft_ld), .rght_ld(rght_ld), .batt(batt),                            //Outputs
                    .SS_n(A2D_SS_n), .SCLK(A2D_SCLK), .MOSI(A2D_MOSI), .MISO(A2D_MISO));        //SPI signals

    /////////////////////////
    // Instantiate speaker //
    /////////////////////////
    piezo iSPKR(.clk(clk), .rst_n(rst_n),
                .norm_mode(pwr_up), .ovr_spd(too_fast), .batt_low(batt <= 15'h800),            //Inputs
                .sound(piezo), .sound_n(piezo_n));											   //Outputs

    /////////////////////////////////////
    // Instantiate reset synchronizer //
    ///////////////////////////////////
    rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));

endmodule
