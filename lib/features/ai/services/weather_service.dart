import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WeatherService {
  static const String apiKey = '158e173060d97aa31a8e26230a6cb3cc';
  static const String baseUrl = 'https://restapi.amap.com/v3/weather/weatherInfo';
  
  // 获取城市天气信息
  Future<Map<String, dynamic>> getWeather({String cityCode = '659001'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?city=$cityCode&key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' && data['lives'] is List && data['lives'].isNotEmpty) {
          return _formatWeatherData(data['lives'][0]);
        } else {
          throw Exception('天气API返回数据无效: ${data['info'] ?? '未知错误'}');
        }
      } else {
        throw Exception('天气API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取天气信息错误: $e');
      // 返回模拟天气数据
      return _getSimulatedWeather(cityCode);
    }
  }
  
  // 将原始天气数据格式化为更易理解的格式
  Map<String, dynamic> _formatWeatherData(Map<String, dynamic> rawData) {
    // 格式化日期时间
    final reportTime = rawData['reporttime'] ?? DateTime.now().toString().substring(0, 16);
    final dateTime = DateTime.parse('${reportTime.split(' ')[0]}T${reportTime.split(' ')[1]}:00');
    final formattedTime = DateFormat('MM月dd日 HH:mm').format(dateTime);
    
    // 获取天气描述和建议
    final weather = rawData['weather'] ?? '未知';
    final temperature = rawData['temperature'] ?? '0';
    final humidity = rawData['humidity'] ?? '0';
    final windDirection = rawData['winddirection'] ?? '无风向';
    final windPower = rawData['windpower'] ?? '0';
    final suggestion = _getWeatherSuggestion(weather, double.parse(temperature));
    
    return {
      'city': rawData['city'] ?? '石河子市',
      'weather': weather,
      'temperature': temperature,
      'humidity': humidity,
      'windDirection': windDirection,
      'windPower': windPower,
      'reportTime': formattedTime,
      'suggestion': suggestion,
      'isSimulated': false,
    };
  }
  
  // 根据天气情况生成建议
  String _getWeatherSuggestion(String weather, double temperature) {
    String suggestion = '';
    
    // 温度相关建议
    if (temperature < 5) {
      suggestion += '今天气温较低，外出请注意保暖，穿厚一点。';
    } else if (temperature < 15) {
      suggestion += '今天温度适中偏凉，建议穿外套或薄毛衣。';
    } else if (temperature < 25) {
      suggestion += '今天温度舒适，适宜户外活动。';
    } else if (temperature < 30) {
      suggestion += '今天气温较高，注意防晒，多喝水。';
    } else {
      suggestion += '今天温度很高，注意防暑降温，避免长时间户外活动。';
    }
    
    // 天气相关建议
    if (weather.contains('雨')) {
      suggestion += '有雨，出门请带伞。';
    } else if (weather.contains('雪')) {
      suggestion += '有雪，路面可能湿滑，注意安全。';
    } else if (weather.contains('雾') || weather.contains('霾')) {
      suggestion += '空气质量不佳，建议戴口罩，减少户外活动。';
    } else if (weather.contains('晴')) {
      suggestion += '天气晴朗，紫外线较强，注意防晒。';
    }
    
    return suggestion;
  }
  
  // 生成模拟天气数据（用于开发测试）
  Map<String, dynamic> _getSimulatedWeather(String cityCode) {
    // 根据城市代码返回不同的模拟数据
    final cityName = _getCityNameByCode(cityCode);
    final now = DateTime.now();
    final weatherOptions = ['晴', '多云', '阴', '小雨', '中雨', '大雨', '雷阵雨', '小雪', '中雪'];
    final windDirections = ['东', '南', '西', '北', '东北', '东南', '西北', '西南'];
    
    // 根据日期生成随机但确定的天气和温度
    final weatherIndex = (now.day + int.parse(cityCode.substring(0, 2))) % weatherOptions.length;
    final baseTemp = 20 + (now.month - 6) * 3; // 基础温度随月份变化
    final tempVariation = (now.day % 10) - 5; // 日期引入的温度变化
    final temperature = (baseTemp + tempVariation).toStringAsFixed(1);
    
    final weather = weatherOptions[weatherIndex];
    final windDirection = windDirections[(now.day + int.parse(cityCode.substring(2, 4))) % windDirections.length];
    
    return {
      'city': cityName,
      'weather': weather,
      'temperature': temperature,
      'humidity': '${50 + now.day % 30}',
      'windDirection': windDirection,
      'windPower': '${(now.day % 6) + 1}级',
      'reportTime': DateFormat('MM月dd日 HH:mm').format(now),
      'suggestion': _getWeatherSuggestion(weather, double.parse(temperature)),
      'isSimulated': true,
    };
  }
  
  // 城市代码转换为城市名称
  String _getCityNameByCode(String cityCode) {
    final cityMap = {
      '659001': '石河子市',
      '659002': '阿拉尔市',
      '659003': '图木舒克市',
      '659004': '五家渠市',
      '650100': '乌鲁木齐市',
      '650200': '克拉玛依市',
      '652300': '昌吉回族自治州',
      '652700': '博尔塔拉蒙古自治州',
      '652800': '巴音郭楞蒙古自治州',
      '652900': '阿克苏地区',
      '653000': '克孜勒苏柯尔克孜自治州',
      '653100': '喀什地区',
      '653200': '和田地区',
      '654000': '伊犁哈萨克自治州',
      '654200': '塔城地区',
      '654300': '阿勒泰地区',
    };
    
    return cityMap[cityCode] ?? '石河子市';
  }
  
  // 格式化天气信息为易读文本
  static String formatWeatherToText(Map<String, dynamic> weatherData) {
    final buffer = StringBuffer();
    
    final city = weatherData['city'];
    final weather = weatherData['weather'];
    final temperature = weatherData['temperature'];
    final reportTime = weatherData['reportTime'];
    final windInfo = '${weatherData['windDirection']}风${weatherData['windPower']}';
    final humidity = weatherData['humidity'];
    final suggestion = weatherData['suggestion'];
    final isSimulated = weatherData['isSimulated'] ?? false;
    
    buffer.writeln("$city天气情况（${isSimulated ? '模拟数据' : '实时数据'}）:");
    buffer.writeln("📅 $reportTime 更新");
    buffer.writeln("🌤️ 天气: $weather");
    buffer.writeln("🌡️ 温度: ${temperature}°C");
    buffer.writeln("💨 风况: $windInfo");
    buffer.writeln("💧 湿度: ${humidity}%");
    buffer.writeln("\n🔔 建议: $suggestion");
    
    return buffer.toString();
  }
}