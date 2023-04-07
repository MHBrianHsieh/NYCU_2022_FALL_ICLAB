// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : SP_wocg.v
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                 AREA            CYCLE
// 1.0     2022-11-17 Brian Hsieh                                  147682.182286   0/1/2
// 2.0     2022-11-20 Brian Hsieh      reduce operations to 9 bits 137653.086102   0/1/2
// 3.1     2022-11-20 Brian Hsieh      revise gray2bin             137333.751664   0/1/2
// 4.0     2022-11-20 Brian Hsieh      revise maxmin in addsub     108287.626998   0/1/2
// 6.0     2022-11-20 Brian Hsieh      gated sma_in(comb)          117531.692704   0/1/2
// 6.1     2022-11-20 Brian Hsieh      revise out_data (tt)        117664.748706   0/1/2
// 7.0     2022-11-20 Brian Hsieh                                  108287.626998   0/1/2
// 10.0    2022-11-20 Brian Hsieh      share the same reg array    99066.846204    0/1/2
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// Series Processing (without clock gating)
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


module SP(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	in_data,
	in_mode,
	// Output signals
	out_valid,
	out_data
);



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                             Input & Output Ports                                                              //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// INPUT AND OUTPUT DECLARATION  
input                     clk;
input                     rst_n;
input                     in_valid;
input                     cg_en;
input              [ 8:0] in_data;
input              [ 2:0] in_mode;

output reg                out_valid;
output reg signed  [ 9:0] out_data;


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                            Parameters & Constants                                                             //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

localparam IDLE                = 3'd0;
localparam GRAY                = 3'd1;
localparam ADD_SUB             = 3'd2;
localparam SMA                 = 3'd3;
localparam FIND                = 3'd4;
localparam OUT                 = 3'd5;



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                  Main Signals                                                                 //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


reg         [ 2:0] current_state;
reg         [ 2:0] next_state;

reg         [ 2:0] in_mode_reg_cs;
reg         [ 2:0] in_mode_reg_ns;
reg  signed [ 8:0] in_data_reg_cs    [0: 8];
reg  signed [ 8:0] in_data_reg_ns    [0: 8];
// reg  signed [ 8:0] in_data_reg1_cs;
// reg  signed [ 8:0] in_data_reg1_ns;
// reg  signed [ 8:0] in_data_reg2_cs;
// reg  signed [ 8:0] in_data_reg2_ns;
// reg  signed [ 8:0] in_data_reg3_cs;
// reg  signed [ 8:0] in_data_reg3_ns;
// reg  signed [ 8:0] in_data_reg4_cs;
// reg  signed [ 8:0] in_data_reg4_ns;
// reg  signed [ 8:0] in_data_reg5_cs;
// reg  signed [ 8:0] in_data_reg5_ns;
// reg  signed [ 8:0] in_data_reg6_cs;
// reg  signed [ 8:0] in_data_reg6_ns;
// reg  signed [ 8:0] in_data_reg7_cs;
// reg  signed [ 8:0] in_data_reg7_ns;
// reg  signed [ 8:0] in_data_reg8_cs;
// reg  signed [ 8:0] in_data_reg8_ns;

reg         [ 3:0] receive_cnt_cs;
reg         [ 3:0] receive_cnt_ns;


// GRAY
wire signed [ 8:0] in_data_gray2bin;


// ADD_SUB
reg  signed [ 8:0] add_sub_max_cs;
reg  signed [ 8:0] add_sub_min_cs;
reg  signed [ 8:0] add_sub_max_ns;
reg  signed [ 8:0] add_sub_min_ns;
reg  signed [ 9:0] sum_max_min;
reg  signed [ 9:0] diff_max_min;
reg  signed [ 8:0] midpoint;
reg  signed [ 8:0] half_diff;
// reg  signed [ 8:0] add_sub_out_cs [0: 8];
// reg  signed [ 8:0] add_sub_out_ns [0: 8];


// SMA
reg  signed [ 8:0] sma_in         [0: 8];
reg  signed [ 8:0] sma_out_cs     [0: 8];
reg  signed [ 8:0] sma_out_ns     [0: 8];


// FIND
reg  signed [ 8:0] find_in        [0 :8];
wire signed [ 8:0] max;
wire signed [ 8:0] median;
wire signed [ 8:0] min;

reg  signed [ 8:0] median_cs;
reg  signed [ 8:0] median_ns;
reg  signed [ 8:0] min_cs;
reg  signed [ 8:0] min_ns;


// OUT
reg                out_valid_ns;
reg  signed [ 9:0] out_data_ns;

reg         [ 1:0] out_cnt_cs;
reg         [ 1:0] out_cnt_ns;

// control signals
wire               receive_end;
wire               out_flag;


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
        next_state = GRAY;
      end
      else begin
        next_state = IDLE;
      end
    end
    GRAY: begin
      if (receive_end) begin
        if (in_mode_reg_cs[1]) begin
          next_state = ADD_SUB;
        end
        else if (in_mode_reg_cs[2]) begin
          next_state = SMA;
        end
        else begin
          next_state = FIND;
        end
      end
      else begin
        next_state = GRAY;
      end
    end
    ADD_SUB: begin
      if (in_mode_reg_cs[2]) begin
        next_state = SMA;
      end
      else begin
        next_state = FIND;
      end
    end
    SMA: begin
      // if () begin
      //   next_state = ;
      // end
      // else begin
        next_state = FIND;
      // end
    end
    FIND: begin
      // if () begin
      //   next_state = ;
      // end
      // else begin
        next_state = OUT;
      // end
    end
    OUT: begin
      if (out_flag) begin
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


// in_mode_reg
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    in_mode_reg_cs <= 3'b000;
  end
  else begin
    in_mode_reg_cs <= in_mode_reg_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid) begin
        in_mode_reg_ns = in_mode;
      end
      else begin
        in_mode_reg_ns = 3'b000;
      end
    end
    default: begin
      in_mode_reg_ns = in_mode_reg_cs;
    end
  endcase
end


// receive_cnt
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    receive_cnt_cs <= 4'd0;
  end
  else begin
    receive_cnt_cs <= receive_cnt_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid) begin
        receive_cnt_ns = 4'd1;
      end
      else begin
        receive_cnt_ns = 4'd0;
      end
    end
    GRAY: begin
      receive_cnt_ns = receive_cnt_cs + 4'd1;
    end
    default: begin
      receive_cnt_ns = receive_cnt_cs;
    end
  endcase
end


//////////////////////////////////////////////////////
//                      GRAY                        //
//////////////////////////////////////////////////////


// in_data_reg
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    in_data_reg_cs[8] <= 9'd0;
  end
  else begin
    in_data_reg_cs[8] <= in_data_reg_ns[8];
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid) begin
        if (in_mode[0]) begin
          in_data_reg_ns[8] = in_data_gray2bin;
        end
        else begin
          in_data_reg_ns[8] = in_data;
        end
      end
      else begin
        in_data_reg_ns[8] = 9'd0;
      end
    end
    GRAY: begin
      if (in_mode_reg_cs[0]) begin
        in_data_reg_ns[8] = in_data_gray2bin;
      end
      else begin
        in_data_reg_ns[8] = in_data;
      end
    end
    ADD_SUB: begin
      if (in_data_reg_cs[8] > midpoint) begin
        in_data_reg_ns[8] = in_data_reg_cs[8] - half_diff;
      end
      else if (in_data_reg_cs[8] < midpoint) begin
        in_data_reg_ns[8] = in_data_reg_cs[8] + half_diff;
      end
      else begin
        in_data_reg_ns[8] = in_data_reg_cs[8];
      end
    end
    default: begin
      in_data_reg_ns[8] = in_data_reg_cs[8];
    end
  endcase
end


genvar i;
generate
  for (i=0; i<8; i=i+1) begin: shift_reg
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        in_data_reg_cs[7-i] <= 9'd0;
      end
      else begin
        in_data_reg_cs[7-i] <= in_data_reg_ns[7-i];
      end
    end

    always @(*) begin
      case(current_state)
        GRAY: begin
          in_data_reg_ns[7-i] = in_data_reg_cs[8-i];
        end
        ADD_SUB: begin
          if (in_data_reg_cs[7-i] > midpoint) begin
            in_data_reg_ns[7-i] = in_data_reg_cs[7-i] - half_diff;
          end
          else if (in_data_reg_cs[7-i] < midpoint) begin
            in_data_reg_ns[7-i] = in_data_reg_cs[7-i] + half_diff;
          end
          else begin
            in_data_reg_ns[7-i] = in_data_reg_cs[7-i];
          end
        end
        default: begin
          in_data_reg_ns[7-i] = in_data_reg_cs[7-i];
        end
      endcase
    end
  end
endgenerate


//////////////////////////////////////////////////////
//                     ADD_SUB                      //
//////////////////////////////////////////////////////

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    add_sub_max_cs <= 9'b1_0000_0000; // -256
    add_sub_min_cs <= 9'b0_1111_1111; // +255
  end
  else begin
    add_sub_max_cs <= add_sub_max_ns;
    add_sub_min_cs <= add_sub_min_ns;
  end
end

always @(*) begin
  case(current_state)
    GRAY, ADD_SUB: begin
      if (in_data_reg_cs[8] > add_sub_max_cs) begin
        add_sub_max_ns = in_data_reg_cs[8];
      end
      else begin
        add_sub_max_ns = add_sub_max_cs;
      end
      if (in_data_reg_cs[8] < add_sub_min_cs) begin
        add_sub_min_ns = in_data_reg_cs[8];
      end
      else begin
        add_sub_min_ns = add_sub_min_cs;
      end
    end
    default: begin
      add_sub_max_ns = 9'b1_0000_0000; // -256
      add_sub_min_ns = 9'b0_1111_1111; // +255
    end
  endcase
end


// midpoint
always @(*) begin
  sum_max_min = add_sub_max_ns + add_sub_min_ns;
  midpoint    = sum_max_min / 2;
end


// half_diff
always @(*) begin
  diff_max_min = add_sub_max_ns - add_sub_min_ns;
  half_diff    = diff_max_min / 2;
end


// add_sub_out
// genvar k;
// generate
//   for (k=0; k<9; k=k+1) begin: add_sub_out_reg
//     always @(posedge clk or negedge rst_n) begin
//       if (!rst_n) begin
//         add_sub_out_cs[k] <= 9'd0;
//       end
//       else begin
//         add_sub_out_cs[k] <= add_sub_out_ns[k];
//       end
//     end

//     always @(*) begin
//       if (in_data_reg_cs[k] > midpoint) begin
//         add_sub_out_ns[k] = in_data_reg_cs[k] - half_diff;
//       end
//       else if (in_data_reg_cs[k] < midpoint) begin
//         add_sub_out_ns[k] = in_data_reg_cs[k] + half_diff;
//       end
//       else begin
//         add_sub_out_ns[k] = in_data_reg_cs[k];
//       end
//     end
//   end
// endgenerate


//////////////////////////////////////////////////////
//                       SMA                        //
//////////////////////////////////////////////////////

// sma_in
genvar m;
generate
  for (m=0; m<9; m=m+1) begin: sma_in_comb
    always @(*) begin
      // if (!in_mode_reg_cs[2]) begin
      //   sma_in[m] = 9'd0;
      // end
      // else begin
        // if (in_mode_reg_cs[1]) begin
        //   sma_in[m] = add_sub_out_cs[m];
        // end
        // else begin
          sma_in[m] = in_data_reg_cs[m];
        // end
      // end
    end
  end
endgenerate


// sma_out
genvar n;
generate
  for (n=0; n<9; n=n+1) begin: sma_out_dff
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        sma_out_cs[n] <= 9'd0;
      end
      else begin
        sma_out_cs[n] <= sma_out_ns[n];
      end
    end
  end
endgenerate

always @(*) begin
  sma_out_ns[0] = (sma_in[8] + sma_in[0] + sma_in[1]) / 3;
  sma_out_ns[1] = (sma_in[0] + sma_in[1] + sma_in[2]) / 3;
  sma_out_ns[2] = (sma_in[1] + sma_in[2] + sma_in[3]) / 3;
  sma_out_ns[3] = (sma_in[2] + sma_in[3] + sma_in[4]) / 3;
  sma_out_ns[4] = (sma_in[3] + sma_in[4] + sma_in[5]) / 3;
  sma_out_ns[5] = (sma_in[4] + sma_in[5] + sma_in[6]) / 3;
  sma_out_ns[6] = (sma_in[5] + sma_in[6] + sma_in[7]) / 3;
  sma_out_ns[7] = (sma_in[6] + sma_in[7] + sma_in[8]) / 3;
  sma_out_ns[8] = (sma_in[7] + sma_in[8] + sma_in[0]) / 3;
end


//////////////////////////////////////////////////////
//                      FIND                        //
//////////////////////////////////////////////////////

// find_in
genvar f;
generate
  for (f=0; f<9; f=f+1) begin: find_in_comb
    always @(*) begin
      if (in_mode_reg_cs[2]) begin
        find_in[f] = sma_out_cs[f];
      end
      // else if (in_mode_reg_cs[1]) begin
      //   find_in[f] = add_sub_out_cs[f];
      // end
      else begin
        find_in[f] = in_data_reg_cs[f];
      end
    end
  end
endgenerate


// median
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    median_cs <= 9'd0;
  end
  else begin
    median_cs <= median_ns;
  end
end

always @(*) begin
  case(current_state)
    FIND: begin
      median_ns = median;
    end
    OUT: begin
      median_ns = median_cs;
    end
    default: begin
      median_ns = 9'd0;
    end
  endcase
end

// min
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    min_cs <= 9'd0;
  end
  else begin
    min_cs <= min_ns;
  end
end

always @(*) begin
  case(current_state)
    FIND: begin
      min_ns = min;
    end
    OUT: begin
      min_ns = min_cs;
    end
    default: begin
      min_ns = 9'd0;
    end
  endcase
end

//////////////////////////////////////////////////////
//                      OUT                         //
//////////////////////////////////////////////////////

// out_cnt
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_cnt_cs <= 2'd0;
  end
  else begin
    out_cnt_cs <= out_cnt_ns;
  end
end

always @(*) begin
  case(current_state)
    OUT: begin
      out_cnt_ns = out_cnt_cs + 2'd1;
    end
    default: begin
      out_cnt_ns = 2'd0;
    end
  endcase
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
    FIND: begin
      // if () begin
        out_valid_ns = 1'b1;
      // end
      // else begin
      //   out_valid_ns = ;
      // end
    end
    OUT: begin
      out_valid_ns = 1'b1;
    end
    default: begin
      out_valid_ns = 1'b0;
    end
  endcase
end


// out_data
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_data <= 10'd0;
  end
  else begin
    out_data <= out_data_ns;
  end
end

always @(*) begin
  case(current_state)
    FIND: begin
      // if () begin
        out_data_ns = {max[8], max};
      // end
      // else begin
      //   out_data_ns = ;
      // end
    end
    OUT: begin
      if (out_flag) begin
        out_data_ns = {min_cs[8], min_cs};
      end
      else begin
        out_data_ns = {median_cs[8], median_cs};
      end
    end
    default: begin
      out_data_ns = 10'd0;
    end
  endcase
end



// control signals
assign receive_end = receive_cnt_cs >= 4'd8;
assign out_flag    = out_cnt_cs == 2'd1;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                  module instantiation                                                   //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

gray2bin u_gray2bin (
  .gray_data(in_data),
  .bin_data(in_data_gray2bin)
);

max_min_median u_max_min_median (
  .input_0(find_in[0]),
  .input_1(find_in[1]),
  .input_2(find_in[2]),
  .input_3(find_in[3]),
  .input_4(find_in[4]),
  .input_5(find_in[5]),
  .input_6(find_in[6]),
  .input_7(find_in[7]),
  .input_8(find_in[8]),
  .max    (max       ),
  .median (median    ),
  .min    (min       )
);



endmodule



module gray2bin (
  input             [ 8:0] gray_data,
  output reg signed [ 8:0] bin_data
);

wire [8:0] bin_data_sgn_mag;

assign bin_data_sgn_mag[8] = gray_data[8];
assign bin_data_sgn_mag[7] = gray_data[7];
assign bin_data_sgn_mag[6] = bin_data_sgn_mag[7] ^ gray_data[6];
assign bin_data_sgn_mag[5] = bin_data_sgn_mag[6] ^ gray_data[5];
assign bin_data_sgn_mag[4] = bin_data_sgn_mag[5] ^ gray_data[4];
assign bin_data_sgn_mag[3] = bin_data_sgn_mag[4] ^ gray_data[3];
assign bin_data_sgn_mag[2] = bin_data_sgn_mag[3] ^ gray_data[2];
assign bin_data_sgn_mag[1] = bin_data_sgn_mag[2] ^ gray_data[1];
assign bin_data_sgn_mag[0] = bin_data_sgn_mag[1] ^ gray_data[0];

always @(*) begin
  if (bin_data_sgn_mag[8]) begin
    bin_data = {bin_data_sgn_mag[8], ~bin_data_sgn_mag[7:0]} + 9'd1;
  end
  else begin
    bin_data = bin_data_sgn_mag;
  end
end


endmodule



module comp_sel (
  input      signed [ 8:0] input_a,
  input      signed [ 8:0] input_b,
  input      signed [ 8:0] input_c,
  output reg signed [ 8:0] max,
  output reg signed [ 8:0] mid,
  output reg signed [ 8:0] min
);

wire       co1;
wire       co2;
wire       co3;
wire [2:0] sel;

assign co1 = input_a > input_b;
assign co2 = input_a > input_c;
assign co3 = input_b > input_c;
assign sel = {co1, co2, co3};


// max
always @(*) begin
  casez (sel)
    3'b11?: begin
      max = input_a;
    end
    3'b0?1: begin
      max = input_b;
    end
    3'b0?0: begin
      max = input_c;
    end
    3'b10?: begin
      max = input_c;
    end
  endcase
end


// mid
always @(*) begin
  casez (sel)
    3'b01?: begin
      mid = input_a;
    end
    3'b10?: begin
      mid = input_a;
    end
    3'b000: begin
      mid = input_b;
    end
    3'b111: begin
      mid = input_b;
    end
    default: begin
      mid = input_c;
    end
  endcase
end



// min
always @(*) begin
  casez (sel)
    3'b00?: begin
      min = input_a;
    end
    3'b1?0: begin
      min = input_b;
    end
    3'b1?1: begin
      min = input_c;
    end
    3'b01?: begin
      min = input_c;
    end
  endcase
end



endmodule



module max_min_median (
  input  signed [ 8:0] input_0,
  input  signed [ 8:0] input_1,
  input  signed [ 8:0] input_2,
  input  signed [ 8:0] input_3,
  input  signed [ 8:0] input_4,
  input  signed [ 8:0] input_5,
  input  signed [ 8:0] input_6,
  input  signed [ 8:0] input_7,
  input  signed [ 8:0] input_8,
  output signed [ 8:0] max,
  output signed [ 8:0] median,
  output signed [ 8:0] min
);

wire signed [ 8:0] cs1_max;
wire signed [ 8:0] cs1_mid;
wire signed [ 8:0] cs1_min;
wire signed [ 8:0] cs2_max;
wire signed [ 8:0] cs2_mid;
wire signed [ 8:0] cs2_min;
wire signed [ 8:0] cs3_max;
wire signed [ 8:0] cs3_mid;
wire signed [ 8:0] cs3_min;
wire signed [ 8:0] cs4_min;
wire signed [ 8:0] cs5_mid;
wire signed [ 8:0] cs6_max;


comp_sel u_comp_sel1 (.input_a(input_0), .input_b(input_1), .input_c(input_2), .max(cs1_max), .mid(cs1_mid), .min(cs1_min));
comp_sel u_comp_sel2 (.input_a(input_3), .input_b(input_4), .input_c(input_5), .max(cs2_max), .mid(cs2_mid), .min(cs2_min));
comp_sel u_comp_sel3 (.input_a(input_6), .input_b(input_7), .input_c(input_8), .max(cs3_max), .mid(cs3_mid), .min(cs3_min));
comp_sel u_comp_sel4 (.input_a(cs1_max), .input_b(cs2_max), .input_c(cs3_max), .max(max    ), .mid(       ), .min(cs4_min));
comp_sel u_comp_sel5 (.input_a(cs1_mid), .input_b(cs2_mid), .input_c(cs3_mid), .max(       ), .mid(cs5_mid), .min(       ));
comp_sel u_comp_sel6 (.input_a(cs1_min), .input_b(cs2_min), .input_c(cs3_min), .max(cs6_max), .mid(       ), .min(min    ));
comp_sel u_comp_sel7 (.input_a(cs4_min), .input_b(cs5_mid), .input_c(cs6_max), .max(       ), .mid(median ), .min(       ));



endmodule