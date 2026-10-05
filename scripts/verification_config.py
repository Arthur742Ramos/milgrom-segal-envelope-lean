#!/usr/bin/env python3
"""Validate submission config and prepare local three-kernel execution config.

This preserves the submitted config. Palomar itself injects protected kernels
in production; its intake rejects submitter-authored external_kernels fields.
"""

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent.parent
PIN = json.loads((ROOT / "policy-pins.json").read_text())["pipeline_commit"]
POLICY = Path(os.environ.get("PALOMAR_SUBMISSION_DIR",
    ROOT.parent / "review-sources/PalomarSubmission-current")).resolve()
parser = argparse.ArgumentParser()
parser.add_argument("destination", type=Path)
args = parser.parse_args()
assert subprocess.check_output(["git", "-C", str(POLICY), "rev-parse", "HEAD"],
    text=True).strip() == PIN
subprocess.run(["git", "-C", str(POLICY), "diff", "--quiet", "HEAD", "--"], check=True)
sys.path.insert(0, str(POLICY))
from scripts.verify_submission import load_comparator_config, PROTECTED_KERNELS, protected_kernels
config = load_comparator_config(ROOT / "comparator.json")
prefix = Path(subprocess.check_output(["lake", "env", "lean", "--print-prefix"],
    cwd=ROOT, text=True).strip()).resolve()
kernels = protected_kernels({binary: prefix / "bin" / binary for _, binary in PROTECTED_KERNELS})
assert kernels["con-ron"][1:] == ["--jobs=2"], "Unreviewed kernel concurrency policy"
for command in kernels.values():
    assert Path(command[0]).is_file() and os.access(command[0], os.X_OK), command
destination = args.destination.resolve()
assert not destination.is_relative_to(ROOT), "Execution config must be outside submission"
assert not args.destination.is_symlink(), "Execution config must not be a symlink"
config["external_kernels"] = kernels
destination.write_text(json.dumps(config, indent=2) + "\n")
print("Official configuration validator passed; local bundled NanoDa and con-ron enabled")
print(json.dumps(kernels, indent=2))
