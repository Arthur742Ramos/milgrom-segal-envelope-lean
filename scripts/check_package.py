#!/usr/bin/env python3
"""Check source shape, official metadata, substantive contracts and evidence hashes."""
import argparse
import hashlib
import json
import os
import re
import sys
from pathlib import Path
import yaml
from make_challenge import render

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent.parent
POLICY = Path(os.environ.get("PALOMAR_SUBMISSION_DIR",
    ROOT.parent / "review-sources/PalomarSubmission-current")).resolve()
parser = argparse.ArgumentParser()
parser.add_argument("--record", action="store_true")
args = parser.parse_args()
sys.path.insert(0, str(POLICY))
from scripts.submission_contract import load_formalization_metadata
from scripts.verify_submission import load_comparator_config

cfg = load_comparator_config(ROOT / "comparator.json")
metadata = load_formalization_metadata(ROOT / "formalization.yaml")
authors = ["Arthur Freitas Ramos", "David Barros Hulak", "Ruy Jose Guerra Barretto de Queiroz"]
assert metadata["project"]["authors"] == authors
assert metadata["project"]["responsible_maintainers"] == [authors[0]]
assert metadata["classification"]["msc2020"] == ["26A24", "26A46", "90C31", "91B02", "03B35"]
assert metadata["project"]["license"] == "BSD-3-Clause"
assert [s["lean"] for s in metadata["alignment"]["statements"]] == cfg["theorem_names"]
citation = yaml.safe_load((ROOT / "CITATION.cff").read_text())
assert [a["given-names"] + " " + a["family-names"] for a in citation["authors"]] == authors
assert all(a in (ROOT / "README.md").read_text() for a in authors)
assert (ROOT / "Challenge.lean").read_bytes() == render().encode()
challenge = (ROOT / "Challenge.lean").read_text()
assert len(challenge.encode()) <= 100 * 1024 and len(challenge.splitlines()) <= 1000
assert len(cfg["theorem_names"]) == 8 and len(cfg["definition_names"]) == 3
for name in cfg["theorem_names"]:
    assert re.search(r"^theorem " + re.escape(name.split(".")[-1]) + r"\b", challenge, re.M), name
for name in cfg["definition_names"]:
    assert re.search(r"\bdef " + re.escape(name.split(".")[-1]) + r"\b", challenge), name
assert set(cfg["permitted_axioms"]) == {"propext", "Quot.sound", "Classical.choice"}
assert (ROOT / "Solution.lean").read_text() == "import MilgromSegal\n"
for filename in ("MilgromSegal.lean", "Examples.lean", "Solution.lean"):
    source = (ROOT / filename).read_text()
    assert not re.search(r"\b(sorry|sorryAx|admit|native_decide|ofReduceBool)\b", source), filename
    assert not re.search(r"^\s*(axiom|unsafe)\b", source, re.M), filename
    assert len(source.splitlines()) <= 10000
deps = (ROOT / "evidence/challenge-source-deps.log").read_text().splitlines()
assert deps and all('/src/lean/' in p or '/.lake/packages/mathlib/' in p for p in deps)
audit = (ROOT / "evidence/all-constants-axioms.log").read_text()
assert "All 25 authored namespace constants use only standard axioms." in audit
assert "error:" not in audit
kernel = (ROOT / "evidence/final-comparator.log").read_text()
assert "Your solution is okay!" in kernel
for name in ("Lean default", "nanoda", "con-ron"):
    assert name + " kernel accepts the solution" in kernel
files = [p for p in ROOT.rglob("*") if p.is_file() and
         '.lake' not in p.relative_to(ROOT).parts and '.git' not in p.relative_to(ROOT).parts and
         '__pycache__' not in p.relative_to(ROOT).parts and p.name != 'Probe.lean' and
         p.relative_to(ROOT).parts[0] not in ('evidence', 'reviews')]
hashes = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(files)}
record = {"source_files_sha256": hashes, "challenge_bytes": len(challenge.encode()),
          "challenge_lines": len(challenge.splitlines()),
          "comparison": "eight substantive theorems and three genuine definitions",
          "proof_holes": "none in library, examples or Solution; intentional Challenge placeholders",
          "all_authored_constants_audited": 25,
          "kernels": ["Lean default", "nanoda", "con-ron"],
          "local_platform": "macOS arm64; no Linux bubblewrap confinement"}
manifest = ROOT / "evidence/verification-manifest.json"
if args.record:
    manifest.write_text(json.dumps(record, indent=2) + "\n")
else:
    assert json.loads(manifest.read_text()) == record, "Audited source or manifest drift"
print("Official metadata, authors, standalone contracts, source shape, axiom and kernel evidence: PASS")
print(f"Challenge: {record['challenge_lines']} lines, {record['challenge_bytes']} bytes")
print("Current source hashes match the recorded manifest" if not args.record else "Recorded current source hashes")
