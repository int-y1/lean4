import Lean

open Lean
open Lean.Elab
open Lean.Elab.Term
open Lean.Elab.Command
open Lean.Format

open Lean.Meta

def checkM (stx : TermElabM Syntax) (optionsPerPos : OptionsPerPos := {}) : TermElabM Unit := do
let opts ← getOptions;
let stx ← stx;
let e ← elabTermAndSynthesize stx none <* throwErrorIfErrors;
let stx' ← liftMetaM $ delab Name.anonymous [] e optionsPerPos;
let stx' ← liftCoreM $ PrettyPrinter.parenthesizeTerm stx';
let f' ← liftCoreM $ PrettyPrinter.formatTerm stx';
IO.println $ f'.pretty opts;
let env ← getEnv;
(match Parser.runParserCategory env `term (toString f') "<input>" with
| Except.error e => throwErrorAt stx e
| Except.ok stx'' => do
  let e' ← elabTermAndSynthesize stx'' none <* throwErrorIfErrors;
  unlessM (isDefEq e e') $
    throwErrorAt stx (fmt "failed to round-trip" ++ line ++ fmt e ++ line ++ fmt e'))

-- set_option trace.PrettyPrinter.parenthesize true
set_option format.width 20

-- #eval checkM `(?m)  -- fails round-trip

#eval checkM `(Sort)
#eval checkM `(Type)
#eval checkM `(Type 0)
#eval checkM `(Type 1)
-- can't add a new universe variable inside a term...
#eval checkM `(Type _)
#eval checkM `(Type (_ + 2))

#eval checkM `(Nat)
#eval checkM `(List Nat)
#eval checkM `(id Nat)
#eval checkM `(id (id (id Nat)))
section
  set_option pp.explicit true
  #eval checkM `(List Nat)
  #eval checkM `(id Nat)
end
section
  set_option pp.universes true
  #eval checkM `(List Nat)
  #eval checkM `(id Nat)
  #eval checkM `(Sum Nat Nat)
end
#eval checkM `(id (id Nat)) (Std.RBMap.empty.insert 4 $ KVMap.empty.insert `pp.explicit true)

-- specify the expected type of `a` in a way that is not erased by the delaborator
def typeAs.{u} (α : Type u) (a : α) := ()

#eval checkM `(fun (a : Nat) => a)
#eval checkM `(fun (a b : Nat) => a)
#eval checkM `(fun (a : Nat) (b : Bool) => a)
#eval checkM `(fun {a b : Nat} => a)
-- implicit lambdas work as long as the expected type is preserved
#eval checkM `(typeAs ({α : Type} → (a : α) → α) fun a => a)
section
  set_option pp.explicit true
  #eval checkM `(fun {α : Type} [ToString α] (a : α) => toString a)
end

#eval checkM `((α : Type) → α)
#eval checkM `((α β : Type) → α)  -- group
#eval checkM `((α β : Type) → Type)  -- don't group
#eval checkM `((α : Type) → (a : α) → α)
#eval checkM `((α : Type) → (a : α) → a = a)
#eval checkM `({α : Type} → α)
#eval checkM `({α : Type} → [ToString α] → α)

-- TODO: hide `ofNat`
#eval checkM `(0)
#eval checkM `(1)
#eval checkM `(42)
#eval checkM `("hi")

set_option pp.structure_instance_type true in
#eval checkM `({ type := Nat, val := 0 : PointedType })
#eval checkM `((1,2,3))
#eval checkM `((1,2).fst)

#eval checkM `(1 < 2 || true)

#eval checkM `(id (fun a => a) 0)
