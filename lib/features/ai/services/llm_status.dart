import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class ApiStatsScreen extends StatefulWidget {
  final String serverUrl;

  const ApiStatsScreen({Key? key, required this.serverUrl}) : super(key: key);

  @override
  _ApiStatsScreenState createState() => _ApiStatsScreenState();
}

class _ApiStatsScreenState extends State<ApiStatsScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  Timer? _refreshTimer;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
    // 每30秒自动刷新一次数据
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _loadStats();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.serverUrl}/api/stats'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _stats = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '获取数据失败: HTTP ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '获取数据出错: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API 用量统计'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: '刷新数据',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(_errorMessage),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStats,
                        child: Text('重试'),
                      ),
                    ],
                  ),
                )
              : _buildStatsView(),
    );
  }

  Widget _buildStatsView() {
    final currentModel = _stats['current_model'] ?? '未知';
    final totalTokens = _stats['current_window_tokens'] ?? 0;
    final isAlert = _stats['is_threshold_alert'] ?? false;
    final startTime = _stats['window_start_time'] ?? '';
    final elapsedMinutes = _stats['elapsed_minutes'] ?? '0';
    final modelHistory = _stats['model_history'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(currentModel, totalTokens, isAlert),
            SizedBox(height: 24),
            Text(
              '窗口统计',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('窗口开始时间:', startTime),
                    _buildInfoRow('已经过时间:', '$elapsedMinutes 分钟'),
                    _buildInfoRow('当前Token消耗:', '$totalTokens tokens'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              '历史使用量',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: modelHistory.entries.map((entry) {
                    return _buildInfoRow('${entry.key}:', '${entry.value} tokens');
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String model, int tokens, bool isAlert) {
    return Card(
      color: isAlert ? Colors.orange[50] : Colors.green[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAlert ? Icons.warning_amber_rounded : Icons.check_circle,
                  color: isAlert ? Colors.orange : Colors.green,
                ),
                SizedBox(width: 8),
                Text(
                  '当前状态',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildInfoRow('当前模型:', model),
            _buildInfoRow('Token使用量:', '$tokens tokens'),
            _buildInfoRow('状态:', isAlert ? '已触发阈值警报，使用备用模型' : '正常，使用默认模型'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}