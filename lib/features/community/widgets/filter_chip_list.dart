// lib/features/community/widgets/filter_chip_list.dart
import 'package:flutter/material.dart';

class FilterChipList<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final String Function(T) getLabel;
  final IconData Function(T)? getIcon;
  final Color Function(T)? getColor;
  final Function(T) onSelected;
  final bool showAllOption;
  final String allOptionLabel;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  const FilterChipList({
    Key? key,
    required this.items,
    required this.selectedItem,
    required this.getLabel,
    this.getIcon,
    this.getColor,
    required this.onSelected,
    this.showAllOption = true,
    this.allOptionLabel = '全部',
    this.scrollable = true,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chipsList = <Widget>[
      if (showAllOption)
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(allOptionLabel),
            selected: selectedItem == null,
            onSelected: (selected) {
              if (selected) {
                onSelected(items.first);  // Will be nullified by caller
              }
            },
            selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
            checkmarkColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(
              color: selectedItem == null 
                  ? Theme.of(context).primaryColor
                  : Colors.grey[800],
              fontWeight: selectedItem == null 
                  ? FontWeight.bold 
                  : FontWeight.normal,
            ),
            backgroundColor: Colors.grey[200],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          ),
        ),
      ...items.map((item) {
        final isSelected = selectedItem == item;
        final color = getColor != null 
            ? getColor!(item) 
            : Theme.of(context).primaryColor;
            
        return Padding(
          padding: EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (getIcon != null) ...[
                  Icon(
                    getIcon!(item),
                    size: 16,
                    color: isSelected ? color : Colors.grey[600],
                  ),
                  SizedBox(width: 4),
                ],
                Text(getLabel(item)),
              ],
            ),
            selected: isSelected,
            onSelected: (selected) {
              onSelected(item);
            },
            selectedColor: color.withOpacity(0.1),
            checkmarkColor: color,
            labelStyle: TextStyle(
              color: isSelected ? color : Colors.grey[800],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: Colors.grey[200],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          ),
        );
      }).toList(),
    ];

    if (scrollable) {
      return Padding(
        padding: padding,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: chipsList),
        ),
      );
    } else {
      return Padding(
        padding: padding,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chipsList,
        ),
      );
    }
  }
}

/// A more advanced filter widget that allows multiple selections
class MultiFilterChipList<T> extends StatelessWidget {
  final List<T> items;
  final List<T> selectedItems;
  final String Function(T) getLabel;
  final IconData Function(T)? getIcon;
  final Color Function(T)? getColor;
  final Function(List<T>) onSelectionChanged;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  const MultiFilterChipList({
    Key? key,
    required this.items,
    required this.selectedItems,
    required this.getLabel,
    this.getIcon,
    this.getColor,
    required this.onSelectionChanged,
    this.scrollable = true,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chipsList = items.map((item) {
      final isSelected = selectedItems.contains(item);
      final color = getColor != null 
          ? getColor!(item) 
          : Theme.of(context).primaryColor;
          
      return Padding(
        padding: EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (getIcon != null) ...[
                Icon(
                  getIcon!(item),
                  size: 16,
                  color: isSelected ? color : Colors.grey[600],
                ),
                SizedBox(width: 4),
              ],
              Text(getLabel(item)),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            final newSelection = List<T>.from(selectedItems);
            
            if (selected) {
              if (!newSelection.contains(item)) {
                newSelection.add(item);
              }
            } else {
              newSelection.remove(item);
            }
            
            onSelectionChanged(newSelection);
          },
          selectedColor: color.withOpacity(0.1),
          checkmarkColor: color,
          labelStyle: TextStyle(
            color: isSelected ? color : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        ),
      );
    }).toList();

    if (scrollable) {
      return Padding(
        padding: padding,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: chipsList),
        ),
      );
    } else {
      return Padding(
        padding: padding,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chipsList,
        ),
      );
    }
  }
}

/// A convenient widget for showing price range filters
class PriceRangeFilter extends StatelessWidget {
  final List<PriceRange> ranges;
  final PriceRange? selectedRange;
  final Function(PriceRange?) onRangeSelected;

  const PriceRangeFilter({
    Key? key,
    required this.ranges,
    required this.selectedRange,
    required this.onRangeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilterChipList<PriceRange>(
      items: ranges,
      selectedItem: selectedRange,
      getLabel: (range) => range.label,
      onSelected: (range) {
        if (selectedRange == range) {
          onRangeSelected(null);
        } else {
          onRangeSelected(range);
        }
      },
    );
  }
}

class PriceRange {
  final String label;
  final double? min;
  final double? max;

  const PriceRange({
    required this.label,
    this.min,
    this.max,
  });

  bool inRange(double price) {
    if (min != null && price < min!) {
      return false;
    }
    if (max != null && price > max!) {
      return false;
    }
    return true;
  }

  static List<PriceRange> getDefaultRanges() {
    return [
      PriceRange(label: '¥0-50', min: 0, max: 50),
      PriceRange(label: '¥50-100', min: 50, max: 100),
      PriceRange(label: '¥100-200', min: 100, max: 200),
      PriceRange(label: '¥200-500', min: 200, max: 500),
      PriceRange(label: '¥500+', min: 500, max: null),
    ];
  }
}

/// Sortable options filter
class SortOptionFilter extends StatelessWidget {
  final List<SortOption> options;
  final SortOption? selectedOption;
  final Function(SortOption) onOptionSelected;

  const SortOptionFilter({
    Key? key,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilterChipList<SortOption>(
      items: options,
      selectedItem: selectedOption,
      getLabel: (option) => option.label,
      getIcon: (option) => option.icon,
      onSelected: (option) {
        onOptionSelected(option);
      },
      showAllOption: false,
    );
  }
}

class SortOption {
  final String label;
  final IconData icon;
  final SortDirection direction;
  final String field;

  const SortOption({
    required this.label,
    required this.icon,
    required this.direction,
    required this.field,
  });

  static List<SortOption> getDefaultOptions() {
    return [
      SortOption(
        label: '最新', 
        icon: Icons.access_time, 
        direction: SortDirection.descending,
        field: 'createdAt',
      ),
      SortOption(
        label: '价格低到高', 
        icon: Icons.arrow_upward, 
        direction: SortDirection.ascending,
        field: 'price',
      ),
      SortOption(
        label: '价格高到低', 
        icon: Icons.arrow_downward, 
        direction: SortDirection.descending,
        field: 'price',
      ),
    ];
  }
}

enum SortDirection {
  ascending,
  descending,
}