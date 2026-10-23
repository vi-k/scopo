/// `listen` and `select` on a `Listenable`, kept out of
/// `package:scopo/scopo.dart`.
///
/// They are extensions on the framework's own `Listenable`, where another
/// package is free to put a `listen` and a `select` of its own. Exported from
/// the main import, they came with every scope: a file that also imported such
/// a package found `listen` ambiguous, and its `select` silently replaced by
/// this one, which is the more specific of the two. The import is the choice.
///
/// `ListenableSelector`, the widget built on `select`, stays in the main
/// import: a widget's name collides with nothing in an extension.
library;

export 'src/utils/listenable/listen.dart';
