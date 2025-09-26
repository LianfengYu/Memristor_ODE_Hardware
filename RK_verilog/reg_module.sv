`timescale 1ns / 1ps
module reg_module#(
	parameter              WIDTH = 32,
    parameter               S = 3,
    parameter               N = 3, 
    parameter               M = 3
)(
    input clk,
	input i_start,
	input signed [WIDTH-1:0] i_a [(S*S-1):0],
	input signed [WIDTH-1:0] i_b [(S-1):0],
	input signed [WIDTH-1:0] i_c [(S-1):0],
    input signed [WIDTH-1:0] i_k [(S-1):0],
    input signed [WIDTH-1:0] i_x0,
    input signed [WIDTH-1:0] i_y0,
    input signed [WIDTH-1:0] i_h0,
    //output
    output reg signed [WIDTH-1:0] o_a [(S*S-1):0],
    output reg signed [WIDTH-1:0] o_b [(S-1):0],           
    output reg signed [WIDTH-1:0] o_c [(S-1):0],           
    output reg signed [WIDTH-1:0] o_k [(S-1):0], 
    output reg signed [WIDTH-1:0] o_x0,                 
    output reg signed [WIDTH-1:0] o_y0,                 
    output reg signed [WIDTH-1:0] o_h0

             
    );
    
    reg [S:0] i,j;
    always@(posedge clk or negedge i_start)begin
        if(!i_start)begin
            for(i = 'd0; i < ($unsigned(S)*$unsigned(S)); i = i+1)begin
                o_a[i] <= 'd0;
            end
            for(j = 'd0; j < $unsigned(S); j = j+1)begin
                o_b[j] <= 'd0;
                o_c[j] <= 'd0;
                o_k[j] <= 'd0;
            end
            o_x0 <= 'd0;
            o_y0 <= 'd0;
            o_h0 <= 'd0;
        end
        else begin
            for(i = 'd0; i < ($unsigned(S)*$unsigned(S)); i = i+1)begin
                o_a[i] <= i_a[i];
            end
            for(j = 'd0; j < $unsigned(S); j = j+1)begin
                o_b[j] <= i_b[j];
                o_c[j] <= i_c[j];
                o_k[j] <= i_k[j];
            end
            o_x0 <= i_x0;
            o_y0 <= i_y0;
            o_h0 <= i_h0;
        end
    end


endmodule

