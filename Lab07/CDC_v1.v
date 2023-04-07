// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : CDC.v
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                 AREA             LATENCY
// 1.0     2022-11-12 Brian Hsieh                                  37511.813252     70588
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// Clock Domain Crossing (CDC)
// -----------------------------------------------------------------------------
// PARAMETERS
// PARAM_NAME RANGE      : DESCRIPTION           : DEFAULT
//
// -----------------------------------------------------------------------------
// REUSE ISSUES
// Reset Schemes : asynchronous active-low reset, rst_n
// Clock Domains : clk1 (36.7 ns), clk2 (6.8 ns), clk3 (2.6 ns)
// Asynchronous I/F : N/A
// Instantiations : synchronizer, syn_XOR (double flop synchronizer + xor)
// Other : 
// -----------------------------------------------------------------------------

`include "synchronizer.v"
`include "syn_XOR.v"
module CDC(
	//Input Port
	clk1,
  clk2,
  clk3,
	rst_n,
	in_valid1,
	in_valid2,
	user1,
	user2,

  //Output Port
  out_valid1,
  out_valid2,
	equal,
	exceed,
	winner
); 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                             Input & Output Ports                                                              //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
input              clk1;
input              clk2;
input              clk3;
input              rst_n;
input              in_valid1;
input              in_valid2;
input       [ 3:0] user1;
input       [ 3:0] user2;

output reg	       out_valid1;
output reg         out_valid2;
output reg	       equal;
output reg	       exceed;
output reg	       winner;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                  Main Signals                                                                 //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//----clk1----
reg   [ 3:0] user1_r;
reg   [ 3:0] user1_nxt;
reg   [ 3:0] user2_r;
reg   [ 3:0] user2_nxt;

reg   [ 5:0] cnt_cycle_r;
reg   [ 5:0] cnt_cycle_nxt;

// reg   [ 5:0] cnt_epoch_r;
// reg   [ 5:0] cnt_epoch_nxt;

reg   [ 5:0] cdf_r            [0:9];
reg   [ 5:0] cdf_nxt          [0:9];

reg   [ 5:0] pt_u1_r;
reg   [ 5:0] pt_u1_nxt;

reg   [ 5:0] pt_u2_r;
reg   [ 5:0] pt_u2_nxt;

reg   [ 1:0] who_is_winner_r;
reg   [ 1:0] who_is_winner_nxt;

reg   [ 4:0] pt_left_r;
reg   [ 4:0] pt_left_nxt;

reg   [ 5:0] num_exceed;
reg   [ 4:0] num_equal;

reg   [ 5:0] denominator;
reg   [12:0] numerator_exceed;
reg   [10:0] numerator_equal;
reg   [ 6:0] p_exceed;
reg   [ 6:0] p_equal;

reg   [ 6:0] p_exceed_tx1_r  ;
reg   [ 6:0] p_exceed_tx1_nxt;
reg   [ 6:0] p_exceed_tx2_r  ;
reg   [ 6:0] p_exceed_tx2_nxt;
reg   [ 6:0] p_equal_tx1_r   ;
reg   [ 6:0] p_equal_tx1_nxt ;
reg   [ 6:0] p_equal_tx2_r   ;
reg   [ 6:0] p_equal_tx2_nxt ;


wire         flag1_clk1_1stcycle;
wire         flag1_clk1;
wire         flag1_clk1_prev;
wire         flag2_clk1;
wire         flag2_clk1_prev;
wire         cnt_5epoch;
wire         cnt_5cycle;
wire         jqk_u1;
wire         jqk_u2;
wire  [ 3:0] user1_rev;
wire  [ 3:0] user2_rev;
wire         cdf_10p_dec_u1;
wire         cdf_9p_dec_u1 ;
wire         cdf_8p_dec_u1 ;
wire         cdf_7p_dec_u1 ;
wire         cdf_6p_dec_u1 ;
wire         cdf_5p_dec_u1 ;
wire         cdf_4p_dec_u1 ;
wire         cdf_3p_dec_u1 ;
wire         cdf_2p_dec_u1 ;
wire         cdf_1p_dec_u1 ;
wire         cdf_10p_dec_u2;
wire         cdf_9p_dec_u2 ;
wire         cdf_8p_dec_u2 ;
wire         cdf_7p_dec_u2 ;
wire         cdf_6p_dec_u2 ;
wire         cdf_5p_dec_u2 ;
wire         cdf_4p_dec_u2 ;
wire         cdf_3p_dec_u2 ;
wire         cdf_2p_dec_u2 ;
wire         cdf_1p_dec_u2 ;

//----clk2----

//----clk3----
wire         flag1_clk3;
reg          flag1_clk3_dly1;
wire         flag2_clk3;
reg          flag2_clk3_dly1;
wire         u1_exceed;
wire         u2_exceed;
wire         winner_exist;
wire         winner_2ndcycle;

reg   [ 2:0] cnt_out_valid1_r  ;
reg   [ 2:0] cnt_out_valid1_nxt;

reg          card3_r;
reg          card3_nxt;


reg          out_valid1_nxt;
reg          out_valid2_nxt;
reg          equal_nxt;
reg          exceed_nxt;
reg          winner_nxt;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
//----clk1----

//----clk2----

//----clk3----

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                     Main Code                                                                 //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//============================================
//   clk1 domain
//============================================

// user1_reg
always @(posedge clk1 or negedge rst_n) begin
  if (!rst_n) begin
    user1_r <= 4'd0;
  end
  else begin
    user1_r <= user1_nxt;
  end
end

always @(*) begin
  if (in_valid1) begin
    user1_nxt = user1_rev;
  end
  else begin
    user1_nxt = user1_r;
  end
end


// user2_reg
always @(posedge clk1 or negedge rst_n) begin
  if (!rst_n) begin
    user2_r <= 4'd0;
  end
  else begin
    user2_r <= user2_nxt;
  end
end

always @(*) begin
  if (in_valid2) begin
    user2_nxt = user2_rev;
  end
  else begin
    user2_nxt = user2_r;
  end
end





// cnt_cycle
always @(posedge clk1 or negedge rst_n) begin
  if (!rst_n) begin
    cnt_cycle_r <= 3'd0;
  end
  else begin
    cnt_cycle_r <= cnt_cycle_nxt;
  end
end

always @(*) begin
  if ( (!in_valid1 && !in_valid2)  ) begin
    cnt_cycle_nxt = 3'd0;
  end
  else if (cnt_cycle_r == 6'd50) begin
    cnt_cycle_nxt = 3'd1;
  end
  else begin
    cnt_cycle_nxt = cnt_cycle_r + 3'd1;
  end
end


// cnt_epoch
// always @(posedge clk1 or negedge rst_n) begin
//   if (!rst_n) begin
//     cnt_epoch_r <= 6'd0;
//   end
//   else begin
//     cnt_epoch_r <= cnt_epoch_nxt;
//   end
// end

// always @(*) begin
//   if ( (!in_valid1 && !in_valid2) || cnt_5epoch ) begin
//     cnt_epoch_nxt = 6'd0;
//   end
//   else if (flag2_clk1) begin
//     cnt_epoch_nxt = cnt_epoch_r + 6'd1;
//   end
//   else begin
//     cnt_epoch_nxt = cnt_epoch_r;
//   end
// end


// cdf
always @(posedge clk1 or negedge rst_n) begin
  if (!rst_n) begin
    cdf_r[9] <= 'd4;
    cdf_r[8] <= 'd8;
    cdf_r[7] <= 'd12;
    cdf_r[6] <= 'd16;
    cdf_r[5] <= 'd20;
    cdf_r[4] <= 'd24;
    cdf_r[3] <= 'd28;
    cdf_r[2] <= 'd32;
    cdf_r[1] <= 'd36;
    cdf_r[0] <= 'd52;
  end
  else begin
    cdf_r[9] <= cdf_nxt[9];
    cdf_r[8] <= cdf_nxt[8];
    cdf_r[7] <= cdf_nxt[7];
    cdf_r[6] <= cdf_nxt[6];
    cdf_r[5] <= cdf_nxt[5];
    cdf_r[4] <= cdf_nxt[4];
    cdf_r[3] <= cdf_nxt[3];
    cdf_r[2] <= cdf_nxt[2];
    cdf_r[1] <= cdf_nxt[1];
    cdf_r[0] <= cdf_nxt[0];
  end
end

always @(*) begin
  if (cnt_5epoch) begin
    cdf_nxt[9] = 'd4;
  end
  else if (in_valid1) begin
    if (cdf_10p_dec_u1) begin
      cdf_nxt[9] = cdf_r[9] - 'd1;
    end
    else begin
      cdf_nxt[9] = cdf_r[9];
    end
  end
  else if (in_valid2) begin
    if (cdf_10p_dec_u2) begin
      cdf_nxt[9] = cdf_r[9] - 'd1;
    end
    else begin
      cdf_nxt[9] = cdf_r[9];
    end
  end
  else begin
    cdf_nxt[9] = 'd4;
  end
end

always @(*) begin
  if (cnt_5epoch) begin
    cdf_nxt[8] = 'd8;
  end
  else if (in_valid1) begin
    if (cdf_9p_dec_u1) begin
      cdf_nxt[8] = cdf_r[8] - 'd1;
    end
    else begin
      cdf_nxt[8] = cdf_r[8];
    end
  end
  else if (in_valid2) begin
    if (cdf_9p_dec_u2) begin
      cdf_nxt[8] = cdf_r[8] - 'd1;
    end
    else begin
      cdf_nxt[8] = cdf_r[8];
    end
  end
  else begin
    cdf_nxt[8] = 'd8;
  end
end

always @(*) begin
  if (cnt_5epoch) begin
    cdf_nxt[7] = 'd12;
  end
  else if (in_valid1) begin
    if (cdf_8p_dec_u1) begin
      cdf_nxt[7] = cdf_r[7] - 'd1;
    end
    else begin
      cdf_nxt[7] = cdf_r[7];
    end
  end
  else if (in_valid2) begin
    if (cdf_8p_dec_u2) begin
      cdf_nxt[7] = cdf_r[7] - 'd1;
    end
    else begin
      cdf_nxt[7] = cdf_r[7];
    end
  end
  else begin
    cdf_nxt[7] = 'd12;
  end
end

always @(*) begin
  if (cnt_5epoch) begin
    cdf_nxt[6] = 'd16;
  end
  else if (in_valid1) begin
    if (cdf_7p_dec_u1) begin
      cdf_nxt[6] = cdf_r[6] - 'd1;
    end
    else begin
      cdf_nxt[6] = cdf_r[6];
    end
  end
  else if (in_valid2) begin
    if (cdf_7p_dec_u2) begin
      cdf_nxt[6] = cdf_r[6] - 'd1;
    end
    else begin
      cdf_nxt[6] = cdf_r[6];
    end
  end
  else begin
    cdf_nxt[6] = 'd16;
  end
end

always @(*) begin
  if (cnt_5epoch) begin
    cdf_nxt[5] = 'd20;
  end
  else if (in_valid1) begin
    if (cdf_6p_dec_u1) begin
      cdf_nxt[5] = cdf_r[5] - 'd1;
    end
    else begin
      cdf_nxt[5] = cdf_r[5];
    end
  end
  else if (in_valid2) begin
    if (cdf_6p_dec_u2) begin
      cdf_nxt[5] = cdf_r[5] - 'd1;
    end
    else begin
      cdf_nxt[5] = cdf_r[5];
    end
  end
  else begin
    cdf_nxt[5] = 'd20;
  end
end

always @(*) begin
  if (cnt_5epoch) begin
    cdf_nxt[4] = 'd24;
  end
  else if (in_valid1) begin
    if (cdf_5p_dec_u1) begin
      cdf_nxt[4] = cdf_r[4] - 'd1;
    end
    else begin
      cdf_nxt[4] = cdf_r[4];
    end
  end
  else if (in_valid2) begin
    if (cdf_5p_dec_u2) begin
      cdf_nxt[4] = cdf_r[4] - 'd1;
    end
    else begin
      cdf_nxt[4] = cdf_r[4];
    end
  end
  else begin
    cdf_nxt[4] = 'd24;
  end
end

always @(*) begin
  if (cnt_5epoch) begin
    cdf_nxt[3] = 'd28;
  end
  else if (in_valid1) begin
    if (cdf_4p_dec_u1) begin
      cdf_nxt[3] = cdf_r[3] - 'd1;
    end
    else begin
      cdf_nxt[3] = cdf_r[3];
    end
  end
  else if (in_valid2) begin
    if (cdf_4p_dec_u2) begin
      cdf_nxt[3] = cdf_r[3] - 'd1;
    end
    else begin
      cdf_nxt[3] = cdf_r[3];
    end
  end
  else begin
    cdf_nxt[3] = 'd28;
  end
end

always @(*) begin
  if (cnt_5epoch) begin
    cdf_nxt[2] = 'd32;
  end
  else if (in_valid1) begin
    if (cdf_3p_dec_u1) begin
      cdf_nxt[2] = cdf_r[2] - 'd1;
    end
    else begin
      cdf_nxt[2] = cdf_r[2];
    end
  end
  else if (in_valid2) begin
    if (cdf_3p_dec_u2) begin
      cdf_nxt[2] = cdf_r[2] - 'd1;
    end
    else begin
      cdf_nxt[2] = cdf_r[2];
    end
  end
  else begin
    cdf_nxt[2] = 'd32;
  end
end

always @(*) begin
  if (cnt_5epoch) begin
    cdf_nxt[1] = 'd36;
  end
  else if (in_valid1) begin
    if (cdf_2p_dec_u1) begin
      cdf_nxt[1] = cdf_r[1] - 'd1;
    end
    else begin
      cdf_nxt[1] = cdf_r[1];
    end
  end
  else if (in_valid2) begin
    if (cdf_2p_dec_u2) begin
      cdf_nxt[1] = cdf_r[1] - 'd1;
    end
    else begin
      cdf_nxt[1] = cdf_r[1];
    end
  end
  else begin
    cdf_nxt[1] = 'd36;
  end
end

always @(*) begin
  if (cnt_5epoch) begin
    cdf_nxt[0] = 'd52;
  end
  else if (in_valid1) begin
    if (cdf_1p_dec_u1) begin
      cdf_nxt[0] = cdf_r[0] - 'd1;
    end
    else begin
      cdf_nxt[0] = cdf_r[0];
    end
  end
  else if (in_valid2) begin
    if (cdf_1p_dec_u2) begin
      cdf_nxt[0] = cdf_r[0] - 'd1;
    end
    else begin
      cdf_nxt[0] = cdf_r[0];
    end
  end
  else begin
    cdf_nxt[0] = 'd52;
  end
end


// pt_u1
always @(posedge clk1 or negedge rst_n) begin
  if (!rst_n) begin
    pt_u1_r <= 6'd0;
  end
  else begin
    pt_u1_r <= pt_u1_nxt;
  end
end

always @(*) begin
  if (flag2_clk1 && in_valid2) begin
    pt_u1_nxt = 6'd0;
  end
  else if (flag2_clk1) begin
    pt_u1_nxt = user1_nxt;
  end
  else if (in_valid1) begin
    pt_u1_nxt = pt_u1_r + user1_nxt;
  end 
  else begin
    pt_u1_nxt = pt_u1_r;
  end
end


// pt_u2
always @(posedge clk1 or negedge rst_n) begin
  if (!rst_n) begin
    pt_u2_r <= 6'd0;
  end
  else begin
    pt_u2_r <= pt_u2_nxt;
  end
end

always @(*) begin
  if (flag2_clk1 && in_valid1) begin
    pt_u2_nxt = 6'd0;
  end
  else if (flag2_clk1) begin
    pt_u2_nxt = user2_nxt;
  end
  else if (in_valid2) begin
    pt_u2_nxt = pt_u2_r + user2_nxt;
  end
  else begin
    pt_u2_nxt = pt_u2_r;
  end
end


// who_is_winner
always @(posedge clk1 or negedge rst_n) begin
  if (!rst_n) begin
    who_is_winner_r <= 2'b00;
  end
  else begin
    who_is_winner_r <= who_is_winner_nxt;
  end
end

always @(*) begin
  if (flag2_clk1_prev) begin
    if ( (pt_u1_nxt == pt_u2_nxt) || (u1_exceed && u2_exceed) ) begin
      who_is_winner_nxt = 2'b00;
    end
    else if ( (pt_u1_nxt > pt_u2_nxt && ~u1_exceed) || u2_exceed ) begin
      who_is_winner_nxt = 2'b10;
    end
    else begin
      who_is_winner_nxt = 2'b11;
    end
  end
  else begin
    who_is_winner_nxt = who_is_winner_r;
  end
end


// pt_left
always @(posedge clk1 or negedge rst_n) begin
  if (!rst_n) begin
    pt_left_r <= 5'd21;
  end
  else begin
    pt_left_r <= pt_left_nxt;
  end
end

always @(*) begin
  if (cnt_5cycle) begin
    pt_left_nxt = 5'd21;
  end
  else if (in_valid1) begin
    if (pt_left_r > user1_nxt) begin
      pt_left_nxt = pt_left_r - user1_nxt;
    end
    else begin
      pt_left_nxt = 5'd0;
    end
  end
  else if (in_valid2) begin
    if (pt_left_r > user2_nxt) begin
      pt_left_nxt = pt_left_r - user2_nxt;
    end
    else begin
      pt_left_nxt = 5'd0;
    end
  end
  else begin
    pt_left_nxt = 5'd21;
  end
end


// num_exceed, num_equal (comb logic)
always @(*) begin
  if (pt_left_nxt > 'd10) begin
    num_exceed = 'd0;
    num_equal  = 'd0;
  end
  else if ( in_valid1 && (flag1_clk1_prev || flag1_clk1_1stcycle || cnt_5cycle) ) begin
    if (pt_left_r > user1_nxt) begin
      if (pt_left_nxt == 'd10) begin
        num_exceed = 'd0;
      end
      else begin
        num_exceed = cdf_nxt[pt_left_nxt];
      end
      num_equal  = cdf_nxt[pt_left_nxt-1] - num_exceed;
    end
    else begin
      num_exceed = cdf_nxt[0];
      num_equal  = 'd0;
    end
  end
  else if ( in_valid2 && (flag1_clk1_prev || flag1_clk1_1stcycle || cnt_5cycle) ) begin
    if (pt_left_r > user2_nxt) begin
      if (pt_left_nxt == 'd10) begin
        num_exceed = 'd0;
      end
      else begin
        num_exceed = cdf_nxt[pt_left_nxt];
      end
      num_equal  = cdf_nxt[pt_left_nxt-1] - num_exceed;
    end
    else begin
      num_exceed = cdf_nxt[0];
      num_equal  = 'd0;
    end
  end
  else begin
    num_exceed = 'd0;
    num_equal  = 'd0;
  end
end


// denominator (comb logic)
always @(*) begin
  denominator = cdf_nxt[0];
end


// numerator_exceed (comb logic)
always @(*) begin
  numerator_exceed = num_exceed * 100;
end


// numerator_equal (comb logic)
always @(*) begin
  numerator_equal  = num_equal  * 100;
end


// p_exceed (comb logic)
always @(*) begin
  p_exceed = numerator_exceed / denominator;
end


// p_equal (comb logic)
always @(*) begin
  p_equal = numerator_equal / denominator;
end


// p_exceed_tx1
always @(posedge clk1 or negedge rst_n) begin
  if (!rst_n) begin
    p_exceed_tx1_r <= 7'd0;
  end
  else begin
    p_exceed_tx1_r <= p_exceed_tx1_nxt;
  end
end

always @(*) begin
  if (flag1_clk1_prev) begin
    p_exceed_tx1_nxt = p_exceed;
  end
  else begin
    p_exceed_tx1_nxt = p_exceed_tx1_r;
  end
end


// p_exceed_tx2
always @(posedge clk1 or negedge rst_n) begin
  if (!rst_n) begin
    p_exceed_tx2_r <= 7'd0;
  end
  else begin
    p_exceed_tx2_r <= p_exceed_tx2_nxt;
  end
end

always @(*) begin
  if (flag1_clk1_1stcycle) begin
    p_exceed_tx2_nxt = p_exceed;
  end
  else begin
    p_exceed_tx2_nxt = p_exceed_tx2_r;
  end
end


// p_equal_tx1
always @(posedge clk1 or negedge rst_n) begin
  if (!rst_n) begin
    p_equal_tx1_r <= 7'd0;
  end
  else begin
    p_equal_tx1_r <= p_equal_tx1_nxt;
  end
end

always @(*) begin
  if (flag1_clk1_prev) begin
    p_equal_tx1_nxt = p_equal;
  end
  else begin
    p_equal_tx1_nxt = p_equal_tx1_r;
  end
end


// p_equal_tx2
always @(posedge clk1 or negedge rst_n) begin
  if (!rst_n) begin
    p_equal_tx2_r <= 7'd0;
  end
  else begin
    p_equal_tx2_r <= p_equal_tx2_nxt;
  end
end

always @(*) begin
  if (flag1_clk1_1stcycle) begin
    p_equal_tx2_nxt = p_equal;
  end
  else begin
    p_equal_tx2_nxt = p_equal_tx2_r;
  end
end


//============================================
//   clk2 domain
//============================================


//============================================
//   clk3 domain
//============================================

// cnt_out_valid1
always @(posedge clk3 or negedge rst_n) begin
  if (!rst_n) begin
    cnt_out_valid1_r <= 3'd6;
  end
  else begin
    cnt_out_valid1_r <= cnt_out_valid1_nxt;
  end
end

always @(*) begin
  if (out_valid1) begin
    cnt_out_valid1_nxt = cnt_out_valid1_r - 3'd1;
  end
  else begin
    cnt_out_valid1_nxt = 3'd6;
  end
end


// card3
always @(posedge clk3 or negedge rst_n) begin
  if (!rst_n) begin
    card3_r <= 1'b0;
  end
  else begin
    card3_r <= card3_nxt;
  end
end

always @(*) begin
  if (flag1_clk3_dly1) begin
    card3_nxt = ~card3_r;
  end
  else begin
    card3_nxt = card3_r;
  end
end

// out_valid1
always @(posedge clk3 or negedge rst_n) begin
  if (!rst_n) begin
    out_valid1 <= 1'b0;
  end
  else begin
    out_valid1 <= out_valid1_nxt;
  end
end

always @(*) begin
  if ( flag1_clk3_dly1 || (cnt_out_valid1_nxt < 3'd6) ) begin
    out_valid1_nxt = 1'b1;
  end
  else begin
    out_valid1_nxt = 1'b0;
  end
end


// equal, exceed
always @(posedge clk3 or negedge rst_n) begin
  if (!rst_n) begin
    equal  <= 1'b0;
    exceed <= 1'b0;
  end
  else begin
    equal  <= equal_nxt;
    exceed <= exceed_nxt;
  end
end

// always @(*) begin
//   if (cnt_out_valid1_nxt == 3'd6) begin
//     if (flag1_clk3_dly1) begin
//       if (card3_nxt) begin
//         equal_nxt  = p_equal_tx1_r[cnt_out_valid1_nxt];
//         exceed_nxt = p_exceed_tx1_r[cnt_out_valid1_nxt];
//       end
//       else begin
//         equal_nxt  = p_equal_tx2_r[cnt_out_valid1_nxt];
//         exceed_nxt = p_exceed_tx2_r[cnt_out_valid1_nxt];
//       end
//     end
//     else begin
//       equal_nxt  = 1'b0;
//       exceed_nxt = 1'b0;
//     end
//   end
//   else if (cnt_out_valid1_nxt == 3'd7) begin
//     equal_nxt  = 1'b0;
//     exceed_nxt = 1'b0;
//   end
//   else begin
//     if (card3_nxt) begin
//       equal_nxt  = p_equal_tx1_r[cnt_out_valid1_nxt];
//       exceed_nxt = p_exceed_tx1_r[cnt_out_valid1_nxt];
//     end
//     else begin
//       equal_nxt  = p_equal_tx2_r[cnt_out_valid1_nxt];
//       exceed_nxt = p_exceed_tx2_r[cnt_out_valid1_nxt];
//     end
//   end
// end

always @(*) begin
  case (cnt_out_valid1_nxt)
    3'd6: begin
      if (flag1_clk3_dly1) begin
        if (card3_nxt) begin
          equal_nxt  = p_equal_tx1_r[6];
          exceed_nxt = p_exceed_tx1_r[6];
        end
        else begin
          equal_nxt  = p_equal_tx2_r[6];
          exceed_nxt = p_exceed_tx2_r[6];
        end
      end
      else begin
        equal_nxt  = 1'b0;
        exceed_nxt = 1'b0;
      end
    end
    3'd5: begin
      if (card3_nxt) begin
        equal_nxt  = p_equal_tx1_r[5];
        exceed_nxt = p_exceed_tx1_r[5];
      end
      else begin
        equal_nxt  = p_equal_tx2_r[5];
        exceed_nxt = p_exceed_tx2_r[5];
      end
    end
    3'd4: begin
      if (card3_nxt) begin
        equal_nxt  = p_equal_tx1_r[4];
        exceed_nxt = p_exceed_tx1_r[4];
      end
      else begin
        equal_nxt  = p_equal_tx2_r[4];
        exceed_nxt = p_exceed_tx2_r[4];
      end
    end
    3'd3: begin
      if (card3_nxt) begin
        equal_nxt  = p_equal_tx1_r[3];
        exceed_nxt = p_exceed_tx1_r[3];
      end
      else begin
        equal_nxt  = p_equal_tx2_r[3];
        exceed_nxt = p_exceed_tx2_r[3];
      end
    end
    3'd2: begin
      if (card3_nxt) begin
        equal_nxt  = p_equal_tx1_r[2];
        exceed_nxt = p_exceed_tx1_r[2];
      end
      else begin
        equal_nxt  = p_equal_tx2_r[2];
        exceed_nxt = p_exceed_tx2_r[2];
      end
    end
    3'd1: begin
      if (card3_nxt) begin
        equal_nxt  = p_equal_tx1_r[1];
        exceed_nxt = p_exceed_tx1_r[1];
      end
      else begin
        equal_nxt  = p_equal_tx2_r[1];
        exceed_nxt = p_exceed_tx2_r[1];
      end
    end
    3'd0: begin
      if (card3_nxt) begin
        equal_nxt  = p_equal_tx1_r[0];
        exceed_nxt = p_exceed_tx1_r[0];
      end
      else begin
        equal_nxt  = p_equal_tx2_r[0];
        exceed_nxt = p_exceed_tx2_r[0];
      end
    end
    3'd7: begin
      equal_nxt  = 1'b0;
      exceed_nxt = 1'b0;
    end
  endcase
end


// flag1_clk3_dly1
always @(posedge clk3 or negedge rst_n) begin
  if (!rst_n) begin
    flag1_clk3_dly1 <= 1'b0;
  end
  else begin
    flag1_clk3_dly1 <= flag1_clk3;
  end
end


// flag2_clk3_dly1
always @(posedge clk3 or negedge rst_n) begin
  if (!rst_n) begin
    flag2_clk3_dly1 <= 1'b0;
  end
  else begin
    flag2_clk3_dly1 <= flag2_clk3;
  end
end


// out_valid2
always @(posedge clk3 or negedge rst_n) begin
  if (!rst_n) begin
    out_valid2 <= 1'b0;
  end
  else begin
    out_valid2 <= out_valid2_nxt;
  end
end

always @(*) begin
  if ( flag2_clk3 || (winner_exist && flag2_clk3_dly1) ) begin
    out_valid2_nxt = 1'b1;
  end
  else begin
    out_valid2_nxt = 1'b0;
  end
end


// winner
always @(posedge clk3 or negedge rst_n) begin
  if (!rst_n) begin
    winner <= 1'b0;
  end
  else begin
    winner <= winner_nxt;
  end
end

always @(*) begin
  if (flag2_clk3) begin
    winner_nxt = winner_exist;
  end
  else if (flag2_clk3_dly1) begin
    winner_nxt = winner_2ndcycle;
  end
  else begin
    winner_nxt = 1'b0;
  end
end


// Control signals
assign cnt_5epoch          = cnt_cycle_r == 6'd49;
assign cnt_5cycle          = cnt_cycle_r == 6'd4 || cnt_cycle_r == 6'd9 || cnt_cycle_r == 6'd14 || cnt_cycle_r == 6'd19 || cnt_cycle_r == 6'd24 || cnt_cycle_r == 6'd29 || cnt_cycle_r == 6'd34 || cnt_cycle_r == 6'd39 || cnt_cycle_r == 6'd44 || cnt_cycle_r == 6'd49;
assign flag1_clk1_1stcycle = cnt_cycle_r == 6'd3 || cnt_cycle_r == 6'd8 || cnt_cycle_r == 6'd13 || cnt_cycle_r == 6'd18 || cnt_cycle_r == 6'd23 || cnt_cycle_r == 6'd28 || cnt_cycle_r == 6'd33 || cnt_cycle_r == 6'd38 || cnt_cycle_r == 6'd43 || cnt_cycle_r == 6'd48;
assign flag1_clk1          = flag1_clk1_1stcycle || cnt_5cycle;
assign flag1_clk1_prev     = cnt_cycle_r == 6'd2 || cnt_cycle_r == 6'd7 || cnt_cycle_r == 6'd12 || cnt_cycle_r == 6'd17 || cnt_cycle_r == 6'd22 || cnt_cycle_r == 6'd27 || cnt_cycle_r == 6'd32 || cnt_cycle_r == 6'd37 || cnt_cycle_r == 6'd42 || cnt_cycle_r == 6'd47;
assign flag2_clk1          = cnt_cycle_r == 6'd10 || cnt_cycle_r == 6'd20 || cnt_cycle_r == 6'd30 || cnt_cycle_r == 6'd40 || cnt_cycle_r == 6'd50;
assign flag2_clk1_prev     = cnt_cycle_r == 6'd9 || cnt_cycle_r == 6'd19 || cnt_cycle_r == 6'd29 || cnt_cycle_r == 6'd39 || cnt_cycle_r == 6'd49;
assign u1_exceed           = pt_u1_nxt > 6'd21;
assign u2_exceed           = pt_u2_nxt > 6'd21;
assign winner_exist        = who_is_winner_r[1];
assign winner_2ndcycle     = who_is_winner_r[0];

assign jqk_u1              = user1 == 4'd11 || user1 == 4'd12 || user1 == 4'd13 ;
assign jqk_u2              = user2 == 4'd11 || user2 == 4'd12 || user2 == 4'd13 ;
assign user1_rev           = jqk_u1 ? 4'd1 : user1;
assign user2_rev           = jqk_u2 ? 4'd1 : user2;

assign cdf_10p_dec_u1      = user1_nxt == 4'd10;
assign cdf_9p_dec_u1       = user1_nxt == 4'd9  || cdf_10p_dec_u1;
assign cdf_8p_dec_u1       = user1_nxt == 4'd8  || cdf_9p_dec_u1;
assign cdf_7p_dec_u1       = user1_nxt == 4'd7  || cdf_8p_dec_u1;
assign cdf_6p_dec_u1       = user1_nxt == 4'd6  || cdf_7p_dec_u1;
assign cdf_5p_dec_u1       = user1_nxt == 4'd5  || cdf_6p_dec_u1;
assign cdf_4p_dec_u1       = user1_nxt == 4'd4  || cdf_5p_dec_u1;
assign cdf_3p_dec_u1       = user1_nxt == 4'd3  || cdf_4p_dec_u1;
assign cdf_2p_dec_u1       = user1_nxt == 4'd2  || cdf_3p_dec_u1;
assign cdf_1p_dec_u1       = user1_nxt == 4'd1  || cdf_2p_dec_u1;

assign cdf_10p_dec_u2      = user2_nxt == 4'd10;
assign cdf_9p_dec_u2       = user2_nxt == 4'd9  || cdf_10p_dec_u2;
assign cdf_8p_dec_u2       = user2_nxt == 4'd8  || cdf_9p_dec_u2;
assign cdf_7p_dec_u2       = user2_nxt == 4'd7  || cdf_8p_dec_u2;
assign cdf_6p_dec_u2       = user2_nxt == 4'd6  || cdf_7p_dec_u2;
assign cdf_5p_dec_u2       = user2_nxt == 4'd5  || cdf_6p_dec_u2;
assign cdf_4p_dec_u2       = user2_nxt == 4'd4  || cdf_5p_dec_u2;
assign cdf_3p_dec_u2       = user2_nxt == 4'd3  || cdf_4p_dec_u2;
assign cdf_2p_dec_u2       = user2_nxt == 4'd2  || cdf_3p_dec_u2;
assign cdf_1p_dec_u2       = user2_nxt == 4'd1  ||  cdf_2p_dec_u2;


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                Module Instantiation                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//---------------------------------------------------------------------
//   syn_XOR
//---------------------------------------------------------------------
syn_XOR u_syn_XOR_1 (.IN(flag1_clk1),.OUT(flag1_clk3),.TX_CLK(clk1),.RX_CLK(clk3),.RST_N(rst_n));
syn_XOR u_syn_XOR_2 (.IN(flag2_clk1),.OUT(flag2_clk3),.TX_CLK(clk1),.RX_CLK(clk3),.RST_N(rst_n));

endmodule