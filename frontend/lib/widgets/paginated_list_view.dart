/// Paginated List Widget - Reusable pagination component
library;

import 'package:flutter/material.dart';

/// Callback type for loading more data
typedef LoadMoreCallback<T> = Future<List<T>> Function(int page);

/// Callback type for refresh
typedef RefreshCallback<T> = Future<List<T>> Function();

/// A widget that handles paginated list with pull-to-refresh and infinite scroll
class PaginatedListView<T> extends StatefulWidget {
  /// Initial data to display
  final List<T> initialData;
  
  /// Callback to load more data
  final LoadMoreCallback<T>? loadMore;
  
  /// Callback to refresh data
  final RefreshCallback<T>? onRefresh;
  
  /// Item builder for each list item
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  
  /// Separator builder
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  
  /// Loading indicator at bottom
  final Widget? loadingIndicator;
  
  /// Error widget when load more fails
  final Widget? errorWidget;
  
  /// Empty widget when no data
  final Widget? emptyWidget;
  
  /// Check if has more data
  final bool hasMore;
  
  /// Initial page (default 0)
  final int initialPage;
  
  /// Page size (default 20)
  final int pageSize;
  
  /// Scroll controller (optional)
  final ScrollController? controller;
  
  /// Pull to refresh enabled
  final bool enablePullToRefresh;
  
  /// Physics for list
  final ScrollPhysics? physics;
  
  /// Padding
  final EdgeInsets? padding;
  
  /// Key for refresh indicator
  final Key? refreshKey;
  
  const PaginatedListView({
    super.key,
    required this.initialData,
    this.loadMore,
    this.onRefresh,
    required this.itemBuilder,
    this.separatorBuilder,
    this.loadingIndicator,
    this.errorWidget,
    this.emptyWidget,
    this.hasMore = true,
    this.initialPage = 0,
    this.pageSize = 20,
    this.controller,
    this.enablePullToRefresh = true,
    this.physics,
    this.padding,
    this.refreshKey,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  late List<T> _items;
  late int _currentPage;
  late bool _hasMore;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;
  
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _items = List<T>.from(widget.initialData);
    _currentPage = widget.initialPage;
    _hasMore = widget.hasMore;
    _scrollController = widget.controller ?? ScrollController();
    
    if (widget.loadMore != null) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void didUpdateWidget(PaginatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialData != oldWidget.initialData) {
      _items = List<T>.from(widget.initialData);
      _currentPage = widget.initialPage;
      _hasMore = widget.hasMore;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !_hasMore) return;
    
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
      _hasError = false;
    });
    
    try {
      final newPage = _currentPage + 1;
      final newItems = await widget.loadMore!(newPage);
      
      if (newItems.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _items.addAll(newItems);
          _currentPage = newPage;
          _hasMore = newItems.length >= widget.pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    if (widget.onRefresh == null) return;
    
    setState(() {
      _hasError = false;
      _isLoadingMore = false;
    });
    
    try {
      final newItems = await widget.onRefresh!();
      setState(() {
        _items = List<T>.from(newItems);
        _currentPage = widget.initialPage;
        _hasMore = newItems.length >= widget.pageSize;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return widget.emptyWidget ?? _buildDefaultEmpty();
    }

    Widget listView;
    
    if (widget.enablePullToRefresh && widget.onRefresh != null) {
      listView = RefreshIndicator(
        key: widget.refreshKey,
        onRefresh: _onRefresh,
        child: _buildListView(),
      );
    } else {
      listView = _buildListView();
    }

    return listView;
  }

  Widget _buildListView() {
    return ListView.separated(
      controller: _scrollController,
      physics: widget.physics,
      padding: widget.padding,
      itemCount: _items.length + (_hasMore || _isLoadingMore ? 1 : 0),
      separatorBuilder: widget.separatorBuilder ?? (context, index) => const SizedBox.shrink(),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return _buildLoadMoreIndicator();
        }
        return widget.itemBuilder(context, _items[index], index);
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultError();
    }
    
    if (_isLoadingMore) {
      return widget.loadingIndicator ?? _buildDefaultLoading();
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildDefaultEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không có dữ liệu',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLoading() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadMore,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simpler pagination state widget for easier integration
class PaginationState<T> extends ChangeNotifier {
  List<T> _items = [];
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _error;
  
  List<T> get items => _items;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _items.isEmpty && !_isLoading;
  
  void setInitialData(List<T> data, {bool hasMore = true}) {
    _items = List<T>.from(data);
    _currentPage = 0;
    _hasMore = hasMore;
    notifyListeners();
  }
  
  Future<void> loadMore(Future<List<T>> Function(int page) loader) async {
    if (_isLoading || !_hasMore) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newPage = _currentPage + 1;
      final newItems = await loader(newPage);
      
      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(newItems);
        _currentPage = newPage;
        _hasMore = newItems.length >= 20; // Assuming page size 20
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> refresh(Future<List<T>> Function() loader) async {
    _currentPage = 0;
    _hasMore = true;
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newItems = await loader();
      _items = List<T>.from(newItems);
      _hasMore = newItems.length >= 20;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void reset() {
    _items = [];
    _currentPage = 0;
    _hasMore = true;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
