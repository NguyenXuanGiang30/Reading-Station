/// FindFriendScreen - Tìm kiếm bạn bè
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../services/friend_service.dart';

class FindFriendScreen extends StatefulWidget {
  const FindFriendScreen({super.key});

  @override
  State<FindFriendScreen> createState() => _FindFriendScreenState();
}

class _FindFriendScreenState extends State<FindFriendScreen> {
  final _searchController = TextEditingController();
  final _friendService = FriendService();
  Timer? _debounce;
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _friendService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi tìm kiếm: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    try {
      await _friendService.sendFriendRequest(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lời mời kết bạn'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tìm bạn bè',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Nhập tên hoặc email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _buildContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy người dùng nào',
          style: GoogleFonts.inter(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user['avatarUrl'] != null ? NetworkImage(user['avatarUrl']) : null,
            child: user['avatarUrl'] == null 
              ? Text((user['displayName'] ?? user['name'] ?? 'U').toString()[0].toUpperCase()) 
              : null,
          ),
          title: Text(
            user['displayName'] ?? user['name'] ?? 'Người dùng',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(user['email'] ?? ''),
          trailing: IconButton(
            icon: const Icon(Icons.person_add, color: AppColors.primaryStart),
            onPressed: () => _sendFriendRequest(user['id'].toString()),
          ),
          onTap: () {
            // Optional: View profile
            // context.push('/friend/${user['id']}');
          },
        );
      },
    );
  }
}
