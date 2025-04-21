import 'package:StoneU_Hood/features/ai/services/llm_chat_service.dart';
import 'package:intl/intl.dart';
import '../services/community_service.dart';
import '../services/weather_service.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../calendar/services/event_repository.dart';
import '../../calendar/models/event.dart';

/// 智能助手工具类 - 用于AI调用的各种功能接口
class AIAgentTools {
  static final CommunityService _communityService = CommunityService();
  static final WeatherService _weatherService = WeatherService();
  static final EventRepository _eventRepository = EventRepository();
  
  // ========== 天气相关工具 ==========
  
  /// 获取石河子市天气信息，包含穿衣建议
  static Future<String> getWeather() async {
    try {
      final weatherData = await _weatherService.getRealTimeWeather();
      final weatherText = WeatherService.formatForecastToText(weatherData);
      final clothingSuggestion = getClothingSuggestion(weatherData);
      final umbrellaAdvice = getUmbrellaAdvice(weatherData);
      
      return '''$weatherText
      
$clothingSuggestion

$umbrellaAdvice''';
    } catch (e) {
      return "获取天气信息失败: $e";
    }
  }
  
  /// 获取指定城市的天气信息，包含穿衣建议
  static Future<String> getWeatherByCity(String city) async {
    try {
      // 简单的城市名称到代码的映射
      final cityCodeMap = {
        '石河子': '659001',
        '石河子市': '659001',
        '乌鲁木齐': '650100',
        '乌鲁木齐市': '650100',
        '克拉玛依': '650200',
        '克拉玛依市': '650200',
        '昌吉': '652300',
        '阿克苏': '652900',
        '喀什': '653100',
        '伊犁': '654000',
      };
      
      final cityCode = cityCodeMap[city] ?? '659001'; // 默认石河子市
      final weatherData = await _weatherService.getRealTimeWeather(cityCode: cityCode);
      final weatherText = WeatherService.formatForecastToText(weatherData);
      final clothingSuggestion = getClothingSuggestion(weatherData);
      final umbrellaAdvice = getUmbrellaAdvice(weatherData);
      
      return '''$weatherText
      
$clothingSuggestion

$umbrellaAdvice''';
    } catch (e) {
      return "获取 $city 天气信息失败: $e";
    }
  }
  
  /// 根据天气数据生成穿衣建议
  static String getClothingSuggestion(Map<String, dynamic> weatherData) {
    try {
      final tempDay = weatherData['forecast'][0]['tempDay'] as String;
      final tempNight = weatherData['forecast'][0]['tempNight'] as String;
      final dayTempInt = int.parse(tempDay);
      final nightTempInt = int.parse(tempNight);
      
      String suggestion = "👕 今日穿衣建议: ";
      
      if (dayTempInt >= 30) {
        suggestion += "天气炎热，建议穿短袖短裤，防晒措施必不可少。";
      } else if (dayTempInt >= 25) {
        suggestion += "天气温暖，建议穿轻薄衣物，外出可带薄外套。";
      } else if (dayTempInt >= 20) {
        suggestion += "天气舒适，建议穿薄长袖或T恤，配薄外套。";
      } else if (dayTempInt >= 15) {
        suggestion += "天气凉爽，建议穿长袖衬衫或薄毛衣，配外套。";
      } else if (dayTempInt >= 10) {
        suggestion += "天气较凉，建议穿长袖衬衫、毛衣和轻便外套。";
      } else if (dayTempInt >= 5) {
        suggestion += "天气转冷，建议穿棉衣或羊毛衫，配保暖外套。";
      } else if (dayTempInt >= 0) {
        suggestion += "天气寒冷，建议穿厚羽绒服或棉衣，注意保暖。";
      } else {
        suggestion += "天气严寒，建议穿厚羽绒服、保暖内衣和防风外套，注意防寒。";
      }
      
      // 昼夜温差提示
      int tempDiff = dayTempInt - nightTempInt;
      if (tempDiff >= 10) {
        suggestion += " 昼夜温差大，请随身携带外套。";
      }
      
      return suggestion;
    } catch (e) {
      return "👕 穿衣建议: 根据当前天气情况，建议适当增减衣物。";
    }
  }
  
  /// 生成是否需要带伞的建议
  static String getUmbrellaAdvice(Map<String, dynamic> weatherData) {
    try {
      final weather = weatherData['forecast'][0]['weather'] as String;
      final weatherKeywords = ['雨', '阵雨', '雷阵雨', '小雨', '中雨', '大雨', '暴雨', '雪', '阵雪', '小雪', '中雪', '大雪'];
      
      if (weatherKeywords.any((keyword) => weather.contains(keyword))) {
        return "☔ 今日需要带伞，预计有$weather天气。";
      } else if (weather.contains('阴') || weather.contains('多云')) {
        return "☂️ 今日天气$weather，建议备伞，以防天气突变。";
      } else {
        return "☀️ 今日天气良好，无需带伞。";
      }
    } catch (e) {
      return "☂️ 建议随身准备雨伞，以备不时之需。";
    }
  }
  
  // ========== 社区帖子相关工具 ==========
  
  /// 获取最新帖子列表
  static Future<String> getRecentPosts({int limit = 5}) async {
    try {
      final posts = await _communityService.getRecentPosts(limit: limit);
      return CommunityService.formatPostsToText(posts);
    } catch (e) {
      return "获取最新帖子失败: $e";
    }
  }
  
  /// 搜索帖子
  static Future<String> searchPosts({
    String? query,
    String? category,
    int limit = 5,
  }) async {
    try {
      final posts = await _communityService.searchPosts(
        query: query,
        category: category,
        limit: limit,
      );
      return CommunityService.formatPostsToText(posts);
    } catch (e) {
      return "搜索帖子失败: $e";
    }
  }
  
  /// 创建新帖子
  static Future<String> createPost({
    required String title,
    required String content,
    required String category,
    List<String> tags = const [],
  }) async {
    try {
      final post = await _communityService.createPost(
        title: title,
        content: content,
        category: category,
        tags: tags,
      );
      
      return '''帖子创建成功！
标题: ${post.title}
分类: ${post.category}
内容: ${post.content.length > 50 ? post.content.substring(0, 50) + '...' : post.content}
${tags.isNotEmpty ? '标签: ${tags.join(', ')}' : ''}
''';
    } catch (e) {
      return "创建帖子失败: $e";
    }
  }
  
  /// 获取用户可能感兴趣的帖子推荐
  static Future<String> getRecommendedPosts({
    required List<String> userInterests,
    int limit = 5,
  }) async {
    try {
      final posts = await _communityService.getRecommendedPosts(
        userInterests: userInterests,
        limit: limit,
      );
      
      if (posts.isEmpty) {
        return "暂无符合您兴趣的帖子推荐。";
      }
      
      final buffer = StringBuffer();
      buffer.writeln("📢 您可能感兴趣的帖子：\n");
      buffer.write(CommunityService.formatPostsToText(posts));
      
      return buffer.toString();
    } catch (e) {
      return "获取推荐帖子失败: $e";
    }
  }
  
  // ========== 环境信息感知工具 ==========
  
  /// 获取当前日期、时间、星期几等信息
  static String getCurrentDateInfo() {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy年MM月dd日');
    final timeFormat = DateFormat('HH:mm:ss');
    final weekdayNames = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final weekday = weekdayNames[now.weekday - 1];
    
    // 计算当前课程周次
    final semesterStart = DateTime(2025, 2, 24); // 假设2025春季学期从2月24日开始
    final diffDays = now.difference(semesterStart).inDays;
    final currentWeek = (diffDays / 7).floor() + 1;
    
    return '''
📅 今天是 ${dateFormat.format(now)} $weekday
⏰ 当前时间: ${timeFormat.format(now)}
📚 当前教学周: 第$currentWeek周
''';
  }
  
  /// 获取当前和未来一周的重要日期
  static String getImportantDates() {
    final now = DateTime.now();
    final dateFormat = DateFormat('MM月dd日');
    final importantDates = <String, String>{};
    
    // 添加重要日期信息
    final chineseNewYear = DateTime(2025, 1, 29);
    final laborDay = DateTime(2025, 5, 1);
    final nationalDay = DateTime(2025, 10, 1);
    final examWeek = DateTime(2025, 6, 30);
    
    // 计算与今天的天数差
    final daysToChineseNewYear = chineseNewYear.difference(now).inDays;
    final daysToLaborDay = laborDay.difference(now).inDays;
    final daysToNationalDay = nationalDay.difference(now).inDays;
    final daysToExamWeek = examWeek.difference(now).inDays;
    
    // 只添加未来的日期
    if (daysToChineseNewYear > 0) {
      importantDates['春节'] = '$daysToChineseNewYear 天后 (${dateFormat.format(chineseNewYear)})';
    }
    if (daysToLaborDay > 0) {
      importantDates['劳动节'] = '$daysToLaborDay 天后 (${dateFormat.format(laborDay)})';
    }
    if (daysToNationalDay > 0) {
      importantDates['国庆节'] = '$daysToNationalDay 天后 (${dateFormat.format(nationalDay)})';
    }
    if (daysToExamWeek > 0) {
      importantDates['期末考试周'] = '$daysToExamWeek 天后 (${dateFormat.format(examWeek)})';
    }
    
    // 检查是否有60天内的重要日期
    final nearDates = importantDates.entries
        .where((entry) => int.parse(entry.value.split(' ')[0]) <= 60)
        .toList();
    
    if (nearDates.isEmpty) {
      return "近期没有重要节日或日期。";
    }
    
    final buffer = StringBuffer();
    buffer.writeln("🗓️ 近期重要日期提醒：");
    
    for (var date in nearDates) {
      buffer.writeln("${date.key}: ${date.value}");
    }
    
    return buffer.toString();
  }
  
  // ========== 工具组合功能 ==========
  
  /// 获取综合环境信息（日期、天气等）
  static Future<String> getEnvironmentInfo() async {
    final buffer = StringBuffer();
    
    // 添加日期信息
    buffer.writeln(getCurrentDateInfo());
    
    // 添加天气信息
    try {
      final weatherData = await _weatherService.getRealTimeWeather();
      final weatherText = WeatherService.formatForecastToText(weatherData);
      final clothingSuggestion = getClothingSuggestion(weatherData);
      final umbrellaAdvice = getUmbrellaAdvice(weatherData);
      
      buffer.writeln("\n$weatherText");
      buffer.writeln("\n$clothingSuggestion");
      buffer.writeln("$umbrellaAdvice");
    } catch (e) {
      buffer.writeln("\n获取天气信息失败，请稍后再试。");
    }
    
    // 添加近期重要日期
    final importantDates = getImportantDates();
    if (importantDates != "近期没有重要节日或日期。") {
      buffer.writeln("\n$importantDates");
    }
    
    return buffer.toString();
  }
  
  /// 智能帖子分析和改进
  static Future<String> enhancePostContent({
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      // 简单的内容增强逻辑
      String enhancedTitle = title;
      String enhancedContent = content;
      
      // 根据分类添加标签
      final List<String> suggestedTags = [];
      
      if (category == '学习') {
        suggestedTags.addAll(['课程', '学习方法', '石大课程']);
        
        // 加入一些常见的学习资源
        enhancedContent += '\n\n推荐学习资源:\n';
        enhancedContent += '1. 石河子大学图书馆电子资源\n';
        enhancedContent += '2. 中国知网学术文献\n';
        enhancedContent += '3. 学校MOOC平台课程';
      } else if (category == '生活') {
        suggestedTags.addAll(['校园生活', '石大生活', '新生指南']);
        
        // 添加一些生活提示
        enhancedContent += '\n\n校园生活小贴士:\n';
        enhancedContent += '1. 校园食堂推荐: 一食堂的兰州拉面、三食堂的麻辣烫\n';
        enhancedContent += '2. 校内快递点位置和营业时间\n';
        enhancedContent += '3. 周边商场和超市信息';
      } else if (category == '活动') {
        suggestedTags.addAll(['校园活动', '社团', '文艺汇演']);
        
        // 活动相关提示
        enhancedContent += '\n\n活动小贴士:\n';
        enhancedContent += '1. 记得提前在学校公众号报名\n';
        enhancedContent += '2. 活动地点和时间安排\n';
        enhancedContent += '3. 参与方式和注意事项';
      }
      
      return '''帖子内容已增强！

标题: $enhancedTitle
分类: $category
推荐标签: ${suggestedTags.join(', ')}

内容预览:
${enhancedContent.length > 200 ? enhancedContent.substring(0, 200) + '...' : enhancedContent}

是否要使用这个增强后的内容发布帖子？请回复"是"或"否"。
''';
    } catch (e) {
      return "内容增强过程中发生错误: $e";
    }
  }
  
  // ========== 课程和日程相关工具 ==========
  
  /// 解析自然语言时间表达
  static Future<DateTime?> parseNaturalLanguageDate(String input) async {
    final now = DateTime.now();
    
    // 常见的日期表达式
    if (input.contains('今天')) {
      return DateTime(now.year, now.month, now.day);
    } else if (input.contains('明天')) {
      return now.add(Duration(days: 1));
    } else if (input.contains('后天')) {
      return now.add(Duration(days: 2));
    } else if (input.contains('昨天')) {
      return now.subtract(Duration(days: 1));
    } else if (input.contains('大后天')) {
      return now.add(Duration(days: 3));
    }
    
    // 星期表达
    final weekdayMap = {
      '星期一': 1, '周一': 1, '礼拜一': 1,
      '星期二': 2, '周二': 2, '礼拜二': 2,
      '星期三': 3, '周三': 3, '礼拜三': 3,
      '星期四': 4, '周四': 4, '礼拜四': 4,
      '星期五': 5, '周五': 5, '礼拜五': 5,
      '星期六': 6, '周六': 6, '礼拜六': 6,
      '星期日': 7, '周日': 7, '礼拜日': 7, '星期天': 7, '周天': 7
    };
    
    for (final entry in weekdayMap.entries) {
      if (input.contains(entry.key)) {
        // 计算从今天到指定星期几的天数
        int daysToAdd = (entry.value - now.weekday) % 7;
        if (daysToAdd == 0) daysToAdd = 7; // 如果是当前星期几，则计算下一周
        
        // 如果包含"下周"，增加7天
        if (input.contains('下周') || input.contains('下星期') || input.contains('下礼拜')) {
          daysToAdd += 7;
        }
        
        return now.add(Duration(days: daysToAdd));
      }
    }
    
    // 尝试直接解析日期格式
    final dateRegex = RegExp(r'(\d{1,2})月(\d{1,2})日');
    final match = dateRegex.firstMatch(input);
    if (match != null) {
      final month = int.parse(match.group(1)!);
      final day = int.parse(match.group(2)!);
      return DateTime(now.year, month, day);
    }
    
    // 默认返回null，表示无法解析
    return null;
  }
  
  /// 获取指定日期的课程
  static Future<String> getCoursesForNaturalLanguageDate(String dateText) async {
    try {
      // 解析自然语言日期
      final date = await parseNaturalLanguageDate(dateText);
      if (date == null) {
        return "抱歉，无法理解您提供的日期。请尝试使用今天、明天、周三等表达方式。";
      }
      
      // 获取该日期的课程
      final events = await _eventRepository.getEvents();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      // 筛选出该日期的课程
      final eventsOnDate = events.where((event) => 
        DateFormat('yyyy-MM-dd').format(event.startTime) == dateStr
      ).toList();
      
      // 按时间排序
      eventsOnDate.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      if (eventsOnDate.isEmpty) {
        final formatter = DateFormat('yyyy年MM月dd日');
        return "${formatter.format(date)} 没有安排课程，可以安心休息或处理其他事务。";
      }
      
      // 格式化结果
      final buffer = StringBuffer();
      final dateFormat = DateFormat('yyyy年MM月dd日');
      final dayName = ['', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'][date.weekday];
      buffer.writeln("📚 ${dateFormat.format(date)} $dayName 课程安排：\n");
      
      for (var i = 0; i < eventsOnDate.length; i++) {
        final event = eventsOnDate[i];
        final startTime = DateFormat('HH:mm').format(event.startTime);
        final endTime = DateFormat('HH:mm').format(event.endTime);
        
        buffer.writeln("${i + 1}. ${event.title} (${startTime}-${endTime})");
        
        // 提取地点信息
        if (event.notes.isNotEmpty) {
          final locationMatch = RegExp(r'地点: (.+?)(?:\n|$)').firstMatch(event.notes);
          if (locationMatch != null) {
            buffer.writeln("   📍 地点: ${locationMatch.group(1)}");
          }
          
          // 提取教师信息
          final teacherMatch = RegExp(r'教师: (.+?)(?:\n|$)').firstMatch(event.notes);
          if (teacherMatch != null) {
            buffer.writeln("   👨‍🏫 教师: ${teacherMatch.group(1)}");
          }
        }
        
        buffer.writeln("");
      }
      
      return buffer.toString();
    } catch (e) {
      return "获取课程信息时出错: $e";
    }
  }
  
  /// 删除事件的增强版本，可以处理自然语言表达
  static Future<String> deleteEventByNaturalLanguage(String query) async {
    try {
      // 首先尝试直接从查询中提取事件ID
      final idRegex = RegExp(r'id[: ]?([a-zA-Z0-9-_]+)');
      final idMatch = idRegex.firstMatch(query);
      
      if (idMatch != null && idMatch.group(1) != null) {
        final eventId = idMatch.group(1)!;
        return await AgentTools.deleteEvent(eventId);
      }
      
      // 尝试根据课程名称和时间删除
      final events = await _eventRepository.getEvents();
      
      // 尝试提取日期
      DateTime? date;
      final dateRegex = RegExp(r'(\d{1,2})月(\d{1,2})日');
      final dateMatch = dateRegex.firstMatch(query);
      if (dateMatch != null) {
        final month = int.parse(dateMatch.group(1)!);
        final day = int.parse(dateMatch.group(2)!);
        date = DateTime(DateTime.now().year, month, day);
      } else {
        // 尝试解析自然语言日期
        date = await parseNaturalLanguageDate(query);
      }
      
      // 尝试提取课程名称
      final potentialEvents = events.where((event) {
        bool isMatch = true;
        
        // 如果有日期，检查日期是否匹配
        if (date != null) {
          final eventDate = DateTime(
            event.startTime.year,
            event.startTime.month,
            event.startTime.day,
          );
          final queryDate = DateTime(
            date.year,
            date.month,
            date.day,
          );
          isMatch = eventDate.isAtSameMomentAs(queryDate);
        }
        
        // 课程名称匹配
        if (isMatch && event.title.toLowerCase().contains(query.toLowerCase())) {
          return true;
        }
        
        return isMatch;
      }).toList();
      
      if (potentialEvents.isEmpty) {
        return "没有找到符合条件的课程。请提供更详细的信息，例如课程名称或日期。";
      } else if (potentialEvents.length == 1) {
        // 如果只找到一个匹配项，直接删除
        return await AgentTools.deleteEvent(potentialEvents[0].id);
      } else {
        // 如果找到多个匹配项，列出来让用户选择
        final buffer = StringBuffer();
        buffer.writeln("找到多个可能的课程，请选择要删除的课程编号：\n");
        
        for (var i = 0; i < potentialEvents.length; i++) {
          final event = potentialEvents[i];
          final dateFormat = DateFormat('yyyy-MM-dd');
          final timeFormat = DateFormat('HH:mm');
          
          buffer.writeln("${i + 1}. ${event.title}");
          buffer.writeln("   日期: ${dateFormat.format(event.startTime)}");
          buffer.writeln("   时间: ${timeFormat.format(event.startTime)}-${timeFormat.format(event.endTime)}");
          buffer.writeln("   ID: ${event.id}");
          buffer.writeln("");
        }
        
        buffer.writeln("请回复 删除+编号 来删除特定课程，例如 删除1 ");
        
        // 将候选事件列表保存到临时存储
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'temp_delete_events',
          json.encode(potentialEvents.map((e) => {'id': e.id, 'title': e.title}).toList()),
        );
        
        return buffer.toString();
      }
    } catch (e) {
      return "处理删除请求时出错: $e";
    }
  }
  
  /// 添加事件的增强版本，支持自然语言解析
  static Future<String> addEventFromNaturalLanguage(String query) async {
    try {
      // 尝试解析课程名称
      String title = "";
      final titleRegex = RegExp(r'(课程|添加|新增|安排)[\s:：]?([^，。,\.]+)');
      final titleMatch = titleRegex.firstMatch(query);
      if (titleMatch != null && titleMatch.group(2) != null) {
        title = titleMatch.group(2)!.trim();
      } else {
        return "无法识别课程名称，请提供明确的课程名称。";
      }
      
      // 尝试解析日期
      DateTime? date;
      final now = DateTime.now();
      final dateRegex = RegExp(r'(\d{1,2})月(\d{1,2})日');
      final dateMatch = dateRegex.firstMatch(query);
      if (dateMatch != null) {
        final month = int.parse(dateMatch.group(1)!);
        final day = int.parse(dateMatch.group(2)!);
        date = DateTime(now.year, month, day);
      } else {
        // 尝试解析自然语言日期
        date = await parseNaturalLanguageDate(query);
      }
      
      if (date == null) {
        return "无法识别日期，请提供明确的日期信息，如10月1日或下周一。";
      }
      
      // 尝试解析时间
      DateTime? startTime;
      DateTime? endTime;
      
      // 解析时间范围，如"9:00-11:00"
      final timeRangeRegex = RegExp(r'(\d{1,2})[:.：](\d{2})[\s-至到]+(\d{1,2})[:.：](\d{2})');
      final timeRangeMatch = timeRangeRegex.firstMatch(query);
      
      if (timeRangeMatch != null) {
        final startHour = int.parse(timeRangeMatch.group(1)!);
        final startMinute = int.parse(timeRangeMatch.group(2)!);
        final endHour = int.parse(timeRangeMatch.group(3)!);
        final endMinute = int.parse(timeRangeMatch.group(4)!);
        
        startTime = DateTime(date.year, date.month, date.day, startHour, startMinute);
        endTime = DateTime(date.year, date.month, date.day, endHour, endMinute);
      } else {
        // 解析单一时间点，默认课程2小时
        final timeRegex = RegExp(r'(\d{1,2})[:.：](\d{2})');
        final timeMatch = timeRegex.firstMatch(query);
        
        if (timeMatch != null) {
          final hour = int.parse(timeMatch.group(1)!);
          final minute = int.parse(timeMatch.group(2)!);
          
          startTime = DateTime(date.year, date.month, date.day, hour, minute);
          endTime = startTime.add(Duration(hours: 2));
        } else {
          // 没有明确时间，使用默认时间
          startTime = DateTime(date.year, date.month, date.day, 9, 0);
          endTime = DateTime(date.year, date.month, date.day, 11, 0);
        }
      }
      
      // 尝试解析地点
      String location = "";
      final locationRegex = RegExp(r'(地点|位置|教室|在)[是:：为]?[\s]?([^，。,\.]+)');
      final locationMatch = locationRegex.firstMatch(query);
      if (locationMatch != null && locationMatch.group(2) != null) {
        location = locationMatch.group(2)!.trim();
      }
      
      // 尝试解析教师
      String teacher = "";
      final teacherRegex = RegExp(r'(老师|教师|讲师|授课|上课)[是:：为]?[\s]?([^，。,\.]+)');
      final teacherMatch = teacherRegex.firstMatch(query);
      if (teacherMatch != null && teacherMatch.group(2) != null) {
        teacher = teacherMatch.group(2)!.trim();
      }
      
      // 构建课程备注
      String notes = "";
      if (location.isNotEmpty) {
        notes += "地点: $location\n";
      }
      if (teacher.isNotEmpty) {
        notes += "教师: $teacher\n";
      }
      
      // 添加事件
      return await AgentTools.addEvent(
        title: title,
        startTime: startTime,
        endTime: endTime,
        notes: notes,
      );
    } catch (e) {
      return "处理添加课程请求时出错: $e";
    }
  }
  
  /// 生成个性化的问候语
  static Future<String> generateGreeting({
    Map<String, dynamic>? userKnowledge,
    List<CalendarEvent>? todayEvents,
    Map<String, dynamic>? weatherData,
  }) async {
    try {
      // 获取当前时间和日期信息
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy年MM月dd日');
      final timeFormat = DateFormat('HH:mm');
      final weekdayNames = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
      final weekday = weekdayNames[now.weekday - 1];
      
      // 获取用户名 (默认值)
      String userName = (userKnowledge != null && userKnowledge.containsKey('user_name')) ? userKnowledge['user_name'] : '同学';
      
      // 生成时间相关问候
      String timeGreeting;
      final hour = now.hour;
      if (hour < 6) {
        timeGreeting = "凌晨好";
      } else if (hour < 9) {
        timeGreeting = "早上好";
      } else if (hour < 12) {
        timeGreeting = "上午好";
      } else if (hour < 14) {
        timeGreeting = "中午好";
      } else if (hour < 18) {
        timeGreeting = "下午好";
      } else if (hour < 22) {
        timeGreeting = "晚上好";
      } else {
        timeGreeting = "夜深了";
      }
      
      // 构建基本问候语数据
      final Map<String, dynamic> greetingData = {
        'greeting': "$timeGreeting，$userName！",
        'date': "${dateFormat.format(now)} $weekday",
      };
      
      // 添加天气信息 (使用默认值)
      greetingData['weather'] = {
        'condition': weatherData?['forecast']?[0]?['weather'] ?? '晴朗',
        'tempDay': weatherData?['forecast']?[0]?['tempDay'] ?? '25',
        'tempNight': weatherData?['forecast']?[0]?['tempNight'] ?? '15',
        'clothing': weatherData != null ? getClothingSuggestion(weatherData) : "👕 今日穿衣建议: 温度适宜，建议穿着舒适的衣物。",
        'umbrella': weatherData != null ? getUmbrellaAdvice(weatherData) : "☀️ 今日天气良好，无需带伞。",
      };
      
      // 添加今日课程信息 (使用默认值)
      List<Map<String, dynamic>> formattedEvents = [];
      
      if (todayEvents != null && todayEvents.isNotEmpty) {
        // 按时间排序并处理
        todayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
        
        formattedEvents = todayEvents.map((event) {
          final eventData = {
            'title': event.title,
            'startTime': timeFormat.format(event.startTime),
            'endTime': timeFormat.format(event.endTime),
            'location': '',
            'teacher': '',
          };
          
          // 提取地点和教师信息
          if (event.notes.isNotEmpty) {
            final locationMatch = RegExp(r'地点: (.+?)(?:\n|$)').firstMatch(event.notes);
            if (locationMatch != null) {
              eventData['location'] = locationMatch.group(1)!;
            }
            
            final teacherMatch = RegExp(r'教师: (.+?)(?:\n|$)').firstMatch(event.notes);
            if (teacherMatch != null) {
              eventData['teacher'] = teacherMatch.group(1)!;
            }
          }
          
          return eventData;
        }).toList();
      }
      
      greetingData['events'] = formattedEvents;
      
      // 添加个性化信息 (使用默认值)
      String major = (userKnowledge != null && userKnowledge.containsKey('major')) ? userKnowledge['major'] : '大学生';
      List interests = (userKnowledge != null && userKnowledge.containsKey('interests') && userKnowledge['interests'] is List) ? 
          userKnowledge['interests'] : ['学习', '运动', '音乐', '阅读'];
      
      // 随机选择一条与专业相关的鼓励语
      final majorEncouragements = [
        "作为$major的学生，希望你今天的学习顺利！",
        "$major的课程需要持续努力，加油！",
        "今天也要在$major领域有所收获哦！"
      ];
      
      final interest = interests[Random().nextInt(interests.length)];
      
      greetingData['personal'] = {
        'major': major,
        'majorMessage': majorEncouragements[Random().nextInt(majorEncouragements.length)],
        'interest': interest,
        'interestMessage': "记得抽时间享受一下你喜欢的$interest活动~",
      };
      
      // 添加勉励语
      final encouragements = [
        "愿今天成为充实而美好的一天！",
        "每一天都是新的开始，加油！",
        "今天也要保持好心情哦！",
        "无论多忙，记得照顾好自己~",
      ];
      
      greetingData['encouragement'] = encouragements[Random().nextInt(encouragements.length)];
      
      // 调用渲染函数
      return renderGreetingContent(greetingData);
    } catch (e) {
      // 返回基本问候，以防出错
      return "您好！今天我能为您做些什么？";
    }
  }
  
  /// 渲染问候内容，使其更美观、易读
  static String renderGreetingContent(Map<String, dynamic> greetingData) {
    final buffer = StringBuffer();
    
    // 添加问候标题
    buffer.writeln("${greetingData['greeting']}");
    buffer.writeln("今天是 ${greetingData['date']}");
    buffer.writeln("");
    
    // 添加天气信息面板
    final weather = greetingData['weather'];
    buffer.writeln("今日天气 ");
    buffer.writeln("🌤️  ${weather['condition']}");
    buffer.writeln("🌡️  ${weather['tempNight']}°C ~ ${weather['tempDay']}°C");
    buffer.writeln("${weather['clothing']}");
    buffer.writeln("${weather['umbrella']}");
    buffer.writeln("");
    
    // 添加今日课程信息面板
    buffer.writeln("今日课程");
    final events = greetingData['events'] as List;
    
    if (events.isEmpty) {
      buffer.writeln("📅 今天没有安排课程");
      buffer.writeln("您可以好好休息或处理其他事务");
    } else {
      for (var i = 0; i < events.length; i++) {
        final event = events[i];
        buffer.writeln("${i + 1}. ${event['title']} (${event['startTime']}-${event['endTime']})");
        
        if (event['location'].isNotEmpty) {
          buffer.writeln("📍 地点: ${event['location']}");
        }
        
        if (event['teacher'].isNotEmpty) {
          buffer.writeln("👨‍🏫 教师: ${event['teacher']}");
        }
      }
    }
    buffer.writeln("");
    
    // 添加个性化信息面板
    buffer.writeln("个性化提示");
    final personal = greetingData['personal'];
    buffer.writeln("📚 ${personal['majorMessage']}");
    buffer.writeln("🎯 ${personal['interestMessage']}");
    buffer.writeln("💪 ${greetingData['encouragement']}");
    
    // 添加交互提示
    buffer.writeln("\n有什么我可以帮您的吗？");
    
    return buffer.toString();
  }
}