#!/usr/bin/env python3
"""Check the prepared hosted workflow with the exact official request parser.

This performs no network request, build, dispatch, or registry operation. Set
PALOMAR_SUBMISSION_DIR to a clean checkout of the recorded policy revision.
"""

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

sys.dont_write_bytecode = True
import yaml

ROOT = Path(__file__).resolve().parent.parent
PINS = json.loads((ROOT / "policy-pins.json").read_text())
POLICY = Path(os.environ.get("PALOMAR_SUBMISSION_DIR",
    ROOT.parent / "review-sources/PalomarSubmission-current")).resolve()
assert subprocess.check_output(["git", "-C", str(POLICY), "rev-parse", "HEAD"],
    text=True).strip() == PINS["pipeline_commit"], "Policy checkout revision differs"
subprocess.run(["git", "-C", str(POLICY), "diff", "--quiet", "HEAD", "--"], check=True)
sys.path.insert(0, str(POLICY))
from scripts.submission_contract import submission_request
from scripts.verification_profile import load_profile, profile_digest
from scripts.verify_submission import supported_toolchain, PROTECTED_KERNELS
from scripts.render_challenge import MAX_RENDER_FILE_BYTES

workflow_path = ROOT / ".github/workflows/palomar-preflight.yml"
workflow = yaml.load(workflow_path.read_text(), Loader=yaml.BaseLoader)
assert set(workflow["on"]) == {"workflow_dispatch"}, "Workflow must require manual dispatch"
job = workflow["jobs"]["palomar-preflight"]
expected_uses = (PINS["pipeline_repository"] +
    "/.github/workflows/submission.yml@" + PINS["pipeline_commit"])
assert job["uses"] == expected_uses, "Reusable workflow SHA differs"
inputs = dict(job["with"])
assert inputs["pipeline_commit"] == PINS["pipeline_commit"], "Paired pipeline SHA differs"
assert inputs["mode"] == "full", "Full mechanical verification is required"
assert inputs["execution_profile"] == "palomar-standard-v1", "Standard runner must be explicit"
assert inputs["repository"] == "${{ github.repository }}"
assert inputs["commit"] == "${{ github.sha }}"
# Resolve event expressions only for the local input-contract dry parse.
# The hosted workflow receives the actual caller repository and immutable SHA.
inputs["repository"] = "Arthur742Ramos/milgrom-segal-envelope-lean"
inputs["commit"] = "0" * 40
request, identifier = submission_request({"inputs": inputs})
assert identifier == "milgromsg001"
assert request["comparator_config_path"] == "comparator.json"
assert request["authorization_relationship"] == "I am a responsible author or maintainer"
profile = load_profile("palomar-standard-v1")
assert profile["runner"]["provider"] == "github-hosted"
assert profile["runner"]["label"] == "ubuntu-24.04"
toolchain = (ROOT / "lean-toolchain").read_text().strip()
supported_toolchain(toolchain)
assert toolchain == PINS["selected_toolchain"], "Selected toolchain differs from reviewed pin"
manifest = json.loads((ROOT / "lake-manifest.json").read_text())
mathlib = [p for p in manifest["packages"] if p["name"] == "mathlib"]
assert len(mathlib) == 1 and mathlib[0]["rev"] == PINS["mathlib_commit"]
assert toolchain in PINS["verso_commits"], "No reviewed exact Verso pin for toolchain"
assert MAX_RENDER_FILE_BYTES == PINS["render_file_cap_bytes"] == 8388608
assert PROTECTED_KERNELS == (("nanoda", "nanoda_bin"), ("con-ron", "con-ron"))
result = {
    "status": "pass",
    "scope": "Official request parser, reviewed workflow pairing and policy; no build or hosted run",
    "pipeline_commit": PINS["pipeline_commit"],
    "request_id": identifier,
    "execution_profile": profile["id"],
    "profile_sha256": profile_digest(profile),
    "toolchain": toolchain,
    "mathlib_commit": PINS["mathlib_commit"],
    "verso_commit": PINS["verso_commits"][toolchain],
    "render_file_cap_bytes": MAX_RENDER_FILE_BYTES,
    "workflow_sha256": hashlib.sha256(workflow_path.read_bytes()).hexdigest(),
}
print(json.dumps(result, indent=2))
