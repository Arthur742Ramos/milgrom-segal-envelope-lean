import MilgromSegal

open Set MeasureTheory
open MilgromSegal

namespace MilgromSegal.Examples

/-- An infinite choice set with finite but unattained supremum at every time. -/
def NegativeChoice := {q : ℝ // q < 0}

instance : Nonempty NegativeChoice := ⟨⟨-1, by norm_num⟩⟩

def unattained (q : NegativeChoice) (t : ℝ) : ℝ := t + q.val

theorem unattained_finite : FiniteValue unattained := by
  intro t _
  refine ⟨t, ?_⟩
  rintro _ ⟨q, rfl⟩
  exact le_of_lt (by simpa [unattained] using q.property)

theorem unattained_value (t : ℝ) : value unattained t = t := by
  apply le_antisymm
  · exact ciSup_le fun q => by simp only [unattained]; linarith [q.property]
  · apply le_of_forall_lt
    intro a ha
    let q : NegativeChoice := ⟨(a - t) / 2, by linarith⟩
    have hbd : BddAbove (range (fun q => unattained q t)) := by
      refine ⟨t, ?_⟩
      rintro _ ⟨q, rfl⟩
      simp only [unattained]
      linarith [q.property]
    have hq : unattained q t ≤ value unattained t := le_ciSup hbd q
    dsimp [unattained, q] at hq
    linarith

theorem unattained_no_optimizer (t : ℝ) : ¬ ∃ q, Optimizes unattained t q := by
  rintro ⟨q, hq⟩
  change t + q.val = value unattained t at hq
  rw [unattained_value] at hq
  linarith [q.property]

/-- This applies the absolute continuity theorem despite failure of all attainment. -/
theorem unattained_ac : AbsolutelyContinuousOnInterval (value unattained) 0 1 := by
  apply absolutelyContinuous_value (b := fun _ => 1) unattained_finite
  · intro q
    apply LipschitzOnWith.absolutelyContinuousOnInterval (K := 1)
    rw [lipschitzOnWith_iff_dist_le_mul]
    intro u _ v _
    simp [unattained]
  · exact intervalIntegrable_const
  · intro q
    filter_upwards with t _
    have hd : deriv (unattained q) t = 1 := (hasDerivAt_id t).add_const q.val |>.deriv
    rw [hd]
    norm_num

/-- An uncountable choice set and a nonunique optimizer at every parameter. -/
theorem arbitrary_selection_linear (sel : ℝ → ℝ) (t : ℝ) (ht : t ∈ Icc (0 : ℝ) 1) :
    value (fun (_ : ℝ) s => s) t =
      value (fun (_ : ℝ) s => s) 0 +
        ∫ s in (0 : ℝ)..t, deriv (fun r : ℝ => r) s := by
  apply integral_envelope (b := fun _ => 1) (sel := sel)
  · intro s _
    exact ⟨s, by simp⟩
  · intro _
    apply LipschitzOnWith.absolutelyContinuousOnInterval (K := 1)
    rw [lipschitzOnWith_iff_dist_le_mul]
    simp
  · exact intervalIntegrable_const
  · intro _
    filter_upwards with s _
    simp
  · intro _ s _
    exact differentiableAt_id
  · filter_upwards with s _
    simp [Optimizes, value]
  · exact ht

end MilgromSegal.Examples
