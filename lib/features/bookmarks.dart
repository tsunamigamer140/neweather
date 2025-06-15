import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'article.dart';
import 'package:provider/provider.dart';
import 'package:neweather/config/themer.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final bookmarksBox = Hive.box('bookmarksBox');
    final bookmarks = bookmarksBox.values.toList();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          title: Text('Bookmarks', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black,)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: bookmarks.isEmpty
            ? Center(
                child: Text('No bookmarks yet', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black,)),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final article = bookmarks[index];
                  final title = article['title'] ?? 'No Title';
                  final desc = article['description'] ?? '';
                  final imageUrl = article['urlToImage'];
                  final url = article['url'];
                  final double scale = title.length > 30 ? 0.9 : 1.2;

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
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 18 * scale,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.black : Colors.white,
                                          fontFamily: 'monospace')),
                                  const SizedBox(height: 4),
                                  Text(desc,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        color: isDarkMode ? Colors.black : Colors.white,
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
              ),
      ),
    );
  }
}
