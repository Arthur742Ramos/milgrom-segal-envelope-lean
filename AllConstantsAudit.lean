import Solution
import Examples
import Lean.Util.CollectAxioms

open Lean in
run_cmd do
  let env ← getEnv
  let allowed := #[`propext, `Quot.sound, `Classical.choice]
  let mut count : Nat := 0
  for (name, _) in env.constants.toList do
    if (`MilgromSegal).isPrefixOf name then
      let axioms ← collectAxioms name
      for ax in axioms do
        unless allowed.contains ax do
          throwError "Unexpected axiom {ax} in {name}"
      logInfo m!"{name}: {axioms}"
      count := count + 1
  unless count ≥ 20 do
    throwError "Audit coverage too small: {count}"
  logInfo m!"All {count} authored namespace constants use only standard axioms."
