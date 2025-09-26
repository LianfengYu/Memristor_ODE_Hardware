module read_ADC
(
	clk,
	rstn,			
    start,     
	SCLK_AD,  
	SDO,		
	CNVST,	        
    ADC,	
    finish,
);

localparam SLEEP = 'd17;			// = 17 * 200ns = 3.4us
localparam CONVERSION = 'd20;		// = 25 * 200ns = 5us
localparam WAIT = 'd42;	
localparam SAMPLE_TIME = 'd1;	

input 	clk;
input	rstn;
input   start;

input [7:0]	SDO;

output reg	SCLK_AD;

output reg	CNVST;
output reg [15:0]   ADC[7:0];
output reg	finish;

reg [6:0]	ADC_cnt;
reg [4:0]	ADC_BIT;
reg [15:0]	ADC_SAMPLE[7:0];
reg [6:0] 	sample_addr;
reg [15:0]	ADC_buf[7:0];

integer i;

always @(*)
begin
	if (ADC_cnt < SLEEP) begin
		SCLK_AD = 'd0;
	end 
	else begin
		SCLK_AD = clk;
	end
end

// ADC Ctrl
always @(negedge clk or negedge rstn)
begin
	if (~rstn) begin		
		CNVST <= 'd0;
		ADC_cnt <= 'd0;
		sample_addr <= 'd0;
		finish <= 'd0;
		for (i = 0; i < 8; i = i+1) begin
			ADC[i] <= 'd0;
			ADC_buf[i] <= 'd0;
		end
	end else
	begin
		if (start ^ finish) begin	
			if (sample_addr < SAMPLE_TIME) begin	
				if (ADC_cnt < WAIT) begin		
					ADC_cnt <= ADC_cnt + 'd1;
					if (ADC_cnt < CONVERSION) begin
						CNVST <= 'd1;			
					end		
					else if (ADC_cnt == CONVERSION) begin
						CNVST <= 'd0;			
					end
				end
				else if (ADC_cnt == WAIT) begin
					sample_addr <= sample_addr + 'd1;
					ADC_cnt <= 'd0;		
					for (i = 0; i < 8; i = i+1) begin
						ADC_buf[i] <= ADC_SAMPLE[i];
					end
				end      	
			end
			else begin				
				for (i = 0; i < 8; i = i+1) begin
					ADC[i] <= ADC_buf[i];
				end
				finish <= ~finish;	
				sample_addr <= 'd0;	
			end
		end
	end
end

always @(posedge clk or negedge rstn)
begin
	if (~rstn) begin		
		ADC_BIT <= 'd0;
		for (i = 0; i < 8; i = i+1) begin
			ADC_SAMPLE[i] <= 'd0;	
		end
	end 
	else begin	
		if (ADC_cnt > CONVERSION) begin			
			if (ADC_BIT <= 'd15) begin
				ADC_BIT <= ADC_BIT + 'd1;
				for (i = 0; i < 8; i = i+1) begin
					ADC_SAMPLE[i][15-ADC_BIT] <= SDO[i];
				end
			end 
			else begin			
				if (ADC_cnt == WAIT) begin
					ADC_BIT <= 'd0;
				end
				else begin
					ADC_BIT <= ADC_BIT;
				end
			end
		end	
	end
end

endmodule
