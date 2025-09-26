module input_DAC
(
	clk,		
    rstn,	
	start,
	SCLK,		
	IDAC,
	SRI,		
	LD,
	finish 		
);

localparam MAX_OPEN_ROW = 'd8;
localparam SETTING_T = 'd30;    // min 1us

input	clk;
input	rstn;
input	start;
input [11:0] IDAC[MAX_OPEN_ROW-1:0];

output reg 			SCLK;
output reg [MAX_OPEN_ROW-1:0]    SRI;
output reg	        LD;
output reg	      finish;

reg	[6:0]	cnt;

integer i;

always @(*)
begin
	if (start ^ finish) begin
		SCLK = clk;
	end 
	else begin
		SCLK = 'd0;
	end
end


// DAC Ctrl
always @(posedge clk or negedge rstn)
begin
	if (~rstn) begin		
		cnt     <= 'd0;
		LD		<= 'd1;
	end else
    begin
		if (start ^ finish) begin
			cnt     <= cnt + 'd1;
        end else begin
            cnt     <= 'd0;
        end
		if (cnt == 'd0) begin
            LD      <= 'd1;  
        end 		
        if (cnt == 'd11) begin
            LD      <= 'd0;
		end
		if (cnt == 'd13) begin
			LD		<= 'd1;
		end
	end
end

always @(negedge clk or negedge rstn)
begin
	if (~rstn) begin		
        SRI     <= 'd0;
        finish  <= 'd0;
	end else
    begin		
        if (cnt >= 'd1 && cnt <= 'd12) begin
            for (i = 0; i < MAX_OPEN_ROW; i = i+1) begin
				SRI[i] <= IDAC[i]['d12 - cnt];
			end			
        end	
        if (cnt == SETTING_T) begin
            finish  <= ~finish;
        end
	end
end

endmodule
