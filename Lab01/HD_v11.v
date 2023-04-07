// -----------------------------------------------------------------------------
// Copyright (c) 2022, Adar Laboratory (Adar Lab).
// Adar Lab's Proprietary/Confidential.
// -----------------------------------------------------------------------------
// FILE NAME : HD.v
// AUTHOR : Brian Hsieh
// -----------------------------------------------------------------------------
// Revision History
// VERSION Date       AUTHOR           DESCRIPTION                                 AREA          SLACK
// 1.0     2022-09-21 Brian Hsieh      
// 2.0     2022-09-21 Brian Hsieh      omit sign extension                         2118.916833   13.54
// 3.0     2022-09-21 Brian Hsieh      2 5-bit adder-substactor                    1975.881626   14.47
// 3.1     2022-09-21 Brian Hsieh      1 5-bit adder & 1 5-bit substactor          2072.347228   13.21
// 3.2     2022-09-21 Brian Hsieh      2 6-bit adder-substactor                    1992.513630   14.82
// 4.0     2022-09-22 Brian Hsieh      1 5-bit adder-substactor                    1912.680025   13.88
// 5.0     2022-09-22 Brian Hsieh      revise adder-substactor                     1846.152033   13.54
// 6.0     2022-09-22 Brian Hsieh      revise c1, c2 to 4-to-1 mux                 1746.360013   14.39
// 6.1     2022-09-22 Brian Hsieh      2 6-bit adder-substactor                    1746.360013   14.11
// 6.2     2022-09-23 Brian Hsieh      try K-map                                   1782.950418   14.00
// 7.0     2022-09-23 Brian Hsieh      revise c1, c2 to 5-to-1 mux                 1729.728013   14.43
// 8.0     2022-09-23 Brian Hsieh      revise c1, c2 to 4 2-to-1 mux               1713.096017   13.93
// 9.0     2022-09-25 Brian Hsieh      combine error_bit & c into an always block  1679.832021   13.91
// 9.1     2022-09-25 Brian Hsieh      revise full adder                           1679.832019   13.91
// 10.0    2022-09-26 Brian Hsieh      revise error_bit & c to gates               1706.443220   14.24
// 10.1    2022-09-26 Brian Hsieh      try K-map                                   1856.131220   13.44
// 11.0    2022-09-26 Brian Hsieh      revise adder-substactor                     1676.505621   13.93 (final)
// -----------------------------------------------------------------------------
// KEYWORDS: General file searching keywords, leave bank if none.
//
// -----------------------------------------------------------------------------
// PURPOSE: Short description of functionality
// (7,4) Hamming Code Decoder
// -----------------------------------------------------------------------------
// PARAMETERS
// PARAM_NAME RANGE      : DESCRIPTION           : DEFAULT
//
// -----------------------------------------------------------------------------
// REUSE ISSUES
// Reset Schemes : N/A
// Clock Domains : N/A
// Asynchronous I/F : N/A
// Instantiations : N/A
// Other : 
// -----------------------------------------------------------------------------


module HD(
  code_word1,
  code_word2,
  out_n
);

input             [6:0] code_word1;
input             [6:0] code_word2;
output     signed [5:0] out_n;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                      main signals                                                                     //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// code_word1 received message
reg                     p11;
reg                     p21;
reg                     p31;
reg                     x11;
reg                     x21;
reg                     x31;
reg                     x41;

// code_word2 received message
reg                     p12;
reg                     p22;
reg                     p32;
reg                     x12;
reg                     x22;
reg                     x32;
reg                     x42;

// code_word1 circle
reg                     circle11;
reg                     circle21;
reg                     circle31;

// code_word2 circle
reg                     circle12;
reg                     circle22;
reg                     circle32;

// circle1, circle2
reg               [2:0] circle1;
reg               [2:0] circle2;

// error_bit
reg                     error_bit1;
reg                     error_bit2;

// error_bit_neg
reg                     error_bit1_neg;
reg                     error_bit2_neg;

// c1, c2
reg  signed       [3:0] c1;
reg  signed       [3:0] c2;

// c1_mult_2, c2_mult_2
reg  signed       [4:0] c1_mult_2;
reg  signed       [4:0] c2_mult_2;

// augend, addend, sub
reg  signed       [5:0] augend;
reg  signed       [5:0] addend;
reg                     sub;


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                       main code                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// code_word1 received message
always @(*) begin
  p11 = code_word1[6];
  p21 = code_word1[5];
  p31 = code_word1[4];
  x11 = code_word1[3];
  x21 = code_word1[2];
  x31 = code_word1[1];
  x41 = code_word1[0];
end

// code_word2 received message
always @(*) begin
  p12 = code_word2[6];
  p22 = code_word2[5];
  p32 = code_word2[4];
  x12 = code_word2[3];
  x22 = code_word2[2];
  x32 = code_word2[1];
  x42 = code_word2[0];
end

// code_word1 circle
always @(*) begin
  circle11 = p11 ^ x11 ^ x21 ^ x31;
  circle21 = p21 ^ x11 ^ x21 ^ x41;
  circle31 = p31 ^ x11 ^ x31 ^ x41;
end

// code_word2 circle
always @(*) begin
  circle12 = p12 ^ x12 ^ x22 ^ x32;
  circle22 = p22 ^ x12 ^ x22 ^ x42;
  circle32 = p32 ^ x12 ^ x32 ^ x42;
end

// circle1, circle2
always @(*) begin
  circle1 = {circle11, circle21, circle31};
  circle2 = {circle12, circle22, circle32};
end

// error_bit1_neg, error_bit2_neg
always @(*) begin
  error_bit1_neg = ~error_bit1;
  error_bit2_neg = ~error_bit2;
end

// error_bit1, c1
always @(*) begin
  c1 = code_word1[3:0];
  casez(circle1)
    3'b110: begin
      error_bit1 = x21;
      c1[2] = error_bit1_neg;
    end
    3'b101: begin
      error_bit1 = x31;
      c1[1] = error_bit1_neg;
    end
    3'b011: begin
      error_bit1 = x41;
      c1[0] = error_bit1_neg;
    end
    3'b111: begin
      error_bit1 = x11;
      c1[3] = error_bit1_neg;
    end
    3'b100: begin
      error_bit1 = p11;
    end
    3'b010: begin
      error_bit1 = p21;
    end
    3'b00?: begin
      error_bit1 = p31;
    end
  endcase
  c1_mult_2 = {c1, 1'b0};
end


// error_bit2, c2
always @(*) begin
  c2 = code_word2[3:0];
  casez(circle2)
    3'b110: begin
      error_bit2 = x22;
      c2[2] = error_bit2_neg;
    end
    3'b101: begin
      error_bit2 = x32;
      c2[1] = error_bit2_neg;
    end
    3'b011: begin
      error_bit2 = x42;
      c2[0] = error_bit2_neg;
    end
    3'b111: begin
      error_bit2 = x12;
      c2[3] = error_bit2_neg;
    end
    3'b100: begin
      error_bit2 = p12;
    end
    3'b010: begin
      error_bit2 = p22;
    end
    3'b00?: begin
      error_bit2 = p32;
    end
  endcase
  c2_mult_2 = {c2, 1'b0};
end

// augend, addend, sub
always @(*) begin
  if (error_bit1) begin
    augend = c1;
    addend = c2_mult_2;
    sub    = error_bit2_neg;
  end
  else begin
    augend = c1_mult_2;
    addend = c2;
    sub    = error_bit2;
  end
end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                      6 bit adder_substractor                                                          //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

wire        [5:0] addend_xor_sub;
wire              C1;
wire              C2;
wire              C3;
wire              C4;
wire              C5;
wire        [5:0] augend_xor_addend_xor_sub;
wire        [5:0] augend_and_addend_xor_sub;
wire        [5:0] augend_xor_addend_xor_sub_and_cin;

assign addend_xor_sub[0] = addend[0] ^ sub;
assign addend_xor_sub[1] = addend[1] ^ sub;
assign addend_xor_sub[2] = addend[2] ^ sub;
assign addend_xor_sub[3] = addend[3] ^ sub;
assign addend_xor_sub[4] = addend[4] ^ sub;
assign addend_xor_sub[5] = addend[5] ^ sub;

assign augend_xor_addend_xor_sub = augend ^ addend_xor_sub;
assign augend_and_addend_xor_sub = augend & addend_xor_sub;

assign augend_xor_addend_xor_sub_and_cin[0] = augend_xor_addend_xor_sub[0] & sub;
assign C1 = augend_xor_addend_xor_sub_and_cin[0] | augend_and_addend_xor_sub[0];

assign augend_xor_addend_xor_sub_and_cin[1] = augend_xor_addend_xor_sub[1] & C1;
assign C2 = augend_xor_addend_xor_sub_and_cin[1] | augend_and_addend_xor_sub[1];

assign augend_xor_addend_xor_sub_and_cin[2] = augend_xor_addend_xor_sub[2] & C2;
assign C3 = augend_xor_addend_xor_sub_and_cin[2] | augend_and_addend_xor_sub[2];

assign augend_xor_addend_xor_sub_and_cin[3] = augend_xor_addend_xor_sub[3] & C3;
assign C4 = augend_xor_addend_xor_sub_and_cin[3] | augend_and_addend_xor_sub[3];

assign augend_xor_addend_xor_sub_and_cin[4] = augend_xor_addend_xor_sub[4] & C4;
assign C5 = augend_xor_addend_xor_sub_and_cin[4] | augend_and_addend_xor_sub[4];

assign augend_xor_addend_xor_sub_and_cin[5] = augend_xor_addend_xor_sub[5] & C5;

assign out_n[0] = augend_xor_addend_xor_sub[0] ^ sub;
assign out_n[1] = augend_xor_addend_xor_sub[1] ^ C1;
assign out_n[2] = augend_xor_addend_xor_sub[2] ^ C2;
assign out_n[3] = augend_xor_addend_xor_sub[3] ^ C3;
assign out_n[4] = augend_xor_addend_xor_sub[4] ^ C4;
assign out_n[5] = augend_xor_addend_xor_sub[5] ^ C5;


endmodule

