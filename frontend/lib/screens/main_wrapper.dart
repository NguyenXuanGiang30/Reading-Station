/// MainWrapper - Bottom Navigation shell
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../widgets/navigation/custom_bottom_nav_bar.dart';

class MainWrapper extends StatefulWidget {
  final Widget child;

  const MainWrapper({super.key, required this.child});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  static const List<String> _paths = ['/', '/library', '/review', '/social', '/profile'];
  static const List<IconData> _icons = [
    Icons.home_outlined,
    Icons.local_library_outlined,
    Icons.auto_awesome_outlined,
    Icons.groups_2_outlined,
    Icons.person_outline_rounded,
  ];
  static const List<IconData> _selectedIcons = [
    Icons.home_rounded,
    Icons.local_library_rounded,
    Icons.auto_awesome_rounded,
    Icons.groups_2_rounded,
    Icons.person_rounded,
  ];
  static const List<String> _labelKeys = [
    'nav_home',
    'nav_library',
    'nav_review',
    'nav_social',
    'nav_profile',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateIndex();
  }

  void _updateIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _paths.indexOf(location);
    if (index != -1 && index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_paths[index]);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: _onTap,
        destinations: List.generate(
          _paths.length,
          (i) => NavigationDestination(
            icon: Icon(_icons[i]),
            selectedIcon: Icon(_selectedIcons[i]),
            label: s.t(_labelKeys[i]),
          ),
        ),
      ),
    );
  }
}
