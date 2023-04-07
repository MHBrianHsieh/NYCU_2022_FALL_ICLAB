// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : CHECKER.sv
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                 
// 1.0     2022-11-30 Brian Hsieh      
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// Assertion:
// 1. All output signals (including FD.sv and bridge.sv) should be zero after reset.
// 2. If action is completed, err_msg should be 4’b0.
// 3. If action is not completed, out_info should be 64’b0.
// 4. The gap between each input valid is at least 1 cycle and at most 5 cycles.
// 5. All input valid signals won’t overlap with each other.
// 6. Out_valid can only be high for exactly one cycle.
// 7. Next operation will be valid 2-10 cycles after out_valid fall.
// 8. Latency should be less than 1200 cycles for each operation.
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

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

//declare other cover group


// covergroup cg1 including coverpoint inf.D.d_id[0]
covergroup cg1 @(posedge clk iff(inf.id_valid));
  coverpoint inf.D.d_id[0] {
    option.at_least = 1;
    option.auto_bin_max = 256;
  }
endgroup : cg1


// covergroup cg2 including coverpoint inf.D.d_act[0] with transition bins from one action to itself or others
covergroup cg2 @(posedge clk iff(inf.act_valid));
  coverpoint inf.D.d_act[0] {
    option.at_least = 10;
    bins action_bin [] = (Take, Deliver, Order, Cancel => Take, Deliver, Order, Cancel);
  }
endgroup : cg2


// covergroup cg3 including coverpoint inf.complete
covergroup cg3 @(negedge clk iff(inf.out_valid));
  coverpoint inf.complete {
    option.at_least = 200;
    bins complete_bin [] = {0, 1};
  }
endgroup : cg3


// covergroup cg4 including coverpoint inf.err_msg
covergroup cg4 @(negedge clk iff(inf.out_valid));
  coverpoint inf.err_msg {
    option.at_least = 20;
    bins err_msg_bin [] = {No_Food, D_man_busy, No_customers, Res_busy, Wrong_cancel, Wrong_res_ID, Wrong_food_ID};
  }
endgroup : cg4


cg1 cg1_inst = new();
cg2 cg2_inst = new();
cg3 cg3_inst = new();
cg4 cg4_inst = new();


//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write the required assertions below
//  assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0 [*2])
//  else
//  begin
//  	$display("Assertion X is violated");
//  	$fatal; 
//  end
wire #(0.5) rst_reg = inf.rst_n;


//write other assertions

Action             action_r_cs;
Action             action_r_ns;

// action_reg
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    action_r_cs <= No_action;
  end
  else begin
    action_r_cs <= action_r_ns;
  end
end

always_comb begin
  if (inf.act_valid === 1'b1) begin
    action_r_ns = inf.D.d_act[0];
  end
  else begin
    action_r_ns = action_r_cs;
  end
end


//===========================================================================================================================
// Assertion 1. All outputs signals (including FD.sv and bridge.sv) should be zero after reset.
//===========================================================================================================================

always @(negedge rst_reg) begin
  SPEC1_FD: assert ( (inf.out_valid === 1'b0) && (inf.err_msg === 4'd0) && (inf.complete === 1'b0) && (inf.out_info === 64'd0) && 
                     (inf.C_addr === 8'd0) && (inf.C_data_w === 64'd0) && (inf.C_in_valid === 1'b0) && (inf.C_r_wb === 1'b0) )
  else begin
    $display("Assertion 1 is violated");
    $fatal;
  end
end

always @(negedge rst_reg) begin
  SPEC1_bridge: assert ( (inf.C_out_valid === 1'b0) && (inf.C_data_r === 64'd0) && 
                         (inf.AR_VALID === 1'b0) && (inf.AR_ADDR === 17'd0) && (inf.R_READY == 1'b0) && (inf.AW_VALID === 1'b0) &&
                         (inf.AW_ADDR === 17'd0) && (inf.W_VALID === 1'b0) && (inf.W_DATA == 64'd0) && (inf.B_READY === 1'b0) )
  else begin
    $display("Assertion 1 is violated");
    $fatal;
  end
end

//===========================================================================================================================
// Assertion 2. If action is completed, err_msg should be 4’b0.
//===========================================================================================================================

SPEC2: assert property ( @(negedge clk) (inf.complete === 1'b1 && inf.out_valid === 1'b1) |-> (inf.err_msg === 4'd0) )
else begin
  $display("Assertion 2 is violated");
  $fatal;
end

//===========================================================================================================================
// Assertion 3. If action is not completed, out_info should be 64’b0.
//===========================================================================================================================

SPEC3: assert property ( @(negedge clk) (inf.complete === 1'b0 && inf.out_valid === 1'b1) |-> (inf.out_info === 64'd0) )
else begin
  $display("Assertion 3 is violated");
  $fatal;
end

//===========================================================================================================================
// Assertion 4. The gap between each input valid is at least 1 cycle and at most 5 cycles.
//===========================================================================================================================


// Take action
SPEC4_TAKE: assert property ( p_take )                                  
else begin
  $display("Assertion 4 is violated");
  $fatal;
end

property p_take;
  @(posedge clk) (inf.D.d_act[0] === Take && inf.act_valid === 1'b1) |=> ##[1:5] ( q_take ) ;
endproperty

sequence q_take;
  (  (inf.cus_valid === 1'b1) or ( (inf.id_valid === 1'b1) ##[2:6] (inf.cus_valid === 1'b1) )  );
endsequence: q_take


SPEC4_TAKE_1: assert property ( p_take_1 )                                  
else begin
  $display("Assertion 4 is violated");
  $fatal;
end

property p_take_1;
  @(posedge clk) (inf.D.d_act[0] === Take && inf.act_valid === 1'b1) |=> ( q_take_1 ) ;
endproperty

sequence q_take_1;
  (  (inf.cus_valid === 1'b0) && (inf.id_valid === 1'b0)   );
endsequence: q_take_1


SPEC4_TAKE_2: assert property ( p_take_2 )                                  
else begin
  $display("Assertion 4 is violated");
  $fatal;
end

property p_take_2;
  @(posedge clk) (action_r_cs === Take && inf.id_valid === 1'b1) |=> ( q_take_2 ) ;
endproperty

sequence q_take_2;
  ( inf.cus_valid === 1'b0 );
endsequence: q_take_2


// Deliver action
SPEC4_DELIVER: assert property ( p_deliver )                                  
else begin
  $display("Assertion 4 is violated");
  $fatal;
end

property p_deliver;
  @(posedge clk) (inf.D.d_act[0] === Deliver && inf.act_valid === 1'b1) |=> ##[1:5] ( q_deliver ) ;
endproperty

sequence q_deliver;
  ( inf.id_valid === 1'b1 );
endsequence: q_deliver


SPEC4_DELIVER_1: assert property ( p_deliver_1 )                                  
else begin
  $display("Assertion 4 is violated");
  $fatal;
end

property p_deliver_1;
  @(posedge clk) (inf.D.d_act[0] === Deliver && inf.act_valid === 1'b1) |=> ( q_deliver_1 ) ;
endproperty

sequence q_deliver_1;
  ( inf.id_valid === 1'b0 );
endsequence: q_deliver_1


// Order action
SPEC4_ORDER: assert property ( p_order )                                  
else begin
  $display("Assertion 4 is violated");
  $fatal;
end

property p_order;
  @(posedge clk) (inf.D.d_act[0] === Order && inf.act_valid === 1'b1) |=> ##[1:5] ( q_order ) ;
endproperty

sequence q_order;
  (  (inf.food_valid === 1'b1) or ( (inf.res_valid === 1'b1) ##[2:6] (inf.food_valid === 1'b1) )  );
endsequence: q_order

SPEC4_ORDER_1: assert property ( p_order_1 )                                  
else begin
  $display("Assertion 4 is violated");
  $fatal;
end

property p_order_1;
  @(posedge clk) (inf.D.d_act[0] === Order && inf.act_valid === 1'b1) |=> ( q_order_1 ) ;
endproperty

sequence q_order_1;
  (  (inf.food_valid === 1'b0) && (inf.res_valid === 1'b0)  );
endsequence: q_order_1

SPEC4_ORDER_2: assert property ( p_order_2 )                                  
else begin
  $display("Assertion 4 is violated");
  $fatal;
end

property p_order_2;
  @(posedge clk) (action_r_cs === Order && inf.res_valid === 1'b1) |=> ( q_order_2 ) ;
endproperty

sequence q_order_2;
  ( inf.food_valid === 1'b0 );
endsequence: q_order_2


// Cancel
SPEC4_CANCEL: assert property ( p_cancel )                                  
else begin
  $display("Assertion 4 is violated");
  $fatal;
end

property p_cancel;
  @(posedge clk) (inf.D.d_act[0] === Cancel && inf.act_valid === 1'b1) |=> ##[1:5] ( q_cancel ) ;
endproperty

sequence q_cancel;
  (  (inf.res_valid === 1'b1) ##[2:6] (inf.food_valid === 1'b1) ##[2:6] (inf.id_valid === 1'b1)  );
endsequence: q_cancel

SPEC4_CANCEL_1: assert property ( p_cancel_1 )                                  
else begin
  $display("Assertion 4 is violated");
  $fatal;
end

property p_cancel_1;
  @(posedge clk) (inf.D.d_act[0] === Cancel && inf.act_valid === 1'b1) |=> ( q_cancel_1 ) ;
endproperty

sequence q_cancel_1;
  (  (inf.res_valid === 1'b0) && (inf.food_valid === 1'b0) && (inf.id_valid === 1'b0)  );
endsequence: q_cancel_1

SPEC4_CANCEL_2: assert property ( p_cancel_2 )                                  
else begin
  $display("Assertion 4 is violated");
  $fatal;
end

property p_cancel_2;
  @(posedge clk) (action_r_cs === Cancel && inf.res_valid === 1'b1) |=> ( q_cancel_2 ) ;
endproperty

sequence q_cancel_2;
  (  (inf.food_valid === 1'b0) && (inf.id_valid === 1'b0)  );
endsequence: q_cancel_2

SPEC4_CANCEL_3: assert property ( p_cancel_3 )                                  
else begin
  $display("Assertion 4 is violated");
  $fatal;
end

property p_cancel_3;
  @(posedge clk) (action_r_cs === Cancel && inf.food_valid === 1'b1) |=> ( q_cancel_3 ) ;
endproperty

sequence q_cancel_3;
  ( inf.id_valid === 1'b0 );
endsequence: q_cancel_3


//===========================================================================================================================
// Assertion 5. All input valid signals won’t overlap with each other.
//===========================================================================================================================

logic all_invalid_0;
assign all_invalid_0 = !(inf.id_valid || inf.act_valid || inf.res_valid || inf.cus_valid || inf.food_valid);


SPEC5: assert property ( @(posedge clk) $onehot({inf.id_valid, inf.act_valid, inf.res_valid, inf.cus_valid, inf.food_valid, all_invalid_0}) )                                  
else begin
  $display("Assertion 5 is violated");
  $fatal;
end

//===========================================================================================================================
// Assertion 6. Out_valid can only be high for exactly one cycle.
//===========================================================================================================================

SPEC6: assert property ( @(negedge clk) (inf.out_valid === 1'b1) |=> (inf.out_valid === 1'b0) )
else begin
  $display("Assertion 6 is violated");
  $fatal;
end

//===========================================================================================================================
// Assertion 7. Next operation will be valid 2-10 cycles after out_valid fall.
//===========================================================================================================================

SPEC7: assert property ( @(posedge clk) (inf.out_valid === 1'b1) |-> ##[2:10] (inf.act_valid === 1'b1) )
else begin
  $display("Assertion 7 is violated");
  $fatal;
end

SPEC7_1: assert property ( @(posedge clk) (inf.out_valid === 1'b1) |-> (inf.act_valid === 1'b0) )
else begin
  $display("Assertion 7 is violated");
  $fatal;
end

SPEC7_2: assert property ( @(posedge clk) (inf.out_valid === 1'b1) |=> (inf.act_valid === 1'b0) )
else begin
  $display("Assertion 7 is violated");
  $fatal;
end

//===========================================================================================================================
// Assertion 8. Latency should be less than 1200 cycles for each operation.
//===========================================================================================================================

// Take action
SPEC8_TAKE: assert property ( @(posedge clk) ( action_r_cs === Take && inf.cus_valid === 1'b1) |-> ##[2:1200] (inf.out_valid === 1'b1) )                                  
else begin
  $display("Assertion 8 is violated");
  $fatal;
end

// Deliver action
SPEC8_DELIVER: assert property ( @(posedge clk) ( action_r_cs === Deliver && inf.id_valid === 1'b1) |-> ##[2:1200] (inf.out_valid === 1'b1) )                                  
else begin
  $display("Assertion 8 is violated");
  $fatal;
end

// Order action
SPEC8_ORDER: assert property ( @(posedge clk) ( action_r_cs === Order && inf.food_valid === 1'b1) |-> ##[2:1200] (inf.out_valid === 1'b1) )                                  
else begin
  $display("Assertion 8 is violated");
  $fatal;
end

// Cancel action
SPEC8_CANCEL: assert property ( @(posedge clk) ( action_r_cs === Cancel && inf.id_valid === 1'b1) |-> ##[2:1200] (inf.out_valid === 1'b1) )                                  
else begin
  $display("Assertion 8 is violated");
  $fatal;
end

endmodule