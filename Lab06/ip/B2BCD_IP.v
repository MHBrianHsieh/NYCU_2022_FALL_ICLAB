// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : B2BCD_IP.v
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                 (WIDTH, DIGIT)  IP_AREA       SLACK(6NS)
// 1.0     2022-10-27 Brian Hsieh                                  (4,2)           133.056002    5.4866
//                                                                 (5,2)           292.723205    4.2770
//                                                                 (6,2)           365.904006    4.0082
//                                                                 (7,3)           625.363209    3.6133
//                                                                 (8,3)           828.273609    1.5180
//                                                                 (9,3)           1101.038412   0.7635
//                                                                 (10,4)          1470.268814   0.0631
//                                                                 (11,4)          1949.270423   0.0149
//                                                                 (12,4)          2474.841634   0.0717
//                                                                 (13,4)          3116.836846   0.0074
//                                                                 (14,5)          3868.603251   0.0026
//                                                                 (15,5)          4819.953681   0.0087
//                                                                 (16,5)          5807.894500   0.0004
//                                                                 (17,6)          7840.324922   0.0000
//                                                                 (18,6)          9270.676925   0.0034
//                                                                 (19,6)          11346.350566  0.0019
//                                                                 (20,7)          13994.164977  0.0003
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// Combinational Binary-to-BCD Converter Soft IP
// -----------------------------------------------------------------------------
// PARAMETERS
// PARAM_NAME RANGE      : DESCRIPTION           : DEFAULT
// WIDTH                   binary bits
// DIGIT                   decimal digits
// -----------------------------------------------------------------------------
// REUSE ISSUES
// Reset Schemes : N/A
// Clock Domains : N/A
// Asynchronous I/F : N/A
// Instantiations : N/A
// Other : Double Dabble Algorithm (Shift-and-Add-3 Algorithm)
// -----------------------------------------------------------------------------


module B2BCD_IP #(parameter WIDTH = 4, parameter DIGIT = 2) (
    // Input signals
    Binary_code,
    // Output signals
    BCD_code
);

// ===============================================================
// Declaration
// ===============================================================
input  [WIDTH-1:0]   Binary_code;
output [DIGIT*4-1:0] BCD_code;

// ===============================================================
// Soft IP DESIGN
// ===============================================================

// initialize the array, add 2 bits to prevent index-out-of-range problem when WIDTH = 13, 16, 19 
wire [DIGIT*4+1:0] init_add3_temp;

assign init_add3_temp = {{(DIGIT*4-WIDTH+2){1'b0}}, Binary_code};

genvar i, j;

generate
  for (i=0; i<=WIDTH-4; i=i+1) begin: loop_depth
    for (j=0; j<=i/3; j=j+1) begin: loop_width
      wire [DIGIT*4+1:0] add3_temp;
      if ( (i == 0) && (i == WIDTH-4) ) begin
        assign add3_temp[WIDTH-i+4*j -: 4]          = (init_add3_temp[WIDTH-i+4*j -: 4] > 4'd4) ? 
                                                      (init_add3_temp[WIDTH-i+4*j -: 4] + 4'd3) : 
                                                      (init_add3_temp[WIDTH-i+4*j -: 4]       ) ;
        assign add3_temp[DIGIT*4+1 : WIDTH-i+4*j+1] = init_add3_temp[DIGIT*4+1 : WIDTH-i+4*j+1];
        assign add3_temp[WIDTH-i+4*j-4 : 0]         = init_add3_temp[WIDTH-i+4*j-4 : 0];
        assign BCD_code = add3_temp[DIGIT*4-1 : 0];
      end
      else if ( (i == 0) && (j == 0) ) begin
        assign add3_temp[WIDTH-i+4*j -: 4]          = (init_add3_temp[WIDTH-i+4*j -: 4] > 4'd4) ? 
                                                      (init_add3_temp[WIDTH-i+4*j -: 4] + 4'd3) : 
                                                      (init_add3_temp[WIDTH-i+4*j -: 4]       ) ;
        assign add3_temp[DIGIT*4+1 : WIDTH-i+4*j+1] = init_add3_temp[DIGIT*4+1 : WIDTH-i+4*j+1];
        assign add3_temp[WIDTH-i+4*j-4 : 0]         = init_add3_temp[WIDTH-i+4*j-4 : 0];
      end
      else if ( (i == WIDTH-4) && (j == i/3) ) begin
        if (j > 0) begin
          assign add3_temp[WIDTH-i+4*j -: 4]          = (loop_depth[i].loop_width[j-1].add3_temp[WIDTH-i+4*j -: 4] > 4'd4) ? 
                                                        (loop_depth[i].loop_width[j-1].add3_temp[WIDTH-i+4*j -: 4] + 4'd3) :
                                                        (loop_depth[i].loop_width[j-1].add3_temp[WIDTH-i+4*j -: 4]       ) ;
          assign add3_temp[DIGIT*4+1 : WIDTH-i+4*j+1] = loop_depth[i].loop_width[j-1].add3_temp[DIGIT*4+1 : WIDTH-i+4*j+1];
          assign add3_temp[WIDTH-i+4*j-4 : 0]         = loop_depth[i].loop_width[j-1].add3_temp[WIDTH-i+4*j-4 : 0];
        end
        else begin
          assign add3_temp[WIDTH-i+4*j -: 4]          = (loop_depth[i-1].loop_width[(i-1)/3].add3_temp[WIDTH-i+4*j -: 4] > 4'd4) ? 
                                                        (loop_depth[i-1].loop_width[(i-1)/3].add3_temp[WIDTH-i+4*j -: 4] + 4'd3) :
                                                        (loop_depth[i-1].loop_width[(i-1)/3].add3_temp[WIDTH-i+4*j -: 4]       ) ;
          assign add3_temp[DIGIT*4+1 : WIDTH-i+4*j+1] = loop_depth[i-1].loop_width[(i-1)/3].add3_temp[DIGIT*4+1 : WIDTH-i+4*j+1];
          assign add3_temp[WIDTH-i+4*j-4 : 0]         = loop_depth[i-1].loop_width[(i-1)/3].add3_temp[WIDTH-i+4*j-4 : 0];
        end
        assign BCD_code = add3_temp[DIGIT*4-1 : 0];
      end
      else begin
        if (j > 0) begin
          assign add3_temp[WIDTH-i+4*j -: 4]          = (loop_depth[i].loop_width[j-1].add3_temp[WIDTH-i+4*j -: 4] > 4'd4) ? 
                                                        (loop_depth[i].loop_width[j-1].add3_temp[WIDTH-i+4*j -: 4] + 4'd3) :
                                                        (loop_depth[i].loop_width[j-1].add3_temp[WIDTH-i+4*j -: 4]       ) ;
          assign add3_temp[DIGIT*4+1 : WIDTH-i+4*j+1] = loop_depth[i].loop_width[j-1].add3_temp[DIGIT*4+1 : WIDTH-i+4*j+1];
          assign add3_temp[WIDTH-i+4*j-4 : 0]         = loop_depth[i].loop_width[j-1].add3_temp[WIDTH-i+4*j-4 : 0];
        end
        else begin
          assign add3_temp[WIDTH-i+4*j -: 4]          = (loop_depth[i-1].loop_width[(i-1)/3].add3_temp[WIDTH-i+4*j -: 4] > 4'd4) ? 
                                                        (loop_depth[i-1].loop_width[(i-1)/3].add3_temp[WIDTH-i+4*j -: 4] + 4'd3) :
                                                        (loop_depth[i-1].loop_width[(i-1)/3].add3_temp[WIDTH-i+4*j -: 4]       ) ;
          assign add3_temp[DIGIT*4+1 : WIDTH-i+4*j+1] = loop_depth[i-1].loop_width[(i-1)/3].add3_temp[DIGIT*4+1 : WIDTH-i+4*j+1];
          assign add3_temp[WIDTH-i+4*j-4 : 0]         = loop_depth[i-1].loop_width[(i-1)/3].add3_temp[WIDTH-i+4*j-4 : 0];
        end
      end
    end
  end
endgenerate

endmodule