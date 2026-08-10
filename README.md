SAM
===

Software Automatic Mouth - Tiny Speech Synthesizer 


What is SAM?
============

Sam is a very small Text-To-Speech (TTS) program written in C, that runs on most popular platforms.
It is an adaption to C of the speech software SAM (Software Automatic Mouth) for the Commodore C64 published 
in the year 1982 by Don't Ask Software (now SoftVoice, Inc.). It includes a Text-To-Phoneme converter called reciter and a Phoneme-To-Speech routine for the 
final output. It is so small that it will work also on embedded computers. On my computer it takes
less than 39KB (much smaller on embedded devices as the executable-overhead is not necessary) of disk space and is a fully stand alone program. 
For immediate output it uses the SDL-library, otherwise it can save .wav files. 

An online version and executables for Windows can be found on the web site: http://simulationcorner.net/index.php?page=sam


Browser (WebAssembly)
=====================

SAM also runs in the browser as a WebAssembly module — no server required.

**Quick start:**

    # Build the WASM artifact (needs Emscripten on PATH)
    source /path/to/emsdk/emsdk_env.sh   # or: brew install emscripten
    bash build_web.sh

    # Serve the web/ directory and open http://localhost:8000
    python3 -m http.server 8000 -d web

    # Smoke-test the shipped artifact in Node (same binary the browser runs)
    node script/test_web_smoke.mjs

**Features** (`web/index.html`):

- Text input — SAM converts it to phonemes automatically
- Phonetic input — enter SAM phoneme codes directly (e.g. `/HEY2`)
- Voice presets — SAM, Elf, Little Robot, Stuffy Guy, Little Old Lady, Extra-Terrestrial
- Sing mode toggle
- WAV download
- Error reporting with the exact position of invalid phoneme codes
- Cmd/Ctrl+Enter shortcut to speak

The build produces `web/sam.js` (ES6 module) + `web/sam.wasm` and runs in both browsers and Node.
The WASM API is defined in `src/web_wrapper.c` — see `webdocs/developer.html` for the full function list.

**Architecture:**

    src/web_wrapper.c      C → WASM bridge exposing sam_web_* functions
    build_web.sh           Emscripten build (MODULARIZE + EXPORT_ES6)
    web/index.html         Self-contained single-page app (no frameworks)
    script/test_web_smoke.mjs   Node smoke test exercising the shipped artifact

    ┌────────────┐    Emscripten    ┌────────────┐
    │  src/*.c   │ ───────────────▶ │ web/sam.js │  ES6 module
    │  (C core)  │    -O2 -sWASM=1  │ web/sam.wasm
    └────────────┘                  └─────┬──────┘
                                          │  import
                                   ┌──────▼──────┐
                                   │ web/index.html │  browser UI
                                   └────────────────┘

Compile
=======

Native (with SDL):

    make                  # builds ./sam (uses SDL for immediate playback)
    make CFLAGS=-DUSESDL=0 LFLAGS=   # headless, no SDL (wav output only)

In order to compile without SDL remove the SDL statements from the CFLAGS and LFLAGS variables in the file "Makefile".

It should compile on every UNIX-like operating system. For Windows you need Cygwin or MinGW( + libsdl).

WebAssembly (see **Browser** section above):

    bash build_web.sh     # produces web/sam.js + web/sam.wasm

Fork
====

Take a look at https://github.com/vidarh/SAM for a more refactored and cleaner version of the code.

Usage
=====

type

	./sam I am Sam

for the first output.

If you have disabled SDL try

	./sam -wav i_am_sam.wav I am Sam

to get a wav file. This file can be played by many media players available for the PC.

you can try other options like
	-pitch number
	-speed number
	-throat number
	-mouth number

Some typical values written in the original manual are:

	DESCRIPTION          SPEED     PITCH     THROAT    MOUTH
	Elf                   72        64        110       160
	Little Robot          92        60        190       190
	Stuffy Guy            82        72        110       105
	Little Old Lady       82        32        145       145
	Extra-Terrestrial    100        64        150       200
	SAM                   72        64        128       128


It can even sing
look at the file "sing"
for a small example.

For the phoneme input table look in the Wiki.


A description of additional features can be found in the original manual at
	http://www.retrobits.net/atari/sam.shtml
or in the manual of the equivalent Apple II program
	http://www.apple-iigs.info/newdoc/sam.pdf


Integration Tests & CI
======================

**Run locally:**

    make -j2                              # build the native binary first
    ./script/test_integration.sh          # generates WAVs and verifies against golden references

The integration script:

1. Synthesises four sample phrases to WAV files
2. Validates WAV headers (mono, 22050 Hz)
3. Compares produced WAVs against golden references in `test-assets/golden_wavs/` using RMS and max-diff tolerance checks

**CI** (`.github/workflows/integration.yml`):

- `build-and-test` — native build + integration script on Ubuntu and macOS; uploads WAV artifacts
- `web-build` — Emscripten WASM build + Node smoke test on Ubuntu; uploads `web/` artifacts


Adaption To C
=============

This program (disassembly at http://hitmen.c02.at/html/tools_sam.html) was converted semi-automatic into C by converting each assembler opcode.
e. g. 

	lda 56		=>	A = mem[56];
	jmp 38018  	=>	goto pos38018;
	inc 38		=>	mem[38]++;
	.			.
	.			.

Then it was manually rewritten to remove most of the 
jumps and register variables in the code and rename the variables to proper names. 
Most of the description below is a result of this rewriting process.

Unfortunately it is still unreadable. But you should see from where I started :)


Short description
=================

First of all I will limit myself here to a very coarse description. 
There are very many exceptions defined in the source code that I will not explain. 
Also a lot of code is unknown for me e. g. Code47503. 
For a complete understanding of the code I need more time and especially more eyes have a look on the code. 

Reciter
-------

It changes the english text to phonemes by a ruleset shown in the wiki.

The rule
	" ANT(I)",	"AY",
means that if he find an "I" with previous letters " ANT", exchange the I by the phoneme "AY".

There are some special signs in this rules like
	#
	&
	@
	^
	+
	:
	%
which can mean e. g. that there must be a vocal or a consonant or something else. 

With the -debug option you will get the corresponding rules and the resulting phonemes.


Output
------

Here is the full tree of subroutine calls:

SAMMain()
	Parser1()
	Parser2()
		Insert()
	CopyStress()
	SetPhonemeLength()
	Code48619()
	Code41240()
		Insert()
	Code48431()
		Insert()
		
	Code48547
		Code47574
			Special1
			Code47503
			Code48227


SAMMain() is the entry routine and calls all further routines. 
Parser1 transforms the phoneme input and transforms it to three tables
	phonemeindex[]
	stress[]
	phonemelength[] (zero at this moment)
	
This tables are now changed: 

Parser2 exchanges some phonemes by others and inserts new. 
CopyStress adds 1 to the stress under some circumstances
SetPhonemeLength sets phoneme lengths. 
Code48619 changes the phoneme lengths
Code41240 adds some additional phonemes
Code48431 has some extra rules


The wiki shows all possible phonemes and some flag fields.  
The final content of these tables can be seen with the -debug command.


In the function PrepareOutput() these tables are partly copied into the small tables:
	phonemeindexOutput[]
	stressOutput[]
	phonemelengthOutput[]
for output.

Final Output
------------

Except of some special phonemes the output is build by a linear combination:
	
	A =   A1 * sin ( f1 * t ) +
	      A2 * sin ( f2 * t ) +
	      A3 * rect( f3 * t )

where rect is a rectangular function with the same periodicity like sin. 
It seems really strange, but this is really enough for most types of phonemes. 

Therefore the above phonemes are converted with some tables to 
	pitches[]
	frequency1[]  =  f1
	frequency2[]  =  f2
	frequency3[]  =  f3
	amplitude1[]  =  A1
	amplitude2[]  =  A2
	amplitude3[]  =  A3
	
Above formula is calculated in one very good omptimized routine.
It only consist of 26 commands:

    48087: 	LDX 43		; get phase	
    CLC		
	LDA 42240,x	; load sine value (high 4 bits)
	ORA TabAmpl1,y	; get amplitude (in low 4 bits)
	TAX		
	LDA 42752,x	; multiplication table
	STA 56		; store 

	LDX 42		; get phase
	LDA 42240,x	; load sine value (high 4 bits)
	ORA TabAmpl2,y	; get amplitude (in low 4 bits)
	TAX		
	LDA 42752,x	; multiplication table
	ADC Var56	; add with previous values
	STA 56		; and store

	LDX 41		; get phase
	LDA 42496,x	; load rect value (high 4 bits)
	ORA TabAmpl3,y	; get amplitude (in low 4 bits)
	TAX		
	LDA 42752,x	; multiplication table
	ADC 56		; add with previous values

	ADC #136		
	LSR A		; get highest 4 bits
	LSR A		
	LSR A		
	LSR A		
	STA 54296	;SID   main output command


The rest is handled in a special way. At the moment I cannot figure out in which way. 
But it seems that it uses some noise (e. g. for "s") using a table with random values. 

License
=======

The software is a reverse-engineered version of a software 
published more than 34 years ago by "Don't ask Software".

The company no longer exists. Any attempt to contact the original
authors failed. Hence S.A.M. can be best described as Abandonware
(http://en.wikipedia.org/wiki/Abandonware)

As long this is the case I cannot put my code under any specific open
source software license. However the software might be used under the
"Fair Use" act (https://en.wikipedia.org/wiki/FAIR_USE_Act) in the USA.

Contact
=======

If you have questions don' t hesitate to ask me.
If you discovered some new knowledge about the code please mail me.

Sebastian Macke
Email: sebastian@macke.de
