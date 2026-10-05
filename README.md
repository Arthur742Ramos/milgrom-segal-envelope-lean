# Milgrom–Segal Envelope Theorems for Arbitrary Choice Sets

Lean proofs of Theorems 1 and 2 of Paul Milgrom and Ilya Segal,
[“Envelope Theorems for Arbitrary Choice Sets”](https://web.stanford.edu/~isegal/envelope.pdf),
Econometrica 70(2), 2002, pp. 585–586.

Authors: Arthur Freitas Ramos; David Barros Hulak; Ruy Jose Guerra Barretto de Queiroz.

The choice type `X` is arbitrary and nonempty. It has no topology, convexity,
compactness or measurable structure. The value is the actual real supremum of
the fibers. `FiniteValue f` explicitly requires that each range is bounded above
at every parameter in `[0,1]`, so real supremum totalization cannot create a
vacuous result. Functions are represented on `ℝ` and all substantive hypotheses
are restricted to `[0,1]`; their values outside that interval are irrelevant.

Theorem 1 includes the frozen-optimizer derivative identity at interior
differentiability points and the right/left derivative inequalities on their
respective valid sides, including `t = 0` and `t = 1`. Equality is not asserted at
the endpoints.

Theorem 2 first derives absolute continuity of the supremum without assuming
attainment. Every fiber is absolutely continuous, and there is one interval
integrable bound `b` with
`∀ x, ∀ᵐ t, t ∈ [0,1] → |deriv (f x) t| ≤ b t`.
The exceptional null set may depend on `x`. The proof applies FTC to each fixed
fiber, bounds its increments, takes suprema, and transfers the absolute
continuity of the primitive of `b` to the value function. It never takes an
uncountable intersection of full-measure sets or integrates an unverified
pointwise supremum of derivatives.

For the integral formula the additional differentiability hypothesis is
`∀ x, ∀ t ∈ (0,1), DifferentiableAt ℝ (f x) t`. Maximizers need only exist almost
everywhere. Choice constructs a selection, and every selection that optimizes
almost everywhere satisfies the formula for every `t ∈ [0,1]`. No selector
measurability is assumed. The selected frozen-fiber derivative equals `V′`
almost everywhere; its interval integrability follows from that equality before
FTC is used. The named `milgrom_segal` theorem includes an explicit nonnegative
bound, selection existence, integrability and the formula. The internal absolute
continuity lemma is slightly stronger and does not need a separate positivity
hypothesis.

## Files and contracts

- `MilgromSegal.lean`: proofs, with auxiliary arguments in `Implementation`.
- `Examples.lean`: an infinite choice family with supremum never attained, and
  an uncountable family with every choice optimal and arbitrary selections.
- `Challenge.lean`: standalone definitions and eight research contracts. The
  theorem proofs are deliberate Comparator placeholders. This module imports
  Mathlib only and has no dependency on the implementation.
- `Solution.lean`: imports the proved library; no proof holes or custom axioms.
- `AllConstantsAudit.lean`: transitive axiom audit of every authored namespace
  constant, including internal and generated helper declarations and examples.
- `reviews/`: independent mathematical, implementation and policy reviews.

The only permitted axioms are Lean's `propext`, `Quot.sound` and `Classical.choice`.
Challenge placeholders are not part of the proved solution's dependency graph.

## Reproduction and scope of verification

Use Lean `v4.35.0-rc2` and the exact Mathlib commit in `lakefile.toml` and
`lake-manifest.json`. `lake build` compiles the library, contracts, solution and
examples. `lake env lean AllConstantsAudit.lean` audits transitive axioms.
`scripts/verify_local.sh` also runs the official Comparator with the bundled
Lean, NanoDa and con-ron kernels. Set `PALOMAR_SUBMISSION_DIR` to a clean checkout
of the exact official policy commit in `policy-pins.json`.

The local macOS Comparator runs without Linux bubblewrap. Its kernel result is
recorded separately from Linux sandbox confinement. The prepared
`.github/workflows/palomar-preflight.yml` calls the official reusable workflow in
`full` mode, with paired full commit pins and explicit `palomar-standard-v1`.
It has a manual trigger only. No hosted workflow or registry intake has been
performed. `scripts/render_local.py` uses pinned Verso, the official separate
trusted declaration printer and the actual sanitizer with its 8 MiB file cap.

See `evidence/status.json` for the achieved gates and limits for the exact local
artifact. Repository creation, push, hosted dispatch, submission and registration
require separate artifact-specific approval.

## Relation to prior work and quantifier regressions

[Econlib's Danskin module at commit 003655cc](https://github.com/danlyng/Econlib/blob/003655ccf010cdf44c4f67d6675167b54ce0e9df/Econlib/Math/Analysis/Danskin.lean)
develops compact continuous convex Danskin results and smoother envelope
corollaries. Its file documentation explicitly assumes a compact topological
choice space, joint continuity and parameter-fiber convexity for its central
results. The present contracts concern the arbitrary-choice, absolute-continuity
statements above. This comparison is bounded and makes no exhaustive novelty or
first-formalization claim.

The all-fibers/all-interior-times assumption cannot be replaced by each fiber
being differentiable almost everywhere. For `X = [0,1]` and
`f(x,t) = t − |t − x|`, each fiber is Lipschitz with common bound 2 and is
differentiable except at `t = x`. The value is `V(t) = t`, with unique optimizer
`x = t`. Every selected frozen fiber is nondifferentiable at its selected time;
Lean's totalized derivative is zero there, although `V′ = 1`. See the independent
statement review for this regression and the endpoint and finite-supremum checks.
This counterexample is reviewed mathematics; the separately compiled positive
examples are in `Examples.lean`.

The package formalizes these two named theorems, not the entire paper or its
economic applications. Independent reviews are AI reviews; no human specialist
review or original-author endorsement is claimed.
