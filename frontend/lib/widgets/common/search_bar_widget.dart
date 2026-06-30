library;

import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? trailing;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.hintText = 'Tìm kiếm',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: controller,
      hintText: hintText,
      leading: const Icon(Icons.search_rounded),
      trailing: trailing == null ? null : <Widget>[trailing!],
      readOnly: readOnly,
      onChanged: onChanged,
      onTap: onTap,
    );
  }
}
