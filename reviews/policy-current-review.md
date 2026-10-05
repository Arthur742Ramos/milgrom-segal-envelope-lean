# Independent current-policy review

Reviewed on 5 October 2026. The live official `main` revision is
`d4e41c1d5b0d114c4859e6e5831dc6d3ad1d0d44`. The review began with the prepared
package at `65f0154ed776cd26c224254aa57b379137f28b0d`; the coordinating agent
then updated the package to the reviewed current policy. The final inspection
below confirms those changes. This reviewer did not change package pins,
workflow, scripts, Lean sources, or metadata.

## Evidence and exact comparison

A fresh read-only connected GitHub request confirmed the new `main` SHA. The
GitHub comparison reports three intervening commits and five changed files,
matching an independent local `git diff`: `README.md`,
`scripts/verify_submission.py`, `scripts/render_challenge.py`, and their two test
files. There are 178 inserted and four deleted lines. The three commits are
`53728204bf0f4ab175a7c88a671b7d474af0c08d`,
`c18b0f4db0c64f2bcc3bf65ef121f5150a000d2a`, and merge
`d4e41c1d5b0d114c4859e6e5831dc6d3ad1d0d44`.

The complete comparison evidence is `evidence/policy-current-compare.json`.
The exact new official source is checked out cleanly, with detached HEAD, in
`review-sources/PalomarSubmission-current` under this task workspace. Its Git
objects were copied without hard links from the existing checkout and the exact
public new commit was fetched there. The existing October 1 checkout was not
modified. No credentials, hosted workflow, registry intake, or publication were
used.

Primary sources:

- [Exact comparison](https://github.com/PalomarRegistry/PalomarSubmission/compare/65f0154ed776cd26c224254aa57b379137f28b0d...d4e41c1d5b0d114c4859e6e5831dc6d3ad1d0d44)
- [Current verifier](https://github.com/PalomarRegistry/PalomarSubmission/blob/d4e41c1d5b0d114c4859e6e5831dc6d3ad1d0d44/scripts/verify_submission.py)
- [Current renderer](https://github.com/PalomarRegistry/PalomarSubmission/blob/d4e41c1d5b0d114c4859e6e5831dc6d3ad1d0d44/scripts/render_challenge.py)

## Changes that affect this package

**Con-ron now runs with exactly two workers.** The official verifier adds
`CON_RON_JOBS = 2`, and its `protected_kernels` function appends `--jobs=2` to
the con-ron command. NanoDa's command and the mandatory three-kernel policy are
unchanged. The upstream commit records that the change controls memory use across
runner profiles. The implementation supports all toolchains from the rc2 floor.

The package's existing `scripts/verification_config.py` manually constructs
commands from the unchanged `PROTECTED_KERNELS` tuple and therefore omits this
new argument. Merely updating its policy SHA would leave local replay different
from the current official replay. It should instead use the official
`protected_kernels` helper with a binary-path mapping, then validate and record
the resulting commands. No submitted `external_kernels` field should be added
to `comparator.json`.

**Dependency shadowing of the Challenge's top-level name is rejected.** New
`shadowing_dependency` and `module_root_shadowed` helpers check whether any
materialized dependency has either a directory named after the first component
of the Challenge module or a correspondingly named `.lean` file. This matters
because Lean's source lookup searches dependencies before the project. The
verification and rendering phases both repeat the check. A rejection has code
`challenge.module_root_shadowed`, field `comparator.challenge_module`, and a
submitter-owned diagnostic.

The current `Challenge` module passes the actual new helper for both the proof
package's materialized dependency closure and the merged renderer workspace's
closure. Both helper calls returned `None`. No module rename is needed.

**Literate build errors have better diagnostics.** The renderer now collects
the lines explaining an unsuccessful literate build via
`comparator_failure_excerpt`, avoiding a large trailing search-path dump.
Successful rendering behavior, renderer dependency selection, trusted declaration
printing, and sanitization are unchanged. The local render script may adopt the
new shadow check before its literate build and optionally the official error
helper, while retaining its explicit macOS confinement limitations.

## Requirements that did not change

The official reusable `.github/workflows/submission.yml` is byte-for-byte
unchanged between the two revisions. A prepared current-policy workflow should
still use `mode: full`, explicit `execution_profile: palomar-standard-v1`, the
same full pipeline SHA in both `uses` and `pipeline_commit`, `contents: read`,
and the manual-only `workflow_dispatch` trigger. Updating both SHA locations to
`d4e41c1d5b0d114c4859e6e5831dc6d3ad1d0d44` is sufficient for the workflow text.
Dispatch remains a separate, artifact-specific approval gate.

The catalogue still defaults to `palomar-namespace-16x32-v1`; an explicit standard
profile remains necessary. The standard runner remains GitHub-hosted Ubuntu
24.04/x86_64, with the same limits and profile digest
`eb97b7b548c5d016967434818f0ed48a215e7fdc15528f564ab21ff2927cfd69`.

The minimum supported toolchain remains `leanprover/lean4:v4.35.0-rc2`.
The selected rc2 toolchain passes the current official `supported_toolchain`
function. Its selected Mathlib pin remains
`065356127b1dc0016f66b7283ce0ce2c4055aa55`. The live Verso rc2 tag still resolves
to the exact compatible commit `9f8096e40b31715b1d8d5997f15a0bd832f7e37d`.
No proof dependency or toolchain change is warranted by this policy update.

`scripts/submission_contract.py`, formalization profile 4, taxonomy files,
browser preflight policy, verification profile, execution profiles,
`toolchains.json`, and the trusted `core_notation_audit.lean` source are all
unchanged. The current official request parser accepts `milgromsg001`, which
remains twelve lowercase alphanumeric characters. The current official metadata
parser and comparator configuration parser both accept the final local files.
The three author names are retained exactly as requested. No metadata edit is
needed because of this update.

The exact trusted printer source is also identical to the source used in the
already completed `evidence/render-final/core-audit` build. The per-file raw and
sanitized rendering cap remains 8,388,608 bytes. The exact actual official
`sanitize` CLI from the new revision was run against the previous raw Verso
output, identical current Challenge/Solution/comparator files, and the unchanged
trusted printer's declaration JSON. It passed without a new build or rerender.
The output HTML is byte-for-byte identical to the earlier sanitized HTML:
291,976 raw bytes, 290,188 sanitized bytes, and sanitized SHA-256
`9ad7c80bf0b3cf36187375f1f43dd073741f709225edc82d65047be18d48d25b`.
This is current sanitizer acceptance of the exact earlier raw rendering; it
does not constitute a fresh complete official rendering execution or Linux
bubblewrap audit.

Current function-call evidence is `evidence/policy-current-validation.json`.
The current sanitizer result is `evidence/policy-current-sanitizer.json`, with
its accepted artifact under `evidence/render-current-sanitized`.

## Recommended local updates and next checks

The following list records the initial recommendations. Items 1–4 have now been
implemented by the coordinating agent and independently inspected below.

1. Update `policy-pins.json` and both paired workflow SHA references to the new
   exact revision. Preserve Lean rc2, Mathlib, Verso, standard profile, request
   ID, manual trigger, and full mode.
2. Point the local tooling's default official source path to the fresh isolated
   current checkout, or supply that path through `PALOMAR_SUBMISSION_DIR`.
   Keep exact revision and clean-checkout checks.
3. Change local execution-config creation to call the official
   `protected_kernels` function, so con-ron receives `--jobs=2`. Add a local
   policy assertion for that resulting command; an assertion on the unchanged
   `PROTECTED_KERNELS` tuple alone would miss the update.
4. Use the official new shadowing check for local proof/render layout checks.
   The current layout already passes; this is a gate update, not a source rename.
5. Rerun the light policy/parser/metadata/source checks and the local Comparator
   with its new command, then record exact commands and current policy revision.
   No Lean proof edits or repeated heavy compilation are justified by these
   policy-only changes. Previously completed proof/kernel evidence remains
   accurately attributed to the old policy; new evidence should not relabel it.
6. Retain the completed current sanitizer acceptance separately from the old
   full local render result. Refresh package evidence manifests, any archived
   package, and local commit after the selected local updates are complete.

The existing older pin is reproducible, and its previous gate results are valid
as evidence for that exact revision. It should not be presented as the current
official policy after this review. A full hosted mechanical preflight still
provides checks not reproduced by local macOS execution and remains distinct
from rendering, editorial review, and registration. None was dispatched during
this review. All package changes above remain recommendations; no package file
was changed by this reviewer.

## Final inspection of the applied local updates

The current `policy-pins.json`, workflow `uses` reference, and explicit
`pipeline_commit` all equal `d4e41c1d5b0d114c4859e6e5831dc6d3ad1d0d44`.
The workflow still contains only the manual dispatch trigger, read-only contents
permissions, `mode: full`, explicit standard profile, valid `milgromsg001` ID,
and the unchanged comparator/authorization options. Its SHA-256 is
`40bf6360aa0aeda833e931c1fd5683df5b82af9689020eb522eb46a624ed3b03`.
The updated actual policy parser gate passed and recorded that same workflow
digest in the package's `evidence/policy-validation.json`.

`scripts/verification_config.py` now imports and calls the current official
`protected_kernels` helper. Its binary-path mapping includes both required
independent kernels; the recorded `evidence/configuration.log` explicitly shows
the rc2 `nanoda_bin` binary and rc2 `con-ron` binary followed by `--jobs=2`.
Its execution configuration remains outside the submitted tree, and the
submitted comparator configuration contains no `external_kernels` field.
This inspection confirms that local replay uses the new command construction,
rather than merely updating the policy SHA around the old worker behavior.

`scripts/render_local.py` now imports the current `manifest_packages` and
`shadowing_dependency` helpers and checks the merged renderer workspace before
rendering. The earlier direct independent current-helper calls already confirmed
that both the proof and renderer dependency closures pass this layout condition.
The current-policy default checkout path is used consistently in
`verify_policy.py`, `verification_config.py`, `render_local.py`, and
`check_package.py`. The new official checkout remains clean.

The exact current-policy proof/kernel gates were running serially at this final
inspection; their completed results and the coordinator's fresh current-policy
render run are to be recorded by the coordinating agent. This review does not
pre-claim those results. The independent current-parser, metadata, layout, and
sanitizer results above are complete. The prepared hosted workflow remains
undispatched, and full official hosted trust-boundary checks remain pending
artifact-specific approval.
