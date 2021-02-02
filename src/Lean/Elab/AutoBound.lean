/-
Copyright (c) 2020 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/
import Lean.Data.Options

/- Basic support for auto bound implicit local names -/

namespace Lean.Elab

register_builtin_option autoBoundImplicitLocal : Bool := {
    defValue := true
    descr    := "Unbound local variables in declaration headers become implicit arguments if they are a lower case or greek letter followed by numeric digits. For example, `def f (x : Vector α n) : Vector α n :=` automatically introduces the implicit variables {α n}."
  }

private def isValidAutoBoundSuffix (s : String) : Bool :=
  s.toSubstring.drop 1 |>.all fun c => c.isDigit || isSubScriptAlnum c || c == '_' || c == '\''

/-
Remark: Issue #255 exposed a nasty interaction between macro scopes and auto-bound-implicit names.
```
local notation "A" => id x
theorem test : A = A := sorry
```
We used to use `n.eraseMacroScopes` at `isValidAutoBoundImplicitName` and `isValidAutoBoundLevelName`.
Thus, in the example above, when `A` is expanded, a `x` with a fresh macro scope is created.
`x`+macros-scope is not in scope and is a valid auto-bound implicit name after macro scopes are erased.
So, an auto-bound exception would be thrown, and `x`+macro-scope would be added as a new implicit.
When, we try again, a `x` with a new macro scope is created and this process keeps repeating.
Therefore, we do consider identifier with macro scopes anymore.
-/

def isValidAutoBoundImplicitName (n : Name) : Bool :=
  match n with
  | Name.str Name.anonymous s _ => s.length > 0 && (isGreek s[0] || s[0].isLower) && isValidAutoBoundSuffix s
  | _ => false

def isValidAutoBoundLevelName (n : Name) : Bool :=
  match n with
  | Name.str Name.anonymous s _ => s.length > 0 && s[0].isLower && isValidAutoBoundSuffix s
  | _ => false

end Lean.Elab
