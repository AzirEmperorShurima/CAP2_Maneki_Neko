import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

/// Clean Navigation Observer
@LazySingleton()
class AppNavigatorObserver extends NavigatorObserver {
  AppNavigatorObserver._();

  factory AppNavigatorObserver() => instance;

  static final AppNavigatorObserver instance = AppNavigatorObserver._();

  /// REAL ROUTE STACK
  final List<String> _stack = [];

  List<String> get routeStack => List.unmodifiable(_stack);

  void _log(String msg) {
    final shortStack =
        _stack.length <= 3 ? _stack : _stack.sublist(_stack.length - 3);

    /// 👉 Không dùng logD nữa — nó gây ra stacktrace & pretty logging
    print("💖 [Navigator] $msg | stack: $shortStack");
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);

    final name = route.settings.name;
    if (name == null || name.isEmpty || route is PopupRoute) return;

    _stack.add(name);
    _log("PUSH → $name");
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);

    final name = route.settings.name;
    if (name == null || name.isEmpty) return;

    if (_stack.isNotEmpty) _stack.removeLast();

    _log("POP → $name");
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);

    final name = route.settings.name;
    if (name == null || name.isEmpty) return;

    _stack.remove(name);
    _log("REMOVE → $name");
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    final oldName = oldRoute?.settings.name;
    final newName = newRoute?.settings.name;

    if (oldName != null) _stack.remove(oldName);
    if (newName != null) _stack.add(newName);

    _log("REPLACE → $oldName → $newName");
  }
}