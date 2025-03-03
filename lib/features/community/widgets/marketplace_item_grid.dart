// lib/features/community/widgets/marketplace_item_grid.dart
import 'package:flutter/material.dart';
import '../models/marketplace_item.dart';
// import 'marketplace_item_card.dart';

class MarketplaceItemGrid extends StatelessWidget {
  final List<MarketplaceItem> items;
  final Function(MarketplaceItem) onItemTap;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const MarketplaceItemGrid({
    Key? key,
    required this.items,
    required this.onItemTap,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.75,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return items.isEmpty
        ? _buildEmptyState()
        : GridView.builder(
            padding: padding,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return MarketplaceItemCard(
                item: items[index],
                onTap: () => onItemTap(items[index]),
              );
            },
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 72,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            '暂无物品',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            '尝试更改筛选条件或稍后再来查看',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class MarketplaceItemCard extends StatelessWidget {
  final MarketplaceItem item;
  final VoidCallback onTap;
  final bool showFavoriteButton;

  const MarketplaceItemCard({
    Key? key,
    required this.item,
    required this.onTap,
    this.showFavoriteButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with aspect ratio
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Item image or placeholder
                  _buildItemImage(),
                  
                  // Optional favorite button overlay
                  if (showFavoriteButton)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildFavoriteButton(context),
                    ),
                    
                  // Category badge overlay
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildCategoryBadge(context),
                  ),
                ],
              ),
            ),
            
            // Item details
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with 2 lines max
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  
                  // Price
                  Text(
                    '¥${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,  // Larger price display
                    ),
                  ),
                  
                  // Item condition
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.condition.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        _formatDate(item.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
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
    );
  }

  Widget _buildItemImage() {
    if (item.imageUrls.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            size: 48,
            color: Colors.grey[500],
          ),
        ),
      );
    }
    
    return Image.network(
      item.imageUrls.first,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: Colors.grey[500],
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black26,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.favorite_border,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildCategoryBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(item.category),
            color: Colors.white,
            size: 12,
          ),
          SizedBox(width: 4),
          Text(
            item.category.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.books:
        return Icons.book;
      case ItemCategory.electronics:
        return Icons.devices;
      case ItemCategory.clothing:
        return Icons.shopping_bag;
      case ItemCategory.furniture:
        return Icons.chair;
      case ItemCategory.sports:
        return Icons.sports_basketball;
      case ItemCategory.other:
        return Icons.category;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}