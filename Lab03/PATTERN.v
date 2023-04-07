// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : PATTERN.v
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                 
// 1.0     2022-10-10 Brian Hsieh      
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// PATTERN of Block Party mode in Fall Guys
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

`ifdef RTL
    `define CYCLE_TIME 10.0
`endif
`ifdef GATE
    `define CYCLE_TIME 10.0
`endif

`define PAT_NUM 300

module PATTERN(
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

output reg       clk, rst_n;
output reg       in_valid;
output reg [2:0] guy;
output reg [1:0] in0, in1, in2, in3, in4, in5, in6, in7;
input            out_valid;
input      [1:0] out;


/* define clock cycle */
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

/* parameter and integer*/
integer patnum = `PAT_NUM;
integer i_pat, i, j, k, a, t;
integer seed = 123;
integer select;
integer f_in;
integer guy_pos;
integer current_hei;
integer current_pos;
integer pos;
integer pfm0, pfm1, pfm2, pfm3, pfm4, pfm5, pfm6, pfm7;
integer golden_cost;
integer out_valid_cycle;
integer latency;
integer total_latency;
localparam STOP  = 2'd0;
localparam RIGHT = 2'd1;
localparam LEFT  = 2'd2;
localparam JUMP  = 2'd3;
localparam NO_OBS   = 2'd0;
localparam LOW_OBS  = 2'd1;
localparam HIGH_OBS = 2'd2;
localparam FULL_OBS = 2'd3;


/* reg declaration */
reg       spec3_pass;
reg [1:0] platform [63:0][7:0];
reg [1:0] out_reg  [62:0];


initial begin
    reset_task; // SPEC 3

    for (i_pat = 0; i_pat < patnum; i_pat = i_pat+1) begin
        input_random_task; // Generate test pattern randomly
        wait_out_valid_task;  // SPEC 6
        check_out_valid_task; // SPEC 7, SPEC 8
        
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %3d\033[m",i_pat ,latency);
    end
    YOU_PASS_task;
end



// SPEC 3
task reset_task; begin 
    spec3_pass = 'b0;
    rst_n = 'b1;
    in_valid = 'b0;
    guy = 'bx;
    current_hei = 'bx;
    current_pos = 'bx;
    in0 = 'bx;
    in1 = 'bx;
    in2 = 'bx;
    in3 = 'bx;
    in4 = 'bx;
    in5 = 'bx;
    in6 = 'bx;
    in7 = 'bx;
    for(i = 0; i < 64; i = i+1) begin
        for(j = 0; j < 8; j = j+1) begin
            platform[i][j] = 'bx;
        end
    end
    for(k = 0; k < 63; k = i+1) begin
        out_reg[k] = 'bx;
    end
    total_latency = 0;
    out_valid_cycle = 0;

    force clk = 0;

    #CYCLE; rst_n = 0; 
    #CYCLE; rst_n = 1;
    
    if(out_valid !== 1'b0 || out !== 'b0) begin
        $display("************************************************************");  
        $display("*                     SPEC 3 IS FAIL!                      *");    
        $display("*      Output signal should be 0 after initial RESET       *");
        $display("************************************************************");
        $finish;
    end
    spec3_pass = 'b1;
    #CYCLE; release clk;
end endtask



// SPEC 4 & SPEC 5
always @(*) begin
    if (spec3_pass) begin
        if (out_valid === 'b0 && out !== 'b0) begin // SPEC 4
            $display("************************************************************");
            $display("*                     SPEC 4 IS FAIL!                      *");
            $display("*      Output signal should be 0 when out_valid is low     *");
            $display("************************************************************");
            $finish;
        end
        if (out_valid === 'b1 && in_valid === 'b1) begin // SPEC 5
            $display("************************************************************");
            $display("*                     SPEC 5 IS FAIL!                      *");
            $display("*       out_valid should be low when in_valid is high      *");
            $display("************************************************************");
            $finish;
        end
    end
end


// input generated randomly
task input_random_task; begin
    t = $urandom_range(2, 4);
    repeat(t) @(negedge clk);
    in_valid = 1'b1;
    out_valid_cycle = 0;
    
    //initial random position from 0 to 7
    guy = $random(seed) % 'd8;
    current_hei = 0;
    current_pos = guy;
    pos = guy;
    in0 = 'd0;
    in1 = 'd0;
    in2 = 'd0;
    in3 = 'd0;
    in4 = 'd0;
    in5 = 'd0;
    in6 = 'd0;
    in7 = 'd0;
    platform[0][0] = in0;
    platform[0][1] = in1;
    platform[0][2] = in2;
    platform[0][3] = in3;
    platform[0][4] = in4;
    platform[0][5] = in5;
    platform[0][6] = in6;
    platform[0][7] = in7;
    // $display("********************************");
    // $display("*  Guy Position:  %1d            *", guy);
    // $display("*  Cycle  0:  %1d %1d %1d %1d %1d %1d %1d %1d  *", platform[0][0], platform[0][1], platform[0][2], platform[0][3], platform[0][4], platform[0][5], platform[0][6], platform[0][7]);
    @(negedge clk);
    guy = 'bx;
    for(i = 0; i < 63; i = i+1) begin
        if (|({platform[i][0], platform[i][1], platform[i][2], platform[i][3], platform[i][4], platform[i][5], platform[i][6], platform[i][7]}) == 1'b0) begin
            if (pos == 'd0) begin
                select = $random(seed) % 'd4;
                case (select)
                    0: begin
                        in0 = 'd0;
                        in1 = 'd0;
                        in2 = 'd0;
                        in3 = 'd0;
                        in4 = 'd0;
                        in5 = 'd0;
                        in6 = 'd0;
                        in7 = 'd0;
                        pos = pos + ($random(seed) % 'd2);
                    end
                    1: begin
                        in0 = 'd1;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                    end
                    2: begin
                        in0 = 'd2;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                    end
                    default : begin
                        in0 = 'd3;
                        in1 = 'd2;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                        pos = pos + 1;
                    end
                endcase
            end
            else if (pos == 'd7) begin
                select = $random(seed) % 'd4;
                case (select)
                    0: begin
                        in0 = 'd0;
                        in1 = 'd0;
                        in2 = 'd0;
                        in3 = 'd0;
                        in4 = 'd0;
                        in5 = 'd0;
                        in6 = 'd0;
                        in7 = 'd0;
                        pos = pos - ($random(seed) % 'd2);
                    end
                    1: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd1;
                    end
                    2: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd2;
                    end
                    default : begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd2;
                        in7 = 'd3;
                        pos = pos - 1;
                    end
                endcase
            end
            else if (pos == 'd1) begin
                select = $random(seed) % 'd5;
                case (select)
                    0: begin
                        in0 = 'd0;
                        in1 = 'd0;
                        in2 = 'd0;
                        in3 = 'd0;
                        in4 = 'd0;
                        in5 = 'd0;
                        in6 = 'd0;
                        in7 = 'd0;
                        pos = pos + ($random(seed) % 2);
                    end
                    1: begin
                        in0 = 'd3;
                        in1 = 'd1;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                    end
                    2: begin
                        in0 = 'd3;
                        in1 = 'd2;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                    end
                    3: begin
                        in0 = 'd2;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                        pos = pos - 1;
                    end
                    default : begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd2;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                        pos = pos + 1;
                    end
                endcase
            end
            else if (pos == 'd2) begin
                select = $random(seed) % 'd5;
                case (select)
                    0: begin
                        in0 = 'd0;
                        in1 = 'd0;
                        in2 = 'd0;
                        in3 = 'd0;
                        in4 = 'd0;
                        in5 = 'd0;
                        in6 = 'd0;
                        in7 = 'd0;
                        pos = pos + ($random(seed) % 2);
                    end
                    1: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd1;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                    end
                    2: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd2;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                    end
                    3: begin
                        in0 = 'd3;
                        in1 = 'd2;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                        pos = pos - 1;
                    end
                    default : begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd2;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                        pos = pos + 1;
                    end
                endcase
            end
            else if (pos == 'd3) begin
                select = $random(seed) % 'd5;
                case (select)
                    0: begin
                        in0 = 'd0;
                        in1 = 'd0;
                        in2 = 'd0;
                        in3 = 'd0;
                        in4 = 'd0;
                        in5 = 'd0;
                        in6 = 'd0;
                        in7 = 'd0;
                        pos = pos + ($random(seed) % 2);
                    end
                    1: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd1;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                    end
                    2: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd2;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                    end
                    3: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd2;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                        pos = pos - 1;
                    end
                    default : begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd2;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                        pos = pos + 1;
                    end
                endcase
            end
            else if (pos == 'd4) begin
                select = $random(seed) % 'd5;
                case (select)
                    0: begin
                        in0 = 'd0;
                        in1 = 'd0;
                        in2 = 'd0;
                        in3 = 'd0;
                        in4 = 'd0;
                        in5 = 'd0;
                        in6 = 'd0;
                        in7 = 'd0;
                        pos = pos + ($random(seed) % 2);
                    end
                    1: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd1;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                    end
                    2: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd2;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                    end
                    3: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd2;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                        pos = pos - 1;
                    end
                    default : begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd2;
                        in6 = 'd3;
                        in7 = 'd3;
                        pos = pos + 1;
                    end
                endcase
            end
            else if (pos == 'd5) begin
                select = $random(seed) % 'd5;
                case (select)
                    0: begin
                        in0 = 'd0;
                        in1 = 'd0;
                        in2 = 'd0;
                        in3 = 'd0;
                        in4 = 'd0;
                        in5 = 'd0;
                        in6 = 'd0;
                        in7 = 'd0;
                        pos = pos + ($random(seed) % 2);
                    end
                    1: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd1;
                        in6 = 'd3;
                        in7 = 'd3;
                    end
                    2: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd2;
                        in6 = 'd3;
                        in7 = 'd3;
                    end
                    3: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd2;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd3;
                        pos = pos - 1;
                    end
                    default : begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd2;
                        in7 = 'd3;
                        pos = pos + 1;
                    end
                endcase
            end
            else if (pos == 'd6) begin
                select = $random(seed) % 'd5;
                case (select)
                    0: begin
                        in0 = 'd0;
                        in1 = 'd0;
                        in2 = 'd0;
                        in3 = 'd0;
                        in4 = 'd0;
                        in5 = 'd0;
                        in6 = 'd0;
                        in7 = 'd0;
                        pos = pos + ($random(seed) % 2);
                    end
                    1: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd1;
                        in7 = 'd3;
                    end
                    2: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd2;
                        in7 = 'd3;
                    end
                    3: begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd2;
                        in6 = 'd3;
                        in7 = 'd3;
                        pos = pos - 1;
                    end
                    default : begin
                        in0 = 'd3;
                        in1 = 'd3;
                        in2 = 'd3;
                        in3 = 'd3;
                        in4 = 'd3;
                        in5 = 'd3;
                        in6 = 'd3;
                        in7 = 'd2;
                        pos = pos + 1;
                    end
                endcase
            end
        end
        else if (platform[i][0] == 'd2 || platform[i][1] == 'd2 || platform[i][2] == 'd2 || platform[i][3] == 'd2 || platform[i][4] == 'd2 || platform[i][5] == 'd2 || platform[i][6] == 'd2 || platform[i][7] == 'd2) begin
            in0 = 'd0;
            in1 = 'd0;
            in2 = 'd0;
            in3 = 'd0;
            in4 = 'd0;
            in5 = 'd0;
            in6 = 'd0;
            in7 = 'd0;
            if (pos == 'd0) begin
                pos = pos + ($random(seed) % 'd2);
            end
            else if (pos == 'd7) begin
                pos = pos - ($random(seed) % 'd2);
            end
            else begin
                pos = pos + ($random(seed) % 2);
            end
        end
        else begin
            in0 = 'd0;
            in1 = 'd0;
            in2 = 'd0;
            in3 = 'd0;
            in4 = 'd0;
            in5 = 'd0;
            in6 = 'd0;
            in7 = 'd0;
        end
        platform[i+1][0] = in0;
        platform[i+1][1] = in1;
        platform[i+1][2] = in2;
        platform[i+1][3] = in3;
        platform[i+1][4] = in4;
        platform[i+1][5] = in5;
        platform[i+1][6] = in6;
        platform[i+1][7] = in7;
        // $display("*  Cycle %2d:  %1d %1d %1d %1d %1d %1d %1d %1d  *",i+1, platform[i+1][0], platform[i+1][1], platform[i+1][2], platform[i+1][3], platform[i+1][4], platform[i+1][5], platform[i+1][6], platform[i+1][7]);
        @(negedge clk);
    end
    // $display("********************************");

    in_valid = 1'b0;
    in0 = 'bx;
    in1 = 'bx;
    in2 = 'bx;
    in3 = 'bx;
    in4 = 'bx;
    in5 = 'bx;
    in6 = 'bx;
    in7 = 'bx;  
end endtask 


// SPEC 6
task wait_out_valid_task; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
        latency = latency + 1;
        if(latency == 3000) begin
            $display("********************************************************");     
            $display("*                   SPEC 6 IS FAIL!                    *");
            $display("*  The execution latency are over 3000 cycles  at %8t  *",$time);//over max
            $display("********************************************************");
            $finish;
        end
        @(negedge clk);
    end
   total_latency = total_latency + latency;
end endtask


// SPEC 8-3
task spec8_3_task; begin
    if ( (out_reg[out_valid_cycle-1] == JUMP) && (out_valid_cycle >= 1) ) begin // previous: JUMP
        if (platform[out_valid_cycle-1][current_pos] == NO_OBS) begin // previous: NO_OBS
            if (platform[out_valid_cycle][current_pos] == NO_OBS) begin // now: NO_OBS
                if (out != STOP) begin // now: not STOP
                    $display ("**********************************************************************");
                    $display ("*                         SPEC 8-3 IS FAIL!                          *");
                    $display ("* If the guy jumps to the SAME HEIGHT, out must be 2'b00 for 1 CYCLE *");
                    $display ("**********************************************************************");
                    $finish;
                end
            end
        end
    end
    if ( (out_reg[out_valid_cycle-1] == JUMP) && (out_valid_cycle >= 1) ) begin // previous: JUMP
        if (platform[out_valid_cycle-1][current_pos] == LOW_OBS) begin // previous: LOW_OBS
            if (platform[out_valid_cycle+1][current_pos] != NO_OBS) begin // next: not NO_OBS
                if (out != STOP) begin // now: not STOP
                    $display ("**********************************************************************");
                    $display ("*                         SPEC 8-3 IS FAIL!                          *");
                    $display ("* If the guy jumps to the SAME HEIGHT, out must be 2'b00 for 1 CYCLE *");
                    $display ("**********************************************************************");
                    $finish;
                end
            end
        end
    end
    if ( (out_reg[out_valid_cycle-1] == JUMP) && (out_valid_cycle >= 1) ) begin // previous: JUMP
        if (platform[out_valid_cycle-1][current_pos] == HIGH_OBS) begin // previous: HIGH_OBS
            if (out != STOP) begin // now: not STOP
                $display ("**********************************************************************");
                $display ("*                         SPEC 8-3 IS FAIL!                          *");
                $display ("* If the guy jumps to the SAME HEIGHT, out must be 2'b00 for 1 CYCLE *");
                $display ("**********************************************************************");
                $finish;
            end
        end
    end
end endtask


// SPEC 8-2
task spec8_2_task; begin
    if ( (out_reg[out_valid_cycle-1] == JUMP) && (out_valid_cycle >= 1) ) begin // previous: JUMP
        if (platform[out_valid_cycle-1][current_pos] == LOW_OBS) begin // previous: LOW_OBS
            if (platform[out_valid_cycle+1][current_pos] != LOW_OBS) begin // next: NO_OBS
                if (out != STOP) begin // now: not STOP
                    $display ("**********************************************************************");
                    $display ("*                         SPEC 8-2 IS FAIL!                          *");
                    $display ("*  If the guy jumps FROM HIGH TO LOW, out must be 2'b00 for 2 CYCLES *");
                    $display ("**********************************************************************");
                    $finish;
                end
            end
        end
    end
    if ( (out_reg[out_valid_cycle-2] == JUMP) && (out_valid_cycle >= 2) ) begin // the last 2: JUMP
        if (platform[out_valid_cycle-2][current_pos] == LOW_OBS) begin // the last 2: LOW_OBS
            if (platform[out_valid_cycle][current_pos] == NO_OBS) begin // now: NO_OBS
                if (out != STOP) begin // now: not STOP
                    $display ("**********************************************************************");
                    $display ("*                         SPEC 8-2 IS FAIL!                          *");
                    $display ("*  If the guy jumps FROM HIGH TO LOW, out must be 2'b00 for 2 CYCLES *");
                    $display ("**********************************************************************");
                    $finish;
                end
            end
        end
    end
end endtask


// SPEC 8-1
task spec8_1_task; begin
    if (current_hei == 1) begin
        if (platform[out_valid_cycle][current_pos][1] == 1) begin // there is obstacle at high place
            $display ("**********************************************************************");
            $display ("*                         SPEC 8-1 IS FAIL!                          *");
            $display ("*                  The guy must avoid all obstacles                  *");
            $display ("**********************************************************************");
            $finish;
        end
    end
    if (current_hei == 0) begin
        if (platform[out_valid_cycle][current_pos][0] == 1) begin // there is obstacle at low place
            $display ("**********************************************************************");
            $display ("*                         SPEC 8-1 IS FAIL!                          *");
            $display ("*                  The guy must avoid all obstacles                  *");
            $display ("**********************************************************************");
            $finish;
        end
    end
    if ( ((current_pos == 0) && (out == LEFT)) || ((current_pos == 7) && (out == RIGHT)) ) begin // leave the platform
        $display ("**********************************************************************");
        $display ("*                         SPEC 8-1 IS FAIL!                          *");
        $display ("*                 The guy cannot leave the platform                  *");
        $display ("**********************************************************************");
        $finish;
    end
end endtask


// UPDATE POSITION, HEIGHT, OUT_REG AND CYCLE
task update_condition_task; begin
    // update height
    if (out == JUMP) begin
        current_hei = current_hei + 1;
    end
    else if (current_hei > 0) begin
        current_hei = current_hei - 1;
    end

    // update position
    if (out == RIGHT) begin
      current_pos = current_pos + 1;
    end
    else if (out == LEFT) begin
      current_pos = current_pos - 1;
    end

    // update out_reg
    out_reg[out_valid_cycle] = out;

    // update cycle
    out_valid_cycle = out_valid_cycle + 1;
end endtask


// SPEC 7, SPEC 8
task check_out_valid_task; begin
    while(out_valid === 'b1) begin
        if (out_valid_cycle === 'd63) begin
            $display ("**********************************************************************");
            $display ("*                          SPEC 7 IS FAIL!                           *");
            $display ("*   out_valid and out should be asserted successively in 63 cycles   *");
            $display ("**********************************************************************");
            $finish;
        end
        spec8_3_task; // SPEC 8-3
        spec8_2_task; // SPEC 8-2
        spec8_1_task; // SPEC 8-1
        update_condition_task;
        @(negedge clk);
    end
    if (out_valid_cycle !== 'd63) begin
        $display ("**********************************************************************");
        $display ("*                          SPEC 7 IS FAIL!                           *");
        $display ("*   out_valid and out should be asserted successively in 63 cycles   *"); 
        $display ("**********************************************************************");
        $finish;
    end
end endtask


task YOU_PASS_task; begin
    $display ("--------------------------------------------------------------------");
    $display ("                         Congratulations!                           ");
    $display ("                  You have passed all patterns!                     ");
    $display ("                  Total latency : %d cycles                     ", total_latency);
    $display ("--------------------------------------------------------------------");        
    $finish;
end endtask


endmodule
