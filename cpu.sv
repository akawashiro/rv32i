module pc (
    input logic clk,
    input logic reset,
    input logic [31:0] pc_in,
    output logic [31:0] pc_out
);
  always_ff @(posedge clk) begin
    if (reset) begin
      pc_out <= 0;
    end else begin
      pc_out <= pc_in;
    end
  end
endmodule

module pc_plus_4 (
    input  logic [31:0] pc_in,
    output logic [31:0] pc_out
);
  assign pc_out = pc_in + 4;
endmodule

module instruction_memory (
    input  logic [31:0] pc,
    output logic [31:0] instruction,
    input  logic [31:0] initial_instructions[32]
);
  logic [31:0] rom[32];

  genvar i;
  generate
    for (i = 0; i < 32; i = i + 1) begin : g_fill_rom
      assign rom[i] = initial_instructions[i];
    end
  endgenerate

  assign instruction = rom[pc[6:2]];
endmodule

module memory (
    input logic [31:0] address,
    input logic [31:0] data_in,
    input logic write_enable,
    input logic clk,
    input logic reset,
    output logic [31:0] data_out,
    input logic [31:0] initial_values[32],
    output logic [31:0] memory_check[32]
);
  logic [31:0] mem[32];
  logic [31:0] effective_address;
  assign effective_address = {2'b00, address[31:2]};

  always_comb begin
    data_out = mem[effective_address];
    for (int j = 0; j < 32; j = j + 1) begin
      memory_check[j] = mem[j];
    end
  end

  always_ff @(posedge clk)
    if (reset) begin
      for (int i = 0; i < 32; i = i + 1) begin
        mem[i] <= initial_values[i];
      end
    end else begin
      if (write_enable) begin
        mem[effective_address] <= data_in;
      end
    end
endmodule

module register_file (
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic [31:0] data_in,
    input logic clk,
    input logic reset,
    input logic write_enable,
    output logic [31:0] data_out1,
    output logic [31:0] data_out2,
    input logic [31:0] initial_values[32],
    output logic [31:0] register_check[32]
);
  logic [31:0] registers[32];

  always_comb begin
    registers[0] = 0;
    data_out1 = registers[rs1];
    data_out2 = registers[rs2];
    for (int j = 0; j < 32; j = j + 1) begin
      register_check[j] = registers[j];
    end
  end

  always_ff @(posedge clk)
    if (reset) begin
      for (int i = 1; i < 32; i = i + 1) begin
        registers[i] <= initial_values[i];
      end
    end else begin
      if (write_enable && rd[4:0] != 0) begin
        registers[rd[4:0]] <= data_in;
      end
    end
endmodule

typedef enum logic [3:0] {
  ADD,
  SUB,
  AND,
  OR,
  XOR,
  SLL,
  SRL,
  SRA,
  SLT,
  BPASS  // For lui
} alu_op_t;

module alu (
    input logic signed [31:0] a,
    input logic signed [31:0] b,
    input logic [3:0] alu_op,
    output logic [31:0] result,
    output logic alu_eq
);
  always_comb begin
    case (alu_op)
      ADD: result = a + b;
      SUB: result = a - b;
      AND: result = a & b;
      OR: result = a | b;
      XOR: result = a ^ b;
      SLL: result = a << b;
      SRL: result = a >> b;
      SRA: result = a >>> b;
      SLT: result = (a < b) ? 1 : 0;
      BPASS: result = b;
      default: result = 0;
    endcase
    alu_eq = (a == b) ? 1 : 0;
  end
endmodule

typedef enum logic [2:0] {
  ADDI_SIGN_EXTEND,
  SLLI_SIGN_EXTEND,
  SW_SIGN_EXTEND,
  LUI_SIGN_EXTEND
} sign_extend_t;

module sign_extend (
    input  logic [31:0] instruction,
    input  logic [ 2:0] sign_extend_type,
    output logic [31:0] imm_ext
);
  logic [31:0] addi_imm_ext;
  logic [31:0] slli_imm_ext;
  logic [31:0] sw_imm_ext;
  logic [31:0] lui_imm_ext;

  assign addi_imm_ext = {{20{instruction[31]}}, instruction[31:20]};
  assign slli_imm_ext = {{27{1'b0}}, instruction[24:20]};
  assign sw_imm_ext   = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
  assign lui_imm_ext  = {instruction[31:12], 12'b0};

  always_comb begin
    case (sign_extend_type)
      ADDI_SIGN_EXTEND: imm_ext = addi_imm_ext;
      SLLI_SIGN_EXTEND: imm_ext = slli_imm_ext;
      SW_SIGN_EXTEND: imm_ext = sw_imm_ext;
      LUI_SIGN_EXTEND: imm_ext = lui_imm_ext;
      default: imm_ext = 0;
    endcase
  end
endmodule

typedef enum logic [6:0] {
  ALU_WITH_TWO_REGISTERS = 7'b0110011,
  ALU_WITH_IMMEDIATE = 7'b0010011,
  LUI = 7'b0110111,
  LW = 7'b0000011,
  SW = 7'b0100011,
  JAL = 7'b1101111,
  JALR = 7'b1100111,
  BEQ = 7'b1100011
} opcode_t;

module control_unit (
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic alu_eq,
    output logic [3:0] alu_op,
    output logic [0:0] reg_write,
    output logic use_imm,
    output logic [1:0] register_data_in_mux_sel,
    output logic [2:0] sign_extend_type,
    output logic [0:0] memory_write,
    output logic [2:0] pc_in_mux_sel
);
  always_comb begin
    case (opcode)
      BEQ: begin
        alu_op = BPASS;
        reg_write = 0;
        use_imm = 0;
        sign_extend_type = ADDI_SIGN_EXTEND;
        register_data_in_mux_sel = REGISTER_DATA_IN_MUX_PC_PLUS_4;
        unique case (alu_eq)
          1'b0: begin
            case (funct3)
              3'b000:  pc_in_mux_sel = PC_IN_MUX_PC_PLUS_4;  // BEQ
              3'b001:  pc_in_mux_sel = PC_IN_MUX_BEQ_OR_BNE_ADDR;  // BNE
              default: pc_in_mux_sel = PC_IN_MUX_PC_PLUS_4;
            endcase
          end
          1'b1: begin
            case (funct3)
              3'b000:  pc_in_mux_sel = PC_IN_MUX_BEQ_OR_BNE_ADDR;  // BEQ
              3'b001:  pc_in_mux_sel = PC_IN_MUX_PC_PLUS_4;  // BNE
              default: pc_in_mux_sel = PC_IN_MUX_PC_PLUS_4;
            endcase
          end
          default: pc_in_mux_sel = PC_IN_MUX_PC_PLUS_4;
        endcase
      end
      JAL: begin
        alu_op = BPASS;
        reg_write = 1;
        use_imm = 0;
        sign_extend_type = ADDI_SIGN_EXTEND;
        register_data_in_mux_sel = REGISTER_DATA_IN_MUX_PC_PLUS_4;
        pc_in_mux_sel = PC_IN_MUX_JAL_ADDR;
      end
      JALR: begin
        alu_op = ADD;
        reg_write = 1;
        use_imm = 1;
        sign_extend_type = ADDI_SIGN_EXTEND;
        register_data_in_mux_sel = REGISTER_DATA_IN_MUX_PC_PLUS_4;
        pc_in_mux_sel = PC_IN_MUX_ALU_RESULT;
      end
      ALU_WITH_TWO_REGISTERS: begin
        unique case (funct3)
          3'b000: begin
            case (funct7)
              7'b0000000: alu_op = ADD;
              7'b0100000: alu_op = SUB;
              default: alu_op = ADD;
            endcase
          end
          3'b001:  alu_op = SLL;
          3'b010:  alu_op = SLT;
          3'b011:  alu_op = SLT;
          3'b100:  alu_op = XOR;
          3'b101:  alu_op = SRL;
          3'b110:  alu_op = OR;
          3'b111:  alu_op = AND;
          default: alu_op = ADD;
        endcase
        reg_write = 1;
        use_imm = 0;
        register_data_in_mux_sel = REGISTER_DATA_IN_MUX_ALU_RESULT;
        pc_in_mux_sel = PC_IN_MUX_PC_PLUS_4;
      end
      ALU_WITH_IMMEDIATE: begin
        case (funct3)
          3'b000: begin
            alu_op = ADD;
            sign_extend_type = ADDI_SIGN_EXTEND;
          end
          3'b001: begin
            alu_op = SLL;
            sign_extend_type = SLLI_SIGN_EXTEND;
          end
          3'b100: begin
            alu_op = XOR;
            sign_extend_type = ADDI_SIGN_EXTEND;
          end
          3'b101: begin
            case (funct7)
              7'b0000000: alu_op = SRL;
              7'b0100000: alu_op = SRA;
              default: alu_op = SRL;
            endcase
            sign_extend_type = SLLI_SIGN_EXTEND;
          end
          3'b110: begin
            alu_op = OR;
            sign_extend_type = ADDI_SIGN_EXTEND;
          end
          3'b111: begin
            alu_op = AND;
            sign_extend_type = ADDI_SIGN_EXTEND;
          end
          default: begin
            alu_op = ADD;
            sign_extend_type = ADDI_SIGN_EXTEND;
          end
        endcase
        reg_write = 1;
        use_imm = 1;
        register_data_in_mux_sel = REGISTER_DATA_IN_MUX_ALU_RESULT;
        pc_in_mux_sel = PC_IN_MUX_PC_PLUS_4;
      end
      LUI: begin
        alu_op = BPASS;
        reg_write = 1;
        use_imm = 1;
        sign_extend_type = LUI_SIGN_EXTEND;
        register_data_in_mux_sel = REGISTER_DATA_IN_MUX_ALU_RESULT;
        pc_in_mux_sel = PC_IN_MUX_PC_PLUS_4;
      end
      LW: begin
        alu_op = ADD;
        reg_write = 1;
        use_imm = 1;
        sign_extend_type = ADDI_SIGN_EXTEND;
        register_data_in_mux_sel = REGISTER_DATA_IN_MUX_MEMORY_DATA;
        pc_in_mux_sel = PC_IN_MUX_PC_PLUS_4;
      end
      SW: begin
        alu_op = ADD;
        reg_write = 0;
        use_imm = 1;
        sign_extend_type = SW_SIGN_EXTEND;
        register_data_in_mux_sel = REGISTER_DATA_IN_MUX_MEMORY_DATA;
        memory_write = 1;
        pc_in_mux_sel = PC_IN_MUX_PC_PLUS_4;
      end
      default: begin
        alu_op = ADD;
        reg_write = 0;
        use_imm = 0;
        sign_extend_type = ADDI_SIGN_EXTEND;
        register_data_in_mux_sel = REGISTER_DATA_IN_MUX_PC_PLUS_4;
        pc_in_mux_sel = PC_IN_MUX_PC_PLUS_4;
      end
    endcase
  end
endmodule


module b_input_mux (
    input logic [31:0] register_data_out2,
    input logic [31:0] imm_ext,
    input logic use_imm,
    output logic [31:0] b_input
);
  assign b_input = use_imm ? imm_ext : register_data_out2;
endmodule

typedef enum logic [1:0] {
  REGISTER_DATA_IN_MUX_ALU_RESULT,
  REGISTER_DATA_IN_MUX_MEMORY_DATA,
  REGISTER_DATA_IN_MUX_PC_PLUS_4
} register_data_in_mux_sel_t;

module register_data_in_mux (
    input  logic [31:0] alu_result,
    input  logic [31:0] memory_data,
    input  logic [31:0] pc_plus_4,
    input  logic [ 1:0] register_data_in_mux_sel,
    output logic [31:0] register_data_in
);
  always_comb begin
    case (register_data_in_mux_sel)
      REGISTER_DATA_IN_MUX_ALU_RESULT: register_data_in = alu_result;
      REGISTER_DATA_IN_MUX_MEMORY_DATA: register_data_in = memory_data;
      REGISTER_DATA_IN_MUX_PC_PLUS_4: register_data_in = pc_plus_4;
      default: register_data_in = 0;
    endcase
  end
endmodule

module jal_addr (
    input  logic [31:0] pc,
    input  logic [31:0] instruction,
    output logic [31:0] jal_imm_check,
    output logic [31:0] jal_addr
);
  logic [31:0] jal_imm;
  assign jal_imm = {
    {12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0
  };
  assign jal_imm_check = jal_imm;
  assign jal_addr = pc + jal_imm;
endmodule

module beq_or_bne_addr (
    input  logic [31:0] pc,
    input  logic [31:0] instruction,
    input  logic [31:0] imm_ext,
    output logic [31:0] beq_or_bne_addr
);
  logic [31:0] beq_or_bne_imm = {
    12'b0, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0
  };
  assign beq_or_bne_addr = pc + beq_or_bne_imm;
endmodule

typedef enum logic [2:0] {
  PC_IN_MUX_PC_PLUS_4,
  PC_IN_MUX_JAL_ADDR,
  PC_IN_MUX_ALU_RESULT,
  PC_IN_MUX_BEQ_OR_BNE_ADDR
} pc_in_mux_sel_t;

module pc_in_mux (
    input  logic [31:0] pc_plus_4,
    input  logic [31:0] jal_addr,
    input  logic [31:0] alu_result,
    input  logic [31:0] beq_or_bne_addr,
    input  logic [ 2:0] pc_in_mux_sel,
    output logic [31:0] pc_in
);
  always_comb begin
    unique case (pc_in_mux_sel)
      PC_IN_MUX_PC_PLUS_4: pc_in = pc_plus_4;
      PC_IN_MUX_JAL_ADDR: pc_in = jal_addr;
      PC_IN_MUX_ALU_RESULT: pc_in = alu_result;
      PC_IN_MUX_BEQ_OR_BNE_ADDR: pc_in = beq_or_bne_addr;
      default: pc_in = 0;
    endcase
  end
endmodule

module cpu (
    input logic clk,
    input logic reset,
    input logic [31:0] initial_instructions[32],
    input logic [31:0] initial_register_values[32],
    input logic [31:0] initial_memory_values[32],
    output logic [31:0] pc_out_check,
    output logic [31:0] instruction_check,
    output logic [3:0] alu_op_check,
    output logic [31:0] register_data_out1_check,
    output logic [31:0] register_data_out2_check,
    output logic [31:0] b_input_check,
    output logic [31:0] register_data_in_check,
    output logic [31:0] alu_result_check,
    output logic [0:0] reg_write_check,
    output logic [31:0] imm_ext_check,
    output logic [0:0] use_imm_check,
    output wire [31:0] register_check[32],
    output wire [31:0] memory_check[32],
    output logic [2:0] sign_extend_type_check
);
  logic [31:0] pc_in;
  logic [31:0] register_data_in;
  logic [31:0] imm_ext;
  logic [ 0:0] use_imm;
  logic [ 2:0] sign_extend_type;

  pc pc_0 (
      .clk(clk),
      .reset(reset),
      .pc_in(pc_in)
  );
  assign pc_out_check = pc_0.pc_out;

  pc_plus_4 pc_plus_4_0 (.pc_in(pc_0.pc_out));

  jal_addr jal_addr_0 (
      .pc(pc_0.pc_out),
      .instruction(instruction_memory_0.instruction)
  );

  beq_or_bne_addr beq_or_bne_addr_0 (
      .pc(pc_0.pc_out),
      .instruction(instruction_memory_0.instruction),
      .imm_ext(imm_ext)
  );

  pc_in_mux pc_in_mux_0 (
      .pc_plus_4(pc_plus_4_0.pc_out),
      .jal_addr(jal_addr_0.jal_addr),
      .alu_result(alu_0.result),
      .beq_or_bne_addr(beq_or_bne_addr_0.beq_or_bne_addr),
      .pc_in_mux_sel(control_unit_0.pc_in_mux_sel),
      .pc_in(pc_in)
  );

  instruction_memory instruction_memory_0 (
      .pc(pc_0.pc_out),
      .initial_instructions(initial_instructions)
  );
  assign instruction_check = instruction_memory_0.instruction;

  control_unit control_unit_0 (
      .opcode(instruction_memory_0.instruction[6:0]),
      .funct3(instruction_memory_0.instruction[14:12]),
      .funct7(instruction_memory_0.instruction[31:25]),
      .alu_op(alu_op),
      .alu_eq(alu_0.alu_eq),
      .use_imm(use_imm),
      .sign_extend_type(sign_extend_type)
  );
  assign alu_op_check = control_unit_0.alu_op;
  assign reg_write_check = control_unit_0.reg_write;
  assign use_imm_check = use_imm;
  assign sign_extend_type_check = sign_extend_type;

  sign_extend sign_extend_0 (
      .instruction(instruction_memory_0.instruction),
      .sign_extend_type(sign_extend_type),
      .imm_ext(imm_ext)
  );
  assign imm_ext_check = imm_ext;

  register_file register_file_0 (
      .rs1(instruction_memory_0.instruction[19:15]),
      .rs2(instruction_memory_0.instruction[24:20]),
      .rd(instruction_memory_0.instruction[11:7]),
      .data_in(register_data_in),
      .clk(clk),
      .reset(reset),
      .write_enable(control_unit_0.reg_write),
      .register_check(register_check),
      .initial_values(initial_register_values)
  );
  assign register_data_out1_check = register_file_0.data_out1;
  assign register_data_out2_check = register_file_0.data_out2;
  assign register_data_in_check   = register_data_in;

  logic [31:0] b_input;
  b_input_mux b_input_mux_0 (
      .register_data_out2(register_file_0.data_out2),
      .imm_ext(imm_ext),
      .use_imm(use_imm),
      .b_input(b_input)
  );
  assign b_input_check = b_input;

  alu alu_0 (
      .a(register_file_0.data_out1),
      .b(b_input),
      .alu_op(control_unit_0.alu_op)
  );
  assign alu_result_check = alu_0.result;

  logic [31:0] memory_data;

  memory memory_0 (
      .address(alu_0.result),
      .data_in(register_file_0.data_out2),
      .write_enable(control_unit_0.memory_write),
      .clk(clk),
      .reset(reset),
      .data_out(memory_data),
      .initial_values(initial_memory_values),
      .memory_check(memory_check)
  );

  register_data_in_mux register_data_in_mux_0 (
      .alu_result(alu_0.result),
      .memory_data(memory_data),
      .pc_plus_4(pc_plus_4_0.pc_out),
      .register_data_in_mux_sel(control_unit_0.register_data_in_mux_sel),
      .register_data_in(register_data_in)
  );
endmodule
