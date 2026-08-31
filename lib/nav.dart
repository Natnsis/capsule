import 'package:flutter/material.dart';

/// Push a screen with a normal platform slide transition.
Future<T?> go<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => screen));

/// Replace the current screen (used when a flow step shouldn't be revisited).
Future<T?> goReplace<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));

/// Replace the whole stack (e.g. finishing onboarding into the main app).
Future<T?> goRoot<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );

/// Push [screen] and drop every route between it and the app root, so
/// dismissing it lands on the root instead of walking back through a
/// finished flow (e.g. after sealing a capsule).
Future<T?> goResetTo<T>(BuildContext context, Widget screen) =>
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => route.isFirst,
    );

void back(BuildContext context) => Navigator.of(context).maybePop();
