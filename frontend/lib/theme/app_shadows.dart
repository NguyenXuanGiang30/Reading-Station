library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  static final List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.shadowSoft,
      blurRadius: 18,
      offset: const Offset(0, 10),
    ),
  ];

  static final List<BoxShadow> elevated = [
    BoxShadow(
      color: AppColors.shadowElevated,
      blurRadius: 28,
      offset: const Offset(0, 16),
    ),
  ];
}
