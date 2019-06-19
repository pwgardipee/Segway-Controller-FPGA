module mtr_drv(clk, rst_n, lft_spd, lft_rev, PWM_rev_lft, PWM_frwrd_lft, rght_spd, rght_rev, PWM_rev_rght, PWM_frwrd_rght);
    input clk, rst_n;
    input [10:0] lft_spd, rght_spd;
    input lft_rev, rght_rev;

    output PWM_rev_lft, PWM_frwrd_lft;
    output PWM_rev_rght, PWM_frwrd_rght;

    reg lft_sig, rght_sig;

	// Takes lft_spd/rght_spd as a duty cycle, produces PWM wave with that duty
	// PWM11 is on an 11-bit counter
    PWM11 lft(.clk(clk), .rst_n(rst_n), .duty(lft_spd), .PWM_sig(lft_sig)),
            rght(.clk(clk), .rst_n(rst_n), .duty(rght_spd), .PWM_sig(rght_sig));

	// Sets values based on if the motor should go forwards or reverse
    assign PWM_rev_lft = lft_rev & lft_sig;
    assign PWM_frwrd_lft = ~lft_rev & lft_sig;
	
	// Sets values based on if the motor should go forwards or reverse
    assign PWM_rev_rght = rght_rev & rght_sig;
    assign PWM_frwrd_rght = ~rght_rev & rght_sig;


endmodule
