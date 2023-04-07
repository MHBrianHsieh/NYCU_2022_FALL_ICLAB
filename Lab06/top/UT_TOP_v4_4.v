// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : UT_TOP.v
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                                   AREA             LATENCY           PERFORMANCE
// 1.0     2022-10-28 Brian Hsieh                                                    53834.458242     6.0ns x 3 cycle   969020.248356
//                                                                                   59199.941587     5.0ns x 3 cycle   887999.123805
//                                                                                   64824.883710     4.4ns x 3 cycle   855688.464972
// 2.0     2022-10-30 Brian Hsieh      modify %7 to /7 and mult                      66351.701324     4.4ns x 3 cycle   875842.4574768
// 2.1     2022-10-30 Brian Hsieh      modify %7 to 15-bit /7 and mult               66298.478988     4.4ns x 3 cycle   
// 2.2     2022-10-30 Brian Hsieh      modify %7 to 15-bit %7                        64921.349378     4.4ns x 3 cycle   
// 2.3     2022-10-30 Brian Hsieh      modify div15 to div60                         65134.238923
// 3.0     2022-10-30 Brian Hsieh      modify div765 to /7 and mult                  60118.028054     4.4ns x 3 cycle   793557.9703128
//                                                                                   61308.879284     4.3ns x 3 cycle   790884.5427636
//                                                                                   62975.405710     4.2ns x 3 cycle   793490.111946
// 4.0     2022-10-30 Brian Hsieh      omit redundant mux                            60397.445724     4.2ns x 3 cycle   761007.8161224
// 4.1     2022-10-30 Brian Hsieh      modify %7 to 15-bit /7 and mult               63507.629736     4.2ns x 3 cycle   800196.1346736
//                                                                                   60500.564051     4.3ns x 3 cycle   780457.2762579
// 4.2     2022-10-30 Brian Hsieh      4.0 modify div15 to /7 and mult               62449.834492     4.2ns x 3 cycle   786867.9145992
// 4.3     2022-10-30 Brian Hsieh      4.2 omit redundant mux                        58142.146366     4.2ns x 3 cycle   732591.0442116
// 4.4     2022-10-30 Brian Hsieh      4.3 omit redundant mux, modify *5 to <<2 +1   56538.821633     4.2ns x 3 cycle   712389.1525758 (final)
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// Unix Time Converter
// -----------------------------------------------------------------------------
// PARAMETERS
// PARAM_NAME RANGE      : DESCRIPTION           : DEFAULT
//
// -----------------------------------------------------------------------------
// REUSE ISSUES
// Reset Schemes : asynchronous active-low reset, rst_n
// Clock Domains : single clock, clk
// Asynchronous I/F : N/A
// Instantiations : B2BCD_IP (Combinational Binary-to-BCD Converter Soft IP), DW_div
// Other : 
// -----------------------------------------------------------------------------


//synopsys translate_off
`include "B2BCD_IP.v"
`include "/RAID2/cad/synopsys/synthesis/cur/dw/sim_ver/DW_div.v"
//synopsys translate_on




module UT_TOP (
    // Input signals
    clk, rst_n, in_valid, in_time,
    // Output signals
    out_valid, out_display, out_day
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input                   clk;
input                   rst_n;
input                   in_valid;
input       [30:0]      in_time;
output reg              out_valid;
output reg  [ 3:0]      out_display;
output reg  [ 2:0]      out_day;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================

localparam ONE_DAY_SECS_RSH7   = 10'd675;
localparam FOUR_YRS_DAYS       = 11'd1461;
localparam ONE_MIN_SECS_RSH2   = 4'd15;
localparam ONE_WEEK_DAYS       = 3'd7;
// localparam DAY_INC_PER4YRS     = 3'd5;
localparam DAY_START           = 3'd4;


//================================================================
// Wire & Reg Declaration
//================================================================

reg         [ 4:0]      cnt_r;
reg         [ 4:0]      cnt_nxt;

reg                     out_valid_nxt;
reg         [ 3:0]      out_display_nxt;
reg         [ 2:0]      out_day_nxt;

reg         [30:0]      in_time_r;
reg         [30:0]      in_time_nxt;


// u_DW_div_675
wire        [14:0]      quotient_675;
// wire        [ 9:0]      remainder_675;
reg         [14:0]      quotient_675_r;
reg         [ 9:0]      remainder_675_r;
reg         [ 9:0]      remainder_675_nxt;

// u_DW_div_1461
wire        [14:0]      quotient_1461;
wire        [10:0]      remainder_1461;
reg         [ 4:0]      quotient_1461_r;
reg         [10:0]      remainder_1461_r;
reg         [ 4:0]      quotient_1461_nxt;
reg         [10:0]      remainder_1461_nxt;

// u_DW_div_15_0
reg         [16:0]      remainder_86400_r;
reg         [16:0]      remainder_86400_nxt;
wire        [10:0]      quotient_15_0;
// wire        [ 3:0]      remainder_15_0;
reg         [10:0]      quotient_15_0_r;
reg         [ 3:0]      remainder_15_0_r;
reg         [10:0]      quotient_15_0_nxt;
reg         [ 3:0]      remainder_15_0_nxt;

// u_DW_div_15_1
wire        [ 8:0]      quotient_15_1;
// wire        [ 3:0]      remainder_15_1;
reg         [ 3:0]      remainder_15_1_r;
reg         [ 3:0]      remainder_15_1_nxt;


// sec_bin_result
reg         [ 5:0]      sec_bin_result_r;
reg         [ 5:0]      sec_bin_result_nxt;

// hr_bin_result
reg         [ 4:0]      hr_bin_result_r;
reg         [ 4:0]      hr_bin_result_nxt;

// min_bin_result
reg         [ 5:0]      min_bin_result_r;
reg         [ 5:0]      min_bin_result_nxt;

reg         [ 1:0]      remainder_1461_year;

reg  signed [ 6:0]      year_19or20_r;
reg  signed [ 6:0]      year_19or20_nxt;

reg         [ 8:0]      date_r;
reg         [ 8:0]      date_nxt;

// reg         [14:0]      day_acc_r;
// reg         [14:0]      day_acc_nxt;

reg         [ 3:0]      month_bin_result_r;
reg         [ 4:0]      date_bin_result_r;
reg         [ 3:0]      month_bin_result_nxt;
reg         [ 4:0]      date_bin_result_nxt;

wire        [ 7:0]      bcd_result;

reg         [ 6:0]      bin_result_r;
reg         [ 6:0]      bin_result_nxt;


// contorl signals
wire                    cnt_0  ;
wire                    cnt_2  ;
wire                    cnt_3  ;
wire                    cnt_4  ;
// wire                    cnt_5  ;
// wire                    cnt_6  ;
// wire                    cnt_7  ;
// wire                    cnt_8  ;
// wire                    cnt_9  ;
wire                    cnt_end;

//================================================================
// DESIGN
//================================================================

// cnt
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    cnt_r <= 5'd0;
  end
  else begin
    cnt_r <= cnt_nxt;
  end
end

always @(*) begin
  if (cnt_0) begin
    if (in_valid) begin
      cnt_nxt = 5'd1;
    end
    else begin
      cnt_nxt = 5'd0;
    end
  end
  else if (cnt_end) begin
    cnt_nxt = 5'd0;
  end
  else begin
    cnt_nxt = cnt_r + 5'd1;
  end
end


// in_time_r
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    in_time_r <= 31'd0;
  end
  else begin
    in_time_r <= in_time_nxt;
  end
end

always @(*) begin
  if (in_valid) begin
    in_time_nxt = in_time;
  end
  else begin
    in_time_nxt = in_time_r;
  end
end


// quotient_675_r
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    quotient_675_r <= 15'd0;
  end
  else begin
    quotient_675_r <= quotient_675;
  end
end

// remainder_675_r
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    remainder_675_r <= 10'd0;
  end
  else begin
    remainder_675_r <= remainder_675_nxt;
  end
end

always @(*) begin
  // if (cnt_2) begin
    remainder_675_nxt = in_time_r[30:7] - quotient_675_r * ONE_DAY_SECS_RSH7;
  // end
  // else begin
  //   remainder_675_nxt = remainder_675_r;
  // end
end


// remainder_86400_r
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    remainder_86400_r <= 10'd0;
  end
  else begin
    remainder_86400_r <= remainder_86400_nxt;
  end
end

always @(*) begin
  // if (cnt_3) begin
    remainder_86400_nxt = {remainder_675_r, in_time_r[6:0]};
  // end
  // else begin
  //   remainder_86400_nxt = remainder_86400_r;
  // end
end


// quotient_1461
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    quotient_1461_r <= 5'd0;
  end
  else begin
    quotient_1461_r <= quotient_1461_nxt;
  end
end

always @(*) begin
  // if (cnt_2) begin
    quotient_1461_nxt = quotient_1461[4:0];
  // end
  // else begin
  //   quotient_1461_nxt = quotient_1461_r;
  // end
end


// remainder_1461
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    remainder_1461_r <= 11'd0;
  end
  else begin
    remainder_1461_r <= remainder_1461_nxt;
  end
end

always @(*) begin
  // if (cnt_2) begin
    remainder_1461_nxt = remainder_1461;
  // end
  // else begin
  //   remainder_1461_nxt = remainder_1461_r;
  // end
end


// quotient_15_0_r
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    quotient_15_0_r <= 11'd0;
  end
  else begin
    quotient_15_0_r <= quotient_15_0_nxt;
  end
end

always @(*) begin
  // if (cnt_4) begin
    quotient_15_0_nxt = quotient_15_0;
  // end
  // else begin
  //   quotient_15_0_nxt = quotient_15_0_r;
  // end
end


// remainder_15_0_r
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    remainder_15_0_r <= 4'd0;
  end
  else begin
    remainder_15_0_r <= remainder_15_0_nxt;
  end
end

always @(*) begin
  // if (cnt_5) begin
    remainder_15_0_nxt = remainder_86400_r[16:2] - quotient_15_0_r * ONE_MIN_SECS_RSH2;
  // end
  // else begin
  //   remainder_15_0_nxt = remainder_15_0_r;
  // end
end


// sec_bin_result
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    sec_bin_result_r <= 6'd0;
  end
  else begin
    sec_bin_result_r <= sec_bin_result_nxt;
  end
end

always @(*) begin
  // if (cnt_6) begin
    sec_bin_result_nxt = {remainder_15_0_r, remainder_86400_r[1:0]};
  // end
  // else begin
  //   sec_bin_result_nxt = sec_bin_result_r;
  // end
end


// hr_bin_result
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    hr_bin_result_r <= 5'd0;
  end
  else begin
    hr_bin_result_r <= hr_bin_result_nxt;
  end
end

always @(*) begin
  // if (cnt_5) begin
    hr_bin_result_nxt = quotient_15_1;
  // end
  // else begin
  //   hr_bin_result_nxt = hr_bin_result_r;
  // end
end


// remainder_15_1_r
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    remainder_15_1_r <= 4'd0;
  end
  else begin
    remainder_15_1_r <= remainder_15_1_nxt;
  end
end

always @(*) begin
  // if (cnt_6) begin
    remainder_15_1_nxt = quotient_15_0_r[10:2] - quotient_15_1 * ONE_MIN_SECS_RSH2;
  // end
  // else begin
  //   remainder_15_1_nxt = remainder_15_1_r;
  // end
end


// min_bin_result
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    min_bin_result_r <= 6'd0;
  end
  else begin
    min_bin_result_r <= min_bin_result_nxt;
  end
end

always @(*) begin
  // if (cnt_7) begin
    min_bin_result_nxt = {remainder_15_1_r, quotient_15_0_r[1:0]};
  // end
  // else begin
  //   min_bin_result_nxt = min_bin_result_r;
  // end
end


// remainder_1461_year
always @(*) begin
  if (remainder_1461_r <= 'd364) begin
    remainder_1461_year = 2'd0;
  end
  else if (remainder_1461_r <= 'd729) begin
    remainder_1461_year = 2'd1;
  end
  else if (remainder_1461_r <= 'd1095) begin
    remainder_1461_year = 2'd2;
  end
  else begin
    remainder_1461_year = 2'd3;
  end
end


// year_19or20
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    year_19or20_r <= 7'd0;
  end
  else begin
    year_19or20_r <= year_19or20_nxt;
  end
end

always @(*) begin
  // if (cnt_3) begin
    year_19or20_nxt = (quotient_1461_r << 2) + remainder_1461_year - 'd30;
  // end
  // else begin
  //   year_19or20_nxt = year_19or20_r;
  // end
end


// date
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    date_r <= 9'd0;
  end
  else begin
    date_r <= date_nxt;
  end
end

always @(*) begin
  // if (cnt_4) begin
    case(remainder_1461_year)
      2'd0: begin
        date_nxt = remainder_1461_r;
      end
      2'd1: begin
        date_nxt = remainder_1461_r - 'd365;
      end
      2'd2: begin
        date_nxt = remainder_1461_r - 'd730;
      end
      2'd3: begin
        date_nxt = remainder_1461_r - 'd1096;
      end
    endcase
  // end
  // else begin
  //   date_nxt = date_r;
  // end
end


// month_bin_result, date_bin_result
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    month_bin_result_r <= 4'd0;
  end
  else begin
    month_bin_result_r <= month_bin_result_nxt;
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    date_bin_result_r <= 5'd0;
  end
  else begin
    date_bin_result_r <= date_bin_result_nxt;
  end
end

always @(*) begin
  // if (cnt_r >= 5'd5) begin
    if (remainder_1461_year == 2'd2) begin // leap year
      if (date_r <= 'd30) begin
        month_bin_result_nxt = 'd1;
        date_bin_result_nxt  = date_r + 'd1;
      end
      else if (date_r <= 'd59) begin
        month_bin_result_nxt = 'd2;
        date_bin_result_nxt  = date_r - 'd30;
      end
      else if (date_r <= 'd90) begin
        month_bin_result_nxt = 'd3;
        date_bin_result_nxt  = date_r - 'd59;
      end
      else if (date_r <= 'd120) begin
        month_bin_result_nxt = 'd4;
        date_bin_result_nxt  = date_r - 'd90;
      end
      else if (date_r <= 'd151) begin
        month_bin_result_nxt = 'd5;
        date_bin_result_nxt  = date_r - 'd120;
      end
      else if (date_r <= 'd181) begin
        month_bin_result_nxt = 'd6;
        date_bin_result_nxt  = date_r - 'd151;
      end
      else if (date_r <= 'd212) begin
        month_bin_result_nxt = 'd7;
        date_bin_result_nxt  = date_r - 'd181;
      end
      else if (date_r <= 'd243) begin
        month_bin_result_nxt = 'd8;
        date_bin_result_nxt  = date_r - 'd212;
      end
      else if (date_r <= 'd273) begin
        month_bin_result_nxt = 'd9;
        date_bin_result_nxt  = date_r - 'd243;
      end
      else if (date_r <= 'd304) begin
        month_bin_result_nxt = 'd10;
        date_bin_result_nxt  = date_r - 'd273;
      end
      else if (date_r <= 'd334) begin
        month_bin_result_nxt = 'd11;
        date_bin_result_nxt  = date_r - 'd304;
      end
      else begin
        month_bin_result_nxt = 'd12;
        date_bin_result_nxt  = date_r - 'd334;
      end
    end
    else begin
      if (date_r <= 'd30) begin
        month_bin_result_nxt = 'd1;
        date_bin_result_nxt  = date_r + 'd1;
      end
      else if (date_r <= 'd58) begin
        month_bin_result_nxt = 'd2;
        date_bin_result_nxt  = date_r - 'd30;
      end
      else if (date_r <= 'd89) begin
        month_bin_result_nxt = 'd3;
        date_bin_result_nxt  = date_r - 'd58;
      end
      else if (date_r <= 'd119) begin
        month_bin_result_nxt = 'd4;
        date_bin_result_nxt  = date_r - 'd89;
      end
      else if (date_r <= 'd150) begin
        month_bin_result_nxt = 'd5;
        date_bin_result_nxt  = date_r - 'd119;
      end
      else if (date_r <= 'd180) begin
        month_bin_result_nxt = 'd6;
        date_bin_result_nxt  = date_r - 'd150;
      end
      else if (date_r <= 'd211) begin
        month_bin_result_nxt = 'd7;
        date_bin_result_nxt  = date_r - 'd180;
      end
      else if (date_r <= 'd242) begin
        month_bin_result_nxt = 'd8;
        date_bin_result_nxt  = date_r - 'd211;
      end
      else if (date_r <= 'd272) begin
        month_bin_result_nxt = 'd9;
        date_bin_result_nxt  = date_r - 'd242;
      end
      else if (date_r <= 'd303) begin
        month_bin_result_nxt = 'd10;
        date_bin_result_nxt  = date_r - 'd272;
      end
      else if (date_r <= 'd333) begin
        month_bin_result_nxt = 'd11;
        date_bin_result_nxt  = date_r - 'd303;
      end
      else begin
        month_bin_result_nxt = 'd12;
        date_bin_result_nxt  = date_r - 'd333;
      end
    end
  // end
  // else begin
  //   month_bin_result_nxt = 4'd0;
  //   date_bin_result_nxt  = 5'd0;
  // end
end




// bin_result_r
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    bin_result_r <= 7'd0;
  end
  else begin
    bin_result_r <= bin_result_nxt;
  end
end

always @(*) begin
  case(cnt_r)
    5'd4: begin
      if (year_19or20_r[6]) begin
        bin_result_nxt = year_19or20_r + 'd100;
      end
      else begin
        bin_result_nxt = year_19or20_r;
      end
    end
    5'd6: begin
      bin_result_nxt = month_bin_result_r;
    end
    5'd8: begin
      bin_result_nxt = date_bin_result_r;
    end
    5'd10: begin
      bin_result_nxt = hr_bin_result_r;
    end
    5'd12: begin
      bin_result_nxt = min_bin_result_r;
    end
    5'd14: begin
      bin_result_nxt = sec_bin_result_r;
    end
    default: begin
      bin_result_nxt = bin_result_r;
    end
  endcase
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
  if (cnt_r >= 5'd3) begin
    out_valid_nxt = 1'b1;
  end
  else begin
    out_valid_nxt = 1'b0;
  end
end


// out_display
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_display <= 4'd0;
  end
  else begin
    out_display <= out_display_nxt;
  end
end

always @(*) begin
  if (cnt_r <= 5'd2) begin
    out_display_nxt = 4'd0;
  end
  else if (cnt_3) begin
    if (year_19or20_nxt[6]) begin
      out_display_nxt = 4'd1;
    end
    else begin
      out_display_nxt = 4'd2;
    end
  end
  else if (cnt_4) begin
    if (year_19or20_nxt[6]) begin
      out_display_nxt = 4'd9;
    end
    else begin
      out_display_nxt = 4'd0;
    end
  end
  else if (cnt_r[0] == 1'b1) begin
    out_display_nxt = bcd_result[7:4];
  end
  else begin
    out_display_nxt = bcd_result[3:0];
  end
end


// day_acc
// always @(posedge clk or negedge rst_n) begin
//   if (!rst_n) begin
//     day_acc_r <= 15'd0;
//   end
//   else begin
//     day_acc_r <= day_acc_nxt;
//   end
// end

// always @(*) begin
//   if (cnt_2) begin
//     day_acc_nxt = (quotient_675_r + DAY_START) / ONE_WEEK_DAYS;
//   end
//   else begin
//     day_acc_nxt = 15'd0;
//   end
// end


// out_day
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out_day <= 3'd0;
  end
  else begin
    out_day <= out_day_nxt;
  end
end

always @(*) begin
  if (cnt_3) begin
    out_day_nxt = ( (quotient_1461_r << 2) + quotient_1461_r + remainder_1461_r + DAY_START ) % ONE_WEEK_DAYS;
  end
  else if (cnt_r > 5'd3) begin
    out_day_nxt = out_day;
  end
  else begin
    out_day_nxt = 3'd0;
  end
end

assign cnt_0   = cnt_r == 5'd0;
assign cnt_2   = cnt_r == 5'd2;
assign cnt_3   = cnt_r == 5'd3;
assign cnt_4   = cnt_r == 5'd4;
// assign cnt_5   = cnt_r == 5'd5;
// assign cnt_6   = cnt_r == 5'd6;
// assign cnt_7   = cnt_r == 5'd7;
// assign cnt_8   = cnt_r == 5'd8;
// assign cnt_9   = cnt_r == 5'd9;
assign cnt_end = cnt_r == 5'd16;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                 module instantiation                                                                  //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// DW_div #(24, 10, 0, 1) u_DW_div_675 (
//   .a(in_time_r[30:7]),
//   .b(ONE_DAY_SECS_RSH7),
//   .quotient(quotient_675),
//   .remainder(remainder_675),
//   .divide_by_0()
// );

assign quotient_675 = in_time_r[30:7] / ONE_DAY_SECS_RSH7;

DW_div #(15, 11, 0, 1) u_DW_div_1461 (
  .a(quotient_675_r),
  .b(FOUR_YRS_DAYS),
  .quotient(quotient_1461),
  .remainder(remainder_1461),
  .divide_by_0()
);

// DW_div #(15, 4, 0, 1) u_DW_div_15_0 (
//   .a(remainder_86400_r[16:2]),
//   .b(ONE_MIN_SECS_RSH2),
//   .quotient(quotient_15_0),
//   .remainder(remainder_15_0),
//   .divide_by_0()
// );

assign quotient_15_0 = remainder_86400_r[16:2] / ONE_MIN_SECS_RSH2;

// DW_div #(9, 4, 0, 1) u_DW_div_15_1 (
//   .a(quotient_15_0_r[10:2]),
//   .b(ONE_MIN_SECS_RSH2),
//   .quotient(quotient_15_1),
//   .remainder(remainder_15_1),
//   .divide_by_0()
// );

assign quotient_15_1 = quotient_15_0_r[10:2] / ONE_MIN_SECS_RSH2;


B2BCD_IP #(7, 2) u_B2BCD_IP (
  .Binary_code(bin_result_r),
  .BCD_code(bcd_result)
);




endmodule

