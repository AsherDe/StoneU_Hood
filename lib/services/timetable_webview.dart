// lib/services/timetable_webview.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/event.dart';
import 'timetable_parser.dart';

class TimetableWebView extends StatefulWidget {
  final Function(List<CalendarEvent>) onEventsImported;

  const TimetableWebView({
    Key? key,
    required this.onEventsImported,
  }) : super(key: key);

  @override
  State<TimetableWebView> createState() => _TimetableWebViewState();
}

class _TimetableWebViewState extends State<TimetableWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _statusMessage = '请登录教务系统并进入课程表页面';
  bool _isTimetablePage = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize and configure WebView controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent('Mozilla/5.0 (Linux; Android 12; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _isTimetablePage = url.contains('xsMain');
              
              if (_isTimetablePage) {
                _statusMessage = '已加载课程表页面，点击右上角下载按钮解析';
              } else {
                _checkForTimetableIframes();
                _statusMessage = '请登录并进入"学期理论课表"页面';
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _statusMessage = '页面加载错误: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      ..enableZoom(true);
    
    // Clear cookies for a fresh session
    WebViewCookieManager().clearCookies();
    
    // Load the website
    _controller.loadRequest(Uri.parse('https://jwgl.shzu.edu.cn/'));
  }

  // 检查页面上是否有包含课表的iframe
  Future<void> _checkForTimetableIframes() async {
    try {
      final iframesCount = await _controller.runJavaScriptReturningResult(
        'document.querySelectorAll("iframe").length'
      );
      
      if (iframesCount.toString() != '0') {
        int count = int.parse(iframesCount.toString());
        for (int i = 0; i < count; i++) {
          final iframeSrc = await _controller.runJavaScriptReturningResult(
            'document.querySelectorAll("iframe")[' + i.toString() + '].src'
          );
          
          if (iframeSrc.toString().contains('xskb_list') || 
              iframeSrc.toString().contains('kbcx')) {
            setState(() {
              _isTimetablePage = true;
              _statusMessage = '检测到课表iframe，点击下载按钮获取数据';
            });
            break;
          }
        }
      }
    } catch (e) {
      print('检查iframe时出错: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入课程表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: '使用帮助',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
            tooltip: '刷新页面',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _isTimetablePage ? _captureAndParse : _promptNavigateToTimetable,
            tooltip: '解析课程表',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) 
            const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_statusMessage),
          ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用帮助'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. 使用学号密码登录教务系统'),
            Text('2. 进入"个人课表"或"学期理论课表"页面'),
            Text('3. 确保课表显示正确后，点击右上角下载按钮'),
            SizedBox(height: 16),
            Text('常见问题:'),
            Text('• 如果页面加载失败，请点击刷新按钮'),
            Text('• 如果解析失败，请确保完全显示课表内容'),
            Text('• 下载按钮只有在课表页面才会启用'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _promptNavigateToTimetable() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未加载课程表'),
        content: const Text('请先导航到"个人课表"或"学期理论课表"页面，再点击下载按钮。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

    Future<void> _captureAndParse() async {
    setState(() {
      _statusMessage = '正在解析课程表...';
      _isLoading = true;
    });

    try {
      // Wait to ensure page is fully loaded
      await Future.delayed(const Duration(milliseconds: 800));
      
      // First check if there are iframes on the page
      final iframesCount = await _controller.runJavaScriptReturningResult(
        'document.querySelectorAll("iframe").length'
      );
      
      print('找到 $iframesCount 个iframe');
      
      String html = '';
      bool foundTarget = false;
      
      // If we have iframes, try to get content from each one
      if (iframesCount.toString() != '0') {
        // List all iframes for debugging
        await _controller.runJavaScript('''
          console.log("页面上的所有iframe:");
          document.querySelectorAll("iframe").forEach((iframe, i) => {
            console.log("Iframe " + i + " id: " + iframe.id);
            console.log("Iframe " + i + " name: " + iframe.name);
            console.log("Iframe " + i + " src: " + iframe.src);
          });
        ''');
        
        // Check each iframe
        int count = double.parse(iframesCount.toString()).toInt();
        for (int i = 0; i < count; i++) {
          // Get iframe source or name to identify the right one
          final iframeSrc = await _controller.runJavaScriptReturningResult(
            'document.querySelectorAll("iframe")[' + i.toString() + '].src'
          );
          final iframeName = await _controller.runJavaScriptReturningResult(
            'document.querySelectorAll("iframe")[' + i.toString() + '].name'
          );
          
          print('Iframe $i - src: $iframeSrc, name: $iframeName');
          
          // Check if this iframe is likely to contain the timetable
          // Adjust these conditions based on your specific educational system
          if (iframeSrc.toString().contains('xskb_list') || 
              iframeSrc.toString().contains('kbcx') ||
              iframeName.toString().contains('xskb')) {
              
            // Try to get content from this iframe - this is the key part
            final iframeContent = await _controller.runJavaScriptReturningResult('''
              (function() {
                try {
                  const iframe = document.querySelectorAll("iframe")[${i}];
                  if (iframe.contentDocument) {
                    return iframe.contentDocument.documentElement.outerHTML;
                  } else {
                    return "无法访问iframe内容 - 可能受到同源策略限制";
                  }
                } catch(e) {
                  return "获取iframe内容错误: " + e.message;
                }
              })()
            ''');
            
            // Convert result to string (removing quotes from JS string)
            html = iframeContent.toString();
            if (html.startsWith('"') && html.endsWith('"')) {
              html = html.substring(1, html.length - 1)
                         .replaceAll("\\\"", "\"")
                         .replaceAll("\\n", "\n")
                         .replaceAll("\\r", "\r")
                         .replaceAll("\\t", "\t");
            }
            
            // If we got something that seems like HTML and contains timetable markers
            if (html.contains("<html") && 
                (html.contains("tbody") || html.contains("kbcontent"))) {
              foundTarget = true;
              break; // Found what we need, stop checking other iframes
            }
            
            // 如果由于同源策略无法直接获取iframe内容，尝试注入JavaScript到iframe
            if (html.contains("同源策略")) {
              print("正在尝试注入脚本到iframe...");
              await _controller.runJavaScript('''
                (function() {
                  try {
                    const iframe = document.querySelectorAll("iframe")[${i}];
                    // 创建一个脚本，让iframe将其内容发送到主页面
                    const script = document.createElement('script');
                    script.textContent = `
                      window.parent.postMessage({
                        type: 'iframeContent',
                        html: document.documentElement.outerHTML
                      }, '*');
                    `;
                    iframe.contentWindow.document.head.appendChild(script);
                  } catch(e) {
                    console.error("注入脚本错误:", e);
                  }
                })()
              ''');
              
              // 等待消息事件
              await Future.delayed(Duration(seconds: 1));
              
              // 尝试使用iframe导航方式
              final mainUrl = await _controller.currentUrl();
              if (mainUrl != null && iframeSrc.toString().length > 2) {
                // 从引号中提取实际URL
                String targetUrl = iframeSrc.toString();
                if (targetUrl.startsWith('"') && targetUrl.endsWith('"')) {
                  targetUrl = targetUrl.substring(1, targetUrl.length - 1);
                }
                
                setState(() {
                  _statusMessage = '正在直接导航到课表页面...';
                });
                
                // 直接导航到iframe的URL
                await _controller.loadRequest(Uri.parse(targetUrl));
                await Future.delayed(Duration(seconds: 2)); // 等待加载
                
                // 现在我们直接在iframe页面上，获取HTML
                final directHtml = await _controller.runJavaScriptReturningResult(
                  'document.documentElement.outerHTML'
                );
                
                html = directHtml.toString();
                if (html.startsWith('"') && html.endsWith('"')) {
                  html = html.substring(1, html.length - 1)
                           .replaceAll("\\\"", "\"")
                           .replaceAll("\\n", "\n")
                           .replaceAll("\\r", "\r")
                           .replaceAll("\\t", "\t");
                }
                
                if (html.contains("tbody") || html.contains("kbcontent")) {
                  foundTarget = true;
                }
              }
            }
          }
        }
      }
      
      // If we didn't find content in iframes, try getting content from the main page
      if (!foundTarget) {
        // Check if there's a specific div with timetable
        final mainTableExists = await _controller.runJavaScriptReturningResult(
          'document.querySelector(".timetable") != null || document.querySelector(".kbcontent") != null'
        );
        
        if (mainTableExists.toString() == 'true') {
          final mainHtml = await _controller.runJavaScriptReturningResult(
            'document.documentElement.outerHTML'
          );
          
          html = mainHtml.toString();
          if (html.startsWith('"') && html.endsWith('"')) {
            html = html.substring(1, html.length - 1)
                       .replaceAll("\\\"", "\"")
                       .replaceAll("\\n", "\n")
                       .replaceAll("\\r", "\r")
                       .replaceAll("\\t", "\t");
          }
          
          foundTarget = true;
        }
      }

      // If we still haven't found the content, try a direct approach for tbody
      if (!foundTarget || !html.contains("tbody")) {
        final tbodyContent = await _controller.runJavaScriptReturningResult('''
          (function() {
            const tbodies = document.querySelectorAll("tbody");
            for (let i = 0; i < tbodies.length; i++) {
              if (tbodies[i].querySelectorAll("td").length > 20) {
                return "<table><tbody>" + tbodies[i].innerHTML + "</tbody></table>";
              }
            }
            return "";
          })()
        ''');
        
        String tbodyHtml = tbodyContent.toString();
        if (tbodyHtml.startsWith('"') && tbodyHtml.endsWith('"')) {
          tbodyHtml = tbodyHtml.substring(1, tbodyHtml.length - 1)
                   .replaceAll("\\\"", "\"")
                   .replaceAll("\\n", "\n")
                   .replaceAll("\\r", "\r")
                   .replaceAll("\\t", "\t");
        }
        
        if (tbodyHtml.length > 100) {
          html = "<html><body>" + tbodyHtml + "</body></html>";
          foundTarget = true;
        }
      }

      if (!foundTarget || html.isEmpty) {
        setState(() {
          _statusMessage = '未能找到课程表内容，请尝试直接导航到课表页面';
          _isLoading = false;
        });
        
        _showTableDebugDialog();
        return;
      }
      
      // Debug: Log the first part of the HTML content
      print('获取到HTML内容，长度: ${html.length}');
      print('HTML前300字符: ${html.substring(0, min(300, html.length))}');
      
      // Parse timetable from HTML
      final events = TimetableParser.parseTimetable(html);
      
      if (events.isEmpty) {
        setState(() {
          _statusMessage = '获取到HTML但未能解析出课程，请确保已显示课表内容';
          _isLoading = false;
        });
        
        _showParsingDebugDialog(html);
        return;
      }
      
      setState(() {
        _statusMessage = '成功解析 ${events.length} 个课程';
        _isLoading = false;
      });
      
      // Return the events to the parent widget
      widget.onEventsImported(events);
    } catch (e) {
      setState(() {
        _statusMessage = '解析过程中出错: $e';
        _isLoading = false;
      });
      print('Error parsing timetable: $e');
    }
  }

  void _showTableDebugDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('调试信息'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('未在页面上找到课程表元素。可能的原因：'),
            SizedBox(height: 8),
            Text('1. 未登录或未导航到正确的课表页面'),
            Text('2. 学校教务系统更新，表格ID或结构已变化'),
            Text('3. 页面未完全加载，请尝试点击刷新后再解析'),
            SizedBox(height: 16),
            Text('请尝试的操作：'),
            Text('- 手动在页面中导航到"学期理论课表"'),
            Text('- 确保课表已经完全显示在页面上'),
            Text('- 刷新页面后再次尝试'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }
  
  void _showPageContentDialog(String html) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('页面内容分析'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('页面内容中未找到课程表相关标记，可能是：'),
            const SizedBox(height: 8),
            const Text('1. 未登录或未导航到课表页面'),
            const Text('2. 学校系统使用了不同的标记方式'),
            const SizedBox(height: 16),
            const Text('页面内容片段：'),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              height: 100,
              child: SingleChildScrollView(
                child: Text(
                  html.length > 1000 
                      ? html.substring(0, 1000) + '...' 
                      : html,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
  
  void _showParsingDebugDialog(String html) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解析调试'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('获取到HTML但未能解析出课程，可能原因：'),
            const SizedBox(height: 8),
            const Text('1. 学校教务系统格式与解析器不匹配'),
            const Text('2. 页面中的课表为空（无课程）'),
            const Text('3. 需要更新TimetableParser适配新格式'),
            const SizedBox(height: 16),
            const Text('检查页面是否包含关键元素：'),
            Text('包含"kbcontent": ${html.contains("kbcontent")}'),
            Text('包含"课表": ${html.contains("课表")}'),
            Text('HTML长度: ${html.length}字符'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 尝试使用更宽松的解析方式（实际应用中可能需要实现）
              Navigator.of(context).pop();
              _showMessage('尝试使用备选解析方式...');
            },
            child: const Text('尝试备选解析'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
  
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  // 帮助函数
  int min(int a, int b) => a < b ? a : b;
}