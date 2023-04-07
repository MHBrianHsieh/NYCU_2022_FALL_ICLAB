// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : MH.v
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                 SYN_AREA        SYN_CLK_PERIOD  CYCLE_NUM  LATENCY(ANDY'S PAT)   CORE_UTIL  CORE_AREA    PERFORMANCE(CORE_AREA*LATENCY)
// 1.0     2022-12-30 Brian Hsieh      HIS 1 DIV                   991279.890635   20.0            29/55/259
//                                                                 1001724.786887  17.0            29/55/259
//                                                                 1001515.223290  16.0            29/55/259  595438 CYCLE/1000PAT  0.7        1412539.128  841079473298.064
//                                                                                                            595438 CYCLE/1000PAT  0.72       1373670.144  817935403203.072
//                                                                 1063945.099686  15.0            29/55/259
// 2.0     2022-01-01 Brian Hsieh      HIS 4 DIV                   1153142.515371  16.0            29/55/3
//                                                                 1143762.067012  15.0            29/55/3
//                                                                 1151648.961184  14.0            29/55/3    546286 CYCLE/1000PAT  0.7        1627048.685  888833917933.91
//                                                                 1166138.759830  13.0            29/55/3
// 2.1     2022-01-02 Brian Hsieh      HIS PIP (ADD -* REG)        1052645.320008  14.0            29/55/4    546478 CYCLE/1000PAT  0.72       1444821.840  789563349479.52
//                                                                 1045350.524899  15.0            29/55/4
//                                                                 1038674.440015  16.0            29/55/4    546478 CYCLE/1000PAT  0.72       1425615.206  779067346544.468
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// Morphology and Histogram Equalization
// -----------------------------------------------------------------------------
// PARAMETERS
// PARAM_NAME RANGE      : DESCRIPTION           : DEFAULT
//
// -----------------------------------------------------------------------------
// REUSE ISSUES
// Reset Schemes : asynchronous active-low reset, rst_n
// Clock Domains : single clock, clk
// Asynchronous I/F : N/A
// Instantiations : RA1SH(SRAM 256 words x 32 bits), DW_addsub_dx, DW_minmax
// Other : 
// -----------------------------------------------------------------------------


//synopsys translate_off
`include "/RAID2/cad/synopsys/synthesis/cur/dw/sim_ver/DW_addsub_dx.v"
`include "/RAID2/cad/synopsys/synthesis/cur/dw/sim_ver/DW_minmax.v"
//synopsys translate_on

module MH (
  clk,
  clk2,
  rst_n,
  in_valid,
  op_valid,
  pic_data,
  se_data,
  op,
  out_valid,
  out_data
);


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                  Parameters                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 8;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                             Input & Output Ports                                                              //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input                              clk           ;
input                              clk2          ;
input                              rst_n         ;
input                              in_valid      ;
input                              op_valid      ;
input      [          31:0]        pic_data      ;
input      [           7:0]        se_data       ;
input      [           2:0]        op            ;
output reg                         out_valid     ;
output reg [          31:0]        out_data      ;


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                            Parameters & Constants                                                             //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

localparam IDLE              = 3'd0;
localparam STORE_SE          = 3'd1;
localparam EROSION           = 3'd2;
localparam DILATION          = 3'd3;
localparam HISTOGRAM_CDF     = 3'd4;
localparam WAIT_SRAM         = 3'd5;
localparam HIS_WAIT_OUT      = 3'd6;
localparam OUT               = 3'd7;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                  Main Signals                                                                 //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


reg          [           2:0]        op_cs;
reg          [           2:0]        op_ns;
reg                                  out_valid_ns;
reg          [DATA_WIDTH-1:0]        out_data_ns;

// state register
reg          [           2:0]        current_state;
reg          [           2:0]        next_state;


// RA1SH SRAM module signals
wire                                 cen;
wire                                 oen;

reg                                  wen_pic_cs ;
reg          [ADDR_WIDTH-1:0]        addr_pic_cs;
reg          [DATA_WIDTH-1:0]        d_pic_cs   ;
wire         [DATA_WIDTH-1:0]        q_pic_cs   ;
reg                                  wen_pic_ns ;
reg          [ADDR_WIDTH-1:0]        addr_pic_ns;
reg          [DATA_WIDTH-1:0]        d_pic_ns   ;

// line buffer (shift register)
reg          [DATA_WIDTH-1:0]        line_buf         [0:25]; // 3.25*32*8

// window
reg          [           7:0]        window           [0:3][0:3][0:3];
reg          [           7:0]        se_window_cs     [0:3][0:3];
reg          [           7:0]        se_window_ns     [0:3][0:3];

// counter 
reg          [           8:0]        cnt_cs;
reg          [           8:0]        cnt_ns;

// DW_addsub_dx module signals
wire         [           7:0]        addsub_out       [0:3][0:3][0:3];


// DW_minmax module signals
wire         [DATA_WIDTH-1:0]        ero_dil_out      ;


// decoder_8to256
reg          [         255:0]        decoder_8to256   [0:3];

// adder_4
reg          [           2:0]        adder_4          [0:255];

// cdf_table
reg          [          10:0]        cdf_table_cs     [0:255];
reg          [          10:0]        cdf_table_ns     [0:255];

// cdf_min
reg          [           7:0]        cdf_min_idx_cs;
reg          [           7:0]        cdf_min_idx_ns;
reg          [          10:0]        cdf_min_cs;
reg          [          10:0]        cdf_min_ns;

// histogram new value numerator
reg          [          17:0]        numerator_cs     [0:3];
reg          [          17:0]        numerator_ns     [0:3];

// histogram new value denominator
reg          [           9:0]        denominator_cs;
reg          [           9:0]        denominator_ns;

// histogram new value result
reg          [           7:0]        his_val          [0:3];


// control signals
wire                                 se_input_state;
wire                                 ero_dil_state;
wire                                 his_cdf_state;
wire                                 his_compute_state;
wire                                 cnt_256_add26;
wire                                 cnt_gt25;
wire                                 cnt_gt26;
wire                                 cnt_255;
wire                                 cnt_256;
wire                                 cnt_lt_255;
wire                                 cnt_neq_511;
wire                                 store_se_end;
wire                                 sram_full;
wire                                 zero_pad;
wire                                 ero_dil_start;
wire                                 open_close_half_end;
wire                                 cdf_end;
wire                                 out_end;
wire                                 open_close_end;
reg                                  open_close_flag_cs;
reg                                  open_close_flag_ns;

wire                                 ero_dil_min_max_mode;


assign se_input_state      = current_state == IDLE || current_state == STORE_SE;
assign ero_dil_state       = current_state == EROSION || current_state == DILATION;
assign his_cdf_state       = current_state == STORE_SE || current_state ==  HISTOGRAM_CDF;
assign his_compute_state   = current_state == HIS_WAIT_OUT || current_state == OUT;
assign cnt_256_add26       = cnt_cs == 'd282;
assign cnt_gt25            = cnt_cs >= 'd25;
assign cnt_gt26            = cnt_cs >= 'd26;
assign cnt_255             = cnt_cs == 'd255;
assign cnt_256             = cnt_cs == 'd256;
assign cnt_lt_255          = cnt_cs <= 'd255;
assign cnt_neq_511         = cnt_cs != 'd511;
assign store_se_end        = cnt_cs == 'd16;
assign sram_full           = op_cs[1] ? cnt_256_add26 : cnt_256;
assign zero_pad            = cnt_cs[2:0] == 3'd1;
assign ero_dil_start       = cnt_gt26 && cnt_neq_511;
assign open_close_half_end = op_cs[2] && (!open_close_flag_cs);
assign open_close_end      = open_close_flag_cs && cnt_gt25 && cnt_neq_511;
assign cdf_end             = current_state == HISTOGRAM_CDF && cnt_256;
assign out_end             = current_state == OUT && (op_cs[2] ? cnt_256_add26 : cnt_255);


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
        next_state = STORE_SE;
      end
      else begin
        next_state = IDLE;
      end
    end
    STORE_SE: begin
      if (store_se_end) begin
        if (!op_cs[1]) begin
          next_state = HISTOGRAM_CDF;
        end
        else if (op_cs[0]) begin
          next_state = DILATION;
        end
        else begin
          next_state = EROSION;
        end
      end
      else begin
        next_state = STORE_SE;
      end
    end
    EROSION: begin
      if (open_close_end) begin
        next_state = OUT;
      end
      else if (sram_full) begin
        next_state = WAIT_SRAM;
      end
      else begin
        next_state = EROSION;
      end
    end
    DILATION: begin
      if (open_close_end) begin
        next_state = OUT;
      end
      else if (sram_full) begin
        next_state = WAIT_SRAM;
      end
      else begin
        next_state = DILATION;
      end
    end
    HISTOGRAM_CDF: begin
      if (cdf_end) begin
        next_state = WAIT_SRAM;
      end
      else begin
        next_state = HISTOGRAM_CDF;
      end
    end
    WAIT_SRAM: begin
      if (op_cs[2]) begin
        if (op_cs[0]) begin
          next_state = EROSION;
        end
        else begin
          next_state = DILATION;
        end
      end
      else begin
        if (op_cs[1]) begin
          next_state = OUT;
        end
        else begin
          next_state = HIS_WAIT_OUT;
        end
      end
    end
    HIS_WAIT_OUT: begin
      next_state = OUT;
    end
    OUT: begin
      if (out_end) begin
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


// cnt
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    cnt_cs <= 9'd0;
  end
  else begin
    cnt_cs <= cnt_ns;
  end
end

always @(*) begin
  if (ero_dil_state) begin
    if (sram_full) begin
      cnt_ns = 9'd511;
    end
    else begin
      cnt_ns = cnt_cs + 9'd1;
    end
  end
  else if (current_state == IDLE) begin
    if (in_valid) begin
      cnt_ns = 9'd1;
    end
    else begin
      cnt_ns = 9'd0;
    end
  end
  else if (current_state == WAIT_SRAM) begin
    if (open_close_half_end) begin
      cnt_ns = cnt_cs + 9'd1;
    end
    else begin
      cnt_ns = 9'd511;
    end
  end
  else if (current_state == HIS_WAIT_OUT) begin
    cnt_ns = 9'd511;
  end
  else begin
    cnt_ns = cnt_cs + 9'd1;
  end
end


// op_cs
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    op_cs <= 3'b000;
  end
  else begin
    op_cs <= op_ns;
  end
end

always @(*) begin
  if (out_end) begin
    op_ns = 3'b000;
  end
  else if (se_input_state) begin
    if (op_valid) begin
      op_ns = op;
    end
    else begin
      op_ns = op_cs;
    end
  end
  else begin
    op_ns = op_cs;
  end
end



// se_window
genvar se_rw, se_cw;
generate
  for (se_rw=0; se_rw<4; se_rw=se_rw+1) begin: se_window_row
    for (se_cw=0; se_cw<4; se_cw=se_cw+1) begin: se_window_col
      always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          se_window_cs[se_rw][se_cw] <= 8'd0;
        end
        else begin
          se_window_cs[se_rw][se_cw] <= se_window_ns[se_rw][se_cw];
        end
      end

      always @(*) begin
        if (se_input_state) begin
          if (in_valid && (cnt_cs[3:2] == se_rw) && (cnt_cs[1:0] == se_cw) && (~cnt_cs[4]) ) begin
            se_window_ns[se_rw][se_cw] = se_data;
          end
          else begin
            se_window_ns[se_rw][se_cw] = se_window_cs[se_rw][se_cw];
          end
        end
        else begin
          se_window_ns[se_rw][se_cw] = se_window_cs[se_rw][se_cw];
        end
      end
    end
  end
endgenerate


// line buffer (shift register)
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    line_buf[0] <= 'd0;
  end
  else begin
    if (in_valid) begin
      line_buf[0] <= pic_data;
    end
    else if (open_close_flag_cs && cnt_lt_255) begin
      line_buf[0] <= q_pic_cs;
    end
    else begin
      line_buf[0] <= 'd0;
    end
  end
end

genvar i;
generate
  for (i=0; i<25; i=i+1) begin: line_buf_i
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        line_buf[i+1] <= 'd0;
      end
      else begin
        line_buf[i+1] <= line_buf[i];
      end
    end
  end
endgenerate


// window
always @(*) begin
  window[0][0][0] = line_buf[25][ 7: 0];
  window[0][0][1] = line_buf[25][15: 8];
  window[0][0][2] = line_buf[25][23:16];
  window[0][0][3] = line_buf[25][31:24];
  window[0][1][0] = line_buf[17][ 7: 0];
  window[0][1][1] = line_buf[17][15: 8];
  window[0][1][2] = line_buf[17][23:16];
  window[0][1][3] = line_buf[17][31:24];
  window[0][2][0] = line_buf[ 9][ 7: 0];
  window[0][2][1] = line_buf[ 9][15: 8];
  window[0][2][2] = line_buf[ 9][23:16];
  window[0][2][3] = line_buf[ 9][31:24];
  window[0][3][0] = line_buf[ 1][ 7: 0];
  window[0][3][1] = line_buf[ 1][15: 8];
  window[0][3][2] = line_buf[ 1][23:16];
  window[0][3][3] = line_buf[ 1][31:24];
end

always @(*) begin
  window[1][0][0] =                   line_buf[25][15: 8];
  window[1][0][1] =                   line_buf[25][23:16];
  window[1][0][2] =                   line_buf[25][31:24];
  window[1][0][3] = zero_pad ? 8'd0 : line_buf[24][ 7: 0];
  window[1][1][0] =                   line_buf[17][15: 8];
  window[1][1][1] =                   line_buf[17][23:16];
  window[1][1][2] =                   line_buf[17][31:24];
  window[1][1][3] = zero_pad ? 8'd0 : line_buf[16][ 7: 0];
  window[1][2][0] =                   line_buf[ 9][15: 8];
  window[1][2][1] =                   line_buf[ 9][23:16];
  window[1][2][2] =                   line_buf[ 9][31:24];
  window[1][2][3] = zero_pad ? 8'd0 : line_buf[ 8][ 7: 0];
  window[1][3][0] =                   line_buf[ 1][15: 8];
  window[1][3][1] =                   line_buf[ 1][23:16];
  window[1][3][2] =                   line_buf[ 1][31:24];
  window[1][3][3] = zero_pad ? 8'd0 : line_buf[ 0][ 7: 0];
end

always @(*) begin
  window[2][0][0] =                   line_buf[25][23:16];
  window[2][0][1] =                   line_buf[25][31:24];
  window[2][0][2] = zero_pad ? 8'd0 : line_buf[24][ 7: 0];
  window[2][0][3] = zero_pad ? 8'd0 : line_buf[24][15: 8];
  window[2][1][0] =                   line_buf[17][23:16];
  window[2][1][1] =                   line_buf[17][31:24];
  window[2][1][2] = zero_pad ? 8'd0 : line_buf[16][ 7: 0];
  window[2][1][3] = zero_pad ? 8'd0 : line_buf[16][15: 8];
  window[2][2][0] =                   line_buf[ 9][23:16];
  window[2][2][1] =                   line_buf[ 9][31:24];
  window[2][2][2] = zero_pad ? 8'd0 : line_buf[ 8][ 7: 0];
  window[2][2][3] = zero_pad ? 8'd0 : line_buf[ 8][15: 8];
  window[2][3][0] =                   line_buf[ 1][23:16];
  window[2][3][1] =                   line_buf[ 1][31:24];
  window[2][3][2] = zero_pad ? 8'd0 : line_buf[ 0][ 7: 0];
  window[2][3][3] = zero_pad ? 8'd0 : line_buf[ 0][15: 8];
end

always @(*) begin
  window[3][0][0] =                   line_buf[25][31:24];
  window[3][0][1] = zero_pad ? 8'd0 : line_buf[24][ 7: 0];
  window[3][0][2] = zero_pad ? 8'd0 : line_buf[24][15: 8];
  window[3][0][3] = zero_pad ? 8'd0 : line_buf[24][23:16];
  window[3][1][0] =                   line_buf[17][31:24];
  window[3][1][1] = zero_pad ? 8'd0 : line_buf[16][ 7: 0];
  window[3][1][2] = zero_pad ? 8'd0 : line_buf[16][15: 8];
  window[3][1][3] = zero_pad ? 8'd0 : line_buf[16][23:16];
  window[3][2][0] =                   line_buf[ 9][31:24];
  window[3][2][1] = zero_pad ? 8'd0 : line_buf[ 8][ 7: 0];
  window[3][2][2] = zero_pad ? 8'd0 : line_buf[ 8][15: 8];
  window[3][2][3] = zero_pad ? 8'd0 : line_buf[ 8][23:16];
  window[3][3][0] =                   line_buf[ 1][31:24];
  window[3][3][1] = zero_pad ? 8'd0 : line_buf[ 0][ 7: 0];
  window[3][3][2] = zero_pad ? 8'd0 : line_buf[ 0][15: 8];
  window[3][3][3] = zero_pad ? 8'd0 : line_buf[ 0][23:16];
end


//////////////////////////////////////////////////////
//                 opening/closing                  //
//////////////////////////////////////////////////////

// open_close_end_flag
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    open_close_flag_cs <= 1'b0;
  end
  else begin
    open_close_flag_cs <= open_close_flag_ns;
  end
end

always @(*) begin
  if (current_state == WAIT_SRAM) begin
    if (open_close_half_end) begin
      open_close_flag_ns = 1'b1;
    end
    else begin
      open_close_flag_ns = open_close_flag_cs;
    end
  end
  else if (out_end) begin
    open_close_flag_ns = 1'b0;
  end
  else begin
    open_close_flag_ns = open_close_flag_cs;
  end
end

//////////////////////////////////////////////////////
//                    histogram                     //
//////////////////////////////////////////////////////

// decoder_8to256
genvar dei, dej;
generate
  for (dei=0; dei<4; dei=dei+1) begin: decoder_num
    for (dej=0; dej<256; dej=dej+1) begin: decoder_dout
      always @(*) begin
        if ( dej >= d_pic_cs[7+8*dei -: 8] ) begin
          decoder_8to256[dei][dej] = 1'b1;
        end
        else begin
          decoder_8to256[dei][dej] = 1'b0;
        end
      end
    end
  end
endgenerate


// adder_4
genvar adi;
generate
  for (adi=0; adi<256; adi=adi+1) begin: adder_num
    always @(*) begin
      adder_4[adi] = decoder_8to256[ 0][adi] +  decoder_8to256[ 1][adi] +  decoder_8to256[ 2][adi] +  decoder_8to256[ 3][adi];
    end
  end
endgenerate


// cdf_table
genvar cdfi;
generate
  for (cdfi=0; cdfi<256; cdfi=cdfi+1) begin: cdf_num
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        cdf_table_cs[cdfi] <= 11'd0;
      end
      else begin
        cdf_table_cs[cdfi] <= cdf_table_ns[cdfi];
      end
    end

    always @(*) begin
      if (his_cdf_state) begin
        cdf_table_ns[cdfi] = cdf_table_cs[cdfi] + adder_4[cdfi];
      end
      else if (current_state == IDLE) begin
          cdf_table_ns[cdfi] = 11'd0;
      end
      else begin
        cdf_table_ns[cdfi] = cdf_table_cs[cdfi];
      end
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
  if (his_cdf_state) begin
    if (ero_dil_out[31:24] < cdf_min_idx_cs) begin
      cdf_min_idx_ns = ero_dil_out[31:24];
    end
    else begin
      cdf_min_idx_ns = cdf_min_idx_cs;
    end
  end
  else if (current_state == IDLE) begin
    cdf_min_idx_ns = 8'd255;
  end
  else begin
    cdf_min_idx_ns = cdf_min_idx_cs;
  end
end


// cdf_min
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    cdf_min_cs <= 11'd0;
  end
  else begin
    cdf_min_cs <= cdf_min_ns;
  end
end

always @(*) begin
  if (current_state == HISTOGRAM_CDF) begin
    if (cdf_end) begin
      cdf_min_ns = cdf_table_ns[cdf_min_idx_ns];
    end
    else begin
      cdf_min_ns = 10'd0;
    end
  end
  else if (current_state >= WAIT_SRAM) begin
    cdf_min_ns = cdf_min_cs;
  end
  else begin
    cdf_min_ns = 10'd0;
  end
end


// numerator
genvar num;
generate
  for (num=0; num<4; num=num+1) begin: numerator_his
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        numerator_cs[num] <= 18'd0;
      end
      else begin
        numerator_cs[num] <= numerator_ns[num];
      end
    end

    always @(*) begin
      if (his_compute_state) begin
        if (out_end) begin
          numerator_ns[num] = 18'd0;
        end
        else begin
          numerator_ns[num] = (cdf_table_cs[q_pic_cs[8*num+7 -: 8]] - cdf_min_cs) * 8'd255;
        end
      end
      else begin
        numerator_ns[num] = 18'd0;
      end
    end
  end
endgenerate


// denominator
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    denominator_cs <= 10'd1;
  end
  else begin
    denominator_cs <= denominator_ns;
  end
end

always @(*) begin
  if (his_compute_state) begin
    if (out_end) begin
      denominator_ns = 10'd1;
    end
    else begin
      denominator_ns = 11'd1024 - cdf_min_cs;
    end
  end
  else begin
    denominator_ns = 10'd1;
  end
end


// his_val
genvar hv;
generate
  for (hv=0; hv<4; hv=hv+1) begin: his_val_div
    always @(*) begin
      if (his_compute_state) begin
        if (out_end) begin
          his_val[hv] = 8'd0;
        end
        else begin
          his_val[hv] = numerator_cs[hv] / denominator_cs;
        end
      end
      else begin
        his_val[hv] = 8'd0;
      end
    end
  end
endgenerate


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
  if (ero_dil_state) begin
    if (sram_full || open_close_flag_cs) begin
      wen_pic_ns = 1'b1;
    end
    else begin
      wen_pic_ns = 1'b0;
    end
  end
  else if (current_state == HISTOGRAM_CDF) begin
    if (sram_full) begin
      wen_pic_ns = 1'b1;
    end
    else begin
      wen_pic_ns = 1'b0;
    end
  end
  else if (current_state == IDLE) begin
    if (in_valid) begin
      wen_pic_ns = 1'b0;
    end
    else begin
      wen_pic_ns = 1'b1;
    end
  end
  else if (current_state == STORE_SE) begin
    wen_pic_ns = 1'b0;
  end
  else begin
    wen_pic_ns = 1'b1;
  end
end


// addr_pic
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    addr_pic_cs <= 8'd0;
  end
  else begin
    addr_pic_cs <= addr_pic_ns;
  end
end

always @(*) begin
  if (ero_dil_state) begin
    if (ero_dil_start || open_close_flag_cs) begin
      addr_pic_ns = addr_pic_cs + 8'd1;
    end
    else begin
      addr_pic_ns = 8'd255;
    end
  end
  else if (current_state == HISTOGRAM_CDF) begin
    if (cdf_end) begin
      addr_pic_ns = 8'd0;
    end
    else begin
      addr_pic_ns = addr_pic_cs + 8'd1;
    end
  end
  else if (current_state == OUT) begin
    if (out_end) begin
      addr_pic_ns = 8'd0;
    end
    else begin
      addr_pic_ns = addr_pic_cs + 8'd1;
    end
  end
  else if (current_state == IDLE) begin
    addr_pic_ns = 8'd0;
  end
  else begin
    addr_pic_ns = addr_pic_cs + 8'd1;
  end
end


// d_pic
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    d_pic_cs <= 'd0;
  end
  else begin
    d_pic_cs <= d_pic_ns;
  end
end

always @(*) begin
  if (ero_dil_state) begin
    if (ero_dil_start) begin
      d_pic_ns = ero_dil_out;
    end
    else begin
      d_pic_ns = d_pic_cs;
    end
  end
  else if (current_state == HISTOGRAM_CDF) begin
    if (cdf_end) begin
      d_pic_ns = d_pic_cs;
    end
    else begin
      d_pic_ns = pic_data;
    end
  end
  else if (current_state == IDLE) begin
    if (in_valid) begin
      d_pic_ns = pic_data;
    end
    else begin
      d_pic_ns = 'd0;
    end
  end
  else if (current_state == STORE_SE) begin
    d_pic_ns = pic_data;
  end
  else begin
    d_pic_ns = d_pic_cs;
  end
end


//////////////////////////////////////////////////////
//                      ouput                       //
//////////////////////////////////////////////////////

// out_valid
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_valid <= 1'b0;
  end
  else begin
    out_valid <= out_valid_ns;
  end
end

always @(*) begin
  if (current_state == OUT) begin
    if (out_end) begin
      out_valid_ns = 1'b0;
    end
    else begin 
      out_valid_ns = 1'b1;
    end
  end
  else begin
    out_valid_ns = 1'b0;
  end
end


// out_data
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_data <= 'd0;
  end
  else begin
    out_data <= out_data_ns;
  end
end

always @(*) begin
  if (current_state == OUT) begin
    if (out_end) begin
      out_data_ns = 'd0;
    end
    else if (~op_cs[1]) begin
      out_data_ns = {his_val[3], his_val[2], his_val[1], his_val[0]};
    end
    else if (op_cs[2]) begin
      out_data_ns = ero_dil_out;
    end
    else begin 
      out_data_ns = q_pic_cs;
    end
  end
  else begin
    out_data_ns = 'd0;
  end
end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                Module Instantiation                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// RA1SH (Single Port SRAM 256 words x 32 bits)
RA1SH u_RA1SH_PIC (
  .Q   (q_pic_cs    ),
  .CLK (clk          ),
  .CEN (cen          ),
  .WEN (wen_pic_cs  ),
  .A   (addr_pic_cs ),
  .D   (d_pic_cs    ),
  .OEN (oen          )
);

assign cen           = 1'b0;
assign oen           = 1'b0;



// DW_addsub_dx: for erosion and dilation
genvar asw, asr, asc;
generate
  for (asw=0; asw<4; asw=asw+1) begin: addsub_window
    for (asr=0; asr<4; asr=asr+1) begin: addsub_row
      for (asc=0; asc<4; asc=asc+1) begin: addsub_col
        DW_addsub_dx #(8) u_DW_addsub_dx (
          .a      ( window[asw][asr][asc]                                                                   ),
          .b      ( (op_cs[0] ^ open_close_flag_cs) ? se_window_cs[3-asr][3-asc] : se_window_cs[asr][asc]   ),
          .ci1    ( 1'b0                                                                                    ),
          .ci2    ( 1'b0                                                                                    ),
          .addsub ( open_close_flag_cs ? op_cs[0] : ~op_cs[0]                                               ),
          .tc     ( 1'b0                                                                                    ),
          .sat    ( 1'b1                                                                                    ),
          .avg    ( 1'b0                                                                                    ),
          .dplx   ( 1'b0                                                                                    ),
          .sum    ( addsub_out[asw][asr][asc]                                                               ),
          .co1    (                                                                                         ),
          .co2    (                                                                                         )
        );
      end
    end
  end
endgenerate


// DW_minmax: for erosion and dilation
genvar mw;
generate
  for (mw=0; mw<3; mw=mw+1) begin: min_max_window
    DW_minmax #(8, 16) u_DW_minmax (
      .a      ( {addsub_out[mw][0][0], addsub_out[mw][0][1], addsub_out[mw][0][2], addsub_out[mw][0][3],
                 addsub_out[mw][1][0], addsub_out[mw][1][1], addsub_out[mw][1][2], addsub_out[mw][1][3],
                 addsub_out[mw][2][0], addsub_out[mw][2][1], addsub_out[mw][2][2], addsub_out[mw][2][3],
                 addsub_out[mw][3][0], addsub_out[mw][3][1], addsub_out[mw][3][2], addsub_out[mw][3][3]} ),
      .tc     ( 1'b0                                                                                     ),
      .min_max( ero_dil_min_max_mode                                                                     ),
      .value  ( ero_dil_out[7+8*mw -: 8]                                                                 ),
      .index  (                                                                                          )
    );
  end
endgenerate


// DW_minmax: for erosion & dilation or histogram equalization
DW_minmax #(8, 16) u_DW_minmax_1 (
  .a      ( op_cs[1] ?
           {addsub_out[3][0][0], addsub_out[3][0][1], addsub_out[3][0][2], addsub_out[3][0][3],
            addsub_out[3][1][0], addsub_out[3][1][1], addsub_out[3][1][2], addsub_out[3][1][3],
            addsub_out[3][2][0], addsub_out[3][2][1], addsub_out[3][2][2], addsub_out[3][2][3],
            addsub_out[3][3][0], addsub_out[3][3][1], addsub_out[3][3][2], addsub_out[3][3][3]} :
           {d_pic_cs[ 7: 0], d_pic_cs[15: 8], d_pic_cs[23:16], d_pic_cs[31:24],
            8'd255, 8'd255, 8'd255, 8'd255,
            8'd255, 8'd255, 8'd255, 8'd255,
            8'd255, 8'd255, 8'd255, 8'd255 }                                                          ),
  .tc     ( 1'b0                                                                                      ),
  .min_max( op_cs[1] ? ero_dil_min_max_mode : 1'b0                                                    ),
  .value  ( ero_dil_out[31:24]                                                                        ),
  .index  (                                                                                           )
);

assign ero_dil_min_max_mode = open_close_flag_cs ? ~op_cs[0] : op_cs[0];

endmodule

