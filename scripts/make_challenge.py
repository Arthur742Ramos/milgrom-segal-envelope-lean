#!/usr/bin/env python3
"""Reproduce the standalone research contracts from the public declarations.

Only contract proofs become placeholders. Definitions retain their exact bodies.
The proved implementation is checked separately and imported only by Solution.
"""
import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

def render():
    source = (ROOT / "MilgromSegal.lean").read_text()
    header = source[:source.index("namespace Implementation")]
    public = source[source.index("end Implementation") + len("end Implementation"):
                    source.rindex("end MilgromSegal")]
    starts = list(re.finditer(r"^theorem (\w+)", public, re.M))
    chunks = []
    for i, match in enumerate(starts):
        part = public[match.start():starts[i + 1].start() if i + 1 < len(starts) else len(public)]
        declaration = part[:part.index(" := by\n")]
        chunks.append(declaration + " := by\n  sorry\n")
    return ("/- Standalone research contracts. Only theorem proofs are deliberate placeholders.\n"
            "Genuine definition bodies below match the implementation. -/\n" + header +
            "\n".join(chunks) + "\nend MilgromSegal\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    expected = render().encode()
    if args.check:
        assert (ROOT / "Challenge.lean").read_bytes() == expected, "Contract source drift"
        print("Standalone Challenge regeneration parity: PASS")
    else:
        (ROOT / "Challenge.lean").write_bytes(expected)
