// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : BP.v
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                     AREA          CYCLE
// 1.0     2022-10-08 Brian Hsieh                                      19066.925030  1 PER PATTERN
// 2.0     2022-10-10 Brian Hsieh      omit out_valid_cnt              18431.582622  1 PER PATTERN
//                                     revise pfm_shift_reg logic      17543.433808  1 PER PATTERN
//                                     omit or gates in next_obs       17493.537812  1 PER PATTERN
//                                     revise out_shift_reg_in logic   17456.947408  1 PER PATTERN
// 3.0     2022-10-10 Brian Hsieh      revise obs                      17230.752206  1 PER PATTERN
// 3.1     2022-10-10 Brian Hsieh      revise some logic               17174.203406  1 PER PATTERN (final)
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// Block Party mode in Fall Guys
// -----------------------------------------------------------------------------
// PARAMETERS
// PARAM_NAME RANGE      : DESCRIPTION           : DEFAULT
//
// -----------------------------------------------------------------------------
// REUSE ISSUES
// Reset Schemes : asynchronous active-low reset, rst_n
// Clock Domains : single clock, clk
// Asynchronous I/F : N/A
// Instantiations : N/A
// Other : 
// -----------------------------------------------------------------------------

module BP(
  clk,
  rst_n,
  in_valid,
  guy,
  in0,
  in1,
  in2,
  in3,
  in4,
  in5,
  in6,
  in7,
  
  out_valid,
  out
);

input              clk;
input              rst_n;
input              in_valid;
input       [ 2:0] guy;
input       [ 1:0] in0, in1, in2, in3, in4, in5, in6, in7;
output reg         out_valid;
output reg  [ 1:0] out;

reg         [ 1:0] current_state;
reg         [ 1:0] next_state;

reg         [ 7:0] guy_pos_cs;
reg         [ 7:0] guy_pos_ns;

reg         [ 5:0] cnt_cs;
reg         [ 5:0] cnt_ns;

reg         [ 8:0] pfm_shift_reg  [ 7:0];
reg         [ 1:0] out_shift_reg  [54:0];

reg                obs;
reg         [ 1:0] out_shift_reg_in;
reg         [ 7:0] next_obs;

reg                out_valid_ns;
reg         [ 1:0] out_ns;


wire               xor_in0      ;
wire               xor_in1      ;
wire               xor_in2      ;
wire               xor_in3      ;
wire               xor_in4      ;
wire               xor_in5      ;
wire               xor_in6      ;
wire               xor_in7      ;
wire               platform_full;
wire               out_full     ;

// FSM parameters
localparam IDLE     = 2'd0;
localparam IN_VAL   = 2'd1;
localparam PFM_FULL = 2'd3;
localparam OUT_FULL = 2'd2;

integer g;


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
        next_state = IN_VAL;
      end
      else begin
        next_state = IDLE;
      end
    end
    IN_VAL: begin
      if (platform_full) begin
        next_state = PFM_FULL;
      end
      else begin
        next_state = IN_VAL;
      end
    end
    PFM_FULL: begin
      if (out_full) begin
        next_state = OUT_FULL;
      end
      else begin
        next_state = PFM_FULL;
      end
    end
    OUT_FULL: begin
      if (out_full) begin
        next_state = IDLE;
      end
      else begin
        next_state = OUT_FULL;
      end
    end
    default: begin
      next_state = IDLE;
    end
  endcase
end


// guy_pos
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    guy_pos_cs <= 8'd0;
  end
  else begin
    guy_pos_cs <= guy_pos_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid) begin
        if (guy == 3'd0) begin
          guy_pos_ns = 8'b10000000;
        end
        else if (guy == 3'd1) begin
          guy_pos_ns = 8'b01000000;
        end
        else if (guy == 3'd2) begin
          guy_pos_ns = 8'b00100000;
        end
        else if (guy == 3'd3) begin
          guy_pos_ns = 8'b00010000;
        end
        else if (guy == 3'd4) begin
          guy_pos_ns = 8'b00001000;
        end
        else if (guy == 3'd5) begin
          guy_pos_ns = 8'b00000100;
        end
        else if (guy == 3'd6) begin
          guy_pos_ns = 8'b00000010;
        end
        else begin
          guy_pos_ns = 8'b00000001;
        end
      end
      else begin
        guy_pos_ns = 8'b00000000;
      end
    end
    IN_VAL: begin
      guy_pos_ns = guy_pos_cs;
    end
    PFM_FULL, OUT_FULL: begin
      if (out_shift_reg_in == 2'b01) begin // RIGHT
        guy_pos_ns = guy_pos_cs >> 1;
      end
      else if (out_shift_reg_in == 2'b10) begin // LEFT
        guy_pos_ns = guy_pos_cs << 1;
      end
      else begin
        guy_pos_ns = guy_pos_cs;
      end
    end
    // OUT_FULL: begin
    //   if (out_shift_reg_in == 2'b01) begin // RIGHT
    //     guy_pos_ns = guy_pos_cs >> 1;
    //   end
    //   else if (out_shift_reg_in == 2'b10) begin // LEFT
    //     guy_pos_ns = guy_pos_cs << 1;
    //   end
    //   else begin
    //     guy_pos_ns = guy_pos_cs;
    //   end
    // end
    default: begin
      guy_pos_ns = 8'd0;
    end
  endcase
end

// cnt
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    cnt_cs <= 6'd0;
  end
  else begin
    cnt_cs <= cnt_ns;
  end
end

always @(*) begin
  if (current_state == IDLE) begin
    cnt_ns = 6'd0;
  end
  else begin
    cnt_ns = cnt_cs + 6'd1;
  end
end


// pfm_shift_reg
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    pfm_shift_reg[0] <= 9'd0;
  end
  else begin
    if ( (current_state != PFM_FULL || out_full) && (!in_valid) ) begin
      pfm_shift_reg[0] <= 9'd0;
    end
    else begin
      pfm_shift_reg[0] <= {xor_in0, xor_in1, xor_in2, xor_in3, xor_in4, xor_in5, xor_in6, xor_in7, obs};
    end
  end
end


genvar i;
generate
  for (i=0; i<7; i=i+1) begin
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        pfm_shift_reg[i+1] <= 9'd0;
      end
      else begin
        pfm_shift_reg[i+1] <= pfm_shift_reg[i];
      end
    end
  end
endgenerate


// obs
always @(*) begin
  obs = (in0[0] == 1'b1) && ((in0[1] == 1'b0) || (in1[1] == 1'b0) || (in2[1] == 1'b0) || (in3[1] == 1'b0) || (in4[1] == 1'b0) || (in5[1] == 1'b0) || (in6[1] == 1'b0) || (in7[1] == 1'b0));
end



// out_shift_reg
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_shift_reg[0] <= 2'd0;
  end
  else begin
    if (current_state[1]) begin
      out_shift_reg[0] <= out_shift_reg_in;
    end
    else begin
      out_shift_reg[0] <= 2'd0;
    end
  end
end

genvar j;
generate
  for (j=0; j<54; j=j+1) begin
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        out_shift_reg[j+1] <= 2'd0;
      end
      else begin
        out_shift_reg[j+1] <= out_shift_reg[j];
      end
    end
  end
endgenerate


// out_shift_reg_in
always @(*) begin
  if (pfm_shift_reg[7][0]) begin
    out_shift_reg_in = 2'b11; // JUMP
  end
  else if (guy_pos_cs == next_obs || next_obs == 8'd0) begin
    out_shift_reg_in = 2'b00; // STOP
  end
  else if (guy_pos_cs > next_obs) begin
    out_shift_reg_in = 2'b01; // RIGHT
  end
  else begin
    out_shift_reg_in = 2'b10; // LEFT
  end
end


// next_obs
always @(*) begin
  if (|pfm_shift_reg[7][8:1]) begin
    next_obs = pfm_shift_reg[7][8:1];
  end
  else if (|pfm_shift_reg[6][8:1]) begin
    next_obs = pfm_shift_reg[6][8:1];
  end
  else if (|pfm_shift_reg[5][8:1]) begin
    next_obs = pfm_shift_reg[5][8:1];
  end
  else if (|pfm_shift_reg[4][8:1]) begin
    next_obs = pfm_shift_reg[4][8:1];
  end
  else if (|pfm_shift_reg[3][8:1]) begin
    next_obs = pfm_shift_reg[3][8:1];
  end
  else if (|pfm_shift_reg[2][8:1]) begin
    next_obs = pfm_shift_reg[2][8:1];
  end
  else if (|pfm_shift_reg[1][8:1]) begin
    next_obs = pfm_shift_reg[1][8:1];
  end
  else if (|pfm_shift_reg[0][8:1]) begin
    next_obs = pfm_shift_reg[0][8:1];
  end
  else begin
    next_obs = 8'd0;
  end
end

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
  case(current_state)
    IDLE: begin
      out_valid_ns = 0;
    end
    IN_VAL: begin
      out_valid_ns = 0;
    end
    PFM_FULL: begin
      // if (out_full) begin
      //   out_valid_ns = 1;
      // end
      // else begin
        out_valid_ns = 0;
      // end
    end
    OUT_FULL: begin
      if (out_full) begin
        out_valid_ns = 0;
      end
      else begin
        out_valid_ns = 1;
      end
    end
    default: begin
      out_valid_ns = 0;
    end
  endcase
end

// out
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out <= 2'b00;
  end
  else begin
    out <= out_ns;
  end
end

// always @(*) begin
//   case(current_state)
//     IDLE: begin
//       out_ns = 2'b00;
//     end
//     IN_VAL: begin
//       out_ns = 2'b00;
//     end
//     PFM_FULL: begin
//       out_ns = 2'b00;
//     end
//     OUT_FULL: begin
//       out_ns = out_shift_reg[54];
//     end
//     default: begin
//       out_ns = 2'b00;
//     end
//   endcase
// end

always @(*) begin
  if (current_state == OUT_FULL) begin
    out_ns = out_shift_reg[54];
  end
  else begin
    out_ns = 2'b00;
  end
end


assign xor_in0       = ^in0;
assign xor_in1       = ^in1;
assign xor_in2       = ^in2;
assign xor_in3       = ^in3;
assign xor_in4       = ^in4;
assign xor_in5       = ^in5;
assign xor_in6       = ^in6;
assign xor_in7       = ^in7;
assign platform_full = cnt_cs == 6'd7;
assign out_full      = cnt_cs == 6'd62;



endmodule
