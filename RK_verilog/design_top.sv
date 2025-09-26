
module design_top#(
	parameter              WIDTH = 32,
    parameter               S = 3,
    parameter               N = 3, 
    parameter               M = 1000
)
(
	// clock, reset
	input clk,
	input wire rstn,
	input signed [WIDTH-1:0] i_a [(S*S-1):0],
	input signed [WIDTH-1:0] i_b [(S-1):0],
	input signed [WIDTH-1:0] i_c [(S-1):0],
    input signed [WIDTH-1:0] i_k [(S-1):0],
    input signed [WIDTH-1:0] i_x0,
    input signed [WIDTH-1:0] i_y0,
    input signed [WIDTH-1:0] i_h0,

	output reg o_finish_flag,
    output reg signed [WIDTH-1:0] o_y 

    );
    
   // reg [2*WIDTH-1:0] r_y ;
    reg signed [WIDTH-1:0] r_yb;   
    wire signed [WIDTH-1:0] r_ya;
    reg finish_flag;
  
    reg [$clog2(N*M)+3:0] cnt_i;
    reg [$clog2(N*M)+3:0] i_num;
    
    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            cnt_i <= 'b0;
            i_num <= 'b0; 
        end
        else if(finish_flag == 1'b1)begin
            cnt_i <= 'b0;
        end
        else if(cnt_i == ((($unsigned(N))*(2*$unsigned(S)+3)+1)) && (i_num < $unsigned(M)))begin
            cnt_i <= 'b0;
            i_num <= i_num + 1'b1;
        end
        else if(i_num == $unsigned(M))begin
            cnt_i <= cnt_i;
        end
        else begin
            cnt_i <= cnt_i +1'b1;
            i_num <= i_num;
        end
    end

    integer i;
    
    always @(posedge clk or negedge rstn)begin
        if(!rstn)begin
            o_y <= 'b0;
	        o_finish_flag <= 'b0;
        end
        else if((cnt_i == 1'b1) && (i_num == 0))begin
            r_yb <= i_y0;
            o_y <= o_y;
            o_finish_flag <= o_finish_flag;
        end
        else if((finish_flag == 1'b1) && (i_num < $unsigned(M)))begin      
            r_yb <= r_ya;
            o_finish_flag <= o_finish_flag;
        end
        else if((finish_flag == 1'b1) && (i_num == $unsigned(M)))begin 
            o_y <= r_ya;
            o_finish_flag <= 1'b1;
        end
        else begin 
            r_yb <= r_yb;
            o_y <= o_y; 
            o_finish_flag <= o_finish_flag;
        end
    end
    

    rk_mvm #(
        .WIDTH(WIDTH),    
        .S(S),
        .N(N),
        .M(M)
    ) rk_mvm0
    (
        .clk(clk),
        .rstn(rstn),
        .i_a(i_a),
        .i_b(i_b),
        .i_c(i_c),
        .i_x0(i_x0),
        .i_y0(r_yb),
        .i_h0(i_h0),
        .i_k(i_k),
        
        .final_out(r_ya),
        .finish_flag(finish_flag)
	
    );
    
    
endmodule

