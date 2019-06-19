`include "tb_tasks.sv"

task CheckAuth;
    //////////////////
    // Auth testing //
    //////////////////

    // No startup with bad command
    SendCmd(8'h66);
    if(iDUT.pwr_up == 1'b1)
        $stop();

    // Starts up
    SendCmd(8'h67);
    if(iDUT.pwr_up == 1'b0)
        $stop();

    // Doesn't turn off when rider is on the segway
    force iDUT.rider_off = 1'b0;
    SendCmd(8'h73);
    if(iDUT.pwr_up == 1'b0)
        $stop();
    if(iDUT.iAUTH.state != 2'b10) // PWR2 state
        $stop();

    // Turns off when rider steps off
    @(negedge clk);
    force iDUT.rider_off = 1'b1;
    @(negedge  clk);
    if(iDUT.iAUTH.state != 2'b00) // OFF state
        $stop();


    SetAuthState(2'b01); // PWR1 state
    if(iDUT.iAUTH.state != 2'b01)
        $stop();

    // Stays in PWR1 state when sent invalid command
    SendCmd(8'h00);
    if(iDUT.iAUTH.state != 2'b01) // PWR1 state
        $stop();

    // Turns off when rider_off is true and send 's'
    SendCmd(8'h73);
    if(iDUT.pwr_up == 1'b1)
        $stop();

    force iDUT.rider_off = 1'b0;
    SetAuthState(2'b10);

    // Stays in PWR2 when sent invalid command
    SendCmd(8'h66);
    if(iDUT.iAUTH.state != 2'b10) // PWR2
        $stop();

    // Goes back to PWR1 when sent 'g'
    SendCmd(8'h67);
    if(iDUT.iAUTH.state != 2'b01)
        $stop();

    release iDUT.rider_off;


    $display("Auth tests pass");

endtask

task CheckPWM;
input [10:0] duty;
int i,j;

    RandomWait(12'h800);

    j = 0;
    force iDUT.iMTR.lft_spd = duty;
    for(int i = 0; i < 2048; i = i + 1) begin
        @(posedge clk);
        if(iDUT.iMTR.lft_sig) j = j + 1;
    end
    if(j != duty)
        $stop();

    $display("PWM test passed");

endtask

task CheckPID;
input [15:0] lean;

    rider_lean = 16'h0000;
    SendCmd(8'h67);
    repeat(50) @(posedge clk);

    rider_lean = lean;
    repeat(1000000) @(posedge clk);

    rider_lean = 16'h0000;
    repeat(1000000) @(posedge clk);

    $display("Look at waveform: theta_platform in iPHYS");
endtask

