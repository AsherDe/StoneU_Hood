import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class WeatherService {
  static const String apiKey = '158e173060d97aa31a8e26230a6cb3cc';
  static const String baseUrl = 'https://restapi.amap.com/v3/weather/weatherInfo';
  
  // 获取实时天气信息
  Future<Map<String, dynamic>> getRealTimeWeather({String cityCode = '659001'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?city=$cityCode&key=$apiKey&extensions=base'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' && data['lives'] != null && data['lives'].isNotEmpty) {
          return _formatRealTimeWeatherData(data['lives'][0]);
        } else {
          throw Exception('天气API返回数据无效: ${data['info'] ?? '未知错误'}');
        }
      } else {
        throw Exception('天气API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取实时天气信息错误: $e');
      // 返回模拟天气数据
      return _getSimulatedRealTimeWeather(cityCode);
    }
  }
  
  // 获取天气预报信息
  Future<List<Map<String, dynamic>>> getWeatherForecast({String cityCode = '659001'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?city=$cityCode&key=$apiKey&extensions=all'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' && data['forecasts'] != null && data['forecasts'].isNotEmpty) {
          final forecastList = data['forecasts'][0]['casts'] as List;
          return forecastList.map((item) => _formatForecastData(item, data['forecasts'][0])).toList();
        } else {
          throw Exception('天气预报API返回数据无效: ${data['info'] ?? '未知错误'}');
        }
      } else {
        throw Exception('天气预报API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取天气预报信息错误: $e');
      // 返回模拟天气预报数据
      return _getSimulatedForecast(cityCode);
    }
  }
  
  // 将原始实时天气数据格式化为更易理解的格式
  Map<String, dynamic> _formatRealTimeWeatherData(Map<String, dynamic> rawData) {
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
    final suggestion = _getWeatherSuggestion(weather, double.tryParse(temperature) ?? 0);
    
    return {
      'city': rawData['city'] ?? '石河子市',
      'province': rawData['province'] ?? '新疆',
      'adcode': rawData['adcode'] ?? '659001',
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
  
  // 将原始天气预报数据格式化为更易理解的格式
  Map<String, dynamic> _formatForecastData(Map<String, dynamic> castData, Map<String, dynamic> forecastData) {
    final date = castData['date'];
    final week = castData['week'];
    final dayweather = castData['dayweather'];
    final nightweather = castData['nightweather'];
    final daytemp = castData['daytemp'];
    final nighttemp = castData['nighttemp'];
    final daywind = castData['daywind'];
    final nightwind = castData['nightwind'];
    final daypower = castData['daypower'];
    final nightpower = castData['nightpower'];
    
    // 格式化日期
    DateTime dateTime;
    try {
      dateTime = DateTime.parse(date);
    } catch (e) {
      dateTime = DateTime.now().add(Duration(days: int.tryParse(week) ?? 0));
    }
    final formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
    
    // 生成建议
    double avgTemp = ((double.tryParse(daytemp) ?? 20) + (double.tryParse(nighttemp) ?? 10)) / 2;
    final suggestion = _getWeatherSuggestion(dayweather, avgTemp);
    
    return {
      'city': forecastData['city'] ?? '石河子市',
      'province': forecastData['province'] ?? '新疆',
      'adcode': forecastData['adcode'] ?? '659001',
      'date': formattedDate,
      'week': '星期$week',
      'dayWeather': dayweather,
      'nightWeather': nightweather,
      'dayTemp': daytemp,
      'nightTemp': nighttemp,
      'dayWind': daywind,
      'nightWind': nightwind,
      'dayPower': daypower,
      'nightPower': nightpower,
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
  
  // 生成模拟实时天气数据（用于开发测试）
  Map<String, dynamic> _getSimulatedRealTimeWeather(String cityCode) {
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
      'province': '新疆',
      'adcode': cityCode,
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
  
  // 生成模拟天气预报数据（用于开发测试）
  List<Map<String, dynamic>> _getSimulatedForecast(String cityCode) {
    final cityName = _getCityNameByCode(cityCode);
    final now = DateTime.now();
    final weatherOptions = ['晴', '多云', '阴', '小雨', '中雨', '大雨', '雷阵雨', '小雪', '中雪'];
    final windDirections = ['东', '南', '西', '北', '东北', '东南', '西北', '西南'];
    final weekDays = ['日', '一', '二', '三', '四', '五', '六'];
    
    List<Map<String, dynamic>> forecastList = [];
    
    // 生成未来三天的天气预报
    for (int i = 0; i < 3; i++) {
      final forecastDate = now.add(Duration(days: i));
      final weatherIndex = (forecastDate.day + int.parse(cityCode.substring(0, 2)) + i) % weatherOptions.length;
      final nightWeatherIndex = (weatherIndex + 1) % weatherOptions.length;
      
      final baseTemp = 20 + (forecastDate.month - 6) * 3;
      final dayTempVariation = (forecastDate.day % 10) - 3 + i;
      final nightTempVariation = (forecastDate.day % 8) - 5 - i;
      
      final dayTemp = (baseTemp + dayTempVariation).toStringAsFixed(0);
      final nightTemp = (baseTemp + nightTempVariation).toStringAsFixed(0);
      
      final windIndex = (forecastDate.day + int.parse(cityCode.substring(2, 4)) + i) % windDirections.length;
      final nightWindIndex = (windIndex + 2) % windDirections.length;
      
      forecastList.add({
        'city': cityName,
        'province': '新疆',
        'adcode': cityCode,
        'date': DateFormat('yyyy-MM-dd').format(forecastDate),
        'week': '星期${weekDays[forecastDate.weekday % 7]}',
        'dayWeather': weatherOptions[weatherIndex],
        'nightWeather': weatherOptions[nightWeatherIndex],
        'dayTemp': dayTemp,
        'nightTemp': nightTemp,
        'dayWind': windDirections[windIndex],
        'nightWind': windDirections[nightWindIndex],
        'dayPower': '${(forecastDate.day % 5) + 1}级',
        'nightPower': '${(forecastDate.day % 4) + 1}级',
        'suggestion': _getWeatherSuggestion(weatherOptions[weatherIndex], double.parse(dayTemp)),
        'isSimulated': true,
      });
    }
    
    return forecastList;
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
  
  // 格式化天气预报信息为易读文本
  static String formatForecastToText(Map<String, dynamic> forecast) {
    final buffer = StringBuffer();
    
    if (forecast.isEmpty) {
      return "暂无天气预报数据";
    }
    
    final city = forecast[0]['city'];
    final isSimulated = forecast[0]['isSimulated'] ?? false;
    
    buffer.writeln("$city天气预报（${isSimulated ? '模拟数据' : '实时数据'}）:");
    buffer.writeln("-----------------------------------");
    
      final date = forecast['date'];
      final week = forecast['week'];
      buffer.writeln("📆 $date ($week)");
      buffer.writeln("☀️ 白天: ${forecast['dayWeather']} ${forecast['dayTemp']}°C ${forecast['dayWind']}风${forecast['dayPower']}");
      buffer.writeln("🌙 夜间: ${forecast['nightWeather']} ${forecast['nightTemp']}°C ${forecast['nightWind']}风${forecast['nightPower']}");
      buffer.writeln("🔔 建议: ${forecast['suggestion']}");
      buffer.writeln("-----------------------------------");
    
    
    return buffer.toString();
  }
}