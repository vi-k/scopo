# Designer reference friction

This is a reference-author journal, not an executor experiment. The designer
was permitted to inspect package sources; this journal does not prove that a
new user could solve the task from public documentation alone.

- ID: F01
- Wanted: keep a Closing view until an asynchronous value scope finishes
  release
- Read: vendor/scopo/README.md, overview and family selection;
  vendor/scopo/doc/async_scope.md, Parents and children;
  vendor/scopo/doc/lite_scope.md, close()
- Gap or misunderstanding: the overview made close() look generally available,
  while the value-family context has no such method; the async topic documents
  coordinator waiting but has no complete remove-frame-wait-navigation recipe
- Tried: inspected context declarations as the designer, then composed UI
  removal, endOfFrame and the documented coordinator wait
- Outcome: resolved; the reference removes the scope, waits for the unmounting
  frame, awaits the coordinator and returns home
- Suggested sentence: For asynchronous value scopes, remove the scope from the
  tree, let Flutter finish that frame, and await the nearest coordinator before
  leaving the closing view; the value context itself has no close() method.
