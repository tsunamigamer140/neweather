import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

import 'package:provider/provider.dart';
import 'package:neweather/config/themer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:neweather/widgets/weathercard.dart';
import 'package:neweather/widgets/weeklyforecast.dart';
import 'package:neweather/widgets/cityweathercomp.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? currentWeather;
  List<dynamic> dailyForecast = [];
  final String apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
  String city = 'Bangalore';
  bool isLoading = true;
  String? errorMsg;
  late Box weatherCacheBox;

  @override
  void initState() {
    super.initState();
    _initHiveAndFetchWeather();
  }

  Future<void> _initHiveAndFetchWeather() async {
  await Hive.initFlutter();
  weatherCacheBox = await Hive.openBox('weatherCacheBox');
  determinePositionAndFetchWeather();
}

  Future<void> determinePositionAndFetchWeather() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          errorMsg = "Location services are disabled.";
          isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMsg = "Location permissions are denied.";
            isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMsg = "Location permissions are permanently denied.";
          isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.low));

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty && placemarks.first.locality != null && placemarks.first.locality!.isNotEmpty) {
        city = placemarks.first.locality!;
      } else {
        city = 'Bangalore'; // fallback
      }
      await fetchWeatherData();
    } catch (e) {
      setState(() {
        errorMsg = "Failed to get location: $e";
        isLoading = false;
      });
    }
  }

  void _loadWeatherFromCache(String city) {
    final cachedWeather = weatherCacheBox.get('weather_$city');
    final cachedForecast = weatherCacheBox.get('forecast_$city');
    if (cachedWeather != null && cachedForecast != null) {
      setState(() {
        currentWeather = Map<String, dynamic>.from(cachedWeather);
        dailyForecast = List<Map<String, dynamic>>.from(cachedForecast);
        errorMsg = "Showing cached data (offline)";
        isLoading = false;
      });
    } else {
      setState(() {
        errorMsg = "No cached data available.";
        isLoading = false;
      });
    }
  }

  Future<void> fetchWeatherData() async {
    final currentUrl =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey';
    final forecastUrl =
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&units=metric&appid=$apiKey';

    try {
      final currentResponse = await http.get(Uri.parse(currentUrl));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (currentResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
        final currentData = json.decode(currentResponse.body);
        final forecastList = json.decode(forecastResponse.body)['list'];
        final daily = _extractDailyForecast(forecastList);

        // Cache both current and forecast
        weatherCacheBox.put('weather_$city', currentData);
        weatherCacheBox.put('forecast_$city', daily);

        setState(() {
          currentWeather = currentData;
          dailyForecast = daily;
          isLoading = false;
        });
      } else {
        _loadWeatherFromCache(city);
      }
    } catch (e) {
      _loadWeatherFromCache(city);
    }
  }

  List<Map<String, dynamic>> _extractDailyForecast(List<dynamic> data) {
    Map<String, Map<String, dynamic>> temp = {};
    for (var entry in data) {
      String day = DateTime.parse(entry['dt_txt']).weekday.toString();
      if (!temp.containsKey(day)) {
        temp[day] = {
          'day': DateTime.parse(entry['dt_txt']),
          'temp': entry['main']['temp'],
          'icon': entry['weather'][0]['icon'],
          'rain': entry['pop'],
        };
      }
    }
    return temp.values.take(7).toList();
  }


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return SafeArea(
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "Weather",
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            )
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMsg != null
                  ? Center(child: Text(errorMsg!, style: TextStyle(color: Colors.red)))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (currentWeather != null)
                            Hero(
                              tag: 'weather-hero',
                              child: WeatherCard(
                                currentWeather: currentWeather!,
                                city: city,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          const SizedBox(height: 16),
                          WeeklyForecast(
                            dailyForecast: dailyForecast,
                            isDarkMode: isDarkMode,
                            weekdayToString: _weekdayToString,
                          ),
                          const SizedBox(height: 16),
                          CompareCitiesWidget(isDarkMode: isDarkMode),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  String _weekdayToString(int weekday) {
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return days[weekday - 1];
  }
}
