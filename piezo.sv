module piezo(clk, rst_n, norm_mode, ovr_spd, batt_low, sound, sound_n);
    input clk, rst_n; // clock is 50MHz
    input norm_mode, ovr_spd, batt_low;

    output reg sound;
    output sound_n;

    assign sound_n = ~sound;


    wire S, R;
    wire S_norm, S_ovr, S_batt;
    wire R_norm, R_ovr, R_batt;
    reg [26:0] count;

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            count <= 27'h0000000;
        else if(count == 27'h5f5e100) //Approximately 2 second counter
            count <= 27'h0000000;
        else
            count <= count + 1;

	// Beeps once every 2 seconds, low frequency
    assign S_norm = norm_mode & (count[26:22] == 5'b00001) & !count[16];
    assign R_norm = !norm_mode | (count[26:22] != 5'b00001) | count[16];

	// Sounds god awful whenever you're going too fast
    assign S_ovr = ovr_spd & !count[13] & count[19];
    assign R_ovr = !ovr_spd | count[13];

	// Beeps twice in a row every two seconds, higher frequency
    assign S_batt = batt_low & !count[15] & (count[26:25] == 2'b00) & (count[23:22] == 2'b01);
    assign R_batt = !batt_low | count[15];

	// Only asserts S_norm when it's fully normal operatoin
	// Asserts S_ovr excluding when batt_low is signalling
    assign S = (S_norm & !ovr_spd & !batt_low) | (S_ovr & !((count[26:25] == 2'b00) & (count[23:22] == 2'b01) & batt_low)) | S_batt;
    // Only shuts off when they all need to shut off
	assign R = R_norm & R_ovr & R_batt;

	// Sort of but not really an SR-FF
    always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            sound <= 0;
        else if(R)
            sound <= 0;
        else if(S)
            sound <= 1;
        else
            sound <= sound;
    end

endmodule
