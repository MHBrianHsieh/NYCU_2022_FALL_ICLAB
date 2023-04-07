// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : MMSA.v
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                 AREA             CYCLE_TIME  PERFORMANCE (AREA^2*CYCLE_TIME)
// 1.0     2022-10-23 Brian Hsieh                                  7636980.630044   20          1.16646946287334502390883872e15
//                                                                 7648210.555796   15          8.7742687058684038843790424e14
//                                                                 9070459.419330   13          1.0695520430102601701094357e15
//                                                                 9161709.226328   12          1.007242991373403203940363008e15
//                                                                 9175873.042409   10          8.4196646090408197912523281e14
//                                                                 8967374.285146   8           6.43310412559181876129930528e14
//                                                                 9051256.111661   7           5.73476660392164234301252447e14
//                                                                 9175410.651712   6.5         5.47223044079075185695451136e14
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
// Instantiations : RA1SH(SRAM x4), PE(Processing Elements x256)
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
input                    clk;
input                    rst_n;
input                    in_valid;
input                    in_valid2;
input             [15:0] matrix;
input             [ 1:0] matrix_size;
input             [ 3:0] i_mat_idx;
input             [ 3:0] w_mat_idx;

output reg               out_valid;
output reg signed [39:0] out_value;
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

reg         [  3:0] matrix_size_r;
reg         [  3:0] matrix_size_nxt;
 
reg         [  3:0] write_cnt_cs;
reg         [  5:0] read_cnt_cs ;
reg         [  3:0] write_cnt_ns;
reg         [  5:0] read_cnt_ns ;
reg         [  3:0] write_cnt_cs_dly1;


reg                 out_valid_ns;
reg  signed [ 39:0] out_value_ns;


// RA1SH SRAM module signals
wire                cen;
wire                oen;

reg                 wen_in0_cs ;
reg         [  7:0] addr_in0_cs;
reg  signed [127:0] d_in0_cs   ;
wire signed [127:0] q_in0_cs   ;
reg                 wen_in0_ns ;
reg         [  7:0] addr_in0_ns;
reg  signed [127:0] d_in0_ns   ;

reg                 wen_in1_cs ;
reg         [  7:0] addr_in1_cs;
reg  signed [127:0] d_in1_cs   ;
wire signed [127:0] q_in1_cs   ;
reg                 wen_in1_ns ;
reg         [  7:0] addr_in1_ns;
reg  signed [127:0] d_in1_ns   ;

reg                 wen_w0_cs ;
reg         [  7:0] addr_w0_cs;
reg  signed [127:0] d_w0_cs   ;
wire signed [127:0] q_w0_cs   ;
reg                 wen_w0_ns ;
reg         [  7:0] addr_w0_ns;
reg  signed [127:0] d_w0_ns   ;

reg                 wen_w1_cs ;
reg         [  7:0] addr_w1_cs;
reg  signed [127:0] d_w1_cs   ;
wire signed [127:0] q_w1_cs   ;
reg                 wen_w1_ns ;
reg         [  7:0] addr_w1_ns;
reg  signed [127:0] d_w1_ns   ;


// PE module signals
reg  signed [255:0] pe_inputa              ;
reg  signed [255:0] pe_inputa_nxt          ;
reg  signed [ 15:0] pe_inputa_dly1         ;
reg  signed [ 15:0] pe_inputa_dly2   [0: 1];
reg  signed [ 15:0] pe_inputa_dly3   [0: 2];
reg  signed [ 15:0] pe_inputa_dly4   [0: 3];
reg  signed [ 15:0] pe_inputa_dly5   [0: 4];
reg  signed [ 15:0] pe_inputa_dly6   [0: 5];
reg  signed [ 15:0] pe_inputa_dly7   [0: 6];
reg  signed [ 15:0] pe_inputa_dly8   [0: 7];
reg  signed [ 15:0] pe_inputa_dly9   [0: 8];
reg  signed [ 15:0] pe_inputa_dly10  [0: 9];
reg  signed [ 15:0] pe_inputa_dly11  [0:10];
reg  signed [ 15:0] pe_inputa_dly12  [0:11];
reg  signed [ 15:0] pe_inputa_dly13  [0:12];
reg  signed [ 15:0] pe_inputa_dly14  [0:13];
reg  signed [ 15:0] pe_inputa_dly15  [0:14];
reg  signed [255:0] pe_weight        [0:15];
reg  signed [255:0] pe_weight_nxt    [0:15];
wire signed [ 35:0] pe_outputc       [0:15][0:15];
wire signed [ 15:0] pe_outputd       [0:15][0:15];


// control signals
reg                 write_end;
reg                 write_in_end    ;
reg                 write_in_end_r  ;
reg                 write_in_end_nxt;
reg                 read_end;
reg                 pe_valid_r;
reg                 pe_valid_nxt;
reg                 out_end;


//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------


// state register
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    current_state <= 0;
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
      else if (in_valid2) begin
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
      else begin
        next_state = READ;
      end
    end
    OUT: begin
      if (out_end) begin
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
    matrix_size_r <= 4'd0;
  end
  else begin
    matrix_size_r <= matrix_size_nxt;
  end
end

always @(*) begin
  if (current_state == IDLE) begin
    if (in_valid) begin
      case(matrix_size)
        2'b00: begin
          matrix_size_nxt = 4'd1;
        end
        2'b01: begin
          matrix_size_nxt = 4'd3;
        end
        2'b10: begin
          matrix_size_nxt = 4'd7;
        end
        2'b11: begin
          matrix_size_nxt = 4'd15;
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


// write_cnt
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    write_cnt_cs <= 4'd0;
  end
  else begin
    write_cnt_cs <= write_cnt_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid) begin
        write_cnt_ns = 4'd1;
      end
      else begin
        write_cnt_ns = 4'd0;
      end
    end
    WRITE: begin
      if (write_cnt_cs == matrix_size_r) begin
        write_cnt_ns = 4'd0;
      end
      else begin
        write_cnt_ns = write_cnt_cs + 4'd1;
      end
    end
    default: begin
      write_cnt_ns = 4'd0;
    end
  endcase
end


// write_cnt_cs_dly1
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    write_cnt_cs_dly1 <= 4'd0;
  end
  else begin
    write_cnt_cs_dly1 <= write_cnt_cs;
  end
end


// read_cnt
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    read_cnt_cs <= 4'd0;
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
      read_cnt_ns = read_cnt_cs + 6'd1;
    // end
  end
  else begin
    read_cnt_ns = 6'd0;
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
      else if (matrix_size_r == 4'd15) begin
        if (write_cnt_cs <= 4'd7) begin
          wen_in0_ns = 1'b0;
        end
        else begin
          wen_in0_ns = 1'b1;
        end
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
    addr_in0_cs <= 8'd0;
  end
  else begin
    addr_in0_cs <= addr_in0_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid2) begin
        case(matrix_size_r)
          4'd1: begin
            addr_in0_ns = i_mat_idx << 1;
          end
          4'd3: begin
            addr_in0_ns = i_mat_idx << 2;
          end
          4'd7: begin
            addr_in0_ns = i_mat_idx << 3;
          end
          4'd15: begin
            addr_in0_ns = i_mat_idx << 4;
          end
          default: begin
            addr_in0_ns = 8'd0;
          end
        endcase
      end
      else begin
        addr_in0_ns = 8'd0;
      end
    end
    WRITE: begin
      if (write_cnt_cs_dly1 == matrix_size_r) begin
        if (write_in_end_nxt) begin
          addr_in0_ns = 8'd0;
        end
        else begin
          addr_in0_ns = addr_in0_cs + 8'd1;
        end
      end
      else begin
        addr_in0_ns = addr_in0_cs;
      end
    end
    READ: begin
      addr_in0_ns = addr_in0_cs + 8'd1;
    end
    default: begin
      addr_in0_ns = 8'd0;
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

genvar ki0;
generate
  for (ki0=0; ki0<8; ki0=ki0+1) begin: d_in0
    always @(*) begin
      case(current_state)
        IDLE, WRITE: begin
          if (write_cnt_cs == ki0) begin
            d_in0_ns[ki0*16+15:ki0*16] = matrix;
          end
          else begin
            d_in0_ns[ki0*16+15:ki0*16] = d_in0_cs[ki0*16+15:ki0*16];
          end
        end
        default: begin
          d_in0_ns[ki0*16+15:ki0*16] = 16'd0;
        end
      endcase
    end
  end
endgenerate


//////////////////////////////////////////////////////
//                   sram_in1                       //
//////////////////////////////////////////////////////

// wen_in1
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    wen_in1_cs <= 1'b1;
  end
  else begin
    wen_in1_cs <= wen_in1_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      // if (in_valid) begin
      //   wen_in1_ns = 1'b0;
      // end
      // else begin
        wen_in1_ns = 1'b1;
      // end
    end
    WRITE: begin
      if (write_in_end_nxt) begin
        wen_in1_ns = 1'b1;
      end
      else if (matrix_size_r == 4'd15) begin
        if (write_cnt_cs > 4'd7) begin
          wen_in1_ns = 1'b0;
        end
        else begin
          wen_in1_ns = 1'b1;
        end
      end
      else begin
        wen_in1_ns = 1'b1;
      end
    end
    default: begin
      wen_in1_ns = 1'b1;
    end
  endcase
end


// addr_in1
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    addr_in1_cs <= 8'd0;
  end
  else begin
    addr_in1_cs <= addr_in1_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid2) begin
        case(matrix_size_r)
          4'd1: begin
            addr_in1_ns = i_mat_idx << 1;
          end
          4'd3: begin
            addr_in1_ns = i_mat_idx << 2;
          end
          4'd7: begin
            addr_in1_ns = i_mat_idx << 3;
          end
          4'd15: begin
            addr_in1_ns = i_mat_idx << 4;
          end
          default: begin
            addr_in1_ns = 8'd0;
          end
        endcase
      end
      else begin
        addr_in1_ns = 8'd0;
      end
    end
    WRITE: begin
      if (write_cnt_cs_dly1 == matrix_size_r) begin
        if (write_in_end_nxt) begin
          addr_in1_ns = 8'd0;
        end
        else begin
          addr_in1_ns = addr_in1_cs + 8'd1;
        end
      end
      else begin
        addr_in1_ns = addr_in1_cs;
      end
    end
    READ: begin
      addr_in1_ns = addr_in1_cs + 8'd1;
    end
    default: begin
      addr_in1_ns = 8'd0;
    end
  endcase
end


// d_in1_cs
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    d_in1_cs <= 128'd0;
  end
  else begin
    d_in1_cs <= d_in1_ns;
  end
end

genvar ki1;
generate
  for (ki1=0; ki1<8; ki1=ki1+1) begin: d_in1
    always @(*) begin
      case(current_state)
        IDLE, WRITE: begin
          if (write_cnt_cs == ki1 + 8) begin
            d_in1_ns[ki1*16+15:ki1*16] = matrix;
          end
          else begin
            d_in1_ns[ki1*16+15:ki1*16] = d_in1_cs[ki1*16+15:ki1*16];
          end
        end
        default: begin
          d_in1_ns[ki1*16+15:ki1*16] = 16'd0;
        end
      endcase
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
      else if (matrix_size_r == 4'd15) begin
        if (write_cnt_cs <= 4'd7) begin
          wen_w0_ns = 1'b0;
        end
        else begin
          wen_w0_ns = 1'b1;
        end
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
    addr_w0_cs <= 8'd0;
  end
  else begin
    addr_w0_cs <= addr_w0_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid2) begin
        case(matrix_size_r)
          4'd1: begin
            addr_w0_ns = w_mat_idx << 1;
          end
          4'd3: begin
            addr_w0_ns = w_mat_idx << 2;
          end
          4'd7: begin
            addr_w0_ns = w_mat_idx << 3;
          end
          4'd15: begin
            addr_w0_ns = w_mat_idx << 4;
          end
          default: begin
            addr_w0_ns = 8'd0;
          end
        endcase
      end
      else begin
        addr_w0_ns = 8'd0;
      end
    end
    WRITE: begin
      if (write_in_end) begin
        addr_w0_ns = 8'd0;
      end
      else if (write_cnt_cs_dly1 == matrix_size_r) begin
        if (write_end || (!write_in_end_nxt)) begin
          addr_w0_ns = 8'd0;
        end
        else begin
          addr_w0_ns = addr_w0_cs + 8'd1;
        end
      end
      else begin
        addr_w0_ns = addr_w0_cs;
      end
    end
    READ: begin
      addr_w0_ns = addr_w0_cs + 8'd1;
    end
    default: begin
      addr_w0_ns = 8'd0;
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

genvar kw0;
generate
  for (kw0=0; kw0<8; kw0=kw0+1) begin: d_w0
    always @(*) begin
      case(current_state)
        WRITE: begin
          if (write_cnt_cs == kw0) begin
            d_w0_ns[kw0*16+15:kw0*16] = matrix;
          end
          else begin
            d_w0_ns[kw0*16+15:kw0*16] = d_w0_cs[kw0*16+15:kw0*16];
          end
        end
        // READ: begin
        //   d_w0_ns[kw0*16+15:kw0*16] = 16'd0;
        // end
        default: begin
          d_w0_ns[kw0*16+15:kw0*16] = 16'd0;
        end
      endcase
    end
  end
endgenerate


//////////////////////////////////////////////////////
//                   sram_w1                        //
//////////////////////////////////////////////////////

// wen_w1
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    wen_w1_cs <= 1'b1;
  end
  else begin
    wen_w1_cs <= wen_w1_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      // if (in_valid) begin
        wen_w1_ns = 1'b1;
      // end
      // else begin
      //   wen_w1_ns = 1'b1;
      // end
    end
    WRITE: begin
      if (!write_in_end_nxt || write_end) begin
        wen_w1_ns = 1'b1;
      end
      else if (matrix_size_r == 4'd15) begin
        if (write_cnt_cs > 4'd7) begin
          wen_w1_ns = 1'b0;
        end
        else begin
          wen_w1_ns = 1'b1;
        end
      end
      else begin
        wen_w1_ns = 1'b1;
      end
    end
    default: begin
      wen_w1_ns = 1'b1;
    end
  endcase
end


// addr_w1
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    addr_w1_cs <= 8'd0;
  end
  else begin
    addr_w1_cs <= addr_w1_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid2) begin
        case(matrix_size_r)
          4'd1: begin
            addr_w1_ns = w_mat_idx << 1;
          end
          4'd3: begin
            addr_w1_ns = w_mat_idx << 2;
          end
          4'd7: begin
            addr_w1_ns = w_mat_idx << 3;
          end
          4'd15: begin
            addr_w1_ns = w_mat_idx << 4;
          end
          default: begin
            addr_w1_ns = 8'd0;
          end
        endcase
      end
      else begin
        addr_w1_ns = 8'd0;
      end
    end
    WRITE: begin
      if (write_in_end) begin
        addr_w1_ns = 8'd0;
      end
      else if (write_cnt_cs_dly1 == matrix_size_r) begin
        if (write_end || (!write_in_end_nxt)) begin
          addr_w1_ns = 8'd0;
        end
        else begin
          addr_w1_ns = addr_w1_cs + 8'd1;
        end
      end
      else begin
        addr_w1_ns = addr_w1_cs;
      end
    end
    READ: begin
      addr_w1_ns = addr_w1_cs + 8'd1;
    end
    default: begin
      addr_w1_ns = 8'd0;
    end
  endcase
end


// d_w1_cs
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    d_w1_cs <= 128'd0;
  end
  else begin
    d_w1_cs <= d_w1_ns;
  end
end

genvar kw1;
generate
  for (kw1=0; kw1<8; kw1=kw1+1) begin: d_w1
    always @(*) begin
      case(current_state)
        WRITE: begin
          if (write_cnt_cs == kw1 + 8) begin
            d_w1_ns[kw1*16+15:kw1*16] = matrix;
          end
          else begin
            d_w1_ns[kw1*16+15:kw1*16] = d_w1_cs[kw1*16+15:kw1*16];
          end
        end
        // READ: begin
        //   d_w1_ns[kw1*16+15:kw1*16] = 16'd0;
        // end
        default: begin
          d_w1_ns[kw1*16+15:kw1*16] = 16'd0;
        end
      endcase
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
    pe_inputa <= 256'd0;
  end
  else begin
    pe_inputa <= pe_inputa_nxt;
  end
end

always @(*) begin
  if (pe_valid_r) begin
    pe_inputa_nxt = {q_in1_cs, q_in0_cs};
  end
  else begin
    pe_inputa_nxt = 256'd0;
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


// pe_inputa_dly8
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly8[0] <= 16'd0;
  end
  else begin
    pe_inputa_dly8[0] <= pe_inputa[143:128];
  end
end

genvar d8;
generate
  for (d8=0; d8<7; d8=d8+1) begin: dly8
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_inputa_dly8[d8+1] <= 16'd0;
      end
      else begin
        pe_inputa_dly8[d8+1] <= pe_inputa_dly8[d8];
      end
    end
  end
endgenerate


// pe_inputa_dly9
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly9[0] <= 16'd0;
  end
  else begin
    pe_inputa_dly9[0] <= pe_inputa[159:144];
  end
end

genvar d9;
generate
  for (d9=0; d9<8; d9=d9+1) begin: dly9
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_inputa_dly9[d9+1] <= 16'd0;
      end
      else begin
        pe_inputa_dly9[d9+1] <= pe_inputa_dly9[d9];
      end
    end
  end
endgenerate


// pe_inputa_dly10
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly10[0] <= 16'd0;
  end
  else begin
    pe_inputa_dly10[0] <= pe_inputa[175:160];
  end
end

genvar d10;
generate
  for (d10=0; d10<9; d10=d10+1) begin: dly10
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_inputa_dly10[d10+1] <= 16'd0;
      end
      else begin
        pe_inputa_dly10[d10+1] <= pe_inputa_dly10[d10];
      end
    end
  end
endgenerate


// pe_inputa_dly11
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly11[0] <= 16'd0;
  end
  else begin
    pe_inputa_dly11[0] <= pe_inputa[191:176];
  end
end

genvar d11;
generate
  for (d11=0; d11<10; d11=d11+1) begin: dly11
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_inputa_dly11[d11+1] <= 16'd0;
      end
      else begin
        pe_inputa_dly11[d11+1] <= pe_inputa_dly11[d11];
      end
    end
  end
endgenerate


// pe_inputa_dly12
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly12[0] <= 16'd0;
  end
  else begin
    pe_inputa_dly12[0] <= pe_inputa[207:192];
  end
end

genvar d12;
generate
  for (d12=0; d12<11; d12=d12+1) begin: dly12
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_inputa_dly12[d12+1] <= 16'd0;
      end
      else begin
        pe_inputa_dly12[d12+1] <= pe_inputa_dly12[d12];
      end
    end
  end
endgenerate


// pe_inputa_dly13
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly13[0] <= 16'd0;
  end
  else begin
    pe_inputa_dly13[0] <= pe_inputa[223:208];
  end
end

genvar d13;
generate
  for (d13=0; d13<12; d13=d13+1) begin: dly13
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_inputa_dly13[d13+1] <= 16'd0;
      end
      else begin
        pe_inputa_dly13[d13+1] <= pe_inputa_dly13[d13];
      end
    end
  end
endgenerate


// pe_inputa_dly14
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly14[0] <= 16'd0;
  end
  else begin
    pe_inputa_dly14[0] <= pe_inputa[239:224];
  end
end

genvar d14;
generate
  for (d14=0; d14<13; d14=d14+1) begin: dly14
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_inputa_dly14[d14+1] <= 16'd0;
      end
      else begin
        pe_inputa_dly14[d14+1] <= pe_inputa_dly14[d14];
      end
    end
  end
endgenerate


// pe_inputa_dly15
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pe_inputa_dly15[0] <= 16'd0;
  end
  else begin
    pe_inputa_dly15[0] <= pe_inputa[255:240];
  end
end

genvar d15;
generate
  for (d15=0; d15<14; d15=d15+1) begin: dly15
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_inputa_dly15[d15+1] <= 16'd0;
      end
      else begin
        pe_inputa_dly15[d15+1] <= pe_inputa_dly15[d15];
      end
    end
  end
endgenerate



// pe_weight
genvar w;
generate
  for (w=0; w<16; w=w+1) begin: weight_reg
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pe_weight[w] <= 256'd0;
      end
      else begin
        pe_weight[w] <= pe_weight_nxt[w];
      end
    end

    always @(*) begin
      if (current_state[1]) begin
        if (read_cnt_cs == w + 1) begin
          pe_weight_nxt[w] = {q_w1_cs, q_w0_cs};
        end
        else if (read_cnt_cs > w + 1) begin
          pe_weight_nxt[w] = pe_weight[w];
        end
        else begin
          pe_weight_nxt[w] = 256'd0;
        end
      end
      else begin
        pe_weight_nxt[w] = 256'd0;
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
    out_valid_ns = 1'b1;
  end
  else begin
    out_valid_ns = 1'b0;
  end
end


// out_value
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_value <= 40'd0;
  end
  else begin
    out_value <= out_value_ns;
  end
end

always @(*) begin
  if (current_state == OUT) begin
    case(matrix_size_r)
      4'd1: begin
        out_value_ns = pe_outputc[1][0] + pe_outputc[1][1];
      end
      4'd3: begin
        out_value_ns = pe_outputc[3][0] + pe_outputc[3][1] + pe_outputc[3][2] + pe_outputc[3][3];
      end
      4'd7: begin
        out_value_ns = pe_outputc[7][0] + pe_outputc[7][1] + pe_outputc[7][2] + pe_outputc[7][3] + pe_outputc[7][4] + pe_outputc[7][5] + pe_outputc[7][6] + pe_outputc[7][7];
      end
      4'd15: begin
        out_value_ns = pe_outputc[15][0] + pe_outputc[15][1] + pe_outputc[15][ 2] + pe_outputc[15][ 3] + pe_outputc[15][ 4] + pe_outputc[15][ 5] + pe_outputc[15][ 6] + pe_outputc[15][ 7] +
                       pe_outputc[15][8] + pe_outputc[15][9] + pe_outputc[15][10] + pe_outputc[15][11] + pe_outputc[15][12] + pe_outputc[15][13] + pe_outputc[15][14] + pe_outputc[15][15];
      end
      default: begin
        out_value_ns = 40'd0;
      end
    endcase
  end
  else begin
    out_value_ns = 40'd0;
  end
end


//////////////////////////////////////////////////////
//                control signals                   //
//////////////////////////////////////////////////////


// write_in_end
always @(*) begin
  case(matrix_size_r)
    4'd1: begin
      write_in_end = (write_cnt_cs_dly1 == 'd1) && (addr_in0_cs == 'd31);
    end
    4'd3: begin
      write_in_end = (write_cnt_cs_dly1 == 'd3) && (addr_in0_cs == 'd63);
    end
    4'd7: begin
      write_in_end = (write_cnt_cs_dly1 == 'd7) && (addr_in0_cs == 'd127);
    end
    4'd15: begin
      write_in_end = (write_cnt_cs_dly1 == 'd15) && (addr_in1_cs == 'd255);
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
    4'd1: begin
      write_end = (write_cnt_cs_dly1 == 'd1) && (addr_w0_cs == 'd31);
    end
    4'd3: begin
      write_end = (write_cnt_cs_dly1 == 'd3) && (addr_w0_cs == 'd63);
    end
    4'd7: begin
      write_end = (write_cnt_cs_dly1 == 'd7) && (addr_w0_cs == 'd127);
    end
    4'd15: begin
      write_end = (write_cnt_cs_dly1 == 'd15) && (addr_w1_cs == 'd255);
    end
    default: begin
      write_end = 1'b0;
    end
  endcase
end


// read_end
always @(*) begin
  case(matrix_size_r)
    4'd1: begin
      read_end = (read_cnt_cs == 'd3);
    end
    4'd3: begin
      read_end = (read_cnt_cs == 'd5);
    end
    4'd7: begin
      read_end = (read_cnt_cs == 'd9);
    end
    4'd15: begin
      read_end = (read_cnt_cs == 'd17);
    end
    default: begin
      read_end = 1'b0;
    end
  endcase
end

always @(*) begin
  case(matrix_size_r)
    4'd1: begin
      out_end = (read_cnt_cs == 'd6);
    end
    4'd3: begin
      out_end = (read_cnt_cs == 'd12);
    end
    4'd7: begin
      out_end = (read_cnt_cs == 'd24);
    end
    4'd15: begin
      out_end = (read_cnt_cs == 'd48);
    end
    default: begin
      out_end = 1'b0;
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

RA1SH u_RA1SH_input_1 (
  .Q   (q_in1_cs),
  .CLK (clk),
  .CEN (cen),
  .WEN (wen_in1_cs),
  .A   (addr_in1_cs),
  .D   (d_in1_cs),
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

RA1SH u_RA1SH_weight_1 (
  .Q   (q_w1_cs),
  .CLK (clk),
  .CEN (cen),
  .WEN (wen_w1_cs),
  .A   (addr_w1_cs),
  .D   (d_w1_cs),
  .OEN (oen)
);


//////////////////////////////////////////////////////
//                   PE Modules                     //
//////////////////////////////////////////////////////

PE u_PE11 (
  .clk     (clk               ),
  .rst_n   (rst_n             ),
  .inputa  (pe_inputa[15:0]   ),
  .inputb  (36'd0             ),
  .weight  (pe_weight[0][15:0]),
  .outputc (pe_outputc[0][0]  ),
  .outputd (pe_outputd[0][0]  )
);

genvar i1;
generate
  for (i1=0; i1<15; i1=i1+1) begin: mac_row1
    PE u_PE1(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[0][i1]               ),
      .inputb  (36'd0                           ),
      .weight  (pe_weight [0][16*i1+31:16*i1+16]),
      .outputc (pe_outputc[0][i1+1]             ),
      .outputd (pe_outputd[0][i1+1]             )
    );
  end
endgenerate


PE u_PE21 (
  .clk     (clk               ),
  .rst_n   (rst_n             ),
  .inputa  (pe_inputa_dly1    ),
  .inputb  (pe_outputc[0][0]  ),
  .weight  (pe_weight[1][15:0]),
  .outputc (pe_outputc[1][0]  ),
  .outputd (pe_outputd[1][0]  )
);

genvar i2;
generate
  for (i2=0; i2<15; i2=i2+1) begin: mac_row2
    PE u_PE2(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[1][i2]               ),
      .inputb  (pe_outputc[0][i2+1]             ),
      .weight  (pe_weight [1][16*i2+31:16*i2+16]),
      .outputc (pe_outputc[1][i2+1]             ),
      .outputd (pe_outputd[1][i2+1]             )
    );
  end
endgenerate


PE u_PE31 (
  .clk     (clk               ),
  .rst_n   (rst_n             ),
  .inputa  (pe_inputa_dly2[1] ),
  .inputb  (pe_outputc[1][0]  ),
  .weight  (pe_weight[2][15:0]),
  .outputc (pe_outputc[2][0]  ),
  .outputd (pe_outputd[2][0]  )
);

genvar i3;
generate
  for (i3=0; i3<15; i3=i3+1) begin: mac_row3
    PE u_PE3(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[2][i3]               ),
      .inputb  (pe_outputc[1][i3+1]             ),
      .weight  (pe_weight [2][16*i3+31:16*i3+16]),
      .outputc (pe_outputc[2][i3+1]             ),
      .outputd (pe_outputd[2][i3+1]             )
    );
  end
endgenerate


PE u_PE41 (
  .clk     (clk               ),
  .rst_n   (rst_n             ),
  .inputa  (pe_inputa_dly3[2] ),
  .inputb  (pe_outputc[2][0]  ),
  .weight  (pe_weight[3][15:0]),
  .outputc (pe_outputc[3][0]  ),
  .outputd (pe_outputd[3][0]  )
);

genvar i4;
generate
  for (i4=0; i4<15; i4=i4+1) begin: mac_row4
    PE u_PE4(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[3][i4]               ),
      .inputb  (pe_outputc[2][i4+1]             ),
      .weight  (pe_weight [3][16*i4+31:16*i4+16]),
      .outputc (pe_outputc[3][i4+1]             ),
      .outputd (pe_outputd[3][i4+1]             )
    );
  end
endgenerate


PE u_PE51 (
  .clk     (clk               ),
  .rst_n   (rst_n             ),
  .inputa  (pe_inputa_dly4[3] ),
  .inputb  (pe_outputc[3][0]  ),
  .weight  (pe_weight[4][15:0]),
  .outputc (pe_outputc[4][0]  ),
  .outputd (pe_outputd[4][0]  )
);

genvar i5;
generate
  for (i5=0; i5<15; i5=i5+1) begin: mac_row5
    PE u_PE5(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[4][i5]               ),
      .inputb  (pe_outputc[3][i5+1]             ),
      .weight  (pe_weight [4][16*i5+31:16*i5+16]),
      .outputc (pe_outputc[4][i5+1]             ),
      .outputd (pe_outputd[4][i5+1]             )
    );
  end
endgenerate


PE u_PE61 (
  .clk     (clk               ),
  .rst_n   (rst_n             ),
  .inputa  (pe_inputa_dly5[4] ),
  .inputb  (pe_outputc[4][0]  ),
  .weight  (pe_weight[5][15:0]),
  .outputc (pe_outputc[5][0]  ),
  .outputd (pe_outputd[5][0]  )
);

genvar i6;
generate
  for (i6=0; i6<15; i6=i6+1) begin: mac_row6
    PE u_PE6(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[5][i6]               ),
      .inputb  (pe_outputc[4][i6+1]             ),
      .weight  (pe_weight [5][16*i6+31:16*i6+16]),
      .outputc (pe_outputc[5][i6+1]             ),
      .outputd (pe_outputd[5][i6+1]             )
    );
  end
endgenerate


PE u_PE71 (
  .clk     (clk               ),
  .rst_n   (rst_n             ),
  .inputa  (pe_inputa_dly6[5] ),
  .inputb  (pe_outputc[5][0]  ),
  .weight  (pe_weight[6][15:0]),
  .outputc (pe_outputc[6][0]  ),
  .outputd (pe_outputd[6][0]  )
);

genvar i7;
generate
  for (i7=0; i7<15; i7=i7+1) begin: mac_row7
    PE u_PE7(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[6][i7]               ),
      .inputb  (pe_outputc[5][i7+1]             ),
      .weight  (pe_weight [6][16*i7+31:16*i7+16]),
      .outputc (pe_outputc[6][i7+1]             ),
      .outputd (pe_outputd[6][i7+1]             )
    );
  end
endgenerate


PE u_PE81 (
  .clk     (clk               ),
  .rst_n   (rst_n             ),
  .inputa  (pe_inputa_dly7[6] ),
  .inputb  (pe_outputc[6][0]  ),
  .weight  (pe_weight[7][15:0]),
  .outputc (pe_outputc[7][0]  ),
  .outputd (pe_outputd[7][0]  )
);

genvar i8;
generate
  for (i8=0; i8<15; i8=i8+1) begin: mac_row8
    PE u_PE8(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[7][i8]               ),
      .inputb  (pe_outputc[6][i8+1]             ),
      .weight  (pe_weight [7][16*i8+31:16*i8+16]),
      .outputc (pe_outputc[7][i8+1]             ),
      .outputd (pe_outputd[7][i8+1]             )
    );
  end
endgenerate


PE u_PE91 (
  .clk     (clk               ),
  .rst_n   (rst_n             ),
  .inputa  (pe_inputa_dly8[7] ),
  .inputb  (pe_outputc[7][0]  ),
  .weight  (pe_weight[8][15:0]),
  .outputc (pe_outputc[8][0]  ),
  .outputd (pe_outputd[8][0]  )
);

genvar i9;
generate
  for (i9=0; i9<15; i9=i9+1) begin: mac_row9
    PE u_PE9(
      .clk     (clk                             ),
      .rst_n   (rst_n                           ),
      .inputa  (pe_outputd[8][i9]               ),
      .inputb  (pe_outputc[7][i9+1]             ),
      .weight  (pe_weight [8][16*i9+31:16*i9+16]),
      .outputc (pe_outputc[8][i9+1]             ),
      .outputd (pe_outputd[8][i9+1]             )
    );
  end
endgenerate


PE u_PEa1 (
  .clk     (clk               ),
  .rst_n   (rst_n             ),
  .inputa  (pe_inputa_dly9[8] ),
  .inputb  (pe_outputc[8][0]  ),
  .weight  (pe_weight[9][15:0]),
  .outputc (pe_outputc[9][0]  ),
  .outputd (pe_outputd[9][0]  )
);

genvar i10;
generate
  for (i10=0; i10<15; i10=i10+1) begin: mac_rowa
    PE u_PEa(
      .clk     (clk                               ),
      .rst_n   (rst_n                             ),
      .inputa  (pe_outputd[9][i10]                ),
      .inputb  (pe_outputc[8][i10+1]              ),
      .weight  (pe_weight [9][16*i10+31:16*i10+16]),
      .outputc (pe_outputc[9][i10+1]              ),
      .outputd (pe_outputd[9][i10+1]              )
    );
  end
endgenerate


PE u_PEb1 (
  .clk     (clk                ),
  .rst_n   (rst_n              ),
  .inputa  (pe_inputa_dly10[9] ),
  .inputb  (pe_outputc[9][0]   ),
  .weight  (pe_weight[10][15:0]),
  .outputc (pe_outputc[10][0]  ),
  .outputd (pe_outputd[10][0]  )
);

genvar i11;
generate
  for (i11=0; i11<15; i11=i11+1) begin: mac_rowb
    PE u_PEb(
      .clk     (clk                                ),
      .rst_n   (rst_n                              ),
      .inputa  (pe_outputd[10][i11]                ),
      .inputb  (pe_outputc[ 9][i11+1]              ),
      .weight  (pe_weight [10][16*i11+31:16*i11+16]),
      .outputc (pe_outputc[10][i11+1]              ),
      .outputd (pe_outputd[10][i11+1]              )
    );
  end
endgenerate


PE u_PEc1 (
  .clk     (clk                 ),
  .rst_n   (rst_n               ),
  .inputa  (pe_inputa_dly11[10] ),
  .inputb  (pe_outputc[10][0]   ),
  .weight  (pe_weight [11][15:0]),
  .outputc (pe_outputc[11][0]   ),
  .outputd (pe_outputd[11][0]   )
);

genvar i12;
generate
  for (i12=0; i12<15; i12=i12+1) begin: mac_rowc
    PE u_PEc(
      .clk     (clk                                ),
      .rst_n   (rst_n                              ),
      .inputa  (pe_outputd[11][i12]                ),
      .inputb  (pe_outputc[10][i12+1]              ),
      .weight  (pe_weight [11][16*i12+31:16*i12+16]),
      .outputc (pe_outputc[11][i12+1]              ),
      .outputd (pe_outputd[11][i12+1]              )
    );
  end
endgenerate


PE u_PEd1 (
  .clk     (clk                 ),
  .rst_n   (rst_n               ),
  .inputa  (pe_inputa_dly12[11] ),
  .inputb  (pe_outputc[11][0]   ),
  .weight  (pe_weight [12][15:0]),
  .outputc (pe_outputc[12][0]   ),
  .outputd (pe_outputd[12][0]   )
);

genvar i13;
generate
  for (i13=0; i13<15; i13=i13+1) begin: mac_rowd
    PE u_PEd(
      .clk     (clk                                ),
      .rst_n   (rst_n                              ),
      .inputa  (pe_outputd[12][i13]                ),
      .inputb  (pe_outputc[11][i13+1]              ),
      .weight  (pe_weight [12][16*i13+31:16*i13+16]),
      .outputc (pe_outputc[12][i13+1]              ),
      .outputd (pe_outputd[12][i13+1]              )
    );
  end
endgenerate


PE u_PEe1 (
  .clk     (clk                 ),
  .rst_n   (rst_n               ),
  .inputa  (pe_inputa_dly13[12] ),
  .inputb  (pe_outputc[12][0]   ),
  .weight  (pe_weight [13][15:0]),
  .outputc (pe_outputc[13][0]   ),
  .outputd (pe_outputd[13][0]   )
);

genvar i14;
generate
  for (i14=0; i14<15; i14=i14+1) begin: mac_rowe
    PE u_PEe(
      .clk     (clk                                ),
      .rst_n   (rst_n                              ),
      .inputa  (pe_outputd[13][i14]                ),
      .inputb  (pe_outputc[12][i14+1]              ),
      .weight  (pe_weight [13][16*i14+31:16*i14+16]),
      .outputc (pe_outputc[13][i14+1]              ),
      .outputd (pe_outputd[13][i14+1]              )
    );
  end
endgenerate


PE u_PEf1 (
  .clk     (clk                 ),
  .rst_n   (rst_n               ),
  .inputa  (pe_inputa_dly14[13] ),
  .inputb  (pe_outputc[13][0]   ),
  .weight  (pe_weight [14][15:0]),
  .outputc (pe_outputc[14][0]   ),
  .outputd (pe_outputd[14][0]   )
);

genvar i15;
generate
  for (i15=0; i15<15; i15=i15+1) begin: mac_rowf
    PE u_PEf(
      .clk     (clk                                ),
      .rst_n   (rst_n                              ),
      .inputa  (pe_outputd[14][i15]                ),
      .inputb  (pe_outputc[13][i15+1]              ),
      .weight  (pe_weight [14][16*i15+31:16*i15+16]),
      .outputc (pe_outputc[14][i15+1]              ),
      .outputd (pe_outputd[14][i15+1]              )
    );
  end
endgenerate


PE u_PEg1 (
  .clk     (clk                 ),
  .rst_n   (rst_n               ),
  .inputa  (pe_inputa_dly15[14] ),
  .inputb  (pe_outputc[14][0]   ),
  .weight  (pe_weight [15][15:0]),
  .outputc (pe_outputc[15][0]   ),
  .outputd (pe_outputd[15][0]   )
);

genvar i16;
generate
  for (i16=0; i16<15; i16=i16+1) begin: mac_rowg
    PE u_PEg(
      .clk     (clk                                ),
      .rst_n   (rst_n                              ),
      .inputa  (pe_outputd[15][i16]                ),
      .inputb  (pe_outputc[14][i16+1]              ),
      .weight  (pe_weight [15][16*i16+31:16*i16+16]),
      .outputc (pe_outputc[15][i16+1]              ),
      .outputd (pe_outputd[15][i16+1]              )
    );
  end
endgenerate



assign cen = 1'b0;
assign oen = 1'b0;

endmodule



module PE #(parameter WIDTH = 36)(
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