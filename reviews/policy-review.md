# Independent package policy review

Reviewed on 3 October 2026. This review covers the official submission contract,
the prepared workflow, and local verification tooling. It does not certify the
mathematics, a compiled proof, a completed kernel replay, or a completed render.
No repository was created, pushed, registered, or submitted, and no hosted
workflow was dispatched.

## Exact official revision and compatible dependencies

The read-only connected GitHub API returned official `main` at
`65f0154ed776cd26c224254aa57b379137f28b0d`, matching the existing clean local
checkout at `2026-10-01/task-3/review-sources/PalomarSubmission`.
The direct shell network request failed under the restricted execution network;
the connected GitHub read succeeded. Evidence is retained in
`evidence/policy-live-refs.json`.

The policy's `toolchains.json` schema 2 requires at least `v4.35.0-rc2`.
The selected Mathlib commit `065356127b1dc0016f66b7283ce0ce2c4055aa55` declares
`leanprover/lean4:v4.35.0-rc2`, confirmed by a live read of that exact commit.
The compatible Verso release is pinned to
`9f8096e40b31715b1d8d5997f15a0bd832f7e37d`; the live `v4.35.0-rc2` tag resolves
to that commit. Thus the selected rc2 package meets the registry minimum and
does not depend on substituting a different Lean toolchain.

The earlier indexed Mathlib commit `302343bb9a029d4edab4f736703f0736896c1b64`
declares rc3. It cannot be silently substituted into the rc2 package. Its exact
compatible Verso commit is `8fc7a297f14d5adc1a551b5b4ecf283c08bd691f`.
`policy-pins.json` retains both reviewed Verso mappings while explicitly selecting
the rc2 Mathlib/toolchain pair.

Primary policy and exact source links:

- [Official revision](https://github.com/PalomarRegistry/PalomarSubmission/tree/65f0154ed776cd26c224254aa57b379137f28b0d)
- [Toolchain minimum](https://github.com/PalomarRegistry/PalomarSubmission/blob/65f0154ed776cd26c224254aa57b379137f28b0d/toolchains.json)
- [Selected Mathlib toolchain](https://github.com/leanprover-community/mathlib4/blob/065356127b1dc0016f66b7283ce0ce2c4055aa55/lean-toolchain)
- [Exact rc2 Verso source](https://github.com/leanprover/verso/tree/9f8096e40b31715b1d8d5997f15a0bd832f7e37d)

## Prepared full hosted preflight

The local `.github/workflows/palomar-preflight.yml` calls the official reusable
`submission.yml` at the full 40-character SHA above and supplies exactly the same
SHA in `pipeline_commit`. It uses `mode: full`, supplies `comparator.json`
explicitly, uses read-only contents permissions, and has only the manual
`workflow_dispatch` trigger. Preparing this file does not dispatch it.

The official parser in `scripts/submission_contract.py`, rather than the README
example, is authoritative for request IDs. Its exact regex is
`^[0-9a-z]{12}$`. The selected `milgromsg001` passes the actual parser. The
README's sample `preflight001` is 11 characters and fails that contract. An
initial local candidate `milgromseg001` was 13 characters and was corrected
before the passing validation was recorded.

The workflow explicitly selects `execution_profile: palomar-standard-v1`.
This is essential: the current `execution-profiles.json` catalogue default is
`palomar-namespace-16x32-v1`. Leaving the input blank would select Namespace.
The standard profile is GitHub-hosted Ubuntu 24.04 on x86_64, with a 350-minute
job timeout, 19,800-second execution budget, at least 20 GiB free workspace,
and a minimum memory capacity of 15,032,385,536 bytes. Its profile digest is
`eb97b7b548c5d016967434818f0ed48a215e7fdc15528f564ab21ff2927cfd69`.

`scripts/verify_policy.py` was executed successfully. It validates the clean
official checkout, SHA pairing, manual-only trigger, full mode, explicit standard
profile, exact selected toolchain/Mathlib pair, official request parser, bundled
kernel constants, and 8 MiB render cap. Its result is
`evidence/policy-validation.json`. The repository and all-zero SHA used for the
local parser invocation are dry-parse stand-ins; they establish no public
repository or source availability. The hosted workflow will receive actual
`${{ github.repository }}` and `${{ github.sha }}` values.

## Comparator contract and Challenge placeholders

The submitted `comparator.json` must contain only official allowed fields.
Its permitted axiom set must be limited to `Classical.choice`, `Quot.sound`, and
`propext`. A submitted `external_kernels` field is rejected. The official runner
injects separate protected commands for the toolchain's `nanoda_bin` and
`con-ron`, alongside Lean's default kernel. Setting or omitting `enable_nanoda`
does not disable the mandatory official independent kernel checks.

The requirement for zero authored library/Solution sorries is compatible with
customary named theorem placeholders in a standalone Challenge. Such placeholders
must be stated explicitly in the package documentation as contract holes.
Comparator compares theorem signatures, while genuine selected definition bodies
must agree between Challenge and Solution. The Challenge therefore must contain
the actual mathematical definitions and selected declaration names. It must
not merely alias the implementation, import the submitted proof namespace, or
substitute decorative `True` contracts. All implementation/Solution proofs and
definition bodies must remain complete, and their axiom closure must exclude
`sorryAx` and custom axioms. If the final package elects a fully proved Challenge,
it must still pass the measured rendering gate described below.

Only canonical allowlisted statement dependencies may occur in the standalone
Challenge's transitive source closure. The canonical official compilation does
not use candidate Lake configuration and publishes Challenge under a protected
per-run namespace. A local ordinary `lake comparator` pass does not reproduce
this provenance boundary.

The official source also sets Challenge bounds of 100 KiB and 1,000 lines, while
the general submitted Lean source bound is 10,000 lines per source. All authored
Lean modules require the `module` header. Full Git dependency revisions must
be 40-character SHA pins; submodules and LFS pointers are unsuitable.

## Prepared local replay and rendering gates

`scripts/verification_config.py` invokes the actual official configuration
loader, verifies the exact clean policy revision, locates both bundled independent
kernels, and writes its local execution-only config outside the submission tree.
`scripts/verify_local.sh` prepares that config and serially builds Challenge,
Solution, the package, the axiom audit, and the contract audit before replaying
the comparator and requiring acceptance from all three kernels. On macOS it
uses Comparator's explicit no-sandbox option because Linux bubblewrap is absent.
This is an accurately scoped local check, not the official Linux trust boundary.
These scripts were syntax-checked, but their heavy proof commands were not run
by this reviewer. They require the final Challenge, Solution, Audit,
ContractAudit, comparator configuration, and a completed dependency cache.

`scripts/render_local.py` operates on a separately prepared official render
workspace. It requires the exact trusted Lakefile and merged manifest output of
the pinned renderer, isolated copied dependency checkouts at their exact revisions,
and identical Challenge/Solution/comparator bytes. It builds `Challenge:literate`,
runs actual `verso-html`, builds the official trusted declaration printer in a
separate dependency-free project, checks its request list against every selected
theorem and definition, and calls the unchanged official `sanitize` CLI with that
trusted declaration JSON. It never fabricates an audit from `#print` output.
The official printer loads submitted environment extensions with `loadExts :=
false` and prints signatures in a separate trusted Lean environment with notation
disabled. The script writes outside the submitted package and reports its local
confinement limits explicitly.

The official sanitizer has an 8,388,608-byte per-file cap. It checks raw generated
files before HTML sanitization, and checks the resulting artifact again. A size
measurement or a call to only `static_html_sanitize` is insufficient to establish
acceptance. The actual `sanitize` command must pass and retain the selected
declaration anchors and trusted audit data.

The existing Border example is useful as a replay/configuration pattern, but its
original fully proved Challenge generated a 12,934,233-byte HTML page from only
28,211 Lean bytes and failed this cap. Most expansion was repeated tactic-state
markup. Its prior success cannot certify this package's rendering. Challenge
theorem placeholders, where permitted by the chosen contract, avoid copying long
implementation proof scripts into the public statement page.

## Remaining gates and limits

The full named mathematics, exact theorem binders, all authored constants' axiom
closures, final metadata author names and classifications, final Challenge
source closure, complete local compilation, three-kernel acceptance, exact
render/sanitizer output, and source/archive hashes remain to be checked against
the final package. The prepared scripts are supporting deliverables, not
completed evidence for those gates.

The official full hosted mechanical preflight additionally supplies Linux
bubblewrap, canonical frozen Challenge provenance, fresh submitted Lake state,
and the production policy/resource checks. Even a passing full mechanical
preflight is advisory and does not perform Challenge rendering, editorial review,
or registration. Publication, hosted dispatch, intake, and registration remain
subject to artifact-specific approval and were not attempted here.
