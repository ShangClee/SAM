#!/usr/bin/env bash
# Runs a few integration checks: invokes sam to produce wav files and verifies headers
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)

CMD=$ROOT/sam
if [ ! -x "$CMD" ]; then
  echo "Executable $CMD not found. Build first." >&2
  exit 2
fi

OUTDIR=$ROOT/tmp_test_wavs
mkdir -p "$OUTDIR"

phrases=("I am Sam" "Hello world" "Integration test")
for i in "${!phrases[@]}"; do
  out="$OUTDIR/test_$i.wav"
  echo "Generating: $out -> '${phrases[$i]}'"
  "$CMD" -wav "$out" "${phrases[$i]}"
  # quick header check
  python3 - <<PY
import wave,sys
f=wave.open('$out','rb')
ch=f.getnchannels(); rate=f.getframerate(); frames=f.getnframes()
print('$out', ch, rate, frames)
assert ch == 1
assert rate == 22050
assert frames > 0
f.close()
PY
done

# Test buffer-bytes suffix parsing
echo "Testing buffer-bytes suffix parsing"
out2="$OUTDIR/test_buffer_bytes.wav"
"$CMD" -buffer-bytes 4K -wav "$out2" "Small buffer test"
python3 - <<PY
import wave,hashlib
f=wave.open('$out2','rb')
print('$out2', f.getnchannels(), f.getframerate(), f.getnframes())
f.close()
buf=open('$out2','rb').read()
print('sha256', hashlib.sha256(buf).hexdigest())
PY

# verify against golden hashes if present
if [ -f "$ROOT/test-assets/golden_hashes.txt" ]; then
  echo "Verifying against golden hashes"
  python3 - <<PY
import hashlib
gold={}
with open('$ROOT/test-assets/golden_hashes.txt') as f:
    for l in f:
        h,p=l.strip().split('  ')
        gold[p]=h
for p in ['test_0.wav','test_1.wav','test_2.wav','test_buffer_bytes.wav']:
    path='$OUTDIR/'+p
    h=hashlib.sha256(open(path,'rb').read()).hexdigest()
    print(p,h)
    if p in gold:
        assert gold[p]==h, (p+' hash mismatch')
PY
fi

echo "Integration tests finished. Wavs in $OUTDIR"
