import 'dart:async';

/// Shared journal of what the resources went through.
final log = <String>[];

/// Knobs the tests turn.
var openDelay = const Duration(milliseconds: 100);
var restoreDelay = const Duration(milliseconds: 100);
var closeDelay = const Duration(milliseconds: 50);
var sessionFails = false;

void resetDomain() {
  log.clear();
  sessionFails = false;
}

class Database {
  Database._();

  bool closed = false;

  static Future<Database> open() async {
    log.add('db: open started');
    await Future<void>.delayed(openDelay);
    log.add('db: opened');
    return Database._();
  }

  Future<void> close() async {
    log.add('db: close started');
    await Future<void>.delayed(closeDelay);
    closed = true;
    log.add('db: closed');
  }
}

class Session {
  Session._(this.db);

  final Database db;

  String get user => 'alice';

  static Future<Session> restore(Database db) async {
    log.add('session: restore started');
    await Future<void>.delayed(restoreDelay);
    if (sessionFails) {
      log.add('session: restore failed');
      throw StateError('session expired');
    }
    if (db.closed) log.add('session: restored ON A CLOSED DB');
    log.add('session: restored');
    return Session._(db);
  }

  Future<void> close() async {
    log.add('session: close started');
    await Future<void>.delayed(closeDelay);
    if (db.closed) log.add('session: closed AFTER its db');
    log.add('session: closed');
  }
}
