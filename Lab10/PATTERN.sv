// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : PATTERN.sv
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                 
// 1.0     2022-12-04 Brian Hsieh      
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// PATTERN for FD.sv and bridge.sv
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

`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_FD.sv"
`define CYCLE_TIME 1.0
`define PATTERN_NUM 550

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

real CYCLE = `CYCLE_TIME;
parameter PAT_NUM = `PATTERN_NUM;

integer seed = 1212;
integer latency = 0;
integer pat;
integer delay_num = 0;
integer gap_num = 0;
integer needed_prob;

parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter START_ADDR = 17'h10000;

logic [7:0] golden_DRAM [ ((START_ADDR+256*8)-1) : START_ADDR ];

Action           current_action;
Delivery_man_id  current_d_man_id;
Delivery_man_id  next_d_man_id;
Ctm_Info         current_ctm_info;
Restaurant_id    current_res_id;
food_ID_servings current_food_info;
reg              needed_flag;

dram_data        dram_info;

Ctm_Info_dram    ctm_info_reg_dram_format;

D_man_Info       d_man_info_dram2out;
res_info         res_info_dram2out;

logic            ctm1_res_same;
logic            ctm1_food_same;
logic            ctm2_res_same;
logic            ctm2_food_same;

// golden answer
logic            golden_complete;
Error_Msg        golden_err_msg;
OUT_INFO         golden_out_info;


initial begin
  $readmemh(DRAM_p_r, golden_DRAM);
	reset_task;
  for (pat=0; pat<PAT_NUM; pat=pat+1) begin
    input_task;
    cal_ans_task;
    wait_out_valid_task;
    check_ans_task;
    // $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %4d,\033[m \033[0;36mAction: %s,\033[m \033[0;31mErr_Msg: %s\033[m",
    // 	       pat, latency, current_action === Take ? ( needed_flag ? "Take (if needed)" : "Take") : ( current_action === Deliver ? "Deliver" : (current_action === Order ? ( needed_flag ? "Order (if needed)" : "Order") : "Cancel") ),
    //          inf.err_msg === No_Err ? "No_Err" : ( inf.err_msg === No_Food ? "No_Food" : (inf.err_msg === D_man_busy ? "D_man_busy" : (inf.err_msg === No_customers ? "No_customers" : (inf.err_msg === Res_busy ? "Res_busy" : (inf.err_msg === Wrong_cancel ? "Wrong_cancel" : (inf.err_msg === Wrong_res_ID ? "Wrong_res_ID" : "Wrong_food_ID") ) ) ) ) ) );
  end
  @(negedge clk);
  // YOU_PASS_task;
  $finish;
end


class random_input;
  rand Action           action_i;
  rand Delivery_man_id  d_man_id_i;
  rand Ctm_Info         ctm_info_i;
  rand Restaurant_id    res_id_i;
  rand food_ID_servings food_info_i;
  constraint limit {
    action_i dist {Take:=1, Deliver:=1, Order:=2, Cancel:=1};
    d_man_id_i            inside {[0:255]};
    ctm_info_i.ctm_status inside {Normal, VIP};
    ctm_info_i.res_ID     inside {[45:75]};
    ctm_info_i.food_ID    inside {FOOD1, FOOD2, FOOD3};
    ctm_info_i.ser_food   inside {15};
    res_id_i              inside {[65:85]};
    food_info_i.d_food_ID inside {FOOD1, FOOD2, FOOD3};
    if (action_i == Cancel)
      food_info_i.d_ser_food inside {0};
    else
    	food_info_i.d_ser_food inside {15};
  }
endclass

random_input random_input_inst = new();



task reset_task; begin
  inf.rst_n = 'b1;
  inf.id_valid = 'b0;
  inf.act_valid = 'b0;
  inf.cus_valid = 'b0;
  inf.food_valid = 'b0;
  inf.res_valid = 'b0;
  inf.D = 'dx;
  current_action = No_action;
  current_d_man_id = 'd0;
  next_d_man_id = 'd0;
  current_res_id = 'd0;
  current_food_info = 'd0;
  needed_flag = 'b0;
  dram_info = 'd0;
  golden_complete = 'b0;
  golden_err_msg = No_Err;
  golden_out_info = 'd0;

  #CYCLE; inf.rst_n = 'b0;
  #CYCLE; inf.rst_n = 'b1;
end endtask


task id_valid_task; begin
  current_d_man_id = (pat > 272) ? random_input_inst.d_man_id_i : ((pat < 20) ? current_d_man_id : next_d_man_id);
  inf.id_valid = 'b1;
  inf.D = 'd0;
  inf.D.d_id[0] = (pat > 272) ? random_input_inst.d_man_id_i : ((pat < 20) ? current_d_man_id : next_d_man_id);
  next_d_man_id = (pat < 20) ? next_d_man_id : next_d_man_id + 1;
  @(negedge clk);
  inf.id_valid = 'b0;
  inf.D = 'bx;
end endtask


task cus_valid_task; begin
  current_ctm_info = random_input_inst.ctm_info_i;
  inf.cus_valid = 'b1;
  inf.D = 'd0;
  inf.D.d_ctm_info[0] = random_input_inst.ctm_info_i;
  @(negedge clk);
  inf.cus_valid = 'b0;
  inf.D = 'bx;
end endtask


task res_valid_task; begin
  current_res_id = random_input_inst.res_id_i;
  inf.res_valid = 'b1;
  inf.D = 'd0;
  inf.D.d_res_id[0] = random_input_inst.res_id_i;
  @(negedge clk);
  inf.res_valid = 'b0;
  inf.D = 'bx;
end endtask


task food_valid_task; begin
  current_food_info = random_input_inst.food_info_i;
  inf.food_valid = 'b1;
  inf.D = 'd0;
  inf.D.d_food_ID_ser[0] = random_input_inst.food_info_i;
  @(negedge clk);
  inf.food_valid = 'b0;
  inf.D = 'bx;
end endtask



task input_task; begin
  // delay_num = $urandom_range(2, 10);
  delay_num = 2;
  // gap_num = $urandom_range(1, 5);
  gap_num = 1;
  repeat(delay_num) @(negedge clk);

  random_input_inst.randomize();

  // act_valid
  // first 20: Cancel (Wrong_food_ID)
  if (pat < 20) begin
    random_input_inst.action_i = Cancel;
    current_d_man_id = next_d_man_id;
    next_d_man_id = (pat == 0) ? 1 : ( (pat % 'd2 == 0) ? 2 : 3);
    random_input_inst.res_id_i = (pat < 2) ? 0 : ( (pat % 'd2 == 0) ? 4 : 3);
    random_input_inst.food_info_i.d_food_ID = (pat % 'd2 == 0) ? FOOD1 : FOOD3;
  end
  // 20 ~ 39: Deliver (No_customers)
  else if (pat < 40) begin
    random_input_inst.action_i = Deliver;
  end
  // 40 ~ 60: Cancel (Wrong_cancel)
  else if (pat < 61) begin
    random_input_inst.action_i = Cancel;
  end
  // 61: Cancel (No_Err)
  else if (pat == 61) begin
    random_input_inst.action_i = Cancel;
    random_input_inst.res_id_i = 'd94;
    random_input_inst.food_info_i.d_food_ID = FOOD3;
  end
  // 62: Cancel (No_Err)
  else if (pat == 62) begin
    random_input_inst.action_i = Cancel;
    random_input_inst.res_id_i = 'd176;
    random_input_inst.food_info_i.d_food_ID = FOOD3;
  end
  // 63: Cancel (No_Err)
  else if (pat == 63) begin
    random_input_inst.action_i = Cancel;
    random_input_inst.res_id_i = 'd167;
    random_input_inst.food_info_i.d_food_ID = FOOD1;
  end
  // 64 ~ 83: Take
  // else if (pat < 84) begin
  //   random_input_inst.action_i = Take;
  // end
  // 64 ~ 272: Cancel / Deliver
  else if (pat < 273) begin
    // random_input_inst.action_i = ($random(seed) % 'd2 == 0) ? Cancel : Deliver;
    random_input_inst.action_i = Take;
  end
  needed_prob = (pat > 63 && pat < 273) ? 0 : $random(seed) % 'd2;
  needed_flag = (current_action == random_input_inst.action_i && (current_action == Take || current_action == Order) && needed_prob == 1);
  current_action = random_input_inst.action_i;
  inf.act_valid = 'b1;
  inf.D = 'd0;
  inf.D.d_act[0] = random_input_inst.action_i;
  @(negedge clk);
  inf.act_valid = 'b0;
  inf.D = 'bx;
  repeat(gap_num) @(negedge clk);

  case(current_action)
    Take: begin
    	// id_valid
      if (!needed_flag) begin
        id_valid_task;
        repeat(gap_num) @(negedge clk);
      end

      // cus_valid
      cus_valid_task;
    end
    Deliver: begin
      // id_valid
      id_valid_task;
    end
    Order: begin
      // res_valid
      if (!needed_flag) begin
        res_valid_task;
        repeat(gap_num) @(negedge clk);
      end

      // food_valid
      food_valid_task;
    end
    Cancel: begin
      // res_valid
      res_valid_task;
      repeat(gap_num) @(negedge clk);

      // food_valid
      food_valid_task;
      repeat(gap_num) @(negedge clk);

      // id_valid
      id_valid_task;
    end
  endcase
end endtask


// ctm_info_reg_dram_format
task ctm_info_2dram_task; begin
  ctm_info_reg_dram_format = {current_ctm_info.res_ID[1:0], current_ctm_info.food_ID, current_ctm_info.ser_food, current_ctm_info.ctm_status, current_ctm_info.res_ID[7:2]};
end endtask


// d_man_info_dram2out
task d_man_info_dram2out_task; begin
  d_man_info_dram2out = {dram_info.d_man_info.ctm_info1[7:0], dram_info.d_man_info.ctm_info1[15:8],
                         dram_info.d_man_info.ctm_info2[7:0], dram_info.d_man_info.ctm_info2[15:8]};
end endtask

// res_info_dram2out
task res_info_dram2out_task; begin
  res_info_dram2out = {dram_info.res_info.limit_num_orders, dram_info.res_info.ser_FOOD1,
                       dram_info.res_info.ser_FOOD2,        dram_info.res_info.ser_FOOD3};
end endtask


// cancel_id_check_task
task cancel_id_check_task; begin
  ctm1_res_same  = {dram_info.d_man_info.ctm_info1.res_ID_7_2, dram_info.d_man_info.ctm_info1.res_ID_1_0} == current_res_id;
  ctm1_food_same = dram_info.d_man_info.ctm_info1.food_ID == current_food_info.d_food_ID;
  ctm2_res_same  = {dram_info.d_man_info.ctm_info2.res_ID_7_2, dram_info.d_man_info.ctm_info2.res_ID_1_0} == current_res_id;
  ctm2_food_same = dram_info.d_man_info.ctm_info2.food_ID == current_food_info.d_food_ID;
end endtask


task cal_ans_task; begin
  case (current_action)
    Take: begin
      // READ DRAM
      dram_info.d_man_info = {golden_DRAM[START_ADDR+7+current_d_man_id       *8], golden_DRAM[START_ADDR+6+current_d_man_id       *8],
                              golden_DRAM[START_ADDR+5+current_d_man_id       *8], golden_DRAM[START_ADDR+4+current_d_man_id       *8]};
      dram_info.res_info   = {golden_DRAM[START_ADDR+3+current_ctm_info.res_ID*8], golden_DRAM[START_ADDR+2+current_ctm_info.res_ID*8],
                              golden_DRAM[START_ADDR+1+current_ctm_info.res_ID*8], golden_DRAM[START_ADDR+0+current_ctm_info.res_ID*8]};

      // ERR_MSG
      if (dram_info.d_man_info.ctm_info2 != 16'd0) begin
        golden_err_msg = D_man_busy;
      end
      else if (current_ctm_info.food_ID == FOOD1) begin
        if (current_ctm_info.ser_food > dram_info.res_info.ser_FOOD1) begin
          golden_err_msg = No_Food;
        end
        else begin
          golden_err_msg = No_Err;
        end
      end
      else if (current_ctm_info.food_ID == FOOD2) begin
        if (current_ctm_info.ser_food > dram_info.res_info.ser_FOOD2) begin
          golden_err_msg = No_Food;
        end
        else begin
          golden_err_msg = No_Err;
        end
      end
      else if (current_ctm_info.food_ID == FOOD3) begin
        if (current_ctm_info.ser_food > dram_info.res_info.ser_FOOD3) begin
          golden_err_msg = No_Food;
        end
        else begin
          golden_err_msg = No_Err;
        end
      end
      else begin
        golden_err_msg = No_Err;
      end

      // EXECUTE
      if (golden_err_msg == No_Err) begin
        ctm_info_2dram_task;
        // d_man_info
        if (current_ctm_info.ctm_status > dram_info.d_man_info.ctm_info1.ctm_status) begin
          dram_info.d_man_info = {dram_info.d_man_info.ctm_info1, ctm_info_reg_dram_format};
        end
        else begin
          dram_info.d_man_info = {ctm_info_reg_dram_format, dram_info.d_man_info.ctm_info1};
        end
        // res_info
        case (current_ctm_info.food_ID)
          FOOD1: begin
            dram_info.res_info.ser_FOOD1 = dram_info.res_info.ser_FOOD1 - current_ctm_info.ser_food;
          end
          FOOD2: begin
            dram_info.res_info.ser_FOOD2 = dram_info.res_info.ser_FOOD2 - current_ctm_info.ser_food;
          end
          FOOD3: begin
            dram_info.res_info.ser_FOOD3 = dram_info.res_info.ser_FOOD3 - current_ctm_info.ser_food;
          end
        endcase
        // golden_complete
        golden_complete = 1'b1;
        // golden_out_info
        d_man_info_dram2out_task;
        res_info_dram2out_task;
        golden_out_info = {d_man_info_dram2out, res_info_dram2out};
        // WRITE DRAM
        {golden_DRAM[START_ADDR+7+current_d_man_id       *8], golden_DRAM[START_ADDR+6+current_d_man_id       *8], 
         golden_DRAM[START_ADDR+5+current_d_man_id       *8], golden_DRAM[START_ADDR+4+current_d_man_id       *8]} = dram_info.d_man_info;
        {golden_DRAM[START_ADDR+3+current_ctm_info.res_ID*8], golden_DRAM[START_ADDR+2+current_ctm_info.res_ID*8],
         golden_DRAM[START_ADDR+1+current_ctm_info.res_ID*8], golden_DRAM[START_ADDR+0+current_ctm_info.res_ID*8]} = dram_info.res_info;
      end
      else begin
        // golden_complete
        golden_complete = 1'b0;
        // golden_out_info
        golden_out_info = 64'd0;
      end
    end
    Deliver: begin
      // READ DRAM
      dram_info.d_man_info = {golden_DRAM[START_ADDR+7+current_d_man_id*8], golden_DRAM[START_ADDR+6+current_d_man_id*8],
                              golden_DRAM[START_ADDR+5+current_d_man_id*8], golden_DRAM[START_ADDR+4+current_d_man_id*8]};

      // ERR_MSG
      if (dram_info.d_man_info == 32'd0) begin
        golden_err_msg = No_customers;
      end
      else begin
        golden_err_msg = No_Err;
      end

      // EXECUTE
      if (golden_err_msg == No_Err) begin
        // d_man_info
        dram_info.d_man_info = {16'd0, dram_info.d_man_info.ctm_info2};
        // golden_complete
        golden_complete = 1'b1;
        // golden_out_info
        d_man_info_dram2out_task;
        golden_out_info = {d_man_info_dram2out, 32'd0};
        // WRITE DRAM
        {golden_DRAM[START_ADDR+7+current_d_man_id*8], golden_DRAM[START_ADDR+6+current_d_man_id*8], 
         golden_DRAM[START_ADDR+5+current_d_man_id*8], golden_DRAM[START_ADDR+4+current_d_man_id*8]} = dram_info.d_man_info;
      end
      else begin
        // golden_complete
        golden_complete = 1'b0;
        // golden_out_info
        golden_out_info = 64'd0;
      end
    end
    Order: begin
      // READ DRAM
      dram_info.res_info = {golden_DRAM[START_ADDR+3+current_res_id*8], golden_DRAM[START_ADDR+2+current_res_id*8],
                            golden_DRAM[START_ADDR+1+current_res_id*8], golden_DRAM[START_ADDR+0+current_res_id*8]};

      // ERR_MSG
      if (dram_info.res_info.limit_num_orders - current_food_info.d_ser_food < dram_info.res_info.ser_FOOD1 + dram_info.res_info.ser_FOOD2 + dram_info.res_info.ser_FOOD3) begin
        golden_err_msg = Res_busy;
      end
      else begin
        golden_err_msg = No_Err;
      end

      // EXECUTE
      if (golden_err_msg == No_Err) begin
        // res_info
        case (current_food_info.d_food_ID)
          FOOD1: begin
            dram_info.res_info.ser_FOOD1 = dram_info.res_info.ser_FOOD1 + current_food_info.d_ser_food;
          end
          FOOD2: begin
            dram_info.res_info.ser_FOOD2 = dram_info.res_info.ser_FOOD2 + current_food_info.d_ser_food;
          end
          FOOD3: begin
            dram_info.res_info.ser_FOOD3 = dram_info.res_info.ser_FOOD3 + current_food_info.d_ser_food;
          end
        endcase
        // golden_complete
        golden_complete = 1'b1;
        // golden_out_info
        res_info_dram2out_task;
        golden_out_info = {32'd0, res_info_dram2out};
        // WRITE DRAM
        {golden_DRAM[START_ADDR+3+current_res_id*8], golden_DRAM[START_ADDR+2+current_res_id*8],
         golden_DRAM[START_ADDR+1+current_res_id*8], golden_DRAM[START_ADDR+0+current_res_id*8]} = dram_info.res_info;
      end
      else begin
        // golden_complete
        golden_complete = 1'b0;
        // golden_out_info
        golden_out_info = 64'd0;
      end
    end
    Cancel: begin
      // READ DRAM
      dram_info.d_man_info = {golden_DRAM[START_ADDR+7+current_d_man_id*8], golden_DRAM[START_ADDR+6+current_d_man_id*8],
                              golden_DRAM[START_ADDR+5+current_d_man_id*8], golden_DRAM[START_ADDR+4+current_d_man_id*8]};

      // ERR_MSG
      cancel_id_check_task;
      if (dram_info.d_man_info == 32'd0) begin
        golden_err_msg = Wrong_cancel;
      end
      else if ( (!ctm1_res_same) && (!ctm2_res_same)) begin
        golden_err_msg = Wrong_res_ID;
      end
      else if ( ctm1_res_same && ctm2_res_same ) begin
        golden_err_msg = ( (!ctm1_food_same) && (!ctm2_food_same) ) ? Wrong_food_ID : No_Err;
      end
      else if ( ctm1_res_same && (!ctm1_food_same) ) begin
        golden_err_msg = Wrong_food_ID;
      end
      else if ( ctm2_res_same && (!ctm2_food_same) ) begin
        golden_err_msg = Wrong_food_ID;
      end
      else begin
        golden_err_msg = No_Err;
      end

      // EXECUTE
      if (golden_err_msg == No_Err) begin
        // d_man_info
        if (ctm1_res_same && ctm1_food_same && ctm2_res_same && ctm2_food_same) begin
          dram_info.d_man_info = 32'd0;
        end
        else if (ctm1_res_same && ctm1_food_same) begin
          dram_info.d_man_info = {16'd0, dram_info.d_man_info.ctm_info2};
        end
        else begin
          dram_info.d_man_info = {16'd0, dram_info.d_man_info.ctm_info1};
        end
        // golden_complete
        golden_complete = 1'b1;
        // golden_out_info
        d_man_info_dram2out_task;
        golden_out_info = {d_man_info_dram2out, 32'd0};
        // WRITE DRAM
        {golden_DRAM[START_ADDR+7+current_d_man_id*8], golden_DRAM[START_ADDR+6+current_d_man_id*8], 
         golden_DRAM[START_ADDR+5+current_d_man_id*8], golden_DRAM[START_ADDR+4+current_d_man_id*8]} = dram_info.d_man_info;
      end
      else begin
        // golden_complete
        golden_complete = 1'b0;
        // golden_out_info
        golden_out_info = 64'd0;
      end
    end
  endcase
end endtask


task check_ans_task; begin
  if (inf.complete !== golden_complete || inf.err_msg !== golden_err_msg || inf.out_info !== golden_out_info) begin
    // $display("\033[0;33mGolden complete : %16d,\033[m \033[0;31mYour complete : %16d\033[m", golden_complete, inf.complete);
    // $display("\033[0;33mGolden err_msg  : %16s,\033[m \033[0;31mYour err_msg  : %16s\033[m",
    //           golden_err_msg === No_Err ? "No_Err" : ( golden_err_msg === No_Food ? "No_Food" : (golden_err_msg === D_man_busy ? "D_man_busy" : (golden_err_msg === No_customers ? "No_customers" : (golden_err_msg === Res_busy ? "Res_busy" : (golden_err_msg === Wrong_cancel ? "Wrong_cancel" : (golden_err_msg === Wrong_res_ID ? "Wrong_res_ID" : "Wrong_food_ID") ) ) ) ) ),
    //           inf.err_msg    === No_Err ? "No_Err" : ( inf.err_msg    === No_Food ? "No_Food" : (inf.err_msg    === D_man_busy ? "D_man_busy" : (inf.err_msg    === No_customers ? "No_customers" : (inf.err_msg    === Res_busy ? "Res_busy" : (inf.err_msg    === Wrong_cancel ? "Wrong_cancel" : (inf.err_msg    === Wrong_res_ID ? "Wrong_res_ID" : "Wrong_food_ID") ) ) ) ) ) );
    // $display("\033[0;33mGolden out_info : %16h,\033[m \033[0;31mYour out_info : %16h\033[m", golden_out_info, inf.out_info);
    FAIL_task;
  end
end endtask


task wait_out_valid_task; begin
  latency = 0;
  while(inf.out_valid !== 1'b1) begin
    latency = latency + 1;
    @(negedge clk);
  end
end endtask


task FAIL_task; begin
  // $display ("--------------------------------------------------------------------");
  $display ("Wrong Answer");
  // $display ("--------------------------------------------------------------------");
  $finish;
end endtask


task YOU_PASS_task; begin
  $display ("--------------------------------------------------------------------");
  $display ("                         Congratulations!                           ");
  $display ("                  You have passed all patterns!                     ");
  $display ("--------------------------------------------------------------------");        
  $finish;
end endtask


endprogram