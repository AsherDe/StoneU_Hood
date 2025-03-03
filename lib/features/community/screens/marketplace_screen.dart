// lib/features/community/screens/marketplace_screen.dart
import 'package:flutter/material.dart';
import '../models/marketplace_item.dart';
import '../widgets/marketplace_item_grid.dart';
import '../widgets/filter_chip_list.dart';
import '../services/community_service.dart';

class MarketplaceScreen extends StatefulWidget {
  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final CommunityService _communityService = CommunityService();
  List<MarketplaceItem> _items = [];
  List<MarketplaceItem> _filteredItems = [];
  bool _isLoading = true;
  ItemCategory? _selectedCategory;
  String _searchQuery = '';
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _communityService.getMarketplaceItems();
      setState(() {
        _items = items;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载商品失败: $e')),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _items.where((item) {
        // Apply category filter
        if (_selectedCategory != null && item.category != _selectedCategory) {
          return false;
        }
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.description.toLowerCase().contains(_searchQuery.toLowerCase());
        }
        
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '二手交易',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.tune),
            onPressed: _showSortFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索二手物品...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          
          // Category filter chips
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: FilterChipList<ItemCategory>(
              items: ItemCategory.values,
              selectedItem: _selectedCategory,
              getLabel: (category) => category.name,
              onSelected: (category) {
                setState(() {
                  if (_selectedCategory == category) {
                    _selectedCategory = null;
                  } else {
                    _selectedCategory = category;
                  }
                  _applyFilters();
                });
              },
            ),
          ),
          
          // Results count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '找到 ${_filteredItems.length} 个物品',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // Items grid
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          '没有找到符合条件的物品',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadItems,
                        child: MarketplaceItemGrid(
                          items: _filteredItems,
                          onItemTap: (item) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MarketplaceItemDetailScreen(item: item),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create item screen
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _showSortFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '排序和筛选',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.sort),
              title: Text('最新发布'),
              onTap: () {
                Navigator.pop(context);
                // Sort by newest
                setState(() {
                  _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  _applyFilters();
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.arrow_downward),
              title: Text('价格从高到低'),
              onTap: () {
                Navigator.pop(context);
                // Sort by price descending
                setState(() {
                  _items.sort((a, b) => b.price.compareTo(a.price));
                  _applyFilters();
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.arrow_upward),
              title: Text('价格从低到高'),
              onTap: () {
                Navigator.pop(context);
                // Sort by price ascending
                setState(() {
                  _items.sort((a, b) => a.price.compareTo(b.price));
                  _applyFilters();
                });
              },
            ),
            SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class MarketplaceItemDetailScreen extends StatelessWidget {
  final MarketplaceItem item;

  const MarketplaceItemDetailScreen({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '物品详情',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.favorite_border),
            onPressed: () {
              // TODO: Implement favorite functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel
            Container(
              height: 250,
              child: PageView.builder(
                itemCount: item.imageUrls.isEmpty ? 1 : item.imageUrls.length,
                itemBuilder: (context, index) {
                  if (item.imageUrls.isEmpty) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    );
                  }
                  return Image.network(
                    item.imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            // Title and price
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '¥${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 28,  // Larger price display as requested
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Item badges
                  Row(
                    children: [
                      _buildBadge(item.category.name, Colors.blue.shade100),
                      SizedBox(width: 8),
                      _buildBadge(item.condition.name, Colors.green.shade100),
                      SizedBox(width: 8),
                      _buildBadge('发布于 ${_formatDate(item.createdAt)}', Colors.grey.shade200),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Description
                  Text(
                    '描述',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Trade link if available
                  if (item.tradeLink != null && item.tradeLink!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '交易链接',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            // TODO: Open trade link
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.link, color: Colors.blue),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.tradeLink!,
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  
                  // Seller info
                  Text(
                    '卖家信息',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          child: Text(
                            item.sellerName.substring(0, 1).toUpperCase(),
                          ),
                        ),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.sellerName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '联系方式: ${item.sellerContact}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implement message seller
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('联系卖家'),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement purchase
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('购买'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes} 分钟前';
      }
      return '${difference.inHours} 小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${date.year}-${date.month}-${date.day}';
    }
  }
}