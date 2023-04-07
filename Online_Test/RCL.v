module RCL(
    clk,
    rst_n,
    in_valid,
    coef_Q,
    coef_L,
    out_valid,
    out
);

input                   clk;
input                   rst_n;
input                   in_valid;
input       [ 4:0]      coef_Q;
input       [ 4:0]      coef_L;
output reg              out_valid;
output reg  [ 1:0]      out;

localparam IDLE                = 3'd0;
localparam STORE               = 3'd1;
localparam MULT                = 3'd2;
localparam ADD                 = 3'd3;
localparam MULT2               = 3'd4;
localparam COMP                = 3'd5;
localparam OUT                 = 3'd6;

reg         [ 2:0] current_state;
reg         [ 2:0] next_state;

reg                out_valid_ns;
reg         [ 1:0] out_ns;

reg  signed [ 4:0] m_cs;
reg  signed [ 4:0] m_ns;

reg  signed [ 4:0] n_cs;
reg  signed [ 4:0] n_ns;

reg         [ 4:0] k_cs;
reg         [ 4:0] k_ns;

reg  signed [ 4:0] a_cs;
reg  signed [ 4:0] a_ns;

reg  signed [ 4:0] b_cs;
reg  signed [ 4:0] b_ns;

reg  signed [ 4:0] c_cs;
reg  signed [ 4:0] c_ns;

reg                flag_cs;
reg                flag_ns;

reg  signed [ 9:0] aa_cs;
reg  signed [ 9:0] aa_ns;

reg  signed [ 9:0] bb_cs;
reg  signed [ 9:0] bb_ns;

reg  signed [ 9:0] am_cs;
reg  signed [ 9:0] am_ns;

reg  signed [ 9:0] bn_cs;
reg  signed [ 9:0] bn_ns;


reg  signed [10:0] sum_den_cs;
reg  signed [10:0] sum_den_ns;

reg  signed [10:0] sum_num_cs;
reg  signed [10:0] sum_num_ns;

reg  signed [21:0] lhs_cs;
reg  signed [21:0] lhs_ns;

reg  signed [21:0] rhs_cs;
reg  signed [21:0] rhs_ns;



// state register
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    current_state <= IDLE;
  end
  else begin
    current_state <= next_state;
  end
end

// next state logic
always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid) begin
        next_state = STORE;
      end
      else begin
        next_state = IDLE;
      end
    end
    STORE: begin
      if (flag_cs) begin
        next_state = MULT;
      end
      else begin
        next_state = STORE;
      end
    end
    MULT: begin
      next_state = ADD;
    end
    ADD: begin
      next_state = MULT2;
    end
		MULT2: begin
      next_state = COMP;
    end
		COMP: begin
      next_state = OUT;
    end
		OUT: begin
      next_state = IDLE;
		end
    default: begin
      next_state = IDLE;
    end
  endcase
end




/////////////////////////////////////////////////////m,a
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    m_cs <= 'd0;
		a_cs <= 'd0;
  end
  else begin
    m_cs <= m_ns;
		a_cs <= a_ns;
  end
end

always @(*) begin
  case(current_state)
    IDLE: begin
      if (in_valid) begin
        m_ns = coef_Q;
				a_ns = coef_L;
      end
      else begin
        m_ns = m_cs;
				a_ns = a_cs;
      end
    end
    default: begin
        m_ns = m_cs;
				a_ns = a_cs;
    end
  endcase
end




/////////////////////////////////////////////////////n,b
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    n_cs <= 'd0;
		b_cs <= 'd0;
  end
  else begin
    n_cs <= n_ns;
		b_cs <= b_ns;
  end
end

always @(*) begin
  case(current_state)
    STORE: begin
      if (flag_cs) begin
        n_ns = n_cs;
				b_ns = b_cs;
      end
      else begin
        n_ns = coef_Q;
				b_ns = coef_L;
      end
    end
    default: begin
        n_ns = n_cs;
				b_ns = b_cs;
    end
  endcase
end




/////////////////////////////////////////////////////k,c
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    k_cs <= 'd0;
		c_cs <= 'd0;
  end
  else begin
    k_cs <= k_ns;
		c_cs <= c_ns;
  end
end

always @(*) begin
  case(current_state)
    STORE: begin
      if (flag_cs) begin
        k_ns = coef_Q;
				c_ns = coef_L;
      end
      else begin
        k_ns = k_cs;
				c_ns = c_cs;
      end
    end
    default: begin
        k_ns = k_cs;
				c_ns = c_cs;
    end
  endcase
end


/////////////////////////////////////////////////////flag
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    flag_cs <= 'd0;
  end
  else begin
    flag_cs <= flag_ns;
  end
end

always @(*) begin
  case(current_state)
    STORE: begin
      flag_ns = 1;
    end
    default: begin
      flag_ns = 0;
    end
  endcase
end









/////////////////////////////////////////////////////aa,bb,am,bn
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    aa_cs <= 'd0;
    bb_cs <= 'd0;
    am_cs <= 'd0;
    bn_cs <= 'd0;
  end
  else begin
    aa_cs <= aa_ns;
    bb_cs <= bb_ns;
    am_cs <= am_ns;
    bn_cs <= bn_ns;
  end
end

always @(*) begin
  case(current_state)
    MULT: begin
			aa_ns = a_cs * a_cs;
			bb_ns = b_cs * b_cs;
			am_ns = a_cs * m_cs;
			bn_ns = b_cs * n_cs;
    end
    default: begin
			aa_ns = aa_cs;
			bb_ns = bb_cs;
			am_ns = am_cs;
			bn_ns = bn_cs;
    end
  endcase
end





/////////////////////////////////////////////////////sum_den, sum_num
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    sum_den_cs <= 'd0;
		sum_num_cs <= 'd0;
  end
  else begin
    sum_den_cs <= sum_den_ns;
		sum_num_cs <= sum_num_ns;
  end
end

always @(*) begin
  case(current_state)
    ADD: begin
			sum_den_ns = aa_cs + bb_cs;
			sum_num_ns = am_cs + bn_cs + c_cs;
    end
    default: begin
			sum_den_ns = sum_den_cs;
			sum_num_ns = sum_num_cs;
    end
  endcase
end




/////////////////////////////////////////////////////lhs,rhs
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    lhs_cs <= 'd0;
    rhs_cs <= 'd0;
  end
  else begin
    lhs_cs <= lhs_ns;
    rhs_cs <= rhs_ns;
  end
end

always @(*) begin
  case(current_state)
    MULT2: begin
			lhs_ns = sum_num_cs * sum_num_cs;
			rhs_ns = sum_den_cs * {{6{1'b0}}, k_cs};
    end
    default: begin
			lhs_ns = lhs_cs;
			rhs_ns = rhs_cs;
    end
  endcase
end



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
    COMP: begin
      out_valid_ns = 1'b1;
		end
    default: begin
      out_valid_ns = 1'b0;
    end
  endcase
end


// out
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    out <= 'd0;
  end
  else begin
    out <= out_ns;
  end
end

always @(*) begin
  case(current_state)
    COMP: begin
      if (lhs_cs == rhs_cs) begin
				out_ns = 2'd1;
			end
			else if (lhs_cs < rhs_cs) begin
				out_ns = 2'd2;
			end
			else begin
				out_ns = 2'd0;
			end
		end
    default: begin
      out_ns = 2'd0;
    end
  endcase
end





endmodule
