// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : EDH.v
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                 AREA             CLK_PERIOD  PERFORMANCE
// 1.0     2022-11-14 Brian Hsieh                                  2288893.856169   17.6        4.02845318685744e7
//                                                                 2367839.304529   12.0        2.8414071654348e7
//                                                                 2352258.447227   11.8        2.77566496772786e7
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// Erosion, Dilation and Histogram Equalization
// -----------------------------------------------------------------------------
// PARAMETERS
// PARAM_NAME RANGE      : DESCRIPTION           : DEFAULT
//
// -----------------------------------------------------------------------------
// REUSE ISSUES
// Reset Schemes : asynchronous active-low reset, rst_n
// Clock Domains : single clock, clk
// Asynchronous I/F : N/A
// Instantiations : DW_addsub_dx, DW_minmax
// Other : 
// -----------------------------------------------------------------------------

//synopsys translate_off
`include "/RAID2/cad/synopsys/synthesis/cur/dw/sim_ver/DW_addsub_dx.v"
`include "/RAID2/cad/synopsys/synthesis/cur/dw/sim_ver/DW_minmax.v"
//synopsys translate_on

module EDH (
  clk,
  rst_n,
  in_valid,
  pic_no,
  se_no,
  op,
  busy,
  
  awid_m_inf,
  awaddr_m_inf,
  awsize_m_inf,
  awburst_m_inf,
  awlen_m_inf,
  awvalid_m_inf,
  awready_m_inf,
  
  wdata_m_inf,
  wlast_m_inf,
  wvalid_m_inf,
  wready_m_inf,
  
  bid_m_inf,
  bresp_m_inf,
  bvalid_m_inf,
  bready_m_inf,
  
  
  arid_m_inf,
  araddr_m_inf,
  arlen_m_inf,
  arsize_m_inf,
  arburst_m_inf,
  arvalid_m_inf,
  arready_m_inf,
  
  
  rid_m_inf,
  rdata_m_inf,
  rresp_m_inf,
  rlast_m_inf,
  rvalid_m_inf,
  rready_m_inf
);


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                  Parameters                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
parameter ID_WIDTH   = 4;
parameter DATA_WIDTH = 128;
parameter ADDR_WIDTH = 32;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                             Input & Output Ports                                                              //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input                              clk           ;
input                              rst_n         ;
input                              in_valid      ;
input      [           3:0]        pic_no        ;
input      [           5:0]        se_no         ;
input      [           1:0]        op            ;
output reg                         busy          ;
// axi write address channel 
output     [  ID_WIDTH-1:0]        awid_m_inf    ;
output reg [ADDR_WIDTH-1:0]        awaddr_m_inf  ;
output     [           2:0]        awsize_m_inf  ;
output     [           1:0]        awburst_m_inf ;
output     [           7:0]        awlen_m_inf   ;
output reg                         awvalid_m_inf ;
input                              awready_m_inf ;
// axi write data channel 
output reg [DATA_WIDTH-1:0]        wdata_m_inf   ;
output reg                         wlast_m_inf   ;
output reg                         wvalid_m_inf  ;
input                              wready_m_inf  ;
// axi write response channel
input      [  ID_WIDTH-1:0]        bid_m_inf     ;
input      [           1:0]        bresp_m_inf   ;
input                              bvalid_m_inf  ;
output                             bready_m_inf  ;
// -----------------------------
// axi read address channel 
output     [  ID_WIDTH-1:0]        arid_m_inf    ;
output reg [ADDR_WIDTH-1:0]        araddr_m_inf  ;
output     [           7:0]        arlen_m_inf   ;
output     [           2:0]        arsize_m_inf  ;
output     [           1:0]        arburst_m_inf ;
output reg                         arvalid_m_inf ;
input                              arready_m_inf ;
// -----------------------------
// axi read data channel 
input      [  ID_WIDTH-1:0]        rid_m_inf     ;
input      [DATA_WIDTH-1:0]        rdata_m_inf   ;
input      [           1:0]        rresp_m_inf   ;
input                              rlast_m_inf   ;
input                              rvalid_m_inf  ;
output                             rready_m_inf  ;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                            Parameters & Constants                                                             //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

localparam IDLE              = 4'd0;
localparam SE_ARREADY        = 4'd1;
localparam SE_READ           = 4'd2;
localparam PIC_ARREADY       = 4'd3;
localparam PIC_READ          = 4'd4;
localparam HISTOGRAM_CDF     = 4'd5;
localparam HISTOGRAM_VAL     = 4'd6;
localparam PIC_AWREADY       = 4'd7;
localparam PIC_WRITE         = 4'd8;
localparam OUT               = 4'd9;



// axi write address channel
assign awid_m_inf    = 'd0;
assign awsize_m_inf  = 3'b010;
assign awburst_m_inf = 2'b01;
assign awlen_m_inf   = 'd255;

// axi write response channel
assign bready_m_inf  = 1'b1;

// axi read address channel
assign arid_m_inf    = 'd0;
assign arsize_m_inf  = 3'b010;
assign arburst_m_inf = 2'b01;

// axi read data channel
assign rready_m_inf  = 1'b1;


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                  Main Signals                                                                 //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


reg          [           3:0]        pic_no_cs;
reg          [           5:0]        se_no_cs;
reg          [           1:0]        op_cs;
reg          [           3:0]        pic_no_ns;
reg          [           5:0]        se_no_ns;
reg          [           1:0]        op_ns;
reg                                  busy_ns;

// axi write address channel
reg          [ADDR_WIDTH-1:0]        awaddr_m_inf_ns;
reg                                  awvalid_m_inf_ns;

// axi write data channel
reg          [DATA_WIDTH-1:0]        wdata_m_inf_ns;
reg                                  wlast_m_inf_ns;
reg                                  wvalid_m_inf_ns;

// axi write response channel
reg                                  bready_m_inf_ns;

// axi read address channel
reg          [ADDR_WIDTH-1:0]        araddr_m_inf_ns;
reg                                  arvalid_m_inf_ns;

// axi read data channel
reg                                  rready_m_inf_ns;


// state register
reg          [           3:0]        current_state;
reg          [           3:0]        next_state;


// RA1SH SRAM module signals
wire                                 cen;
wire                                 oen;

reg                                  wen_pic_cs ;
reg          [           7:0]        addr_pic_cs;
reg          [DATA_WIDTH-1:0]        d_pic_cs   ;
wire         [DATA_WIDTH-1:0]        q_pic_cs   ;
reg                                  wen_pic_ns ;
reg          [           7:0]        addr_pic_ns;
reg          [DATA_WIDTH-1:0]        d_pic_ns   ;

//se_reg
reg          [DATA_WIDTH-1:0]        se_reg_cs   ;
reg          [DATA_WIDTH-1:0]        se_reg_ns   ;


// line buffer (shift register)
reg          [DATA_WIDTH-1:0]        line_buf         [0:13]; // 3.5*64*8

// window
reg          [           7:0]        window           [0:15][0:3][0:3];
reg          [           7:0]        se_window        [0:3][0:3];

// counter of the number of dram data which has been read
reg          [           8:0]        cnt_pic_read_cs;
reg          [           8:0]        cnt_pic_read_ns;

// counter of the number of dram data which has been written
reg          [           8:0]        cnt_pic_wr_dram_cs;
reg          [           8:0]        cnt_pic_wr_dram_ns;

// counter of the number of cycles when dram write is waiting for sram read
reg          [           1:0]        cnt_dram_wait_sram_cs;
reg          [           1:0]        cnt_dram_wait_sram_ns;


// DW_addsub_dx module signals
wire         [           7:0]        addsub_out       [0:15][0:3][0:3];


// DW_minmax module signals
wire         [DATA_WIDTH-1:0]        ero_dil_out      ;


// decoder_8to256
reg          [         255:0]        decoder_8to256   [0:15];

// adder_16
reg          [           4:0]        adder_16         [0:255];

// cdf_table
reg          [          12:0]        cdf_table_cs     [0:255];
reg          [          12:0]        cdf_table_ns     [0:255];

// cdf_min
reg          [           7:0]        cdf_min_idx_cs;
reg          [           7:0]        cdf_min_idx_ns;
reg          [          12:0]        cdf_min_cs;
reg          [          12:0]        cdf_min_ns;

// histogram new value numerator
reg          [          19:0]        numerator_cs;
reg          [          19:0]        numerator_ns;

// histogram new value denominator
reg          [          11:0]        denominator_cs;
reg          [          11:0]        denominator_ns;



// control signals
wire                                 ero_dil_start;
wire                                 sram_wr_end;
wire                                 dram_wr_end;
wire                                 dram_wait_sram;
wire                                 his_start;
wire                                 cdf_end;
wire                                 his_val_end;

assign arlen_m_inf    = ( (current_state == SE_ARREADY || current_state == SE_READ) && (~op_cs[1]) ) ? 8'd0 : 8'd255;
assign ero_dil_start  = cnt_pic_read_cs >= 'd14;
assign sram_wr_end    = cnt_pic_read_cs == 'd269;
assign dram_wr_end    = cnt_pic_wr_dram_cs == 'd256;
assign dram_wait_sram = !cnt_dram_wait_sram_cs[1] && wready_m_inf;
assign his_start      = cnt_pic_read_cs >= 'd1;
assign cdf_end        = cnt_pic_read_cs == 'd256;
assign his_val_end    = cdf_end;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                     Main Code                                                                 //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// state register
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    current_state <= IDLE;
  end
  else begin
    current_state <= next_state;
  end
end

// next state logic
always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid) begin
        next_state = SE_ARREADY;
      end
      else begin
        next_state = IDLE;
      end
    end
    SE_ARREADY: begin
      if (op_cs[1]) begin
        next_state = PIC_ARREADY;
      end
      else if (arready_m_inf) begin
        next_state = SE_READ;
      end
      else begin
        next_state = SE_ARREADY;
      end
    end
    SE_READ: begin
      if (rlast_m_inf) begin
        next_state = PIC_ARREADY;
      end
      else begin
        next_state = SE_READ;
      end
    end
    PIC_ARREADY: begin
      if (op_cs[1]) begin
        next_state = HISTOGRAM_CDF;
      end
      else if (arready_m_inf) begin
        next_state = PIC_READ;
      end
      else begin
        next_state = PIC_ARREADY;
      end
    end
    PIC_READ: begin
      if (sram_wr_end) begin
        next_state = PIC_AWREADY;
      end
      else begin
        next_state = PIC_READ;
      end
    end
    HISTOGRAM_CDF: begin
      if (cdf_end) begin
        next_state = HISTOGRAM_VAL;
      end
      else begin
        next_state = HISTOGRAM_CDF;
      end
    end
    HISTOGRAM_VAL: begin
      if (his_val_end) begin
        next_state = PIC_AWREADY;
      end
      else begin
        next_state = HISTOGRAM_VAL;
      end
    end
    PIC_AWREADY: begin
      if (awready_m_inf) begin
        next_state = PIC_WRITE;
      end
      else begin
        next_state = PIC_AWREADY;
      end
    end
    PIC_WRITE: begin
      if (wlast_m_inf) begin
        next_state = OUT;
      end
      else begin
        next_state = PIC_WRITE;
      end
    end
    OUT: begin
      if (bvalid_m_inf) begin
        next_state = IDLE;
      end
      else begin
        next_state = OUT;
      end
    end
    default: begin
      next_state = IDLE;
    end
  endcase
end


// pic_no_cs, se_no_cs, op_cs
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pic_no_cs <= 4'd0;
    se_no_cs  <= 6'd0;
    op_cs     <= 2'd0;
  end
  else begin
    pic_no_cs <= pic_no_ns;
    se_no_cs  <= se_no_ns;
    op_cs     <= op_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid) begin
        pic_no_ns = pic_no;
        se_no_ns  = se_no;
        op_ns     = op;
      end
      else begin
        pic_no_ns = 4'd0;
        se_no_ns  = 6'd0;
        op_ns     = 2'd0;
      end
    end
    default: begin
      pic_no_ns = pic_no_cs;
      se_no_ns  = se_no_cs;
      op_ns     = op_cs;
    end
  endcase
end


// se_reg
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    se_reg_cs <= 128'd0;
  end
  else begin
    se_reg_cs <= se_reg_ns;
  end
end

always @(*) begin
  case(current_state)
    SE_READ: begin
      if (rvalid_m_inf) begin
        se_reg_ns = rdata_m_inf;
      end
      else begin
        se_reg_ns = 128'd0;
      end
    end
    default: begin
      se_reg_ns = se_reg_cs;
    end
  endcase
end


// se_window
genvar se_rw, se_cw;
generate
  for (se_rw=0; se_rw<4; se_rw=se_rw+1) begin: se_window_row
    for (se_cw=0; se_cw<4; se_cw=se_cw+1) begin: se_window_col
      always @(*) begin
        se_window[se_rw][se_cw] = se_reg_cs[ 7+32*se_rw+8*se_cw -: 8];
      end
    end
  end
endgenerate


// line buffer (shift register)
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    line_buf[0] <= 128'd0;
  end
  else begin
    if ( current_state == PIC_READ && rvalid_m_inf ) begin
      line_buf[0] <= rdata_m_inf;
    end
    else begin
      line_buf[0] <= 128'd0;
    end
  end
end

genvar i;
generate
  for (i=0; i<13; i=i+1) begin: line_buf_i
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        line_buf[i+1] <= 128'd0;
      end
      else begin
        line_buf[i+1] <= line_buf[i];
      end
    end
  end
endgenerate


// window
genvar w, rw, rc;
generate
  for (w=0; w<13; w=w+1) begin: window_w
    for (rw=0; rw<4; rw=rw+1) begin: window_row
      for (rc=0; rc<4; rc=rc+1) begin: window_col
        always @(*) begin
          window[w][rw][rc] = line_buf[13-4*rw][ 7+8*rc+8*w -: 8];
        end
      end
    end
  end
endgenerate

// always @(*) begin
//   window0[0][0] = line_buf[13][ 7: 0];
//   window0[0][1] = line_buf[13][15: 8];
//   window0[0][2] = line_buf[13][23:16];
//   window0[0][3] = line_buf[13][31:24];
//   window0[1][0] = line_buf[ 9][ 7: 0];
//   window0[1][1] = line_buf[ 9][15: 8];
//   window0[1][2] = line_buf[ 9][23:16];
//   window0[1][3] = line_buf[ 9][31:24];
//   window0[2][0] = line_buf[ 5][ 7: 0];
//   window0[2][1] = line_buf[ 5][15: 8];
//   window0[2][2] = line_buf[ 5][23:16];
//   window0[2][3] = line_buf[ 5][31:24];
//   window0[3][0] = line_buf[ 1][ 7: 0];
//   window0[3][1] = line_buf[ 1][15: 8];
//   window0[3][2] = line_buf[ 1][23:16];
//   window0[3][3] = line_buf[ 1][31:24];
// end

// always @(*) begin
//   window4[0][0] = line_buf[13][39:32];
//   window4[0][1] = line_buf[13][47:40];
//   window4[0][2] = line_buf[13][55:48];
//   window4[0][3] = line_buf[13][63:56];
//   window4[1][0] = line_buf[ 9][39:32];
//   window4[1][1] = line_buf[ 9][47:40];
//   window4[1][2] = line_buf[ 9][55:48];
//   window4[1][3] = line_buf[ 9][63:56];
//   window4[2][0] = line_buf[ 5][39:32];
//   window4[2][1] = line_buf[ 5][47:40];
//   window4[2][2] = line_buf[ 5][55:48];
//   window4[2][3] = line_buf[ 5][63:56];
//   window4[3][0] = line_buf[ 1][39:32];
//   window4[3][1] = line_buf[ 1][47:40];
//   window4[3][2] = line_buf[ 1][55:48];
//   window4[3][3] = line_buf[ 1][63:56];
// end

// always @(*) begin
//   window8[0][0] = line_buf[13][71:64];
//   window8[0][1] = line_buf[13][79:72];
//   window8[0][2] = line_buf[13][87:80];
//   window8[0][3] = line_buf[13][95:88];
//   window8[1][0] = line_buf[ 9][71:64];
//   window8[1][1] = line_buf[ 9][79:72];
//   window8[1][2] = line_buf[ 9][87:80];
//   window8[1][3] = line_buf[ 9][95:88];
//   window8[2][0] = line_buf[ 5][71:64];
//   window8[2][1] = line_buf[ 5][79:72];
//   window8[2][2] = line_buf[ 5][87:80];
//   window8[2][3] = line_buf[ 5][95:88];
//   window8[3][0] = line_buf[ 1][71:64];
//   window8[3][1] = line_buf[ 1][79:72];
//   window8[3][2] = line_buf[ 1][87:80];
//   window8[3][3] = line_buf[ 1][95:88];
// end

// always @(*) begin
//   window12[0][0] = line_buf[13][103: 96];
//   window12[0][1] = line_buf[13][111:104];
//   window12[0][2] = line_buf[13][119:112];
//   window12[0][3] = line_buf[13][127:120];
//   window12[1][0] = line_buf[ 9][103: 96];
//   window12[1][1] = line_buf[ 9][111:104];
//   window12[1][2] = line_buf[ 9][119:112];
//   window12[1][3] = line_buf[ 9][127:120];
//   window12[2][0] = line_buf[ 5][103: 96];
//   window12[2][1] = line_buf[ 5][111:104];
//   window12[2][2] = line_buf[ 5][119:112];
//   window12[2][3] = line_buf[ 5][127:120];
//   window12[3][0] = line_buf[ 1][103: 96];
//   window12[3][1] = line_buf[ 1][111:104];
//   window12[3][2] = line_buf[ 1][119:112];
//   window12[3][3] = line_buf[ 1][127:120];
// end

always @(*) begin
  window[13][0][0] =                                         line_buf[13][111:104];
  window[13][0][1] =                                         line_buf[13][119:112];
  window[13][0][2] =                                         line_buf[13][127:120];
  window[13][0][3] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[12][  7:  0];
  window[13][1][0] =                                         line_buf[ 9][111:104];
  window[13][1][1] =                                         line_buf[ 9][119:112];
  window[13][1][2] =                                         line_buf[ 9][127:120];
  window[13][1][3] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 8][  7:  0];
  window[13][2][0] =                                         line_buf[ 5][111:104];
  window[13][2][1] =                                         line_buf[ 5][119:112];
  window[13][2][2] =                                         line_buf[ 5][127:120];
  window[13][2][3] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 4][  7:  0];
  window[13][3][0] =                                         line_buf[ 1][111:104];
  window[13][3][1] =                                         line_buf[ 1][119:112];
  window[13][3][2] =                                         line_buf[ 1][127:120];
  window[13][3][3] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 0][  7:  0];
end

always @(*) begin
  window[14][0][0] =                                         line_buf[13][119:112];
  window[14][0][1] =                                         line_buf[13][127:120];
  window[14][0][2] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[12][  7:  0];
  window[14][0][3] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[12][ 15:  8];
  window[14][1][0] =                                         line_buf[ 9][119:112];
  window[14][1][1] =                                         line_buf[ 9][127:120];
  window[14][1][2] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 8][  7:  0];
  window[14][1][3] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 8][ 15:  8];
  window[14][2][0] =                                         line_buf[ 5][119:112];
  window[14][2][1] =                                         line_buf[ 5][127:120];
  window[14][2][2] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 4][  7:  0];
  window[14][2][3] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 4][ 15:  8];
  window[14][3][0] =                                         line_buf[ 1][119:112];
  window[14][3][1] =                                         line_buf[ 1][127:120];
  window[14][3][2] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 0][  7:  0];
  window[14][3][3] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 0][ 15:  8];
end

always @(*) begin
  window[15][0][0] =                                         line_buf[13][127:120];
  window[15][0][1] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[12][  7:  0];
  window[15][0][2] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[12][ 15:  8];
  window[15][0][3] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[12][ 23: 16];
  window[15][1][0] =                                         line_buf[ 9][127:120];
  window[15][1][1] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 8][  7:  0];
  window[15][1][2] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 8][ 15:  8];
  window[15][1][3] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 8][ 23: 16];
  window[15][2][0] =                                         line_buf[ 5][127:120];
  window[15][2][1] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 4][  7:  0];
  window[15][2][2] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 4][ 15:  8];
  window[15][2][3] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 4][ 23: 16];
  window[15][3][0] =                                         line_buf[ 1][127:120];
  window[15][3][1] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 0][  7:  0];
  window[15][3][2] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 0][ 15:  8];
  window[15][3][3] = (cnt_pic_read_cs[1:0] == 2'd1) ? 8'd0 : line_buf[ 0][ 23: 16];
end


// cnt_pic_read
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    cnt_pic_read_cs <= 9'd0;
  end
  else begin
    cnt_pic_read_cs <= cnt_pic_read_ns;
  end
end

always @(*) begin
  case(current_state)
    PIC_READ: begin
      if (rvalid_m_inf) begin
        cnt_pic_read_ns = cnt_pic_read_cs + 9'd1;
      end
      else if (cnt_pic_read_cs >= 9'd256) begin
        cnt_pic_read_ns = cnt_pic_read_cs + 9'd1;
      end
      else begin
        cnt_pic_read_ns = 9'd0;
      end
    end
    HISTOGRAM_CDF: begin
      if (rvalid_m_inf) begin
        cnt_pic_read_ns = cnt_pic_read_cs + 9'd1;
      end
      else begin
        cnt_pic_read_ns = 9'd0;
      end
    end
    HISTOGRAM_VAL: begin
      cnt_pic_read_ns = cnt_pic_read_cs + 9'd1;
    end
    default: begin
      cnt_pic_read_ns = 9'd0;
    end
  endcase
end


// cnt_pic_wr_dram
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    cnt_pic_wr_dram_cs <= 9'd0;
  end
  else begin
    cnt_pic_wr_dram_cs <= cnt_pic_wr_dram_ns;
  end
end

always @(*) begin
  case(current_state)
    PIC_WRITE: begin
      if (wready_m_inf) begin
        cnt_pic_wr_dram_ns = cnt_pic_wr_dram_cs + 9'd1;
      end
      else begin
        cnt_pic_wr_dram_ns = 9'd0;
      end
    end
    default: begin
      cnt_pic_wr_dram_ns = 9'd0;
    end
  endcase
end


//////////////////////////////////////////////////////
//                 axi read channel                 //
//////////////////////////////////////////////////////


// araddr_m_inf
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    araddr_m_inf <= 'd0;
  end
  else begin
    araddr_m_inf <= araddr_m_inf_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid) begin
        if (op[1]) begin
          araddr_m_inf_ns = {16'h0004, pic_no_ns, 12'h000};
        end
        else begin
          araddr_m_inf_ns = {20'h00030, 2'b00, se_no_ns, 4'h0};
        end
      end
      else begin
        araddr_m_inf_ns = 32'd0;
      end
    end
    SE_ARREADY: begin
      if (op_cs[1]) begin
        araddr_m_inf_ns = {16'h0004, pic_no_cs, 12'h000};
      end
      else begin
        araddr_m_inf_ns = {20'h00030, 2'b00, se_no_cs, 4'h0};
      end
    end
    SE_READ: begin
      if (rlast_m_inf) begin
        araddr_m_inf_ns = {16'h0004, pic_no_cs, 12'h000};
      end
      else begin
        araddr_m_inf_ns = araddr_m_inf;
      end
    end
    PIC_ARREADY: begin
      araddr_m_inf_ns = {16'h0004, pic_no_cs, 12'h000};
    end
    default: begin
      araddr_m_inf_ns = araddr_m_inf;
    end
  endcase
end


// arvalid_m_inf
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    arvalid_m_inf <= 1'b0;
  end
  else begin
    arvalid_m_inf <= arvalid_m_inf_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid) begin
        arvalid_m_inf_ns = 1'b1;
      end
      else begin
        arvalid_m_inf_ns = 1'b0;
      end
    end
    SE_ARREADY: begin
      if (arready_m_inf) begin
        arvalid_m_inf_ns = 1'b0;
      end
      else begin
        arvalid_m_inf_ns = 1'b1;
      end
    end
    SE_READ: begin
      if (rlast_m_inf) begin
        arvalid_m_inf_ns = 1'b1;
      end
      else begin
        arvalid_m_inf_ns = 1'b0;
      end
    end
    PIC_ARREADY: begin
      if (arready_m_inf) begin
        arvalid_m_inf_ns = 1'b0;
      end
      else begin
        arvalid_m_inf_ns = 1'b1;
      end
    end
    default: begin
      arvalid_m_inf_ns = 1'b0;
    end
  endcase
end


//////////////////////////////////////////////////////
//                 axi write channel                //
//////////////////////////////////////////////////////

// awaddr_m_inf
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    awaddr_m_inf <= 'd0;
  end
  else begin
    awaddr_m_inf <= awaddr_m_inf_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      awaddr_m_inf_ns = 32'd0;
    end
    default: begin
      awaddr_m_inf_ns = {16'h0004, pic_no_cs, 12'h000};
    end
  endcase
end

// awvalid_m_inf
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    awvalid_m_inf <= 1'b0;
  end
  else begin
    awvalid_m_inf <= awvalid_m_inf_ns;
  end
end

always @(*) begin
  case(current_state)
    PIC_READ: begin
      if (sram_wr_end) begin
        awvalid_m_inf_ns = 1'b1;
      end
      else begin
        awvalid_m_inf_ns = 1'b0;
      end
    end
    HISTOGRAM_VAL: begin
      if (his_val_end) begin
        awvalid_m_inf_ns = 1'b1;
      end
      else begin
        awvalid_m_inf_ns = 1'b0;
      end
    end
    PIC_AWREADY: begin
      if (awready_m_inf) begin
        awvalid_m_inf_ns = 1'b0;
      end
      else begin
        awvalid_m_inf_ns = 1'b1;
      end
    end
    default: begin
      awvalid_m_inf_ns = 1'b0;
    end
  endcase
end


// wdata_m_inf
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    wdata_m_inf <= 128'd0;
  end
  else begin
    wdata_m_inf <= wdata_m_inf_ns;
  end
end

always @(*) begin
  case(current_state)
    PIC_WRITE: begin
      if (wlast_m_inf) begin
        wdata_m_inf_ns = 128'd0;
      end
      else if (op_cs[1]) begin
        wdata_m_inf_ns = {cdf_table_cs[q_pic_cs[127:120]][7:0], cdf_table_cs[q_pic_cs[119:112]][7:0], cdf_table_cs[q_pic_cs[111:104]][7:0], cdf_table_cs[q_pic_cs[103: 96]][7:0],
                          cdf_table_cs[q_pic_cs[ 95: 88]][7:0], cdf_table_cs[q_pic_cs[ 87: 80]][7:0], cdf_table_cs[q_pic_cs[ 79: 72]][7:0], cdf_table_cs[q_pic_cs[ 71: 64]][7:0],
                          cdf_table_cs[q_pic_cs[ 63: 56]][7:0], cdf_table_cs[q_pic_cs[ 55: 48]][7:0], cdf_table_cs[q_pic_cs[ 47: 40]][7:0], cdf_table_cs[q_pic_cs[ 39: 32]][7:0],
                          cdf_table_cs[q_pic_cs[ 31: 24]][7:0], cdf_table_cs[q_pic_cs[ 23: 16]][7:0], cdf_table_cs[q_pic_cs[ 15:  8]][7:0], cdf_table_cs[q_pic_cs[  7:  0]][7:0] };
      end
      else begin
        wdata_m_inf_ns = q_pic_cs;
      end
    end
    default: begin
      wdata_m_inf_ns = 128'd0;
    end
  endcase
end


// wlast_m_inf
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    wlast_m_inf <= 1'b0;
  end
  else begin
    wlast_m_inf <= wlast_m_inf_ns;
  end
end

always @(*) begin
  case(current_state)
    PIC_WRITE: begin
      if (dram_wr_end) begin
        wlast_m_inf_ns = 1'b1;
      end
      else begin
        wlast_m_inf_ns = 1'b0;
      end
    end
    default: begin
      wlast_m_inf_ns = 1'b0;
    end
  endcase
end


// wvalid_m_inf
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    wvalid_m_inf <= 1'b0;
  end
  else begin
    wvalid_m_inf <= wvalid_m_inf_ns;
  end
end

always @(*) begin
  case(current_state)
    PIC_AWREADY: begin
      if (awvalid_m_inf_ns) begin
        wvalid_m_inf_ns = 1'b0;
      end
      else begin
        wvalid_m_inf_ns = 1'b1;
      end
    end
    PIC_WRITE: begin
      if (wlast_m_inf || dram_wait_sram) begin
        wvalid_m_inf_ns = 1'b0;
      end
      else begin
        wvalid_m_inf_ns = 1'b1;
      end
    end
    default: begin
      wvalid_m_inf_ns = 1'b0;
    end
  endcase
end


// cnt_dram_wait_sram
always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    cnt_dram_wait_sram_cs <= 2'd0;
  end
  else begin
    cnt_dram_wait_sram_cs <= cnt_dram_wait_sram_ns;
  end
end

always @(*) begin
  if (wready_m_inf && cnt_dram_wait_sram_cs == 2'd2) begin
    cnt_dram_wait_sram_ns = 2'd2;
  end
  else if (wready_m_inf) begin
    cnt_dram_wait_sram_ns = cnt_dram_wait_sram_cs + 2'd1;
  end 
  else begin
    cnt_dram_wait_sram_ns = 2'd0;
  end
end


//////////////////////////////////////////////////////
//                    histogram                     //
//////////////////////////////////////////////////////

// decoder_8to256
genvar dei, dej;
generate
  for (dei=0; dei<16; dei=dei+1) begin: decoder_num
    for (dej=0; dej<256; dej=dej+1) begin: decoder_dout
      always @(*) begin
        if ( dej >= rdata_m_inf[7+8*dei -: 8] ) begin
          decoder_8to256[dei][dej] = 1'b1;
        end
        else begin
          decoder_8to256[dei][dej] = 1'b0;
        end
      end
    end
  end
endgenerate


// adder_16
genvar adi;
generate
  for (adi=0; adi<256; adi=adi+1) begin: adder_num
    always @(*) begin
      adder_16[adi] = decoder_8to256[ 0][adi] +  decoder_8to256[ 1][adi] +  decoder_8to256[ 2][adi] +  decoder_8to256[ 3][adi]
                    + decoder_8to256[ 4][adi] +  decoder_8to256[ 5][adi] +  decoder_8to256[ 6][adi] +  decoder_8to256[ 7][adi]
                    + decoder_8to256[ 8][adi] +  decoder_8to256[ 9][adi] +  decoder_8to256[10][adi] +  decoder_8to256[11][adi]
                    + decoder_8to256[12][adi] +  decoder_8to256[13][adi] +  decoder_8to256[14][adi] +  decoder_8to256[15][adi];
    end
  end
endgenerate


// cdf_table
genvar cdfi;
generate
  for (cdfi=0; cdfi<256; cdfi=cdfi+1) begin: cdf_num
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        cdf_table_cs[cdfi] <= 13'd0;
      end
      else begin
        cdf_table_cs[cdfi] <= cdf_table_ns[cdfi];
      end
    end

    always @(*) begin
      case(current_state)
        IDLE: begin
          cdf_table_ns[cdfi] = 13'd0;
        end
        HISTOGRAM_CDF: begin
          if (rvalid_m_inf) begin
            cdf_table_ns[cdfi] = cdf_table_cs[cdfi] + adder_16[cdfi];
          end
          else begin
            cdf_table_ns[cdfi] = cdf_table_cs[cdfi];
          end
        end
        HISTOGRAM_VAL: begin
          if (cdfi == cnt_pic_read_cs - 1) begin
            cdf_table_ns[cdfi] = numerator_cs / denominator_cs;
          end
          else begin
            cdf_table_ns[cdfi] = cdf_table_cs[cdfi];
          end
        end
        default: begin
          cdf_table_ns[cdfi] = cdf_table_cs[cdfi];
        end
      endcase
    end
  end
endgenerate


// cdf_min_idx
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    cdf_min_idx_cs <= 8'd255;
  end
  else begin
    cdf_min_idx_cs <= cdf_min_idx_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      cdf_min_idx_ns = 8'd255;
    end
    HISTOGRAM_CDF: begin
      if ( rvalid_m_inf && (ero_dil_out[127:120] < cdf_min_idx_cs) ) begin
        cdf_min_idx_ns = ero_dil_out[127:120];
      end
      else begin
        cdf_min_idx_ns = cdf_min_idx_cs;
      end
    end
    default: begin
      cdf_min_idx_ns = cdf_min_idx_cs;
    end
  endcase
end


// cdf_min
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    cdf_min_cs <= 13'd0;
  end
  else begin
    cdf_min_cs <= cdf_min_ns;
  end
end

always @(*) begin
  case (current_state)
    HISTOGRAM_CDF: begin
      if (cdf_end) begin
        cdf_min_ns = cdf_table_cs[cdf_min_idx_ns];
      end
      else begin
        cdf_min_ns = 13'd0;
      end
    end
    HISTOGRAM_VAL: begin
      cdf_min_ns = cdf_min_cs;
    end
    default: begin
      cdf_min_ns = 13'd0;
    end
  endcase
end


// numerator
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    numerator_cs <= 20'd0;
  end
  else begin
    numerator_cs <= numerator_ns;
  end
end

always @(*) begin
  case(current_state)
    HISTOGRAM_VAL: begin
      if (his_val_end) begin
        numerator_ns = numerator_cs;
      end
      else begin
        numerator_ns = (cdf_table_cs[addr_pic_cs] - cdf_min_cs) * 8'd255;
      end
    end
    default: begin
      numerator_ns = 20'd0;
    end
  endcase
end


// denominator
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    denominator_cs <= 12'd1;
  end
  else begin
    denominator_cs <= denominator_ns;
  end
end

always @(*) begin
  case(current_state)
    HISTOGRAM_VAL: begin
      if (his_val_end) begin
        denominator_ns = denominator_cs;
      end
      else begin
        denominator_ns = 13'd4096 - cdf_min_cs;
      end
    end
    default: begin
      denominator_ns = 12'd1;
    end
  endcase
end


//////////////////////////////////////////////////////
//                    sram_pic                      //
//////////////////////////////////////////////////////

// wen_pic
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    wen_pic_cs <= 1'b1;
  end
  else begin
    wen_pic_cs <= wen_pic_ns;
  end
end

always @(*) begin
  case(current_state)
    PIC_READ: begin
      if (ero_dil_start) begin
        wen_pic_ns = 1'b0;
      end
      else begin
        wen_pic_ns = 1'b1;
      end
    end
    HISTOGRAM_CDF: begin
      if (!rvalid_m_inf) begin
        wen_pic_ns = 1'b1;
      end
      else begin
        wen_pic_ns = 1'b0;
      end
    end
    default: begin
      wen_pic_ns = 1'b1;
    end
  endcase
end


// addr_pic
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    addr_pic_cs <= 8'd255;
  end
  else begin
    addr_pic_cs <= addr_pic_ns;
  end
end

always @(*) begin
  case(current_state)
    PIC_READ: begin
      if (ero_dil_start) begin
        addr_pic_ns = addr_pic_cs + 8'd1;
      end
      else begin
        addr_pic_ns = 8'd255;
      end
    end
    HISTOGRAM_CDF: begin
      if (cdf_end) begin
        addr_pic_ns = 8'd0;
      end
      else if (rvalid_m_inf) begin
        addr_pic_ns = addr_pic_cs + 8'd1;
      end
      else begin
        addr_pic_ns = 8'd255;
      end
    end
    HISTOGRAM_VAL: begin
      // if (rvalid_m_inf) begin
        addr_pic_ns = addr_pic_cs + 8'd1;
      // end
      // else begin
      //   addr_pic_ns = 8'd0;
      // end
    end
    PIC_AWREADY: begin
      addr_pic_ns = 8'd0;
    end
    PIC_WRITE: begin
      if (wready_m_inf) begin
        addr_pic_ns = addr_pic_cs + 8'd1;
      end
      else begin
        addr_pic_ns = 8'd0;
      end
    end
    default: begin
      addr_pic_ns = 8'd255;
    end
  endcase
end


// d_pic
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    d_pic_cs <= 128'd0;
  end
  else begin
    d_pic_cs <= d_pic_ns;
  end
end

always @(*) begin
  case(current_state)
    PIC_READ: begin
      if (ero_dil_start) begin
        d_pic_ns = ero_dil_out;
      end
      else begin
        d_pic_ns = d_pic_cs;
      end
    end
    HISTOGRAM_CDF: begin
      if (rvalid_m_inf) begin
        d_pic_ns = rdata_m_inf;
      end
      else begin
        d_pic_ns = d_pic_cs;
      end
    end
    default: begin
      d_pic_ns = d_pic_cs;
    end
  endcase
end



// busy
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    busy <= 1'b0;
  end
  else begin
    busy <= busy_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      busy_ns = 1'b0;
    end
    OUT: begin
      if (bvalid_m_inf) begin
        busy_ns = 1'b0;
      end
      else begin 
        busy_ns = 1'b1;
      end
    end
    default: begin
      busy_ns = 1'b1;
    end
  endcase
end



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                Module Instantiation                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

RA1SH u_RA1SH_PIC (
  .Q   (q_pic_cs    ),
  .CLK (clk          ),
  .CEN (cen          ),
  .WEN (wen_pic_cs  ),
  .A   (addr_pic_cs ),
  .D   (d_pic_cs    ),
  .OEN (oen          )
);

// RA2SH u_RA2SH (
//   .QA   (QA),
//   .CLKA (clk),
//   .CENA (cen),
//   .WENA (WENA),
//   .AA   (AA),
//   .DA   (DA),
//   .OENA (oen),
//   .QB   (QB),
//   .CLKB (clk),
//   .CENB (cen),
//   .WENB (WENB),
//   .AB   (AB),
//   .DB   (DB),
//   .OENB (oen)
// );


// RA1SH_SE u_RA1SH_SE (
//   .Q   (q_se_cs    ),
//   .CLK (clk        ),
//   .CEN (cen        ),
//   .WEN (wen_se_cs  ),
//   .A   (addr_se_cs ),
//   .D   (d_se_cs    ),
//   .OEN (oen        )
// );

assign cen           = 1'b0;
assign oen           = 1'b0;



// DW_addsub_dx: for erosion and dilation
genvar asw, asr, asc;
generate
  for (asw=0; asw<16; asw=asw+1) begin: addsub_window
    for (asr=0; asr<4; asr=asr+1) begin: addsub_row
      for (asc=0; asc<4; asc=asc+1) begin: addsub_col
        DW_addsub_dx #(8) u_DW_addsub_dx (
          .a      (window[asw][asr][asc]                                    ),
          .b      (op_cs[0] ? se_window[3-asr][3-asc] : se_window[asr][asc] ),
          .ci1    (1'b0                                                     ),
          .ci2    (1'b0                                                     ),
          .addsub (~op_cs[0]                                                ),
          .tc     (1'b0                                                     ),
          .sat    (1'b1                                                     ),
          .avg    (1'b0                                                     ),
          .dplx   (1'b0                                                     ),
          .sum    (addsub_out[asw][asr][asc]                                ),
          .co1    (                                                         ),
          .co2    (                                                         )
        );
      end
    end
  end
endgenerate


// DW_minmax: for erosion and dilation
genvar mw;
generate
  for (mw=0; mw<15; mw=mw+1) begin: min_max_window
    DW_minmax #(8, 16) u_DW_minmax (
      .a      ({addsub_out[mw][0][0], addsub_out[mw][0][1], addsub_out[mw][0][2], addsub_out[mw][0][3],
                addsub_out[mw][1][0], addsub_out[mw][1][1], addsub_out[mw][1][2], addsub_out[mw][1][3],
                addsub_out[mw][2][0], addsub_out[mw][2][1], addsub_out[mw][2][2], addsub_out[mw][2][3],
                addsub_out[mw][3][0], addsub_out[mw][3][1], addsub_out[mw][3][2], addsub_out[mw][3][3]} ),
      .tc     (1'b0                                                                                     ),
      .min_max(op_cs[0]                                                                                 ),
      .value  (ero_dil_out[7+8*mw -: 8]                                                                 ),
      .index  (                                                                                         )
    );
  end
endgenerate


// DW_minmax: for erosion & dilation or histogram equalization
DW_minmax #(8, 16) u_DW_minmax_1 (
  .a      ( (current_state == PIC_READ) ?
           {addsub_out[15][0][0], addsub_out[15][0][1], addsub_out[15][0][2], addsub_out[15][0][3],
            addsub_out[15][1][0], addsub_out[15][1][1], addsub_out[15][1][2], addsub_out[15][1][3],
            addsub_out[15][2][0], addsub_out[15][2][1], addsub_out[15][2][2], addsub_out[15][2][3],
            addsub_out[15][3][0], addsub_out[15][3][1], addsub_out[15][3][2], addsub_out[15][3][3]} :
           {rdata_m_inf[ 7: 0], rdata_m_inf[15: 8], rdata_m_inf[23:16], rdata_m_inf[31:24],
            rdata_m_inf[39:32], rdata_m_inf[47:40], rdata_m_inf[55:48], rdata_m_inf[63:56],
            rdata_m_inf[71:64], rdata_m_inf[79:72], rdata_m_inf[87:80], rdata_m_inf[95:88],
            rdata_m_inf[103:96], rdata_m_inf[111:104], rdata_m_inf[119:112], rdata_m_inf[127:120]}    ),
  .tc     ( 1'b0                                                                                      ),
  .min_max( (current_state == PIC_READ) ? op_cs[0] : 1'b0                                             ),
  .value  ( ero_dil_out[127:120]                                                                      ),
  .index  (                                                                                           )
);



endmodule

