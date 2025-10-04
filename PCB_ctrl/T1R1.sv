module T1R1
(
	clk_in,
	rstn,			

    SEL_BL,
    EN_BL,
    SEL_SL,
    EN_SL,
    OPEN_MODE,

    SRI,
    EN,
    S1A,
    S2A,
    S3A,
    S4A,
    S5A,    
    S6A,
    S7A,
    S8A,

    CS,
    SCLK,
    LD,

    SCLK_AD,	
    SDO,			
	CNVST,		

    READ_MODE,

    SA,
    A,
    B,

    SCLK_DA,
    DIN,
    SYNC,

	PULSE,			
	RE_SET,					       
       
    scl,		
    sda		
);

localparam  BL_SIZE     = 'd32;
localparam  WL_SIZE     = 'd36;
localparam  BL_WIDTH    = $clog2(BL_SIZE);
localparam  WL_WIDTH    = $clog2(WL_SIZE);

localparam  FORMING_TH = 'd6000;

localparam  WV_R    = 'd0;
localparam  WV_W    = 'd1;
localparam  MVM_A   = 'd2;
localparam  MVM_D   = 'd3;
localparam  READ    = 'd4;
localparam  MVM_H   = 'd5;

localparam RELAX_TIME       = 'd49;         // 20ns * 50 = 1us
localparam FORMING_WIDTH    = 'd250000;     // 2500000 * 20ns = 50ms
localparam FORMING_PERIOD   = 'd250100;	    // 50ms + 20ns * 100 = 2us
localparam FORMING_W        = $clog2(FORMING_PERIOD);
localparam PULSE_PERIOD     = 'd99;		    // 20ns * 100 = 2us

input	clk_in;
input	rstn;

output reg          SEL_BL;
output reg          EN_BL;
output reg [1:0]    SEL_SL;
output reg          EN_SL;
output reg          OPEN_MODE;

output reg  [7:0]   SRI;
output reg  [7:0]   EN;

output reg [1:0]    S1A;
output reg [1:0]    S2A;
output reg [1:0]    S3A;
output reg [1:0]    S4A;
output reg [1:0]    S5A;
output reg [1:0]    S6A;
output reg [1:0]    S7A;
output reg [1:0]    S8A;

output reg [2:0]    CS;
output wire	        SCLK;
output wire	        LD;

output wire         SCLK_AD;
input      [7:0]    SDO;
output wire	        CNVST;

output reg          READ_MODE;

output reg [1:0]    SA;
output reg [5:0]    A;
output reg [5:0]    B;

output wire         SCLK_DA;
output wire         DIN;
output wire         SYNC;

output reg          RE_SET;
output reg	        PULSE;

input   scl;
inout   sda;

wire	clk;
wire	clk1;
wire    o_sda;

wire [7:0]      SRI_D;

reg [3:0]       finish;         //ireg00d

wire [3:0]      start;          //reg01d
wire [2:0]      pcb_mode;       //reg02d
wire [4:0]      BL_addr;        //reg03d
wire [4:0]      WL_addr;        //reg04d
wire [7:0]      W_PULSE_H;      //reg05d
wire [7:0]      W_PULSE_DW;     //reg06d    0 >= idle, 1 >= set, 2 >= reset, 3 >= forming  
wire [7:0]      EN_CTRL;        //reg07d
wire [7:0]      first_SA;       //reg08d    S1A ~ S4A
wire [7:0]      last_SA;        //reg09d    S5A ~ S8A
wire [11:0]     IDAC[7:0];      //reg0a-15d
wire [15:0]     ADC[7:0];       
wire [31:0]     RE;             //reg16-19d
wire [4:0]      RM;             //reg1ad
wire [4:0]      CM;             //reg1bd

reg [FORMING_W-1:0]       pulse_cnt;

assign SCLK_DA = clk;

always @(*)
begin
    if (pcb_mode == WV_R || pcb_mode == MVM_A) begin
        SEL_BL  = 'd0;
        EN_BL   = 'd0;
        SEL_SL  = 'd0;
        EN_SL   = 'd1;
        EN      = EN_CTRL;
        OPEN_MODE = 'd0;
        RE_SET  = 'd0;
        SRI     = SRI_D;
    end
    else if (pcb_mode == WV_W) begin
        SEL_BL  = 'd0;
        EN_BL   = 'd1;
        SEL_SL  = 'd1;
        EN_SL   = 'd1;
        EN      = 'd0;
        OPEN_MODE = 'd0;
        SRI     = SRI_D;
        
        if (W_PULSE_DW[7:6] == 'd1 || W_PULSE_DW[7:6] == 'd3) begin
            RE_SET  = 'd1;
        end
        else if (W_PULSE_DW[7:6] == 'd2) begin
            RE_SET  = 'd0;
        end
        else begin
            RE_SET  = 'd0;
        end
    end
    else if (pcb_mode == MVM_D || pcb_mode == READ) begin
        SEL_BL  = 'd0;
        EN_BL   = 'd0;
        SEL_SL  = 'd2;
        EN_SL   = 'd1;
        EN      = RE[31:24];
        OPEN_MODE = 'd1;
        RE_SET  = 'd0;
        SRI     = RE[23:16];
    end
    else if (pcb_mode == MVM_H) begin
        SEL_BL  = 'd1;
        EN_BL   = 'd1;
        SEL_SL  = 'd0;
        EN_SL   = 'd0;
        EN      = EN_CTRL;
        OPEN_MODE = 'd0;
        RE_SET  = 'd0;
        SRI     = SRI_D;
    end
end

always @(*)
begin
    B   = 'd0;
    B[3:0]  = BL_addr[3:0];
    if (BL_addr <= 'd15) begin
        B[4]    = 'd0;
        B[5]    = 'd1;
    end
    else if (BL_addr <= 'd31) begin
        B[4]    = 'd1;
        B[5]    = 'd0;
    end

    A   = 'd0;
    A[3:0]  = WL_addr[3:0];
    if (WL_addr <= 'd15) begin
        A[4]    = 'd0;
        A[5]    = 'd1;
    end
    else if (WL_addr <= 'd31) begin
        A[4]    = 'd1;
        A[5]    = 'd0;
    end

    if (pcb_mode == MVM_A) begin
        B[4]    = 'd1;
        B[5]    = 'd1;
    end
    else if (pcb_mode == MVM_D || pcb_mode == READ) begin
        A[4]    = 'd1;
        A[5]    = 'd1;
        B[4]    = 'd1;
        B[5]    = 'd1;
    end
end

always @(*)
begin
    if (pcb_mode == MVM_D || pcb_mode == READ) begin
        S1A = RE[1:0];
        S2A = RE[3:2];
        S3A = RE[5:4];
        S4A = RE[7:6];
        S5A = RE[9:8];
        S6A = RE[11:10];
        S7A = RE[13:12];
        S8A = RE[15:14];
    end else begin
        S1A = first_SA[7:6];
        S2A = first_SA[5:4];
        S3A = first_SA[3:2];
        S4A = first_SA[1:0];
        S5A = last_SA[7:6];
        S6A = last_SA[5:4];
        S7A = last_SA[3:2];
        S8A = last_SA[1:0];
    end
end

always @(*)
begin
    CS          =       CM[2:0];
    READ_MODE   =       RM[0];
end

// Pulse Generator
always @(posedge clk_in or negedge rstn)
begin
	if (~rstn) begin		
		pulse_cnt   <= 'd0;
		PULSE       <= 'd0;
        finish[3]   <= 'd0;
	end else
    begin
		if (start[3] ^ finish[3]) begin
            if (W_PULSE_DW[7:6] == 'd3) begin           // forming
                pulse_cnt   <= pulse_cnt + 'd1;
                if (pulse_cnt == RELAX_TIME) begin
                    PULSE   <= 'd1;
                end
                else if (pulse_cnt == RELAX_TIME + FORMING_WIDTH) begin
                    PULSE <= 'd0;
                end	
                else if (pulse_cnt == FORMING_PERIOD) begin
                    pulse_cnt <= 'd0;
                    finish[3] <= ~finish[3];
                end
            end
            else if (W_PULSE_DW[7:6] == 'd1 || W_PULSE_DW[7:6] == 'd2) begin      // set/reset
                pulse_cnt <= pulse_cnt + 'd1;
                if (pulse_cnt == RELAX_TIME) begin
                    PULSE <= 'd1;
                end
                else if (pulse_cnt == RELAX_TIME + W_PULSE_DW[5:0]) begin
                    PULSE <= 'd0;
                end	
                else if (pulse_cnt == PULSE_PERIOD) begin
                    pulse_cnt <= 'd0;
                    finish[3] <= ~finish[3];
                end
            end
		end 
        else begin
            pulse_cnt <= 'd0;
        end
	end
end


PLL	PLL_inst (
	.inclk0 ( clk_in ),
	.c0 ( clk ),
	.c1 ( clk1 )
	);

read_ADC read_adc (
    .clk (clk1),
	.rstn (rstn),			
    .start (start[0]),   
    .SCLK_AD (SCLK_AD),   			
	.SDO (SDO),			
	.CNVST (CNVST),
    .ADC (ADC),	
    .finish (finish[0])
);

input_DAC input_dac (
    .clk (clk),
    .rstn (rstn),	
	.start (start[1]),
    .SCLK (SCLK),
	.IDAC (IDAC),
	.SRI (SRI_D),		
	.LD (LD),
	.finish (finish[1]) 
);

write_DAC write_dac (
    .clk (clk),
	.rstn (rstn),			
    .start (start[2]),   
    .pulse_h (W_PULSE_H),
    .sync (SYNC),
    .Din (DIN),    
    .finish (finish[2])  
);

bufif0  ( sda, 1'b0, o_sda );	// Slave's SDA IO

i2c_slave i2cs (
    .clk	(clk_in),
    .rstn	(rstn),
    .I_DEV_ADR (7'h6C),
    .isda	(sda),
    .osda	(o_sda),
    .isck	(scl),
    .ireg00d    (finish),
    .reg00d	(),
    .reg01d	(start),
    .reg02d	(pcb_mode),
    .reg03d (BL_addr),
    .reg04d	(WL_addr),
    .reg05d	(W_PULSE_H),
    .reg06d	(W_PULSE_DW),
    .reg07d	(EN_CTRL),
    .reg08d	(first_SA),
    .reg09d	(last_SA),
    .reg0ad	(IDAC[0][11:4]),
    .reg0bd	({IDAC[0][3:0], IDAC[1][11:8]}),
    .reg0cd	(IDAC[1][7:0]),
    .reg0dd	(IDAC[2][11:4]),
    .reg0ed	({IDAC[2][3:0], IDAC[3][11:8]}),
    .reg0fd	(IDAC[3][7:0]),
    .reg10d	(IDAC[4][11:4]),
    .reg11d	({IDAC[4][3:0], IDAC[5][11:8]}),
    .reg12d	(IDAC[5][7:0]),
    .reg13d	(IDAC[6][11:4]),
    .reg14d	({IDAC[6][3:0], IDAC[7][11:8]}),
    .reg15d	(IDAC[7][7:0]),
    .reg16d (RE[31:24]),
    .reg17d (RE[23:16]),
    .reg18d (RE[15:8]),
    .reg19d (RE[7:0]),
    .reg1ad (RM),
    .reg1bd (CM),
    .ireg1bd (ADC[0][15:8]),
    .ireg1cd (ADC[0][7:0]),
    .ireg1dd (ADC[1][15:8]),
    .ireg1ed (ADC[1][7:0]),
    .ireg1fd (ADC[2][15:8]),
    .ireg20d (ADC[2][7:0]),
    .ireg21d (ADC[3][15:8]),
    .ireg22d (ADC[3][7:0]),
    .ireg23d (ADC[4][15:8]),
    .ireg24d (ADC[4][7:0]),
    .ireg25d (ADC[5][15:8]),
    .ireg26d (ADC[5][7:0]),
    .ireg27d (ADC[6][15:8]),
    .ireg28d (ADC[6][7:0]),
    .ireg29d (ADC[7][15:8]),
    .ireg2ad (ADC[7][7:0])
    
);

endmodule
