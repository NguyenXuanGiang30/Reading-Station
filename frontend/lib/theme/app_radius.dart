library;

import 'package:flutter/material.dart';

class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;

  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get button => BorderRadius.circular(md);
  static BorderRadius get input => BorderRadius.circular(sm);
  static BorderRadius get bottomSheet => BorderRadius.circular(xl);
}
