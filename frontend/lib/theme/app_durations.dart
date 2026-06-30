library;

import 'package:flutter/material.dart';

class AppDurations {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration page = Duration(milliseconds: 400);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve playful = Curves.easeOutBack;
}
