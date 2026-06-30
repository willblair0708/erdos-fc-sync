import APNOutputs.ErdosProblems.erdos_152
import APNOutputs.ErdosProblems.erdos_846
import APNOutputs.ErdosProblems.«erdos_12.parts.ii»
import APNOutputs.ErdosProblems.«erdos_125.variants.positive_lower_density»
import APNOutputs.ErdosProblems.«erdos_138.variants.difference»
import APNOutputs.ErdosProblems.«erdos_26.variants.tenenbaum»
import APNOutputs.ErdosProblems.«erdos_741.parts.ii»
open Lean Elab Command Meta
def declNames : List String := [
  "Erdos12.target_theorem_0",
  "Erdos125.target_theorem_0",
  "Erdos138.target_theorem_0",
  "Erdos152.target_theorem_0",
  "Erdos26.target_theorem_0",
  "Erdos741.target_theorem_0",
  "Erdos846.target_theorem_0"
]
def kernelAxioms : List Name := [``propext, ``Classical.choice, ``Quot.sound]
run_cmd do
  let env ← getEnv
  for s in declNames do
    let declName := s.toName
    if (env.find? declName).isNone then continue
    let axs ← liftCoreM (Lean.collectAxioms declName)
    let axList := axs.toList
    let sorryFree := !axList.contains ``sorryAx
    let nonKernel := axList.filter (fun a => !kernelAxioms.contains a && a != ``sorryAx)
    let (named, preconds) ← liftTermElabM do
      let info ← getConstInfo declName
      forallTelescope info.type fun xs _ => do
        let mut named : Array String := #[]
        let mut preconds : Array String := #[]
        for x in xs do
          let ld ← x.fvarId!.getDecl
          if (← Meta.isProp ld.type) && ld.binderInfo != BinderInfo.instImplicit then
            let nm := ld.userName.eraseMacroScopes
            let nmStr := if nm.isInternal || nm.hasMacroScopes then "_" else nm.toString
            let entry := s!"{nmStr} : {(← ppExpr ld.type).pretty.replace "\n" " "}"
            -- a problem-defined named Prop (head const in an Erdos* namespace)
            -- is a candidate smuggled assumption; everything else is a routine
            -- precondition (an inequality, membership, quantified formula, or a
            -- standard Mathlib property of the theorem's own variables).
            let isNamed := match ld.type.getAppFn with
              | .const hn _ => "Erdos".isPrefixOf hn.toString
              | _ => false
            if isNamed then named := named.push entry else preconds := preconds.push entry
        return (named, preconds)
    let verdict := if !sorryFree then "incomplete"
                   else if !named.isEmpty || !nonKernel.isEmpty then "conditional"
                   else "unconditional"
    let record : Json := Json.mkObj [
      ("schema", Json.str "vela.lean_assumption.v0.1"),
      ("decl", Json.str declName.toString),
      ("sorry_free", Json.bool sorryFree),
      ("axioms", Json.arr (axList.map (fun a => Json.str a.toString)).toArray),
      ("axiom_verdict", Json.str (if nonKernel.isEmpty then "kernel_clean" else "non_kernel_axioms")),
      ("named_assumptions", Json.arr (named.map Json.str)),
      ("preconditions", Json.arr (preconds.map Json.str)),
      ("verdict", Json.str verdict) ]
    IO.println record.compress
