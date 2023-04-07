// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : TT.v
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History                                                                        (ORI PAT) (RANDOM PAT)  
// VERSION Date       AUTHOR           DESCRIPTION                          AREA           CYCLE+500 CYCLE+200,000 PERFORMANCE
// 1.0     2022-09-30 Brian Hsieh                                           36597.053391   1697
// 2.0     2022-10-01 Brian Hsieh      calculate 1 cycle earlier (S_TRACK)  36959.630934   1201      725008
// 2.1     2022-10-01 Brian Hsieh      5.0 revision except dst_found_0cycle,
//                                     new_destination, dst_neighbor,
//                                     and omit visited neighbors           33896.016459   1201      725008        2.4575×10^10

// 3.0     2022-10-01 Brian Hsieh      add new_destination, dst_neighbor    42521.371952   1173      636136
// 3.1     2022-10-01 Brian Hsieh      5.0 revision except dst_found_0cycle
//                                     and omit visited neighbors           39454.431034   1173      636136        2.5098×10^10

// 4.0     2022-10-02 Brian Hsieh      omit visited neighbors               45994.133517   1159      551524
// 4.1     2022-10-02 Brian Hsieh      5.0 revision except dst_found_0cycle 42947.150982   1159      551524        2.3686×10^10

// 5.0     2022-10-02 Brian Hsieh      increase dst_found_0cycle, 
//                                     revise dst_found, line 241 omit &&
//                                     FSM param one-hot encoding           46769.184719   821       483790
// 5.1     2022-10-03 Brian Hsieh      define adder                         46789.143124   821       483790        2.2636×10^10
// 5.2     2022-10-03 Brian Hsieh      revise dst_found                     46742.573532   821       483790        2.2614×10^10
// 5.3     2022-10-03 Brian Hsieh      revise next state logic              46715.962336   821       483790        2.2601×10^10
// 5.4     2022-10-03 Brian Hsieh      increase no_nbr                      46835.712729   815       468972        2.1965×10^10
// 5.5     2022-10-03 Brian Hsieh      omit one cost counter                46616.170358   815       468972        2.1862×10^10 (final)
//
// 2nd demo
//                                                                          AREA           CYCLE+1000(1DE PAT) PERFORMANCE
// 5.6     2022-10-03 Brian Hsieh      use generate to simpilify code       46616.170358   3509                1.63576141786222×10^8
// 6.0     2022-10-04 Brian Hsieh      omit new_destination, dst_neighbor   39471.063045   3602                1.4217476908809×10^8
// 6.1     2022-10-04 Brian Hsieh      omit S_OUTPUT, FSM param decode      39224.909411   3602                1.41288123698422×10^8
// 6.2     2022-10-04 Brian Hsieh      revise dst_found, cost condition     39111.811811   2921                1.14245602299931×10^8 (final)
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// Train Tour
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


module TT(
  //Input Port
  clk,
  rst_n,
  in_valid,
  source,
  destination,

  //Output Port
  out_valid,
  cost
);

input              clk;
input              rst_n;
input              in_valid;
input       [ 3:0] source;
input       [ 3:0] destination;

output reg         out_valid;
output reg  [ 3:0] cost;

//==============================================//
//             Parameter and Integer            //
//==============================================//

integer i;

//==============================================//
//            FSM State Declaration             //
//==============================================//

localparam S_IDLE     = 2'b01;
localparam S_TRACK    = 2'b10;
localparam S_FIND     = 2'b00;

//==============================================//
//                Main signals                  //
//==============================================//

reg         [ 1:0] current_state;
reg         [ 1:0] next_state;

reg         [15:0] adj_mem        [15:0];

reg         [ 3:0] source_reg_cs;
reg         [ 3:0] destination_reg_cs;
reg         [ 3:0] source_reg_ns;
reg         [ 3:0] destination_reg_ns;

reg         [15:0] new_source;

reg         [15:0] src_visited_nbr;

reg                out_valid_ns;
reg         [ 3:0] cost_ns;

wire        [15:0] src_masked_adj [15:0];
wire        [15:0] src_neighbor         ;

wire               dst_found_0cycle;
wire               dst_found;
wire               no_nbr;
wire               dst_not_found;
wire               find_end;
wire               find_end_0cycle;

wire        [ 3:0] increment;

//==============================================//
//             Current State Block              //
//==============================================//

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    current_state <= S_IDLE;
  end
  else begin
    current_state <= next_state;
  end
end

//==============================================//
//              Next State Block                //
//==============================================//

always @(*) begin
  case(current_state)
    S_IDLE: begin
      if (in_valid) begin
        next_state = S_TRACK;
      end
      else begin
        next_state = S_IDLE;
      end
    end
    S_TRACK: begin
      if (in_valid) begin
        next_state = S_TRACK;
      end
      else if (find_end_0cycle) begin
        next_state = S_IDLE;
      end
      else begin
        next_state = S_FIND;
      end
    end
    S_FIND: begin
      if (find_end) begin
        next_state = S_IDLE;
      end
      else begin
        next_state = S_FIND;
      end
    end
    default: begin
      next_state = S_IDLE;
    end
  endcase
end


//==============================================//
//                  Input Block                 //
//==============================================//

// source_reg, destination_reg
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    source_reg_cs      <= 4'd0;
    destination_reg_cs <= 4'd0;
  end
  else begin
    source_reg_cs      <= source_reg_ns;
    destination_reg_cs <= destination_reg_ns;
  end
end

always @(*) begin
  if (current_state[0]) begin // S_IDLE
    if (in_valid) begin
      source_reg_ns      = source;
      destination_reg_ns = destination;
    end
    else begin
      source_reg_ns      = source_reg_cs;
      destination_reg_ns = destination_reg_cs;
    end
  end
  else begin
    source_reg_ns      = source_reg_cs;
    destination_reg_ns = destination_reg_cs;
  end
end


// adj_mem
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    for (i=0; i<16; i=i+1) begin
      adj_mem[i] <= 16'd0;
    end
  end
  else begin
    if (current_state[0]) begin // S_IDLE
      for (i=0; i<16; i=i+1) begin
        adj_mem[i] <= 16'd0;
      end
    end
    else if (current_state[1]) begin // S_TRACK
      if (in_valid) begin
        adj_mem[source][destination] <= 1'b1;
        adj_mem[destination][source] <= 1'b1;
      end
    end
  end
end



//==============================================//
//              Calculation Block               //
//==============================================//

// new_source, new_destination, src_visited_nbr, dst_visited_nbr
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    new_source <= 16'h0000;
    src_visited_nbr <= 16'hffff;
  end
  else begin
    if (current_state[0]) begin // S_IDLE
      new_source <= 16'h0000;
      src_visited_nbr <= 16'hffff;
    end
    else if (current_state[1]) begin // S_TRACK
      if (in_valid) begin
        new_source[source_reg_cs] <= 1'b1;
        src_visited_nbr[source_reg_cs] <= 1'b0;
      end
      else begin
        new_source <= src_neighbor;
        src_visited_nbr <= src_visited_nbr & (~src_neighbor);
      end
    end
    else begin // S_FIND
      new_source <= src_neighbor;
      src_visited_nbr <= src_visited_nbr & (~src_neighbor);
    end
  end
end


//==============================================//
//                Output Block                  //
//==============================================//

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
    S_TRACK: begin
      if (find_end_0cycle) begin
        if (in_valid) begin
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
    S_FIND: begin
      if (find_end) begin
        out_valid_ns = 1'b1;
      end
      else begin
        out_valid_ns = 1'b0;
      end
    end
    default: begin
      out_valid_ns = 1'b0;
    end
  endcase
end


// cost
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    cost <= 4'd0;
  end
  else begin
    cost <= cost_ns;
  end
end

always @(*) begin
  case(current_state)
    S_TRACK: begin
      if (in_valid | no_nbr) begin
        cost_ns = 4'd0;
      end
      else begin
        cost_ns = 4'd1;
      end
    end
    S_FIND: begin
      if (dst_not_found) begin
        cost_ns = 4'd0;
      end
      else begin
        cost_ns = increment;
      end
    end
    default: begin
      cost_ns = 4'd0;
    end
  endcase
end

adder u_adder (.x(cost), .y(increment));

genvar sm;
generate
  for (sm=0; sm<16; sm=sm+1) begin: src_mask
    assign src_masked_adj[sm] = {16{new_source[sm]}} & adj_mem[sm];
  end
endgenerate

assign src_neighbor = ( src_masked_adj[ 0] | src_masked_adj[ 1] | src_masked_adj[ 2] | src_masked_adj[ 3] |
                        src_masked_adj[ 4] | src_masked_adj[ 5] | src_masked_adj[ 6] | src_masked_adj[ 7] |
                        src_masked_adj[ 8] | src_masked_adj[ 9] | src_masked_adj[10] | src_masked_adj[11] |
                        src_masked_adj[12] | src_masked_adj[13] | src_masked_adj[14] | src_masked_adj[15] ) & src_visited_nbr;


// assign dst_found_0cycle = (adj_mem[destination_reg_cs][source_reg_cs] == 1'b1);
assign dst_found_0cycle = (adj_mem[source_reg_cs][destination_reg_cs] == 1'b1);
// assign dst_found        = (new_source[destination_reg_cs] == 1'b1);
assign dst_found        = (src_neighbor[destination_reg_cs] == 1'b1);
assign no_nbr           = (src_neighbor == 16'd0);
assign dst_not_found    = no_nbr | (cost == 4'd15);
assign find_end         = dst_found | dst_not_found;
assign find_end_0cycle  = dst_found_0cycle | no_nbr;

endmodule 


module adder (x, y);

input  [3:0] x;
output [3:0] y;

assign y = x + 4'd1;

endmodule