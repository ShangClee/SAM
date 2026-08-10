# SAM Phoneme Tables — Complete Reference

## Overview

SAM (Software Automatic Mouth) uses a two-layer table system to convert phonemes into sound. Every phoneme (index 0–80) has parallel entries in **linguistic tables** and **acoustic tables** — 12 values per phoneme that together define how each sound is synthesized.

```
SamTabs.h    →  linguistic data  (name, flags, length)
RenderTabs.h →  acoustic data    (frequencies, amplitudes, noise)
```

The **phoneme index** (0–80) is the key into every table — they are parallel arrays, not per-phoneme structs.

---

## The Core Synthesis Formula

For every 10ms frame of a phoneme, SAM mixes **three oscillators**:

```
sample = A1·sin(f1·t) + A2·sin(f2·t) + A3·rect(f3·t)
```

| Component | What it does |
|-----------|-------------|
| `sin(f1)` + `sin(f2)` | Two sine waves → the first two **formants** (give vowels their character) |
| `rect(f3)` | A rectangular (square) wave → adds brightness/buzz |
| `A1, A2, A3` | Amplitudes that fade in/out over time (envelopes) |

All math is **integer-only** — no floating point. The original C64 version was just 26 assembly instructions.

---

## Table System Architecture

### Linguistic Tables (`SamTabs.h`)

| Table | Purpose |
|-------|---------|
| `phonemeLengthTable[]` | Default length (in frames, 1 frame = 10ms) for each phoneme when unstressed |
| `phonemeStressedLengthTable[]` | Length used when a phoneme carries stress (stress = 1–8) |
| `signInputTable1[]` & `signInputTable2[]` | Two-character ASCII codes that map to a phoneme index (e.g., `'I','Y'` → IY) |
| `flags[]` | Bit-field per phoneme indicating vowel, voiced, consonant type, etc. |
| `flags2[]` | Additional flag bits (used for special handling) |

### Acoustic Tables (`RenderTabs.h`)

| Table | Purpose |
|-------|---------|
| `freq1data[]` | Formant 1 frequency for each phoneme |
| `freq2data[]` | Formant 2 frequency for each phoneme |
| `freq3data[]` | Formant 3 frequency for each phoneme |
| `ampl1data[]` | Amplitude 1 envelope for each phoneme |
| `ampl2data[]` | Amplitude 2 envelope for each phoneme |
| `ampl3data[]` | Amplitude 3 envelope for each phoneme |
| `sampledConsonantFlags[]` | Flags indicating if a phoneme uses the noise table instead of tones |
| `sampleTable[]` | 1280 bytes of noise data for unvoiced fricatives (S, SH, F, TH) |

---

## How the Tables Connect to Sound

```
Phoneme index (e.g. 5 = IY)
    │
    ├──→ phonemeLengthTable[5] = 8      → expand into 8 frames
    │
    ├──→ freq1data[5] = 10   ─┐
    ├──→ freq2data[5] = 84     ├─→ for each frame, compute:
    ├──→ freq3data[5] = 110    │     sample = A1·sin(f1) + A2·sin(f2) + A3·rect(f3)
    ├──→ ampl1data[5] = 13     │
    ├──→ ampl2data[5] = 10     ├─→ these are the A1, A2, A3 values
    ├──→ ampl3data[5] = 8      ┘
    │
    └──→ sampledConsonantFlags[5] = 0   → use sine waves (not noise)
```

For **S\*** (index 32), all amplitudes are 0 and `sampledConsonantFlags` is non-zero — so instead of the sine-wave formula, SAM plays bytes from the `sampleTable[]` (1280 bytes of noise data in `RenderTabs.h`), which produces the hissing sound.

---

## Flag Bits Decoded

```
flags[5]  = 0xA4 = 10100100
                    │││   │
                    │││   └─ bit 0: (always 0 for vowels)
                    ││└───── bit 2: vowel = YES
                    │└────── bit 5: voiced = YES
                    └─────── bit 7: (set for most vowels)

flags[32] = 0x40 = 01000000
                    │
                    └─────── bit 6: unvoiced consonant = YES
                             (no vowel bit, no voiced bit)
```

---

## Worked Examples — 3 Phonemes Side by Side

### IY (index 5) — vowel "ee" as in "f**ee**t"

| Table | Value | Meaning |
|-------|-------|--------|
| `signInputTable1[5]` | `'I'` | First char of name |
| `signInputTable2[5]` | `'Y'` | Second char → name = "IY" |
| `flags[5]` | `0xA4` = `10100100` | Vowel, voiced, no special |
| `phonemeLengthTable[5]` | `8` | 8 frames = 80ms default |
| `phonemeStressedLengthTable[5]` | `11` | 11 frames = 110ms when stressed |
| `freq1data[5]` | `10` | Formant 1 frequency (low pitch) |
| `freq2data[5]` | `84` | Formant 2 frequency (high — makes "ee" bright) |
| `freq3data[5]` | `110` | Formant 3 frequency |
| `ampl1data[5]` | `13` | Amplitude 1 (strong) |
| `ampl2data[5]` | `10` | Amplitude 2 (strong) |
| `ampl3data[5]` | `8` | Amplitude 3 (moderate) |
| `sampledConsonantFlags[5]` | `0` | Not a noise consonant |

### S\* (index 32) — unvoiced "s" as in "**s**un"

| Table | Value | Meaning |
|-------|-------|--------|
| `signInputTable1[32]` | `'S'` | First char |
| `signInputTable2[32]` | `'*'` | Second char → name = "S*" |
| `flags[32]` | `0x40` = `01000000` | **Unvoiced**, no vowel flag |
| `phonemeLengthTable[32]` | `2` | 2 frames = 20ms (very short) |
| `phonemeStressedLengthTable[32]` | `2` | Same when stressed |
| `freq1data[32]` | `6` | Low frequency |
| `freq2data[32]` | `73` | |
| `freq3data[32]` | `99` | |
| `ampl1data[32]` | `0` | **Zero** — no tonal component! |
| `ampl2data[32]` | `0` | **Zero** |
| `ampl3data[32]` | `0` | **Zero** |
| `sampledConsonantFlags[32]` | `0xF1` = `11110001` | **Uses noise table** instead of tones |

### AY (index 49) — diphthong "eye" as in "h**igh**"

| Table | Value | Meaning |
|-------|-------|--------|
| `signInputTable1[49]` | `'A'` | First char |
| `signInputTable2[49]` | `'Y'` | Second char → name = "AY" |
| `flags[49]` | `0xB4` = `10110100` | Vowel + diphthong flag |
| `phonemeLengthTable[49]` | `12` | 12 frames = 120ms |
| `phonemeStressedLengthTable[49]` | `15` | 15 frames = 150ms when stressed |
| `freq1data[49]` | `26` | Formant 1 |
| `freq2data[49]` | `38` | Formant 2 (lower than IY — sounds "darker") |
| `freq3data[49]` | `88` | Formant 3 |
| `ampl1data[49]` | `15` | Strong amplitude 1 |
| `ampl2data[49]` | `13` | Strong amplitude 2 |
| `ampl3data[49]` | `1` | Weak amplitude 3 |
| `sampledConsonantFlags[49]` | `0` | Not noise |

---

## Different Phoneme Types → Different Rendering Rules

The `flags[]` table classifies each phoneme, which changes how it's rendered:

| Type | Examples | Rendering Rule |
|------|----------|----------------|
| **Vowels** | IY, AH, AE | Full 3-oscillator mix, pitch-tracked |
| **Voiced consonants** | B, D, G, Z, V | Same mix, shorter duration |
| **Unvoiced fricatives** | S, SH, F, TH | **Noise table** (random values) instead of periodic waves |
| **Stops** | P, T, K | Brief silence → burst of the mix |

---

## Full Phoneme Inventory (All 81 Entries)

The tables cover indices 0–80. Here is the complete list:

| Index | Name | Type | Length | Stressed | f1 | f2 | f3 | A1 | A2 | A3 |
|-------|------|------|--------|----------|----|----|----|----|----|-----|
| 0 | `*` | Pause/punctuation | — | — | — | — | — | — | — | — |
| 1 | `.*` | Pause/punctuation | — | — | — | — | — | — | — | — |
| 2 | `?*` | Pause/punctuation | — | — | — | — | — | — | — | — |
| 3 | `,*` | Pause/punctuation | — | — | — | — | — | — | — | — |
| 4 | `-*` | Pause/punctuation | — | — | — | — | — | — | — | — |
| 5 | IY | Vowel | 8 | 11 | 10 | 84 | 110 | 13 | 10 | 8 |
| 6 | IH | Vowel | 8 | 11 | 14 | 72 | 93 | 13 | 11 | 7 |
| 7 | EH | Vowel | 8 | 11 | 18 | 66 | 91 | 14 | 13 | 8 |
| 8 | AE | Vowel | 8 | 11 | 24 | 62 | 88 | 15 | 12 | 8 |
| 9 | AA | Vowel | 11 | 15 | 26 | 46 | 89 | 15 | 13 | 1 |
| 10 | AH | Vowel | 10 | 11 | 22 | 44 | 87 | 15 | 12 | 1 |
| 11 | AO | Vowel | 12 | 16 | 20 | 30 | 88 | 15 | 12 | 0 |
| 12 | UH | Vowel | 10 | 12 | 16 | 36 | 82 | 15 | 12 | 6 |
| 13 | AX | Vowel | 10 | 6 | 20 | 44 | 89 | 12 | 9 | 7 |
| 14 | IX | Vowel | 5 | 6 | 14 | 72 | 93 | 13 | 11 | 5 |
| 15 | ER | Vowel | 11 | 14 | 18 | 30 | 62 | 15 | 11 | 1 |
| 16 | UX | Vowel | 11 | 14 | 18 | 30 | 82 | 15 | 12 | 0 |
| 17 | OH | Vowel | 11 | 14 | 14 | 40 | 94 | 15 | 12 | 1 |
| 18 | RX | Semivowel | 9 | 11 | varies | varies | varies | 13 | 12 | 0 |
| 19 | LX | Semivowel | 10 | 11 | varies | varies | varies | 13 | 12 | 0 |
| 20 | WX | Semivowel | 9 | 11 | varies | varies | varies | 13 | 12 | 0 |
| 21 | YX | Semivowel | 10 | 11 | varies | varies | varies | 13 | 12 | 0 |
| 22 | WH | Fricative | 9 | 11 | 10 | 24 | 90 | 13 | 8 | 0 |
| 23 | R\* | Voiced cons. | 6 | 8 | varies | varies | varies | 13 | 8 | 0 |
| 24 | L\* | Voiced cons. | 6 | 8 | varies | varies | varies | 13 | 8 | 0 |
| 25 | W\* | Voiced cons. | 8 | 8 | varies | varies | varies | 13 | 8 | 0 |
| 26 | Y\* | Voiced cons. | 6 | 8 | varies | varies | varies | 13 | 8 | 0 |
| 27 | M\* | Nasal | 7 | 8 | 6 | 46 | 110 | 12 | 9 | 0 |
| 28 | N\* | Nasal | 7 | 8 | 6 | 46 | 110 | 12 | 9 | 0 |
| 29 | NX | Nasal | 7 | 8 | 6 | 46 | 110 | 12 | 9 | 0 |
| 30 | DX | Flap | 2 | 3 | 6 | 54 | 121 | 0 | 0 | 0 |
| 31 | Q\* | Glottal stop | 5 | 5 | 17 | 67 | 91 | 0 | 0 | 0 |
| 32 | S\* | Unvoiced fric. | 2 | 2 | 6 | 73 | 99 | 0 | 0 | 0 |
| 33 | SH | Unvoiced fric. | 2 | 2 | 6 | 79 | 121 | 0 | 0 | 0 |
| 34 | F\* | Unvoiced fric. | 2 | 2 | 6 | 73 | 121 | 0 | 0 | 0 |
| 35 | TH | Unvoiced fric. | 2 | 2 | 6 | 79 | 121 | 0 | 0 | 0 |
| 36 | /H | Breath | 2 | 2 | 14 | 73 | 93 | 11 | 0 | 0 |
| 37 | — | (unused) | — | — | — | — | — | — | — | — |
| 38 | Z\* | Voiced fric. | 6 | 6 | 8 | 40 | 77 | 11 | 3 | 0 |
| 39 | ZH | Voiced fric. | 6 | 6 | 10 | 66 | 103 | 11 | 3 | 0 |
| 40 | V\* | Voiced fric. | 6 | 6 | 8 | 40 | 77 | 11 | 3 | 0 |
| 41 | DH | Voiced fric. | 6 | 6 | 10 | 66 | 103 | 11 | 3 | 0 |
| 42 | CH | Affricate | 6 | 9 | 6 | 79 | 103 | 0 | 0 | 0 |
| 43 | — | (unused) | — | — | — | — | — | — | — | — |
| 44 | J\* | Voiced affr. | 3 | 4 | 6 | 79 | 103 | 11 | 0 | 0 |
| 45–47 | — | (unused) | — | — | — | — | — | — | — | — |
| 48 | EY | Diphthong | 12 | 14 | 18 | 30 | 85 | 14 | 12 | 0 |
| 49 | AY | Diphthong | 12 | 15 | 26 | 38 | 88 | 15 | 13 | 1 |
| 50 | OY | Diphthong | 12 | 15 | 18 | 30 | 88 | 15 | 13 | 0 |
| 51 | AW | Diphthong | 12 | 14 | 24 | 30 | 88 | 15 | 13 | 0 |
| 52 | OW | Diphthong | 12 | 14 | 14 | 30 | 94 | 15 | 12 | 1 |
| 53 | UW | Diphthong | 12 | 14 | 16 | 30 | 82 | 15 | 12 | 0 |
| 54 | B\* | Stop | 1 | 1 | 6 | 34 | 94 | 0 | 0 | 0 |
| 55 | — | (unused) | — | — | — | — | — | — | — | — |
| 56 | — | (unused) | — | — | — | — | — | — | — | — |
| 57 | D\* | Stop | 1 | 1 | 6 | 54 | 103 | 0 | 0 | 0 |
| 58 | — | (unused) | — | — | — | — | — | — | — | — |
| 59 | — | (unused) | — | — | — | — | — | — | — | — |
| 60 | G\* | Stop | 1 | 1 | 6 | 110 | 110 | 0 | 0 | 0 |
| 61 | — | (unused) | — | — | — | — | — | — | — | — |
| 62 | — | (unused) | — | — | — | — | — | — | — | — |
| 63 | GX | Stop | 1 | 1 | 6 | 110 | 110 | 0 | 0 | 0 |
| 64 | — | (unused) | — | — | — | — | — | — | — | — |
| 65 | — | (unused) | — | — | — | — | — | — | — | — |
| 66 | P\* | Unvoiced stop | 1 | 1 | 6 | 86 | 94 | 0 | 0 | 0 |
| 67 | — | (unused) | — | — | — | — | — | — | — | — |
| 68 | — | (unused) | — | — | — | — | — | — | — | — |
| 69 | T\* | Unvoiced stop | 1 | 1 | 6 | 109 | 121 | 0 | 0 | 0 |
| 70 | — | (unused) | — | — | — | — | — | — | — | — |
| 71 | — | (unused) | — | — | — | — | — | — | — | — |
| 72 | K\* | Unvoiced stop | 1 | 1 | 6 | 109 | 121 | 0 | 0 | 0 |
| 73 | — | (unused) | — | — | — | — | — | — | — | — |
| 74 | — | (unused) | — | — | — | — | — | — | — | — |
| 75 | KX | Unvoiced stop | 1 | 1 | 6 | 109 | 121 | 0 | 0 | 0 |
| 76 | — | (unused) | — | — | — | — | — | — | — | — |
| 77 | — | (unused) | — | — | — | — | — | — | — | — |
| 78 | UL | Special | 5 | 5 | 6 | 34 | 94 | 12 | 10 | 7 |
| 79 | UM | Special | 12 | 14 | 6 | 34 | 94 | 12 | 10 | 7 |
| 80 | UN | Special | 12 | 14 | 6 | 34 | 94 | 12 | 10 | 7 |

---

## The Full Pipeline

```
Text → Phonemes → Frames → Samples
"Hello"  /H EH L OW/  [frame][frame][frame]...  [8-bit PCM bytes]
```

1. **Text → Phonemes** (`reciter.c`): Rule-based conversion ("ANT(I)" → "AY")
2. **Phonemes → Frames** (`sam.c`): Each phoneme expands into N frames (10ms each), with stress and length adjustments
3. **Frames → Samples** (`render.c`): For each frame, look up frequencies & amplitudes, **interpolate between adjacent phonemes** for smooth transitions, then compute the mixed waveform

---

## Additional Rendering Tables

### Blend Tables (`RenderTabs.h`)

| Table | Purpose |
|-------|---------|
| `blendRank[]` | Used to decide which phoneme's blend lengths. The candidate with the lower score is selected |
| `outBlendLength[]` | Number of frames at the end of a phoneme devoted to interpolating to next phoneme's final value |
| `inBlendLength[]` | Number of frames at beginning of a phoneme devoted to interpolating to phoneme's final value |

### Amplitude & Frequency Modification

| Table | Purpose |
|-------|---------|
| `amplitudeRescale[]` | Rescales amplitude values for output |
| `tab47492[]` | Pitch modification table |
| `tab48426[]` | Additional timing data |
| `sampleTable[]` | 1280 bytes of noise data for unvoiced consonants (S, SH, F, TH, CH) |

---

## The Clever 6502 Trick

From the original C64 implementation — the code packed the high 4 bits of a sine value with the low 4 bits of an amplitude into a single byte, used that as an index into a multiplication lookup table, and accumulated — all in 8-bit integer math:

```asm
; Original 6502 assembly (from README)
LDX 43       ; get phase
LDA 42176,x  ; load sine value (high 4 bits)
ORA TabAmpl1,y; get amplitude (in low 4 bits)
TAX
LDA 42752,x  ; multiplication table
ADC 56       ; add with previous values
STA 56       ; and store
```

That's why SAM is so tiny (39KB) and can run on embedded devices.

---

## Summary

**In one sentence:** Each phoneme has a row of 12 values across 6 tables — 3 frequencies, 3 amplitudes, a length, a stressed length, flags, and noise flags — all indexed by the same phoneme number, and the renderer reads those values to compute `A1·sin(f1) + A2·sin(f2) + A3·rect(f3)` for every 10ms frame.

---

*Generated from SAM source code analysis — `src/SamTabs.h`, `src/RenderTabs.h`, `src/render.c`, `src/sam.c`*
