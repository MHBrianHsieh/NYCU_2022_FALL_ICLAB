// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : NN.v
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                 AREA            LATENCY:(19+X)*PAT_NUM-18  CYCLE_TIME   PERFORMANCE
// 1.0     2022-10-16 Brian Hsieh                                  1642449.930058  (19+8)*PAT_NUM-18          22           9.74964848282149032e11
//                                                                 1358085.979620  (19+8)*PAT_NUM-18          30           1.0993162770632052e12
//                                                                 1256088.578441  (19+8)*PAT_NUM-18          50           1.6945891011747531e12
// 2.0     2022-10-16 Brian Hsieh      omit some logic, arch_dp=1  1289735.106550  (19+8)*PAT_NUM-18          22           7.655919181885062e11  
//                                                                 1344308.022146  (19+8)*PAT_NUM-18          21           7.61714500124410812e11  (final)
// 2.1     2022-10-17 Brian Hsieh      arch_exp=1                  1400920.023457  (19+8)*PAT_NUM-18          20.5         7.74892293494793867e11
//                                                                 1482104.139450  (19+8)*PAT_NUM-18          20           7.99802677812798e11
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// Simple Recurrent Neural Network
// -----------------------------------------------------------------------------
// PARAMETERS
// PARAM_NAME RANGE      : DESCRIPTION           : DEFAULT
//
// -----------------------------------------------------------------------------
// REUSE ISSUES
// Reset Schemes : asynchronous active-low reset, rst_n
// Clock Domains : single clock, clk
// Asynchronous I/F : N/A
// Instantiations : 
// Other : 
// -----------------------------------------------------------------------------


module NN(
  // Input signals
  clk,
  rst_n,
  in_valid_u,
  in_valid_w,
  in_valid_v,
  in_valid_x,
  weight_u,
  weight_w,
  weight_v,
  data_x,
  // Output signals
  out_valid,
  out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameters
parameter  inst_sig_width       = 23;
parameter  inst_exp_width       = 8;
parameter  inst_ieee_compliance = 0;
parameter  inst_arch_dp3        = 1;
parameter  inst_arch_exp        = 0;
parameter  inst_rnd             = 3'b000;
localparam ieee_one             = 32'b00111111100000000000000000000000;

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input                                        clk;
input                                        rst_n;
input                                        in_valid_u;
input                                        in_valid_w;
input                                        in_valid_v;
input                                        in_valid_x;
input      [inst_sig_width+inst_exp_width:0] weight_u;
input      [inst_sig_width+inst_exp_width:0] weight_w;
input      [inst_sig_width+inst_exp_width:0] weight_v;
input      [inst_sig_width+inst_exp_width:0] data_x;
output reg                                   out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------

reg  [                            4:0] cnt_r;
reg  [                            4:0] cnt_nxt;

reg  [inst_sig_width+inst_exp_width:0] weight_u_r   [0:8];
reg  [inst_sig_width+inst_exp_width:0] weight_w_r   [0:8];
reg  [inst_sig_width+inst_exp_width:0] weight_v_r   [0:8];
reg  [inst_sig_width+inst_exp_width:0] data_x_r     [0:8];
reg  [inst_sig_width+inst_exp_width:0] weight_u_nxt [0:8];
reg  [inst_sig_width+inst_exp_width:0] weight_w_nxt [0:8];
reg  [inst_sig_width+inst_exp_width:0] weight_v_nxt [0:8];
reg  [inst_sig_width+inst_exp_width:0] data_x_nxt   [0:8];

reg  [inst_sig_width+inst_exp_width:0] ux_r;
reg  [inst_sig_width+inst_exp_width:0] wh_r;
reg  [inst_sig_width+inst_exp_width:0] ux_nxt;
reg  [inst_sig_width+inst_exp_width:0] wh_nxt;

reg  [inst_sig_width+inst_exp_width:0] exp_out_r;
reg  [inst_sig_width+inst_exp_width:0] exp_out_nxt;

reg  [inst_sig_width+inst_exp_width:0] h1_r         [0:2];
reg  [inst_sig_width+inst_exp_width:0] h2_r         [0:2];
reg  [inst_sig_width+inst_exp_width:0] h3_r         [0:2];
reg  [inst_sig_width+inst_exp_width:0] h1_nxt       [0:2];
reg  [inst_sig_width+inst_exp_width:0] h2_nxt       [0:2];
reg  [inst_sig_width+inst_exp_width:0] h3_nxt       [0:2];

reg  [inst_sig_width+inst_exp_width:0] relu_out;

reg  [inst_sig_width+inst_exp_width:0] y1_r         [0:2];
reg  [inst_sig_width+inst_exp_width:0] y2_r         [0:2];
//reg  [inst_sig_width+inst_exp_width:0] y3_r         [0:2];
reg  [inst_sig_width+inst_exp_width:0] y1_nxt       [0:2];
reg  [inst_sig_width+inst_exp_width:0] y2_nxt       [0:2];
//reg  [inst_sig_width+inst_exp_width:0] y3_nxt       [0:2];

reg  [inst_sig_width+inst_exp_width:0] out_nxt;
reg                                    out_valid_nxt;

reg  [inst_sig_width+inst_exp_width:0] dp_ux_in_u0;
reg  [inst_sig_width+inst_exp_width:0] dp_ux_in_u1;
reg  [inst_sig_width+inst_exp_width:0] dp_ux_in_u2;
reg  [inst_sig_width+inst_exp_width:0] dp_ux_in_x0;
reg  [inst_sig_width+inst_exp_width:0] dp_ux_in_x1;
reg  [inst_sig_width+inst_exp_width:0] dp_ux_in_x2;
wire [inst_sig_width+inst_exp_width:0] dp_ux_out;

reg  [inst_sig_width+inst_exp_width:0] dp_wh_in_w0;
reg  [inst_sig_width+inst_exp_width:0] dp_wh_in_w1;
reg  [inst_sig_width+inst_exp_width:0] dp_wh_in_w2;
reg  [inst_sig_width+inst_exp_width:0] dp_wh_in_h0;
reg  [inst_sig_width+inst_exp_width:0] dp_wh_in_h1;
reg  [inst_sig_width+inst_exp_width:0] dp_wh_in_h2;
wire [inst_sig_width+inst_exp_width:0] dp_wh_out;

reg  [inst_sig_width+inst_exp_width:0] dp_vh_in_v0;
reg  [inst_sig_width+inst_exp_width:0] dp_vh_in_v1;
reg  [inst_sig_width+inst_exp_width:0] dp_vh_in_v2;
reg  [inst_sig_width+inst_exp_width:0] dp_vh_in_h0;
reg  [inst_sig_width+inst_exp_width:0] dp_vh_in_h1;
reg  [inst_sig_width+inst_exp_width:0] dp_vh_in_h2;
wire [inst_sig_width+inst_exp_width:0] dp_vh_out;

// reg  [inst_sig_width+inst_exp_width:0] add_uxwh_in_ux;
// reg  [inst_sig_width+inst_exp_width:0] add_uxwh_in_wh;
wire [inst_sig_width+inst_exp_width:0] add_uxwh_out;

reg  [inst_sig_width+inst_exp_width:0] exp_in;
wire [inst_sig_width+inst_exp_width:0] exp_out;

// reg  [inst_sig_width+inst_exp_width:0] add_1_in;
wire [inst_sig_width+inst_exp_width:0] add_1_out;

//reg  [inst_sig_width+inst_exp_width:0] recip_in;
wire [inst_sig_width+inst_exp_width:0] recip_out;





wire                                   cnt_7          ;
wire                                   cnt_8          ;
wire                                   cnt_9          ;
wire                                   cnt_10         ;
wire                                   cnt_11         ;
wire                                   cnt_12         ;
wire                                   cnt_13         ;
wire                                   cnt_14         ;
wire                                   cnt_15         ;
wire                                   cnt_16         ;
wire                                   cnt_17         ;
wire                                   cnt_18         ;
wire                                   cnt_19         ;
wire                                   cnt_20         ;
wire                                   cnt_21         ;
wire                                   cnt_22         ;
wire                                   cnt_23         ;
wire                                   cnt_24         ;
wire                                   cnt_rst        ;
wire                                   out_valid_high ;



// cnt: counter for control
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    cnt_r <= 5'd0;
  end
  else begin
    cnt_r <= cnt_nxt;
  end
end

always @(*) begin
  if (cnt_24) begin
    cnt_nxt = 5'd0;
  end
  else if (cnt_rst) begin
    if (in_valid_u) begin
      cnt_nxt = 5'd1;
    end
    else begin
      cnt_nxt = 5'd0;
    end
  end
  else begin
    cnt_nxt = cnt_r + 5'd1;
  end
end

genvar i;
generate
  for (i=0; i<9; i=i+1) begin: input_reg
    // weight_u
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        weight_u_r[i] <= 32'd0;
      end
      else begin
        weight_u_r[i] <= weight_u_nxt[i];
      end
    end

    always @(*) begin
      if (in_valid_u && (cnt_r == i)) begin
        weight_u_nxt[i] = weight_u;
      end
      else begin
        weight_u_nxt[i] = weight_u_r[i];
      end
    end

    // weight_w
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        weight_w_r[i] <= 32'd0;
      end
      else begin
        weight_w_r[i] <= weight_w_nxt[i];
      end
    end

    always @(*) begin
      if (in_valid_w && (cnt_r == i)) begin
        weight_w_nxt[i] = weight_w;
      end
      else begin
        weight_w_nxt[i] = weight_w_r[i];
      end
    end

    // weight_v
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        weight_v_r[i] <= 32'd0;
      end
      else begin
        weight_v_r[i] <= weight_v_nxt[i];
      end
    end

    always @(*) begin
      if (in_valid_v && (cnt_r == i)) begin
        weight_v_nxt[i] = weight_v;
      end
      else begin
        weight_v_nxt[i] = weight_v_r[i];
      end
    end

    // data_x
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        data_x_r[i] <= 32'd0;
      end
      else begin
        data_x_r[i] <= data_x_nxt[i];
      end
    end

    always @(*) begin
      if (in_valid_x && (cnt_r == i)) begin
        data_x_nxt[i] = data_x;
      end
      else begin
        data_x_nxt[i] = data_x_r[i];
      end
    end
  end
endgenerate

// dp_ux_in
always @(*) begin
  if (cnt_7) begin
    dp_ux_in_u0 = weight_u_r[0];
    dp_ux_in_u1 = weight_u_r[1];
    dp_ux_in_u2 = weight_u_r[2];
    dp_ux_in_x0 = data_x_r  [0];
    dp_ux_in_x1 = data_x_r  [1];
    dp_ux_in_x2 = data_x_r  [2];
  end
  else if (cnt_8) begin
    dp_ux_in_u0 = weight_u_r[3];
    dp_ux_in_u1 = weight_u_r[4];
    dp_ux_in_u2 = weight_u_r[5];
    dp_ux_in_x0 = data_x_r  [0];
    dp_ux_in_x1 = data_x_r  [1];
    dp_ux_in_x2 = data_x_r  [2];
  end
  else if (cnt_9) begin
    dp_ux_in_u0 = weight_u_r[6];
    dp_ux_in_u1 = weight_u_r[7];
    dp_ux_in_u2 = weight_u_r[8];
    dp_ux_in_x0 = data_x_r  [0];
    dp_ux_in_x1 = data_x_r  [1];
    dp_ux_in_x2 = data_x_r  [2];
  end
  else if (cnt_12) begin
    dp_ux_in_u0 = weight_u_r[0];
    dp_ux_in_u1 = weight_u_r[1];
    dp_ux_in_u2 = weight_u_r[2];
    dp_ux_in_x0 = data_x_r  [3];
    dp_ux_in_x1 = data_x_r  [4];
    dp_ux_in_x2 = data_x_r  [5];
  end
  else if (cnt_13) begin
    dp_ux_in_u0 = weight_u_r[3];
    dp_ux_in_u1 = weight_u_r[4];
    dp_ux_in_u2 = weight_u_r[5];
    dp_ux_in_x0 = data_x_r  [3];
    dp_ux_in_x1 = data_x_r  [4];
    dp_ux_in_x2 = data_x_r  [5];
  end
  else if (cnt_14) begin
    dp_ux_in_u0 = weight_u_r[6];
    dp_ux_in_u1 = weight_u_r[7];
    dp_ux_in_u2 = weight_u_r[8];
    dp_ux_in_x0 = data_x_r  [3];
    dp_ux_in_x1 = data_x_r  [4];
    dp_ux_in_x2 = data_x_r  [5];
  end
  else if (cnt_17) begin
    dp_ux_in_u0 = weight_u_r[0];
    dp_ux_in_u1 = weight_u_r[1];
    dp_ux_in_u2 = weight_u_r[2];
    dp_ux_in_x0 = data_x_r  [6];
    dp_ux_in_x1 = data_x_r  [7];
    dp_ux_in_x2 = data_x_r  [8];
  end
  else if (cnt_18) begin
    dp_ux_in_u0 = weight_u_r[3];
    dp_ux_in_u1 = weight_u_r[4];
    dp_ux_in_u2 = weight_u_r[5];
    dp_ux_in_x0 = data_x_r  [6];
    dp_ux_in_x1 = data_x_r  [7];
    dp_ux_in_x2 = data_x_r  [8];
  end
  else if (cnt_19) begin
    dp_ux_in_u0 = weight_u_r[6];
    dp_ux_in_u1 = weight_u_r[7];
    dp_ux_in_u2 = weight_u_r[8];
    dp_ux_in_x0 = data_x_r  [6];
    dp_ux_in_x1 = data_x_r  [7];
    dp_ux_in_x2 = data_x_r  [8];
  end
  else begin
    dp_ux_in_u0 = 32'd0;
    dp_ux_in_u1 = 32'd0;
    dp_ux_in_u2 = 32'd0;
    dp_ux_in_x0 = 32'd0;
    dp_ux_in_x1 = 32'd0;
    dp_ux_in_x2 = 32'd0;
  end
end


// dp_wh_in
always @(*) begin
  if (cnt_12) begin
    dp_wh_in_w0 = weight_w_r[0];
    dp_wh_in_w1 = weight_w_r[1];
    dp_wh_in_w2 = weight_w_r[2];
    dp_wh_in_h0 = h1_r      [0];
    dp_wh_in_h1 = h1_r      [1];
    dp_wh_in_h2 = h1_r      [2];
  end
  else if (cnt_13) begin
    dp_wh_in_w0 = weight_w_r[3];
    dp_wh_in_w1 = weight_w_r[4];
    dp_wh_in_w2 = weight_w_r[5];
    dp_wh_in_h0 = h1_r      [0];
    dp_wh_in_h1 = h1_r      [1];
    dp_wh_in_h2 = h1_r      [2];
  end
  else if (cnt_14) begin
    dp_wh_in_w0 = weight_w_r[6];
    dp_wh_in_w1 = weight_w_r[7];
    dp_wh_in_w2 = weight_w_r[8];
    dp_wh_in_h0 = h1_r      [0];
    dp_wh_in_h1 = h1_r      [1];
    dp_wh_in_h2 = h1_r      [2];
  end
  else if (cnt_17) begin
    dp_wh_in_w0 = weight_w_r[0];
    dp_wh_in_w1 = weight_w_r[1];
    dp_wh_in_w2 = weight_w_r[2];
    dp_wh_in_h0 = h2_r      [0];
    dp_wh_in_h1 = h2_r      [1];
    dp_wh_in_h2 = h2_r      [2];
  end
  else if (cnt_18) begin
    dp_wh_in_w0 = weight_w_r[3];
    dp_wh_in_w1 = weight_w_r[4];
    dp_wh_in_w2 = weight_w_r[5];
    dp_wh_in_h0 = h2_r      [0];
    dp_wh_in_h1 = h2_r      [1];
    dp_wh_in_h2 = h2_r      [2];
  end
  else if (cnt_19) begin
    dp_wh_in_w0 = weight_w_r[6];
    dp_wh_in_w1 = weight_w_r[7];
    dp_wh_in_w2 = weight_w_r[8];
    dp_wh_in_h0 = h2_r      [0];
    dp_wh_in_h1 = h2_r      [1];
    dp_wh_in_h2 = h2_r      [2];
  end
  else begin
    dp_wh_in_w0 = 32'd0;
    dp_wh_in_w1 = 32'd0;
    dp_wh_in_w2 = 32'd0;
    dp_wh_in_h0 = 32'd0;
    dp_wh_in_h1 = 32'd0;
    dp_wh_in_h2 = 32'd0;
  end
end


// dp_vh_in
always @(*) begin
  if (cnt_12) begin
    dp_vh_in_v0 = weight_v_r[0];
    dp_vh_in_v1 = weight_v_r[1];
    dp_vh_in_v2 = weight_v_r[2];
    dp_vh_in_h0 = h1_r      [0];
    dp_vh_in_h1 = h1_r      [1];
    dp_vh_in_h2 = h1_r      [2];
  end
  else if (cnt_13) begin
    dp_vh_in_v0 = weight_v_r[3];
    dp_vh_in_v1 = weight_v_r[4];
    dp_vh_in_v2 = weight_v_r[5];
    dp_vh_in_h0 = h1_r      [0];
    dp_vh_in_h1 = h1_r      [1];
    dp_vh_in_h2 = h1_r      [2];
  end
  else if (cnt_14) begin
    dp_vh_in_v0 = weight_v_r[6];
    dp_vh_in_v1 = weight_v_r[7];
    dp_vh_in_v2 = weight_v_r[8];
    dp_vh_in_h0 = h1_r      [0];
    dp_vh_in_h1 = h1_r      [1];
    dp_vh_in_h2 = h1_r      [2];
  end
  else if (cnt_17) begin
    dp_vh_in_v0 = weight_v_r[0];
    dp_vh_in_v1 = weight_v_r[1];
    dp_vh_in_v2 = weight_v_r[2];
    dp_vh_in_h0 = h2_r      [0];
    dp_vh_in_h1 = h2_r      [1];
    dp_vh_in_h2 = h2_r      [2];
  end
  else if (cnt_18) begin
    dp_vh_in_v0 = weight_v_r[3];
    dp_vh_in_v1 = weight_v_r[4];
    dp_vh_in_v2 = weight_v_r[5];
    dp_vh_in_h0 = h2_r      [0];
    dp_vh_in_h1 = h2_r      [1];
    dp_vh_in_h2 = h2_r      [2];
  end
  else if (cnt_19) begin
    dp_vh_in_v0 = weight_v_r[6];
    dp_vh_in_v1 = weight_v_r[7];
    dp_vh_in_v2 = weight_v_r[8];
    dp_vh_in_h0 = h2_r      [0];
    dp_vh_in_h1 = h2_r      [1];
    dp_vh_in_h2 = h2_r      [2];
  end
  else if (cnt_22) begin
    dp_vh_in_v0 = weight_v_r[0];
    dp_vh_in_v1 = weight_v_r[1];
    dp_vh_in_v2 = weight_v_r[2];
    dp_vh_in_h0 = h3_r      [0];
    dp_vh_in_h1 = h3_r      [1];
    dp_vh_in_h2 = h3_r      [2];
  end
  else if (cnt_23) begin
    dp_vh_in_v0 = weight_v_r[3];
    dp_vh_in_v1 = weight_v_r[4];
    dp_vh_in_v2 = weight_v_r[5];
    dp_vh_in_h0 = h3_r      [0];
    dp_vh_in_h1 = h3_r      [1];
    dp_vh_in_h2 = h3_r      [2];
  end
  else if (cnt_24) begin
    dp_vh_in_v0 = weight_v_r[6];
    dp_vh_in_v1 = weight_v_r[7];
    dp_vh_in_v2 = weight_v_r[8];
    dp_vh_in_h0 = h3_r      [0];
    dp_vh_in_h1 = h3_r      [1];
    dp_vh_in_h2 = h3_r      [2];
  end
  else begin
    dp_vh_in_v0 = 32'd0;
    dp_vh_in_v1 = 32'd0;
    dp_vh_in_v2 = 32'd0;
    dp_vh_in_h0 = 32'd0;
    dp_vh_in_h1 = 32'd0;
    dp_vh_in_h2 = 32'd0;
  end
end


// ux
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    ux_r <= 32'd0;
  end
  else begin
    ux_r <= ux_nxt;
  end
end

always @(*) begin
  if (cnt_7 || cnt_8 || cnt_9 || cnt_12 || cnt_13 || cnt_14 || cnt_17 || cnt_18 || cnt_19) begin
    ux_nxt = dp_ux_out;
  end
  else begin
    ux_nxt = ux_r;
  end
end


// wh
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    wh_r <= 32'd0;
  end
  else begin
    wh_r <= wh_nxt;
  end
end

always @(*) begin
  if (cnt_12 || cnt_13 || cnt_14 || cnt_17 || cnt_18 || cnt_19) begin
    wh_nxt = dp_wh_out;
  end
  else begin
    wh_nxt = 32'd0;
  end
end


// add_ux_wh_in_ux
// always @(*) begin
//   if (cnt_8 || cnt_9 || cnt_10 || cnt_13 || cnt_14 || cnt_15 || cnt_18 || cnt_19 || cnt_20) begin
//     add_uxwh_in_ux = ux_r;
//     add_uxwh_in_wh = wh_r;
//   end
//   else begin
//     add_uxwh_in_ux = 32'd0;
//     add_uxwh_in_wh = 32'd0;
//   end
// end

// exp_in
always @(*) begin
  exp_in = {~add_uxwh_out[31], add_uxwh_out[30:0]};
end

// exp_out_r
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    exp_out_r <= 32'd0;
  end
  else begin
    exp_out_r <= exp_out_nxt;
  end
end

always @(*) begin
  if (cnt_8 || cnt_9 || cnt_10 || cnt_13 || cnt_14 || cnt_15 || cnt_18 || cnt_19 || cnt_20) begin
    exp_out_nxt = exp_out;
  end
  else begin
    exp_out_nxt = exp_out_r;
  end
end


// h1
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    h1_r[0] <= 32'd0;
  end
  else begin
    h1_r[0] <= h1_nxt[0];
  end
end

always @(*) begin
  if (cnt_9) begin
    h1_nxt[0] = recip_out;
  end
  else begin
    h1_nxt[0] = h1_r[0];
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    h1_r[1] <= 32'd0;
  end
  else begin
    h1_r[1] <= h1_nxt[1];
  end
end

always @(*) begin
  if (cnt_10) begin
    h1_nxt[1] = recip_out;
  end
  else begin
    h1_nxt[1] = h1_r[1];
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    h1_r[2] <= 32'd0;
  end
  else begin
    h1_r[2] <= h1_nxt[2];
  end
end

always @(*) begin
  if (cnt_11) begin
    h1_nxt[2] = recip_out;
  end
  else begin
    h1_nxt[2] = h1_r[2];
  end
end

// h2
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    h2_r[0] <= 32'd0;
  end
  else begin
    h2_r[0] <= h2_nxt[0];
  end
end

always @(*) begin
  if (cnt_14) begin
    h2_nxt[0] = recip_out;
  end
  else begin
    h2_nxt[0] = h2_r[0];
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    h2_r[1] <= 32'd0;
  end
  else begin
    h2_r[1] <= h2_nxt[1];
  end
end

always @(*) begin
  if (cnt_15) begin
    h2_nxt[1] = recip_out;
  end
  else begin
    h2_nxt[1] = h2_r[1];
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    h2_r[2] <= 32'd0;
  end
  else begin
    h2_r[2] <= h2_nxt[2];
  end
end

always @(*) begin
  if (cnt_16) begin
    h2_nxt[2] = recip_out;
  end
  else begin
    h2_nxt[2] = h2_r[2];
  end
end


// h3
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    h3_r[0] <= 32'd0;
  end
  else begin
    h3_r[0] <= h3_nxt[0];
  end
end

always @(*) begin
  if (cnt_19) begin
    h3_nxt[0] = recip_out;
  end
  else begin
    h3_nxt[0] = h3_r[0];
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    h3_r[1] <= 32'd0;
  end
  else begin
    h3_r[1] <= h3_nxt[1];
  end
end

always @(*) begin
  if (cnt_20) begin
    h3_nxt[1] = recip_out;
  end
  else begin
    h3_nxt[1] = h3_r[1];
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    h3_r[2] <= 32'd0;
  end
  else begin
    h3_r[2] <= h3_nxt[2];
  end
end

always @(*) begin
  if (cnt_21) begin
    h3_nxt[2] = recip_out;
  end
  else begin
    h3_nxt[2] = h3_r[2];
  end
end

// relu_out
always @(*) begin
  if (dp_vh_out[31]) begin
    relu_out = 32'd0;
  end
  else begin
    relu_out = dp_vh_out;
  end
end


// y1
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    y1_r[0] <= 32'd0;
  end
  else begin
    y1_r[0] <= y1_nxt[0];
  end
end

always @(*) begin
  if (cnt_12) begin
    y1_nxt[0] = relu_out;
  end
  else begin
    y1_nxt[0] = y1_r[0];
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    y1_r[1] <= 32'd0;
  end
  else begin
    y1_r[1] <= y1_nxt[1];
  end
end

always @(*) begin
  if (cnt_13) begin
    y1_nxt[1] = relu_out;
  end
  else begin
    y1_nxt[1] = y1_r[1];
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    y1_r[2] <= 32'd0;
  end
  else begin
    y1_r[2] <= y1_nxt[2];
  end
end

always @(*) begin
  if (cnt_14) begin
    y1_nxt[2] = relu_out;
  end
  else begin
    y1_nxt[2] = y1_r[2];
  end
end


// y2
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    y2_r[0] <= 32'd0;
  end
  else begin
    y2_r[0] <= y2_nxt[0];
  end
end

always @(*) begin
  if (cnt_17) begin
    y2_nxt[0] = relu_out;
  end
  else begin
    y2_nxt[0] = y2_r[0];
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    y2_r[1] <= 32'd0;
  end
  else begin
    y2_r[1] <= y2_nxt[1];
  end
end

always @(*) begin
  if (cnt_18) begin
    y2_nxt[1] = relu_out;
  end
  else begin
    y2_nxt[1] = y2_r[1];
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    y2_r[2] <= 32'd0;
  end
  else begin
    y2_r[2] <= y2_nxt[2];
  end
end

always @(*) begin
  if (cnt_19) begin
    y2_nxt[2] = relu_out;
  end
  else begin
    y2_nxt[2] = y2_r[2];
  end
end


// out_valid
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_valid <= 1'b0;
  end
  else begin
    out_valid <= out_valid_nxt;
  end
end

always @(*) begin
  if (out_valid_high) begin
    out_valid_nxt = 1'b1;
  end
  else begin
    out_valid_nxt = 1'b0;
  end
end


// out
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out <= 32'd0;
  end
  else begin
    out <= out_nxt;
  end
end

always @(*) begin
  if (cnt_22 || cnt_23 || cnt_24) begin
    out_nxt = relu_out;
  end
  else if (cnt_16) begin
    out_nxt = y1_r[0];
  end
  else if (cnt_17) begin
    out_nxt = y1_r[1];
  end
  else if (cnt_18) begin
    out_nxt = y1_r[2];
  end
  else if (cnt_19) begin
    out_nxt = y2_r[0];
  end
  else if (cnt_20) begin
    out_nxt = y2_r[1];
  end
  else if (cnt_21) begin
    out_nxt = y2_r[2];
  end
  else begin
    out_nxt = 32'd0;
  end
end



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                 module instantiation                                                                  //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U1 (
//   .a(weight_u_reg),
//   .b(weight_w_reg),
//   .c(weight_v_reg),
//   .rnd(3'b000),
//   .z(z_inst),
//   .status()
// );


// DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 (
//   .a(weight_u_reg),
//   .b(weight_w_reg),
//   .rnd(3'b000),
//   .z(mult_out),
//   .status()
// );

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_dp3) u_DW_fp_dp3_Ux (
  .a(dp_ux_in_u0),
  .b(dp_ux_in_x0),
  .c(dp_ux_in_u1),
  .d(dp_ux_in_x1),
  .e(dp_ux_in_u2),
  .f(dp_ux_in_x2),
  .rnd(inst_rnd),
  .z(dp_ux_out),
  .status()
);

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_dp3) u_DW_fp_dp3_Wh (
  .a(dp_wh_in_w0),
  .b(dp_wh_in_h0),
  .c(dp_wh_in_w1),
  .d(dp_wh_in_h1),
  .e(dp_wh_in_w2),
  .f(dp_wh_in_h2),
  .rnd(inst_rnd),
  .z(dp_wh_out),
  .status()
);

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_dp3) u_DW_fp_dp3_Vh (
  .a(dp_vh_in_v0),
  .b(dp_vh_in_h0),
  .c(dp_vh_in_v1),
  .d(dp_vh_in_h1),
  .e(dp_vh_in_v2),
  .f(dp_vh_in_h2),
  .rnd(inst_rnd),
  .z(dp_vh_out),
  .status()
);

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) u_DW_fp_add_Ux_Wh (
  .a(ux_r),
  .b(wh_r),
  .rnd(inst_rnd),
  .z(add_uxwh_out),
  .status()
);

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_exp) u_DW_fp_exp (
  .a(exp_in),
  .z(exp_out),
  .status() 
);

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) u_DW_fp_add_add1 (
  .a(ieee_one),
  .b(exp_out_r),
  .rnd(inst_rnd),
  .z(add_1_out),
  .status()
);

DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance) u_DW_fp_recip (
  .a(add_1_out),
  .rnd(inst_rnd),
  .z(recip_out),
  .status()
);


assign cnt_7              = cnt_r == 5'd7;
assign cnt_8              = cnt_r == 5'd8;
assign cnt_9              = cnt_r == 5'd9;
assign cnt_10             = cnt_r == 5'd10;
assign cnt_11             = cnt_r == 5'd11;
assign cnt_12             = cnt_r == 5'd12;
assign cnt_13             = cnt_r == 5'd13;
assign cnt_14             = cnt_r == 5'd14;
assign cnt_15             = cnt_r == 5'd15;
assign cnt_16             = cnt_r == 5'd16;
assign cnt_17             = cnt_r == 5'd17;
assign cnt_18             = cnt_r == 5'd18;
assign cnt_19             = cnt_r == 5'd19;
assign cnt_20             = cnt_r == 5'd20;
assign cnt_21             = cnt_r == 5'd21;
assign cnt_22             = cnt_r == 5'd22;
assign cnt_23             = cnt_r == 5'd23;
assign cnt_24             = cnt_r == 5'd24;
assign cnt_rst            = cnt_r == 5'd0;
assign out_valid_high     = cnt_r >= 5'd16;



endmodule