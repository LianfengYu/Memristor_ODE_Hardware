
module functiond_input#(
	parameter WIDTH = 32
)
(   input clk,
    input rstn,
    input signed [WIDTH-1:0] i_x,
    input signed [WIDTH-1:0] i_y,
    //input begin_flag,
    output reg signed [WIDTH-1:0] o_y
    );
    
    //reg signed [WIDTH-1:0] y_cut;
    
    always @(posedge clk or negedge rstn) begin
        if(!rstn)begin
            o_y <= 'd0;
        end
        //else if(begin_flag == 1'b1)begin 
        //    o_y <= i_y + i_x;
	//end
        else begin   
            o_y <= i_y + i_x;
	    end
    end
    
endmodule

