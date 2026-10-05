import Mathlib.MeasureTheory.Integral.IntervalIntegral.AbsolutelyContinuousFun
import Mathlib.Analysis.Calculus.LocalExtr.Basic
import Mathlib.Tactic

open Set Filter MeasureTheory
open scoped Topology

namespace MilgromSegal

/-- The choice type carries no topology or measurable structure. -/
noncomputable def value {X : Type*} (f : X → ℝ → ℝ) (t : ℝ) : ℝ := ⨆ x, f x t

/-- Explicit finiteness: real `iSup` must never be used without boundedness. -/
def FiniteValue {X : Type*} (f : X → ℝ → ℝ) : Prop :=
  ∀ t ∈ Icc (0 : ℝ) 1, BddAbove (range (fun x => f x t))

def Optimizes {X : Type*} (f : X → ℝ → ℝ) (t : ℝ) (x : X) : Prop :=
  f x t = value f t

namespace Implementation

theorem fiber_increment {f b : ℝ → ℝ}
    (hf : AbsolutelyContinuousOnInterval f 0 1)
    (hb : IntervalIntegrable b volume 0 1)
    (hbound : ∀ᵐ t ∂volume, t ∈ Icc (0 : ℝ) 1 → |deriv f t| ≤ b t)
    {u v : ℝ} (hu : u ∈ Icc (0 : ℝ) 1) (hv : v ∈ Icc (0 : ℝ) 1)
    (huv : u ≤ v) : |f v - f u| ≤ ∫ t in u..v, b t := by
  have hs : uIcc u v ⊆ uIcc (0 : ℝ) 1 := by
    simp only [uIcc_of_le huv, uIcc_of_le (by norm_num : (0 : ℝ) ≤ 1)]
    intro t ht
    exact ⟨hu.1.trans ht.1, ht.2.trans hv.2⟩
  have hsub := hf.mono hs
  rw [← hsub.integral_deriv_eq_sub, ← Real.norm_eq_abs]
  apply intervalIntegral.norm_integral_le_of_norm_le huv ?_ (hb.mono_set hs)
  filter_upwards [hbound] with t ht hmem
  simpa only [Real.norm_eq_abs] using ht ⟨hu.1.trans hmem.1.le, hmem.2.trans hv.2⟩

theorem value_increment {X : Type*} [Nonempty X] {f : X → ℝ → ℝ} {b : ℝ → ℝ}
    (hfin : FiniteValue f)
    (hf : ∀ x, AbsolutelyContinuousOnInterval (f x) 0 1)
    (hb : IntervalIntegrable b volume 0 1)
    (hbound : ∀ x, ∀ᵐ t ∂volume, t ∈ Icc (0 : ℝ) 1 → |deriv (f x) t| ≤ b t)
    {u v : ℝ} (hu : u ∈ Icc (0 : ℝ) 1) (hv : v ∈ Icc (0 : ℝ) 1)
    (huv : u ≤ v) : |value f v - value f u| ≤ ∫ t in u..v, b t := by
  have h1 : value f v ≤ value f u + ∫ t in u..v, b t := by
    apply ciSup_le
    intro x
    have hi := (abs_le.mp (fiber_increment (hf x) hb (hbound x) hu hv huv)).2
    have hx : f x u ≤ value f u := le_ciSup (hfin u hu) x
    linarith
  have h2 : value f u ≤ value f v + ∫ t in u..v, b t := by
    apply ciSup_le
    intro x
    have hi := (abs_le.mp (fiber_increment (hf x) hb (hbound x) hu hv huv)).1
    have hx : f x v ≤ value f v := le_ciSup (hfin v hv) x
    linarith
  exact abs_le.mpr ⟨by linarith, by linarith⟩

theorem ac_of_dist_le {g h : ℝ → ℝ}
    (hh : AbsolutelyContinuousOnInterval h 0 1)
    (hdom : ∀ u ∈ Icc (0 : ℝ) 1, ∀ v ∈ Icc (0 : ℝ) 1,
      dist (g u) (g v) ≤ dist (h u) (h v)) :
    AbsolutelyContinuousOnInterval g 0 1 := by
  rw [absolutelyContinuousOnInterval_iff] at hh ⊢
  intro ε hε
  obtain ⟨δ, hδ, hh⟩ := hh ε hε
  refine ⟨δ, hδ, fun E hE hlen => lt_of_le_of_lt ?_ (hh E hE hlen)⟩
  apply Finset.sum_le_sum
  intro i hi
  obtain ⟨hends, _⟩ := hE
  have he := hends i hi
  rw [uIcc_of_le (by norm_num : (0 : ℝ) ≤ 1)] at he
  exact hdom _ he.1 _ he.2

end Implementation

/-- Milgrom–Segal Theorem 2, absolute continuity without optimizer attainment. -/
theorem absolutelyContinuous_value {X : Type*} [Nonempty X]
    {f : X → ℝ → ℝ} {b : ℝ → ℝ}
    (hfin : FiniteValue f)
    (hf : ∀ x, AbsolutelyContinuousOnInterval (f x) 0 1)
    (hb : IntervalIntegrable b volume 0 1)
    (hbound : ∀ x, ∀ᵐ t ∂volume, t ∈ Icc (0 : ℝ) 1 → |deriv (f x) t| ≤ b t) :
    AbsolutelyContinuousOnInterval (value f) 0 1 := by
  let B : ℝ → ℝ := fun t => ∫ s in (0 : ℝ)..t, b s
  have hB : AbsolutelyContinuousOnInterval B 0 1 :=
    hb.absolutelyContinuousOnInterval_intervalIntegral (by simp)
  apply Implementation.ac_of_dist_le hB
  intro u hu v hv
  have hsub (t : ℝ) (ht : t ∈ Icc (0 : ℝ) 1) :
      IntervalIntegrable b volume 0 t := hb.mono_set (by
        rw [uIcc_of_le ht.1, uIcc_of_le (by norm_num : (0 : ℝ) ≤ 1)]
        exact Icc_subset_Icc le_rfl ht.2)
  have hBdiff : B v - B u = ∫ s in u..v, b s :=
    intervalIntegral.integral_interval_sub_left (hsub v hv) (hsub u hu)
  rcases le_total u v with huv | hvu
  · rw [dist_comm (value f u), Real.dist_eq, dist_comm (B u), Real.dist_eq, hBdiff]
    exact (Implementation.value_increment hfin hf hb hbound hu hv huv).trans (le_abs_self _)
  · rw [Real.dist_eq, Real.dist_eq]
    have hd : B u - B v = ∫ s in v..u, b s :=
      intervalIntegral.integral_interval_sub_left (hsub u hu) (hsub v hv)
    rw [hd]
    exact (Implementation.value_increment hfin hf hb hbound hv hu hvu).trans (le_abs_self _)

/-- Milgrom–Segal Theorem 1: freeze any optimizer at an interior time. -/
theorem derivative_identity {X : Type*} [Nonempty X] {f : X → ℝ → ℝ}
    (hfin : FiniteValue f) {t : ℝ} (ht : t ∈ Ioo (0 : ℝ) 1)
    {x : X} (hx : Optimizes f t x)
    (hfx : DifferentiableAt ℝ (f x) t)
    (hV : DifferentiableAt ℝ (value f) t) :
    deriv (value f) t = deriv (f x) t := by
  have hmin : IsLocalMin (fun s => value f s - f x s) t := by
    filter_upwards [Ioo_mem_nhds ht.1 ht.2] with s hs
    change value f t - f x t ≤ value f s - f x s
    have hle : f x s ≤ value f s := le_ciSup (hfin s ⟨hs.1.le, hs.2.le⟩) x
    rw [show f x t = value f t from hx]
    linarith
  have hz := hmin.hasDerivAt_eq_zero (hV.hasDerivAt.sub hfx.hasDerivAt)
  linarith

/-- Theorem 1's right-hand inequality, including the parameter endpoint `t = 0`.
The fiber derivative is taken within the parameter interval. -/
theorem right_derivative_inequality {X : Type*} [Nonempty X] {f : X → ℝ → ℝ}
    (hfin : FiniteValue f) {t d D : ℝ} (ht : t ∈ Icc (0 : ℝ) 1) (ht1 : t < 1)
    {x : X} (hx : Optimizes f t x)
    (hfx : HasDerivWithinAt (f x) d (Icc (0 : ℝ) 1) t)
    (hV : HasDerivWithinAt (value f) D (Ioi t) t) : d ≤ D := by
  have hlt : ∀ᶠ s in 𝓝 t, s < 1 := Iio_mem_nhds ht1
  have hnear : Icc (0 : ℝ) 1 ∈ 𝓝[>] t := by
    filter_upwards [self_mem_nhdsWithin,
      hlt.filter_mono nhdsWithin_le_nhds] with s hs hs1
    exact ⟨ht.1.trans hs.le, hs1.le⟩
  have hfSlope := (hasDerivWithinAt_iff_tendsto_slope' (by simp : t ∉ Ioi t)).mp
    (hfx.mono_of_mem_nhdsWithin hnear)
  have hVSlope := (hasDerivWithinAt_iff_tendsto_slope' (by simp : t ∉ Ioi t)).mp hV
  apply le_of_tendsto_of_tendsto hfSlope hVSlope
  filter_upwards [self_mem_nhdsWithin, hnear] with s hs hs01
  rw [slope_def_field, slope_def_field]
  apply (div_le_div_iff_of_pos_right (sub_pos.mpr hs)).mpr
  have hle : f x s ≤ value f s := le_ciSup (hfin s hs01) x
  rw [show f x t = value f t from hx]
  linarith

/-- Theorem 1's left-hand inequality, including the parameter endpoint `t = 1`. -/
theorem left_derivative_inequality {X : Type*} [Nonempty X] {f : X → ℝ → ℝ}
    (hfin : FiniteValue f) {t d D : ℝ} (ht : t ∈ Icc (0 : ℝ) 1) (ht0 : 0 < t)
    {x : X} (hx : Optimizes f t x)
    (hfx : HasDerivWithinAt (f x) d (Icc (0 : ℝ) 1) t)
    (hV : HasDerivWithinAt (value f) D (Iio t) t) : D ≤ d := by
  have hgt : ∀ᶠ s in 𝓝 t, 0 < s := Ioi_mem_nhds ht0
  have hnear : Icc (0 : ℝ) 1 ∈ 𝓝[<] t := by
    filter_upwards [self_mem_nhdsWithin,
      hgt.filter_mono nhdsWithin_le_nhds] with s hs hs0
    exact ⟨hs0.le, hs.le.trans ht.2⟩
  have hfSlope := (hasDerivWithinAt_iff_tendsto_slope' (by simp : t ∉ Iio t)).mp
    (hfx.mono_of_mem_nhdsWithin hnear)
  have hVSlope := (hasDerivWithinAt_iff_tendsto_slope' (by simp : t ∉ Iio t)).mp hV
  apply le_of_tendsto_of_tendsto hVSlope hfSlope
  filter_upwards [self_mem_nhdsWithin, hnear] with s hs hs01
  rw [slope_def_field, slope_def_field]
  apply (div_le_div_right_of_neg (sub_neg.mpr hs)).mpr
  have hle : f x s ≤ value f s := le_ciSup (hfin s hs01) x
  rw [show f x t = value f t from hx]
  linarith

/-- Any a.e. optimizer selection has an integrable frozen-fiber derivative.
No measurable structure on the choice type, or measurability of `sel`, is assumed. -/
theorem selected_derivative_integrable {X : Type*} [Nonempty X]
    {f : X → ℝ → ℝ} {b : ℝ → ℝ}
    (hfin : FiniteValue f)
    (hf : ∀ x, AbsolutelyContinuousOnInterval (f x) 0 1)
    (hb : IntervalIntegrable b volume 0 1)
    (hbound : ∀ x, ∀ᵐ t ∂volume, t ∈ Icc (0 : ℝ) 1 → |deriv (f x) t| ≤ b t)
    (hdiff : ∀ x, ∀ t ∈ Ioo (0 : ℝ) 1, DifferentiableAt ℝ (f x) t)
    (sel : ℝ → X)
    (hsel : ∀ᵐ t ∂volume, t ∈ Ioo (0 : ℝ) 1 → Optimizes f t (sel t)) :
    IntervalIntegrable (fun t => deriv (f (sel t)) t) volume 0 1 := by
  have hV := absolutelyContinuous_value hfin hf hb hbound
  apply hV.intervalIntegrable_deriv.congr_ae
  rw [uIoc_of_le (by norm_num : (0 : ℝ) ≤ 1), ← restrict_Ioo_eq_restrict_Ioc]
  change ∀ᵐ t ∂volume.restrict (Ioo (0 : ℝ) 1), deriv (value f) t = deriv (f (sel t)) t
  rw [ae_restrict_iff' measurableSet_Ioo]
  filter_upwards [hV.ae_differentiableAt, hsel] with t ht hs hmem
  exact derivative_identity hfin hmem (hs hmem) (hdiff _ _ hmem)
    (ht (by simpa [uIcc_of_le (by norm_num : (0 : ℝ) ≤ 1)] using (show _ ∈ Icc (0 : ℝ) 1 from ⟨hmem.1.le, hmem.2.le⟩)))

/-- Milgrom–Segal Theorem 2, integral envelope formula, including `t = 0` and `t = 1`.
The selection is arbitrary off the full-measure set of attainment. -/
theorem integral_envelope {X : Type*} [Nonempty X]
    {f : X → ℝ → ℝ} {b : ℝ → ℝ}
    (hfin : FiniteValue f)
    (hf : ∀ x, AbsolutelyContinuousOnInterval (f x) 0 1)
    (hb : IntervalIntegrable b volume 0 1)
    (hbound : ∀ x, ∀ᵐ t ∂volume, t ∈ Icc (0 : ℝ) 1 → |deriv (f x) t| ≤ b t)
    (hdiff : ∀ x, ∀ t ∈ Ioo (0 : ℝ) 1, DifferentiableAt ℝ (f x) t)
    (sel : ℝ → X)
    (hsel : ∀ᵐ s ∂volume, s ∈ Ioo (0 : ℝ) 1 → Optimizes f s (sel s))
    {t : ℝ} (ht : t ∈ Icc (0 : ℝ) 1) :
    value f t = value f 0 + ∫ s in (0 : ℝ)..t, deriv (f (sel s)) s := by
  have hV := absolutelyContinuous_value hfin hf hb hbound
  have hsub : uIcc (0 : ℝ) t ⊆ uIcc (0 : ℝ) 1 := by
    rw [uIcc_of_le ht.1, uIcc_of_le (by norm_num : (0 : ℝ) ≤ 1)]
    exact Icc_subset_Icc le_rfl ht.2
  have heq : (fun s => deriv (value f) s) =ᵐ[volume.restrict (Ioo (0 : ℝ) 1)]
      (fun s => deriv (f (sel s)) s) := by
    change ∀ᵐ s ∂volume.restrict (Ioo (0 : ℝ) 1), deriv (value f) s = deriv (f (sel s)) s
    rw [ae_restrict_iff' measurableSet_Ioo]
    filter_upwards [hV.ae_differentiableAt, hsel] with s hs hopt hmem
    exact derivative_identity hfin hmem (hopt hmem) (hdiff _ _ hmem)
      (hs (by simpa [uIcc_of_le (by norm_num : (0 : ℝ) ≤ 1)] using (show _ ∈ Icc (0 : ℝ) 1 from ⟨hmem.1.le, hmem.2.le⟩)))
  have heqt : (fun s => deriv (value f) s) =ᵐ[volume.restrict (uIoc (0 : ℝ) t)]
      (fun s => deriv (f (sel s)) s) := by
    rw [uIoc_of_le ht.1, ← restrict_Ioo_eq_restrict_Ioc]
    exact ae_restrict_of_ae_restrict_of_subset (Ioo_subset_Ioo le_rfl ht.2) heq
  have hftc := (hV.mono hsub).integral_deriv_eq_sub
  have hi := intervalIntegral.integral_congr_ae_restrict heqt
  linarith

/-- A.e. attainment yields an optimizer selection by choice alone. -/
theorem exists_optimizer_selection {X : Type*} [Nonempty X] {f : X → ℝ → ℝ}
    (hopt : ∀ᵐ t ∂volume, t ∈ Ioo (0 : ℝ) 1 → ∃ x, Optimizes f t x) :
    ∃ sel : ℝ → X, ∀ᵐ t ∂volume, t ∈ Ioo (0 : ℝ) 1 → Optimizes f t (sel t) := by
  classical
  let sel : ℝ → X := fun t => if h : ∃ x, Optimizes f t x then Classical.choose h
    else Classical.arbitrary X
  refine ⟨sel, ?_⟩
  filter_upwards [hopt] with t ht hmem
  have h := ht hmem
  simpa only [sel, dite_eq_left h] using Classical.choose_spec h

/-- Full integral-envelope conclusion of Milgrom–Segal Theorem 2 on an arbitrary
nonempty choice type, with explicit finite values and a nonnegative common bound. -/
theorem milgrom_segal {X : Type*} [Nonempty X] {f : X → ℝ → ℝ} {b : ℝ → ℝ}
    (hfin : FiniteValue f)
    (hf : ∀ x, AbsolutelyContinuousOnInterval (f x) 0 1)
    (hb : IntervalIntegrable b volume 0 1)
    (_hb0 : ∀ t ∈ Icc (0 : ℝ) 1, 0 ≤ b t)
    (hbound : ∀ x, ∀ᵐ t ∂volume, t ∈ Icc (0 : ℝ) 1 → |deriv (f x) t| ≤ b t)
    (hdiff : ∀ x, ∀ t ∈ Ioo (0 : ℝ) 1, DifferentiableAt ℝ (f x) t)
    (hopt : ∀ᵐ t ∂volume, t ∈ Ioo (0 : ℝ) 1 → ∃ x, Optimizes f t x) :
    AbsolutelyContinuousOnInterval (value f) 0 1 ∧
    (∃ sel : ℝ → X, ∀ᵐ t ∂volume, t ∈ Ioo (0 : ℝ) 1 → Optimizes f t (sel t)) ∧
    ∀ sel : ℝ → X,
      (∀ᵐ t ∂volume, t ∈ Ioo (0 : ℝ) 1 → Optimizes f t (sel t)) →
      IntervalIntegrable (fun t => deriv (f (sel t)) t) volume 0 1 ∧
      ∀ t ∈ Icc (0 : ℝ) 1,
        value f t = value f 0 + ∫ s in (0 : ℝ)..t, deriv (f (sel s)) s := by
  refine ⟨absolutelyContinuous_value hfin hf hb hbound,
    exists_optimizer_selection hopt, fun sel hs => ?_⟩
  exact ⟨selected_derivative_integrable hfin hf hb hbound hdiff sel hs,
    fun t ht => integral_envelope hfin hf hb hbound hdiff sel hs ht⟩

end MilgromSegal
