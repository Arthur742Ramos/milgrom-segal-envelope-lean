#!/usr/bin/env python3
"""Render and sanitize a separately prepared exact official Verso workspace.

Prepare the workspace with the pinned official prepare_workspace function,
or its exact trusted_lakefile/merge_renderer_manifest output. This script does
not fetch dependencies. It builds only in that isolated workspace and in its
new output directory. Local execution does not reproduce Linux confinement.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import shutil

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent.parent
PINS = json.loads((ROOT / "policy-pins.json").read_text())
POLICY = Path(os.environ.get("PALOMAR_SUBMISSION_DIR",
    ROOT.parent / "review-sources/PalomarSubmission-current")).resolve()
parser = argparse.ArgumentParser()
parser.add_argument("--workspace", required=True, type=Path)
parser.add_argument("--output", type=Path, default=ROOT.parent / "evidence/render-local")
parser.add_argument("--audit-cache", type=Path,
    help="Reuse an isolated build cache whose trusted printer source/config/toolchain match exactly")
args = parser.parse_args()
workspace, output = args.workspace.resolve(), args.output.resolve()
assert workspace != ROOT and not ROOT.is_relative_to(workspace)
assert not output.is_relative_to(ROOT), "Render evidence must stay outside submitted source"
assert not output.exists(), "Use a fresh output directory to avoid stale render evidence"
assert subprocess.check_output(["git", "-C", str(POLICY), "rev-parse", "HEAD"],
    text=True).strip() == PINS["pipeline_commit"]
subprocess.run(["git", "-C", str(POLICY), "diff", "--quiet", "HEAD", "--"], check=True)
sys.path.insert(0, str(POLICY))
from scripts.render_challenge import (
    core_notation_audit_lean_path, merge_renderer_manifest,
    trusted_lakefile, validated_audit_declarations,
)
from scripts.verify_submission import manifest_packages, shadowing_dependency
from pathlib import PurePosixPath

toolchain = (ROOT / "lean-toolchain").read_text().strip()
assert (workspace / "lean-toolchain").read_text().strip() == toolchain
verso_commit = PINS["verso_commits"][toolchain]
verso = workspace / ".lake/packages/verso"
assert subprocess.check_output(["git", "-C", str(verso), "rev-parse", "HEAD"],
    text=True).strip() == verso_commit, "Unexpected Verso checkout"
source_manifest = json.loads((ROOT / "lake-manifest.json").read_text())
verso_manifest = json.loads((verso / "lake-manifest.json").read_text())
expected_manifest = merge_renderer_manifest(source_manifest, verso_manifest, verso_commit)
assert json.loads((workspace / "lake-manifest.json").read_text()) == expected_manifest
for package in expected_manifest["packages"]:
    assert package["type"] == "git", "Reviewed local render requires pinned Git packages"
    checkout = workspace / ".lake/packages" / package["name"]
    assert not checkout.is_symlink(), "Local render dependencies must be isolated copies"
    assert subprocess.check_output(["git", "-C", str(checkout), "rev-parse", "HEAD"],
        text=True).strip() == package["rev"], package["name"]
    subprocess.run(["git", "-C", str(checkout), "diff", "--quiet", "HEAD", "--"], check=True)
config = json.loads((ROOT / "comparator.json").read_text())
assert config["challenge_module"] == "Challenge" and config["solution_module"] == "Solution"
assert (workspace / "lakefile.toml").read_text() == trusted_lakefile(
    source_manifest, verso_commit, challenge_module="Challenge",
    challenge_source_root=PurePosixPath("."))
for name in ("Challenge.lean", "Solution.lean", "comparator.json"):
    assert (workspace / name).read_bytes() == (ROOT / name).read_bytes(), name
assert shadowing_dependency("Challenge", manifest_packages(workspace),
    source=workspace, checkout=workspace) is None, "Challenge module root shadowed by dependency"

output.mkdir(parents=True)
env = os.environ.copy()
env.setdefault("LEAN_NUM_THREADS", "2")
def run(command, cwd, log_name, environment=env):
    with (output / log_name).open("w") as log:
        subprocess.run(command, cwd=cwd, env=environment, stdout=log,
            stderr=subprocess.STDOUT, check=True)

run(["lake", "build", "Challenge:literate"], workspace, "literate-build.log")
run(["lake", "exe", "verso-html", ".lake/build/literate", str(output / "raw-html")],
    workspace, "verso-html.log")

# Compile the exact official printer in a separate dependency-free project.
# No submitted environment extension initializes inside this printer.
audit = output / "core-audit"
audit.mkdir()
(audit / "PalomarAudit.lean").write_bytes((POLICY / "scripts/core_notation_audit.lean").read_bytes())
(audit / "lean-toolchain").write_text(toolchain + "\n")
(audit / "lakefile.toml").write_text('name = "PalomarCoreNotationAudit"\n'
    'defaultTargets = ["palomar-audit"]\n\n[[lean_exe]]\n'
    'name = "palomar-audit"\nroot = "PalomarAudit"\nsupportInterpreter = true\n')
if args.audit_cache:
    previous = args.audit_cache.resolve()
    assert previous != audit
    for name in ("PalomarAudit.lean", "lean-toolchain", "lakefile.toml"):
        assert (previous / name).read_bytes() == (audit / name).read_bytes(), name
    assert not (previous / ".lake").is_symlink()
    shutil.copytree(previous / ".lake", audit / ".lake")
run(["lake", "build", "palomar-audit"], audit, "core-audit-build.log")
prefix = Path(subprocess.check_output(["lake", "env", "lean", "--print-prefix"],
    cwd=workspace, env=env, text=True).strip())
lean_path = subprocess.check_output(["lake", "env", "printenv", "LEAN_PATH"],
    cwd=workspace, env=env, text=True).strip()
audit_env = env.copy()
audit_env["LEAN_PATH"] = core_notation_audit_lean_path(lean_path,
    workspace=workspace, challenge_module="Challenge", lean_prefix=prefix)
requests = []
for kind, key in (("theorem", "theorem_names"), ("def", "definition_names")):
    for name in config.get(key, []):
        requests.extend([kind, name])
declarations = config["theorem_names"] + config.get("definition_names", [])
rows = json.loads(subprocess.check_output([str(audit / ".lake/build/bin/palomar-audit"),
    "Challenge", *requests], cwd=workspace, env=audit_env, text=True))
validated_audit_declarations(rows, declarations)
audit_json = output / "trusted-declarations.json"
audit_json.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + "\n")
clean = output / "sanitized"
clean.mkdir()
run([sys.executable, str(POLICY / "scripts/render_challenge.py"), "sanitize",
    "--input-dir", str(output / "raw-html"), "--output-dir", str(clean),
    "--challenge", str(workspace / "Challenge.lean"),
    "--solution", str(workspace / "Solution.lean"),
    "--comparator", str(workspace / "comparator.json"),
    "--challenge-module", "Challenge", "--lean", str(prefix / "bin/lean"),
    "--diagnostic-out", str(output / "sanitize-diagnostic.json"),
    "--audit-declarations", str(audit_json)], workspace, "sanitize.log", audit_env)
result = {"status": "pass", "pipeline_commit": PINS["pipeline_commit"],
    "verso_commit": verso_commit, "toolchain": toolchain,
    "render_file_cap_bytes": PINS["render_file_cap_bytes"],
    "challenge_sha256": hashlib.sha256((ROOT / "Challenge.lean").read_bytes()).hexdigest(),
    "raw_challenge_html_bytes": (output / "raw-html/Challenge/index.html").stat().st_size,
    "sanitized_challenge_html_bytes": (clean / "Challenge/index.html").stat().st_size,
    "scope": "Exact local Verso, official trusted printer and sanitizer; no Linux bubblewrap or hosted run"}
(output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps(result, indent=2))
