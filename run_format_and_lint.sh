#! /bin/bash

set -eux -o pipefail

VERIBLE_DIR=/tmp/verible-v0.0-3933-g0e3fe53a-linux-static-x86_64

if [ -d ${VERIBLE_DIR} ]; then
    mkdir -p ${VERIBLE_DIR}
    wget https://github.com/chipsalliance/verible/releases/download/v0.0-3933-g0e3fe53a/verible-v0.0-3933-g0e3fe53a-linux-static-x86_64.tar.gz -O ${VERIBLE_DIR}/verible.tar.gz
    tar -xvf ${VERIBLE_DIR}/verible.tar.gz -C ${VERIBLE_DIR}
fi

FORMAT_CMD="${VERIBLE_DIR}/verible-v0.0-3933-g0e3fe53a/bin/verible-verilog-format"
LINT_CMD="${VERIBLE_DIR}/verible-v0.0-3933-g0e3fe53a/bin/verible-verilog-lint"

${FORMAT_CMD} --inplace *.sv
git diff --exit-code
${LINT_CMD} *.sv
