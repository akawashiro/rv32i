#! /bin/bash

set -eux -o pipefail

tmpfile=$(mktemp)
iverilog -g 2012 -o fib fib.sv -W all
vvp fib | tee $tmpfile
! grep -q '^ERROR.*$' $tmpfile
