# Independent mathematical statement review

Reviewer: independent statement reviewer. Date: 2026-10-03.

Status: **Accepted**, subject to the exact binder requirements below. This is a mathematical and source review before implementation; it is not a Lean compilation or proof audit.

Primary source: Paul Milgrom and Ilya Segal, *Envelope Theorems for Arbitrary Choice Sets*, Econometrica 70(2), 2002, pp. 583–601, [author-hosted PDF](https://web.stanford.edu/~isegal/envelope.pdf). The relevant material is printed pp. 585–586, PDF pages 3–4, equations (1)–(3) and Theorems 1–2.

## Source correspondence

Theorem 1 assumes an optimizer and an existing time derivative of its frozen fiber. It gives a left derivative upper bound when t > 0, a right derivative lower bound when t < 1, and equality when both the value function and frozen fiber are differentiable at an interior point. Theorem 2 assumes absolutely continuous fibers and a common integrable nonnegative bound on the absolute time derivatives. Its first conclusion is absolute continuity of the value function. Its additional differentiability and almost everywhere attainment assumptions give the integral envelope formula for an optimizer selection. The source does not impose topology or convexity on the choice set.

The requested finite real supremum assumptions make explicit a necessary convention for a real-valued formalization. Interior fiber differentiability suffices for the formula, since the endpoints have zero measure. The derivative-bound wording must be encoded explicitly rather than relying on the informal placement of “almost all.”

## Required mathematical contract

Let X be an arbitrary nonempty type, with no topological or measurable structure. Let f_x : ℝ → ℝ be fibers used only on I = [0,1]. A formal real extension outside I is harmless if all assumptions and conclusions respect this restriction. For every t ∈ I require BddAbove {f_x(t) | x ∈ X}, or equivalently give a finite V(t) and a genuine least-upper-bound specification. Define V(t) as that supremum.

For the absolute continuity conclusion require:

- Every f_x is absolutely continuous on I.
- b is Lebesgue integrable on I and nonnegative there (almost everywhere nonnegativity also suffices mathematically).
- For every fixed x, for almost every t ∈ I, |deriv f_x t| ≤ b(t). The exceptional set may depend on x.

For the formula additionally require:

- For every x and every t ∈ (0,1), f_x is differentiable at t.
- Maximizers exist for almost every t ∈ I.

For every selector σ : ℝ → X attaining the supremum almost everywhere on I, define q(t) = deriv (f_{σ(t)}) t. Conclude that q is integrable on I and that, for every t ∈ I,

V(t) = V(0) + ∫₀ᵗ q(s) ds.

Values of σ at points without an optimizer, outside I, and at endpoints may be arbitrary. Nonempty X permits these total choices. A selector contract must express attainment almost everywhere, not demand attainment at every point. A separately supplied selector is sufficient for the universal formula; a classical choice argument can also obtain one from almost everywhere existence without adding measurability on X.

## Independent proof route

For a fixed x and 0 ≤ u ≤ v ≤ 1, the fiber FTC and its own derivative bound give

|f_x(v) − f_x(u)| ≤ ∫ᵤᵛ b(s) ds.

This inequality now holds for every x and every pair of endpoints. Only at this stage take suprema. Upper bounds in both directions give

|V(v) − V(u)| ≤ ∫ᵤᵛ b(s) ds.

Neither step uses an optimizer. Neither intersects the exceptional sets of different fibers. Neither integrates a possibly nonmeasurable supremum of an uncountable family of derivative functions. Absolute continuity of the Lebesgue integral of b transfers this increment estimate to absolute continuity of V, using disjoint interval sums.

At an interior point where V is differentiable and σ attains, the function V − f_{σ(t)} has a local minimum zero while σ(t) is frozen. Its derivative is zero, proving q(t) = V'(t). All-fiber interior differentiability makes this step valid for the chosen index without diagonalizing fiber-dependent null sets. Intersect only the fixed null set where V fails to be differentiable, the fixed attainment null set, and the endpoint set. Consequently q = V' almost everywhere on I. Integrability follows by almost everywhere congruence from the integrability of V', before invoking the interval integral formula. This rules out a proof that depends on Bochner integrals being totalized to zero for nonintegrable functions.

Theorem 1's one-sided inequalities follow from f_x(s) ≤ V(s), equality at t, and division by s − t. Division reverses the inequality on the left of t. Endpoint conclusions are therefore inequalities, not derivative identities.

## Nonvacuity and regression examples

1. **No attainment needed for absolute continuity.** X = (0,1), f_x(t) = x + t. Then V(t) = 1 + t, b = 1, all fibers are smooth, and no optimizer exists at any parameter.
2. **Per-fiber almost everywhere differentiability cannot replace all-fiber interior differentiability in the formula.** X = [0,1], f_x(t) = t − |t − x|. Every fiber is absolutely continuous with derivative bounded by 2 almost everywhere. V(t) = t and the unique optimizer is x = t, but the selected frozen fiber is nondifferentiable at every interior parameter. Lean's totalized derivative is zero at those kinks, while V' = 1; the proposed weakened formula would be false.
3. **Endpoint equality is false.** With fibers 0 and t, both are optimal at t = 0; the first fiber has derivative 0 and V has right derivative 1. At t = 1, fibers 0 and t − 1 give left derivative 0 for V and derivative 1 for the second optimizing fiber.
4. **Finite suprema must be substantive.** Constant fibers f_n(t) = n have a common zero derivative bound but an infinite supremum. A real sSup totalization must not silently stand in for the required finite value hypothesis.

## Implementation review conditions

The Challenge statement must expose the derivative-bound binder as ∀ x, ∀ᵐ t, rather than assume or manufacture ∀ᵐ t, ∀ x. The formula statement must expose ∀ x, ∀ t ∈ (0,1), DifferentiableAt. The absolute continuity conclusion must have no attainment hypothesis. The formula must prove selected-derivative integrability and cover both endpoints as values of the FTC identity. If the package is described as implementing all of Theorem 1, it must include its one-sided inequalities as well as the interior equality. No part of this mathematical acceptance confirms compilation, trust auditing, or official preflight readiness.
