- ID: F01
- Wanted: Find the AsyncDataScope and AsyncScope topic files locally.
- Read: /Users/user/.claude/jobs/715c8327/tmp/r7/vendor/scopo/README.md,
  Documentation table.
- Gap or misunderstanding: I inferred AsyncDataScope.md and AsyncScope.md from
  the topic names; the local files use snake_case names instead.
- Tried: Reading doc/AsyncDataScope.md and doc/AsyncScope.md returned "No such
  file or directory"; enumerated the permitted doc directory.
- Outcome: Resolved by reading doc/async_data_scope.md and doc/async_scope.md.
  The README does say doc/*.md, but does not map names.
- Suggested sentence: "The AsyncDataScope and AsyncScope topics are stored
  locally as doc/async_data_scope.md and doc/async_scope.md."

- ID: F02
- Wanted: Keep resource ownership exclusive without timeout-based overlap.
- Read: /Users/user/.claude/jobs/715c8327/tmp/r7/vendor/scopo/README.md,
  scopeKey;
  /Users/user/.claude/jobs/715c8327/tmp/r7/vendor/scopo/doc/async_scope.md,
  scopeKey and the coordinator;
  /Users/user/.claude/jobs/715c8327/tmp/r7/vendor/scopo/doc/debug.md, Timeouts;
  /Users/user/.claude/jobs/715c8327/tmp/r7/vendor/api/scopo/AsyncScopeBase/initCancellationTimeout.html,
  initCancellationTimeout property.
- Gap or misunderstanding: I generalized the ScopeTimeout.none override to
  initCancellationTimeout before reading its documented exception. The
  exception exists in debug.md and the member documentation, so this was my
  misunderstanding rather than an absent explanation.
- Tried: Set all four AsyncDataScope timeout overrides to ScopeTimeout.none.
  Widget tests reported "ScopeTimeout.none is not accepted by
  initCancellationTimeout."
- Outcome: Resolved by using the documented global
  ScopeConfig.defaultInitCancellationTimeout = null and removing that local
  override. The other waits retain local ScopeTimeout.none overrides.
- Suggested sentence: "For unbounded ownership, use the global cancellation
  default; initCancellationTimeout alone rejects ScopeTimeout.none locally."

- ID: F03
- Wanted: Handle an opening failure that arrives after Leave without a late
  error screen or an unhandled Flutter error.
- Read:
  /Users/user/.claude/jobs/715c8327/tmp/r7/vendor/scopo/doc/async_scope.md,
  Errors; Disposal, in order; What goes through the context, and what does not.
- Gap or misunderstanding: A bare open returning late is safely released, but a
  bare open throwing during cancellation is reported. I initially treated those
  outcomes as equivalent. The disposal section explains the reporting, but the
  short bare-call example does not show a failing open.
- Tried: The late-failure widget test received StateError: Cannot open a
  through tester.takeException(). Read the cancellation checkpoint guidance.
- Outcome: Resolved by checking cancellation in the acquisition error handler
  before rethrowing an active opening error. Successful late returns still go
  directly to scopo for disposal.
- Suggested sentence: "If a bare acquisition can fail after removal, catch its
  error, call ctx.check() to accept pending cancellation, then rethrow when the
  initialization is still active."

- ID: F04
- Wanted: Confirm the cancellation checkpoint signature in the API reference.
- Read:
  /Users/user/.claude/jobs/715c8327/tmp/r7/vendor/scopo/doc/async_scope.md,
  What goes through the context, and what does not; attempted API page
  /Users/user/.claude/jobs/715c8327/tmp/r7/vendor/api/scopo/ScopeInitContext/check.html.
- Gap or misunderstanding: I expected the inherited check method to have a
  local ScopeInitContext/check.html page.
- Tried: Reading that page returned "No such file or directory". Enumerated
  matching API filenames instead of retrieving source definitions.
- Outcome: Resolved using the public topic's explicit ctx.check() example and
  compiler validation; no inherited member page was needed.
- Suggested sentence: "ctx.check() is inherited from JobContext and is shown
  here because the local scopo reference may not include its own member page."
