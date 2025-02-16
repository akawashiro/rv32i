`include "cpu.sv"

// $ cat fib.asm
// .global main
//
// .main:
//     # 初期値の設定
//     li a0, 0   # a0 = F(n-2)
//     li a1, 1   # a1 = F(n-1)
//     li a2, 10  # a2 = n (求めるフィボナッチ数の番号)
//     li a4, 1
//
// .loop:
//     # n が 2 より小さい場合はループを終了
//     ble a2, a4, .end
//
//     # F(n) を計算
//     add a3, a0, a1
//
//     # F(n-2) と F(n-1) を更新
//     mv a0, a1
//     mv a1, a3
//
//     # n をデクリメント
//     addi a2, a2, -1
//
//     # ループに戻る
//     j .loop
//
// .end:
//     # 結果 (F(10)) を a1 に格納
//     mv a1, a3
// $ riscv64-unknown-elf-as fib.asm -o fib.o
// $ riscv64-linux-gnu-objdump -D fib.o

module fib;
  logic clk;
  logic reset;
  logic [31:0] initial_instructions[32];
  logic [31:0] initial_register_values[32];
  logic [31:0] initial_memory_values[32];
  wire [31:0] register_check[32];
  logic [31:0] pc_out_check;

  assign initial_instructions[0]  = 32'h00000513;
  assign initial_instructions[1]  = 32'h00100593;
  assign initial_instructions[2]  = 32'h00a00613;
  assign initial_instructions[3]  = 32'h00100713;
  assign initial_instructions[4]  = 32'h00c75c63;
  assign initial_instructions[5]  = 32'h00b506b3;
  assign initial_instructions[6]  = 32'h00058513;
  assign initial_instructions[7]  = 32'h00068593;
  assign initial_instructions[8]  = 32'hfff60613;
  assign initial_instructions[9]  = 32'hfedff06f;
  assign initial_instructions[10] = 32'h00068593;

  cpu cpu_0 (
      .clk(clk),
      .reset(reset),
      .initial_instructions(initial_instructions),
      .initial_register_values(initial_register_values),
      .initial_memory_values(initial_memory_values),
      .pc_out_check(pc_out_check),
      .register_check(register_check)
  );

  initial begin
    clk   = 0;
    reset = 0;
    #10 clk = 1;
    reset = 1;
    #10 reset = 0;
    clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    assert (register_check[10] == 0)
    else $error("register_check[0] = %d", register_check[10]);
    assert (register_check[11] == 1)
    else $error("register_check[1] = %d", register_check[11]);
    assert (register_check[12] == 10)
    else $error("register_check[12] = %d", register_check[12]);
    assert (register_check[14] == 1)
    else $error("register_check[14] = %d", register_check[14]);
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    assert (register_check[12] == 9)
    else $error("register_check[12] = %d", register_check[12]);
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    assert (register_check[12] == 8)
    else $error("register_check[12] = %d", register_check[12]);
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    assert (register_check[12] == 7)
    else $error("register_check[12] = %d", register_check[12]);
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    assert (register_check[12] == 6)
    else $error("register_check[12] = %d", register_check[12]);
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    assert (register_check[12] == 5)
    else $error("register_check[12] = %d", register_check[12]);
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    assert (register_check[12] == 4)
    else $error("register_check[12] = %d", register_check[12]);
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    assert (register_check[12] == 3)
    else $error("register_check[12] = %d", register_check[12]);
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    #10 clk = 0;
    #10 clk = 1;
    // The 10th item in the Fibonacci sequence is 55.
    assert (register_check[11] == 55)
    else $error("register_check[11] = %d", register_check[11]);
  end
endmodule

