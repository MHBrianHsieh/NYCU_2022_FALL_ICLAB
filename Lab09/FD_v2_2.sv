// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : FD.sv
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                 BRIDGE_AREA       FD_AREA         CYCLE_TIME   PERFORMANCE
// 1.0     2022-11-29 Brian Hsieh                                  13525.142536      48129.682052    2.7          166468.0263876
//                                     revise action to one-hot                      45844.445262    2.7          160297.8870546
//                                     omit some logic                               44713.469275    2.7          157244.2518897
// 2.0                                                             13624.934540      47644.027666    2.6          159299.3017356
// 2.1                                                             13728.052948      48498.912560    2.5          155567.41377
// 2.2                                                             13728.052948      47514.298013    2.5          153105.8774025
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// Food Delivery Platform Simulation
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
`include "Usertype_FD.sv"


module FD(input clk, INF.FD_inf inf);
import usertype::*;

//===========================================================================
// parameter 
//===========================================================================

//===========================================================================
// logic 
//===========================================================================

fd_state           current_state;
fd_state           next_state;

Action             action_reg_cs;
Action             action_reg_ns;

Delivery_man_id    d_man_id_reg_cs;
Delivery_man_id    d_man_id_reg_ns;

Ctm_Info           ctm_info_reg_cs;
Ctm_Info           ctm_info_reg_ns;

food_ID_servings   food_info_reg_cs;
food_ID_servings   food_info_reg_ns;

Restaurant_id      res_id_reg_cs;
Restaurant_id      res_id_reg_ns;

// AXI4 LITE INTERFACE
// logic              c_in_valid_ns;
logic              c_r_wb_ns;
logic      [ 7:0]  c_addr_ns;
logic      [63:0]  c_data_w_ns;

logic              needed_flag_cs;
logic              needed_flag_ns;

logic              cus_valid_flag_cs;
logic              cus_valid_flag_ns;

logic              c_out_valid_flag_cs;
logic              c_out_valid_flag_ns;

logic              id_same_flag;
logic              id_diff_flag_cs;
logic              id_diff_flag_ns;

logic              c_out_valid_cus_valid_flag;
logic              write_twice;
logic              ctm1_res_same    ;
logic              ctm1_food_same   ;
logic              ctm2_res_same    ;
logic              ctm2_food_same   ;
logic              d_man_empty      ;
logic              d_man_ctm2_empty ;
logic              ctm1_wrong_res_id;
logic              ctm2_wrong_res_id;

dram_data          d_man_info_dram_cs;
dram_data          d_man_info_dram_ns;

dram_data          res_info_dram_cs;
dram_data          res_info_dram_ns;

Ctm_Info_dram      ctm_info_reg_dram_format;

D_man_Info         d_man_info_dram2out;
res_info           res_info_dram2out;

Error_Msg          err_msg_ns;

logic              complete_ns;
logic              out_valid_ns;
logic      [63:0]  out_info_ns;


// state register
always_ff @(posedge clk or negedge inf.rst_n) begin
  if(!inf.rst_n) begin
    current_state <= FD_IDLE;
  end
  else begin
    current_state <= next_state;
  end
end


// next state logic
always_comb begin
  case (current_state)
    FD_IDLE: begin
      if (inf.act_valid) begin
        next_state = FD_ACT_VALID;
      end
      else begin
        next_state = FD_IDLE;
      end
    end
    FD_ACT_VALID: begin
      if (inf.res_valid) begin
        next_state = FD_RES_VALID;
      end
      else if (inf.id_valid) begin
        next_state = FD_ID_VALID;
      end
      else if (inf.cus_valid) begin
        next_state = FD_CUS_VALID;
      end
      else if (inf.food_valid) begin
        next_state = FD_FOOD_VALID;
      end
      else begin
        next_state = FD_ACT_VALID;
      end
    end
    FD_ID_VALID: begin
      if (action_reg_cs == Take) begin
        next_state = FD_CUS_VALID;
      end
      else begin
        next_state = FD_DRAM_READ;
      end
    end
    FD_RES_VALID: begin
      if (inf.food_valid) begin
        next_state = FD_FOOD_VALID;
      end
      else begin
        next_state = FD_RES_VALID;
      end
    end
    FD_FOOD_VALID: begin
      if (action_reg_cs == Cancel) begin
        if (inf.id_valid) begin
          next_state = FD_ID_VALID;
        end
        else begin
          next_state = FD_FOOD_VALID;
        end
      end
      else begin
        if (needed_flag_cs) begin
          next_state = FD_ERR_MSG;
        end
        else begin
          next_state = FD_RD_C_IN_VALID;
        end
      end
    end
    FD_CUS_VALID: begin
      if (needed_flag_cs) begin
        next_state = FD_RD_C_IN_VALID;
      end
      else if (c_out_valid_cus_valid_flag) begin
        next_state = FD_RD_C_IN_VALID;
      end
      else begin
        next_state = FD_CUS_VALID;
      end
    end
    FD_RD_C_IN_VALID: begin
      // if () begin
        next_state = FD_DRAM_READ;
      // end
      // else begin
      //   next_state = ;
      // end
    end
    FD_DRAM_READ: begin
      if (inf.C_out_valid) begin
        next_state = FD_ERR_MSG;
      end
      else begin
        next_state = FD_DRAM_READ;
      end
    end
    FD_ERR_MSG: begin
      if (err_msg_ns == No_Err) begin  // dff???
        next_state = FD_EXECUTE;
      end
      else begin
        next_state = FD_FINISH;
      end
    end
    FD_EXECUTE: begin
      // if (inf.) begin
        next_state = FD_WR_C_IN_VALID;
      // end
      // else begin
        // next_state = ;
      // end
    end
    FD_WR_C_IN_VALID: begin
      // if (inf.) begin
        next_state = FD_DRAM_WRITE;
      // end
      // else begin
        // next_state = ;
      // end
    end
    FD_DRAM_WRITE: begin
      if (write_twice) begin
        if (inf.C_out_valid) begin
          next_state = FD_WR_C_IN_VALID;
        end
        else begin
          next_state = FD_DRAM_WRITE;
        end
      end
      else begin
        if (inf.C_out_valid) begin
          next_state = FD_FINISH;
        end
        else begin
          next_state = FD_DRAM_WRITE;
        end
      end
    end
    FD_FINISH: begin
      next_state = B_IDLE;
    end
    default: begin
      next_state = B_IDLE;
    end
  endcase
end



// action_reg
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    action_reg_cs <= No_action;
  end
  else begin
    action_reg_cs <= action_reg_ns;
  end
end

always_comb begin
  if (inf.act_valid) begin
    action_reg_ns = inf.D.d_act[0];
  end
  else begin
    action_reg_ns = action_reg_cs;
  end
end


// d_man_id_reg
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    d_man_id_reg_cs <= 8'd0;
  end
  else begin
    d_man_id_reg_cs <= d_man_id_reg_ns;
  end
end

always_comb begin
  if (inf.id_valid) begin
    d_man_id_reg_ns = inf.D.d_id[0];
  end
  else begin
    d_man_id_reg_ns = d_man_id_reg_cs;
  end
end


// ctm_info_reg
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    ctm_info_reg_cs <= 16'd0;
  end
  else begin
    ctm_info_reg_cs <= ctm_info_reg_ns;
  end
end

always_comb begin
  if (inf.cus_valid) begin
    ctm_info_reg_ns = inf.D.d_ctm_info[0];
  end
  else begin
    ctm_info_reg_ns = ctm_info_reg_cs;
  end
end


// food_info_reg
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    food_info_reg_cs <= 6'd0;
  end
  else begin
    food_info_reg_cs <= food_info_reg_ns;
  end
end

always_comb begin
  if (inf.food_valid) begin
    food_info_reg_ns = inf.D.d_food_ID_ser[0];
  end
  else begin
    food_info_reg_ns = food_info_reg_cs;
  end
end


// res_id_reg
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    res_id_reg_cs <= 8'd0;
  end
  else begin
    res_id_reg_cs <= res_id_reg_ns;
  end
end

always_comb begin
  if (inf.res_valid) begin
    res_id_reg_ns = inf.D.d_res_id[0];
  end
  else begin
    res_id_reg_ns = res_id_reg_cs;
  end
end


// needed_flag
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    needed_flag_cs <= 1'b0;
  end
  else begin
    needed_flag_cs <= needed_flag_ns;
  end
end

always_comb begin
  if (current_state == FD_IDLE) begin
    needed_flag_ns = 1'b0;
  end
  else if (current_state == FD_ACT_VALID && (inf.cus_valid || inf.food_valid)) begin
    needed_flag_ns = 1'b1;
  end
  else begin
    needed_flag_ns = needed_flag_cs;
  end
end


// cus_valid_flag
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    cus_valid_flag_cs <= 1'b0;
  end
  else begin
    cus_valid_flag_cs <= cus_valid_flag_ns;
  end
end

always_comb begin
  if (current_state == FD_CUS_VALID && inf.cus_valid) begin
    cus_valid_flag_ns = 1'b1;
  end
  else begin
    cus_valid_flag_ns = cus_valid_flag_cs;
  end
end


// c_out_valid_flag
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    c_out_valid_flag_cs <= 1'b0;
  end
  else begin
    c_out_valid_flag_cs <= c_out_valid_flag_ns;
  end
end

always_comb begin
  if (current_state == FD_CUS_VALID && inf.C_out_valid) begin
    c_out_valid_flag_ns = 1'b1;
  end
  else begin
    c_out_valid_flag_ns = 1'b0;
  end
end


// id_diff_flag
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    id_diff_flag_cs <= 1'b0;
  end
  else begin
    id_diff_flag_cs <= id_diff_flag_ns;
  end
end

always_comb begin
  if (current_state == FD_IDLE) begin
    id_diff_flag_ns = 1'b0;
  end
  else if (current_state == FD_WR_C_IN_VALID) begin
    if ( !id_same_flag && !id_diff_flag_cs ) begin
      id_diff_flag_ns = 1'b1;
    end
    else begin
      id_diff_flag_ns = 1'b0;
    end
  end
  else begin
    id_diff_flag_ns = id_diff_flag_cs;
  end
end


// C_in_valid

// always_ff @(posedge clk or negedge inf.rst_n) begin
//   if (!inf.rst_n) begin
//     inf.C_in_valid <= 1'b0;
//   end
//   else begin
//     inf.C_in_valid <= c_in_valid_ns;
//   end
// end

always_comb begin
  inf.C_in_valid = (current_state == FD_ID_VALID) || (current_state == FD_RD_C_IN_VALID) || (current_state == FD_WR_C_IN_VALID); // (current_state[1:0] == 2'b10)
end


// C_r_wb
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    inf.C_r_wb <= 1'b0;
  end
  else begin
    inf.C_r_wb <= c_r_wb_ns;
  end
end

always_comb begin
  c_r_wb_ns = (current_state == FD_ID_VALID) || (current_state == FD_RD_C_IN_VALID); // ({current_state[3], current_state[1:0]} == 3'b010)
end


// C_addr
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    inf.C_addr <= 8'd0;
  end
  else begin
    inf.C_addr <= c_addr_ns;
  end
end

// always_comb begin
//   if (current_state == FD_WR_C_IN_VALID && write_twice) begin
//     c_addr_ns = ctm_info_reg_cs.res_ID;
//   end
//   else if (current_state == FD_EXECUTE) begin
//     c_addr_ns = (action_reg_cs == Order) ? res_id_reg_cs : d_man_id_reg_cs;
//   end
//   else if ( current_state == FD_FOOD_VALID && (action_reg_cs == Order) ) begin
//     c_addr_ns = res_id_reg_cs;
//   end
//   else if (current_state == FD_CUS_VALID && (needed_flag_cs && inf.C_out_valid) ) begin
//     c_addr_ns = ctm_info_reg_cs.res_ID;
//   end
//   else if (current_state == FD_CUS_VALID && (!needed_flag_cs && c_out_valid_cus_valid_flag) ) begin
//     c_addr_ns = ctm_info_reg_cs.res_ID;
//   end
//   else if (inf.id_valid) begin
//     c_addr_ns = inf.D.d_id[0];
//   end
//   else begin
//     c_addr_ns = inf.C_addr;
//   end
// end



always_comb begin
  if (current_state == FD_WR_C_IN_VALID) begin
    c_addr_ns = (id_diff_flag_cs) ? ctm_info_reg_cs.res_ID : ( (action_reg_cs == Order) ? res_id_reg_cs : d_man_id_reg_cs );
  end
  else if (current_state == FD_RD_C_IN_VALID) begin
    c_addr_ns = (action_reg_cs == Order) ? res_id_reg_cs : ctm_info_reg_cs.res_ID;
  end
  else if (current_state == FD_ID_VALID) begin
    c_addr_ns = d_man_id_reg_cs;
  end
  else begin
    c_addr_ns = inf.C_addr;
  end
end


// ctm_info_reg_dram_format
always_comb begin
  ctm_info_reg_dram_format = {ctm_info_reg_cs.res_ID[1:0], ctm_info_reg_cs.food_ID, ctm_info_reg_cs.ser_food, ctm_info_reg_cs.ctm_status, ctm_info_reg_cs.res_ID[7:2]};
end


// d_man_info_dram2out
always_comb begin
  d_man_info_dram2out = {d_man_info_dram_cs.d_man_info.ctm_info1[7:0], d_man_info_dram_cs.d_man_info.ctm_info1[15:8],
                         d_man_info_dram_cs.d_man_info.ctm_info2[7:0], d_man_info_dram_cs.d_man_info.ctm_info2[15:8]};
end

// res_info_dram2out
always_comb begin
  res_info_dram2out = {res_info_dram_cs.res_info.limit_num_orders, res_info_dram_cs.res_info.ser_FOOD1,
                       res_info_dram_cs.res_info.ser_FOOD2,        res_info_dram_cs.res_info.ser_FOOD3};
end


// d_man_info_dram
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    d_man_info_dram_cs <= 64'd0;
  end
  else begin
    d_man_info_dram_cs <= d_man_info_dram_ns;
  end
end

always_comb begin
  if (action_reg_cs[0]) begin  // TAKE
    if (current_state == FD_EXECUTE) begin
      if (ctm_info_reg_cs.ctm_status > d_man_info_dram_cs.d_man_info.ctm_info1.ctm_status) begin
        d_man_info_dram_ns = {d_man_info_dram_cs.d_man_info.ctm_info1, ctm_info_reg_dram_format, d_man_info_dram_cs.res_info};
      end
      else begin
        d_man_info_dram_ns = {ctm_info_reg_dram_format, d_man_info_dram_cs.d_man_info.ctm_info1, d_man_info_dram_cs.res_info};
      end
    end
    else if (current_state == FD_CUS_VALID) begin
      if (inf.C_out_valid) begin
        d_man_info_dram_ns = inf.C_data_r;
      end
      else begin
        d_man_info_dram_ns = d_man_info_dram_cs;
      end
    end
    else if (current_state == FD_WR_C_IN_VALID) begin   // SAME ID CORNER CASE
      if (id_same_flag) begin
        d_man_info_dram_ns = {d_man_info_dram_cs.d_man_info, res_info_dram_cs.res_info};
      end
      else begin
        d_man_info_dram_ns = d_man_info_dram_cs;
      end
    end
    else begin
      d_man_info_dram_ns = d_man_info_dram_cs;
    end
  end
  else if (action_reg_cs[1]) begin  // DELIVER
    if (current_state == FD_DRAM_READ) begin
      if (inf.C_out_valid) begin
        d_man_info_dram_ns = inf.C_data_r;
      end
      else begin
        d_man_info_dram_ns = d_man_info_dram_cs;
      end
    end
    else if (current_state == FD_EXECUTE) begin
      d_man_info_dram_ns = {16'd0, d_man_info_dram_cs.d_man_info.ctm_info2, d_man_info_dram_cs.res_info};
    end
    else begin
      d_man_info_dram_ns = d_man_info_dram_cs;
    end
  end
  else if (action_reg_cs[3]) begin  // CANCEL
    if (current_state == FD_EXECUTE) begin
      if (ctm1_res_same && ctm1_food_same && ctm2_res_same && ctm2_food_same) begin
        d_man_info_dram_ns = {32'd0, d_man_info_dram_cs.res_info};
      end
      else if (ctm1_res_same && ctm1_food_same) begin
        d_man_info_dram_ns = {16'd0, d_man_info_dram_cs.d_man_info.ctm_info2, d_man_info_dram_cs.res_info};
      end
      else begin
        d_man_info_dram_ns = {16'd0, d_man_info_dram_cs.d_man_info.ctm_info1, d_man_info_dram_cs.res_info};
      end
    end
    else if (current_state == FD_DRAM_READ) begin
      if (inf.C_out_valid) begin
        d_man_info_dram_ns = inf.C_data_r;
      end
      else begin
        d_man_info_dram_ns = d_man_info_dram_cs;
      end
    end
    else begin
      d_man_info_dram_ns = d_man_info_dram_cs;
    end
  end
  else begin
    d_man_info_dram_ns = d_man_info_dram_cs;
  end
end




// res_info_dram
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    res_info_dram_cs <= 64'd0;
  end
  else begin
    res_info_dram_cs <= res_info_dram_ns;
  end
end

always_comb begin
  case (action_reg_cs)
    Take: begin  // TAKE
      case (current_state)
        FD_EXECUTE: begin
          case (ctm_info_reg_cs.food_ID)
            No_food: begin
              res_info_dram_ns = res_info_dram_cs;
            end
            FOOD1: begin
              res_info_dram_ns = {res_info_dram_cs.d_man_info, res_info_dram_cs.res_info.ser_FOOD3, res_info_dram_cs.res_info.ser_FOOD2, 
                                  (res_info_dram_cs.res_info.ser_FOOD1 - ctm_info_reg_cs.ser_food), res_info_dram_cs.res_info.limit_num_orders};
            end
            FOOD2: begin
              res_info_dram_ns = {res_info_dram_cs.d_man_info, res_info_dram_cs.res_info.ser_FOOD3, (res_info_dram_cs.res_info.ser_FOOD2 - ctm_info_reg_cs.ser_food), 
                                  res_info_dram_cs.res_info.ser_FOOD1, res_info_dram_cs.res_info.limit_num_orders};
            end
            FOOD3: begin
              res_info_dram_ns = {res_info_dram_cs.d_man_info, (res_info_dram_cs.res_info.ser_FOOD3 - ctm_info_reg_cs.ser_food), 
                                  res_info_dram_cs.res_info.ser_FOOD2, res_info_dram_cs.res_info.ser_FOOD1, res_info_dram_cs.res_info.limit_num_orders};
            end
          endcase
        end
        FD_DRAM_READ: begin
          if (inf.C_out_valid) begin
            res_info_dram_ns = inf.C_data_r;
          end
          else begin
            res_info_dram_ns = res_info_dram_cs;
          end
        end
        FD_WR_C_IN_VALID: begin   // SAME ID CORNER CASE
          if (id_same_flag) begin
            res_info_dram_ns = {d_man_info_dram_cs.d_man_info, res_info_dram_cs.res_info};
          end
          else begin
            res_info_dram_ns = res_info_dram_cs;
          end
        end
        default: begin
          res_info_dram_ns = res_info_dram_cs;
        end
      endcase
    end
    Order: begin  // ORDER
      case (current_state)
        FD_EXECUTE: begin
          case (food_info_reg_cs.d_food_ID)
            No_food: begin
              res_info_dram_ns = res_info_dram_cs;
            end
            FOOD1: begin
              res_info_dram_ns = {res_info_dram_cs.d_man_info, res_info_dram_cs.res_info.ser_FOOD3, res_info_dram_cs.res_info.ser_FOOD2, 
                                  (res_info_dram_cs.res_info.ser_FOOD1 + food_info_reg_cs.d_ser_food), res_info_dram_cs.res_info.limit_num_orders};
            end
            FOOD2: begin
              res_info_dram_ns = {res_info_dram_cs.d_man_info, res_info_dram_cs.res_info.ser_FOOD3, (res_info_dram_cs.res_info.ser_FOOD2 + food_info_reg_cs.d_ser_food), 
                                  res_info_dram_cs.res_info.ser_FOOD1, res_info_dram_cs.res_info.limit_num_orders};
            end
            FOOD3: begin
              res_info_dram_ns = {res_info_dram_cs.d_man_info, (res_info_dram_cs.res_info.ser_FOOD3 + food_info_reg_cs.d_ser_food), 
                                  res_info_dram_cs.res_info.ser_FOOD2, res_info_dram_cs.res_info.ser_FOOD1, res_info_dram_cs.res_info.limit_num_orders};
            end
          endcase
        end
        FD_DRAM_READ: begin
          if (inf.C_out_valid) begin
            res_info_dram_ns = inf.C_data_r;
          end
          else begin
            res_info_dram_ns = res_info_dram_cs;
          end
        end
        default: begin
          res_info_dram_ns = res_info_dram_cs;
        end
      endcase
    end
    default: begin
      res_info_dram_ns = res_info_dram_cs;
    end
  endcase
end

// logic addr_debug_flag;
// always_comb begin
//   if (inf.C_addr == 8'd95) begin
//     addr_debug_flag = 1;
//   end
//   else begin
//     addr_debug_flag = 0;
//   end
// end

// c_data_w
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    inf.C_data_w <= 64'd0;
  end
  else begin
    inf.C_data_w <= c_data_w_ns;
  end
end

always_comb begin
  if (current_state == FD_WR_C_IN_VALID) begin
    if (action_reg_cs[0]) begin  //TAKE
      if (id_same_flag) begin
        c_data_w_ns = {d_man_info_dram_cs.d_man_info, res_info_dram_cs.res_info};
      end
      else if (id_diff_flag_cs) begin
        c_data_w_ns = res_info_dram_cs;
      end
      else begin
        c_data_w_ns = d_man_info_dram_cs;
      end
    end
    // else if (action_reg_cs == Deliver) begin
    //   c_data_w_ns = d_man_info_dram_cs;
    // end
    else if (action_reg_cs[2]) begin  // ORDER
      c_data_w_ns = res_info_dram_cs;
    end
    else begin
      c_data_w_ns = d_man_info_dram_cs;
    end
  end
  else begin
    c_data_w_ns = inf.C_data_w;
  end
end


// err_msg
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    inf.err_msg <= 4'd0;
  end
  else begin
    inf.err_msg <= err_msg_ns;
  end
end

always_comb begin
  if (current_state == FD_ERR_MSG) begin
    if (action_reg_cs[3]) begin  // CANCEL
      if (d_man_empty) begin
        err_msg_ns = Wrong_cancel;
      end
      else if (d_man_ctm2_empty && ctm1_wrong_res_id) begin
        err_msg_ns = Wrong_res_ID;
      end
      else if (ctm1_wrong_res_id && ctm2_wrong_res_id) begin
        err_msg_ns = Wrong_res_ID;
      end
      else if ( (!ctm1_wrong_res_id) && (!d_man_ctm2_empty) && (!ctm2_wrong_res_id) ) begin
        err_msg_ns = (!ctm1_food_same && !ctm2_food_same) ? Wrong_food_ID : No_Err;
      end
      else if ( !ctm1_wrong_res_id && !ctm1_food_same ) begin
        err_msg_ns = Wrong_food_ID;
      end
      else if ( (!d_man_ctm2_empty) && (!ctm2_wrong_res_id) && !ctm2_food_same ) begin
        err_msg_ns = Wrong_food_ID;
      end
      else begin
        err_msg_ns = No_Err;
      end
    end
    else if (action_reg_cs[0]) begin  //TAKE
      if (!d_man_ctm2_empty) begin
        err_msg_ns = D_man_busy;
      end
      else if (ctm_info_reg_cs.food_ID == FOOD1) begin
        if (ctm_info_reg_cs.ser_food > res_info_dram_cs.res_info.ser_FOOD1) begin
          err_msg_ns = No_Food;
        end
        else begin
          err_msg_ns = No_Err;
        end
      end
      else if (ctm_info_reg_cs.food_ID == FOOD2) begin
        if (ctm_info_reg_cs.ser_food > res_info_dram_cs.res_info.ser_FOOD2) begin
          err_msg_ns = No_Food;
        end
        else begin
          err_msg_ns = No_Err;
        end
      end
      else if (ctm_info_reg_cs.food_ID == FOOD3) begin
        if (ctm_info_reg_cs.ser_food > res_info_dram_cs.res_info.ser_FOOD3) begin
          err_msg_ns = No_Food;
        end
        else begin
          err_msg_ns = No_Err;
        end
      end
      else begin
        err_msg_ns = No_Err;
      end
    end
    else if (action_reg_cs[2]) begin  // ORDER
      if (res_info_dram_cs.res_info.limit_num_orders - food_info_reg_cs.d_ser_food < res_info_dram_cs.res_info.ser_FOOD1 + res_info_dram_cs.res_info.ser_FOOD2 + res_info_dram_cs.res_info.ser_FOOD3) begin
        err_msg_ns = Res_busy;
      end
      else begin
        err_msg_ns = No_Err;
      end
    end
    else begin
      if (d_man_empty) begin
        err_msg_ns = No_customers;
      end
      else begin
        err_msg_ns = No_Err;
      end
    end
  end
  // else if (current_state == FD_IDLE) begin                    // omit???
  //   err_msg_ns = No_Err;
  // end
  else begin
    err_msg_ns = inf.err_msg;
  end
end


// complete
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    inf.complete <= 1'b0;
  end
  else begin
    inf.complete <= complete_ns;
  end
end

always_comb begin
  if (current_state == FD_ERR_MSG) begin
    if (err_msg_ns == No_Err) begin            // dff???
      complete_ns = 1'b1;
    end
    else begin
      complete_ns = 1'b0;
    end
  end
  else begin
    complete_ns = inf.complete;
  end
end


// out_valid
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    inf.out_valid <= 1'b0;
  end
  else begin
    inf.out_valid <= out_valid_ns;
  end
end

always_comb begin
  if (current_state == FD_FINISH) begin
    out_valid_ns = 1'b1;
  end
  else begin
    out_valid_ns = 1'b0;
  end
end


// out_info
always_ff @(posedge clk or negedge inf.rst_n) begin
  if (!inf.rst_n) begin
    inf.out_info <= 64'd0;
  end
  else begin
    inf.out_info <= out_info_ns;
  end
end

always_comb begin
  if (current_state == FD_FINISH) begin
    if (inf.err_msg != No_Err) begin
      out_info_ns = 64'd0;
    end
    else if (action_reg_cs[0]) begin  // TAKE
      out_info_ns = {d_man_info_dram2out, res_info_dram2out};
    end
    else if (action_reg_cs[2]) begin  // ORDER
      out_info_ns = {32'd0, res_info_dram2out};
    end
    else begin
      out_info_ns = {d_man_info_dram2out, 32'd0};
    end
  end
  else begin
    out_info_ns = 64'd0;
  end
end





// control signals

assign c_out_valid_cus_valid_flag = (c_out_valid_flag_cs || inf.C_out_valid) && (cus_valid_flag_cs || inf.cus_valid);
assign id_same_flag      = d_man_id_reg_cs == ctm_info_reg_cs.res_ID;
assign write_twice       = action_reg_cs[0] && id_diff_flag_cs;

assign ctm1_res_same     = {d_man_info_dram_cs.d_man_info.ctm_info1.res_ID_7_2, d_man_info_dram_cs.d_man_info.ctm_info1.res_ID_1_0} == res_id_reg_cs;
assign ctm1_food_same    = d_man_info_dram_cs.d_man_info.ctm_info1.food_ID == food_info_reg_cs.d_food_ID;
assign ctm2_res_same     = {d_man_info_dram_cs.d_man_info.ctm_info2.res_ID_7_2, d_man_info_dram_cs.d_man_info.ctm_info2.res_ID_1_0} == res_id_reg_cs;
assign ctm2_food_same    = d_man_info_dram_cs.d_man_info.ctm_info2.food_ID == food_info_reg_cs.d_food_ID;

assign d_man_empty       = d_man_info_dram_cs.d_man_info == 32'd0;
assign d_man_ctm2_empty  = d_man_info_dram_cs.d_man_info.ctm_info2 == 16'd0;

assign ctm1_wrong_res_id = res_id_reg_cs != {d_man_info_dram_cs.d_man_info.ctm_info1.res_ID_7_2, d_man_info_dram_cs.d_man_info.ctm_info1.res_ID_1_0};
assign ctm2_wrong_res_id = res_id_reg_cs != {d_man_info_dram_cs.d_man_info.ctm_info2.res_ID_7_2, d_man_info_dram_cs.d_man_info.ctm_info2.res_ID_1_0};


endmodule