# SystemVerilog による RISC-V プロセッサの実装

このリポジトリは、SystemVerilog で RISC-V プロセッサを実装するリポジトリです。
RV32I 命令セットを実装しています。
RV32I は RISC-V の 32bit 整数命令セットであり、命令数が少なく簡単に実装することができます。
最低限の実装で妥協しているため、パイプライン化などの高度な機能は実装していません。
また、FPGA などでの動作確認も行っていません。

## テスト
`run_unit_test.sh` で単体テストを実行することができます。
また、`run_fib.sh` でフィボナッチ数列を計算するプログラムを実行することができます。
実行環境は Ubuntu 24.04 を想定しており、[Icarus Verilog](https://github.com/steveicarus/iverilog) が必要です。

## フォーマッタとリンタ
`./run_format_and_lint.sh` でフォーマッタとリンタを実行することができます。
[verible](https://github.com/chipsalliance/verible) を使用しています。

## 関連リンク

### [コンピュータ構成と設計 / Computer Organization and Design (2024)](https://yamin.cis.k.hosei.ac.jp/lectures/cod/)
法政大学の授業資料。
RV32I の各命令の意味とビットフィールドが記載されています。
このリポジトリは主にこの資料を参考にしています。

### [なぜ教育用モデルプロセッサにRISC-Vを使用すべきか ?](https://riscv.or.jp/wp-content/uploads/day1_15_keio-Hideharu-Amano_RVdayTokyo.pdf)
RISV-V Tokyo 2020 での講演資料。
P19 の「RV32Iの命令フィールドは複雑に見える」の命令中の即値の取り扱いについての記述が参考になります。

### [マイクロプロセッサの設計と実装](https://exp.mtl.t.u-tokyo.ac.jp/2022/b3exp/-/wikis/home)
東京大学の3回生向けの授業資料です。

### [『SystemVerilog超入門』](https://www.kyoritsu-pub.co.jp/book/b10031708.html)
SystemVerilog の入門書です。
文法が乗っているものがあると便利でした。

### [Icarus Verilog](https://steveicarus.github.io/iverilog/)
SystemVerilog をシミュレーションするためのツールです。

### [verible](https://github.com/chipsalliance/verible)
フォーマッタとリンタです。
