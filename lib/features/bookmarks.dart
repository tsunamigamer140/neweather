import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'article.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarksBox = Hive.box('bookmarksBox');
    final bookmarks = bookmarksBox.values.toList();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Bookmarks', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        body: bookmarks.isEmpty
            ? const Center(
                child: Text('No bookmarks yet', style: TextStyle(color: Colors.white)),
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
                                  Text(title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 18 * scale,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace')),
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
    );
  }
}
