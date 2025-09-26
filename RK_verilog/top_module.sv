
module top_module#(
	parameter              WIDTH = 32,
    parameter               S = 2,
    parameter               N = 2, 
    parameter               M = 4000
)
(
	// clock, reset
	input clk,
	input i_start,
	input wire rstn,
	input signed [WIDTH-1:0] i_a [(S*S-1):0],
	input signed [WIDTH-1:0] i_b [(S-1):0],
	input signed [WIDTH-1:0] i_c [(S-1):0],
    input signed [WIDTH-1:0] i_k [(S-1):0],
    input signed [WIDTH-1:0] i_x0,
    input signed [WIDTH-1:0] i_y0,
    input signed [WIDTH-1:0] i_h0,

	output wire o_finish_flag,
    output wire signed [WIDTH-1:0] o_y

    );
    
    wire signed [WIDTH-1:0] r_a [(S*S-1):0];
    wire signed [WIDTH-1:0] r_b [(S-1):0];             
    wire signed [WIDTH-1:0] r_c [(S-1):0];             
    wire signed [WIDTH-1:0] r_k [(S-1):0];
    wire signed [WIDTH-1:0] r_x0;                   
    wire signed [WIDTH-1:0] r_y0;                   
    wire signed [WIDTH-1:0] r_h0;                   
    
    reg_module#(
                .WIDTH(WIDTH),
                .N(N),
                .S(S),
                .M(M)
               )
               reg_data_trans(
               .clk(clk),
               .i_start(i_start),           
               .i_a(i_a), 
               .i_b(i_b), 
               .i_c(i_c), 
               .i_k(i_k), 
               .i_x0(i_x0),
               .i_y0(i_y0),
               .i_h0(i_h0),
               
               .o_a(r_a), 
               .o_b(r_b), 
               .o_c(r_c),
               .o_k(r_k), 
               .o_x0(r_x0),
               .o_y0(r_y0),
               .o_h0(r_h0)
                                 
               );
               
    design_top#(
                .WIDTH(WIDTH),
                .N(N),
                .S(S),
                .M(M)
               )design_top_0(
               .clk(clk),
               .rstn(rstn),
               .i_a(r_a), 
               .i_b(r_b), 
               .i_c(r_c), 
               .i_k(r_k), 
               .i_x0(r_x0),
               .i_y0(r_y0),
               .i_h0(r_h0),
		        .o_finish_flag(o_finish_flag),
               .o_y(o_y)
                       
               );               
endmodule

