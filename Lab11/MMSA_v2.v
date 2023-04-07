// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : MMSA.v
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                 SYN_AREA        CLK_PERIOD  CYCLE_NUM  CORE_AREA    CHIP_AREA    PERFORMANCE(CHIP_AREA^2*CLK_PERIOD)
// 1.0     2022-12-18 Brian Hsieh                                  2366932.484652  18.0        8/10/14    3291153.466  7316571.230  9.635798621459468322e14
// 2.0     2022-12-20 Brian Hsieh      revise SRAM to 128 words    2151253.362094  18.0        8/10/14    3010980.773  6895783.916  8.55933044690957311008e14
//                                     revise clk period           2476136.191207  10.0        8/10/14    3474887.170  7589291.660  5.75973479005455556e14
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// Matrix Multiplication with Systolic Array
// -----------------------------------------------------------------------------
// PARAMETERS
// PARAM_NAME RANGE      : DESCRIPTION           : DEFAULT
//
// -----------------------------------------------------------------------------
// REUSE ISSUES
// Reset Schemes : asynchronous active-low reset, rst_n
// Clock Domains : single clock, clk
// Asynchronous I/F : N/A
// Instantiations : RA1SH(SRAM 128words x 128 bits x2), PE(Processing Elements x64)
// Other :
// -----------------------------------------------------------------------------

module MMSA(
// input signals
  clk,
  rst_n,
  in_valid,
  in_valid2,
  matrix,
  matrix_size,
  i_mat_idx,
  w_mat_idx,
  
// output signals
  out_valid,
  out_value
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input               clk;
input               rst_n;
input               in_valid;
input               in_valid2;
input               matrix;
input       [  1:0] matrix_size;
input               i_mat_idx;
input               w_mat_idx;

output reg          out_valid;
output reg          out_value;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
localparam IDLE       = 2'b00;
localparam WRITE      = 2'b01;
localparam READ       = 2'b10;
localparam OUT        = 2'b11;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------

reg         [  1:0] current_state;
reg         [  1:0] next_state;

reg         [  1:0] in_valid2_cnt_cs;
reg         [  1:0] in_valid2_cnt_ns;

reg         [  3:0] i_mat_idx_r;
reg         [  3:0] i_mat_idx_nxt;

reg         [  3:0] w_mat_idx_r;
reg         [  3:0] w_mat_idx_nxt;

reg         [  2:0] matrix_size_r;
reg         [  2:0] matrix_size_nxt;
 
reg         [  2:0] write_cnt_cs;
reg         [  4:0] read_cnt_cs ;
reg         [  2:0] write_cnt_ns;
reg         [  4:0] read_cnt_ns ;
// reg         [  2:0] write_cnt_cs_dly1;

reg         [  3:0] write_cnt_singlebit_cs;
reg         [  3:0] write_cnt_singlebit_ns;
reg         [  3:0] write_cnt_singlebit_dly1;


reg  signed [ 37:0] out_value_38bit_cs  [0: 14];
reg  signed [ 37:0] out_value_38bit_ns  [0: 14];

reg         [  5:0] length_cs           [0: 14];
reg         [  5:0] length_ns           [0: 14];

reg         [  5:0] out_length_cnt_cs;
reg         [  5:0] out_length_cnt_ns;

reg         [  3:0] out_num_cnt_cs;
reg         [  3:0] out_num_cnt_ns;

reg                 out_valid_ns;
reg                 out_value_ns;


// RA1SH SRAM module signals
wire                cen;
wire                oen;

reg                 wen_in0_cs ;
reg         [  6:0] addr_in0_cs;
reg  signed [127:0] d_in0_cs   ;
wire signed [127:0] q_in0_cs   ;
reg                 wen_in0_ns ;
reg         [  6:0] addr_in0_ns;
reg  signed [127:0] d_in0_ns   ;


reg                 wen_w0_cs ;
reg         [  6:0] addr_w0_cs;
reg  signed [127:0] d_w0_cs   ;
wire signed [127:0] q_w0_cs   ;
reg                 wen_w0_ns ;
reg         [  6:0] addr_w0_ns;
reg  signed [127:0] d_w0_ns   ;


// PE module signals
reg  signed [127:0] pe_inputa              ;
reg  signed [127:0] pe_inputa_nxt          ;
reg  signed [ 15:0] pe_inputa_dly1         ;
reg  signed [ 15:0] pe_inputa_dly2   [0: 1];
reg  signed [ 15:0] pe_inputa_dly3   [0: 2];
reg  signed [ 15:0] pe_inputa_dly4   [0: 3];
reg  signed [ 15:0] pe_inputa_dly5   [0: 4];
reg  signed [ 15:0] pe_inputa_dly6   [0: 5];
reg  signed [ 15:0] pe_inputa_dly7   [0: 6];
reg  signed [127:0] pe_weight        [0: 7];
reg  signed [127:0] pe_weight_nxt    [0: 7];
wire signed [ 31:0] pe_outputc_32    [0: 7];
wire signed [ 32:0] pe_outputc_33    [0: 1][0: 7];
wire signed [ 33:0] pe_outputc_34    [0: 3][0: 7];
wire signed [ 34:0] pe_outputc_35    [0: 7][0: 7];
wire signed [ 15:0] pe_outputd       [0: 7][0: 7];


// control signals
reg                 in_valid2_end_r;
reg                 in_valid2_end_nxt;
reg                 write_16bit_end;
reg                 write_16bit_end_dly1;
reg                 write_cnt_end;
reg                 write_cnt_end_dly1;
reg                 out_num_cnt_end;
reg                 out_length_cnt_end;
reg                 out_valid_end_cs;
reg                 out_valid_end_ns;
reg                 write_end;
reg                 write_in_end    ;
reg                 write_in_end_r  ;
reg                 write_in_end_nxt;
reg                 read_end;
reg                 pe_valid_r;
reg                 pe_valid_nxt;


//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------


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
        next_state = WRITE;
      end
      else if (in_valid2_end_r) begin
        next_state = READ;
      end
      else begin
        next_state = IDLE;
      end
    end
    WRITE: begin
      if (write_end) begin
        next_state = IDLE;
      end
      else begin
        next_state = WRITE;
      end
    end
    READ: begin
      if (read_end) begin
        next_state = OUT;
      end
      // if (read_end) begin
      //   next_state = IDLE;
      // end
      else begin
        next_state = READ;
      end
    end
    OUT: begin
      if (out_valid_end_cs) begin
        // if (cal_finish) begin
          next_state = IDLE;
        // end
        // else begin
        //   next_state = READ;
        // end
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


// matrix_size decoder
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    matrix_size_r <= 3'd0;
  end
  else begin
    matrix_size_r <= matrix_size_nxt;
  end
end

always @(*) begin
  if (current_state == IDLE) begin
    if (in_valid) begin
      casez(matrix_size)
        2'b00: begin
          matrix_size_nxt = 3'd1;
        end
        2'b01: begin
          matrix_size_nxt = 3'd3;
        end
        2'b1?: begin
          matrix_size_nxt = 3'd7;
        end
      endcase
    end
    else begin
      matrix_size_nxt = matrix_size_r;
    end
  end
  else begin
    matrix_size_nxt = matrix_size_r;
  end
end


// in_valid2_cnt
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    in_valid2_cnt_cs <= 2'd0;
  end
  else begin
    in_valid2_cnt_cs <= in_valid2_cnt_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid2) begin
        in_valid2_cnt_ns = in_valid2_cnt_cs + 2'd1;
      end
      else begin
        in_valid2_cnt_ns = 2'd0;
      end
    end
    default: begin
      in_valid2_cnt_ns = 2'd0;
    end
  endcase
end


// i_mat_idx_r
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    i_mat_idx_r <= 3'd0;
  end
  else begin
    i_mat_idx_r <= i_mat_idx_nxt;
  end
end

genvar iidx;
generate
  for (iidx=0; iidx<4; iidx=iidx+1) begin: i_idx
    always @(*) begin
      if (in_valid2 && in_valid2_cnt_cs == iidx) begin
        i_mat_idx_nxt[3-iidx] = i_mat_idx;
      end
      else begin
        i_mat_idx_nxt[3-iidx] = i_mat_idx_r[3-iidx];
      end
    end
  end
endgenerate


// w_mat_idx_r
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    w_mat_idx_r <= 3'd0;
  end
  else begin
    w_mat_idx_r <= w_mat_idx_nxt;
  end
end

genvar widx;
generate
  for (widx=0; widx<4; widx=widx+1) begin: w_idx
    always @(*) begin
      if (in_valid2 && in_valid2_cnt_cs == widx) begin
        w_mat_idx_nxt[3-widx] = w_mat_idx;
      end
      else begin
        w_mat_idx_nxt[3-widx] = w_mat_idx_r[3-widx];
      end
    end
  end
endgenerate


// write_cnt
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    write_cnt_cs <= 3'd0;
  end
  else begin
    write_cnt_cs <= write_cnt_ns;
  end
end

always @(*) begin
  if (current_state == WRITE) begin
    if (write_cnt_end) begin
      write_cnt_ns = 3'd0;
    end
    else if (write_cnt_singlebit_cs == 4'd15) begin
      write_cnt_ns = write_cnt_cs + 3'd1;
    end
    else begin
      write_cnt_ns = write_cnt_cs;
    end
  end
  else begin
    write_cnt_ns = 3'd0;
  end
end


// write_cnt_cs_dly1
// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n) begin
//     write_cnt_cs_dly1 <= 3'd0;
//   end
//   else begin
//     write_cnt_cs_dly1 <= write_cnt_cs;
//   end
// end


// write_cnt_singlebit
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    write_cnt_singlebit_cs <= 4'd0;
  end
  else begin
    write_cnt_singlebit_cs <= write_cnt_singlebit_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid) begin
        write_cnt_singlebit_ns = 4'd1;
      end
      else begin
        write_cnt_singlebit_ns = 4'd0;
      end
    end
    WRITE: begin
      if (write_16bit_end) begin
        write_cnt_singlebit_ns = 4'd0;
      end
      else begin
        write_cnt_singlebit_ns = write_cnt_singlebit_cs + 4'd1;
      end
    end
    OUT: begin // store out_value
      if (write_16bit_end) begin
        write_cnt_singlebit_ns = 4'd15;
      end
      else begin
        write_cnt_singlebit_ns = write_cnt_singlebit_cs + 4'd1;
      end
    end
    default: begin
      write_cnt_singlebit_ns = 4'd0;
    end
  endcase
end


// write_cnt_singlebit_dly1
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    write_cnt_singlebit_dly1 <= 4'd0;
  end
  else begin
    write_cnt_singlebit_dly1 <= write_cnt_singlebit_cs;
  end
end


// read_cnt
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    read_cnt_cs <= 5'd0;
  end
  else begin
    read_cnt_cs <= read_cnt_ns;
  end
end

always @(*) begin
  if (current_state[1]) begin
    // if (read_end) begin
    //   read_cnt_ns = 4'd0;
    // end
    // else begin
      read_cnt_ns = read_cnt_cs + 5'd1;
    // end
  end
  else begin
    read_cnt_ns = 5'd0;
  end
end


//////////////////////////////////////////////////////
//                   sram_in0                       //
//////////////////////////////////////////////////////

// wen_in0
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    wen_in0_cs <= 1'b1;
  end
  else begin
    wen_in0_cs <= wen_in0_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid) begin
        wen_in0_ns = 1'b0;
      end
      else begin
        wen_in0_ns = 1'b1;
      end
    end
    WRITE: begin
      if (write_in_end_nxt) begin
        wen_in0_ns = 1'b1;
      end
      else begin
        wen_in0_ns = 1'b0;
      end
    end
    default: begin
      wen_in0_ns = 1'b1;
    end
  endcase
end


// addr_in0
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    addr_in0_cs <= 7'd0;
  end
  else begin
    addr_in0_cs <= addr_in0_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid2_end_r) begin
        case(matrix_size_r)
          3'd1: begin
            addr_in0_ns = i_mat_idx_r << 1;
          end
          3'd3: begin
            addr_in0_ns = i_mat_idx_r << 2;
          end
          3'd7: begin
            addr_in0_ns = i_mat_idx_r << 3;
          end
          default: begin
            addr_in0_ns = 7'd0;
          end
        endcase
      end
      else begin
        addr_in0_ns = 7'd0;
      end
    end
    WRITE: begin
      if (write_cnt_end_dly1) begin
        if (write_in_end_nxt) begin
          addr_in0_ns = 7'd0;
        end
        else begin
          addr_in0_ns = addr_in0_cs + 7'd1;
        end
      end
      else begin
        addr_in0_ns = addr_in0_cs;
      end
    end
    READ: begin
      addr_in0_ns = addr_in0_cs + 7'd1;
    end
    default: begin
      addr_in0_ns = 7'd0;
    end
  endcase
end


// d_in0_cs
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    d_in0_cs <= 128'd0;
  end
  else begin
    d_in0_cs <= d_in0_ns;
  end
end

genvar ki0, ki1;
generate
  for (ki0=0; ki0<8; ki0=ki0+1) begin: d_in0_col
    for (ki1=0; ki1<16; ki1=ki1+1) begin: d_in0_row
      always @(*) begin
        case(current_state)
          IDLE, WRITE: begin
            if (write_cnt_cs == ki0 && write_cnt_singlebit_cs == ki1) begin
              d_in0_ns[ki0*16+15-ki1] = matrix;
            end
            else begin
              d_in0_ns[ki0*16+15-ki1] = d_in0_cs[ki0*16+15-ki1];
            end
          end
          default: begin
            d_in0_ns[ki0*16+15-ki1] = 16'd0;
          end
        endcase
      end
    end
  end
endgenerate


//////////////////////////////////////////////////////
//                   sram_w0                        //
//////////////////////////////////////////////////////

// wen_w0
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    wen_w0_cs <= 1'b1;
  end
  else begin
    wen_w0_cs <= wen_w0_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      // if (in_valid) begin
        wen_w0_ns = 1'b1;
      // end
      // else begin
      //   wen_w0_ns = 1'b1;
      // end
    end
    WRITE: begin
      if (!write_in_end_nxt || write_end) begin
        wen_w0_ns = 1'b1;
      end
      else begin
        wen_w0_ns = 1'b0;
      end
    end
    default: begin
      wen_w0_ns = 1'b1;
    end
  endcase
end


// addr_w0
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    addr_w0_cs <= 7'd0;
  end
  else begin
    addr_w0_cs <= addr_w0_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid2_end_r) begin
        case(matrix_size_r)
          3'd1: begin
            addr_w0_ns = w_mat_idx_r << 1;
          end
          3'd3: begin
            addr_w0_ns = w_mat_idx_r << 2;
          end
          3'd7: begin
            addr_w0_ns = w_mat_idx_r << 3;
          end
          default: begin
            addr_w0_ns = 7'd0;
          end
        endcase
      end
      else begin
        addr_w0_ns = 7'd0;
      end
    end
    WRITE: begin
      if (write_in_end) begin
        addr_w0_ns = 7'd0;
      end
      else if (write_cnt_end_dly1) begin
        if (write_end || (!write_in_end_nxt)) begin
          addr_w0_ns = 7'd0;
        end
        else begin
          addr_w0_ns = addr_w0_cs + 7'd1;
        end
      end
      else begin
        addr_w0_ns = addr_w0_cs;
      end
    end
    READ: begin
      addr_w0_ns = addr_w0_cs + 7'd1;
    end
    default: begin
      addr_w0_ns = 7'd0;
    end
  endcase
end


// d_w0_cs
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    d_w0_cs <= 128'd0;
  end
  else begin
    d_w0_cs <= d_w0_ns;
  end
end

genvar kw0, kw1;
generate
  for (kw0=0; kw0<8; kw0=kw0+1) begin: d_w0_col
    for (kw1=0; kw1<16; kw1=kw1+1) begin: d_w0_row
      always @(*) begin
        case(current_state)
          WRITE: begin
            if (write_cnt_cs == kw0 && write_cnt_singlebit_cs == kw1) begin
              d_w0_ns[kw0*16+15-kw1] = matrix;
            end
            else begin
              d_w0_ns[kw0*16+15-kw1] = d_w0_cs[kw0*16+15-kw1];
            end
          end
          // READ: begin
          //   d_w0_ns[kw0*16+15-kw1] = 128'd0;
          // end
          default: begin
            d_w0_ns[kw0*16+15-kw1] = 128'd0;
          end
        endcase
      end
    end
  end
endgenerate


//////////////////////////////////////////////////////
//                       PE                         //
//////////////////////////////////////////////////////


// pe_valid_r
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_valid_r <= 1'b0;
  end
  else begin
    pe_valid_r <= pe_valid_nxt;
  end
end

always @(*) begin
  if (current_state == READ) begin
    if (read_cnt_cs <= matrix_size_r) begin
      pe_valid_nxt = 1'b1;
    end
    else begin
      pe_valid_nxt = 1'b0;
    end
  end
  else begin
    pe_valid_nxt = 1'b0;
  end
end


// pe_inputa
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa <= 128'd0;
  end
  else begin
    pe_inputa <= pe_inputa_nxt;
  end
end

always @(*) begin
  if (pe_valid_r) begin
    pe_inputa_nxt = q_in0_cs;
  end
  else begin
    pe_inputa_nxt = 128'd0;
  end
end


// pe_inputa_dly1
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly1 <= 16'd0;
  end
  else begin
    pe_inputa_dly1 <= pe_inputa[31:16];
  end
end


// pe_inputa_dly2
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly2[0] <= 16'd0;
  end
  else begin
    pe_inputa_dly2[0] <= pe_inputa[47:32];
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly2[1] <= 16'd0;
  end
  else begin
    pe_inputa_dly2[1] <= pe_inputa_dly2[0];
  end
end


// pe_inputa_dly3
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly3[0] <= 16'd0;
  end
  else begin
    pe_inputa_dly3[0] <= pe_inputa[63:48];
  end
end

genvar d3;
generate
  for (d3=0; d3<2; d3=d3+1) begin: dly3
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_inputa_dly3[d3+1] <= 16'd0;
      end
      else begin
        pe_inputa_dly3[d3+1] <= pe_inputa_dly3[d3];
      end
    end
  end
endgenerate


// pe_inputa_dly4
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly4[0] <= 16'd0;
  end
  else begin
    pe_inputa_dly4[0] <= pe_inputa[79:64];
  end
end

genvar d4;
generate
  for (d4=0; d4<3; d4=d4+1) begin: dly4
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_inputa_dly4[d4+1] <= 16'd0;
      end
      else begin
        pe_inputa_dly4[d4+1] <= pe_inputa_dly4[d4];
      end
    end
  end
endgenerate


// pe_inputa_dly5
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly5[0] <= 16'd0;
  end
  else begin
    pe_inputa_dly5[0] <= pe_inputa[95:80];
  end
end

genvar d5;
generate
  for (d5=0; d5<4; d5=d5+1) begin: dly5
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_inputa_dly5[d5+1] <= 16'd0;
      end
      else begin
        pe_inputa_dly5[d5+1] <= pe_inputa_dly5[d5];
      end
    end
  end
endgenerate


// pe_inputa_dly6
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly6[0] <= 16'd0;
  end
  else begin
    pe_inputa_dly6[0] <= pe_inputa[111:96];
  end
end

genvar d6;
generate
  for (d6=0; d6<5; d6=d6+1) begin: dly6
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_inputa_dly6[d6+1] <= 16'd0;
      end
      else begin
        pe_inputa_dly6[d6+1] <= pe_inputa_dly6[d6];
      end
    end
  end
endgenerate


// pe_inputa_dly7
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly7[0] <= 16'd0;
  end
  else begin
    pe_inputa_dly7[0] <= pe_inputa[127:112];
  end
end

genvar d7;
generate
  for (d7=0; d7<6; d7=d7+1) begin: dly7
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_inputa_dly7[d7+1] <= 16'd0;
      end
      else begin
        pe_inputa_dly7[d7+1] <= pe_inputa_dly7[d7];
      end
    end
  end
endgenerate






// pe_weight
genvar w;
generate
  for (w=0; w<8; w=w+1) begin: weight_reg
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_weight[w] <= 128'd0;
      end
      else begin
        pe_weight[w] <= pe_weight_nxt[w];
      end
    end

    always @(*) begin
      if (current_state[1]) begin
        if (read_cnt_cs == w + 1) begin
          pe_weight_nxt[w] = q_w0_cs;
        end
        else if (read_cnt_cs > w + 1) begin
          pe_weight_nxt[w] = pe_weight[w];
        end
        else begin
          pe_weight_nxt[w] = 128'd0;
        end
      end
      else begin
        pe_weight_nxt[w] = 128'd0;
      end
    end
  end
endgenerate


//////////////////////////////////////////////////////
//                output signals                    //
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
    if (out_valid_end_cs || write_cnt_singlebit_cs <= 'd1) begin
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


// out_value_reg
// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n) begin
//     out_value_reg_cs <= 38'd0;
//   end
//   else begin
//     out_value_reg_cs <= out_value_reg_ns;
//   end
// end

// always @(*) begin
//   if (current_state == OUT) begin
//     case(matrix_size_r)
//       4'd1: begin
//         out_value_reg_ns = pe_outputc_33[0][0] + pe_outputc_33[0][1];
//       end
//       4'd3: begin
//         out_value_reg_ns = pe_outputc_34[0][0] + pe_outputc_34[0][1] + pe_outputc_34[0][2] + pe_outputc_34[0][3];
//       end
//       4'd7: begin
//         out_value_reg_ns = pe_outputc_35[0][0] + pe_outputc_35[0][1] + pe_outputc_35[0][2] + pe_outputc_35[0][3] + pe_outputc_35[0][4] + pe_outputc_35[0][5] + pe_outputc_35[0][6] + pe_outputc_35[0][7];
//       end
//       default: begin
//         out_value_reg_ns = 38'd0;
//       end
//     endcase
//   end
//   else begin
//     out_value_reg_ns = 38'd0;
//   end
// end


// out_value_38bit
genvar oi;
generate
  for (oi=0; oi<15; oi=oi+1) begin: out_value_reg
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        out_value_38bit_cs[oi] <= 38'd0;
      end
      else begin
        out_value_38bit_cs[oi] <= out_value_38bit_ns[oi];
      end
    end

    always @(*) begin
      if (current_state == OUT) begin
        case(matrix_size_r)
          3'd1: begin
            if (write_cnt_singlebit_cs == oi && oi < 3) begin
              out_value_38bit_ns[oi] = pe_outputc_33[0][0] + pe_outputc_33[0][1];
            end
            else begin
              out_value_38bit_ns[oi] = out_value_38bit_cs[oi];
            end
          end
          3'd3: begin
            if (write_cnt_singlebit_cs == oi && oi < 7) begin
              out_value_38bit_ns[oi] = pe_outputc_34[0][0] + pe_outputc_34[0][1] + pe_outputc_34[0][2] + pe_outputc_34[0][3];
            end
            else begin
              out_value_38bit_ns[oi] = out_value_38bit_cs[oi];
            end
          end
          3'd7: begin
            if (write_cnt_singlebit_cs == oi && oi < 15) begin
              out_value_38bit_ns[oi] = pe_outputc_35[0][0] + pe_outputc_35[0][1] + pe_outputc_35[0][2] + pe_outputc_35[0][3] + pe_outputc_35[0][4] + pe_outputc_35[0][5] + pe_outputc_35[0][6] + pe_outputc_35[0][7];
            end
            else begin
              out_value_38bit_ns[oi] = out_value_38bit_cs[oi];
            end
          end
          default: begin
            out_value_38bit_ns[oi] = 38'd0;
          end
        endcase
      end
      else begin
        out_value_38bit_ns[oi] = 38'd0;
      end
    end
  end
endgenerate


// length
genvar li;
generate
  for (li=0; li<15; li=li+1) begin: length_reg
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        length_cs[li] <= 6'd0;
      end
      else begin
        length_cs[li] <= length_ns[li];
      end
    end
    
    always @(*) begin
      casez(out_value_38bit_cs[li])
        38'b1?????????????????????????????????????: length_ns[li] = 6'd40;
        38'b01????????????????????????????????????: length_ns[li] = 6'd37;
        38'b001???????????????????????????????????: length_ns[li] = 6'd36;
        38'b0001??????????????????????????????????: length_ns[li] = 6'd35;
        38'b00001?????????????????????????????????: length_ns[li] = 6'd34;
        38'b000001????????????????????????????????: length_ns[li] = 6'd33;
        38'b0000001???????????????????????????????: length_ns[li] = 6'd32;
        38'b00000001??????????????????????????????: length_ns[li] = 6'd31;
        38'b000000001?????????????????????????????: length_ns[li] = 6'd30;
        38'b0000000001????????????????????????????: length_ns[li] = 6'd29;
        38'b00000000001???????????????????????????: length_ns[li] = 6'd28;
        38'b000000000001??????????????????????????: length_ns[li] = 6'd27;
        38'b0000000000001?????????????????????????: length_ns[li] = 6'd26;
        38'b00000000000001????????????????????????: length_ns[li] = 6'd25;
        38'b000000000000001???????????????????????: length_ns[li] = 6'd24;
        38'b0000000000000001??????????????????????: length_ns[li] = 6'd23;
        38'b00000000000000001?????????????????????: length_ns[li] = 6'd22;
        38'b000000000000000001????????????????????: length_ns[li] = 6'd21;
        38'b0000000000000000001???????????????????: length_ns[li] = 6'd20;
        38'b00000000000000000001??????????????????: length_ns[li] = 6'd19;
        38'b000000000000000000001?????????????????: length_ns[li] = 6'd18;
        38'b0000000000000000000001????????????????: length_ns[li] = 6'd17;
        38'b00000000000000000000001???????????????: length_ns[li] = 6'd16;
        38'b000000000000000000000001??????????????: length_ns[li] = 6'd15;
        38'b0000000000000000000000001?????????????: length_ns[li] = 6'd14;
        38'b00000000000000000000000001????????????: length_ns[li] = 6'd13;
        38'b000000000000000000000000001???????????: length_ns[li] = 6'd12;
        38'b0000000000000000000000000001??????????: length_ns[li] = 6'd11;
        38'b00000000000000000000000000001?????????: length_ns[li] = 6'd10;
        38'b000000000000000000000000000001????????: length_ns[li] = 6'd9;
        38'b0000000000000000000000000000001???????: length_ns[li] = 6'd8;
        38'b00000000000000000000000000000001??????: length_ns[li] = 6'd7;
        38'b000000000000000000000000000000001?????: length_ns[li] = 6'd6;
        38'b0000000000000000000000000000000001????: length_ns[li] = 6'd5;
        38'b00000000000000000000000000000000001???: length_ns[li] = 6'd4;
        38'b000000000000000000000000000000000001??: length_ns[li] = 6'd3;
        38'b0000000000000000000000000000000000001?: length_ns[li] = 6'd2;
        38'b0000000000000000000000000000000000000?: length_ns[li] = 6'd1;
      endcase
    end
  end
endgenerate


// out_length_cnt
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_length_cnt_cs <= 6'd0;
  end
  else begin
    out_length_cnt_cs <= out_length_cnt_ns;
  end
end

always @(*) begin
  if (current_state == OUT) begin
    if (out_length_cnt_end || write_cnt_singlebit_dly1 == 'd0) begin
      out_length_cnt_ns = 6'd0;
    end
    else begin
      out_length_cnt_ns = out_length_cnt_cs + 6'd1;
    end
  end
  else begin
    out_length_cnt_ns = 6'd0;
  end
end


// out_num_cnt
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_num_cnt_cs <= 4'd0;
  end
  else begin
    out_num_cnt_cs <= out_num_cnt_ns;
  end
end

always @(*) begin
  if (current_state == OUT) begin
    if (out_valid_end_ns) begin
      out_num_cnt_ns = 4'd0;
    end
    else if (out_length_cnt_end) begin
      out_num_cnt_ns = out_num_cnt_cs + 4'd1;
    end
    else begin
      out_num_cnt_ns = out_num_cnt_cs;
    end
  end
  else begin
    out_num_cnt_ns = 4'd0;
  end
end


// out_value
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_value <= 1'b0;
  end
  else begin
    out_value <= out_value_ns;
  end
end

always @(*) begin
  if (current_state == OUT) begin
    if (out_valid_end_cs || write_cnt_singlebit_cs <= 'd1) begin
      out_value_ns = 1'b0;
    end
    else begin
      if (out_length_cnt_cs <= 6'd5) begin
        out_value_ns = length_cs[out_num_cnt_cs][5-out_length_cnt_cs];
      end
      else if (out_value_38bit_cs[out_num_cnt_cs][37]) begin
        if (out_length_cnt_cs <= 6'd7) begin
          out_value_ns = 1'b1;
        end
        else begin
          out_value_ns = out_value_38bit_cs[out_num_cnt_cs][45-out_length_cnt_cs];
        end
      end
      else begin
        out_value_ns = out_value_38bit_cs[out_num_cnt_cs][5+length_cs[out_num_cnt_cs]-out_length_cnt_cs];
      end
    end
  end
  else begin
    out_value_ns = 1'b0;
  end
end


//////////////////////////////////////////////////////
//                control signals                   //
//////////////////////////////////////////////////////

// in_valid2_end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    in_valid2_end_r <= 1'b0;
  end
  else begin
    in_valid2_end_r <= in_valid2_end_nxt;
  end
end

always @(*) begin
  in_valid2_end_nxt = (in_valid2_cnt_cs == 2'd3);
end

// write_16bit_end
always @(*) begin
  write_16bit_end = (write_cnt_singlebit_cs == 4'd15);
end

// write_16bit_end_dly1
always @(*) begin
  write_16bit_end_dly1 = (write_cnt_singlebit_dly1 == 4'd15);
end

// write_cnt_end
always @(*) begin
  write_cnt_end = (write_cnt_cs == matrix_size_r && write_16bit_end);
end

// write_cnt_end_dly1
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    write_cnt_end_dly1 <= 1'b0;
  end
  else begin
    write_cnt_end_dly1 <= write_cnt_end;
  end
end


// out_num_cnt_end
always @(*) begin
  case (matrix_size_r)
    3'd1: begin
      out_num_cnt_end = (out_num_cnt_cs == 'd2);
    end
    3'd3: begin
      out_num_cnt_end = (out_num_cnt_cs == 'd6);
    end
    3'd7: begin
      out_num_cnt_end = (out_num_cnt_cs == 'd14);
    end
    default: begin
      out_num_cnt_end = 1'b0;
    end
  endcase
end

// out_length_cnt_end
always @(*) begin
  out_length_cnt_end = (out_length_cnt_cs == 5 + length_cs[out_num_cnt_cs]);
end

// out_valid_end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_valid_end_cs <= 1'b0;
  end
  else begin
    out_valid_end_cs <= out_valid_end_ns;
  end
end

always @(*) begin
  out_valid_end_ns = out_length_cnt_end && out_num_cnt_end;
end

// write_in_end
always @(*) begin
  case(matrix_size_r)
    3'd1: begin
      write_in_end = write_cnt_end_dly1 && (addr_in0_cs == 'd31);
    end
    3'd3: begin
      write_in_end = write_cnt_end_dly1 && (addr_in0_cs == 'd63);
    end
    3'd7: begin
      write_in_end = write_cnt_end_dly1 && (addr_in0_cs == 'd127);
    end
    default: begin
      write_in_end = 1'b0;
    end
  endcase
end

// write_in_end_r
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    write_in_end_r <= 1'b0;
  end
  else begin
    write_in_end_r <= write_in_end_nxt;
  end
end

always @(*) begin
  if (write_in_end) begin
    write_in_end_nxt = 1'b1;
  end
  else if (current_state == OUT) begin
    write_in_end_nxt = 1'b0;
  end
  else begin
    write_in_end_nxt = write_in_end_r;
  end
end


// write_end
always @(*) begin
  case(matrix_size_r)
    3'd1: begin
      write_end = write_cnt_end_dly1 && (addr_w0_cs == 'd31);
    end
    3'd3: begin
      write_end = write_cnt_end_dly1 && (addr_w0_cs == 'd63);
    end
    3'd7: begin
      write_end = write_cnt_end_dly1 && (addr_w0_cs == 'd127);
    end
    default: begin
      write_end = 1'b0;
    end
  endcase
end


// read_end
always @(*) begin
  case(matrix_size_r)
    3'd1: begin
      read_end = (read_cnt_cs == 'd3);
    end
    3'd3: begin
      read_end = (read_cnt_cs == 'd5);
    end
    3'd7: begin
      read_end = (read_cnt_cs == 'd9);
    end
    default: begin
      read_end = 1'b0;
    end
  endcase
end


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                 module instantiation                                                                  //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////
//                 SRAM Modules                     //
//////////////////////////////////////////////////////

RA1SH u_RA1SH_input_0 (
  .Q   (q_in0_cs),
  .CLK (clk),
  .CEN (cen),
  .WEN (wen_in0_cs),
  .A   (addr_in0_cs),
  .D   (d_in0_cs),
  .OEN (oen)
);


RA1SH u_RA1SH_weight_0 (
  .Q   (q_w0_cs),
  .CLK (clk),
  .CEN (cen),
  .WEN (wen_w0_cs),
  .A   (addr_w0_cs),
  .D   (d_w0_cs),
  .OEN (oen)
);




//////////////////////////////////////////////////////
//                   PE Modules                     //
//////////////////////////////////////////////////////

PE_32 u_PE11 (
  .clk     (clk               ),
  .rst_n   (rst_n             ),
  .inputa  (pe_inputa[15:0]   ),
  .weight  (pe_weight[0][15:0]),
  .outputc (pe_outputc_32[0]  ),
  .outputd (pe_outputd[0][0]  )
);

genvar i1;
generate
  for (i1=0; i1<7; i1=i1+1) begin: mac_row1
    PE_32 u_PE1(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[0][i1]               ),
      .weight  (pe_weight [0][16*i1+31:16*i1+16]),
      .outputc (pe_outputc_32[i1+1]             ),
      .outputd (pe_outputd[0][i1+1]             )
    );
  end
endgenerate


PE_33_0 u_PE21 (
  .clk     (clk                           ),
  .rst_n   (rst_n                         ),
  .inputa  (pe_inputa_dly1                ),
  .inputb  (pe_outputc_32[0]              ),
  .weight  (pe_weight[1][15:0]            ),
  .outputc (pe_outputc_33[0][0]           ),
  .outputd (pe_outputd[1][0]              )
);

genvar i2;
generate
  for (i2=0; i2<7; i2=i2+1) begin: mac_row2
    PE_33_0 u_PE2(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[1][i2]               ),
      .inputb  (pe_outputc_32[i2+1]             ),
      .weight  (pe_weight [1][16*i2+31:16*i2+16]),
      .outputc (pe_outputc_33[0][i2+1]          ),
      .outputd (pe_outputd[1][i2+1]             )
    );
  end
endgenerate


PE_33 u_PE31 (
  .clk     (clk                  ),
  .rst_n   (rst_n                ),
  .inputa  (pe_inputa_dly2[1]    ),
  .inputb  (pe_outputc_33[0][0]  ),
  .weight  (pe_weight[2][15:0]   ),
  .outputc (pe_outputc_33[1][0]  ),
  .outputd (pe_outputd[2][0]     )
);

genvar i3;
generate
  for (i3=0; i3<7; i3=i3+1) begin: mac_row3
    PE_33 u_PE3(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[2][i3]               ),
      .inputb  (pe_outputc_33[0][i3+1]          ),
      .weight  (pe_weight [2][16*i3+31:16*i3+16]),
      .outputc (pe_outputc_33[1][i3+1]          ),
      .outputd (pe_outputd[2][i3+1]             )
    );
  end
endgenerate


PE_34_0 u_PE41 (
  .clk     (clk                           ),
  .rst_n   (rst_n                         ),
  .inputa  (pe_inputa_dly3[2]             ),
  .inputb  (pe_outputc_33[1][0]           ),
  .weight  (pe_weight[3][15:0]            ),
  .outputc (pe_outputc_34[0][0]           ),
  .outputd (pe_outputd[3][0]              )
);

genvar i4;
generate
  for (i4=0; i4<7; i4=i4+1) begin: mac_row4
    PE_34_0 u_PE4(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[3][i4]               ),
      .inputb  (pe_outputc_33[1][i4+1]          ),
      .weight  (pe_weight [3][16*i4+31:16*i4+16]),
      .outputc (pe_outputc_34[0][i4+1]          ),
      .outputd (pe_outputd[3][i4+1]             )
    );
  end
endgenerate


PE_34 u_PE51 (
  .clk     (clk                  ),
  .rst_n   (rst_n                ),
  .inputa  (pe_inputa_dly4[3]    ),
  .inputb  (pe_outputc_34[0][0]  ),
  .weight  (pe_weight[4][15:0]   ),
  .outputc (pe_outputc_34[1][0]  ),
  .outputd (pe_outputd[4][0]     )
);

genvar i5;
generate
  for (i5=0; i5<7; i5=i5+1) begin: mac_row5
    PE_34 u_PE5(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[4][i5]               ),
      .inputb  (pe_outputc_34[0][i5+1]          ),
      .weight  (pe_weight [4][16*i5+31:16*i5+16]),
      .outputc (pe_outputc_34[1][i5+1]          ),
      .outputd (pe_outputd[4][i5+1]             )
    );
  end
endgenerate


PE_34 u_PE61 (
  .clk     (clk                  ),
  .rst_n   (rst_n                ),
  .inputa  (pe_inputa_dly5[4]    ),
  .inputb  (pe_outputc_34[1][0]  ),
  .weight  (pe_weight[5][15:0]   ),
  .outputc (pe_outputc_34[2][0]  ),
  .outputd (pe_outputd[5][0]     )
);

genvar i6;
generate
  for (i6=0; i6<7; i6=i6+1) begin: mac_row6
    PE_34 u_PE6(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[5][i6]               ),
      .inputb  (pe_outputc_34[1][i6+1]          ),
      .weight  (pe_weight [5][16*i6+31:16*i6+16]),
      .outputc (pe_outputc_34[2][i6+1]          ),
      .outputd (pe_outputd[5][i6+1]             )
    );
  end
endgenerate


PE_34 u_PE71 (
  .clk     (clk                  ),
  .rst_n   (rst_n                ),
  .inputa  (pe_inputa_dly6[5]    ),
  .inputb  (pe_outputc_34[2][0]  ),
  .weight  (pe_weight[6][15:0]   ),
  .outputc (pe_outputc_34[3][0]  ),
  .outputd (pe_outputd[6][0]     )
);

genvar i7;
generate
  for (i7=0; i7<7; i7=i7+1) begin: mac_row7
    PE_34 u_PE7(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[6][i7]               ),
      .inputb  (pe_outputc_34[2][i7+1]          ),
      .weight  (pe_weight [6][16*i7+31:16*i7+16]),
      .outputc (pe_outputc_34[3][i7+1]          ),
      .outputd (pe_outputd[6][i7+1]             )
    );
  end
endgenerate


PE_35_0 u_PE81 (
  .clk     (clk                           ),
  .rst_n   (rst_n                         ),
  .inputa  (pe_inputa_dly7[6]             ),
  .inputb  (pe_outputc_34[3][0]           ),
  .weight  (pe_weight[7][15:0]            ),
  .outputc (pe_outputc_35[0][0]           ),
  .outputd (pe_outputd[7][0]              )
);

genvar i8;
generate
  for (i8=0; i8<7; i8=i8+1) begin: mac_row8
    PE_35_0 u_PE8(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[7][i8]               ),
      .inputb  (pe_outputc_34[3][i8+1]          ),
      .weight  (pe_weight [7][16*i8+31:16*i8+16]),
      .outputc (pe_outputc_35[0][i8+1]          ),
      .outputd (pe_outputd[7][i8+1]             )
    );
  end
endgenerate




assign cen = 1'b0;
assign oen = 1'b0;

endmodule


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                       PE Modules                                                                      //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module PE_32 (
  input                              clk,
  input                              rst_n,
  input       signed     [     15:0] inputa,
  input       signed     [     15:0] weight,
  output reg  signed     [     31:0] outputc,
  output reg  signed     [     15:0] outputd
);


wire signed [     31:0] product;
// wire signed [WIDTH-1:0] product_sign_ext;

// outputc dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputc <= 'd0;
  end
  else begin
    outputc <= product;
  end
end

// outputd dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputd <= 'd0;
  end
  else begin
    outputd <= inputa;
  end
end

// sign extension
// assign product_sign_ext = product[31] ? {{(WIDTH-32){1'b1}}, product} : {{(WIDTH-32){1'b0}}, product};

// dw ip instantiation
// DW02_mult #(16, 16) u_DW02_mult ( .A(inputa), .B(weight), .TC(1'b1), .PRODUCT(product) );
// DW01_add  #(WIDTH) u_DW01_add (.A(product_sign_ext), .B(inputb), .CI(1'b0), .SUM(mac), .CO( ) );
assign product = inputa * weight;

endmodule


module PE_33_0 #(parameter WIDTH = 33)(
  input                              clk,
  input                              rst_n,
  input       signed     [     15:0] inputa,
  input       signed     [WIDTH-2:0] inputb,
  input       signed     [     15:0] weight,
  output reg  signed     [WIDTH-1:0] outputc,
  output reg  signed     [     15:0] outputd
);


wire signed [     31:0] product;
// wire signed [WIDTH-1:0] product_sign_ext;
wire signed [WIDTH-1:0] mac;

// outputc dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputc <= 'd0;
  end
  else begin
    outputc <= mac;
  end
end

// outputd dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputd <= 'd0;
  end
  else begin
    outputd <= inputa;
  end
end

// sign extension
// assign product_sign_ext = product[31] ? {{(WIDTH-32){1'b1}}, product} : {{(WIDTH-32){1'b0}}, product};

// dw ip instantiation
// DW02_mult #(16, 16) u_DW02_mult ( .A(inputa), .B(weight), .TC(1'b1), .PRODUCT(product) );
// DW01_add  #(WIDTH) u_DW01_add (.A(product_sign_ext), .B(inputb), .CI(1'b0), .SUM(mac), .CO( ) );
assign product = inputa * weight;
assign mac     = product + inputb;

endmodule


module PE_33 #(parameter WIDTH = 33)(
  input                              clk,
  input                              rst_n,
  input       signed     [     15:0] inputa,
  input       signed     [WIDTH-1:0] inputb,
  input       signed     [     15:0] weight,
  output reg  signed     [WIDTH-1:0] outputc,
  output reg  signed     [     15:0] outputd
);


wire signed [     31:0] product;
// wire signed [WIDTH-1:0] product_sign_ext;
wire signed [WIDTH-1:0] mac;

// outputc dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputc <= 'd0;
  end
  else begin
    outputc <= mac;
  end
end

// outputd dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputd <= 'd0;
  end
  else begin
    outputd <= inputa;
  end
end

// sign extension
// assign product_sign_ext = product[31] ? {{(WIDTH-32){1'b1}}, product} : {{(WIDTH-32){1'b0}}, product};

// dw ip instantiation
// DW02_mult #(16, 16) u_DW02_mult ( .A(inputa), .B(weight), .TC(1'b1), .PRODUCT(product) );
// DW01_add  #(WIDTH) u_DW01_add (.A(product_sign_ext), .B(inputb), .CI(1'b0), .SUM(mac), .CO( ) );
assign product = inputa * weight;
assign mac     = product + inputb;

endmodule


module PE_34_0 #(parameter WIDTH = 34)(
  input                              clk,
  input                              rst_n,
  input       signed     [     15:0] inputa,
  input       signed     [WIDTH-2:0] inputb,
  input       signed     [     15:0] weight,
  output reg  signed     [WIDTH-1:0] outputc,
  output reg  signed     [     15:0] outputd
);


wire signed [     31:0] product;
// wire signed [WIDTH-1:0] product_sign_ext;
wire signed [WIDTH-1:0] mac;

// outputc dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputc <= 'd0;
  end
  else begin
    outputc <= mac;
  end
end

// outputd dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputd <= 'd0;
  end
  else begin
    outputd <= inputa;
  end
end

// sign extension
// assign product_sign_ext = product[31] ? {{(WIDTH-32){1'b1}}, product} : {{(WIDTH-32){1'b0}}, product};

// dw ip instantiation
// DW02_mult #(16, 16) u_DW02_mult ( .A(inputa), .B(weight), .TC(1'b1), .PRODUCT(product) );
// DW01_add  #(WIDTH) u_DW01_add (.A(product_sign_ext), .B(inputb), .CI(1'b0), .SUM(mac), .CO( ) );
assign product = inputa * weight;
assign mac     = product + inputb;

endmodule


module PE_34 #(parameter WIDTH = 34)(
  input                              clk,
  input                              rst_n,
  input       signed     [     15:0] inputa,
  input       signed     [WIDTH-1:0] inputb,
  input       signed     [     15:0] weight,
  output reg  signed     [WIDTH-1:0] outputc,
  output reg  signed     [     15:0] outputd
);


wire signed [     31:0] product;
// wire signed [WIDTH-1:0] product_sign_ext;
wire signed [WIDTH-1:0] mac;

// outputc dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputc <= 'd0;
  end
  else begin
    outputc <= mac;
  end
end

// outputd dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputd <= 'd0;
  end
  else begin
    outputd <= inputa;
  end
end

// sign extension
// assign product_sign_ext = product[31] ? {{(WIDTH-32){1'b1}}, product} : {{(WIDTH-32){1'b0}}, product};

// dw ip instantiation
// DW02_mult #(16, 16) u_DW02_mult ( .A(inputa), .B(weight), .TC(1'b1), .PRODUCT(product) );
// DW01_add  #(WIDTH) u_DW01_add (.A(product_sign_ext), .B(inputb), .CI(1'b0), .SUM(mac), .CO( ) );
assign product = inputa * weight;
assign mac     = product + inputb;

endmodule


module PE_35_0 #(parameter WIDTH = 35)(
  input                              clk,
  input                              rst_n,
  input       signed     [     15:0] inputa,
  input       signed     [WIDTH-2:0] inputb,
  input       signed     [     15:0] weight,
  output reg  signed     [WIDTH-1:0] outputc,
  output reg  signed     [     15:0] outputd
);


wire signed [     31:0] product;
// wire signed [WIDTH-1:0] product_sign_ext;
wire signed [WIDTH-1:0] mac;

// outputc dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputc <= 'd0;
  end
  else begin
    outputc <= mac;
  end
end

// outputd dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputd <= 'd0;
  end
  else begin
    outputd <= inputa;
  end
end

// sign extension
// assign product_sign_ext = product[31] ? {{(WIDTH-32){1'b1}}, product} : {{(WIDTH-32){1'b0}}, product};

// dw ip instantiation
// DW02_mult #(16, 16) u_DW02_mult ( .A(inputa), .B(weight), .TC(1'b1), .PRODUCT(product) );
// DW01_add  #(WIDTH) u_DW01_add (.A(product_sign_ext), .B(inputb), .CI(1'b0), .SUM(mac), .CO( ) );
assign product = inputa * weight;
assign mac     = product + inputb;

endmodule



module PE_35 #(parameter WIDTH = 35)(
  input                              clk,
  input                              rst_n,
  input       signed     [     15:0] inputa,
  input       signed     [WIDTH-1:0] inputb,
  input       signed     [     15:0] weight,
  output reg  signed     [WIDTH-1:0] outputc,
  output reg  signed     [     15:0] outputd
);


wire signed [     31:0] product;
// wire signed [WIDTH-1:0] product_sign_ext;
wire signed [WIDTH-1:0] mac;

// outputc dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputc <= 'd0;
  end
  else begin
    outputc <= mac;
  end
end

// outputd dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputd <= 'd0;
  end
  else begin
    outputd <= inputa;
  end
end

// sign extension
// assign product_sign_ext = product[31] ? {{(WIDTH-32){1'b1}}, product} : {{(WIDTH-32){1'b0}}, product};

// dw ip instantiation
// DW02_mult #(16, 16) u_DW02_mult ( .A(inputa), .B(weight), .TC(1'b1), .PRODUCT(product) );
// DW01_add  #(WIDTH) u_DW01_add (.A(product_sign_ext), .B(inputb), .CI(1'b0), .SUM(mac), .CO( ) );
assign product = inputa * weight;
assign mac     = product + inputb;

endmodule


module PE_36 #(parameter WIDTH = 36)(
  input                              clk,
  input                              rst_n,
  input       signed     [     15:0] inputa,
  input       signed     [WIDTH-2:0] inputb,
  input       signed     [     15:0] weight,
  output reg  signed     [WIDTH-1:0] outputc,
  output reg  signed     [     15:0] outputd
);


wire signed [     31:0] product;
// wire signed [WIDTH-1:0] product_sign_ext;
wire signed [WIDTH-1:0] mac;

// outputc dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputc <= 'd0;
  end
  else begin
    outputc <= mac;
  end
end

// outputd dff
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    outputd <= 'd0;
  end
  else begin
    outputd <= inputa;
  end
end

// sign extension
// assign product_sign_ext = product[31] ? {{(WIDTH-32){1'b1}}, product} : {{(WIDTH-32){1'b0}}, product};

// dw ip instantiation
// DW02_mult #(16, 16) u_DW02_mult ( .A(inputa), .B(weight), .TC(1'b1), .PRODUCT(product) );
// DW01_add  #(WIDTH) u_DW01_add (.A(product_sign_ext), .B(inputb), .CI(1'b0), .SUM(mac), .CO( ) );
assign product = inputa * weight;
assign mac     = product + inputb;

endmodule

