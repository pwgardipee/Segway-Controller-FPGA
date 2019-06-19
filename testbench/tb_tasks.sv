task Initialize;
    clk = 0;
    RST_n = 0;

    // Initialize to default values
    cmd = 8'h00;
    send_cmd = 0;
    rider_lean = 14'h0000;
    left_load = 12'h000;
    right_load = 12'h000;
    batt = 12'h000;

    repeat(2) @(negedge clk)
    RST_n = 1;
endtask

task RandomWait;
input [31:0] max;

    repeat($urandom_range(max)) @(posedge clk);

endtask

task SendCmd;
input [7:0] send;

    cmd = send;
    @(posedge clk);
    send_cmd = 1'b1;
    @(posedge clk);
    send_cmd = 1'b0;
    @(posedge cmd_sent);
    @(posedge iDUT.iAUTH.rdy);
    repeat(2) @(negedge clk);

endtask

task EnableSteer;
    left_load = 12'h200;
    right_load = 12'h200;
    repeat(2**16+2**15) @(posedge clk);
endtask

task SetLeanQuick;
input [15:0] lean;

    rider_lean = lean;
    repeat(100000) @(posedge clk);
endtask

task SetLean;
input [15:0] lean;

    rider_lean = lean;
    repeat(1000000) @(posedge clk);
endtask

task SetAuthState;
input [1:0] state;
    force iDUT.iAUTH.next_state = iDUT.iAUTH.next_state.first(); // OFF state
    force iDUT.iAUTH.next_state = iDUT.iAUTH.next_state.next(state);
    repeat(2) @(posedge clk);
    release iDUT.iAUTH.next_state;

endtask

task ForceSendInert;
input [16:0] iAZ, iPTCH;

    force iPHYS.ptch_rate = iPTCH;
    force iPHYS.az = iAZ;

    force iDUT.INT = 1'b1;
    repeat(2) @(posedge clk);
    release iDUT.INT;

    @(posedge iDUT.vld);
    repeat(2) @(posedge clk);
    if(iDUT.iININT.AZ != iAZ)
        $stop();
    if(iDUT.iININT.ptch_rt != iPTCH)
        $stop();

    release iPHYS.az;
    release iPHYS.ptch_rate;

    $display("Successfully sent data to inertial interface");

endtask

task ForceSendADC;
input [11:0] iLEFT, iRGHT, iBATT;

    left_load = iLEFT;
    right_load = iRGHT;
    batt = iBATT;

    // Read from, all 3 ADCs in order
    force iDUT.iA2DINT.nxt = 1'b1;
    @(posedge clk);
    release iDUT.iA2DINT.nxt;
    @(posedge iDUT.iA2DINT.update);
    @(negedge iDUT.iA2DINT.update);

    force iDUT.iA2DINT.nxt = 1'b1;
    @(posedge clk);
    release iDUT.iA2DINT.nxt;
    @(posedge iDUT.iA2DINT.update);
    @(negedge iDUT.iA2DINT.update);

    force iDUT.iA2DINT.nxt = 1'b1;
    @(posedge clk);
    release iDUT.iA2DINT.nxt;
    @(posedge iDUT.iA2DINT.update);
    @(negedge iDUT.iA2DINT.update);

    //iDUT.iA2DINT
    if(iDUT.iA2DINT.lft_ld != iLEFT)
        $stop();
    if(iDUT.iA2DINT.rght_ld != iRGHT)
        $stop();
    if(iDUT.iA2DINT.batt != iBATT)
        $stop();

    $display("Successfully sent data to ADC interface");

endtask

task SendADC;
input [11:0] iLEFT, iRGHT, iBATT;

    left_load = iLEFT;
    right_load = iRGHT;
    batt = iBATT;

    repeat(3) @(posedge iDUT.iA2DINT.nxt);
    @(posedge iDUT.iA2DINT.update);
    @(negedge iDUT.iA2DINT.update);

    if(iDUT.iA2DINT.lft_ld != iLEFT)
        $stop();
    if(iDUT.iA2DINT.rght_ld != iRGHT)
        $stop();
    if(iDUT.iA2DINT.batt != iBATT)
        $stop();

    $display("Successfully sent data to ADC interface");

endtask

task TestLean;
input [15:0] lean;

int signed a, b, prev_plat;

    prev_plat = 0;

    rider_lean = lean;
    repeat(1000000) @(posedge clk);
    prev_plat = iPHYS.theta_platform;
    rider_lean = 16'h0000;
    repeat(1000000) @(posedge clk);

    if($signed(prev_plat) > $signed(16'h1000) | $signed(prev_plat) < $signed(-16'h1000))
        $stop();
    if(iPHYS.theta_platform > $signed(16'h1000) | iPHYS.theta_platform < $signed(-16'h1000))
        $stop();

    $display("Segway balanced");

endtask

task TestLoad;
input [11:0] left, right;

real lcnt, rcnt;

    lcnt = 0;
    rcnt = 0;

    left_load = left;
    right_load = right;
    repeat(2**15) @(posedge clk);

    repeat(500000) begin
        @(posedge clk);
        if(PWM_frwrd_rght | PWM_rev_rght)
            rcnt = rcnt + 1;
        if(PWM_frwrd_lft | PWM_rev_lft)
            lcnt = lcnt + 1;
    end

    if(left > right) begin
        if($signed(rider_lean) > 0)
            $display("Actual ratio: %f", rcnt/lcnt);
        else
            $display("Actual ratio: %f", lcnt/rcnt);
    end

    if(left < right) begin
        if($signed(rider_lean) > 0)
            $display("Actual ratio: %f", lcnt/rcnt);
        else
            $display("Actual ratio: %f", rcnt/lcnt);
    end


endtask

task TryTooFast;
input [15:0] lean;
int cnt;

    cnt = 0;
    SetLean(-lean);
    rider_lean = lean;

    repeat(1000000) begin
        @(posedge clk);
        if(iDUT.too_fast)
            cnt = cnt + 1;
    end

    $display("Too fast count: %d", cnt);
endtask

