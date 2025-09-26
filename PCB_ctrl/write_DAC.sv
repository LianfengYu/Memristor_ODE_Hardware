module write_DAC
(
    clk,
	rstn,			
    start,   
    pulse_h,					
	sync,				
	Din,				
    finish
);

localparam RELAX_TIME       = 'd36;       // = 15 * 100ns = 15us

input   clk;
input	rstn;
input   start;
input [7:0] pulse_h;

output reg	sync;
output reg	Din;
output reg	finish;

wire [7:0]    DAC;

reg	[6:0]	DAC_cnt;

assign DAC = pulse_h;

// DAC Ctrl
always @(posedge clk or negedge rstn)
begin
	if (~rstn) begin		
		sync	<= 'd1;
		DAC_cnt <= 'd0;
        Din     <= 'd0;
	end else
    begin
		if (start ^ finish) begin
			DAC_cnt <= DAC_cnt + 'd1;
        end else begin
            sync	<= 'd1;
            DAC_cnt <= 'd0;
            Din     <= 'd0;
        end       
        if (DAC_cnt == 'd1) begin
            sync	<= 'd0;
        end 		
        if (DAC_cnt == 'd17) begin
            sync	<= 'd1;				
        end	 

        if (DAC_cnt >= 'd1 && DAC_cnt <= 'd2) begin
            Din	<= 'd0;     // mode choose
        end 		
        else if (DAC_cnt >= 'd3 && DAC_cnt <= 'd10) begin
            Din	<= DAC['d10-DAC_cnt];				
        end	 
        else if (DAC_cnt >= 'd11) begin
            Din <= 'd0;
        end
        if (DAC_cnt == RELAX_TIME) begin
            finish <= ~finish;
        end
	end
end

endmodule
