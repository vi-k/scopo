// Shared fakes for the four probes: a database and a session that depends
// on it. Both take time to open and to close, both record what happened.
import 'dart:async';

final events = <String>[];

class Db {
  bool closed = false;

  static Future<Db> open() async {
    events.add('db opening');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    events.add('db opened');
    return Db();
  }

  Future<void> close() async {
    events.add('db closing');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    closed = true;
    events.add('db closed');
  }
}

class Session {
  final Db db;

  Session(this.db);

  static Future<Session> open(Db db) async {
    events.add('session opening');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    events.add('session opened');
    return Session(db);
  }

  Future<void> close() async {
    events.add('session closing');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    events.add('session closed');
  }
}
