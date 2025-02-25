// semester_settings_dialog.dart 新文件：
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SemesterSettingsDialog extends StatefulWidget {
  final DateTime? currentFirstWeek;
  
  const SemesterSettingsDialog({
    Key? key,
    this.currentFirstWeek,
  }) : super(key: key);

  @override
  _SemesterSettingsDialogState createState() => _SemesterSettingsDialogState();
}

class _SemesterSettingsDialogState extends State<SemesterSettingsDialog> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.currentFirstWeek ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('设置学期第一周'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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