module CHIP(    
    // Input signals
    clk,
    clk2,
    rst_n,
    in_valid,
    op_valid,
    pic_data,
    se_data,
    op,
    
    // Output signals
    out_valid,
    out_data
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input               clk;
input               clk2;
input               rst_n;
input               in_valid;
input               op_valid;
input       [31:0]  pic_data;
input       [ 7:0]  se_data;
input       [ 2:0]  op;

output              out_valid;
output      [31:0]  out_data;

wire                C_clk;
wire                C_clk2;
wire                C_rst_n;
wire                C_in_valid;
wire                C_op_valid;
wire        [31:0]  C_pic_data;
wire        [ 7:0]  C_se_data;
wire        [ 2:0]  C_op;

wire                C_out_valid;
wire        [31:0]  C_out_data;


wire                BUF_clk;
wire                BUF_clk2;

CLKBUFX20 buf0(.A(C_clk),.Y(BUF_clk));
CLKBUFX20 buf1(.A(C_clk2),.Y(BUF_clk2));


MH CORE(
    .clk(BUF_clk),
    .clk2(BUF_clk2),
    .rst_n(C_rst_n),
    .in_valid(C_in_valid),
    .op_valid(C_op_valid),
    .pic_data(C_pic_data),
    .se_data(C_se_data),
    .op(C_op),
    
    .out_valid(C_out_valid),
    .out_data(C_out_data)
);


P8C I_CLK          ( .Y(C_clk),            .P(clk),            .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b0), .CSEN(1'b1) );
P8C I_CLK2         ( .Y(C_clk2),           .P(clk2),           .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b0), .CSEN(1'b1) );
P8C I_RESET        ( .Y(C_rst_n),          .P(rst_n),          .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_VALID        ( .Y(C_in_valid),       .P(in_valid),       .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_OPVALID      ( .Y(C_op_valid),       .P(op_valid),       .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA0     ( .Y(C_pic_data[ 0]),   .P(pic_data[ 0]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA1     ( .Y(C_pic_data[ 1]),   .P(pic_data[ 1]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA2     ( .Y(C_pic_data[ 2]),   .P(pic_data[ 2]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA3     ( .Y(C_pic_data[ 3]),   .P(pic_data[ 3]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA4     ( .Y(C_pic_data[ 4]),   .P(pic_data[ 4]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA5     ( .Y(C_pic_data[ 5]),   .P(pic_data[ 5]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA6     ( .Y(C_pic_data[ 6]),   .P(pic_data[ 6]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA7     ( .Y(C_pic_data[ 7]),   .P(pic_data[ 7]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA8     ( .Y(C_pic_data[ 8]),   .P(pic_data[ 8]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA9     ( .Y(C_pic_data[ 9]),   .P(pic_data[ 9]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA10    ( .Y(C_pic_data[10]),   .P(pic_data[10]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA11    ( .Y(C_pic_data[11]),   .P(pic_data[11]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA12    ( .Y(C_pic_data[12]),   .P(pic_data[12]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA13    ( .Y(C_pic_data[13]),   .P(pic_data[13]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA14    ( .Y(C_pic_data[14]),   .P(pic_data[14]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA15    ( .Y(C_pic_data[15]),   .P(pic_data[15]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA16    ( .Y(C_pic_data[16]),   .P(pic_data[16]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA17    ( .Y(C_pic_data[17]),   .P(pic_data[17]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA18    ( .Y(C_pic_data[18]),   .P(pic_data[18]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA19    ( .Y(C_pic_data[19]),   .P(pic_data[19]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA20    ( .Y(C_pic_data[20]),   .P(pic_data[20]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA21    ( .Y(C_pic_data[21]),   .P(pic_data[21]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA22    ( .Y(C_pic_data[22]),   .P(pic_data[22]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA23    ( .Y(C_pic_data[23]),   .P(pic_data[23]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA24    ( .Y(C_pic_data[24]),   .P(pic_data[24]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA25    ( .Y(C_pic_data[25]),   .P(pic_data[25]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA26    ( .Y(C_pic_data[26]),   .P(pic_data[26]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA27    ( .Y(C_pic_data[27]),   .P(pic_data[27]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA28    ( .Y(C_pic_data[28]),   .P(pic_data[28]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA29    ( .Y(C_pic_data[29]),   .P(pic_data[29]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA30    ( .Y(C_pic_data[30]),   .P(pic_data[30]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_PICDATA31    ( .Y(C_pic_data[31]),   .P(pic_data[31]),   .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_SEDATA0      ( .Y(C_se_data[ 0]),    .P(se_data[ 0]),    .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_SEDATA1      ( .Y(C_se_data[ 1]),    .P(se_data[ 1]),    .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_SEDATA2      ( .Y(C_se_data[ 2]),    .P(se_data[ 2]),    .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_SEDATA3      ( .Y(C_se_data[ 3]),    .P(se_data[ 3]),    .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_SEDATA4      ( .Y(C_se_data[ 4]),    .P(se_data[ 4]),    .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_SEDATA5      ( .Y(C_se_data[ 5]),    .P(se_data[ 5]),    .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_SEDATA6      ( .Y(C_se_data[ 6]),    .P(se_data[ 6]),    .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_SEDATA7      ( .Y(C_se_data[ 7]),    .P(se_data[ 7]),    .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_OP0          ( .Y(C_op[0]),          .P(op[0]),          .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_OP1          ( .Y(C_op[1]),          .P(op[1]),          .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );
P4C I_OP2          ( .Y(C_op[2]),          .P(op[2]),          .A(1'b0), .ODEN(1'b0), .OCEN(1'b0), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0) );


P8C O_VALID        ( .A(C_out_valid),      .P(out_valid),    .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA0     ( .A(C_out_data[ 0]),   .P(out_data[ 0]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA1     ( .A(C_out_data[ 1]),   .P(out_data[ 1]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA2     ( .A(C_out_data[ 2]),   .P(out_data[ 2]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA3     ( .A(C_out_data[ 3]),   .P(out_data[ 3]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA4     ( .A(C_out_data[ 4]),   .P(out_data[ 4]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA5     ( .A(C_out_data[ 5]),   .P(out_data[ 5]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA6     ( .A(C_out_data[ 6]),   .P(out_data[ 6]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA7     ( .A(C_out_data[ 7]),   .P(out_data[ 7]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA8     ( .A(C_out_data[ 8]),   .P(out_data[ 8]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA9     ( .A(C_out_data[ 9]),   .P(out_data[ 9]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA10    ( .A(C_out_data[10]),   .P(out_data[10]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA11    ( .A(C_out_data[11]),   .P(out_data[11]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA12    ( .A(C_out_data[12]),   .P(out_data[12]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA13    ( .A(C_out_data[13]),   .P(out_data[13]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA14    ( .A(C_out_data[14]),   .P(out_data[14]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA15    ( .A(C_out_data[15]),   .P(out_data[15]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA16    ( .A(C_out_data[16]),   .P(out_data[16]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA17    ( .A(C_out_data[17]),   .P(out_data[17]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA18    ( .A(C_out_data[18]),   .P(out_data[18]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA19    ( .A(C_out_data[19]),   .P(out_data[19]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA20    ( .A(C_out_data[20]),   .P(out_data[20]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA21    ( .A(C_out_data[21]),   .P(out_data[21]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA22    ( .A(C_out_data[22]),   .P(out_data[22]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA23    ( .A(C_out_data[23]),   .P(out_data[23]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA24    ( .A(C_out_data[24]),   .P(out_data[24]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA25    ( .A(C_out_data[25]),   .P(out_data[25]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA26    ( .A(C_out_data[26]),   .P(out_data[26]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA27    ( .A(C_out_data[27]),   .P(out_data[27]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA28    ( .A(C_out_data[28]),   .P(out_data[28]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA29    ( .A(C_out_data[29]),   .P(out_data[29]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA30    ( .A(C_out_data[30]),   .P(out_data[30]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));
P8C O_OUTDATA31    ( .A(C_out_data[31]),   .P(out_data[31]), .ODEN(1'b1), .OCEN(1'b1), .PU(1'b1), .PD(1'b0), .CEN(1'b1), .CSEN(1'b0));

//I/O power 3.3V pads x? (DVDD + DGND)
PVDDR VDDP0 ();
PVSSR GNDP0 ();
PVDDR VDDP1 ();
PVSSR GNDP1 ();
PVDDR VDDP2 ();
PVSSR GNDP2 ();
PVDDR VDDP3 ();
PVSSR GNDP3 ();
PVDDR VDDP4 ();
PVSSR GNDP4 ();
PVDDR VDDP5 ();
PVSSR GNDP5 ();
PVDDR VDDP6 ();
PVSSR GNDP6 ();
PVDDR VDDP7 ();
PVSSR GNDP7 ();

//Core poweri 1.8V pads x? (VDD + GND)
PVDDC VDDC0 ();
PVSSC GNDC0 ();
PVDDC VDDC1 ();
PVSSC GNDC1 ();
PVDDC VDDC2 ();
PVSSC GNDC2 ();
PVDDC VDDC3 ();
PVSSC GNDC3 ();

endmodule