import 'package:flutter/material.dart';

/// Global messenger so non-widget code (push handler) can show SnackBars.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
