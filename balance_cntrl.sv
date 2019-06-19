module balance_cntrl(clk,rst_n,vld,ptch,ld_cell_diff,lft_spd,lft_rev,
                     rght_spd,rght_rev,rider_off, en_steer, pwr_up, too_fast);
  // Kyle Roarty
  // Peyton Gardipee
  parameter fast_sim = 0;

  input clk,rst_n;
  input vld;                        // tells when a new valid inertial reading ready
  input signed [15:0] ptch;         // actual pitch measured
  input signed [11:0] ld_cell_diff; // lft_ld - rght_ld from steer_en block
  input rider_off;                  // High when weight on load cells indicates no rider
  input en_steer;
  output [10:0] lft_spd;            // 11-bit unsigned speed at which to run left motor
  output lft_rev;                   // direction to run left motor (1==>reverse)
  output [10:0] rght_spd;           // 11-bit unsigned speed at which to run right motor
  output rght_rev;                  // direction to run right motor (1==>reverse)

  input pwr_up;						// High when motors should be driven
  output too_fast;					// High when motors can't compensate for changes in balance

  ////////////////////////////////////
  // Define needed registers below //
  //////////////////////////////////
    reg signed [17:0] ptch_I_term;
    reg signed [9:0] ptch_err_tmp, prev_ptch_err;

  ///////////////////////////////////////////
  // Define needed internal signals below //
  /////////////////////////////////////////
    wire signed [6:0] ptch_D_sat;
    wire signed [9:0] ptch_err_sat, ptch_D_diff;
    wire signed [12:0] ptch_D_term;
    wire signed [14:0] ptch_P_term;
    wire signed [15:0] PID_cntrl, lft_shaped, rght_shaped;
    reg signed [15:0] lft_torque, rght_torque;
    wire [15:0] lft_torque_abs, rght_torque_abs, lft_shaped_abs, rght_shaped_abs;
    wire signed [17:0] ptch_err_sat_ext;
    wire signed [17:0] integral;
    wire ov;
  /////////////////////////////////////////////
  // local params for increased flexibility //
  ///////////////////////////////////////////
  localparam P_COEFF = 5'h0E;
  localparam D_COEFF = 6'h14;               // D coefficient in PID control = +20

  localparam LOW_TORQUE_BAND = 8'h46;   // LOW_TORQUE_BAND = 5*P_COEFF
  localparam GAIN_MULTIPLIER = 6'h0F;   // GAIN_MULTIPLIER = 1 + (MIN_DUTY/LOW_TORQUE_BAND)
  localparam MIN_DUTY = 15'h03D4;       // minimum duty cycle (stiffen motor and get it ready)

    // saturate ptch -> ptch_err_sat from 16 -> 10 bits. ptch is signed
	// Tells us how far off the board is from perfectly stable
    assign ptch_err_sat = ptch[15] ? &ptch[14:9] ? ptch[9:0]
                                                 : 10'h200
                                   : |ptch[14:9] ? 10'h1ff
                                                 : {1'b0, ptch[8:0]};

    // P math : proportional. Multiply ptch error by a constant
    assign ptch_P_term = ptch_err_sat * $signed(P_COEFF);

    // I math : integral. Integrate ptch_err over time
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            ptch_I_term <= 18'h00000;
        else if(!pwr_up) // Reset on power up to prevent over/undercorrection when rider gets on
            ptch_I_term <= 18'h00000;
        else if(rider_off) // Same idea as above, prevent integration of perfectly level board dampening correction
            ptch_I_term <= 18'h00000;
        else if(vld & ~ov) // Update 'I' term when it won't overflow
            ptch_I_term <= integral;
        else
            ptch_I_term <= ptch_I_term; // If 'I' term is maxed/would overflow, keep as is to prevent bad correction
    end

    // Sign extend to 18 bits
    assign ptch_err_sat_ext = { {8{ptch_err_sat[9]}}, ptch_err_sat };
    assign integral = ptch_err_sat_ext + ptch_I_term;
    // Overflow if input signs are same and output sign is different
    assign ov = (ptch_err_sat_ext[17] & ptch_I_term[17] & ~integral[17]) | (~ptch_err_sat_ext[17] & ~ptch_I_term[17] & integral[17]);

    // D math
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            ptch_err_tmp <= 10'h000;
            prev_ptch_err <= 10'h000;
        end else if(vld) begin // Store up to 2 samples ago. Store when new data available
            ptch_err_tmp <= ptch_err_sat;
            prev_ptch_err <= ptch_err_tmp;
        end else begin // Hold value
            ptch_err_tmp <= ptch_err_tmp;
            prev_ptch_err <= prev_ptch_err;
        end
    end

    // Current err - prev err
    assign ptch_D_diff = ptch_err_sat - prev_ptch_err;
    // Saturate to 7 bits, signed
    assign ptch_D_sat = ptch_D_diff[9] ? &ptch_D_diff[8:6] ? ptch_D_diff[6:0]
                                                           : 7'h40
                                       : |ptch_D_diff[8:6] ? 7'h3f
                                                           : {1'b0, ptch_D_diff[5:0]};
    assign ptch_D_term = ptch_D_sat * $signed(D_COEFF);

    // PID math, get torque
    // Just P+I+D, after sign extension

    reg [15:0] ptch_P_term_16, ptch_I_term_16, ptch_D_term_16;

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n) begin
            ptch_P_term_16 <= 16'h0000;
            ptch_I_term_16 <= 16'h0000;
            ptch_D_term_16 <= 16'h0000;
        end else begin
            ptch_P_term_16 <= { ptch_P_term[14], ptch_P_term }; // Sign extend
            ptch_I_term_16 <= (fast_sim) ? ptch_I_term[17:2] : { {4{ptch_I_term[17]}}, ptch_I_term[17:6] }; // Sign extend. Choose higher bits when simulating
            ptch_D_term_16 <= { {3{ptch_D_term[12]}}, ptch_D_term }; // Sign extend

        end

    assign PID_cntrl = ptch_P_term_16 + ptch_I_term_16 + ptch_D_term_16; // Sum up PID terms 

	// ld_cell_diff is left_ld - right_ld
    // Adds to left, subtract from right. allows for steering
	// If leaning forward and left, ccw
	// Forward right, cw
	// Back left, cw
	// Back right, ccw
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            lft_torque <= 16'h0000;
        else begin
            lft_torque <= (en_steer) ? PID_cntrl - { {7{ld_cell_diff[11]}}, ld_cell_diff[11:3] }
                                     : PID_cntrl;
        end
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            rght_torque <= 16'h0000;
        else begin
            rght_torque <= (en_steer) ? PID_cntrl + { {7{ld_cell_diff[11]}}, ld_cell_diff[11:3] }
                                     : PID_cntrl;
        end

    assign lft_torque_abs = lft_torque[15] ? ~lft_torque + 1
                                           : lft_torque;
    assign rght_torque_abs = rght_torque[15] ? ~rght_torque + 1
                                             : rght_torque;

    // if small torque, multiply it to overcome motor friction/dead zone
    // If larger, add/sub the MIN_DUTY to get out of the dead zone
    assign lft_shaped = (lft_torque_abs >= LOW_TORQUE_BAND) ? (lft_torque[15]) ? lft_torque - MIN_DUTY
                                                                               : lft_torque + MIN_DUTY
                                                            : lft_torque * $signed(GAIN_MULTIPLIER);
    assign rght_shaped = (rght_torque_abs >= LOW_TORQUE_BAND) ? (rght_torque[15]) ? rght_torque - MIN_DUTY
                                                                                  : rght_torque + MIN_DUTY
                                                              : rght_torque * $signed(GAIN_MULTIPLIER);

    assign lft_shaped_abs = lft_shaped[15] ? ~lft_shaped + 1
                                           : lft_shaped;
    assign rght_shaped_abs = rght_shaped[15] ? ~rght_shaped + 1
                                             : rght_shaped;

    // Outputs
    assign lft_rev = lft_shaped[15];
    assign rght_rev = rght_shaped[15];

	// Check if speed is > 11 bits, if so set to max 11 bit number
	// check if board is powered, otherwise set everything to 0
    assign lft_spd = (|lft_shaped_abs[15:11] ? 11'h7ff : lft_shaped_abs[10:0]) & {11{pwr_up}};
    assign rght_spd = (|rght_shaped_abs[15:11] ? 11'h7ff : rght_shaped_abs[10:0]) & {11{pwr_up}};

    assign too_fast = (lft_spd > 1536) | (rght_spd > 1536);

endmodule
