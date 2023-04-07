// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : bridge.sv
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                 
// 1.0     2022-11-23 Brian Hsieh      
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// Bridge DRAM and FD.sv by AXI4 Lite
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

`include "Usertype_FD.sv"

module bridge(input clk, INF.bridge_inf inf);

import  usertype::*;

//================================================================
// state 
//================================================================
bridge_state current_state;
bridge_state next_state;

//================================================================
// logic 
//================================================================
logic [ 7:0] C_addr_reg_cs;
logic [ 7:0] C_addr_reg_ns;
logic [63:0] C_data_w_reg_cs;
logic [63:0] C_data_w_reg_ns;

logic        C_out_valid_nxt;
logic [63:0] C_data_r_nxt;


// AXI4 LITE READ
assign inf.AR_VALID = (current_state == B_ARREADY);
assign inf.AR_ADDR = (current_state == B_ARREADY) ? {1'b1, 5'd0, C_addr_reg_cs, 3'd0} : 17'd0;
assign inf.R_READY = (current_state != B_IDLE);

// AXI4 LITE WRITE
assign inf.AW_VALID = (current_state == B_AWREADY);
assign inf.AW_ADDR = (current_state == B_AWREADY) ? {1'b1, 5'd0, C_addr_reg_cs, 3'd0} : 17'd0;
assign inf.W_VALID = inf.R_READY; // current_state != B_IDLE
assign inf.W_DATA = C_data_w_reg_cs;
assign inf.B_READY = inf.R_READY; // current_state != B_IDLE


//================================================================
//   FSM
//================================================================

// state register
always_ff @(posedge clk or negedge inf.rst_n) begin
  if(!inf.rst_n) begin
    current_state <= B_IDLE;
  end
  else begin
    current_state <= next_state;
  end
end


// next state logic
always_comb begin
  case (current_state)
    B_IDLE: begin
      if (inf.C_in_valid) begin
        next_state = B_C_IN_VALID;
      end
      else begin
        next_state = B_IDLE;
      end
    end
    B_C_IN_VALID: begin
      if (inf.C_r_wb) begin
        next_state = B_ARREADY;
      end
      else begin
        next_state = B_AWREADY;
      end
    end
    B_ARREADY: begin
      if (inf.AR_READY) begin
        next_state = B_RVALID;
      end
      else begin
        next_state = B_ARREADY;
      end
    end
    B_RVALID: begin
      if (inf.R_VALID) begin
        next_state = B_FINISH;
      end
      else begin
        next_state = B_RVALID;
      end
    end
    B_AWREADY: begin
      if (inf.AW_READY) begin
        next_state = B_WVALID;
      end
      else begin
        next_state = B_AWREADY;
      end
    end
    B_WVALID: begin
      if (inf.B_VALID) begin
        next_state = B_FINISH;
      end
      else begin
        next_state = B_WVALID;
      end
    end
    B_FINISH: begin
      next_state = B_IDLE;
    end
    default: begin
      next_state = B_IDLE;
    end
  endcase
end


// C_addr_reg
always_ff @(posedge clk or negedge inf.rst_n) begin
  if(!inf.rst_n) begin
    C_addr_reg_cs <= 0;
  end else begin
    C_addr_reg_cs <= C_addr_reg_ns;
  end
end

always_comb begin
  if (current_state == B_C_IN_VALID) begin
    C_addr_reg_ns = inf.C_addr;
  end
  else begin
    C_addr_reg_ns = C_addr_reg_cs;
  end
end

// C_data_w_reg_cs
always_ff @(posedge clk or negedge inf.rst_n) begin
  if(!inf.rst_n) begin
    C_data_w_reg_cs <= 0;
  end else begin
    C_data_w_reg_cs <= C_data_w_reg_ns;
  end
end

always_comb begin
  if (current_state == B_AWREADY && inf.AW_READY) begin
    C_data_w_reg_ns = inf.C_data_w;
  end
  else begin
    C_data_w_reg_ns = C_data_w_reg_cs;
  end
end


// C_out_valid
always_ff @(posedge clk or negedge inf.rst_n) begin
  if(!inf.rst_n) begin
    inf.C_out_valid <= 1'b0;
  end
  else begin
    inf.C_out_valid <= C_out_valid_nxt;
  end
end

always_comb begin
  case (current_state)
    B_RVALID: begin
      if (inf.R_VALID) begin
        C_out_valid_nxt = 1'b1;
      end
      else begin
        C_out_valid_nxt = 1'b0;
      end
    end
    B_WVALID: begin
      if (inf.B_VALID) begin
        C_out_valid_nxt = 1'b1;
      end
      else begin
        C_out_valid_nxt = 1'b0;
      end
    end
    default: begin
      C_out_valid_nxt = 1'b0;
    end
  endcase
end


// C_data_r
always_ff @(posedge clk or negedge inf.rst_n) begin
  if(!inf.rst_n) begin
    inf.C_data_r <= 64'd0;
  end
  else begin
    inf.C_data_r <= C_data_r_nxt;
  end
end

always_comb begin
  if (current_state == B_RVALID) begin
    if (inf.R_VALID) begin
      C_data_r_nxt = inf.R_DATA;
    end
    else begin
      C_data_r_nxt = 64'd0;
    end
  end
  else begin
    C_data_r_nxt = 64'd0;
  end
end

endmodule