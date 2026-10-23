# Designer reference friction

This reference was authored with source access. It validates acceptance across
families; it is not evidence of a documentation-only executor run.

- ID: F01
- Wanted: await controller release while keeping a Closing view visible
- Read: vendor/scopo/doc/async_scope.md, Parents and children;
  vendor/scopo/doc/lite_scope.md, close()
- Gap or misunderstanding: controller scope contexts also have no direct
  close() member; waiting after removing the scope must be composed with a
  Flutter frame boundary
- Tried: checked the context declaration and removed the scope before awaiting
  the coordinator
- Outcome: resolved; the scope owns the controller, and the coordinator wait
  delays navigation until release finishes
- Suggested sentence: To await an asynchronous controller scope after removal,
  first finish the unmounting frame, then wait for the nearest coordinator from
  a context outside the removed scope.

- ID: F02
- Wanted: prevent artificial gate waits from expiring in reference tests
- Read: vendor/scopo/doc/debug.md, Timeouts
- Gap or misunderstanding: initially assumed every per-scope timeout accepted
  the unbounded marker; this section explicitly documents the
  initialization-cancellation exception
- Tried: used that marker for initialization cancellation and encountered the
  documented assertion in the reference test
- Outcome: resolved by reading the exception and retaining all default
  timeouts; this was an author misunderstanding, not missing documentation
- Suggested sentence: Before changing a timeout, check the exceptions described
  in this section; initialization cancellation does not accept the per-scope
  unbounded marker.
