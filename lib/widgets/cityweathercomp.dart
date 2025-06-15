import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CompareCitiesWidget extends StatefulWidget {
  final bool isDarkMode;
  const CompareCitiesWidget({super.key, required this.isDarkMode});

  @override
  State<CompareCitiesWidget> createState() => _CompareCitiesWidgetState();
}

class _CompareCitiesWidgetState extends State<CompareCitiesWidget> {
  final TextEditingController _city1Controller = TextEditingController();
  final TextEditingController _city2Controller = TextEditingController();

  Map<String, dynamic>? city1Weather;
  Map<String, dynamic>? city2Weather;
  bool loading1 = false;
  bool loading2 = false;
  String? error1;
  String? error2;

  Future<void> fetchWeather(String city, int index) async {
    setState(() {
      if (index == 1) {
        loading1 = true;
        error1 = null;
      } else {
        loading2 = true;
        error2 = null;
      }
    });
    final apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
    final url =
        "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (index == 1) {
            city1Weather = data;
            loading1 = false;
          } else {
            city2Weather = data;
            loading2 = false;
          }
        });
      } else {
        setState(() {
          if (index == 1) {
            error1 = "Not found";
            loading1 = false;
          } else {
            error2 = "Not found";
            loading2 = false;
          }
        });
      }
    } catch (_) {
      setState(() {
        if (index == 1) {
          error1 = "Error";
          loading1 = false;
        } else {
          error2 = "Error";
          loading2 = false;
        }
      });
    }
  }

  Widget _weatherBox(Map<String, dynamic>? weather, String? error, bool loading, String city) {
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error, style: TextStyle(color: Colors.red)));
    }
    if (weather == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.amber.shade700 : Colors.amberAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny, color: widget.isDarkMode ? Colors.white : Colors.black, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  weather['weather'][0]['main'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "${weather['main']['temp'].round()}°C   ${weather['main']['humidity']}%H",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            city,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compare Cities',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      controller: _city1Controller,
                      decoration: const InputDecoration(
                        labelText: "City 1",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) fetchWeather(val.trim(), 1);
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_city1Controller.text.trim().isNotEmpty) {
                          fetchWeather(_city1Controller.text.trim(), 1);
                        }
                      },
                      child: const Text("Get Weather"),
                    ),
                    _weatherBox(city1Weather, error1, loading1, _city1Controller.text.trim()),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      controller: _city2Controller,
                      decoration: const InputDecoration(
                        labelText: "City 2",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) fetchWeather(val.trim(), 2);
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_city2Controller.text.trim().isNotEmpty) {
                          fetchWeather(_city2Controller.text.trim(), 2);
                        }
                      },
                      child: const Text("Get Weather"),
                    ),
                    _weatherBox(city2Weather, error2, loading2, _city2Controller.text.trim()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}