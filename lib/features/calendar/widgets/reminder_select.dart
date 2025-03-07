// lib/widgets/reminder_select.dart
import 'package:flutter/material.dart';

class ReminderMultiSelect extends StatefulWidget {
  final List<int> initialValue;
  final Function(List<int>) onChanged;

  const ReminderMultiSelect({
    Key? key,
    required this.initialValue,
    required this.onChanged,
  }) : super(key: key);

  @override 
  _ReminderMultiSelectState createState() => _ReminderMultiSelectState();
}

class _ReminderMultiSelectState extends State<ReminderMultiSelect> {
  late List<int> _selectedValues;
  
  final Map<int, String> _reminderOptions = {
    5: '提前5分钟提醒',
    10: '提前10分钟提醒',
    20: '提前20分钟提醒',
    30: '提前30分钟提醒',
    60: '提前1小时前提醒',
    120: '提醒2小时提醒',
    1440: '在1天前提醒',
  };

  @override
  void initState() {
    super.initState();
    _selectedValues = List.from(widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
          child: Text(
            '提醒时间 (可多选)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: _reminderOptions.entries.map((entry) {
              final isSelected = _selectedValues.contains(entry.key);
              return CheckboxListTile(
                title: Text(entry.value),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      if (!_selectedValues.contains(entry.key)) {
                        _selectedValues.add(entry.key);
                        _selectedValues.sort(); // Keep list ordered
                      }
                    } else {
                      _selectedValues.remove(entry.key);
                    }
                    widget.onChanged(_selectedValues);
                  });
                },
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ),
        ),
        if (_selectedValues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Wrap(
              spacing: 8.0,
              children: _selectedValues.map((value) => Chip(
                label: Text(_reminderOptions[value] ?? ''),
                onDeleted: () {
                  setState(() {
                    _selectedValues.remove(value);
                    widget.onChanged(_selectedValues);
                  });
                },
              )).toList(),
            ),
          ),
      ],
    );
  }
}