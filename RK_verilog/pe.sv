`timescale 1ns / 1ps
module PE #(
    parameter               WIDTH = 32,
	parameter	            N = 3,
    parameter               S = 3		
)
(

	// clock, reset
	input							clk,
	input							rstn,

    // input
    input signed [WIDTH-1:0]			 i_a,	//A
    input signed [WIDTH-1:0]             i_k,	//k
    input signed [(2*WIDTH + $clog2(S)-1):0]  i_partial_sum,
	// output
    output reg signed [(2*WIDTH + $clog2(S)-1):0]     o_down,
    output reg signed [WIDTH-1:0]	    o_right
	
);

    //reg signed [(2*WIDTH + $clog2(S)-1):0]    r_ak;	        
    reg signed [(2*WIDTH + $clog2(S)-1):0]    r_partial_sum;
    
    always @(*) 
    begin
        //r_ak = i_a * i_k;
        o_down = r_partial_sum + i_a * i_k;  
    end
	
	always @(posedge clk or negedge rstn) begin
	if (!rstn) begin
        r_partial_sum <= 'd0;
        o_right <= 'd0;
	end else begin
	    r_partial_sum <= i_partial_sum;
        o_right <= i_k;
	end
	end
 
endmodule


