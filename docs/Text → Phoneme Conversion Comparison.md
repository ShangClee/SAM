Here's the side-by-side comparison of **original text → SAM phoneme codes**, captured from the native `sam -debug` binary:

## Text → Phoneme Conversion Comparison

| #   | Original Text                                 | SAM Phonetic Output                                      | Rules Applied                                                                                                                                                                 |
| --- | --------------------------------------------- | -------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `Hello world`                                 | `/HEHLOW WERLD`                                          | H→/H, E→EH, L→L, L(L)→∅, O→OW, WOR→WER, L→L, D→D                                                                                                                              |
| 2   | `I am SAM`                                    | `AY4 AEM SAEM`                                           | I→AY (stress 4), A→AE, M→M, S→S, A→AE, M→M                                                                                                                                    |
| 3   | `The quick brown fox jumps over the lazy dog` | `DHAX KWIHK BROWN FAAKS JAH5MS OW5VER DHAX LEY4ZIY DAAG` | THE→DHAX, QU→KW, I→IH, CK→K, B→B, R→R, OW→OW, N→N, F→F, O→AA, X→KS, J→J, U→AH(stress 5), M→M, P→∅, S→S, OVER→OW5VER, THE→DHAX, L→L, A→EY(stress 4), Z→Z, Y→IY, D→D, O→AA, G→G |
| 4   | `Can you make it as web version`              | `KAEN YUW MEYK IHT AEZ WEHB VERSHUN`                     | C→K, A→AE, N→N, YOU→YUW, M→M, A→EY, K→K, E→∅, I→IH, T→T, A→AE, S→Z, W→W, E→EH, B→B, V→V, ER→ER, SION→SHUN                                                                     |
| 5   | `I love you`                                  | `AY4 LAH4V YUW`                                          | I→AY(stress 4), L→L, OV→AH(stress 4)V, E→∅, YOU→YUW                                                                                                                           |
| 6   | `What is the basic rule for making sound`     | `WHAHT IHZ DHAX BEY4SIHK RUWL FAOR MEYKIHNX SAWND`       | WHAT→WHAHT, I→IH, S→Z, THE→DHAX, B→B, AS→EY4S, I→IH, C→K, R→R, U→UW, L→L, E→∅, F→F, OR→AOR, M→M, A→EY, K→K, I→IH, NG→NX                                                       |
| 7   | `Sam can speak`                               | `SAEM KAEN SPIY5K`                                       | S→S, A→AE, M→M, C→K, A→AE, N→N, S→S, P→P, EA→IY(stress 5), K→K                                                                                                                |
| 8   | `I am SAM the software automatic mouth`       | `AY4 AEM SAEM DHAX SAO4FTWEHR AO4TAHMAETIHK MAWTH`       | I→AY4, A→AE, M→M, S→S, A→AE, M→M, THE→DHAX, S→S, A→AO4, F→F, T→T, W→W, E→EH, R→R, E→∅, A→AO4, T→T, O→AH, M→M, A→AE, T→T, I→IH, C→K, M→M, A→AW, TH→TH                          |

## How to Read the Phonetic Codes

| Code       | Sound              | Example Word |
| ---------- | ------------------ | ------------ |
| `/H`       | breathy H          | **h**ello    |
| `EH`       | short e            | b**e**g      |
| `AE`       | short a            | S**a**m      |
| `AY`       | long I (diphthong) | h**igh**     |
| `EY`       | long A (diphthong) | m**a**de     |
| `OW`       | long O (diphthong) | sl**o**w     |
| `UW`       | long U (diphthong) | cr**ew**     |
| `AA`       | short O            | p**o**t      |
| `AH`       | short U            | b**u**dget   |
| `AO`       | aw sound           | t**al**k     |
| `IH`       | short I            | p**i**n      |
| `IY`       | long E             | f**ee**t     |
| `ER`       | r-colored vowel    | b**ir**d     |
| `AX`       | schwa (unstressed) | gall**o**n   |
| `DH`       | voiced TH          | **th**en     |
| `TH`       | unvoiced TH        | **th**in     |
| `SH`       | sh sound           | fi**sh**     |
| `NX`       | nasal ng           | si**ng**     |
| `L*` / `L` | L                  | **l**ow      |
| `M*` / `M` | M                  | **m**an      |
| `N*` / `N` | N                  | **n**o       |
| `R*` / `R` | R                  | **r**ed      |
| `W*` / `W` | W                  | **w**ay      |
| `Y*` / `Y` | Y                  | **y**ou      |
| `S*` / `S` | S                  | **S**am      |
| `Z*` / `Z` | Z                  | **z**oo      |
| `K*` / `K` | K                  | **c**ake     |
| `D*` / `D` | D                  | **d**og      |
| `B*` / `B` | B                  | **b**ad      |
| `G*` / `G` | G                  | **g**ood     |
| `F*` / `F` | F                  | **f**ish     |
| `V*` / `V` | V                  | se**v**en    |
| `P*` / `P` | P                  | **p**oke     |
| `T*` / `T` | T                  | **t**alk     |

## Stress Markers

Numbers `1`–`8` after a phoneme indicate **stress level** (8 = most emphasized):

| Code | Meaning |
|------|---------|
| `AY4` | "I" with moderate stress |
| `JAH5MS` | "jumps" — the U gets stress level 5 |
| `OW5VER` | "over" — the O gets stress level 5 |
| `LEY4ZIY` | "lazy" — the A gets stress level 4 |
| `SPIY5K` | "speak" — the EA gets stress level 5 |

## Interesting Transformations

| Original | What Happens | Why |
|----------|--------------|-----|
| `HELLO` → `/HEHLOW` | H becomes `/H` (breath), double-L collapses to single L | `L(L)` rule removes duplicate L |
| `WORLD` → `WERLD` | O becomes ER | `WOR` rule: O after W → ER sound |
| `THE` → `DHAX` | Whole word lookup | Dictionary entry: TH+schwa |
| `YOU` → `YUW` | Whole word lookup | Dictionary entry: Y+UW diphthong |
| `VERSION` → `VERSHUN` | SION → SHUN | `^(SION)` rule: SION at end → SH+UN |
| `OVER` → `OW5VER` | Whole word lookup + stress | Dictionary entry with stress on O |
| `QUICK` → `KWIHK` | QU → KW, CK → K | `QU` rule + `CK` rule |
| `FOX` → `FAAKS` | O → AA, X → KS | X decomposes to K+S |
| `MAKING` → `MEYKIHNX` | A → EY, NG → NX | `A^%` rule + `NG` → nasal NX |
| `JUMPS` → `JAH5MS` | U → AH with stress, P before S is silent | `(P)S` rule drops P |
| `IS` → `IHZ` | S → Z between voiced sounds | `:#(S)` rule: S after vowel → Z |
| `LAZY` → `LEY4ZIY` | A → EY with stress, Y → IY | `:(A)^+` rule + `#:^(Y)` rule |

## The Full Pipeline for "Hello World"

```
Step 1: TEXT INPUT
  "Hello world" → uppercased → "HELLO WORLD "

Step 2: TEXT-TO-PHONEME RULES (reciter.c)
  H  → /H       (rule: (H)# → /H)
  E  → EH       (rule: (E) → EH)
  L  → L        (rule: (L) → L)
  L  → (deleted)(rule: L(L) → ∅, double-L collapses)
  O  → OW       (rule: (O)  → OW)
  W  → W
  O  → ER       (rule: (WOR)^ → WER)
  R  → R
  L  → L
  D  → D

  Result: "/HEHLOW WERLD"

Step 3: PHONEME PARSING (sam.c — Parser1)
  /H → index 36    EH → index 7     L* → index 24
  OW → index 52    *  → index 0    W* → index 25
  ER → index 15    L* → index 24   D* → index 57

Step 4: PARSER2 (adjustments)
  L* after vowel → LX (index 19)
  OW (diphthong) → insert WX after it
  ER before LX → decrease length by 1
  LX after vowel → increase length by 1/2 + 1

Step 5: LENGTH ASSIGNMENT
  /H:  2 frames (20ms)
  EH:  8 frames (80ms)
  LX:  9 frames (90ms)  [was 8, +1 for voiced consonant rule]
  OW: 14 frames (140ms)
  WX:  8 frames (80ms)  [inserted]
  W*:  8 frames (80ms)
  ER: 10 frames (100ms) [was 11, -1 for consonant rule]
  LX: 12 frames (120ms) [was 9, +3 for voiced consonant rule]
  D*:  5 frames (50ms)

Step 6: RENDER (render.c — 8-bit PCM samples)
  Each frame → A1·sin(f1) + A2·sin(f2) + A3·rect(f3)
  → 22050 Hz, 8-bit unsigned PCM → WAV file
```

This shows the complete journey from **"Hello world"** (text) through **"/HEHLOW WERLD"** (phonemes) to actual audio samples.