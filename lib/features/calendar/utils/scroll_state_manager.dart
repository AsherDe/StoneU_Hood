// lib/utils/scroll_state_manager.dart
import 'package:flutter/material.dart';

/// A utility class to manage vertical scroll positions across multiple pages
class ScrollStateManager {
  final Map<int, double> _scrollPositions = {};
  final ScrollController scrollController;
  int _currentPage = 0;

  ScrollStateManager(this.scrollController);

  void savePage(int page) {
    // Save the current scroll position before changing pages
    _scrollPositions[_currentPage] = scrollController.offset;
    _currentPage = page;
  }

  void restoreScrollPosition(int page) {
    // Jump to the previously saved scroll position or use default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollPositions.containsKey(page)) {
        scrollController.jumpTo(_scrollPositions[page] ?? 0.0); //8h
      }
    });
  }

  void setDefaultScrollForPage(int page, double position) {
    if (!_scrollPositions.containsKey(page)) {
      _scrollPositions[page] = position;
    }
  }

  void clear() {
    _scrollPositions.clear();
  }
}