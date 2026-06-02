import 'package:flutter/material.dart';

/// Global navigator for FCM deep links when no [BuildContext] is available.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
