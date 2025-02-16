#! /bin/bash

set -eux -o pipefail

tmpfile=$(mktemp)
iverilog -g 2012 -o test_cpu test_cpu.sv -W all
vvp test_cpu | tee $tmpfile
! grep -q '^ERROR.*$' $tmpfile
