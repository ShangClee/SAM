#!/usr/bin/env python3
"""
phoneme_freq_table.py

Extracts SAM's formant-frequency and amplitude tables from the actual C sources
(src/RenderTabs.h, src/SamTabs.h), converts the raw phase-increment values into
real Hz, and writes a human-readable table.

Formula (per SAM's renderer): the sine table holds one full cycle in 256
samples, so a phase increment of N advances N/256 of a cycle per output sample:
    f_Hz = (phase_increment * sample_rate) / 256
with sample_rate = 22050.
"""

import os
import re

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RENDER_TABS = os.path.join(BASE, "src", "RenderTabs.h")
SAM_TABS = os.path.join(BASE, "src", "SamTabs.h")
OUT_FILE = os.path.join(BASE, "docs", "phoneme_freq_table.txt")

SAMPLE_RATE = 22050
SINE_TABLE_SIZE = 256  # one full cycle


def _array_body(source, name):
    """Return the text between the outer braces of 'name[...] = {...}'."""
    m = re.search(r"\b" + re.escape(name) + r"\s*\[[^\]]*\]\s*=", source)
    if not m:
        raise ValueError(f"Array '{name}' not found in source")
    start = source.index("{", m.end())
    depth = 0
    end = None
    for i in range(start, len(source)):
        if source[i] == "{":
            depth += 1
        elif source[i] == "}":
            depth -= 1
            if depth == 0:
                end = i
                break
    if end is None:
        raise ValueError(f"Array '{name}': closing brace not found")
    body = source[start + 1 : end]
    body = re.sub(r"/\*.*?\*/", " ", body, flags=re.S)  # block comments
    body = re.sub(r"//[^\n]*", " ", body)               # line comments
    return body


def extract_numeric_array(source, name):
    """Return the list of integer values of a C array like 'unsigned char name[] = {...}'.

    Handles hex (0x0A) and decimal (10) literals, leading commas, comments,
    and whitespace weirdness found in the hand-formatted source.
    """
    body = _array_body(source, name)
    # int(token, 0) understands both 0x.. and decimal
    return [int(t, 0) for t in re.findall(r"(?:0[xX][0-9a-fA-F]+|\d+)", body)]


def extract_char_array(source, name):
    """Return the list of single characters of a C array of char literals."""
    body = _array_body(source, name)
    return re.findall(r"'([^'])'", body)


def phoneme_name(t1, t2):
    """Combine the two sign-input chars; '*' means 'no character'."""
    return (t1 if t1 != "*" else "") + (t2 if t2 != "*" else "")


def hz(value):
    return value * SAMPLE_RATE / SINE_TABLE_SIZE


def main():
    render_src = open(RENDER_TABS, encoding="ascii", errors="replace").read()
    sam_src = open(SAM_TABS, encoding="ascii", errors="replace").read()

    data_arrays = {
        "freq1data": extract_numeric_array(render_src, "freq1data"),
        "freq2data": extract_numeric_array(render_src, "freq2data"),
        "freq3data": extract_numeric_array(render_src, "freq3data"),
        "ampl1data": extract_numeric_array(render_src, "ampl1data"),
        "ampl2data": extract_numeric_array(render_src, "ampl2data"),
        "ampl3data": extract_numeric_array(render_src, "ampl3data"),
    }
    t1 = extract_char_array(sam_src, "signInputTable1")
    t2 = extract_char_array(sam_src, "signInputTable2")

    lengths = {k: len(v) for k, v in data_arrays.items()}
    n_data = min(lengths.values())
    n_names = len(t1)
    n = max(n_data, n_names)

    # Pad the shorter side so every phoneme index has a row.
    padded = {k: v + [0] * (n - len(v)) for k, v in data_arrays.items()}
    names = [phoneme_name(t1[i] if i < len(t1) else "*",
                          t2[i] if i < len(t2) else "*") for i in range(n)]

    print(f"Parsed {RENDER_TABS}")
    for k, v in data_arrays.items():
        print(f"  {k}: {len(v)} entries")
    print(f"Parsed {SAM_TABS}")
    print(f"  signInputTable1: {len(t1)} entries")
    print(f"  signInputTable2: {len(t2)} entries")

    header = [
        "# SAM phoneme formant-frequency table",
        "#",
        f"# Source: {os.path.relpath(RENDER_TABS, BASE)} (freq1data..ampl3data),",
        f"#         {os.path.relpath(SAM_TABS, BASE)} (signInputTable1/2)",
        "#",
        f"# f_Hz = (phase_increment * {SAMPLE_RATE}) / {SINE_TABLE_SIZE}",
        "#   (sine table = one full cycle in 256 samples; sample rate 22050 Hz)",
        "#",
        f"# Note: the data arrays contain {n_data} entries, the name tables {n_names}.",
        f"#       Table below has {n} rows; missing entries are padded with 0.",
        "#",
        "# Index  Name      F1(Hz)   F2(Hz)   F3(Hz)    A1   A2   A3",
        "# -----  --------  -------  -------  -------  ---- ---- ----",
    ]

    rows = []
    for i in range(n):
        f1 = hz(padded["freq1data"][i])
        f2 = hz(padded["freq2data"][i])
        f3 = hz(padded["freq3data"][i])
        a1 = padded["ampl1data"][i]
        a2 = padded["ampl2data"][i]
        a3 = padded["ampl3data"][i]
        row = f"{i:5d}  {names[i]:<8s}  {f1:7.1f}  {f2:7.1f}  {f3:7.1f}  {a1:4d} {a2:4d} {a3:4d}"
        rows.append(row)
        print(row)

    os.makedirs(os.path.dirname(OUT_FILE), exist_ok=True)
    with open(OUT_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(header) + "\n" + "\n".join(rows) + "\n")
    print(f"\nSaved table to {OUT_FILE}")


if __name__ == "__main__":
    main()
