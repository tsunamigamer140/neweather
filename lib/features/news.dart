import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:neweather/features/bookmarks.dart';
import 'package:shimmer/shimmer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:neweather/widgets/articleList.dart';
import 'article.dart';
import 'package:provider/provider.dart';
import 'package:neweather/config/themer.dart';
import 'package:neweather/widgets/categorybar.dart';

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

  bool isSearching = false;
  String searchQuery = '';
  List searchResults = [];
  bool isSearchLoading = false;
  final TextEditingController _searchController = TextEditingController();

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

  Future<void> _searchArticles(String query) async {
    setState(() {
      isSearchLoading = true;
      searchResults = [];
    });
    final url = Uri.parse(
        'https://newsapi.org/v2/everything?q=$query&apiKey=$apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          searchResults = jsonData['articles'];
        });
      }
    } catch (e) {
      // Optionally handle error
    } finally {
      setState(() {
        isSearchLoading = false;
      });
    }
  }

  void _startSearch() {
    setState(() {
      isSearching = true;
      _searchController.clear();
      searchResults = [];
    });
  }

  void _stopSearch() {
    setState(() {
      isSearching = false;
      searchQuery = '';
      searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final paginatedArticles = articles.skip(page * itemsPerPage).take(itemsPerPage).toList();

    return Hero(
      tag: 'news-hero',
      child: SafeArea(
        child: Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode ? Colors.white : Colors.black
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search articles...',
                      hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                      border: InputBorder.none,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (query) {
                      if (query.trim().isNotEmpty) {
                        setState(() => searchQuery = query.trim());
                        _searchArticles(query.trim());
                      }
                    },
                  )
                : Text(
                    "News",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black
                    )
                  ),
            actions: [
              if (!isSearching)
                IconButton(
                  icon: Icon(Icons.search, color: isDarkMode ? Colors.white : Colors.black),
                  onPressed: _startSearch,
                ),
              if (isSearching)
                IconButton(
                  icon: Icon(Icons.close, color: isDarkMode ? Colors.white : Colors.black),
                  onPressed: _stopSearch,
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
              )
            ]
          ),
          body: isSearching
              ? (isSearchLoading
                  ? Center(child: CircularProgressIndicator())
                  : ArticleList(
                      paginatedArticles: searchResults,
                      isLoading: false,
                      isBookmarked: isBookmarked,
                      toggleBookmark: toggleBookmark,
                      buildArticleSkeleton: _buildArticleSkeleton,
                    )
                )
              : GestureDetector(
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
                        CategoryBar(
                          categories: categories,
                          currentCategoryIndex: currentCategoryIndex,
                          isDarkMode: isDarkMode,
                          onCategorySelected: (index) {
                            setState(() {
                              currentCategoryIndex = index;
                            });
                            _fetchNews();
                          },
                        ),
                        const Divider(height: 1, color: Colors.white),
                        const SizedBox(height: 10),
                        // Articles list or skeletons
                        Expanded(
                          child: ArticleList(
                            paginatedArticles: paginatedArticles,
                            isLoading: isLoading,
                            isBookmarked: isBookmarked,
                            toggleBookmark: toggleBookmark,
                            buildArticleSkeleton: _buildArticleSkeleton,
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
      ),
    );
  }
}
