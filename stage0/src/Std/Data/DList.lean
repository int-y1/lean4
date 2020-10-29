/-
Copyright (c) 2018 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Leonardo de Moura
-/
namespace Std
universes u
/--
A difference List is a Function that, given a List, returns the original
contents of the difference List prepended to the given List.
This structure supports `O(1)` `append` and `concat` operations on lists, making it
useful for append-heavy uses such as logging and pretty printing.
-/
structure DList (α : Type u) :=
  (apply     : List α → List α)
  (invariant : ∀ l, apply l = apply [] ++ l)

namespace DList
variables {α : Type u}
open List

def ofList (l : List α) : DList α :=
  ⟨Append.append l, fun t => by rw appendNil; exact rfl⟩

def empty : DList α :=
  ⟨id, fun t => rfl⟩

instance : EmptyCollection (DList α) :=
  ⟨DList.empty⟩

def toList : DList α → List α
  | ⟨f, h⟩ => f []

def singleton (a : α) : DList α := {
  apply     := fun t => a :: t,
  invariant := fun t => rfl
}

def cons : α → DList α → DList α
  | a, ⟨f, h⟩ => {
    apply     := fun t => a :: f t,
    invariant := by
      intro t
      show a :: f t = a :: f [] ++ t
      rw [consAppend, h]
      exact rfl
  }

def append : DList α → DList α → DList α
  | ⟨f, h₁⟩, ⟨g, h₂⟩ => {
    apply     := f ∘ g,
    invariant := by
      intro t
      show f (g t) = (f (g [])) ++ t
      rw [h₁ (g t), h₂ t, ← appendAssoc (f []) (g []) t, ← h₁ (g [])]
      exact rfl
    }

def push : DList α → α → DList α
  | ⟨f, h⟩, a => {
    apply     := fun t => f (a :: t),
    invariant := by
      intro t
      show f (a :: t) = f (a :: nil) ++ t
      rw [h [a], h (a::t), appendAssoc (f []) [a] t]
      exact rfl
  }

instance : Append (DList α) := ⟨DList.append⟩

end DList
end Std
