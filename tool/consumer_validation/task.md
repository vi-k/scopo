# Resource desk

Build a small Flutter application using scopo to own an asynchronous resource.
Budget: about one hour. The lifecycle must be managed by scopo; choose the
appropriate family using its public documentation. Ordinary UI state for
navigation, the selected id, retry identity, and the closing view is fine. Do
not replace the resource lifecycle with a hand-written StatefulWidget and
loading/disposal flags. Do not modify lib/backend.dart or bypass its methods.

## Entry point and observable contract

Keep Widget buildApp(Backend backend) in lib/app.dart. It returns the complete
app, accepts the supplied backend instance, and does not call runApp. Keep
lib/main.dart runnable. Use ValueKey<String> with the exact names below; a key
identifies a single visible widget. Buttons must be enabled in the stated
states. No particular layout, navigation API, or scopo API is required.

Initially show a home view keyed home, with a button keyed open labelled Open.
Opening always selects resource id a. The resource view has these states:

| State | Required visible content and actions |
| --- | --- |
| Opening or waiting to open id | loading, text Loading a (or Loading b); leave button labelled Leave |
| Ready | the provided ResourceChild(resource: acquiredResource); leave, switch, close buttons labelled Leave, Switch, Close |
| Opening failed | error, text Open failed a (or Open failed b), plus the actual error message; retry and leave buttons labelled Retry, Leave |
| Closing | closing, text Closing; no ResourceChild, no interactive resource actions |

ResourceChild supplies data (text Data a or Data b) and the use button. Mount
this exact provided widget only while ready. Its resource must match the
current id. It uses the resource at mount, on Use, and one last time in
dispose. Do not copy it, replace it, edit it, or catch/suppress its errors.

All names in the table such as loading, error, closing are keys, not required
literal captions. The ready branch also contains a switch button keyed switch
and a close button keyed close. Use leave, retry, open as the respective button
keys. Home and resource states are mutually exclusive.

## Required lifecycle behavior

1. Open starts exactly one acquisition through backend.open(id), displays the
   loading state while it is pending, and displays the acquired data afterward.
2. Leave returns to home immediately, including during opening or after an
   error. If opening finishes after Leave, its result must still be closed
   exactly once. No late UI update, unhandled exception, or leaked resource.
3. An opening error is visible. Retry performs a new acquisition of the same
   id, displays loading, and can reach data after a successful attempt.
4. Switch alternates a and b. Unmount the old resource child, close the old
   resource, and finish that close BEFORE starting the next acquisition. Show
   loading for the newly selected id while waiting. One press is one switch.
5. Close first removes the resource child and shows Closing. Keep this screen
   visible until asynchronous release has finished; only then return to home.
   The child's dispose must finish before resource.close starts. Apply the same
   child-before-resource ordering to Leave and Switch. Leave may show home
   while the asynchronous release proceeds; Close must await it.

At most one live acquired resource per app. Close every acquired resource
exactly once, on normal exit as well as exceptional paths. Use scopo for
ownership, replacement serialization and awaited teardown. Do not call the
backend's test-control methods from application code, inspect its journal to
drive behavior, introduce arbitrary waits to simulate ownership, globally
suppress errors, or change package sources. Normal repeated use after returning
home must work too. App unmount must also release its resource.

## Backend and tests

Read lib/backend.dart: it is fixed exercise infrastructure. Backend() uses
short real-time delays. Tests can use holdOpens/holdCloses, releaseOpen(id),
releaseClose(id), failNextOpen(id), events, liveResources and useAfterClose.
Releasing a gate affects currently pending operations only. A failure consumes
one opening attempt and allocates no resource. Events include open:id,
opened:id, failed:id, close:id, closed:id and use:id:mount/tap/dispose. Backend
operations have no upper bound on duration: an opening or a release may outlast
any default time limit of the package, and every requirement above still holds.

Real event-loop time matters: some teardown work in the package runs outside
the fake clock of widget tests. In your own tests, alternate short real waits
inside tester.runAsync with tester.pump; pumpAndSettle alone is insufficient.
Removing or raising a time limit is allowed; switching off how a failure or an
expired limit is reported is not. Write your own meaningful widget tests,
covering the lifecycle as well as the visible screen. Finish with green fvm
flutter analyze and fvm flutter test. Do not add dependencies beyond the
provided scopo, Flutter/flutter_test and packages already present in the pub
cache. Keep Flutter 3.38.1 selected with the provided .fvmrc and SDK symlink.

For temporary files, from your application root set TMPDIR to $PWD/.review-tmp
and create that directory. If using mktemp, supply an explicit template beneath
that directory. Use fvm flutter and fvm dart for all SDK work.

## Documentation boundary

You may read and search your own application workspace, and these public
materials (including code examples within them):

- @VENDOR@/scopo/README.md
- @VENDOR@/scopo/CHANGELOG.md
- @VENDOR@/scopo/doc/
- @VENDOR@/scopo/example/
- @VENDOR@/scopo/ide/
- @VENDOR@/api/ (HTML API reference)
- @VENDOR@/async_job_api/ (HTML API
  reference of async_job, which scopo builds on: JobContext and its check()
  link out to pub.dev from the scopo pages, and are documented here offline)

Do not read vendor/scopo/lib/**, other scopo clones (including scopo-src), the
kit, pub-cache sources, @SOURCES@, SDK sources, or any other path
outside your application except the public materials listed above. Toolchain
execution and automatic compiler/package resolution are permitted; reading
compiler and analyzer diagnostics is permitted. Do not use tools to retrieve
source definitions. You may enumerate public API reference files.

## FRICTION.md

Create FRICTION.md at your application root. Record every documentation or API
stumble when it happens, including ones you resolve. Do not invent problems. If
none occurred, write No friction encountered. Use this fixed record format,
repeated for each actual stumble (all fields required):

- ID: F01
- Wanted: what you were trying to achieve or find
- Read: exact public document path and heading (or API page/member)
- Gap or misunderstanding: what was missing or what you misunderstood
- Tried: concrete code/API attempt, search, or diagnostic
- Outcome: resolved/unresolved, and how
- Suggested sentence: the exact sentence that would have prevented this

Keep the journal factual, distinguishing an absent explanation from one you
found later. Deliver the working app, your tests and FRICTION.md. Do not read
or request hidden tests or reference solutions.
