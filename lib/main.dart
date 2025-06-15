import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shimmer/shimmer.dart';

import 'features/news.dart';
import 'features/weather.dart';
import 'package:neweather/config/settings.dart';
import 'package:neweather/config/themer.dart';
import 'package:neweather/widgets/weathercard.dart';
import 'package:neweather/widgets/articleList.dart';
import 'package:neweather/features/bookmarks.dart';
import 'package:neweather/widgets/newsdashboard.dart';

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
  HomePage({super.key}) {
    _initHive();
  }

  Future<void> _initHive() async {
    weatherCacheBox = await Hive.openBox('weatherCacheBox');
    newsCacheBox = await Hive.openBox('newsCacheBox');
  }

  final String weatherApiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
  final String newsApiKey = dotenv.env['NEWS_API_KEY'] ?? '';

  late final Box weatherCacheBox;
  late final Box newsCacheBox;

  Future<Map<String, dynamic>> fetchWeather() async {
    String cityName = "Bangalore";
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty && placemarks.first.locality != null && placemarks.first.locality!.isNotEmpty) {
            cityName = placemarks.first.locality!;
          }
        }
      }
    } catch (_) {
      // fallback to Bangalore
    }

    final url = "https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$weatherApiKey&units=metric";
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    return {
      'currentWeather': data,
      'city': cityName,
    };
  }

  Future<List<Map<String, dynamic>>> fetchNews() async {
    final url = "https://newsapi.org/v2/everything?q=Apple&from=2025-06-12&sortBy=popularity&apiKey=$newsApiKey";
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    return List<Map<String, dynamic>>.from(
      data['articles'].take(5)
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
                } else if (snapshot.hasError || snapshot.data == null) {
                  return errorCard("Failed to load weather");
                }

                final weather = snapshot.data!;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WeatherScreen()),
                    );
                  },
                  child: Hero(
                    tag: 'weather-hero',
                    child: WeatherCard(
                      currentWeather: weather['currentWeather'],
                      city: weather['city'],
                      isDarkMode: isDarkMode,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            /// News Section
            FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchNews(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return NewsDashboardSkeleton(isDarkMode: isDarkMode);
                } else if (snapshot.hasError || snapshot.data == null) {
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
                  child: Hero(
                    tag: 'news-hero',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 8, 152, 219),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                            "Top articles",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.bookmark,
                              color: isDarkMode ? Colors.white : Colors.black),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const BookmarksScreen()),
                              );
                            }
                          ),
                            ]
                          ),
                          SizedBox(
                            height: 420, 
                            child: ArticleList(
                              paginatedArticles: articles,
                              isLoading: false,
                              isBookmarked: (_) => false,
                              toggleBookmark: (_, __) {},
                              buildArticleSkeleton: () => Container(
                                height: 150,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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