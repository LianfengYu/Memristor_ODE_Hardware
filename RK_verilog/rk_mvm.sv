module rk_mvm #(
	parameter              WIDTH = 32,
    parameter               S = 3,
    parameter               N = 3, 
    parameter               M = 2
)
(
	// clock, reset
	input clk,
	input rstn,
	input wire signed [WIDTH-1:0] i_a [(S*S-1):0],//A
	input signed [WIDTH-1:0] i_b [(S-1):0],
	input signed [WIDTH-1:0] i_c [(S-1):0],
    input signed [WIDTH-1:0] i_k [(S-1):0],//k
    input signed [WIDTH-1:0] i_x0,
    input signed [WIDTH-1:0] i_y0,
    input signed [WIDTH-1:0] i_h0,
    //output reg signed [WIDTH-1:0] o_y [S-1:0],
    //output reg o_finish_flag
	output reg signed [WIDTH-1:0] final_out,
	output reg finish_flag

);
    //INPUT
    reg signed [WIDTH-1:0] r_c [(S-1):0];  
    reg signed [WIDTH-1:0] r_c_next [(S-1):0];      
    reg signed [WIDTH-1:0] r_b [(S-1):0];  
    reg signed [WIDTH-1:0] r_y0;           
    reg signed [WIDTH-1:0] r_y0_next;
    reg signed [WIDTH-1:0] r_x0;
    reg signed [WIDTH-1:0] r_x0_next;
    reg signed [WIDTH-1:0] r_h0;
    reg signed [WIDTH-1:0] r_h0_next;
    //output
    reg finish_flag_0;
    //PE
    wire signed [WIDTH-1:0] right [(S*S-1):0];
    reg signed [WIDTH-1:0] right_initial [S-1:0];  
    wire signed [(2*WIDTH + $clog2(S) - 1):0] down [S*S-1:0]; 
    reg signed [WIDTH-1:0] down_cut [S*S-1:0];      
    //CALCULATE
    reg signed [WIDTH-1:0] r_k0 [(S-1):0]; 
    reg signed [WIDTH-1:0] r_k [(S-1):0];
	reg signed [WIDTH-1:0] r_k0_next [(S-1):0];
	reg signed [WIDTH-1:0] r_k_next [(S-1):0];
    reg signed [2*WIDTH-1:0] r_bk [(S-1):0];    //r_bk
    reg signed [(2*WIDTH + $clog2(S) - 1):0] r_bkn [(S-1):0];  //r_bkn
    reg signed [WIDTH-1:0] r_bkn_result;  //r_bkn_result  
    //reg signed [2*WIDTH+1:0] r_ch[(S-1):0]; //r_ch 
	//reg signed [2*WIDTH+1:0] r_ch_next[(S-1):0]; 
    //x        
    reg signed [2*WIDTH:0] r_x [(S-1):0];   
    reg signed [WIDTH-1:0] r_x_cut [(S-1):0]; 
    //y               
    reg signed [WIDTH:0] r_y [(N-1):0][(S-1):0];  
    //reg signed [WIDTH-1:0] r_y [(N-1):0][(S-1):0];             
    reg signed [WIDTH-1:0] r_y_cut [(N-1):0][(S-1):0];    
    //function
    reg signed [WIDTH-1:0] f_x;     
    reg signed [WIDTH-1:0] f_y;    
    reg signed [WIDTH-1:0] f_k;     
            
    reg[S:0] i_1,j_1,k_1;
    
    reg [($clog2(S)+1):0] i_cnt,k_cnt,c_cnt,d_cnt;  
    reg signed [($clog2(S)+1):0] j_cnt;
    reg i_cnt_flag,j_cnt_flag,k_cnt_flag,d_cnt_flag;   
    reg [($clog2(M*N)+1):0] r_inum,r_jnum,r_knum,r_dnum;
    reg pass_flag;      
    reg [$clog2(M*N):0]c_cnt_time;    
    reg [$clog2(M*N):0] finish_flag_cnt;  
    //reg  [(2*WIDTH+log2(S)-1):0] final_out_cut;
    reg signed [WIDTH:0] final_out_cut;  //final_out_cut

    reg [(2*WIDTH + $clog2(S)-1):0] r_zeros;

    always@(posedge clk or negedge rstn)begin
        //if((!rstn) ||(finish_flag))begin 
        //The expression in the reset condition of the 'if' statement in this 'always' block can only be a simple identifier or its negation.  
        if(!rstn)begin     
            i_cnt <= 'd0;
            i_cnt_flag <= 'd0;
            r_inum <= 'd0;
        end
        else if(finish_flag == 1'd1)begin
            i_cnt <= 'd0;      
            i_cnt_flag <= 'd0; 
            r_inum <= 'd0;     
        end
        else if (i_cnt == (2*$unsigned(S)+2))begin
            i_cnt <= 'd0;
            r_inum <= r_inum + 1'b1;
			i_cnt_flag <= i_cnt_flag;
        end
        else if (r_inum == $unsigned(N))begin
            i_cnt <= 'd0;
			i_cnt_flag <= i_cnt_flag;
			r_inum <= r_inum;
        end
        else begin 
            i_cnt <= i_cnt + 1'b1;
			r_inum <= r_inum;
            if((i_cnt >= 'd0) && (i_cnt < $unsigned(S)))begin
                i_cnt_flag <= 1'b1;
            end
            else begin
                i_cnt_flag <= 'd0;
            end
        end
    end

    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            c_cnt <= 'd0;
            c_cnt_time <= 'd0;
        end
        else if(finish_flag == 1'b1)begin
            c_cnt <= 'd0;      
            c_cnt_time <= 'd0; 
        end
        else if ((i_cnt == 2*$unsigned(S))&&(c_cnt_time < $unsigned(N)))begin
            c_cnt <= c_cnt +1'b1;
            c_cnt_time <= c_cnt_time + 1'b1;
        end
        else if(c_cnt_time == $unsigned(N))begin
            c_cnt <= 'd0;
			c_cnt_time <= c_cnt_time;
        end
        else begin
            c_cnt <= c_cnt;
            c_cnt_time <= c_cnt_time;
        end
    end    
        
    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            j_cnt <= 'd0;
            j_cnt_flag <= 'd0;
            r_jnum <= 'd0;
        end
        else if(finish_flag == 1'b1)begin 
            j_cnt <= 'd0;     
            j_cnt_flag <= 'd0;
            r_jnum <= 'd0;                                    
        end                            
        else if((i_cnt > $unsigned(S)-1)&&(i_cnt < 2*$unsigned(S))&&(j_cnt < $signed(S)))begin
            j_cnt <= j_cnt + $signed(1);
            j_cnt_flag <= 1'b1;
			r_jnum <= r_jnum;
        end
        else if((j_cnt == $signed(S))&&((i_cnt > 2*$unsigned(S)-2)||(i_cnt < $unsigned(S)-1)))begin
            j_cnt <= 'd0;
            j_cnt_flag <= 'd0;
            r_jnum <= r_jnum + 1'b1;
        end
        else if (r_jnum == $unsigned(N))begin
            j_cnt <= 'd0;
			r_jnum <= r_jnum;
			j_cnt_flag <= j_cnt_flag;
        end
        else begin
            j_cnt <= j_cnt;
			r_jnum <= r_jnum;
            j_cnt_flag <= j_cnt_flag;
        end
    end
   
   always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            k_cnt <= 'd0;
            k_cnt_flag <= 'd0;
            r_knum <= 'd0;
        end
        else if(finish_flag == 1'b1)begin 
            k_cnt <= 'd0;     
            k_cnt_flag <= 'd0;
            r_knum <= 'd0;                                   
        end     
        else if((i_cnt > $unsigned(S))&&(i_cnt <= 2*$unsigned(S)+1)&&(k_cnt < $unsigned(S)))begin
            k_cnt <= k_cnt + 1'b1;
            k_cnt_flag <= 1'b1;
			r_knum <= r_knum;
        end
        else if((k_cnt == $unsigned(S))&&((i_cnt > 2*$unsigned(S))||(i_cnt < $unsigned(S))))begin
            k_cnt <= 'd0;
            k_cnt_flag <= 'd0;
            r_knum <= r_knum + 1'b1;
        end
        else if (r_knum == $unsigned(N))begin
            k_cnt <= 'd0;
			k_cnt_flag <= k_cnt_flag;
			r_knum <= r_knum;
        end
        else begin
            k_cnt <= k_cnt;
            k_cnt_flag <= k_cnt_flag;
			r_knum <=r_knum;
        end
    end
    
    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            d_cnt <= 'd0;
            d_cnt_flag <= 'd0;
            r_dnum <= 'd0;
        end
        else if(finish_flag == 1'b1)begin
            d_cnt <= 'd0;               
            d_cnt_flag <= 'd0;          
            r_dnum <= 'd0;              
        end                            
        //else if((i_cnt > S+2)&&(i_cnt <= 2*S+3)&&(d_cnt < S))begin
        else if((i_cnt > $unsigned(S)+2)&&(i_cnt <= 2*$unsigned(S)+2)&&(d_cnt < $unsigned(S)))begin
            d_cnt <= d_cnt + 1'b1;
            d_cnt_flag <= 1'b1;
			r_dnum <= r_dnum;
        end
        else if((d_cnt == $unsigned(S))&&((i_cnt > 2*$unsigned(S)+2)||(i_cnt < $unsigned(S)+2)))begin
            d_cnt <= 'd0;
            d_cnt_flag <= 'd0;
            r_dnum <= r_dnum + 1'b1;
        end
        else if (r_dnum == $unsigned(N))begin
            d_cnt <= 'd0;
			r_dnum <= r_dnum;
			d_cnt_flag <= d_cnt_flag;
        end
        else begin
            d_cnt <= d_cnt;
            r_dnum <= r_dnum;
            d_cnt_flag <= d_cnt_flag;
        end
    end
    
    always@(posedge clk or negedge rstn)begin
        if(!rstn) begin
            pass_flag <= 1'b0;
        end
        else if(finish_flag == 1'b1)begin
            pass_flag <= 1'b0;
        end
        else if ((i_cnt >= $unsigned(S)+1) && (i_cnt <= 2*$unsigned(S)+2))begin
            pass_flag <= 1'b1;
        end
        else begin
            pass_flag <= 1'b0;
        end
    end
    
    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin  
            for(i_1 = $unsigned(0); i_1 < ($unsigned(S)); i_1 = i_1+$unsigned(1)) begin:loop_i1                           
                r_k0[i_1] <= 'd0;
                r_b[i_1] <= 'd0;
				r_c[i_1] <= 'd0;
            end:loop_i1
            r_x0 <= 'd0;
            r_h0 <= 'd0;
        end
        else if (finish_flag == 1'b1)begin       
            for(i_1 = $unsigned(0); i_1 < ($unsigned(S)); i_1 = i_1+$unsigned(1)) begin:loop_i2
              r_k0[i_1] <= 'd0; 
			  r_b[i_1] <= r_b[i_1];
			  r_c[i_1] <= r_c[i_1];			  
            end:loop_i2                                                                                  
        r_x0 <= 'd0;                                         
        r_h0 <= 'd0;                                         
        end                                                       
        else begin
            for(i_1 = $unsigned(0); i_1 < $unsigned(S); i_1 = i_1+$unsigned(1))begin:loop_i3
                r_k0[i_1] <= i_k[i_1];
                r_b[i_1] <= i_b[i_1];
                r_c[i_1] <= i_c[i_1];
            end:loop_i3
            r_x0 <= i_x0;
            r_h0 <= i_h0;
        end
    end
    
    always@(posedge clk or negedge rstn)begin
        if((!rstn))begin
			r_y0 <= 'd0;
		end
		else if((finish_flag == 1'b1) && (finish_flag_cnt == $unsigned(M)))begin
            r_y0 <= 'd0;
        end
        else begin
            r_y0 <= i_y0;   
        end
    end
    
    genvar i,j,k ;
    
    always@(posedge clk or negedge rstn)begin
       if(!rstn) begin
            r_zeros <= 'd0;
        end
        else begin   
            r_zeros <= 'd0;
        end
    end

    always@(posedge clk or negedge rstn)begin
        if(!rstn) begin
            for(i_1 = $unsigned(0); i_1 < $unsigned(S); i_1 = i_1+$unsigned(1))begin:loop_i4
                r_k[i_1] <= 'd0;
            end:loop_i4
        end
        else if(finish_flag == 1'b1)begin
            for(i_1 = $unsigned(0); i_1 < $unsigned(S); i_1 = i_1+$unsigned(1))begin:loop_i5
                r_k[i_1] <= 'd0;                     
            end:loop_i5                                    
        end
        else if(pass_flag == 1'b1)begin
            r_k[d_cnt-1] <= f_k;
        end
        else if((i_cnt >= 'd0)&&(i_cnt < $unsigned(S)) && (c_cnt > 'd0))begin
             r_k[i_cnt] <= 'd0;
        end
        else begin
            r_k[d_cnt - 1] <= r_k[d_cnt - 1];
        end
    end   
    	
    always@(posedge clk or negedge rstn)begin
        if(!rstn) begin
            for(i_1 = $unsigned(0); i_1 < $unsigned(S); i_1 = (i_1 + $unsigned(1))) begin:loop_i6
                right_initial[i_1] <= 'd0;
            end:loop_i6
        end
        else if(finish_flag == 1'b1)begin
            for(i_1 = $unsigned(0); i_1 < $unsigned(S); i_1 = (i_1 + $unsigned(1))) begin:loop_i7
                right_initial[i_1] <= 'd0;             
            end:loop_i7 
        end   
        else if((i_cnt_flag == 1'b1) && (r_inum == 'd0))begin
            for (i_1 = $unsigned(0); i_1 < $unsigned(S); i_1 = i_1+$unsigned(1)) begin:loop_first       
               right_initial[i_1] <= r_k0_next[i_1]; 
            end:loop_first
        end                                 
        else begin  
            if((i_cnt >= 0)&&(i_cnt < $unsigned(S)) && (c_cnt > 0)) begin              
                right_initial[i_cnt] <= r_k_next[i_cnt];            
            end
            else begin
                right_initial[i_cnt] <= right_initial[i_cnt];       
            end            
        end
    end

    always @(posedge clk or negedge rstn)begin
        if(!rstn)begin
            for(j_1 = 0; j_1 < $unsigned(S) ; j_1 = j_1 + 1)begin
               //r_ch[j_1] <= 'd0;
               r_x[j_1] <= 'd0; 
            end
        end
        else if((i_cnt >= 1)&&(i_cnt < $unsigned(S)+1)) begin
            //r_ch[i_cnt-1] <= r_c[i_cnt-1] *r_h0_next;            
            //r_x[i_cnt-1] <= r_x0 + r_ch[i_cnt-1];	
			r_x[i_cnt-1] <= r_x0_next + r_c_next[i_cnt-1] *r_h0_next;			
        end
        else begin
            //r_ch[i_cnt] <= 'd0;
            r_x[i_cnt] <= 'd0;
        end
    end
    
    always @(posedge clk or negedge rstn)begin  
        if(!rstn)begin
            for(j_1 = $unsigned(0); j_1 < $unsigned(N) ; j_1 = j_1 + $unsigned(1))begin  
                for(i_1 = $unsigned(0); i_1 < $unsigned(S);i_1 = i_1 + $unsigned(1) )begin
                     r_y[j_1][i_1] <= 'd0;
                end
            end
        end
        else if(j_cnt != 'sd0)begin    
            r_y[c_cnt][j_cnt-1] <= r_y0_next + (down_cut[S*(S-1)+j_cnt-1] * r_h0_next);   
        end    
        else begin
            r_y[c_cnt][j_cnt-1] <= 'd0;
        end
    end
    
    always@(*)begin
        for(j_1 = 'd0; j_1 < $unsigned(N) ; j_1 = j_1 + 1)begin:loop_j3  
            for(i_1 = 'd0; i_1 < $unsigned(S);i_1 = i_1 + 1 )begin:loop_i8    
                 r_y_cut[j_1][i_1][WIDTH-1:0] = r_y[j_1][i_1][WIDTH:1];
		 //r_y_cut[j_1][i_1][WIDTH-1:0] = r_y[j_1][i_1][WIDTH-1:0];
                 //r_x_cut[j_1][i_1][WIDTH-1:0] = r_x[j_1][i_1][2*WIDTH : 2*WIDTH-31];//[2*WIDTH :0] r_x [(S-1):0];
             end:loop_i8        
         end:loop_j3
         
         for(i_1 = 'd0; i_1 < $unsigned(S);i_1 = i_1 + 1 )begin:loop_i9    
            r_x_cut[i_1][WIDTH-1:0] = r_x[i_1][2*WIDTH : 2*WIDTH-31];//[2*WIDTH :0] r_x [(S-1):0];
            r_c_next[i_1] = r_c[i_1];
            r_k_next[i_1] = r_k[i_1];
            //r_ch_next[i_1] = r_ch[i_1];
            r_k0_next[i_1] = r_k0[i_1];
         end:loop_i9
         
         for(k_1 = 'd0; k_1 < ($unsigned(S)*$unsigned(S)) ; k_1 = k_1 + 1)begin:loop_k1
            down_cut[k_1][31:0] = down[k_1][(2*WIDTH+$clog2(S)-1):(2*WIDTH+$clog2(S)-32)];//[(2*WIDTH + log2(S)-1):0] S*S+S
        end:loop_k1
        
        r_x0_next = r_x0;
        r_y0_next = r_y0;
        r_h0_next = r_h0;
     end
         
    
    always@(*)begin 
        //if((!rstn) || ( (finish_flag == 1) && (finish_flag_cnt < M)) ) begin
        if(!rstn)begin
            for(i_1 = $unsigned(0); i_1 < $unsigned(S); i_1 = i_1+$unsigned(1)) begin:loop_i10 
                r_bk[i_1] = 'd0;
                r_bkn[i_1] = 'd0;
            end:loop_i10
            final_out_cut = 'd0;
            finish_flag_0 = 'd0;
        end
        else if((finish_flag == 1'b1)&& (finish_flag_cnt < $unsigned(M)))begin
            for(i_1 = 'd0; i_1 < $unsigned(S); i_1 = i_1+1'b1) begin:loop_i11
                r_bk[i_1] = 'd0;                              
                r_bkn[i_1] = 'd0;                             
            end:loop_i11                                                                                                                                   
            final_out_cut = 'd0;                              
            finish_flag_0 = 'd0; 
        end
        else if(r_dnum == ($unsigned(N)) ||(finish_flag_cnt == $unsigned(M)))begin
            for(i_1 = 'd0; i_1 < S; i_1 = i_1+1'b1) begin:loop_i12 
                //r_bk[i_1] = r_b[i_1] * r_k[i_1];
                if(i_1 == 'd0)
                    //r_bkn[0] = r_bk[0];
					r_bkn[0] = r_b[0] * r_k[0];
                else
                    r_bkn[i_1] = r_b[i_1] * r_k[i_1] + r_bkn[i_1 - 1]; 
                    
            end:loop_i12
            r_bkn_result = r_bkn[S-1][(2*WIDTH + $clog2(S) - 1):(2*WIDTH + $clog2(S) - 32)];
            final_out_cut = r_y0 +r_bkn_result * r_h0;          
            finish_flag_0 = 1'b1;
        end
        else begin
            for(i_1 = $unsigned(0); i_1 < $unsigned(S); i_1 = i_1+$unsigned(1)) begin:loop_i13 
                r_bk[i_1] = 'd0;
                r_bkn[i_1] = 'd0;
            end:loop_i13
            final_out_cut = 'd0;
            finish_flag_0 = 'd0;
        end
    end
	
    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            final_out <= 'd0;
        end
        else begin
            final_out[WIDTH-1:0] <= final_out_cut[WIDTH:1];
        end
    end   
	
	always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            finish_flag <= 'd0;
        end
        else begin
            finish_flag <= finish_flag_0;
        end
    end
	
    always@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            finish_flag_cnt <= 'd0;
        end
        else if((finish_flag_0 == 1'b1) && (finish_flag_cnt < $unsigned(M)))begin
            finish_flag_cnt <= finish_flag_cnt + 1'b1;
        end
        else begin
            finish_flag_cnt <= finish_flag_cnt;
        end
    end

    always@(posedge clk or negedge rstn)begin 
        if(!rstn)begin
            f_x <= 'd0;
            f_y <= 'd0;
        end
        else if(k_cnt_flag == 1'b1)begin                     
            f_x <= r_x_cut[k_cnt - 1'b1];
            f_y <= r_y_cut[r_inum][k_cnt - 1'b1];
        end		
        else begin
            f_x <= f_x; 
            f_y <= f_y; 
        end
    end
    

    functiond_input #(
		.WIDTH(WIDTH)
	) function_input_mult
	(
        .clk(clk),
        .rstn(rstn),
        //.begin_flag(k_cnt_flag),
        .i_x(f_x),
        .i_y(f_y),
        .o_y(f_k)
    ); 
           
     generate         
                PE #(
                    .WIDTH(WIDTH),
                    .N(N),
                    .S(S)
                ) pe_0
                (
                    .clk(clk),
                    .rstn(rstn),               
                    // input
                    .i_a(i_a[0]),
                    .i_k(right_initial[0]),
                    .i_partial_sum(r_zeros), 
                    // output
                    .o_down(down[0]),
                    .o_right(right[0])
                ); 
    endgenerate
    
    
    generate  
            for (i = 1; i < S; i = i+1) begin
                PE #(
                    .WIDTH(WIDTH),
                    .N(N),
                    .S(S)
                ) pe_1
                (
                    .clk(clk),
                    .rstn(rstn),               
                    // input
                    .i_a(i_a[(S*i)]),
                    .i_k(right[i-1]),
                    .i_partial_sum(r_zeros), 
                    // output
                    .o_down(down[i]),
                    .o_right(right[i])
                ); 
            end
    endgenerate
    
    generate  
            for (i = 1; i < S; i = i+1) begin
                PE #(
                    .WIDTH(WIDTH),
                    .N(N),
                    .S(S)
                ) pe_2
                (
                    .clk(clk),
                    .rstn(rstn),               
                    // input
                    .i_a(i_a[i]),
                    .i_k(right_initial[i]),
                    .i_partial_sum(down[(i-1)*S]), 
                    // output
                    .o_down(down[i*S]),
                    .o_right(right[S*i])
                ); 
            end
    endgenerate
    
    generate 
        for (j = 0; j < S-1; j = j+1) begin 
            for (i = 0; i < S-1; i = i+1) begin
                PE #(
                    .WIDTH(WIDTH),
                    .N(N),
                    .S(S)
                ) pe_3
                (
                    .clk(clk),
                    .rstn(rstn),               
                    // input
                    .i_a(i_a[S*(i+1)+j+1]),
                    .i_k(right[S*(j+1)+i]),
                    .i_partial_sum(down[S*j+i+1]),
                    // output
                    .o_down(down[S*(j+1)+i+1]),
                    .o_right(right[S*(j+1)+i+1])
                ); 
            end
        end 
    endgenerate 
  
endmodule

