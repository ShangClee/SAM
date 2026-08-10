#!/usr/bin/env node
// Smoke test for the shipped WASM artifact (web/sam.js + web/sam.wasm).
// Runs the exact ES6 module that the browser app imports, in Node.
// Usage: node script/test_web_smoke.mjs
// (run after bash build_web.sh)
import { createRequire } from 'module';
import { fileURLToPath } from 'url';
import path from 'path';
import assert from 'assert';

const require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const webDir = path.resolve(__dirname, '../web');

const mod = await import(path.join(webDir, 'sam.js'));
const createSamModule = mod.default;

const stdoutLines = [];
const SamModule = await createSamModule({
  print: (t) => stdoutLines.push(t),
  printErr: (t) => stdoutLines.push(t),
});

function synthesize(text, phonetic, { pitch = 64, speed = 72, mouth = 128, throat = 128, singmode = 0 } = {}) {
  stdoutLines.length = 0;
  const sampleCount = SamModule.ccall(
    'sam_web_synthesize', 'number',
    ['string', 'number', 'number', 'number', 'number', 'number', 'number'],
    [text, phonetic, pitch, speed, mouth, throat, singmode]
  );
  const bufPtr = SamModule.ccall('sam_web_get_buffer', 'number', [], []);
  const error = SamModule.ccall('sam_web_get_error', 'number', [], []);
  const errorPos = SamModule.ccall('sam_web_get_error_position', 'number', [], []);
  const phoneticOutput = SamModule.ccall('sam_web_get_phonetic_output', 'string', [], []);
  const samples = sampleCount > 0
    ? new Uint8Array(SamModule.HEAPU8.buffer, bufPtr, sampleCount)
    : new Uint8Array(0);
  return { sampleCount, error, errorPos, phoneticOutput, samples, stdout: [...stdoutLines] };
}

// 1. Text mode: "hello world" must produce audio + phonetics
{
  const r = synthesize('Hello world!', 0);
  assert.ok(r.sampleCount > 1000, `text mode produced ${r.sampleCount} samples`);
  assert.ok(r.error === 0, `text mode error=${r.error}`);
  assert.ok(r.phoneticOutput.includes('HEHLOW'), `unexpected phonetics: ${r.phoneticOutput}`);
  const hasNonSilence = [...r.samples].some(s => s < 100 || s > 156);
  assert.ok(hasNonSilence, 'output is all silence');
  console.log(`✓ text mode: ${r.sampleCount} samples, phonetics: ${r.phoneticOutput.trim()}`);
}

// 2. Phonetic mode: valid code "/HEY2" must work
{
  const r = synthesize('/HEY2', 1);
  assert.ok(r.sampleCount > 0, `phonetic mode produced ${r.sampleCount} samples`);
  assert.ok(r.error === 0, `phonetic mode error=${r.error}`);
  console.log(`✓ phonetic mode: ${r.sampleCount} samples`);
}

// 3. Phonetic mode: invalid code must fail with a parse error + position
{
  const r = synthesize('HEY2', 1); // 'H' is not a SAM phoneme code ('/H' is)
  assert.strictEqual(r.sampleCount, 0, 'invalid input should yield 0 samples');
  assert.strictEqual(r.error, 2, `expected SAM_ERR_PARSE (2), got ${r.error}`);
  assert.ok(r.errorPos >= 0, `expected error position, got ${r.errorPos}`);
  console.log(`✓ parse error reporting: code=${r.error} position=${r.errorPos}`);
}

// 4. Sing mode should not crash and should produce audio
{
  const r = synthesize('DO RE MI', 0, { singmode: 1 });
  assert.ok(r.sampleCount > 0, `sing mode produced ${r.sampleCount} samples`);
  console.log(`✓ sing mode: ${r.sampleCount} samples`);
}

console.log('\nAll web smoke tests passed! ✨');
