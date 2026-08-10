#!/bin/bash
set -e

# Build SAM as WebAssembly using Emscripten
# Usage: source /tmp/emsdk/emsdk_env.sh && bash build_web.sh
#
# The generated sam.js is an ES6 module that runs in browsers (web) and in
# Node.js (node) so the exact artifact shipped to users can be smoke-tested
# in CI with: node script/test_web_smoke.mjs

OUTDIR="web"
SRC="src"

emcc -O2 \
    -I${SRC} \
    ${SRC}/reciter.c \
    ${SRC}/sam.c \
    ${SRC}/render.c \
    ${SRC}/debug.c \
    ${SRC}/web_wrapper.c \
    -o ${OUTDIR}/sam.js \
    -s WASM=1 \
    -s MODULARIZE=1 \
    -s EXPORT_ES6=1 \
    -s ENVIRONMENT=web,node \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s EXPORTED_FUNCTIONS='["_sam_web_synthesize","_sam_web_get_buffer","_sam_web_get_sample_count","_sam_web_get_sample_rate","_sam_web_get_phonetic_output","_sam_web_get_error","_sam_web_get_error_position"]' \
    -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap","getValue","setValue","UTF8ToString","stringToNewUTF8","HEAPU8","HEAP8","HEAPU16","HEAP16","HEAPU32","HEAP32","HEAPF32","HEAPF64"]' \
    -s STRICT=0

echo "Build complete: ${OUTDIR}/sam.js + ${OUTDIR}/sam.wasm"
echo "Smoke test:      node script/test_web_smoke.mjs"
