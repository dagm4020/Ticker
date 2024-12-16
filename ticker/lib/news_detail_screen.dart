// lib/news_detail_screen.dart

import 'package:flutter/material.dart';
import 'models/news_article.dart'; // Correct import path
import 'package:cached_network_image/cached_network_image.dart';
import 'article_webview_screen.dart'; // Import the WebView screen

class NewsDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Article article =
        ModalRoute.of(context)!.settings.arguments as Article;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.deepPurple.shade900],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    SizedBox(height: 8.0),

                    // Article Image or Placeholder
                    if (article.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: CachedNetworkImage(
                          imageUrl: article.imageUrl,
                          placeholder: (context, url) => Container(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            color: Colors.grey,
                            child: Icon(Icons.error,
                                color: Colors.red, size: 50),
                          ),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      // Placeholder for articles without images
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Container(
                          height: 200,
                          color: Colors.grey,
                          child: Icon(Icons.image, size: 100, color: Colors.white),
                        ),
                      ),

                    SizedBox(height: 16.0),

                    // Article Title
                    Text(
                      article.title,
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 12.0),

                    // Article Description
                    if (article.description.isNotEmpty)
                      Text(
                        article.description,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white70,
                        ),
                      ),

                    SizedBox(height: 12.0),

                    // Article Content
                    if (article.content.isNotEmpty)
                      Text(
                        article.content,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white70,
                        ),
                      )
                    else if (article.description.isNotEmpty)
                      Text(
                        'For more details, please read the full article.',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Text(
                        'No additional content available.',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                    SizedBox(height: 80.0), // Add spacing to accommodate the button
                  ],
                ),
              ),
              // Positioned "Read More" Button
              Positioned(
                bottom: 16.0,
                left: 16.0,
                right: 16.0,
                child: ElevatedButton(
                  onPressed: () {
                    if (article.url.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleWebViewScreen(
                            url: article.url,
                            title: article.title,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Article URL is not available.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Read More',
                    style: TextStyle(
                      color: Colors.white, // Ensure text is white
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.deepPurple, // Button background color
                    padding:
                        EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 5.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
