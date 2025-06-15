import 'package:flutter/material.dart';
import 'package:neweather/features/article.dart';
import 'package:provider/provider.dart';
import 'package:neweather/config/themer.dart';

class ArticleList extends StatelessWidget {
  final List paginatedArticles;
  final bool isLoading;
  final bool Function(String url) isBookmarked;
  final void Function(String url, Map article) toggleBookmark;
  final Widget Function() buildArticleSkeleton;

  const ArticleList({
    super.key,
    required this.paginatedArticles,
    required this.isLoading,
    required this.isBookmarked,
    required this.toggleBookmark,
    required this.buildArticleSkeleton,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return isLoading
        ? ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => buildArticleSkeleton(),
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
                    color: isDarkMode ? Colors.grey.shade300 : Colors.black,
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
                            mainAxisAlignment: MainAxisAlignment.start,
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
                                            color: isDarkMode ? Colors.black : Colors.white,
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
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: isDarkMode ? Colors.black : Colors.white
                                  )
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}