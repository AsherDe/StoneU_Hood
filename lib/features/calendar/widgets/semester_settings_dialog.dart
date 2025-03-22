// semester_settings_dialog.dart 新文件：
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SemesterSettingsDialog extends StatefulWidget {
  final DateTime? currentFirstWeek;
  final bool isFirstTime;
  
  const SemesterSettingsDialog({
    super.key,
    this.currentFirstWeek,
    this.isFirstTime = false,
  });

  @override
  _SemesterSettingsDialogState createState() => _SemesterSettingsDialogState();
}

class _SemesterSettingsDialogState extends State<SemesterSettingsDialog> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    if(widget.isFirstTime) {
      final now = DateTime.now();
      selectedDate = now.subtract(Duration(days: now.weekday - 1));
    } else {
      selectedDate = widget.currentFirstWeek ?? DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('设置学期第一周'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 如果是首次启动，显示欢迎信息
          if (widget.isFirstTime)
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                '欢迎使用石大日历！请设置本学期的第一周开始日期。',
                style: TextStyle(
                  color: Colors.blue, // 使用主题颜色
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text('请选择本学期的第一周的周一日期：'),
          ListTile(
            title: Text('选择日期'),
            subtitle: Text(DateFormat('yyyy年MM月dd日').format(selectedDate)),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                selectableDayPredicate: (DateTime date) {
                  // 只允许选择周一
                  return date.weekday == DateTime.monday;
                },
              );
              if (date != null) {
                setState(() {
                  selectedDate = date;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        if (!widget.isFirstTime)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, selectedDate),
          child: Text('确定'),
        ),
      ],
    );
  }
}