import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';


import 'features/news.dart';
import 'features/weather.dart';
import 'package:neweather/config/settings.dart';
import 'package:neweather/config/themer.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  await Hive.openBox('settingsBox');
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp()
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Weather and News',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final String weatherApiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
  final String newsApiKey = dotenv.env['NEWS_API_KEY'] ?? '';
  final String city = "Bangalore";

  Future<Map<String, dynamic>> fetchWeather() async {
    final url = "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$weatherApiKey&units=metric";
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    return {
      'description': data['weather'][0]['main'],
      'temperature': data['main']['temp'].toInt(),
      'humidity': data['main']['humidity'],
    };
  }

  Future<List<String>> fetchNews() async {
    final url = "https://newsapi.org/v2/everything?q=Apple&from=2025-06-12&sortBy=popularity&apiKey=$newsApiKey";
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    return List<String>.from(
      data['articles'].map((article) => article['title']).take(5)
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            /// Weather Section
            FutureBuilder<Map<String, dynamic>>(
              future: fetchWeather(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return loadingCard();
                } else if (snapshot.hasError) {
                  return errorCard("Failed to load weather");
                }

                final weather = snapshot.data!;
                return GestureDetector(
                  onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WeatherScreen()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wb_sunny, size: 48, color: Colors.black,),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              weather['description'],
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            Text(
                              "${weather['temperature']}°   ${weather['humidity']}%H",
                              style: TextStyle(fontSize: 18, color: Colors.black),
                            ),
                            Text(
                              city.toLowerCase(),
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            /// News Section
            FutureBuilder<List<String>>(
              future: fetchNews(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return loadingCard();
                } else if (snapshot.hasError) {
                  return errorCard("Failed to load news");
                }

                final articles = snapshot.data!;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NewsScreen()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Top 5 articles today",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        for (var article in articles)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              article,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            /// Preferences Button
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreenAccent.shade400,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen())
                  );
                },
                icon: const Icon(Icons.settings, color: Colors.black),
                label: const Text(
                  "Preferences",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget loadingCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );

  Widget errorCard(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
            child: Text(message,
                style: TextStyle(fontSize: 16, color: Colors.white))),
      );
} 