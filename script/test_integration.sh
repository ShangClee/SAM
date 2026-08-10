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
if [ -d "$ROOT/test-assets/golden_wavs" ]; then
  echo "Verifying produced WAVs against golden WAVs (tolerance checks)"
  python3 - <<PY
import wave,math,sys
ROOT = '$ROOT'
OUTDIR = '$OUTDIR'
golddir = ROOT + '/test-assets/golden_wavs'

def read_samples(path):
    f = wave.open(path,'rb')
    assert f.getnchannels()==1
    assert f.getframerate()==22050
    frames = f.getnframes()
    raw = f.readframes(frames)
    f.close()
    # 8-bit unsigned PCM -> convert to signed centered at 0
    samples = [ (b if isinstance(b,int) else ord(b)) - 128 for b in raw ]
    return samples

def compare(gold_path, out_path, rms_tol=2.0, max_tol=10):
    g = read_samples(gold_path)
    o = read_samples(out_path)
    if len(g) != len(o):
        print('length mismatch', gold_path, len(g), out_path, len(o))
        return False
    # compute RMS and max abs diff
    ssd = 0
    maxd = 0
    for a,b in zip(g,o):
        d = a-b
        ssd += d*d
        if abs(d) > maxd: maxd = abs(d)
    rms = math.sqrt(ssd/len(g))
    print(out_path, 'rms=', rms, 'max=', maxd)
    return rms <= rms_tol and maxd <= max_tol

ok = True
for name in ['test_0.wav','test_1.wav','test_2.wav','test_buffer_bytes.wav']:
    gold = golddir + '/' + name
    out = OUTDIR + '/' + name
    if not compare(gold, out):
        print('Tolerance check failed for', name)
        ok = False

if not ok:
    sys.exit(2)
else:
    print('All tolerance checks passed')
PY
fi

echo "Integration tests finished. Wavs in $OUTDIR"
