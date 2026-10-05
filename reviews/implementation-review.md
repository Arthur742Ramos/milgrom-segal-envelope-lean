# Independent mathematical implementation review

Date: 2026-10-03. Reviewer: independent implementation reviewer.

Status: **Accepted for mathematical scope and proof structure.** No mathematical gap or binder mismatch was found in the reviewed core. This review does not certify a compilation, transitive axiom audit, Comparator result, or hosted preflight; those are separate gates.

Reviewed core: `milgrom-segal-envelope-lean/MilgromSegal.lean`.

SHA256: `afd689756b9a2cc7da65c2d92765c92cf8332944cddeb392f11ca22d11076ebc`.

The hash was read after the implementation author confirmed the deprecated-name replacement and successful core build. This reviewer did not run a build or modify the core. Additional examples, Challenge, and Solution files are outside this review's scope.

## Sources checked

- Paul Milgrom and Ilya Segal, *Envelope Theorems for Arbitrary Choice Sets*, Econometrica 70(2), 2002, printed pp. 585–586, PDF pages 3–4, equations (1)–(3) and Theorems 1–2: [author-hosted primary PDF](https://web.stanford.edu/~isegal/envelope.pdf).
- The workspace's `reviews/statement-review.md`, including its exact quantifier and endpoint requirements.
- The complete 253-line core, plus the local Mathlib definitions of the absolute-continuity derivative integrability and FTC results used by it.

The source's Theorem 1 gives the left upper bound, right lower bound, and interior derivative identity for a frozen optimizer. Theorem 2 gives absolute continuity from absolutely continuous fibers and a common integrable bound, followed by the integral formula under additional differentiability and almost everywhere attainment. The implementation covers these named results, without claiming the remaining paper.

## Statement-to-binder findings

1. **Arbitrary choice set and finite supremum.** Every relevant theorem quantifies over `{X : Type*} [Nonempty X]`. There is no topology, measurable space, order, finiteness, convexity, compactness, uniqueness, or selector-continuity requirement on `X`. `value` is the real indexed supremum, and `FiniteValue` explicitly requires `BddAbove (range (fun x => f x t))` at every `t ∈ [0,1]`. Nonemptiness makes these bounded-above fibers genuine nonempty finite real suprema. Each use of `le_ciSup` supplies the corresponding boundedness proof. The extension of fibers to all real arguments adds no assumptions outside the parameter interval.

2. **Exceptional null sets remain fiber-dependent.** `hbound` has the exact order `∀ x, ∀ᵐ t ∂volume, t ∈ Icc 0 1 → |deriv (f x) t| ≤ b t`. The proof never replaces it with `∀ᵐ t, ∀ x`. `fiber_increment` uses the bound for one fixed fiber. Only after its pointwise increment estimate has been established does `value_increment` quantify over the index and take suprema. No uncountable null-set intersection or measurability of a derivative supremum is used.

3. **Absolute continuity does not assume attainment.** `absolutelyContinuous_value` assumes only finite values, fiber absolute continuity, interval integrability of the common bound, and the fiber-dependent almost everywhere derivative bound. The conclusion's absolute continuity is proved, not supplied as a hypothesis. `value_increment` obtains both supremum inequalities without selecting an optimizer. `ac_of_dist_le` transfers the disjoint-interval sums in the definition from the integral primitive of the bound to the value function.

4. **The differentiability assumption is the required universal one.** Both formula lemmas and `milgrom_segal` require `∀ x, ∀ t ∈ Ioo 0 1, DifferentiableAt ℝ (f x) t`. They do not substitute per-fiber almost everywhere differentiability. Consequently the derivative identity is valid at the index chosen at that particular time.

5. **Selection uses choice alone.** Attainment is assumed only almost everywhere on the open interval. Since its omitted endpoints are Lebesgue-null, this is the requested almost everywhere attainment on the closed parameter interval. `exists_optimizer_selection` uses classical choice and an arbitrary default from the nonempty type. The universal selection statement requires only almost everywhere optimization and imposes no measurable structure on `X` or measurability of the selector.

6. **Integrability is substantive.** `selected_derivative_integrable` first derives absolute continuity of the value function, obtains `hV.intervalIntegrable_deriv`, and transfers it using almost everywhere equality of the selected derivative to `deriv (value f)`. The equality intersects only the fixed value-differentiability and attainment exceptional sets; fiber differentiability is available everywhere in the interior. In `milgrom_segal`, interval integrability is the first component of the universal selector conclusion, before the formula. The standalone `integral_envelope` also uses the genuine FTC for the derived absolutely continuous value function and almost everywhere congruence of integrands. It cannot make a nonintegrable selected derivative satisfy the claim merely through the integral's zero totalization: the separately established congruence implies its integrability. No diagonal bound on the selected derivative is asserted.

7. **Endpoints and all parts of Theorem 1.** `integral_envelope` quantifies over `Icc 0 1`, so the value formula covers both endpoints. It removes endpoint integrand values through equality of restricted interval measures, not through endpoint differentiability assumptions. The interior identity freezes one optimizer and uses the local minimum of `value f − f x`. The two one-sided lemmas establish `d ≤ D` on the right when `t < 1` (including `t = 0`) and `D ≤ d` on the left when `0 < t` (including `t = 1`). Their fiber derivative is `HasDerivWithinAt` on the parameter interval, which is the appropriate boundary interpretation. The slope denominator is positive on the right and negative on the left, with the inequality reversed in the latter proof. Neither lemma wrongly asserts an endpoint equality.

## Internal strengthening and source hygiene

The helper and individual absolute-continuity lemmas omit explicit nonnegativity of `b`. This is harmless strengthening: for a fixed fiber, the almost everywhere absolute-derivative bound forces nonnegativity almost everywhere inside the interval; the proven increment inequality suffices for the primitive-distance transfer. The named `milgrom_segal` theorem retains explicit pointwise nonnegativity on `[0,1]`, matching the requested contract.

The core contains no authored `axiom`, `sorry`, `admit`, `unsafe`, or trust-altering `set_option` declaration. Classical choice is used for the selector, and the indexed supremum is noncomputable. These are ordinary Lean constructions. This source inspection is not a claim about every transitive dependency's kernel axioms; the package's separate trusted audit must establish that gate.

The only remaining qualifications for this review are procedural: Challenge/Solution correspondence, nonvacuity examples, kernel compilation, transitive trusted-constant auditing, sanitization, and official preflight must be assessed independently. They do not change this mathematical acceptance of the hashed core.
