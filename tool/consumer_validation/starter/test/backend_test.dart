import 'package:flutter_test/flutter_test.dart';
import 'package:resource_exercise/backend.dart';

void main() {
  test('held acquisition and release expose exact ownership events', () async {
    final backend = Backend(holdOpens: true, holdCloses: true);
    final opening = backend.open('x');
    expect(backend.events, ['open:x']);
    expect(backend.liveResources, 0);
    backend.releaseOpen('x');
    final resource = await opening;
    resource.use('test');
    final closing = resource.close();
    expect(backend.liveResources, 1);
    expect(backend.events.last, 'close:x');
    backend.releaseClose('x');
    await closing;
    expect(backend.liveResources, 0);
    expect(backend.events,
        ['open:x', 'opened:x', 'use:x:test', 'close:x', 'closed:x']);
  });

  test('failed attempt allocates nothing and the next attempt waits anew',
      () async {
    final backend = Backend(holdOpens: true)..failNextOpen('x');
    final failure = expectLater(backend.open('x'), throwsStateError);
    backend.releaseOpen('x');
    await failure;
    expect(backend.liveResources, 0);
    final retry = backend.open('x');
    expect(backend.events, ['open:x', 'failed:x', 'open:x']);
    backend.releaseOpen('x');
    final resource = await retry;
    await resource.close();
    expect(backend.liveResources, 0);
  });

  test('use during or after close and duplicate release are detected',
      () async {
    final backend = Backend(holdCloses: true);
    final resource = await backend.open('x');
    final closing = resource.close();
    expect(() => resource.use('during'), throwsStateError);
    backend.releaseClose('x');
    await closing;
    expect(() => resource.use('after'), throwsStateError);
    await expectLater(resource.close(), throwsStateError);
    expect(backend.useAfterClose, 2);
  });
}
