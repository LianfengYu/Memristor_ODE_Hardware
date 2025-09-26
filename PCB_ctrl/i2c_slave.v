module i2c_slave ( clk, rstn, I_DEV_ADR, isda, osda, isck,
// write into chip
	reg00d, reg01d, reg02d, reg03d, reg04d, 
	reg05d, reg06d, reg07d, reg08d, reg09d,
	reg0ad, reg0bd, reg0cd, reg0dd, reg0ed,
	reg0fd, reg10d, reg11d, reg12d, reg13d,
	reg14d, reg15d, reg16d, reg17d, reg18d,
	reg19d, reg1ad, reg1bd,
//read from chip
    ireg00d, ireg1cd, ireg1dd, ireg1ed, ireg1fd,
	ireg20d, ireg21d, ireg22d, ireg23d, ireg24d, 
	ireg25d, ireg26d, ireg27d, ireg28d, ireg29d, 
	ireg2ad, ireg2bd
	 );
input	clk;
input	rstn;
input	[7:1]	I_DEV_ADR;	// Device address
input	isda;
output	reg osda;
input	isck;
// write into chip
output	reg[7:0] reg00d,reg01d,reg02d,reg03d,reg04d,reg05d,reg06d,reg07d,reg08d,reg09d,reg0ad,reg0bd,reg0cd,reg0dd,reg0ed,reg0fd,reg10d,reg11d,reg12d,reg13d,reg14d,reg15d,reg16d,reg17d,reg18d,reg19d,reg1ad,reg1bd;
// read from chip
input [7:0] ireg00d,ireg1cd,ireg1dd,ireg1ed,ireg1fd,ireg20d,ireg21d,ireg22d,ireg23d,ireg24d,ireg25d,ireg26d,ireg27d,ireg28d,ireg29d,ireg2ad,ireg2bd;

// Initial value define
parameter	INI00D = 'd0;
parameter	INI01D = 'd0;
parameter	INI02D = 'd3;
parameter	INI03D = 8'h00;
parameter	INI04D = 8'h00;
parameter	INI05D = 8'h00;
parameter	INI06D = 8'h00;
parameter	INI07D = 8'h00;
parameter	INI08D = 8'h00;
parameter	INI09D = 8'h00;
parameter	INI0AD = 8'h1b;
parameter	INI0BD = 8'h00;
parameter	INI0CD = 8'h00;
parameter	INI0DD = 8'h00;
parameter	INI0ED = 8'h00;
parameter	INI0FD = 8'h00;
parameter	INI10D = 8'h00;
parameter	INI11D = 8'h00;
parameter	INI12D = 8'h00;
parameter	INI13D = 8'h00;
parameter	INI14D = 8'h00;
parameter	INI15D = 8'h00;
parameter	INI16D = 8'h00;
parameter	INI17D = 8'h00;
parameter	INI18D = 8'h00;
parameter	INI19D = 8'h00;
parameter	INI1AD = 8'h00;
parameter	INI1BD = 8'h00;

// do not touch FF ---
parameter	INIFFD = 8'h00;
// -------------------


parameter DB_0    = 3'b100,	// State 0
	  DB_021  = 3'b101,	// 0 -> 1
	  DB_120  = 3'b110,	// 1 -> 0
	  DB_1    = 3'b111;	// State 1
reg [2:0]	isda_cs, isck_cs;
parameter SDA_TOP = 4'h2;	// Consecutive constant number
parameter SCK_TOP = 4'h2;	// Consecutive constant number
reg [3:0]	isda_cnt, isck_cnt;	// Consecutive constant value counter
reg [2:0]	isda_syn, isck_syn;	// meta-stability SCK/SDA
wire		sdai, scki;
reg		sdain, sckin;	// Debounce SDA/SCK

parameter I2C_IDLE = 4'h0,
	  I2C_STR  = 4'h1,
	  I2C_ADR  = 4'h2,
	  I2C_ACK  = 4'h3,	// I2C Address ACK
	  I2C_RADR = 4'h4,	// Register Address phase
	  I2C_ACK2 = 4'h5,	// Register Address ACK
	  I2C_WD   = 4'h6,
	  I2C_RD   = 4'h7,
	  I2C_DACK = 4'h8;	// Register Data ACK
reg [3:0] i2c_cs, i2c_ns;
reg [29:0] long_cnt;	// For timeout
wire		sstr;	// Signal START
wire		sstp;	// Signal STOP
wire		sclkr;	// Signal SCK rising
wire		sclkf;	// Signal SCK falling
reg	[2:0]	bit_cnt;	// bit counter
reg	[2:0]	bit_cnt_dly;	// bit counter
reg		bit_dat_lat;	// Bit data latch pulse
reg		dev_adr_lat;	// Device address latch pulse
reg		reg_adr_lat;	// Register address latch pulse
reg		reg_dat_lat;	// Register write in data latch pulse
reg		mult_ph;	// Write/Read multiple flag
reg		mult_ph_prog;	// Multiple in progress
wire		read_ph;	// Phase : 0: Write, 1: Read
reg		reg_adr_add;	// Register address auto add
reg		ireg_acs_pul;	// Internal register access pulse
reg		ireg_access;
reg	[3:0]	read_byte_cnt;	// Count the current read byte from I2C master
wire		read_mult;	// Enable read multiple
wire	[3:0]	read_mult_byte;	// Multiple read bytes

// internal registers
reg [7:0]   regffd;
reg	[7:0]	dev_adr;	// dev_adr[0], 1: read out data phase
reg	[7:0]	reg_adr;	// regisrer address
reg	[7:0]	reg_wdata;	// write in data
reg	[7:0]	reg_rdata;	// read out data

//reg	[7:0]	mem_data[5:0];	// 64 * 8 = 512 bits memory space

// SCK, SDA signal re-sync to internal clock domain
assign	sdai = isda_syn[2];
assign	scki = isck_syn[2];

always @(posedge clk or negedge rstn)
if (!rstn)	begin isda_cs <= DB_1; isck_cs <= DB_1;	
	isda_syn <= 3'h7; isck_syn <= 3'h7;
	sdain <= 1'b1;	sckin <= 1'b1;
	isda_cnt <= 4'h0; isck_cnt <= 4'h0;	end
else begin
isda_syn <= {isda_syn[1:0], isda};
isck_syn <= {isck_syn[1:0], isck};
case (isda_cs)
DB_0  : begin sdain <= 1'b0;
	if (sdai) begin isda_cs <= DB_021; isda_cnt <= 4'h0; end
	end
DB_021: begin sdain <= 1'b0;
	if (sdai) begin
	  if (isda_cnt==SDA_TOP) begin isda_cs <= DB_1; end
	  else begin isda_cnt <= isda_cnt + 4'h1; end	end
	else begin isda_cs <= DB_0; end
	end
DB_1  : begin sdain <= 1'b1;
	if (!sdai) begin isda_cs <= DB_120; isda_cnt <= 4'h0; end
	end
DB_120: begin sdain <= 1'b1;
	if (sdai) isda_cs <= DB_1;
	else begin
	  if (isda_cnt==SDA_TOP) begin isda_cs <= DB_0; end
	  else begin isda_cnt <= isda_cnt + 4'h1; end
	end
	end
endcase
case (isck_cs)
DB_0  : begin sckin <= 1'b0;
	if (scki) begin isck_cs <= DB_021; isck_cnt <= 4'h0; end
	end
DB_021: begin sckin <= 1'b0;
	if (scki) begin
	  if (isck_cnt==SDA_TOP) begin isck_cs <= DB_1; end
	  else begin isck_cnt <= isck_cnt + 4'h1; end	end
	else begin isck_cs <= DB_0; end
	end
DB_1  : begin sckin <= 1'b1;
	if (!scki) begin isck_cs <= DB_120; isck_cnt <= 4'h0; end
	end
DB_120: begin sckin <= 1'b1;
	if (scki) isck_cs <= DB_1;
	else begin
	  if (isck_cnt==SDA_TOP) begin isck_cs <= DB_0; end
	  else begin isck_cnt <= isck_cnt + 4'h1; end
	end
	end
endcase
end

reg	sda_dly, sck_dly;
always @(posedge clk or negedge rstn)
if	(!rstn) begin	sda_dly <= 1'b1; sck_dly <= 1'b1;	end
else  begin sda_dly <= sdain; sck_dly <= sckin;	end

assign	sstr = sda_dly && sck_dly && !sdain;	// START event
assign	sstp = !sda_dly && sck_dly && sdain;	// STOP event
assign	sclkr = !sck_dly && sckin;		// Data latch event and counter proceed
assign	sclkf = sck_dly && !sckin;		// Data latch event and counter proceed

// I2C protocol handling
always @(posedge clk or negedge rstn) begin
if (!rstn)	begin i2c_cs <= I2C_IDLE; ireg_access <= 1'b0; ireg_acs_pul <= 1'b0; end
else if (sstp)	begin i2c_cs <= I2C_IDLE; 
		mult_ph_prog <= mult_ph;	end
else if (sstr)	begin	i2c_cs <= I2C_STR; end		// Prevent dead lock
else begin
i2c_ns <= i2c_cs;
bit_dat_lat <= 1'b0;
dev_adr_lat <= 1'b0;
reg_adr_lat <= 1'b0;
reg_dat_lat <= 1'b0;
reg_adr_add <= 1'b0;
ireg_acs_pul<= 1'b0;
bit_cnt_dly <= bit_cnt;
ireg_access <= ireg_acs_pul;
case (i2c_cs)
I2C_IDLE : begin
	if (sstr) i2c_cs <= I2C_STR;
	else if (sclkf && mult_ph_prog) begin
	  reg_adr_add <= 1'b1;
	  if (read_ph)	i2c_cs <= I2C_RD;
	  else	begin	i2c_cs <= I2C_WD;	end	
	end
	end
I2C_STR	 : begin
	  read_byte_cnt <= 4'h0;
	  bit_cnt <= 3'h7;
	  mult_ph <= 1'b0;
	  mult_ph_prog <= 1'b0;
	if (sstp) i2c_cs <= I2C_IDLE;
	else if (!sckin)	i2c_cs <= I2C_ADR;
	end
I2C_ADR	 : if (sclkr) begin
	  read_byte_cnt <= 4'h0;
	  mult_ph <= 1'b0;
	  bit_cnt <= bit_cnt + 3'h7;
	  bit_dat_lat <= 1'b1;
	  if (~|bit_cnt)	begin
	    dev_adr_lat <= 1'b1;	i2c_cs <= I2C_ACK;	end
	end
I2C_ACK	 : if (sclkr) begin
	  bit_cnt <= 3'h7;
	  if (read_ph) begin
	    i2c_cs <= I2C_RD;
	    ireg_acs_pul <= 1'b1;
	  end
	  else	begin i2c_cs <= I2C_RADR; end
	end
I2C_RADR : if (sclkr) begin
	  bit_cnt <= bit_cnt + 3'h7;
	  bit_dat_lat <= 1'b1;
	  if (~|bit_cnt)	begin
	    reg_adr_lat <= 1'b1;	i2c_cs <= I2C_ACK2;	end
	end
I2C_ACK2 : if (sclkr) begin
	  bit_cnt <= 3'h7;
	  i2c_cs <= I2C_WD;
	end
I2C_WD	 : if (sclkr) begin
	  mult_ph <= 1'b1;
	  bit_cnt <= bit_cnt + 3'h7;
	  bit_dat_lat <= 1'b1;
	  if (~|bit_cnt)	begin
	    reg_dat_lat <= 1'b1;
	    ireg_acs_pul <= 1'b1;
	   if (mult_ph_prog)	i2c_cs <= I2C_DACK;
	   else begin		i2c_cs <= I2C_IDLE;	end
	  end
	end
I2C_RD	 : if (sclkr) begin
	  mult_ph <= 1'b1;
	  bit_cnt <= bit_cnt + 3'h7;
	  bit_dat_lat <= 1'b1;
	  if (~|bit_cnt)	begin
	    reg_dat_lat <= 1'b1;
	   if (mult_ph_prog)	begin
		i2c_cs <= I2C_DACK;
		read_byte_cnt <= read_byte_cnt + 4'h1;
	   end
	   else begin		i2c_cs <= I2C_IDLE;	end
	  end
	end
I2C_DACK : if (sclkr) begin
	  reg_adr_add <= 1'b1;
	  if (read_ph) begin
	    i2c_cs <= I2C_RD;
	    ireg_acs_pul <= 1'b1;
	  end
	  else begin	i2c_cs <= I2C_WD;	end 
	end
endcase
end
end

always @(posedge clk or negedge rstn) begin
if (!rstn)	osda <= 1'b1;
else if (sclkf) begin
case (i2c_cs)
default : osda <= 1'b1;
I2C_ACK : if (I_DEV_ADR==dev_adr[7:1])	osda <= 1'b0;
I2C_ACK2: osda <= 1'b0;
I2C_DACK: if (read_ph) begin osda <= !read_mult || (read_byte_cnt==read_mult_byte); end
	else		osda <= 1'b0;
I2C_RD  : begin
	case (bit_cnt)
	3'h0	: osda <= reg_rdata[0];
	3'h1	: osda <= reg_rdata[1];
	3'h2	: osda <= reg_rdata[2];
	3'h3	: osda <= reg_rdata[3];
	3'h4	: osda <= reg_rdata[4];
	3'h5	: osda <= reg_rdata[5];
	3'h6	: osda <= reg_rdata[6];
	3'h7	: osda <= reg_rdata[7];
	endcase
	end
endcase
end
end

// Internal register read/write handling
assign	read_ph = dev_adr[0];
always @(posedge clk or negedge rstn) begin
if (!rstn)	begin	dev_adr<='d0 ; reg_adr<='d0 ; reg_wdata<='d0; end
else begin
  if (i2c_ns==I2C_ADR) begin
    if (dev_adr_lat) dev_adr <= {dev_adr[7:1], sdain};
    else if (bit_dat_lat) begin
      case (bit_cnt_dly)
      default	: dev_adr[1] <= sdain;
      3'h2	: dev_adr[2] <= sdain;
      3'h3	: dev_adr[3] <= sdain;
      3'h4	: dev_adr[4] <= sdain;
      3'h5	: dev_adr[5] <= sdain;
      3'h6	: dev_adr[6] <= sdain;
      3'h7	: dev_adr[7] <= sdain;
      endcase
    end
  end

  if (i2c_ns==I2C_RADR) begin
    if (reg_adr_lat) reg_adr <= {reg_adr[7:1], sdain};
    else if (bit_dat_lat) begin
      case (bit_cnt_dly)
      default	: reg_adr[1] <= sdain;
      3'h2	: reg_adr[2] <= sdain;
      3'h3	: reg_adr[3] <= sdain;
      3'h4	: reg_adr[4] <= sdain;
      3'h5	: reg_adr[5] <= sdain;
      3'h6	: reg_adr[6] <= sdain;
      3'h7	: reg_adr[7] <= sdain;
      endcase
    end
  end
  else if (reg_adr_add)	begin reg_adr <= reg_adr + 8'h1;	end

  if (i2c_ns==I2C_WD) begin
    if (reg_dat_lat) reg_wdata <= {reg_wdata[7:1], sdain};
    else if (bit_dat_lat) begin
      case (bit_cnt_dly)
      default	: reg_wdata[1] <= sdain;
      3'h2	: reg_wdata[2] <= sdain;
      3'h3	: reg_wdata[3] <= sdain;
      3'h4	: reg_wdata[4] <= sdain;
      3'h5	: reg_wdata[5] <= sdain;
      3'h6	: reg_wdata[6] <= sdain;
      3'h7	: reg_wdata[7] <= sdain;
      endcase
    end
  end
end
end


// FIFO
always @(posedge clk or negedge rstn) begin
if (!rstn)	begin
		reg00d <= INI00D; 
		reg01d <= INI01D;
		reg02d <= INI02D; 
		reg03d <= INI03D;
		reg04d <= INI04D; 
		reg05d <= INI05D; 
		reg06d <= INI06D; 
		reg07d <= INI07D; 
		reg08d <= INI08D; 
		reg09d <= INI09D; 
		reg0ad <= INI0AD; 
		reg0bd <= INI0BD; 
		reg0cd <= INI0CD;
		reg0dd <= INI0DD;
		reg0ed <= INI0ED;
		reg0fd <= INI0FD;
		reg10d <= INI10D;
		reg11d <= INI11D;
		reg12d <= INI12D;
		reg13d <= INI13D;
		reg14d <= INI14D;
		reg15d <= INI15D;
		reg16d <= INI16D;
		reg17d <= INI17D;
		reg18d <= INI18D;
		reg19d <= INI19D;
		reg1ad <= INI1AD;
		reg1bd <= INI1BD;
		//do not touch FF---
		regffd <= INIFFD; 
		//------------------
		reg_rdata <= 'd0 ;
end
else if (ireg_access) begin
  if (read_ph) begin
  case (reg_adr)
  8'h00	: reg_rdata <= ireg00d;
  8'h01	: reg_rdata <= reg01d;
  8'h02	: reg_rdata <= reg02d;
  8'h03	: reg_rdata <= reg03d;
  8'h04	: reg_rdata <= reg04d;
  8'h05	: reg_rdata <= reg05d;
  8'h06	: reg_rdata <= reg06d;
  8'h07	: reg_rdata <= reg07d;
  8'h08	: reg_rdata <= reg08d;
  8'h09	: reg_rdata <= reg09d;
  8'h0a	: reg_rdata <= reg0ad;
  8'h0b	: reg_rdata <= reg0bd;
  8'h0c	: reg_rdata <= reg0cd;
  8'h0d	: reg_rdata <= reg0dd;
  8'h0e	: reg_rdata <= reg0ed;
  8'h0f	: reg_rdata <= reg0fd;
  8'h10	: reg_rdata <= reg10d;
  8'h11	: reg_rdata <= reg11d;
  8'h12	: reg_rdata <= reg12d;
  8'h13	: reg_rdata <= reg13d;
  8'h14	: reg_rdata <= reg14d;
  8'h15	: reg_rdata <= reg15d;
  8'h16 : reg_rdata <= reg16d;
  8'h17 : reg_rdata <= reg17d;
  8'h18	: reg_rdata <= reg18d;
  8'h19	: reg_rdata <= reg19d;
  8'h1a	: reg_rdata <= reg1ad;
  8'h1b	: reg_rdata <= reg1bd;
  8'h1c	: reg_rdata <= ireg1cd;
  8'h1d	: reg_rdata <= ireg1dd;
  8'h1e	: reg_rdata <= ireg1ed;
  8'h1f	: reg_rdata <= ireg1fd;
  8'h20	: reg_rdata <= ireg20d;
  8'h21	: reg_rdata <= ireg21d;
  8'h22	: reg_rdata <= ireg22d;
  8'h23	: reg_rdata <= ireg23d;
  8'h24	: reg_rdata <= ireg24d;
  8'h25	: reg_rdata <= ireg25d;
  8'h26	: reg_rdata <= ireg26d;
  8'h27	: reg_rdata <= ireg27d;
  8'h28	: reg_rdata <= ireg28d;
  8'h29	: reg_rdata <= ireg29d;
  8'h2a	: reg_rdata <= ireg2ad;
  8'h2b	: reg_rdata <= ireg2bd;


//do not touch FF---
  8'hff	: reg_rdata <= regffd;
//------------------
  default: reg_rdata <= reg_rdata;
  endcase
  end	// end of read_ph
  else begin
  case (reg_adr)
  8'h00	: reg00d <= reg_wdata;
  8'h01	: reg01d <= reg_wdata;
  8'h02	: reg02d <= reg_wdata;
  8'h03	: reg03d <= reg_wdata;
  8'h04	: reg04d <= reg_wdata;
  8'h05	: reg05d <= reg_wdata;
  8'h06	: reg06d <= reg_wdata;
  8'h07	: reg07d <= reg_wdata;
  8'h08	: reg08d <= reg_wdata;
  8'h09	: reg09d <= reg_wdata;
  8'h0a	: reg0ad <= reg_wdata;
  8'h0b	: reg0bd <= reg_wdata;
  8'h0c	: reg0cd <= reg_wdata;
  8'h0d	: reg0dd <= reg_wdata;
  8'h0e	: reg0ed <= reg_wdata;
  8'h0f	: reg0fd <= reg_wdata;
  8'h10	: reg10d <= reg_wdata;
  8'h11	: reg11d <= reg_wdata;
  8'h12	: reg12d <= reg_wdata;
  8'h13	: reg13d <= reg_wdata;
  8'h14	: reg14d <= reg_wdata;
  8'h15	: reg15d <= reg_wdata;
  8'h16	: reg16d <= reg_wdata;
  8'h17	: reg17d <= reg_wdata;
  8'h18	: reg18d <= reg_wdata;
  8'h19	: reg19d <= reg_wdata;
  8'h1a	: reg1ad <= reg_wdata;
  8'h1b	: reg1bd <= reg_wdata;

  //do not touch FF---
  8'hff	: regffd <= reg_wdata;
  //------------------
  default:;
  endcase
  end
  end	// end of ireg_access
end

assign	read_mult = regffd[7];
assign	read_mult_byte = regffd[3:0];

endmodule
