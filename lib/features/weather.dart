import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

import 'package:provider/provider.dart';
import 'package:neweather/config/themer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  @override
  void initState() {
    super.initState();
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
          desiredAccuracy: LocationAccuracy.low);

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

  Future<void> fetchWeatherData() async {
    final currentUrl =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey';
    final forecastUrl =
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&units=metric&appid=$apiKey';

    try {
      final currentResponse = await http.get(Uri.parse(currentUrl));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (currentResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
        setState(() {
          currentWeather = json.decode(currentResponse.body);
          final forecastList = json.decode(forecastResponse.body)['list'];
          dailyForecast = _extractDailyForecast(forecastList);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMsg = "Error fetching weather data for $city";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = "Error fetching weather: $e";
        isLoading = false;
      });
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

  void _addCityComparison() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Choose City'),
        content: const Text('City picker coming soon!'),
      ),
    );
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
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (currentWeather != null)
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.amber.shade700 : Colors.amberAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.wb_sunny, size: 64, color: isDarkMode ? Colors.white : Colors.black),
                                const SizedBox(height: 8),
                                Text(
                                  currentWeather!['weather'][0]['main'],
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${currentWeather!['main']['temp'].round()}°   ${currentWeather!['main']['humidity']}%H",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  city.toLowerCase(),
                                  style: TextStyle(fontSize: 20, fontFamily: 'monospace', color: isDarkMode ? Colors.white70 : Colors.black),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (dailyForecast.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.blueGrey.shade800 : Colors.blueAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(16),
                            height: 220,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: dailyForecast.map((day) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Column(
                                      children: [
                                        Text(
                                          _weekdayToString(day['day'].weekday),
                                          style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                                        ),
                                        const SizedBox(height: 4),
                                        Image.network(
                                          'https://openweathermap.org/img/wn/${day['icon']}@2x.png',
                                          width: 36,
                                          height: 36,
                                        ),
                                        const SizedBox(height: 4),
                                        Text('${day['temp'].round()}°',
                                            style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                                        const SizedBox(height: 4),
                                        Text('${(day['rain'] * 100).round()}%\nchance\nof rain',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black87)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('compare cities', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildCityCompareBox(isDarkMode),
                                  _buildCityCompareBox(isDarkMode),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  String _weekdayToString(int weekday) {
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return days[weekday - 1];
  }

  Widget _buildCityCompareBox(bool isDarkMode) {
    return GestureDetector(
      onTap: _addCityComparison,
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Icon(Icons.add, size: 28, color: isDarkMode ? Colors.white : Colors.black)),
      ),
    );
  }
}
