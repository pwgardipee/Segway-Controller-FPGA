module PWM11(clk, rst_n, duty, PWM_sig);

input clk, rst_n;
input [10:0] duty;
output reg PWM_sig;

reg [10:0] cnt;
reg S, R;

assign S = cnt == 0;
assign R = cnt >= duty;

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        cnt <= 0;
    else
        cnt <= cnt + 1;
end

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n)
        PWM_sig <= 0;
    else if(R)
        PWM_sig <= 0;
    else if(S)
        PWM_sig <= 1;
    else
        PWM_sig <= PWM_sig;
end

endmodule
