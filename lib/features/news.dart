import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neweather/features/bookmarks.dart';
import 'package:shimmer/shimmer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'article.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final List<String> categories = ['general', 'business', 'entertainment', 'health', 'science', 'sports', 'technology'];
  int currentCategoryIndex = 0;
  List articles = [];
  int page = 0;
  final int itemsPerPage = 5;
  final String apiKey = dotenv.env['NEWS_API_KEY'] ?? '';
  bool isLoading = false;
  late Box bookmarksBox;

  @override
  void initState() {
    super.initState();
    _initHiveAndFetch();
  }

  Future<void> _initHiveAndFetch() async {
    await Hive.initFlutter();
    bookmarksBox = await Hive.openBox('bookmarksBox');
    await Hive.openBox('cacheBox');
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() => isLoading = true);
    final box = Hive.box('cacheBox');
    final category = categories[currentCategoryIndex];
    final url = Uri.parse(
        'https://newsapi.org/v2/top-headlines?country=us&category=$category&apiKey=$apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        box.put('articles_$category', jsonData['articles']);
        if (!mounted) return;
        setState(() {
          articles = jsonData['articles'];
          page = 0;
        });
      } else {
        _loadFromCache(box, category);
      }
    } catch (e) {
      _loadFromCache(box, category);
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _loadFromCache(Box box, String category) {
    final cached = box.get('articles_$category');
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        articles = List.from(cached);
        page = 0;
      });
    } else {
      debugPrint('No cached data available.');
    }
  }

  void _nextPage() {
    if ((page + 1) * itemsPerPage < articles.length) {
      setState(() => page++);
    }
  }

  void _prevPage() {
    if (page > 0) {
      setState(() => page--);
    }
  }

  void _onSwipeCategory(bool left) {
    setState(() {
      currentCategoryIndex = (currentCategoryIndex + (left ? 1 : -1)) % categories.length;
      if (currentCategoryIndex < 0) currentCategoryIndex += categories.length;
    });
    _fetchNews();
  }

  Widget _buildArticleSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 150,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  bool isBookmarked(String url) => bookmarksBox.containsKey(url);

  void toggleBookmark(String url, Map article) {
    setState(() {
      if (isBookmarked(url)) {
        bookmarksBox.delete(url);
      } else {
        bookmarksBox.put(url, article);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final paginatedArticles = articles.skip(page * itemsPerPage).take(itemsPerPage).toList();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text("News", style: TextStyle(color: Colors.white)),
          actions: [
            IconButton(
              icon: Icon(Icons.bookmark, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookmarksScreen()),
                );
              }
            )
          ]
        ),
        body: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < 0) {
                _onSwipeCategory(true); // Swipe left
              } else {
                _onSwipeCategory(false); // Swipe right
              }
            }
          },
          child: RefreshIndicator(
            onRefresh: _fetchNews,
            child: Column(
              children: [
                // Scrollable Category bar
                Container(
                  color: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  height: 48,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = categories.indexOf(cat) == currentCategoryIndex;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                currentCategoryIndex = categories.indexOf(cat);
                              });
                              _fetchNews();
                            },
                            child: Text(cat,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.black : Colors.grey,
                                  fontSize: 18,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Colors.white),

                // Articles list or skeletons
                Expanded(
                  child: isLoading
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: 5,
                          itemBuilder: (context, index) => _buildArticleSkeleton(),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: paginatedArticles.length,
                          itemBuilder: (context, index) {
                            final article = paginatedArticles[index];
                            final title = article['title'] ?? 'No Title';
                            final desc = article['description'] ?? '';
                            final imageUrl = article['urlToImage'];
                            final url = article['url'];
                            final double scale = title.length > 30 ? 0.9 : 1.2;
                            final bookmarked = isBookmarked(url);

                            return GestureDetector(
                              onTap: () {
                                if (url != null && url.toString().startsWith("http")) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ArticleDetailScreen(url: url, title: title),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                                      child: imageUrl != null
                                          ? Image.network(
                                              imageUrl,
                                              width: 100,
                                              height: 150,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Container(width: 100, height: 150, color: Colors.grey),
                                            )
                                          : Container(width: 100, height: 150, color: Colors.grey),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(title,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                          fontSize: 18 * scale,
                                                          fontWeight: FontWeight.bold,
                                                          fontFamily: 'monospace')),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    bookmarked ? Icons.bookmark : Icons.bookmark_border,
                                                    color: Colors.black,
                                                  ),
                                                  onPressed: () {
                                                    toggleBookmark(url, article);
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(desc,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontFamily: 'monospace')),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Pagination
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: _prevPage,
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: _nextPage,
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
